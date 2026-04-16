using ContextualOptimization 
using DataFrames, CSV, XLSX, Dates  
using JuMP, Gurobi  
using Distributions, LinearAlgebra, Statistics, StatsBase, Random, CovarianceEstimation  
using DotEnv, JSON3, HTTP, YFinance, MarketData 




# Set random seed for reproducibility
Random.seed!(42)


@testset "ContextualOptimization.jl" begin
    include("test_models.jl")
    include("test_moments.jl")
    include("test_splitting.jl")
    include("test_performance.jl")
    include("test_backtest.jl")
end