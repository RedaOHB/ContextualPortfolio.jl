@testset "Backtest Integration" begin
    @testset "Basic Backtest" begin
        # Generate synthetic data
        Random.seed!(123)
        T, N, K = 200, 5, 2
        returns = randn(T, N) * 0.01 .+ 0.0005
        context = randn(T, K)
        
        # Run backtest
        model = MeanVariance(risk_aversion=0.5)
        results = backtest(
            returns,
            context, 
            model;
            train_size=0.7,
            rebalance_freq=20
        )
        
        # Check results structure
        @test haskey(results, :weights) || hasproperty(results, :weights)
        @test haskey(results, :returns) || hasproperty(results, :returns)
        
        # Check dimensions
        n_rebalance = length(results.returns)
        @test n_rebalance > 0
        
        # Check weight constraints
        for w in eachrow(results.weights)
            @test all(w .>= -1e-6)  # Non-negative (allow small numerical errors)
            @test sum(w) ≈ 1.0 atol=1e-4  # Budget constraint
        end
    end
    
    @testset "Different Models" begin
        Random.seed!(456)
        T, N, K = 150, 5, 2
        returns = randn(T, N) * 0.01
        context = randn(T, K)
        
        # Test all models
        models = [
            MeanVariance(risk_aversion=0.5),
            CVaR(confidence_level=0.95),
            RobustOptimization(kappa=0.1)
        ]
        
        for model in models
            results = backtest(returns, context, model; train_size=0.7)
            @test length(results.returns) > 0
        end
    end
    
    @testset "Performance Evaluation" begin
        Random.seed!(789)
        T, N, K = 200, 5, 2
        returns = randn(T, N) * 0.01 .+ 0.0005
        context = randn(T, K)
        
        model = MeanVariance(risk_aversion=0.5)
        results = backtest(returns, context, model; train_size=0.7)
        
        # Evaluate performance
        metrics = evaluate_performance(results)
        
        # Check that metrics exist and are reasonable
        @test haskey(metrics, :sharpe_ratio) || hasproperty(metrics, :sharpe_ratio)
        @test haskey(metrics, :volatility) || hasproperty(metrics, :volatility)
        @test metrics.volatility > 0
    end
    
    @testset "Edge Cases" begin
        # Small dataset
        returns_small = randn(50, 3) * 0.01
        context_small = randn(50, 2)
        
        model = MeanVariance()
        results = backtest(returns_small, context_small, model; train_size=0.6)
        @test length(results.returns) > 0
    end
end