using Documenter
using ContextualOptimization

makedocs(
    sitename = "ContextualOptimization.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [ContextualOptimization],
    pages = [
        "Home" => "index.md",
        "Method" => "method.md",
        "Tutorial" => "tutorial.md",
        "API Reference" => "api.md",
        "Examples" => "examples.md"
    ]
)

deploydocs(
    repo = "github.com/RedaOHB/ContextualOptimization.jl.git",
    devbranch = "main"
)