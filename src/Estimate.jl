"""
	estimate(estimators, parameters::P, m; <keyword args>) where {P <: ParameterConfigurations}

Using a collection of `estimators`, compute estimates from data simulated from a
set of `parameters`.

`estimate()` requires the user to have defined a method `simulate(parameters, m::Integer)`.

# Keyword arguments
- `m::Vector{Integer} where I <: Integer`: sample sizes to estimate from.
- `estimator_names::Vector{String}`: estimator names used when combining estimates into a `DataFrame` (e.g., `["NeuralEstimator", "BayesEstimator", "MLE"]`), with sensible default values provided.
- `parameter_names::Vector{String}`: parameter names used when combining estimates into a `DataFrame` (e.g., `["μ", "σ"]`), with sensible default values provided.
- `num_rep::Integer = 1`: the number of times to replicate each parameter in `parameters` to reduce the effect of sample variability when assessing the estimators.
- `use_gpu = true`: should be a `Bool` or a collection of `Bool` objects with length equal to the number of estimators.
"""
function estimate(
    estimators, parameters::P; m::Vector{I},
	estimator_names::Vector{String} = ["estimator$i" for i ∈ eachindex(estimators)],
	parameter_names::Vector{String} = ["θ$i" for i ∈ 1:size(parameters, 1)],
	num_rep::Integer = 1, use_gpu = true
	) where {P <: ParameterConfigurations, I <: Integer}

	obj = map(m) do i
	 	_estimate(
		estimators, parameters, i,
		estimator_names = estimator_names, parameter_names = parameter_names,
		num_rep = num_rep, use_gpu = use_gpu
		)
	end

	# Original code:
	# if length(m) > 1
	# 	θ̂ = vcat(map(x -> x.θ̂, obj)...)
	# 	runtime = vcat(map(x -> x.runtime, obj)...)
	# else
	# 	θ̂ = obj.θ̂
	# 	runtime = obj.runtime
	# end

	θ = obj[1].θ
	θ̂ = vcat(map(x -> x.θ̂, obj)...)
	runtime = vcat(map(x -> x.runtime, obj)...)

	return (θ = θ, θ̂ = θ̂, runtime = runtime)
end

function _estimate(
	estimators, parameters::P, m::Integer;
	estimator_names::Vector{String} = ["estimator$i" for i ∈ eachindex(estimators)],
	parameter_names::Vector{String} = ["θ$i" for i ∈ 1:size(parameters, 1)],
	num_rep::Integer = 1, use_gpu = true
	) where {P <: ParameterConfigurations}

	println("Estimating with m = $m...")

	E = length(estimators)
	K = size(parameters, 1)
	@assert length(estimator_names) == E
	@assert length(parameter_names) == K

	@assert eltype(use_gpu) == Bool
	if typeof(use_gpu) == Bool use_gpu = repeat([use_gpu], E) end
	@assert length(use_gpu) == E

	# Simulate data
	println("	Simulating data...")
    y = simulate(parameters, m, num_rep)

	# Initialise a DataFrame to record the run times
	runtime = DataFrame(estimator = [], m = [], time = [])

	θ̂ = map(eachindex(estimators)) do i
		println("	Running estimator $(estimator_names[i])...")
		time = @elapsed θ̂ = _runondevice(estimators[i], y, use_gpu[i])
		push!(runtime, [estimator_names[i], m, time])
		θ̂
	end

    # Convert to DataFrame and add estimator information
    θ̂ = hcat(θ̂...)
    θ̂ = DataFrame(θ̂', parameter_names)
    θ̂[!, "estimator"] = repeat(estimator_names, inner = nrow(θ̂) ÷ E)
    θ̂[!, "m"] = repeat([m], nrow(θ̂))

	# Also provide the true parameters for comparison with the estimates
	# θ = repeat(parameters.θ, outer = (1, num_rep))
	θ = DataFrame(parameters.θ', parameter_names)

    return (θ = θ, θ̂ = θ̂, runtime = runtime)
end

# TODO Helper function for combining θ and θ̂ into a single long form data frame that will be
# useful for plotting. Also want to merge into wide data frame for the scenario plots.
