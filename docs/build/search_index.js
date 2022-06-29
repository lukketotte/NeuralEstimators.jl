var documenterSearchIndex = {"docs":
[{"location":"API/simulation/#Data-simulation","page":"Data simulation","title":"Data simulation","text":"","category":"section"},{"location":"API/simulation/#Model-simulators","page":"Data simulation","title":"Model simulators","text":"","category":"section"},{"location":"API/simulation/","page":"Data simulation","title":"Data simulation","text":"simulategaussianprocess\n\nsimulateschlather\n\nsimulateconditionalextremes","category":"page"},{"location":"API/simulation/#NeuralEstimators.simulategaussianprocess","page":"Data simulation","title":"NeuralEstimators.simulategaussianprocess","text":"simulategaussianprocess(L::AbstractArray{T, 2}, σ::T, m::Integer)\nsimulategaussianprocess(L::AbstractArray{T, 2})\n\nSimulates m realisations from a Gau(0, 𝚺 + σ²𝐈) distribution, where 𝚺 ≡ LL'.\n\nIf σ and m are not provided, a single field without nugget variance is returned.\n\n\n\n\n\n","category":"function"},{"location":"API/simulation/#NeuralEstimators.simulateschlather","page":"Data simulation","title":"NeuralEstimators.simulateschlather","text":"simulateschlather(L::AbstractArray{T, 2}; C = 3.5)\nsimulateschlather(L::AbstractArray{T, 2}, m::Integer; C = 3.5)\n\nSimulates from Schlather's max-stable model. Based on Algorithm 1.2.2 of Dey DK, Yan J (2016). Extreme value modeling and risk analysis: methods and applications. CRC Press, Boca Raton, Florida.\n\n\n\n\n\n","category":"function"},{"location":"API/simulation/#NeuralEstimators.simulateconditionalextremes","page":"Data simulation","title":"NeuralEstimators.simulateconditionalextremes","text":"simulateconditionalextremes(θ, L::AbstractArray{T, 2}, S, s₀, u)\nsimulateconditionalextremes(θ, L::AbstractArray{T, 2}, S, s₀, u, m::Integer)\n\nSimulates from the spatial conditional extremes model.\n\n\n\n\n\n","category":"function"},{"location":"API/simulation/#Intermediate-objects","page":"Data simulation","title":"Intermediate objects","text":"","category":"section"},{"location":"API/simulation/","page":"Data simulation","title":"Data simulation","text":"matern\n\nmaternchols\n\nincgammalower\n\nfₛ","category":"page"},{"location":"API/simulation/#NeuralEstimators.matern","page":"Data simulation","title":"NeuralEstimators.matern","text":"matern(h, ρ, ν, σ² = 1)\n\nFor two points separated by h units, compute the Matérn covariance function with range ρ, smoothness ν, and marginal variance σ².\n\nWe use the parametrisation C(mathbfh) = sigma^2 frac2^1 - nuGamma(nu) left(fracmathbfhrhoright) K_nu left(fracmathbfhrhoright), where Gamma(cdot) is the gamma function, and K_nu(cdot) is the modified Bessel function of the second kind of order nu. This parameterisation is the same as used by the R package fields, but differs to the parametrisation given by Wikipedia.\n\nNote that the Julia functions for Gamma(cdot) and K_nu(cdot), respectively gamma() and besselk(), do not work on the GPU and, hence, nor does matern().\n\n\n\n\n\n","category":"function"},{"location":"API/simulation/#NeuralEstimators.maternchols","page":"Data simulation","title":"NeuralEstimators.maternchols","text":"maternchols(D, ρ, ν)\n\nGiven a distance matrix D, computes the covariance matrix Σ under the Matérn covariance function with range ρ and smoothness ν, and return the Cholesky factor of this matrix.\n\nProviding vectors for ρ and ν will yield a three-dimensional array of Cholesky factors.\n\n\n\n\n\n","category":"function"},{"location":"API/simulation/#NeuralEstimators.incgammalower","page":"Data simulation","title":"NeuralEstimators.incgammalower","text":"incgammalower(a, x)\n\nFor positive a and x, computes the lower incomplete gamma function, gamma(a x) = int_0^x t^a-1e^-tdt.\n\n\n\n\n\n","category":"function"},{"location":"API/simulation/#NeuralEstimators.fₛ","page":"Data simulation","title":"NeuralEstimators.fₛ","text":"fₛ(x, μ, τ, δ)\nFₛ(q, μ, τ, δ)\nFₛ⁻¹(p, μ, τ, δ)\n\nThe density, distribution, and quantile functions Subbotin (delta-Laplace) distribution with location parameter μ, scale parameter τ, and shape parameter δ:\n\n f_S(y mu tau delta) = fracdelta2tau Gamma(1delta) expleft(-leftfracy - mutauright^deltaright)\n F_S(y mu tau delta) = frac12 + textrmsign(y - mu) frac12 Gamma(1delta) gammaleft(1delta leftfracy - mutauright^deltaright)\n F_S^-1(p mu tau delta) = textsign(p - 05)G^-1left(2p - 05 frac1delta frac1(ktau)^deltaright)^1delta + mu\n\nwith gamma(cdot) and G^-1(cdot) the unnormalised incomplete lower gamma function and quantile function of the Gamma distribution, respectively.\n\nExamples\n\np = [0.025, 0.05, 0.5, 0.9, 0.95, 0.975]\n\n# Standard Gaussian:\nμ = 0.0; τ = sqrt(2); δ = 2.0\nFₛ⁻¹.(p, μ, τ, δ)\n\n# Standard Laplace:\nμ = 0.0; τ = 1.0; δ = 1.0\nFₛ⁻¹.(p, μ, τ, δ)\n\n\n\n\n\n","category":"function"},{"location":"API/#Index","page":"Index","title":"Index","text":"","category":"section"},{"location":"API/","page":"Index","title":"Index","text":"","category":"page"},{"location":"related/","page":"-","title":"-","text":"You may also be interested in the Julia packages Flux (the deep learning framework this package is built upon), Turing (for general-purpose probabilistic programming), and Mill (for generalised multiple-instance learning models). ","category":"page"},{"location":"workflow/advanced/#Advanced-usage","page":"Advanced usage","title":"Advanced usage","text":"","category":"section"},{"location":"workflow/advanced/#Balancing-time-and-memory-complexity","page":"Advanced usage","title":"Balancing time and memory complexity","text":"","category":"section"},{"location":"workflow/advanced/","page":"Advanced usage","title":"Advanced usage","text":"\"On-the-fly\" simulation refers to simulating new values for the parameters, θ, and/or the data, Z, continuously during training. \"Just-in-time\" simulation refers to simulating small batches of parameters and data, training the neural estimator with this small batch, and then removing the batch from memory.   ","category":"page"},{"location":"workflow/advanced/","page":"Advanced usage","title":"Advanced usage","text":"There are three variants of on-the-fly and just-in-time simulation, each with advantages and disadvantages.","category":"page"},{"location":"workflow/advanced/","page":"Advanced usage","title":"Advanced usage","text":"Resampling θ and Z every epoch. This approach is the most theoretically justified and has the best memory complexity, since both θ and Z can be simulated just-in-time, but it has the worst time complexity.\nResampling θ every x epochs, resampling Z every epoch. This approach can reduce time complexity if generating θ (or intermediate objects thereof) dominates the computational cost. Further, memory complexity may be kept low since Z can still be simulated just-in-time.\nResampling θ every x epochs, resampling Z every y epochs, where x is a multiple of y. This approach minimises time complexity but has the largest memory complexity, since both θ and Z must be stored in full. Note that fixing θ and Z (i.e., setting y = ∞) often leads to worse out-of-sample performance and, hence, is generally discouraged.","category":"page"},{"location":"workflow/advanced/","page":"Advanced usage","title":"Advanced usage","text":"The keyword arguments epochs_per_θ_refresh and epochs_per_Z_refresh in train() are intended to cater for these simulation variants.","category":"page"},{"location":"workflow/advanced/#Loading-previously-saved-estimators","page":"Advanced usage","title":"Loading previously saved estimators","text":"","category":"section"},{"location":"workflow/advanced/#Reusing-intermediate-objects-(e.g.,-Cholesky-factors)-for-multiple-parameter-configurations","page":"Advanced usage","title":"Reusing intermediate objects (e.g., Cholesky factors) for multiple parameter configurations","text":"","category":"section"},{"location":"workflow/advanced/","page":"Advanced usage","title":"Advanced usage","text":"Use the Gaussian process example. ","category":"page"},{"location":"workflow/advanced/#Piece-wise-estimators-conditional-on-the-sample-size","page":"Advanced usage","title":"Piece-wise estimators conditional on the sample size","text":"","category":"section"},{"location":"workflow/advanced/#Bootstrapping-with-real-data","page":"Advanced usage","title":"Bootstrapping with real data","text":"","category":"section"},{"location":"workflow/overview/#Workflow-overview","page":"Overview","title":"Workflow overview","text":"","category":"section"},{"location":"workflow/overview/","page":"Overview","title":"Overview","text":"To develop a neural estimator with NeuralEstimators.jl,","category":"page"},{"location":"workflow/overview/","page":"Overview","title":"Overview","text":"Create an object ξ containing invariant model information, that is, model information that does not depend on the parameters and hence stays constant during training (e.g, the prior distribution of the parameters, spatial locations, distance matrices, etc.).\nDefine a type Parameters <: ParameterConfigurations containing a compulsory field θ storing K parameter vectors as a p × K matrix, with p the dimension of θ, as well as any other intermediate objects associated with the parameters (e.g., Cholesky factors) that are needed for data simulation.\nDefine a Parameters constructor Parameters(ξ, K::Integer), which draws K parameters from the prior.\nImplicitly define the statistical model by overloading the function simulate.\nInitialise neural networks ψ and ϕ, and a DeepSet object θ̂ = DeepSet(ψ, ϕ).\nTrain θ̂ using train under an arbitrary loss function.\nTest θ̂ using estimate.","category":"page"},{"location":"workflow/overview/","page":"Overview","title":"Overview","text":"For clarity, see a Simple example and a More complicated example. Once familiar with the basic workflow, see Advanced usage for some important practical considerations and how to construct neural estimators most effectively.","category":"page"},{"location":"motivation/#Motivation","page":"Motivation","title":"Motivation","text":"","category":"section"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"Definition of an estimator:","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"hatmathbftheta  mathcalS^m to Theta","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"Permutation invariance:","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"hatmathbftheta(mathbfZ_1 dots mathbfZ_m) = hatmathbftheta(mathbfZ_pi(1) dots mathbfZ_pi(m))","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"Under some arbitrary loss function L(mathbftheta hatmathbftheta(mathcalZ)), the risk function:","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"R(mathbftheta hatmathbftheta(cdot)) equiv int_mathcalS^m  L(mathbftheta hatmathbftheta(mathcalZ))p(mathcalZ mid mathbftheta) d mathcalZ","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"Weighted average risk function:","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"r_Omega(hatmathbftheta(cdot))\nequiv int_Theta R(mathbftheta hatmathbftheta(cdot)) dOmega(mathbftheta)  ","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"Deep Set (Zaheer et al., 2017) representation of an estimator:","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"beginaligned\nhatmathbftheta(mathcalZ) = mathbfphi(mathbfT(mathcalZ)) \nmathbfT(mathcalZ)  = sum_mathbfZ in mathcalZ mathbfpsi(mathbfZ)\nendaligned","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"Optimisation task:","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"hatmathbftheta_mathbfgamma^*(cdot)\nmathbfgamma^*\nequiv\nundersetmathbfgammamathrmargmin  r_Omega(hatmathbftheta_mathbfgamma(cdot))","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"Monte Carlo approximation of the weighted average risk:","category":"page"},{"location":"motivation/","page":"Motivation","title":"Motivation","text":"r_Omega(hatmathbftheta(cdot))\napprox\nfrac1K sum_k = 1^K frac1J sum_j = 1^J L(mathbftheta_k hatmathbftheta(mathcalZ_kj))  ","category":"page"},{"location":"API/core/#Core-functions","page":"Core functions","title":"Core functions","text":"","category":"section"},{"location":"API/core/#Parameters","page":"Core functions","title":"Parameters","text":"","category":"section"},{"location":"API/core/","page":"Core functions","title":"Core functions","text":"ParameterConfigurations\n\nsubsetparameters","category":"page"},{"location":"API/core/#NeuralEstimators.ParameterConfigurations","page":"Core functions","title":"NeuralEstimators.ParameterConfigurations","text":"ParameterConfigurations\n\nAn abstract supertype for storing parameters θ and any intermediate objects needed for data simulation with simulate.\n\n\n\n\n\n","category":"type"},{"location":"API/core/#NeuralEstimators.subsetparameters","page":"Core functions","title":"NeuralEstimators.subsetparameters","text":"subsetparameters(parameters::Parameters, indices) where {Parameters <: ParameterConfigurations}\n\nSubset parameters using a collection of indices.\n\nThe default method assumes that each field of parameters is an array with the last dimension corresponding to the parameter configurations (i.e., it subsets over the last dimension of each array). If this is not the case, define an appropriate subsetting method by overloading subsetparameters after running import NeuralEstimators: subsetparameters.\n\n\n\n\n\n","category":"function"},{"location":"API/core/#Simulation","page":"Core functions","title":"Simulation","text":"","category":"section"},{"location":"API/core/","page":"Core functions","title":"Core functions","text":"simulate","category":"page"},{"location":"API/core/#NeuralEstimators.simulate","page":"Core functions","title":"NeuralEstimators.simulate","text":"simulate(parameters::P, ξ, m::Integer, num_rep::Integer) where {P <: ParameterConfigurations}\n\nGeneric method that simulates num_rep sets of  sets of m independent replicates for each parameter configuration by calling simulate(parameters, ξ, m).\n\nSee also Data simulation.\n\n\n\n\n\n","category":"function"},{"location":"API/core/#Deep-Set-representation","page":"Core functions","title":"Deep Set representation","text":"","category":"section"},{"location":"API/core/#Vanilla-Deep-Set","page":"Core functions","title":"Vanilla Deep Set","text":"","category":"section"},{"location":"API/core/","page":"Core functions","title":"Core functions","text":"DeepSet\n\nDeepSet(ψ, ϕ; aggregation::String)","category":"page"},{"location":"API/core/#NeuralEstimators.DeepSet","page":"Core functions","title":"NeuralEstimators.DeepSet","text":"DeepSet(ψ, ϕ, agg)\n\nImplementation of the Deep Set framework, where ψ and ϕ are neural networks (e.g., Flux networks) and agg is a symmetric function that pools data over the last dimension (the replicates/batch dimension) of an array.\n\nDeepSet objects are applied to AbstractVectors of AbstractArrays, where each array is associated with one parameter vector.\n\nExamples\n\nn = 10 # observations in each realisation\np = 5  # number of parameters in the statistical model\nw = 32 # width of each layer\nψ = Chain(Dense(n, w, relu), Dense(w, w, relu));\nϕ = Chain(Dense(w, w, relu), Dense(w, p));\nagg(X) = sum(X, dims = ndims(X))\nθ̂  = DeepSet(ψ, ϕ, agg)\n\n# A single set of m=3 realisations:\nZ = [rand(n, 1, 3)];\nθ̂ (Z)\n\n# Two sets each containing m=3 realisations:\nZ = [rand(n, 1, m) for m ∈ (3, 3)];\nθ̂ (Z)\n\n# Two sets respectivaly containing m=3 and m=4 realisations:\nZ = [rand(n, 1, m) for m ∈ (3, 4)];\nθ̂ (Z)\n\n\n\n\n\n","category":"type"},{"location":"API/core/#NeuralEstimators.DeepSet-Tuple{Any, Any}","page":"Core functions","title":"NeuralEstimators.DeepSet","text":"DeepSet(ψ, ϕ; aggregation::String = \"mean\")\n\nConvenient constructor for a DeepSet object with agg equal to the \"mean\", \"sum\", or \"logsumexp\" function.\n\n\n\n\n\n","category":"method"},{"location":"API/core/#Deep-Set-with-expert-summary-statistics","page":"Core functions","title":"Deep Set with expert summary statistics","text":"","category":"section"},{"location":"API/core/","page":"Core functions","title":"Core functions","text":"DeepSetExpert\n\nDeepSetExpert(deepset::DeepSet, ϕ, S)\n\nDeepSetExpert(ψ, ϕ, S; aggregation::String)\n\nsamplesize","category":"page"},{"location":"API/core/#NeuralEstimators.DeepSetExpert","page":"Core functions","title":"NeuralEstimators.DeepSetExpert","text":"DeepSetExpert(ψ, ϕ, S, agg)\n\nImplementation of the Deep Set framework with ψ and ϕ neural networks, agg a symmetric function that pools data over the last dimension of an array, and S a vector of real-valued functions that serve as expert summary statistics.\n\nThe dimension of the domain of ϕ should be qₜ + qₛ, where qₜ is the range of ϕ and qₛ is the dimension of S, that is, length(S). DeepSetExpert objects are applied to AbstractVectors of AbstractArrays, where each array is associated with one parameter vector. The functions ψ and S both act on these arrays individually (i.e., they are broadcasted over the AbstractVector).\n\n\n\n\n\n","category":"type"},{"location":"API/core/#NeuralEstimators.DeepSetExpert-Tuple{DeepSet, Any, Any}","page":"Core functions","title":"NeuralEstimators.DeepSetExpert","text":"DeepSetExpert(deepset::DeepSet, ϕ, S)\n\nDeepSetExpert constructor with the aggregation function agg and inner neural network ψ inherited from deepset.\n\nNote that we cannot inherit the outer network, ϕ, since DeepSetExpert objects require the dimension of the domain of ϕ to be qₜ + qₛ.\n\n\n\n\n\n","category":"method"},{"location":"API/core/#NeuralEstimators.DeepSetExpert-Tuple{Any, Any, Any}","page":"Core functions","title":"NeuralEstimators.DeepSetExpert","text":"DeepSetExpert(ψ, ϕ, S; aggregation::String = \"mean\")\n\nDeepSetExpert constructor with agg equal to the \"mean\", \"sum\", or \"logsumexp\" function.\n\n\n\n\n\n","category":"method"},{"location":"API/core/#NeuralEstimators.samplesize","page":"Core functions","title":"NeuralEstimators.samplesize","text":"samplesize(x::A) where {A <: AbstractArray{T, N}} where {T, N}\n\nComputes the sample size m for a set of independent realisations Z, useful as an expert summary statistic in DeepSetExpert objects.\n\n\n\n\n\n","category":"function"},{"location":"API/core/#Piecewise-Deep-Set-neural-estimators","page":"Core functions","title":"Piecewise Deep Set neural estimators","text":"","category":"section"},{"location":"API/core/","page":"Core functions","title":"Core functions","text":"DeepSetPiecewise","category":"page"},{"location":"API/core/#NeuralEstimators.DeepSetPiecewise","page":"Core functions","title":"NeuralEstimators.DeepSetPiecewise","text":"DeepSetPiecewise(estimators, m_cutoffs)\n\nGiven an arbitrary number of estimators, creates a piecewise neural estimator based on the sample size cut offs, m_cutoffs, which should contain one element fewer than the number of estimators.\n\nExamples\n\nSuppose that we have two neural estimators, θ̂₁ and θ̂₂, taking the following arbitrary forms:\n\nn = 10\np = 5\nw = 32\n\nψ₁ = Chain(Dense(n, w, relu), Dense(w, w, relu));\nϕ₁ = Chain(Dense(w, w, relu), Dense(w, p));\nθ̂₁ = DeepSet(ψ₁, ϕ₁)\n\nψ₂ = Chain(Dense(n, w, relu), Dense(w, w, relu), Dense(w, w, relu));\nϕ₂ = Chain(Dense(w, w, relu), Dense(w, w, relu), Dense(w, p));\nθ̂₂ = DeepSet(ψ₂, ϕ₂)\n\nFurther suppose that we've trained θ̂₁ for small sample sizes (e.g., m ≦ 30) and θ̂₂ for moderate-to-large sample sizes (e.g., m > 30). Then we construct a piecewise Deep Set object with a cut-off sample size of 30 which dispatches θ̂₁ if m ≤ 30 and θ̂₂ if m > 30:\n\nθ̂ = DeepSetPiecewise((θ̂₁, θ̂₂), (30,))\nZ = [rand(Float32, n, 1, m) for m ∈ (10, 50)]\nθ̂(Z)\n\n\n\n\n\n","category":"type"},{"location":"API/core/#Training","page":"Core functions","title":"Training","text":"","category":"section"},{"location":"API/core/","page":"Core functions","title":"Core functions","text":"There are two training methods. For both methods, the validation parameters and validation data are held fixed so that the validation risk is interpretable. There are a number of practical considerations to keep in mind: In particular, see Balancing time and memory complexity.","category":"page"},{"location":"API/core/","page":"Core functions","title":"Core functions","text":"train","category":"page"},{"location":"API/core/#NeuralEstimators.train","page":"Core functions","title":"NeuralEstimators.train","text":"train(θ̂, ξ, P; <keyword args>) where {P <: ParameterConfigurations}\n\nTrain the neural estimator θ̂ by providing the invariant model information ξ needed for the constructor P to automatically sample the sets of training and validation parameters.\n\nKeyword arguments common to both train methods:\n\nm: sample sizes (either an Integer or a collection of Integers).\nbatchsize::Integer = 32\nepochs::Integer = 100: the maximum number of epochs used during training.\nepochs_per_Z_refresh::Integer = 1: how often to refresh the training data.\nloss = mae: the loss function, which should return an average loss when applied to multiple replicates.\noptimiser = ADAM(1e-4)\nsavepath::String = \"runs/\": path to save the trained θ̂ and other information; if savepath is an empty string (i.e., \"\"), nothing is saved.\nstopping_epochs::Integer = 10: halt training if the risk doesn't improve in stopping_epochs epochs.\nuse_gpu::Bool = true\nverbose::Bool = true\n\nSimulator keyword arguments only:\n\nK::Integer = 10_000: the number of parameters in the training set; the size of the validation set is K ÷ 5.\nepochs_per_θ_refresh::Integer = 1: how often to refresh the training parameters; this must be a multiple of epochs_per_Z_refresh.\n\n\n\n\n\ntrain(θ̂, ξ, θ_train::P, θ_val::P; <keyword args>) where {P <: ParameterConfigurations}\n\nTrain the neural estimator θ̂ by providing the training and validation sets explicitly as θ_train and θ_val, which are both held fixed during training, as well as the invariant model information ξ.\n\n\n\n\n\n","category":"function"},{"location":"API/core/#Estimation","page":"Core functions","title":"Estimation","text":"","category":"section"},{"location":"API/core/","page":"Core functions","title":"Core functions","text":"estimate\n\nEstimates\n\nmerge(::Estimates)","category":"page"},{"location":"API/core/#NeuralEstimators.estimate","page":"Core functions","title":"NeuralEstimators.estimate","text":"estimate(estimators, parameters::P, m; <keyword args>) where {P <: ParameterConfigurations}\n\nUsing a collection of estimators, compute estimates from data simulated from a set of parameters with invariant information ξ.\n\nNote that estimate() requires the user to have defined a method simulate(parameters, ξ, m::Integer).\n\nKeyword arguments\n\nm::Vector{Integer} where I <: Integer: sample sizes to estimate from.\nestimator_names::Vector{String}: names of the estimators (sensible default values provided).\nparameter_names::Vector{String}: names of the parameters (sensible default values provided).\nnum_rep::Integer = 1: the number of times to replicate each parameter in parameters.\nuse_ξ = false: a Bool or a collection of Bool objects with length equal to the number of estimators. Specifies whether or not the estimator uses the invariant model information, ξ: If it does, the estimator will be applied as estimator(Z, ξ).\nuse_gpu = true: a Bool or a collection of Bool objects with length equal to the number of estimators.\nverbose::Bool = true\n\n\n\n\n\n","category":"function"},{"location":"API/core/#NeuralEstimators.Estimates","page":"Core functions","title":"NeuralEstimators.Estimates","text":"Estimates(θ, θ̂, runtime)\n\nA set of true parameters θ, corresponding estimates θ̂, and the runtime to obtain θ̂, as returned by a call to estimate.\n\n\n\n\n\n","category":"type"},{"location":"API/core/#Base.merge-Tuple{Estimates}","page":"Core functions","title":"Base.merge","text":"merge(estimates::Estimates)\n\nMerge estimates into a single long-form DataFrame containing the true parameters and the corresponding estimates.\n\n\n\n\n\n","category":"method"},{"location":"API/core/#Bootstrapping","page":"Core functions","title":"Bootstrapping","text":"","category":"section"},{"location":"API/core/","page":"Core functions","title":"Core functions","text":"Note that all bootstrapping functions are currently implemented for a single parameter configuration only.","category":"page"},{"location":"API/core/","page":"Core functions","title":"Core functions","text":"parametricbootstrap\n\nnonparametricbootstrap","category":"page"},{"location":"API/core/#NeuralEstimators.parametricbootstrap","page":"Core functions","title":"NeuralEstimators.parametricbootstrap","text":"parametricbootstrap(θ̂, parameters::P, ξ, m::Integer; B::Integer = 100, use_gpu::Bool = true) where {P <: ParameterConfigurations}\n\nReturns B parameteric bootstrap samples of an estimator θ̂ as a p × B matrix, where p is the number of parameters in the statistical model, based on data sets of size m simulated using the invariant model information ξ and parameter configurations, parameters.\n\nThis function requires the user to have defined a method simulate(parameters::P, ξ, m::Integer).\n\n\n\n\n\n","category":"function"},{"location":"API/core/#NeuralEstimators.nonparametricbootstrap","page":"Core functions","title":"NeuralEstimators.nonparametricbootstrap","text":"nonparametricbootstrap(θ̂, Z::AbstractArray{T, N}; B::Integer = 100, use_gpu::Bool = true)\nnonparametricbootstrap(θ̂, Z::AbstractArray{T, N}, blocks; B::Integer = 100, use_gpu::Bool = true)\n\nReturns B non-parametric bootstrap samples of an estimator θ̂ as a p × B matrix, where p is the number of parameters in the statistical model.\n\nThe argument blocks caters for block bootstrapping, and should be an integer vector specifying the block for each replicate. For example, if we have 5 replicates with the first two replicates corresponding to block 1 and the remaining replicates corresponding to block 2, then blocks should be [1, 1, 2, 2, 2]. The resampling algorithm tries to produce resampled data sets of a similar size to the original data, but this can only be achieved exactly if the blocks are the same length.\n\n\n\n\n\n","category":"function"},{"location":"API/utility/#Utility-functions","page":"Utility functions","title":"Utility functions","text":"","category":"section"},{"location":"API/utility/","page":"Utility functions","title":"Utility functions","text":"loadbestweights\n\nstackarrays\n\nexpandgrid","category":"page"},{"location":"API/utility/#NeuralEstimators.loadbestweights","page":"Utility functions","title":"NeuralEstimators.loadbestweights","text":"loadbestweights(path::String)\n\nGiven a path to a training run containing neural networks saved with names 'networkepochx.bson' and an object saved as 'lossper_epoch.bson',  returns the weights of the best network (measured by validation loss).\n\n\n\n\n\n","category":"function"},{"location":"API/utility/#NeuralEstimators.stackarrays","page":"Utility functions","title":"NeuralEstimators.stackarrays","text":"stackarrays(v::V; merge::Bool = true) where {V <: AbstractVector{A}} where {A <: AbstractArray{T, N}} where {T, N}\n\nStack a vector of arrays v along the last dimension of each array, optionally merging the final dimension of the stacked array.\n\nThe arrays must be of the same for the first N-1 dimensions. However, if merge = true, the size of the final dimension can vary between arrays.\n\nExamples\n\n# Vector containing arrays of the same size:\nZ = [rand(2, 3, m) for m ∈ (1, 1)];\nstackarrays(Z)\nstackarrays(Z, merge = false)\n\n# Vector containing arrays with differing final dimension size:\nZ = [rand(2, 3, m) for m ∈ (1, 2)];\nstackarrays(Z)\n\n\n\n\n\n","category":"function"},{"location":"API/utility/#NeuralEstimators.expandgrid","page":"Utility functions","title":"NeuralEstimators.expandgrid","text":"expandgrid(xs, ys)\n\nSame as expand.grid() in R, but currently caters for two dimensions only.\n\n\n\n\n\n","category":"function"},{"location":"workflow/morecomplicated/#More-complicated-example","page":"More complicated example","title":"More complicated example","text":"","category":"section"},{"location":"workflow/morecomplicated/","page":"More complicated example","title":"More complicated example","text":"In this example, we'll consider a standard spatial model, the linear Gaussian-Gaussian model,","category":"page"},{"location":"workflow/morecomplicated/","page":"More complicated example","title":"More complicated example","text":"Z_i = Y(mathbfs_i) + epsilon_i quad  i = 1 dots n","category":"page"},{"location":"workflow/morecomplicated/","page":"More complicated example","title":"More complicated example","text":"where mathbfZ equiv (Z_1 dots Z_n)^top are data observed at locations mathbfs_1 dots mathbfs_n subset mathcalD, Y(cdot) is a spatially-correlated mean-zero Gaussian process, and epsilon_i sim rmN(0 sigma^2_epsilon) is Gaussian white noise with sigma^2_epsilon the measurement-error variance parameter. An important component of the model is the covariance function, C(mathbfs mathbfu) equiv rmcov(Y(mathbfs) Y(mathbfu)), for mathbfs mathbfu in mathcalD, which is the primary mechanism for capturing spatial dependence. Here, we use the popular isotropic Matérn covariance function,","category":"page"},{"location":"workflow/morecomplicated/","page":"More complicated example","title":"More complicated example","text":" C(mathbfh) = sigma^2 frac2^1 - nuGamma(nu) left(fracmathbfhrhoright) K_nu left(fracmathbfhrhoright)","category":"page"},{"location":"workflow/morecomplicated/","page":"More complicated example","title":"More complicated example","text":"where sigma is the marginal variance parameter, Gamma(cdot) is the gamma function, K_nu(cdot) is the Bessel function of the second kind of order nu, and rho  0 and nu  0 are the range and smoothness parameters, respectively. We follow the common practice decision to fix sigma to 1, which leaves three unknown parameters that need to be estimated: mathbftheta equiv (sigma^2_epsilon rho nu)top.","category":"page"},{"location":"workflow/simple/#Simple-example","page":"Simple example","title":"Simple example","text":"","category":"section"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"Perhaps the simplest estimation task involves inferring μ from N(μ, σ) data, where σ is known, and this is the model that we consider. Specifically, we will develop a neural estimator for μ, where","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"μ sim N(0 05) quad mathcalZ equiv Z_1 dots Z_m  Z_i sim N(μ 1)","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"The first step is to define an object ξ that contains invariant model information. In this example, we have two invariant objects: The prior distribution of the parameters, Ω, and the standard deviation, σ.","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"using Distributions\nξ = (Ω = Normal(0, 0.5), σ = 1)","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"Next, we define a subtype of ParameterConfigurations, say, Parameters (the name is arbitrary); for the current model, Parameters need only stores the sampled parameters, which must be held in a field named θ:","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"using NeuralEstimators\nstruct Parameters <: ParameterConfigurations\n\tθ\nend","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"We then define a Parameters constructor, returning K draws from Ω:","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"function Parameters(ξ, K::Integer)\n\tθ = rand(ξ.Ω, 1, K)\n\tParameters(θ)\nend","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"Next, we implicitly define the statistical model by overloading simulate as follows.","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"import NeuralEstimators: simulate\nfunction simulate(parameters::Parameters, ξ, m::Integer)\n\tθ = vec(parameters.θ)\n\tZ = [rand(Normal(μ, ξ.σ), 1, 1, m) for μ ∈ θ]\nend","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"There is some flexibility in the permitted type of the sample size m (e.g., Integer, IntegerRange, etc.), but simulate must return an AbstractVector of (multi-dimensional) AbstractArrays, where each array is associated with one parameter vector (i.e., one column of parameters.θ). Note also that the size of each array must be amenable to Flux neural networks; for instance, above we return a 3-dimensional array, even though the second dimension is redundant.","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"We then choose an architecture for modelling ψ(⋅) and ϕ(⋅) in the Deep Set framework, and initialise the neural estimator as a DeepSet object.","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"p = 1\nw = 32\nq = 16\nψ = Chain(Dense(n, w, relu), Dense(w, q, relu))\nϕ = Chain(Dense(q, w, relu), Dense(w, p), flatten)\nθ̂ = DeepSet(ψ, ϕ)","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"Next, we train the neural estimator using train. The argument m specifies the sample size used during training, and its type should be consistent with the simulate method defined above. There are two methods for train: Below, we provide the invariant model information ξ and the type Parameters, so that parameter configurations will be automatically and continuously sampled during training.","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"θ̂ = train(θ̂, ξ, Parameters, m = 10)","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"The estimator θ̂ now approximates the Bayes estimator. It's usually a good idea to assess the performance of the estimator before putting it into practice. Since the performance of θ̂ for particular values of θ may be of particular interest, estimate takes an instance of Parameters.","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"parameters = Parameters(ξ, 500)                   # test set with 500 parameters\nm          = [1, 10, 30]                          # sample sizes we wish to test\nestimates  = estimate(θ̂, ξ, parameters, m = m)  ","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"The true parameters, estimates, and timings from this test run are returned in an Estimates object (each field is a DataFrame corresponding to the parameters, estimates, or timings). The true parameters and estimates may be merged into a convenient long-form DataFrame, and this greatly facilitates visualisation and diagnostic computation:","category":"page"},{"location":"workflow/simple/","page":"Simple example","title":"Simple example","text":"merged_df = merge(estimates)","category":"page"},{"location":"#NeuralEstimators-documentation","page":"Home","title":"NeuralEstimators documentation","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Landing page and brief description of neural estimators as a recent likelihood-inference approach, and an alternative to ABC.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Say how to install the package.","category":"page"}]
}
