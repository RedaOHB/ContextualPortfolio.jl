# Contributing to ContextualPortfolio.jl

Thank you for your interest in contributing to ContextualPortfolio.jl!

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request, please open an issue on the
[GitHub issue tracker](https://github.com/RedaOHB/ContextualPortfolio.jl/issues).
Include:

- A clear description of the problem or feature
- A minimal reproducible example (if reporting a bug)
- The versions of Julia and ContextualPortfolio.jl you are using

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Add or update tests as appropriate
5. Ensure all tests pass (`julia --project -e 'using Pkg; Pkg.test()'`)
6. Commit your changes with a clear message
7. Push to your fork and open a Pull Request

### Development Setup

```julia
using Pkg
Pkg.develop(url="https://github.com/RedaOHB/ContextualPortfolio.jl")
```

### Code Style

- Follow standard Julia naming conventions
- Add docstrings to all public functions
- Include tests for new functionality

### Adding Optimization Models

New optimization models should:

1. Accept an `optimizer` keyword argument (default `Clarabel.Optimizer`)
2. Use solver-agnostic JuMP functions (`set_silent`, `set_time_limit_sec`)
3. Include a docstring with the mathematical formulation
4. Be added to `src/models.jl` and exported in `src/ContextualPortfolio.jl`
5. Have corresponding tests in `test/test_models.jl`

## Questions

For questions about usage or development, please open an issue on GitHub.
