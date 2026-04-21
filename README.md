# ContextualOptimization.jl

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://RedaOHB.github.io/ContextualOptimization.jl/stable)

`ContextualOptimization.jl` is a Julia package that solves portfolio optimization problems by leveraging contextual information about market conditions. The package implements a rolling window backtesting framework with multiple optimization models.

### Key Features

- **Contextual Optimization**: Integrate external factors into portfolio decisions using conditional moments
- **Multiple Optimization Models**: Mean-variance and robust optimization with uncertainty sets
- **Rolling Window Backtesting**: Evaluate out-of-sample performance with periodic rebalancing
- **Comprehensive Performance Metrics**: Sharpe ratio, CVaR, Omega ratio, diversification measures,etc
- **Robust Covariance Estimation**: Built-in shrinkage estimation for stable optimization

## Installation 
```julia 
using Pkg Pkg.add("ContextualOptimization")
```

Or install the development version:
```julia
using Pkg
Pkg.add(url="https://github.com/RedaOHB/ContextualOptimization.jl")
```

## Quick start
```julia 
using ContextualOptimization 
using DataFrames, Dates 

# Load your data (returns and contextual features) 
returns = historical_returns(Assets, start_date, end_date, Api_key, frequency) 
context = context_data(file_path, file_type) 
# Define optimization model
model = optimize_mv # Mean Variance model 
# Or "optimize_mvbu" for Mean Variance with Box Uncertainty 
# Or "optimize_mveu" for Mean Variance with Ellipsoïdal Uncertainty 

# Run backtest 
  # Define the parameters structure 
  Parameters = backtestparameters( 
               estimation_horizon = 48, 
               evaluation_horizon = 1, 
               returns = returns, 
               context = context, 
               model = model, 
               \eta = 1.0, 
               start_date = Date(2020,01,01), 
               end_date = Date(2024,01,01) ) 
  # Call solve function 
  Portfolios, Performace_metrics, Global_performance = backtest_portfolio(Parameters) 

# Evaluate performance
println("Average return: ", Global_performance.Mean_return[1])
println("Sharpe ratio: ", Global_performance.Sharpe_ratio[1])
println("Average HHI: ", Global_performance[1])
```

## Methodology

`ContextualOptimization.jl` implements a contextual optimization framework based on conditional moments. Unlike traditional approaches that separate prediction and optimization, this method jointly optimizes portfolio decisions based on contextual features.

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

**Mean-Variance with Box Uncertainty**:
```julia
model = optimize_mvbu(μᵣ_ₛ, Σᵣ_ₛ, η, data)
```

**Mean-Variance with Ellipsoidal Uncertainty**:
```julia
model = optimize_mveu(μᵣ_ₛ, Σᵣ_ₛ, η, data)
```

## Performance metrics

The package computes comprehensive performance metrics:

- **Return Metrics**: mean return and cumulative return
- **Risk Metrics**: volatility and CVaR
- **Risk-Adjusted**: Sharpe and Omega ratios
- **Portfolio Characteristics**: Number of assets, HHI (diversification) and turnove

## Documentation

For detailed documentation, tutorial, and examples, see:

- [**Tutorial**](https://RedaOHB.github.io/ContextualOptimization.jl/stable/tutorial/)
- [**API Reference**](https://RedaOHB.github.io/ContextualOptimization.jl/stable/api/)
- [**Methodology**](https://RedaOHB.github.io/ContextualOptimization.jl/stable/method/)

## Data loading 

Helper functions for loading financial data are available in `test/data/`:
```julia
include("test/data/data_loading.jl")

# Load historical returns from Tiingo API
Assets = ["AAPL", "IBM", "GOOGL", "META", "AMZN"]
returns = historical_returns(Assets, Date(2020,01,01), Date(2024,12,31), api_key, "daily")

# Load contextual features from FRED data
feature_1 = context_data("CPI.xlsx", "xlsx")
features_2 = context_data("IPI.xlsx", "xlsx")
  # Align contextual data
  context = align(features_1, features_2)

```

See `test/data/README.md` for setup instructions (requires API key).

## Example 

Complete example with synthetic data:
```julia
using ContextualOptimization
using Random, Dates

# Generate synthetic data
Random.seed!(42)
n_assets = 10
n_context = 3

dates = Date(2015, 01, 01):Day(1):Date(2024, 12, 31) # Daily retruns
returns = DataFrame(Date = dates)
for i in 1:n_assets
    returns[!, Symbol("Asset$i")] = randn(n_periods) * 0.01 .+ 0.0005
end

dates = Date(2015, 01, 01):Monthly(1):Date(2024, 12, 31) # Monthly features
context = DataFrame(Date = dates)
for i in 1:n_context
    context_1[!, Symbol("Feature$i")] = randn(n_periods)
end

# Run backtest with mean-variance
Parameters = backtestParameters( 
                estimation_horizon = 48,  # 48 months of estimation
                evaluation_horizon = 1,   # 1 month of evaluation
                returns = returns, 
                context = context, 
                model = optimize_mv,            # mean-variance model
                η = 1.0,                  # risk aversion
                start_date = Date(2015,01,01), 
                end_date = Date(2024,12,31) ) 

Portfolios, Portfolio_performance, Global_performance = backtest_portfolio(Parameters)

# Evaluate and visualize
println("Global performance Metrics:")
println("  Mean Return: ", round(Global_performance.Mean_return[1] * 100, digits=2), "%")
println("  Volatility: ", round(Global_performance.Volatility[1] * 100, digits=2), "%")
println("  Sharpe Ratio: ", round(Global_performance.sharpe_ratio[1], digits=2))
println(" Diversification index: ", round(Global_performance.HHI[1], digits=2))

# Plot cumulative returns
dates = Date(2015, 01, 01):Monthly(1):Date(2024, 12, 31) # Monthly features

plot(Portfolio_performance.Return, dates, 
   xlabel="Dates",
   ylabel="Cumulative Return",
   title="Portfolio Performance",
   linewidth=2)

```

## Requirements

- Julia ≥ 1.6
- JuMP.jl and an optimization solver (Gurobi)
- See `Project.toml` for full list of dependencies

## Citation



## References

The methodology is based on:

- Nguyen et al. (2024). "Contextual Optimization Framework for Portfolio Selection."
- Markowitz, H. (1952). "Portfolio Selection." *The Journal of Finance*.

## Acknowledgments

- Economic data from [FRED (Federal Reserve Economic Data)](https://fred.stlouisfed.org)
- Financial data via [Tiingo API](https://www.tiingo.com)
- Built with [Julia](https://julialang.org) and [JuMP.jl](https://jump.dev)














