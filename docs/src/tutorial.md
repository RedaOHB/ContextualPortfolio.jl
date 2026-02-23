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
In practice, **daily historical returns** are loading from the Data Finance Database `Tiingo` using specify API key. To make this load easier, we have created `historical_returns` function, where specialized key is introduce inside it. All what you have to do is call this function with its appropriate arguments:
```julia 
Returns = historical_returns(Assets, start_date, end_date)
```      
with:
* `Assets` : set of assets used to construct portfolio.
* `start_date` and `end_date` : begin and stop dates to collections data.

For more details about the main `historical_returns` function, take a look to [test directory](https://github.com/RedaOHB/ContextualOptimization.jl/test).

**Contxtual features** are reported on a menthly basis and where downloaded from the ***Economic Research : Federal Research Bank of St. Louis*** in the web site http://research.stlouisfed.org. Its availables on `.xlsx` or `.csv` extensions. One file correspond to one contextual factor, and each file is reading by:
* For `.xlsx` extension:
```julia
xf = XLSX.readxlsx("file_name.xlsx")  # read file
sheet = xf["Monthly"]  # select the right sheet
xf = sheet[:]  
headers = Symbol.(xf[1, :]) 
data = DataFrame([xf[2:end, i] for i in 1:size(xf, 2)], headers)  # transform to DataFrame
```
* For `.csv` extension:
```julia
data = CSV.read("file_name.csv", DataFrame)  # read file and transform to DataFrame
```

For more clarity, you join all contextual data on the same DataFrame to after uses on the main function:
```julia
context = innerjoin(data_1,data_2,data_3; on = :Date_column)  # on=:Date_column --> date alignement
```

## Step 2: Specify an Optimization Model
Choose an optimization model based on your investment objectives. The mean-variance models uses the two conditional moments as arguments and risk-aversion parameter

### Mean-Variance model
```julia
model = mean_variance_model(μ, Σ, η)  # Mean Variance (MV)
``` 
This maximize the return and minimize the risk of portfolio.

### Robust Mean-Variance models
```julia
model = mean_variance_Box_Uncertainty(μ, Σ, η, data)  # Mean Variance with Box Uncertainty (MVBU)
model = mean_variance_Ellipsoidale_Uncertainty(μ, Σ, η, data)  # Mean Variance with Ellipsoidale Uncertainty (MVEU)
```
This accounts for uncertainty in the parameter estimates.

The risk aversion parameter `η` controls the trade-off between return and risk. Higher values lead to more conservative portfolios.

## Step3: Run the Backtest
Now we can run the backtest with our prepared data and chosen model. Before calling `backtest` function, we define the arguments structure

| **Arguments**          | **Details**        |
|------------------------|--------------------|
| `estimation_horizon`   | lenght of rolling window         | 
| `validation_horizon`   | lenght of slide window           |
| `data`                 |     historical returns           |
| `context`              |     contextual factors           |
| `model`                |     optimization model           |
| `η`                    |      risk-aversion parameter     |   
| `start_date`           |       begin date of optimization |
| `end_date`             |       end date of optimization   |

The structure is declared like this:
```julia
Parameter = BacktestParameters(
    estimation_horizon = 48,  # 4 years of estimation 
    validation_horizon = 1,  # 1 month of validation
    data,
    context,
    model,
    η = 1,                 # moderate value
    start_date = Date(2005,01,01)
    end_date = Date(2020,06,30)
)
```

Now, we solve the optimiztion problem by calling the main function:
```julia
portfolios, portfolio_performance, global_performance = backtest_portfolio(Parameter)
```







                                                                             