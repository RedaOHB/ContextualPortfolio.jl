# [Tutorial](@id Tutorial)

This tutorial provides a step-by-step guide to using ContextualOptimization.jl for portfolio optimization with contextual information.

## Overview

In this tutorial, you will learn how to:

1. Prepare your data (returns and contextual features)
2. Specify an optimization model
3. Run a backtest with rolling window validation
4. Analyze and interpret the results

## Setup 
Make sure you have the package installed and loaded:
```julia
using ContextualOptimization  # our package
using DataFrames, Dates  # for data handling
using JuMP, HiGHS  # for modeling and solving (HiGHS is the default open-source solver)
using Distributions, LinearAlgebra, Statistics, StatsBase, Random, CovarianceEstimation  # for mathematical manipulation
```

For data loading and visualization (optional):
```julia
using CSV, XLSX  # for reading data files
using Plots  # for visualization
```

## Step 1: Prepare your Data

### Data requirements 

ContextualOptimization.jl requires two main data inputs, returns and contextual information.

1. **Returns** (DataFrame): Historical asset returns with a `Date` column followed by asset columns
2. **Context** (DataFrame): Contextual features with a `Date` column followed by feature columns

### Loading real Data

#### Loading Returns Data

**Option 1: Using Tiingo API**

You can load historical returns from various sources. For convenience, we provide a helper function to load historical returns from the Tiingo financial data API. This function is available in the [test directory](https://github.com/RedaOHB/ContextualOptimization.jl/tree/main/test/data).
```julia 
# Include the data loading utilities
  include("test/data/data_loading.jl")  

# Load historical returns from Tiingo
  Assets = ["AAPL", "MSFT", "GOOGL", "AMZN", "META"]
  start_date = Date(2015, 01, 01)
  end_date = Date(2024, 12, 31)
  Returns = historical_returns(Assets, start_date, end_date, api_key, "daily")
```      

!!! note "API Key Required"
    The `historical_returns` function requires a Tiingo API key. You can obtain a free API key at [https://www.tiingo.com](https://www.tiingo.com). The function reads the API key from an environment variable or configuration file. See `test/data/README.md` for setup instructions.

**Option 2: Load from CSV Files**

If you have pre-downloaded data:
```julia
# Load returns from CSV
  Returns = CSV.read("returns.csv", DataFrame)
```

#### Loading Contextual Features

Contextual features can include macroeconomic indicators, market variables, or other relevant data:
```julia
# Example: Load from XLSX file (e.g., from FRED database)
  feature = XLSX.readtable("test/data/Features_example.xlsx", "Sheet1") |> DataFrame
```

Or load from `csv` file:
```julia
  feature = CSV.read("test/data/Features_example.csv", DataFrame)
```

#### Accepted data frequencies 
For a consistent and reliable setup, historical returns can be provided at either a daily or monthly frequency. Contextual features must be provided on a monthly basis.

#### Aligning data by date
**Aligning contextual features**
Ensure that all contextual data are aligned by date for subsequent processing:
```julia
context = innerjoin(feature_1, feature_2, feature_3; on=:Date)
```

**Aligning returns and contextual features**
For the optimization process, returns and contextual data are aligned by date within the main function. If both are represented at the same frequency, the alignment is straightforward. If the frequencies differ, contextual values are duplicated for each day within the corresponding period.
```julia
# Aligning returns and contextual data
  Data = align(returns, context)
```


### Example: Synthetic Data

For testing purposes, you can generate synthetic data:
```julia
using Random
Random.seed!(123)

# Generate synthetic data
  N = 10   # Number of assets
  K = 3    # Number of contextual features

# Generate synthetic daily returns
  dates_daily = Date(2015, 01, 01):Day(1):Date(2024, 12, 31)
  returns = DataFrame(Date=dates_daily)
  for i in 1:N
      returns[!, Symbol("Asset$i")] = randn(length(dates_daily)) * 0.01 .+ 0.0005
  end

# Generate synthetic monthly contextual features
  dates_monthly = Date(2015, 01, 01):Month(1):Date(2024, 12, 31)
  context = DataFrame(Date=dates_monthly)
  for i in 1:K
      context[!, Symbol("Feature$i")] = randn(length(dates_monthly))
  end
```

## Step 2: Specify an Optimization Model
Choose an optimization model based on your investment objectives. The mean-variance models use the conditional moments and a risk-aversion parameter as arguments.

### Mean-Variance model
```julia
model = optimize_mv  # Mean Variance (MV)
``` 
This maximizes the return and minimizes the risk of portfolio.

### Robust Mean-Variance models
```julia
model = optimize_mvbu  # Mean Variance with Box Uncertainty (MVBU)
model = optimize_mveu  # Mean Variance with Ellipsoidal Uncertainty (MVEU)
```
These account for uncertainty in parameter estimates, making the portfolio more robust.

The risk aversion parameter `η` controls the trade-off between return and risk: 
- **Higher values** (e.g., 2.0, 5.0): More conservative portfolios with lower volatility
- **Lower values** (e.g., 0.1, 0.5): More aggressive portfolios seeking higher returns

## Step 3: Run the Backtest
Now we can run the backtest using our prepared data and chosen model. Before calling the `backtest_portfolio` function, we define the parameters structure:

| **Arguments**          | **Details**        |
|------------------------|--------------------|
| `estimation_horizon`   | length of rolling window         | 
| `evaluation_horizon`   | length of slide window           |
| `returns`              | historical returns               |
| `context`              | contextual factors               |
| `model`                | optimization model               |
| `η`                    | risk-aversion parameter          |   
| `start_date`           | begin date of optimization       |
| `end_date`             | end date of optimization         |
| `optimizer`            | JuMP solver (default: HiGHS)     |

The structure is defined as follows:
```julia
params = backtestParameters(
    estimation_horizon = 48,  # 4 years of estimation (48 months) 
    evaluation_horizon = 1,   # 1 month of validation
    returns = returns,
    context = context,
    model = optimize_mv,
    η = 1.0,                  # moderate value of risk aversion
    start_date = Date(2015, 01, 01),
    end_date = Date(2024, 12, 31)
)
```

Now, we solve the optimization problem by calling the main function:
```julia
portfolios, portfolio_performance, global_performance = backtest_portfolio(params)
```

## Step 4: Analyze Results

### View Performance Metrics

The backtest returns three objects: all portfolios constructed within the rolling window approach, performance metrics of each portfolio, and global performance:
```julia
println("Performance metrics of all portfolios:")
println(portfolio_performance)
```

### Analyze Portfolio Composition

Plot the changes of portfolio composition over time (turnover):
```julia
using Plots

dates = portfolio_performance.Start_Period

plot(dates, portfolio_performance.turnover,
     xlabel="Dates",
     ylabel="Turnover",
     title="Portfolio Composition Evolution",
     legend=false,
     alpha=0.6)
```

### Examine Diversification

Plot the Herfindahl-Hirschman index (HHI) over time:
```julia
plot(dates, portfolio_performance.HHI,
     xlabel="Dates",
     ylabel="HHI",
     title="Portfolio Diversification (HHI)",
     linewidth=2)
```
Lower HHI values indicate better diversification (minimum is 1/N for equal weights).

### Visualize Portfolio Returns

Plot the cumulative return over time:
```julia
plot(dates, portfolio_performance.Return,
     xlabel="Dates",
     ylabel="Return",
     title="Portfolio Performance",
     linewidth=2)
```

### View Global Performance

Evaluate aggregated performance metrics over the rolling window approach:

```julia
println("Global performance:")
println("  Mean Return: ", round(global_performance.Mean_return[1] * 100, digits=2), "%")
println("  Volatility: ", round(global_performance.Volatility[1] * 100, digits=2), "%")
println("  Sharpe Ratio: ", round(global_performance.Sharpe_ratio[1], digits=2))
println("  CVaR (95%): ", round(global_performance.CVaR[1] * 100, digits=2), "%")
println("  Omega Ratio: ", round(global_performance.Omega_ratio[1], digits=2))
println("  Average number of assets: ", round(global_performance.No_Assets[1], digits=3))
println("  Average HHI: ", round(global_performance.HHI[1], digits=3))
println("  Average Turnover: ", round(global_performance.turnover[1], digits=3))
```

## Complete Example

Here's a complete working example: 
```julia
using ContextualOptimization
using DataFrames, Dates, Random
using Plots

# Generate synthetic data
Random.seed!(42)
N = 10
K = 3

# Daily returns
dates_daily = Date(2015, 01, 01):Day(1):Date(2024, 12, 31)
returns = DataFrame(Date=dates_daily)
for i in 1:N
    returns[!, Symbol("Asset$i")] = randn(length(dates_daily)) * 0.01 .+ 0.0005
end

# Monthly contextual features
dates_monthly = Date(2015, 01, 01):Month(1):Date(2024, 12, 31)
context = DataFrame(Date=dates_monthly)
for i in 1:K
    context[!, Symbol("Feature$i")] = randn(length(dates_monthly))
end

# Run backtest
params = backtestParameters(
    estimation_horizon = 48,  # 48 months of estimation (4 years) 
    evaluation_horizon = 1,   # 1 month of validation
    returns = returns,
    context = context,
    model = optimize_mv,
    η = 1.0,                  # moderate value of risk aversion
    start_date = Date(2015, 01, 01),
    end_date = Date(2024, 12, 31)
)

portfolios, portfolio_performance, global_performance = backtest_portfolio(params)

# Evaluate performance    
println("  Sharpe Ratio: ", round(global_performance.Sharpe_ratio[1], digits=2))
println("  Average HHI: ", round(global_performance.HHI[1], digits=3))

# Visualize returns
dates = portfolio_performance.Start_Period

plot(dates, portfolio_performance.Return,
     xlabel="Dates",
     ylabel="Return",
     title="Portfolio Performance",
     linewidth=2)
```

## Tips and Best Practices

1. **Contextual data frequency**: Ensure context data are on a monthly basis
2. **Feature Selection**: Choose contextual features relevant to your asset universe
3. **Parameter Tuning**: Experiment with `η`, `estimation_horizon`, and `evaluation_horizon`
4. **Solver Choice**: The default solver HiGHS is open-source; pass `optimizer=Gurobi.Optimizer` for Gurobi
5. **Validation**: Always evaluate on true out-of-sample data

## Next Steps

- Explore the [API Reference](@ref) for detailed function documentation
- Read the [Method](@ref) section for mathematical details
- Try different contextual features and optimization models

## Data Sources
 
Contextual features can be obtained from:
- **FRED** (Federal Reserve Economic Data): https://fred.stlouisfed.org
- **Yahoo Finance**: Market indices and volatility measures
- **Quandl**: Economic and financial datasets
- **World Bank**: International economic indicators
