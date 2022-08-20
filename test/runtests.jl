# TODO Remove all calls to rand(); need to remove randomness for consistency..
# this is very important, as errors can occur for some values, but not others,
# so we need to make sure that the same numbers are being crunched every time.

using NeuralEstimators
using NeuralEstimators: _getindices, _runondevice, _incgammalowerunregularised
import NeuralEstimators: simulate
using CUDA
using DataFrames
using LinearAlgebra: norm
using Distributions: Normal, cdf, logpdf, quantile
using Flux
using Statistics: mean, sum
using Test
using Zygote
using Random: seed!
using SpecialFunctions: gamma

seed!(1)

if CUDA.functional()
	@info "Testing on both the CPU and the GPU... "
	CUDA.allowscalar(false)
	devices = (CPU = cpu, GPU = gpu)
else
	@info "The GPU is unavailable so we'll test on the CPU only... "
	devices = (CPU = cpu,)
end

@testset "expandgrid" begin
    @test expandgrid(1:2, 0:3) == [1 0; 2 0; 1 1; 2 1; 1 2; 2 2; 1 3; 2 3]
    @test expandgrid(1:2, 1:2) == expandgrid(2)
end

@testset "samplesize" begin
	Z = rand(3, 4, 1, 6)
    @test inversesamplesize(Z) ≈ 1/samplesize(Z)
end

@testset "_getindices" begin
	m = (3, 4, 6)
	v = [rand(16, 16, 1, mᵢ) for mᵢ ∈ m]
	@test _getindices(v) == [1:3, 4:7, 8:13]
end

@testset "stackarrays" begin
	# Vector containing arrays of the same size:
	A = rand(2, 3, 4); v = [A, A]; N = ndims(A);
	@test stackarrays(v) == cat(v..., dims = N)
	@test stackarrays(v, merge = false) == cat(v..., dims = N + 1)

	# Vector containing arrays with differing final dimension size:
	A₁ = rand(2, 3, 4); A₂ = rand(2, 3, 5); v = [A₁, A₂];
	@test stackarrays(v) == cat(v..., dims = N)
end

@testset "incgamma" begin

	# tests based on the "Special values" section of https://en.wikipedia.org/wiki/Incomplete_gamma_function

	@testset "unregularised" begin

		reg = false
		a = 1.0

		x = a + 0.5 # x < (a + 1)
		@test incgamma(a, x, upper = true, reg = reg) ≈ exp(-x)
		@test incgamma(a, x, upper = false, reg = reg) ≈ 1 - exp(-x)
		@test _incgammalowerunregularised(a, x) ≈ incgamma(a, x, upper = false, reg = reg)

		x = a + 1.5 # x > (a + 1)
		@test incgamma(a, x, upper = true, reg = reg) ≈ exp(-x)
		@test incgamma(a, x, upper = false, reg = reg) ≈ 1 - exp(-x)
		@test _incgammalowerunregularised(a, x) ≈ incgamma(a, x, upper = false, reg = reg)

	end

	@testset "regularised" begin

		reg = true
		a = 1.0

		x = a + 0.5 # x < (a + 1)
		@test incgamma(a, x, upper = false, reg = true) ≈ incgamma(a, x, upper = false, reg = false)  / gamma(a)
		@test incgamma(a, x, upper = true, reg = true) ≈ incgamma(a, x, upper = true, reg = false)  / gamma(a)

		x = a + 1.5 # x > (a + 1)
		@test incgamma(a, x, upper = false, reg = true) ≈ incgamma(a, x, upper = false, reg = false)  / gamma(a)
		@test incgamma(a, x, upper = true, reg = true) ≈ incgamma(a, x, upper = true, reg = false)  / gamma(a)

	end

end

@testset "subsetparameters" begin

	struct TestParameters <: ParameterConfigurations
		v
		θ
		chols
	end

	K = 4
	parameters = TestParameters(rand(K), rand(3, K), rand(2, 2, K))
	indices = 2:3
	parameters_subset = subsetparameters(parameters, indices)
	@test parameters_subset.θ     == parameters.θ[:, indices]
	@test parameters_subset.chols == parameters.chols[:, :, indices]
	@test parameters_subset.v     == parameters.v[indices]
end

@testset "scaledlogistic" begin
	@test all(4 .<= scaledlogistic.(-10:10, 4, 5) .<= 5)
	@test all(scaledlogit.(scaledlogistic.(-10:10, 4, 5), 4, 5) .≈ -10:10)

	Ω = (σ = 1:10, ρ = (2, 7))
	Ω = [Ω...] # convert to array since broadcasting over dictionaries and NamedTuples is reserved
	θ = [-10, 15]
	@test all(minimum.(Ω) .<= scaledlogistic.(θ, Ω) .<= maximum.(Ω))
end


