module NeuralEstimators

# Note that functions must be explicitly imported to be extended with new
# methods. Be aware of type piracy, though.
using Base: @propagate_inbounds
using Base.GC: gc
using BSON: @save, load
using CUDA
using CSV
using DataFrames
using Distributions: Gamma, Normal, cdf, quantile
using Flux
using Flux.Data: DataLoader
using Flux.Optimise: update!
using Functors: @functor
using LinearAlgebra
using Random: randexp
using RecursiveArrayTools: VectorOfArray, convert
using SpecialFunctions: besselk, gamma
using Statistics: mean, median, sum
using Zygote

export ParameterConfigurations
include("ParameterConfigurations.jl")

export DeepSet
include("DeepSet.jl")

export simulate, simulategaussianprocess, simulateschlather, simulateconditionalextremes, matern, fₛ, Fₛ, Fₛ⁻¹
include("DataSimulation.jl")
export incgammalower
include("IncGammaLower.jl")

export train
include("Train.jl")

export estimate
include("Estimate.jl")

export parametricbootstrap, nonparametricbootstrap
include("Bootstrap.jl")

export stack, expandgrid
include("UtilityFunctions.jl")

end
