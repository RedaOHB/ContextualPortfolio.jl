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
using DataFrames, CSV, XLSX, ExcelFiles, Dates  # for data handling
using JuMP, Gurobi  # for julia modeling and solving
using Distributions, LinearAlgebra, Statistics, StatsBase, Random, CovarianceEstimation  # for mathemaic manipulation
using Plots  # for visualization
using DotEnv, JSON3, HTTP, YFinance, MarketData  # for load data
```

## Step 1: Prepare your Data

### Data requirements 

ContextualOptimization.jl requires two main data inputs, returns and contextual informations.

1. **Returns** (DataFrame): Historical asset returns (`T * N` matrix, where `T` is time periods (dates), `N` is number of assets)
2. **Contex** (DataFrame): Contextual features (`T * K` matrix, where `K` is number of features)  

### Loading real Data

#### Loading Returns Data

**Option 1: Using Tiingo API**

You can load historical returns from various sources. For convenience, we provide a helper function to load historical returns from the Tiingo financial data API. This function is available in the [test directory](https://github.com/RedaOHB/ContextualOptimization.jl/test/data).
```julia 
# Include the data loading utilities
  include("test/data/data_loading.jl")  

# Load historical returns from Tiingo
  Assets = ["AAPL", "MSFT", "GOOGL", "AMZN", "META"]
  start_date = Date(2015, 01, 01)
  end_date = Date(2024, 01, 01)
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

# Load contextual data
  feature = context_data("file_path/file.xlsx", "xlsx")
```

Or load from `csv` file
```julia
feature = context_data("file_path/file.csv", "csv")  # read file and transform to DataFrame
```

#### Accepted data frequencies 
For a consistent and reliable setup, historical returns can be provided at either a daily or monthly frequency. Contextual features must be provided on a monthly basis.

#### Aligning data by date
**Aligning contextual features**
Ensure that all contextual data are aligned by date for subsequent processing
```julia
context = innerjoin(feature_1,feature_2,feature_3; on = :Date_column)  # on=:Date_column --> Join on date column
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
  T = 500  # Number of time periods
  N = 10   # Number of assets
  K = 3    # Number of contextual features

# Generate synthetic returns (you would load your own data here)
  Assets = ["AAPL", "AMGN", "AXP", "BA", "CAT", "CRM", "CSCO", "CVX", "DIS", "DOW"]  # Example of assets
  returns = randn(T, N) * 0.01 .+ 0.0005  # Daily returns with mean ~0.05% and volatility ~1%
  returns = DataFrame(returns, Assets)  # convert to DataFrame

# Generate contextual features (e.g., market indicators, economic variables)
  Features = ["CPI", "IPI", "GPD"]  # Exemple of features
  context = randn(T, K)
  context = DataFrame(context, Features)

# join data: returns + contextual features
  data = align(returns, context)

```

## Step 2: Specify an Optimization Model
Choose an optimization model based on your investment objectives. The mean-variance models uses the two conditional moments as arguments and risk-aversion parameter

### Mean-Variance model
```julia
model = optimize_mv(μ, Σ, η)  # Mean Variance (MV)
``` 
This maximize the return and minimize the risk of portfolio.

### Robust Mean-Variance models
```julia
model = optimize_mvbu(μ, Σ, η, data)  # Mean Variance with Box Uncertainty (MVBU)
model = optimize_mveu(μ, Σ, η, data)  # Mean Variance with Ellipsoidale Uncertainty (MVEU)
```
These account for uncertainty in parameter estimates, making the portfolio more robust.

The risk aversion parameter `η` controls the trade-off between return and risk: 
- **Higher values** (e.g., 2.0, 5.0): More conservative portfolios with lower volatility
- **Lower values** (e.g., 0.1, 0.5): More aggressive portfolios seeking higher returns

## Step3: Run the Backtest
Now we can run the backtest using our prepared data and chosen model. Before calling `backtest` function, we define the arguments structure

| **Arguments**          | **Details**        |
|------------------------|--------------------|
| `estimation_horizon`   | lenght of rolling window         | 
| `evaluation_horizon`   | lenght of slide window           |
| `returns`                 |     historical returns           |
| `context`              |     contextual factors           |
| `model`                |     optimization model           |
| `η`                    |      risk-aversion parameter     |   
| `start_date`           |       begin date of optimization |
| `end_date`             |       end date of optimization   |

The structure is defined as follows:
```julia
Parameter = BacktestParameters(
    estimation_horizon = 48,  # 4 years of estimation (48 months) 
    evaluation_horizon = 1,  # 1 month of validation
    returns,
    context,
    model,
    η = 1,                 # moderate value of risk aversion
    start_date = Date(2005,01,01)
    end_date = Date(2020,06,30)
)
```

Now, we solve the optimiztion problem by calling the main function:
```julia
portfolios, portfolio_performance, global_performance = backtest_portfolio(Parameter)
```

## Step 4: Analyze Results

### View Performance Metrics

The backtest returns three results object containing all portfolio constructed within rolling window approach, performance metrics of each portfolio and global performance:
```julia
println(" Performance metrics of all portfolios:")
println(portfolio_performance)
```

### Analyze Portfolio Composition

Plot the changes of portfolio composition over time (turnover)
```julia
using plot

