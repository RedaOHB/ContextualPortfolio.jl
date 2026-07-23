---
title: 'ContextualPortfolio.jl: A Julia Package for Contextual Portfolio Optimization'
tags:
  - Julia
  - portfolio optimization
  - contextual optimization
  - conditional moments
  - backtesting
  - robust optimization
authors:
  - name: Reda Ouahib
    orcid: 0009-0001-9940-9572
    affiliation: 1
  - name: Fabian Bastin
    orcid: 0000-0003-1323-6787
    affiliation: 1
affiliations:
  - name: "D\\'{e}partement d'informatique et de recherche op\\'{e}rationnelle, Universit\\'{e} de Montr\\'{e}al, Montr\\'{e}al, Canada"
    index: 1
date: 27 April 2026
bibliography: paper.bib
---

# Summary

`ContextualPortfolio.jl` is a Julia package that implements a contextual
portfolio optimization framework.  Unlike traditional portfolio optimization,
which treats expected returns and covariances as fixed inputs, contextual
optimization conditions these estimates on observable side information such as
macroeconomic indicators or market signals.  The package provides three
mean--variance optimization models---standard, box-uncertainty robust, and
ellipsoidal-uncertainty robust---together with a rolling-window backtesting
engine that evaluates out-of-sample performance with comprehensive risk and
return metrics.

# Statement of Need

Portfolio optimization is a cornerstone of quantitative finance, yet
practitioners routinely face two challenges.  First, traditional approaches
separate the estimation of return distributions from the optimization step,
ignoring information that could improve decisions [@Nguyen2024].  Second, most
existing software either targets a single model (e.g., mean--variance only) or
requires deep expertise in optimization modelling languages.

`ContextualPortfolio.jl` addresses both gaps.  By computing conditional
moments of returns given contextual features and feeding them directly into the
optimization, the package implements the contextual optimization framework
of @Nguyen2024 in a single, easy-to-use interface.  It ships with robust
variants that account for estimation uncertainty via box and ellipsoidal
uncertainty sets, following the robust optimization principles described
by @BenTal2009.  The rolling-window backtesting engine automates the
train/validate cycle and produces a comprehensive set of performance metrics
(Sharpe ratio, CVaR, Omega ratio, HHI, turnover), enabling reproducible
empirical studies.

The package is built on JuMP [@Lubin2023], the Julia mathematical programming
framework, and defaults to the open-source Clarabel solver [@Goulart2024], 
avoiding licensing barriers. Users may substitute any JuMP-compatible quadratic
programming solver.

Existing tools such as `PortfolioAnalytics` in R [@PortfolioAnalytics] or
`PyPortfolioOpt` in Python [@PyPortfolioOpt] provide portfolio construction
utilities but do not offer built-in contextual conditioning.  In the Julia
ecosystem, `PortfolioOpt.jl` provides basic mean--variance optimization but
lacks contextual moment estimation, robust models, and backtesting.
`ContextualPortfolio.jl` fills this niche by combining conditional moment
estimation, robust optimization, and rolling-window backtesting in a single
package.

# Methodology

The core methodology consists of two stages applied at each step of a rolling
window.

**Conditional moment estimation.**  Given a joint dataset of asset returns $r$
and contextual features $s$, the package estimates the conditional mean and
covariance:

$$\mu_{r|s} = \mu_r + \Sigma_{rs}\,\Sigma_{ss}^{-1}(s - \mu_s),$$
$$\Sigma_{r|s} = \Sigma_{rr} - \Sigma_{rs}\,\Sigma_{ss}^{-1}\,\Sigma_{sr},$$

where $\mu_r$, $\mu_s$ are marginal means and $\Sigma_{rr}$, $\Sigma_{ss}$,
$\Sigma_{rs}$ are the corresponding blocks of the joint covariance matrix.
Covariance estimation uses linear shrinkage [@LedoitWolf2004] for numerical
stability.

**Portfolio optimization.**  The conditional moments are passed to one of three
quadratic programs.  The standard mean--variance model [@Markowitz1952] solves:

$$\min_{\mathbf{x}} \; -\mu_{r|s}^\top \mathbf{x} + \eta\,\mathbf{x}^\top \Sigma_{r|s}\,\mathbf{x}
\quad \text{s.t.} \quad \mathbf{1}^\top\mathbf{x}=1,\;\mathbf{x}\ge 0,$$

where $\eta$ is the risk-aversion parameter.  The box-uncertainty and
ellipsoidal-uncertainty variants add penalty terms that hedge against estimation
error in the mean, producing more conservative allocations.

# Usage

A typical workflow requires fewer than ten lines of code:

```julia
using ContextualPortfolio, DataFrames, Dates

params = Backtest_Parameters(
    estimation_horizon = 48, evaluation_horizon = 1,
    returns = returns, context = context,
    model = optimize_mv, η = 1.0,
    start_date = Date(2015,1,1), end_date = Date(2024,12,31))

portfolios, perf, average_perf, global_perf = backtest_portfolio(params)
```

The solver can be changed via the `optimizer` keyword (e.g.,
`optimizer = Gurobi.Optimizer`).

To build a portfolio without contextual information, set `context = nothing`. For an equal-weight portfolio, use `model = :EqualWeight`.

# Numerical experiments

To assess the effectiveness of the contextual approach, we construct portfolios over a 20-year horizon and compare performance with and without contextual information. We generate synthetic data composed of daily returns and monthly contextual features using the `synthetic_data` function, which takes as input the number of assets, the number of contextual features, the random seed, the start date, and the end date. 

```julia
using ContextualPortfolio
using Distributions, LinearAlgebra, Statistics, Dates, DataFrames, Random

n_asset = 10  # number of assets
n_features = 3  # number of contextual features
start_date = Date(2005, 01, 01)  
end_date = Date(2025, 12, 31)
random_state = 0  # the control knob for reproducibility

# generate daily returns and monthly features
returns, features = synthetic_data(n_assets, n_features, random_state, start_date, end_date)

```

Following the structure described above, we obtain, for each case, the resulting portfolios over the evaluation horizon, together with the performance measures of each portfolio and the corresponding average and global metrics. Table 1 summarizes the global performance measures for the two cases. The results indicate that our approach improves both return and risk-adjusted performance while reducing risk.
     
| Metrics | Return | Volatility | CVaR | Sharp ratio | Omega ratio|
| --- | ---: | ---: | ---: | ---: | ---: |
| without context (classical model) | 0.0742384 | 0.12709 | 0.15628 | 0.627528 | 1.59229 |
| with context (contextual model)| 0.0847691 | 0.122842 | 0.126934 | 0.725273 | 1.68121 |


Using the turnover metric, which measures changes in portfolio composition between two consecutive periods, we analyze portfolio reactivity across rebalancing dates. The evolution is presented in Figure 1.
We find that the turnover of the contextual model is generally higher than that of the classical model, indicating a more reactive management that better reflects market changes.

![Turnover dynamics of classical and contextual portfolios](paper/figures/turnover_plot.png)

For an initial investement of 100$, we show in Figure 2 the wealth evolution of the classical and contextual portfolios. Both strategies follow a similar upward trend over the investment horizon, but the contextual model generally achieves a slightly higher wealth trajectory, particularly toward the end of the sample. This suggests that incorporating contextual information can improve portfolio growth over time.

![Evolution of portfolio wealth for classical and contextual strategies](paper/figures/wealth_plot.png)


# Acknowledgements

We thank the developers of JuMP, Clarabel, and the Julia data-science ecosystem
for the tools that made this package possible.  Economic data used in examples
is sourced from FRED (Federal Reserve Economic Data) and Tiingo.

# References


