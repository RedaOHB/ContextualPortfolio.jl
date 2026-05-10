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

params = backtestParameters(
    estimation_horizon = 48, evaluation_horizon = 1,
    returns = returns, context = context,
    model = optimize_mv, η = 1.0,
    start_date = Date(2015,1,1), end_date = Date(2024,12,31))

portfolios, perf, global_perf = backtest_portfolio(params)
```

The solver can be changed via the `optimizer` keyword (e.g.,
`optimizer = Gurobi.Optimizer`).

# Acknowledgements

We thank the developers of JuMP, Clarabel, and the Julia data-science ecosystem
for the tools that made this package possible.  Economic data used in examples
is sourced from FRED (Federal Reserve Economic Data) and Tiingo.

# References