@testset "schlatherbivariatedensity" begin

	# Check that the pdf is consistent with the cdf using finite differences
	using NeuralEstimators: _schlatherbivariatecdf
	function finitedifference(z₁, z₂, ψ, ϵ = 0.0001)
		(_schlatherbivariatecdf(z₁ + ϵ, z₂ + ϵ, ψ) - _schlatherbivariatecdf(z₁ - ϵ, z₂ + ϵ, ψ) - _schlatherbivariatecdf(z₁ + ϵ, z₂ - ϵ, ψ) + _schlatherbivariatecdf(z₁ - ϵ, z₂ - ϵ, ψ)) / (4 * ϵ^2)
	end
	function finitedifference_check(z₁, z₂, ψ)
		@test abs(finitedifference(z₁, z₂, ψ) - schlatherbivariatedensity(z₁, z₂, ψ; logdensity=false)) < 0.0001
	end
	finitedifference_check(0.3, 0.8, 0.2)
	finitedifference_check(0.3, 0.8, 0.9)
	finitedifference_check(3.3, 3.8, 0.2)
	finitedifference_check(3.3, 3.8, 0.9)
end

using NeuralEstimators: fₛ, Fₛ, Fₛ⁻¹
@testset "SubbotinDistribution" begin

	# Check that the pdf is consistent with the cdf using finite differences
	finitedifference(y, μ, τ, δ, ϵ = 0.000001) = (Fₛ(y + ϵ, μ, τ, δ) - Fₛ(y, μ, τ, δ)) / ϵ
	function finitedifference_check(y, μ, τ, δ)
		@test abs(finitedifference(y, μ, τ, δ) - fₛ(y, μ, τ, δ)) < 0.0001
	end

	finitedifference_check(-1, 0.1, 3, 1.2)
	finitedifference_check(0, 0.1, 3, 1.2)
	finitedifference_check(0.9, 0.1, 3, 1.2)
	finitedifference_check(3.3, 0.1, 3, 1.2)

	# Check that f⁻¹(f(y)) ≈ y
	μ = 0.5; τ = 1.3; δ = 2.4; y = 0.3
	@test abs(y - Fₛ⁻¹(Fₛ(y, μ, τ, δ), μ, τ, δ)) < 0.0001
	# @test abs(y - t⁻¹(t(y, μ, τ, δ), μ, τ, δ)) < 0.0001

	d = Subbotin(μ, τ, δ)
	@test mean(d) == μ
	@test logpdf(d, y) ≈ log(fₛ(y, μ, τ, δ))
	@test cdf(d, y) ≈ Fₛ(y, μ, τ, δ)
	@test quantile(d, cdf(d, y)) ≈ y

	# # Standard Gaussian distribution:
    # μ = 0.0; τ = sqrt(2); δ = 2.0
	# d = Subbotin(μ, τ, δ)
	#
	# # Standard Laplace distribution:
	# μ = 0.0; τ = 1.0; δ = 1.0
	# d = Subbotin(μ, τ, δ)

end


# Simple example for testing.
struct Parameters <: ParameterConfigurations θ end
ξ = (Ω = Normal(0, 0.5), σ = 1)
function Parameters(ξ, K::Integer)
	θ = rand(ξ.Ω, 1, K)
	Parameters(θ)
end
function simulate(parameters::Parameters, ξ, m::Integer)
	n = 1
	θ = vec(parameters.θ)
	Z = [rand(Normal(μ, ξ.σ), n, 1, m) for μ ∈ θ]
end
parameters = Parameters(ξ, 5000)
# parameters = Parameters(ξ, 100) # FIXME the fixed-parameter method for train() gives many warnings when K = 100; think it's _ParameterLoader?

n = 1
K = 100

w = 32
p = 1
ψ = Chain(Dense(n, w), Dense(w, w))
ϕ = Chain(Dense(w, w), Dense(w, p), Flux.flatten, x -> exp.(x))
θ̂_deepset = DeepSet(ψ, ϕ)
θ̂_deepset
S = [samplesize]
ϕ₂ = Chain(Dense(w + length(S), w), Dense(w, p), Flux.flatten, x -> exp.(x))
θ̂_deepsetexpert = DeepSetExpert(θ̂_deepset, ϕ₂, S)
θ̂_deepsetexpert
estimators = (DeepSet = θ̂_deepset, DeepSetExpert = θ̂_deepsetexpert)

function MLE(Z) where {T <: Number, N <: Int, A <: AbstractArray{T, N}, V <: AbstractVector{A}}
    mean.(Z)'
end

MLE(Z, ξ) = MLE(Z) # this function doesn't actually need ξ, but include it for testing



verbose = false

