using Documenter
using ContextualPortfolio

makedocs(
    sitename = "ContextualPortfolio.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [ContextualPortfolio],
    pages = [
        "Home" => "index.md",
        "Method" => "method.md",
        "Tutorial" => "tutorial.md",
        "API Reference" => "api.md"
    ]
)

deploydocs(
    repo = "github.com/RedaOHB/ContextualPortfolio.jl.git",
    devbranch = "main"
)