`ContextualOptimization.jl` implements a contextual portfolio optimization framework based on a rolling window backtesting approach with periodic rebalancing. The method operates in two key phases:
1. **Estimation phase**: Model training and parameter estimation using historical data.
2. **Validation phase**: Out-of-sample performance evaluation.

This two-phase structure allows for robust evaluation of the contextual optimization strategy under realistic market conditions.

### Estimation phase
During the estimation phase, the algorithm uses a rolling training window of historical data to estimate conditional moments (mean, covariance) based on contextual features appliying the follows formula:
```math
\begin{align*}
  \mu_{r|s} &= \mu_{r} + \Sigma_{rs} (\Sigma_{ss})^{-1} (s - \mu_{s}),\\
  \Sigma_{r|s} &= \Sigma_{rr} - \Sigma_{rs} (\Sigma_{ss})^{-1} \Sigma_{sr}.
\end{align*}
```
  
with:
* $\mu_{r}$ is the mean vector of returns $\mu_{s}$ is the mean vector of contextual features
* $\mu_{s}$ is the mean vector of contextual features



Than, it solves optimization problem to determine optimal portfolio weights. The optimization model is choosen between models defined in [models](https://github.com/RedaOHB/ContextualOptimization.jl/src/models.jl).
For backtesting experience, we opte for mean-variance model: 
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