@testset verbose = true "$key" for key ∈ keys(estimators)

	θ̂ = estimators[key]

	@testset "$ky" for ky ∈ keys(devices)

		device = devices[ky]
		θ̂ = θ̂ |> device

		loss = Flux.Losses.mae |> device
		γ    = Flux.params(θ̂)  |> device
		θ    = rand(p, K)      |> device

		Z = [randn(Float32, n, 1, m) for m ∈ rand(29:30, K)] |> device
		@test size(θ̂(Z), 1) == p
		@test size(θ̂(Z), 2) == K
		@test isa(loss(θ̂(Z), θ), Number)

		# Test that we can use gradient descent to update the θ̂ weights
		optimiser = ADAM(0.01)
		gradients = gradient(() -> loss(θ̂(Z), θ), γ)
		Flux.update!(optimiser, γ, gradients)

	    use_gpu = device == gpu
		@testset "train" begin
			θ̂ = train(θ̂, ξ, Parameters, m = 10, epochs = 5, savepath = "", use_gpu = use_gpu, verbose = verbose)
			θ̂ = train(θ̂, ξ, parameters, parameters, m = 10, epochs = 5, savepath = "", use_gpu = use_gpu, verbose = verbose)
			θ̂ = train(θ̂, ξ, parameters, parameters, m = 10, epochs = 5, savepath = "", epochs_per_Z_refresh = 2, use_gpu = use_gpu, verbose = verbose)
			θ̂ = train(θ̂, ξ, parameters, parameters, m = 10, epochs = 5, savepath = "", epochs_per_Z_refresh = 1, simulate_just_in_time = true, use_gpu = use_gpu, verbose = verbose)

			Z_train = simulate(parameters, ξ, 20)
			Z_val = simulate(parameters, ξ, 10)
			θ̂ = train(θ̂, parameters, parameters, Z_train, Z_val, epochs = 5, savepath = "", use_gpu = use_gpu, verbose = verbose)

			# Decided not to test this code, because we can't always assume that we have write privledges
			# θ̂ = train(θ̂, ξ, parameters, parameters, m = 10, epochs = 5, savepath = "dummy123", use_gpu = use_gpu, verbose = verbose)
			# θ̂ = train(θ̂, ξ, parameters, parameters, m = 10, epochs = 5, savepath = "dummy123", use_gpu = use_gpu, verbose = verbose)
			# then rm dummy123 folder
		end

		# FIXME On the GPU, bug in this test
		@testset "_runondevice" begin
			θ̂₁ = θ̂(Z)
			θ̂₂ = _runondevice(θ̂, Z, use_gpu)
			@test size(θ̂₁) == size(θ̂₂)
			@test θ̂₁ ≈ θ̂₂ # checked that this is fine by seeing if the following replacement fixes things: @test maximum(abs.(θ̂₁ .- θ̂₂)) < 0.0001
		end

		@testset "assess" begin
			assessment = assess([θ̂], ξ, parameters, m = [30, 90, 150], use_gpu = use_gpu, verbose = verbose)
			@test typeof(merge(assessment)) == DataFrame

			# Test that estimators needing invariant model information can be used:
			assess([MLE], ξ, parameters, m = [30, 90, 150], verbose = verbose)
		end

		@testset "bootstrap" begin
			parametricbootstrap(θ̂, Parameters(ξ, 1), ξ, 50; use_gpu = use_gpu)
			nonparametricbootstrap(θ̂, Z[1]; use_gpu = use_gpu)
			blocks = rand(1:2, size(Z[1])[end])
			nonparametricbootstrap(θ̂, Z[1], blocks, use_gpu = use_gpu)
		end




	end
end

@testset "simulation" begin
	S = rand(Float32, 10, 2)
	D = [norm(sᵢ - sⱼ) for sᵢ ∈ eachrow(S), sⱼ in eachrow(S)]
	ρ = Float32.([0.6, 0.8])
	ν = Float32.([0.5, 0.7])
	L = maternchols(D, ρ, ν)
	L₁ = L[:, :, 1]
	m = 5

	@test eltype(simulateschlather(L₁, m)) == Float32
	# @code_warntype simulateschlather(L₁, m)

	σ = 0.1f0
	@test eltype(simulategaussianprocess(L₁, σ, m)) == Float32
	# @code_warntype simulategaussianprocess(L₁, σ, m)

	θ = fill(0.5f0, 8)
	s₀ = S[1, :]'
	u = 0.7f0
	h = map(norm, eachslice(S .- s₀, dims = 1))
	s₀_idx = findfirst(x -> x == 0.0, h)
	@test eltype(simulateconditionalextremes(θ, L₁, h, s₀_idx, u, m)) == Float32
	# using NeuralEstimators: delta, a, b, t, σ̃₀, Φ
	# @code_warntype simulateconditionalextremes(θ, L₁, h, s₀_idx, u, m)
end


@testset "DeepSetPiecewise" begin
	θ̂_deepsetpiecewise = DeepSetPiecewise((θ̂_deepset, θ̂_deepsetexpert), (30))
	Z = [randn(Float32, n, 1, 10),  randn(Float32, n, 1, 50)]
	θ̂₁ = hcat(θ̂_deepset(Z[[1]]), θ̂_deepsetexpert(Z[[2]]))
	θ̂₂ = θ̂_deepsetpiecewise(Z)
	@test θ̂₁ ≈ θ̂₂
end