dates = start_date:Month(evaluation_horizon):end_date

plot(portfolio_performance[:,"Turnover"], dates,
     xlabel="Dates",
     ylabel="Turnover",
     title="Portfolio composition Evolution",
     legend=false,
     alpha=0.6)
```

### Examine Diversification

Plot the Herfindahl-Hirschman index (HHI) over time
```julia
plot(portfolio_performance[:,"HHI"], dates,
     xlabel="Dates",
     ylabel="HHI",
     title="Portfolio Diversification (HHI)",
     linewidth=2)
```
Lower HHI values indicate better diversification (minimum is 1/N for equal weights).

### Visualize Portfolio Returns

Plot the cumulative return over time
```julia
plot(portfolio_performance[:,"Returns"], dates,
     xlabel="Dates",
     ylabel="Cumulative Return",
     title="Portfolio Performance",
     linewidth=2)
```

### View global performance

Evaluate performance metrics of agregated serie of returns over the rolling window approach

```julia
Println(" Global performance:")
println("  Mean Return: ", round(global_performance["Mean_return"] * 100, digits=2), "%")
println("  Volatility: ", round(global_performance["Volatility"] * 100, digits=2), "%")
println("  Sharpe Ratio: ", round(global_performance["Sharpe_ratio"], digits=2))
println("  CVaR (95%): ", round(global_performance["CVaR"] * 100, digits=2), "%")
println("  Omega Ratio: ", round(global_performance["Omega_ratio"], digits=2))
println("  Average number of assets: ", round(global_performance["No_Assets"], digits=3))  
println("  Average HHI: ", round(global_performance["HHI"], digits=3))
println("  Average Turnover: ", round(global_performance["Turnover"], digits=3))
```

## Complete exemple

Here's a complete working exemple: 
```julia
using ContextualOptimization
using Random, Plots

# Generate synthetic data
 # Let generate data for period between 01 january 2005 and 31 december 2024
 # This correspond to 5033 trading days (for historical returns)
 # Also correspond to 240 monthly observations (for contextual features)

  Random.seed!(42)
  T1 = 5033
  T2 = 240
  N = 10
  K = 3

  # Generate synthetic returns (you would load your own data here)
    Assets = ["AAPL", "AMGN", "AXP", "BA", "CAT", "CRM", "CSCO", "CVX", "DIS", "DOW"]  # Example of assets
    data = randn(T1, N) * 0.01 .+ 0.0005  # Daily returns with mean ~0.05% and volatility ~1%
    returns = DataFrame(data, assets)  # convert to DataFrame

  # Generate contextual features (e.g., market indicators, economic variables)
    Features = ["CPI", "IPI", "GPD"]  # Exemple of features
    data = randn(T2, K)
    context = DataFrame(data, Features)

# Specify model
  model = mean_variance_model # Or mean_variance_Box_Uncertainty or mean_variance_Ellipsoidale_Uncertainty

# Run backtest
  Parameter = BacktestParameters(
    estimation_horizon = 48,  # 4 years of estimation (48 months) 
    validation_horizon = 1,  # 1 month of validation
    data,
    context,
    model,
    η = 1,                 # moderate value of risk aversion
    start_date = Date(2005,01,01)
    end_date = Date(2024,12,31)
  )

portfolios, portfolio_performance, global_performance = backtest_portfolio(Parameter)

# Evaluate performance    
  println("  Sharpe Ratio: ", round(global_performance["Sharpe_ratio"], digits=2))
  println("  Average HHI: ", round(global_performance["HHI"], digits=3))

# Visualize cumulative returns
  dates = start_date:Month(evaluation_horizon):end_date

  plot(portfolio_performance[:,"Returns"], dates,
     xlabel="Dates",
     ylabel="Cumulative Return",
     title="Portfolio Performance",
     linewidth=2)

```

## Tips and Best Practices

1. **Contextual data frequency**: Ensure context data are on monthly basis
2. **Feature Selection**: Choose contextual features relevant to your asset universe
3. **Parameter Tuning**: Experiment with `risk_aversion`, `estimation_horizon`, and `validation_horizon`
4. **Computational Efficiency**: For large portfolios, reduce `validation_horizon` or use sparse matrices
5. **Validation**: Always evaluate on true out-of-sample data

## Next steps

- Explore the [API Reference](@ref) for detailed function documentation
- Read the [Method](@ref) section for mathematical details
- Try different contextual features and optimization models

## Data Sources
 
Contextual features can be obtained from:
- **FRED** (Federal Reserve Economic Data): https://fred.stlouisfed.org
- **Yahoo Finance**: Market indices and volatility measures
- **Quandl**: Economic and financial datasets
- **World Bank**: International economic indicators





                                                                             