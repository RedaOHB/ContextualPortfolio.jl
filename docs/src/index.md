# [ContextualPortfolio.jl documentation](@id Home)
* A julia package for contextual optimization and backtesting 

## Overview
```ContextualPortfolio.jl``` is a Julia package for portfolio optimization that incorporate external factors into the decision-making process. The package supports multiple optimization models including mean-variance, and robust optimization. It provides comprehensive tools for performance evaluation and backtesting.

Contextual optimization is an approach where decisions are tailored based on specific contextual information. In portfolio selection, the traditional problem seeks to determine optimal asset weights that maximize (or minimize) a specific objective function. Contextual optimization extends this framework by incorporating external information such as market conditions, economic indicators, or other relevant features directly into the optimization process.

This framework, formalized by Nguyen et al. (2024), proposed conditioning the optimization on the conditional distribution of returns given contextual information, leading to better out-of-sample performance compared to traditional approaches that separate prediction from optimization.

```ContextualPortfolio.jl``` implements this framework across multiple optimization models, providing a unified interface for contextual portfolio selection.


Consider the standard mean-variance model. The contextual optimization problem can be formulated as:
```math
\begin{equation*}
\begin{split}
    \min_x \  \quad & - \boldsymbol{\mu}_{r\,|\,s}^{T} . \boldsymbol{x} + \eta \boldsymbol{x}^{T} \boldsymbol{\Sigma}_{r\,|\,s} \boldsymbol{x}\\
    \text{s.t.} \quad & \boldsymbol{1}^{T} \boldsymbol{x} = 1\\
    & \boldsymbol{x} \geq \boldsymbol{0},
\end{split}
\end{equation*}
```

where: 
* $\mathbf{\mu}_{r|s}$ is conditional expected return given context $s$.
* $\mathbf{\Sigma}_{r|s}$ representes conditional covariance matrix given context $s$.
* $\mathbf{x}$ is the vector of portfolio weights.              

## Installation
```ContextualPortfolio.jl``` can be installed using Julia's package manager:
```julia
using Pkg
Pkg.add("ContextualPortfolio")
```

Or for the development version: 
```julia
using Pkg
Pkg.add(url="https://github.com/RedaOHB/ContextualPortfolio.jl")
```

## Basic usage
Using ```ContextualPortfolio.jl``` follows a simple three-step process:
1. Prepare your asset returns and contextual data
2. Specify an optimization model
3. Call the solver function with your parameters

For detailed examples and comprehensive tests, see the [Tutorial](@ref) page. Additional test cases demonstrating package functionality can be found in the [test directory](https://github.com/RedaOHB/ContextualPortfolio.jl/test).

## Algorithm description
```ContextualPortfolio.jl``` incorporates periodic portfolio rebalancing using a rolling window approach. This allows the portfolio to adapt dynamically to changing market conditions while maintaining computational efficiency.
 
A complete description of the methodology is provided in the [Method](@ref) section.

## Documentation Overview
```@contents
Pages = [
    "index.md",
    "method.md",
    "tutorial.md",
    "api.md",
]
Depth = 2
```

## Citation

If you use ContextualPortfolio.jl in your research, please cite:         

```bibtex  
@article{RedaOuahib2026,
  title={ContextualPortfolio.jl: A Julia Package for contextual optimization},
  author={Reda Ouahib and Fabian Bastin},
  journal={Journal of Open Source Software},
  year={2026},
  note={Submitted}
}
```




