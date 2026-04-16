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
# Or optimize_mvbu for Mean Variance with Box Uncertainty 
# Or optimize_mveu for Mean Variance with Ellipsoïdal Uncertainty 
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
```
