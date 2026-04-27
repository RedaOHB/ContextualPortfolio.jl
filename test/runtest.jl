using Test
using ContextualOptimization
using DataFrames, Dates
using JuMP, HiGHS
using Distributions, LinearAlgebra, Statistics, StatsBase, Random, CovarianceEstimation

# Set random seed for reproducibility
Random.seed!(42)

@testset "ContextualOptimization.jl" begin
    include("test_models.jl")
    include("test_moments.jl")
    include("test_splitting.jl")
    include("test_performance.jl")
    include("test_backtest.jl")
end
