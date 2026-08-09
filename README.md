# ContextualPortfolio.jl

[![CI](https://github.com/RedaOHB/ContextualPortfolio.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/RedaOHB/ContextualPortfolio.jl/actions/workflows/CI.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://RedaOHB.github.io/ContextualPortfolio.jl/stable)

`ContextualPortfolio.jl` is a Julia package that solves portfolio optimization problems by leveraging contextual information about market conditions. The package implements a rolling window backtesting framework with multiple optimization models.

### Key Features

- **Contextual Optimization**: Integrate external factors into portfolio decisions using conditional moments
- **Multiple Optimization Models**: Mean-variance and robust optimization with uncertainty sets
- **Rolling Window Backtesting**: Evaluate out-of-sample performance with periodic rebalancing
- **Comprehensive Performance Metrics**: Sharpe ratio, CVaR, Omega ratio, diversification measures,etc
- **Robust Covariance Estimation**: Built-in shrinkage estimation for stable optimization

## Installation 
```julia 
using Pkg
Pkg.add("ContextualPortfolio")
```

Or install the development version:
```julia
using Pkg
Pkg.add(url="https://github.com/RedaOHB/ContextualPortfolio.jl")
```

## Quick start
```julia 
using ContextualPortfolio 
using DataFrames, Dates 

# Load your data (returns and contextual features) 
returns = historical_returns(Assets, start_date, end_date, Api_key, frequency) 
context = context_data(file_path, file_type, sheet_name) 
# Define optimization model
model = optimize_mv # Mean Variance model 
# Or "optimize_mvbu" for Mean Variance with Box Uncertainty 
# Or "optimize_mveu" for Mean Variance with Ellipsoïdal Uncertainty 

# Run backtest 
  # Define the parameters structure 
  Parameters = Backtest_Parameters(  
               estimation_horizon = 48, 
               evaluation_horizon = 1, 
               returns = returns, 
               context = context, 
               model = model, 
               η = 1.0, 
               start_date = Date(2020,01,01), 
               end_date = Date(2024,12,31) ) 
  # Call solve function 
  Portfolios, Performance_metrics, Average_performance, Global_performance = backtest_portfolio(Parameters) 

# Evaluate performance
println("Average return: ", Average_performance.mean_Return[1])
println("Sharpe ratio: ", Global_performance.Sharpe_ratio[1])
println("Average HHI: ", Average_performance.HHI[1])
```

## Methodology

`ContextualPortfolio.jl` implements a contextual optimization framework based on conditional moments. Unlike traditional approaches that separate prediction and optimization, this method jointly optimizes portfolio decisions based on contextual features.

### Conditional moments

The package estimates conditional expected returns and covariance given context $s$:

```math
\begin{align*}
  \mu_{r|s} &= \mu_{r} + \Sigma_{rs} (\Sigma_{ss})^{-1} (s - \mu_{s}),\\
  \Sigma_{r|s} &= \Sigma_{rr} - \Sigma_{rs} (\Sigma_{ss})^{-1} \Sigma_{sr}.
\end{align*}
```

### Optimization models

**Mean-Variance**:
```julia
model = optimize_mv(μᵣ_ₛ, Σᵣ_ₛ, η)
```
This maximize the return and minimize the risk of portfolio.

**Mean-Variance with Box Uncertainty**:
```julia
model = optimize_mvbu(μᵣ_ₛ, Σᵣ_ₛ, η, data)
```

**Mean-Variance with Ellipsoidal Uncertainty**:
```julia
model = optimize_mveu(μᵣ_ₛ, Σᵣ_ₛ, η, data)
```

These account for uncertainty in parameter estimates, making the portfolio more robust.


## Performance metrics

The package computes comprehensive performance metrics:

- **Return Metrics**: mean return and cumulative return
- **Risk Metrics**: volatility and CVaR
- **Risk-Adjusted**: Sharpe and Omega ratios
- **Portfolio Characteristics**: Number of assets, HHI (diversification) and turnover

## Documentation

For detailed documentation, tutorial, and examples, see:

- [**Tutorial**](https://RedaOHB.github.io/ContextualPortfolio.jl/stable/tutorial/)
- [**API Reference**](https://RedaOHB.github.io/ContextualPortfolio.jl/stable/api/)
- [**Methodology**](https://RedaOHB.github.io/ContextualPortfolio.jl/stable/method/)

## Data loading 

Helper functions for loading financial data are available in `test/data/`:
```julia
include("test/data/data_loading.jl")

# Load historical returns from Tiingo API
Assets = ["AAPL", "IBM", "GOOGL", "META", "AMZN"]
returns = historical_returns(Assets, Date(2020,01,01), Date(2024,12,31), api_key, "daily")

# Load contextual features from FRED data
context = context_data("test/data/Features_example.csv", "csv", "sheet1")

```

See `test/data/README.md` for setup instructions (requires API key).

## Example 

Complete example with synthetic data:
```julia
using ContextualPortfolio
using Random, Dates

# Generate synthetic data
Random.seed!(42)
n_assets = 10
n_context = 3

dates = Date(2015, 01, 01):Day(1):Date(2024, 12, 31) # Daily returns
n_periods = length(dates)
returns = DataFrame(Date = dates)
for i in 1:n_assets
    returns[!, Symbol("Asset$i")] = randn(n_periods) * 0.01 .+ 0.0005
end

dates = Date(2015, 01, 01):Month(1):Date(2024, 12, 31) # Monthly features
n_periods = length(dates)
context = DataFrame(Date = dates)
for i in 1:n_context
    context[!, Symbol("Feature$i")] = randn(n_periods)
end

# Run backtest with mean-variance 
Parameters = Backtest_Parameters( 
                estimation_horizon = 48,  # 48 months of estimation
                evaluation_horizon = 1,   # 1 month of evaluation
                returns = returns, 
                context = context, 
                model = optimize_mv,            # mean-variance model
                η = 1.0,                  # risk aversion
                start_date = Date(2015,01,01), 
                end_date = Date(2024,12,31) ) 

Portfolios, Portfolio_performance, Average_performance, Global_performance = backtest_portfolio(Parameters)

# Evaluate and visualize
println("Global performance Metrics:")
println("  Global Return: ", round(Global_performance.global_Return[1] * 100, digits=2), "%")
println("  Volatility: ", round(Global_performance.Volatility[1] * 100, digits=2), "%")
println("  Sharpe Ratio: ", round(Global_performance.Sharpe_ratio[1], digits=2))
println(" Diversification index: ", round(Average_performance.mean_HHI[1], digits=2))

# Plot return
dates = Portfolio_performance.Start_Period

plot(dates, Portfolio_performance.Return, 
   xlabel="Dates",
   ylabel="Return",
   title="Portfolio Performance",
   linewidth=2)

```

## Solver

The package uses [Clarabel](https://clarabel.org) (open-source, MIT license) by default.
You can use any JuMP-compatible QP solver by passing the `optimizer` keyword:

```julia
# Default (Clarabel — no license required)
Parameters = Backtest_Parameters(estimation_horizon=48, ...) 

# Using Gurobi (requires a license)
using Gurobi
Parameters = Backtest_Parameters(estimation_horizon=48, ..., optimizer=Gurobi.Optimizer)

# Or pass the optimizer directly to a model function
x = optimize_mv(μ, Σ, η; optimizer=Gurobi.Optimizer)
```

## Requirements

- Julia ≥ 1.6
- JuMP.jl (Clarabel is included by default; other QP solvers can be used)
- See `Project.toml` for full list of dependencies

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

## References

The methodology is based on:

- Viet Anh Nguyen, Fan Zhang, Shanshan Wang, Jose Blanchet, Erick Delage, and Yinyu Ye (2024). "Robustifying conditional portfolio decisions via optimal transport." *Operations Research* 73(5), pp. 2801–2829.
- Harry Markowitz (1952). "Portfolio Selection." *The Journal of Finance* 7(1), pp. 77-91.

## Acknowledgments

- Economic data from [FRED (Federal Reserve Economic Data)](https://fred.stlouisfed.org)
- Financial data via [Tiingo API](https://www.tiingo.com)
- Built with [Julia](https://julialang.org) and [JuMP.jl](https://jump.dev)














