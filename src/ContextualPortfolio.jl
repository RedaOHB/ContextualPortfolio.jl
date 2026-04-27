module ContextualPortfolio

using JuMP, HiGHS
using DataFrames, Dates
using Distributions, CovarianceEstimation, LinearAlgebra, Statistics, StatsBase

# Include source files
include("splitting.jl")
include("utils.jl")
include("moments.jl")
include("performance.jl")
include("models.jl")
include("backtest.jl")

# Export types
export backtestParameters

# Export optimization models
export optimize_mv, optimize_mvbu, optimize_mveu

# Export backtesting
export backtest_portfolio

# Export conditional moments
export conditional_moments

# Export performance metrics
export cumulative_return, volatility
export Conditional_Value_at_Risk, Sharpe_ratio, Omega_ratio
export Assets_number, Diversification, Turnover

# Export utilities
export split_sample, align

end # module ContextualPortfolio
