`ContextualOptimization.jl` implements a contextual portfolio optimization framework based on a rolling window backtesting approach with periodic rebalancing. The method operates in two key phases:
1. **Estimation phase**: Model training and parameter estimation using historical data.
2. **Validation phase**: Out-of-sample performance evaluation.

This two-phase structure allows for robust evaluation of the contextual optimization strategy under realistic market conditions.

### Estimation phase
During the estimation phase, the algorithm uses a rolling training window of historical data to estimate conditional moments (mean, covariance) based on contextual features by applying the following formulas:
```math
\begin{align*}
  \mu_{r|s} &= \mu_{r} + \Sigma_{rs} (\Sigma_{ss})^{-1} (s - \mu_{s}),\\
  \Sigma_{r|s} &= \Sigma_{rr} - \Sigma_{rs} (\Sigma_{ss})^{-1} \Sigma_{sr}.
\end{align*}
```
  
where:
* $\mu_{r}$ and $\mu_{s}$ are the mean vectors of returns and contextual features, respectively.
* $\Sigma_{rr}$ and $\Sigma_{ss}$ are the covariance matrices of returns and contextual features, respectively. 
* $\Sigma_{rs} = \Sigma_{sr}^{T}$ representens the cross-covariance between returns and contextual features.

The next step is solving optimization problem to determine optimal portfolio weights. The optimization model can be chosen from several models defined in [`models.jl`](https://github.com/RedaOHB/ContextualOptimization.jl/src/models.jl).

As an example, the mean-variance formulation is:
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
* $\mathbf{\Sigma}_{r|s}$ is the conditional covariance matrix given context $s$.
* $\mathbf{x}$ is the vector of portfolio weights.          
* $\eta$ is the risk aversion parameter.

### Validation phase
During the validation phase, the algorithm applies the optimized portfolio to out-of-sample data and evaluates performance using multiple metrics described below.

Let $R_{t} = r_{t}^{T} x$ denote the portfolio return at time $t$, and $R = (R_{1},\dots,R_{T})$ the sequence of returns over the validation period.

#### Portfolio Composition Metrics

**Number of Active Assets**: The number of assets with non-zero weights in the portfolio:
$$|X| = \sum_{i=1}^{N} \mathbb{1}(x_{i} > 0)$$
where $X = (x_{1},\dots, x_{N})$ is the vector of portfolio weights.

**Diversification Index (Herfindahl-Hirschman Index)**: Measures portfolio concentration:
$$\text{HHI} = \sum_{i=1}^{N} x_{i}^{2}$$
Lower values indicate greater diversification.

**Turnover**: Measures portfolio rebalancing activity between periods $t$ and $t+1$:
$$\text{Turnover} = \sum_{i=1}^{N} |x_{i}^{t+1} - x_{i}^{t}|$$

#### Portfolio Performance Metrics

**Cumulative Return**: Total return over the validation period:
$$R_{p} = \prod_{t=1}^{T} (1 + R_{t}) - 1$$

**Volatility** (standard deviation of returns):
$$\sigma_{p} = \sqrt{\frac{1}{T-1} \sum_{t=1}^{T} (R_{t} - \bar{R})^{2}}$$
where $\bar{R} = \frac{1}{T} \sum_{t=1}^{T} R_{t}$ is the mean portfolio return.

**Conditional Value-at-Risk (CVaR)**: Expected loss beyond the VaR threshold at confidence level $\beta$:
$$\text{CVaR}_{\beta} = \mathbb{E}[L \mid L \geq \text{VaR}_{\beta}]$$
where $L = -R$ represents the loss.

**Sharpe Ratio**: Risk-adjusted return measure:
$$\text{Sharpe} = \frac{\bar{R} - R_{f}}{\sigma_{p}}$$
where $R_{f}$ represents the risk-free rate.

**Omega Ratio**: Probability-weighted ratio of gains versus losses relative to threshold $\tau$:
$$\Omega = \frac{\sum_{t=1}^{T} \max(R_{t} - \tau, 0)}{\sum_{t=1}^{T} \max(\tau - R_{t}, 0)}$$

At each rebalancing period, the algorithm advances the rolling window, re-estimates the conditional moments with updated data, and repeats the optimization process.