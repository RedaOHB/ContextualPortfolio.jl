# ContextualOptimization.jl 
* A julia package for contextual optimization and backtesting * 

## Overview
```ContextualOptimization.jl``` is a julia package for portfolio optimization that incorporate external factors into the decision-making process. The package supports multiple optimization models including mean-variance, CVaR, and robust optimization. It provides comprehensive tools for performance evaluation and backtesting.

Contextual optimization is an approach where decisions are tailored based on specific contextual information. In portfolio selection, the traditional problem seeks to determine optimal asset weights that maximize (or minimize) a specific objective function. Contextual optimization extends this framework by incorporating external information such as market conditions, economic indicators, or other relevant features directly into the optimization process.

This framework, formalized by Nguyen et al., proposed conditioning the optimization on the conditional distribution of returns given contextual information, leading to better out-of-sample performance compared to traditional approaches that separate prediction from optimization.

```ContextualOptimization.jl``` implements this framework across multiple optimization models, providing a unified interface for contextual portfolio selection.


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
$\boldsymbol{\mu}_{r\,|\,s}$ and $\boldsymbol{\Sigma}_{r\,|\,s}$ representes conditional expected return and conditional covariance matrix given context $s$ respectively.
* $\boldsymbol{x}$ is the vector of portfolio weights.              


