module ContextualOptimization

# Import extenal package dependencies
using JuMP, Gurobi
using DataFrames, Dates, DelimitedFiles, ExcelFiles, XLSX
using Distributions, CovarianceEstimation, LinearAlgebra, Random, Statistics, StatsBase
using Plots
using MarketData, YFinance, JSON3, HTTP, DotEnv 

# Include source files 
include("splitting.jl")
include("utils.jl")
include("moments.jl")
include("performance.jl")
include("models.jl")
include("backtest.jl")

# Export the main user-facing functions
export backtest_portfolio  # backtesting function
export Conditional_Value_at_Risk, Sharpe_ratio, Omega_ratio, Turnover  # performance metrics
export optimize_mv, optimize_mvbu, optimize_mveu  # optimization models
export conditional_moments  # conditional moments

end # module ContextualOptimization










