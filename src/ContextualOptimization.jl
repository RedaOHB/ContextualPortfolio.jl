module ContextualOptimization

# Import extenal package dependencies
using JuMP
using CovarianceEstimation
using DataFrames
using Dates
using DelimitedFiles
using Distributions
using ExcelFiles
using Gurobi
using LinearAlgebra
using Plots
using Random
using Statistics
using StatsBase
using XLSX
using MarketData
using YFinance
using HTTP
using JSON3
using DotEnv

# Include source files 
include("splitting.jl")
include("moments.jl")
include("performance.jl")
include("models.jl")
include("backtest.jl")

# Export the main user-facing functions
export backtest

end # module ContextualOptimization










