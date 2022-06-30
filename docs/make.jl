push!(LOAD_PATH,"../src/")
using Documenter, NeuralEstimators

makedocs(
    sitename="NeuralEstimators.jl",
    pages = [
           "Home" => "index.md",
           "motivation.md",
           "Workflow" => [
                "Overview" => "workflow/overview.md",
                "Simple example" => "workflow/simpleexample.md",
                "More complicated example" => "workflow/morecomplicatedexample.md",
                "Advanced usage" => "workflow/advancedusage.md"
           ],
           "API" => [
                "Core functions" => "API/core.md",
                "Data simulation" => "API/simulation.md",
                "Utility functions" => "API/utility.md",
                "Index" => "API/index.md"
           ]
       ]
)


deploydocs(;
    repo="github.com/msainsburydale/NeuralEstimators.jl",
)
