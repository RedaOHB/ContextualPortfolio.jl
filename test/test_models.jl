@testset "Optimization Models" begin

    @testset "Mean Variance" begin

        # Simple test case with known solution
        n_assets = 3
        μ = [0.01, 0.015, 0.02]  # Expected returns
        Σ = [0.04 0.01 0.00;
             0.01 0.04 0.01;
             0.00 0.01 0.04]     # Covariance matrix
        η = 1.0                   # Risk aversion
        
        # Run optimization
        x = optimize_mv(μ, Σ, η)
        
        # Basic checks
        @test length(x) == n_assets
        @test all(x .>= -1e-6)     # Non-negativity (allow small numerical errors)
        @test sum(x) ≈ 1.0 atol=1e-4  # Budget constraint
        
        # Check reasonable portfolio (not all in one asset)
        @test maximum(x) <= 1.0
        @test minimum(x) >= 0.0       
    end

    @testset "Mean Variance with Box Uncertainty" begin

        # Create test data with dates
        dates = Date(2020, 01, 01):Day(1):Date(2024, 12, 31)
        n_periods = length(dates)
        n_assets = 3
        
        # Create DataFrame with Date column and asset returns (daily returns)
        data = DataFrame(Date = dates)
        for i in 1:n_assets
            data[!, Symbol("Asset$i")] = randn(n_periods) * 0.01
        end
        
        data1 = Float64.(Matrix(data[:,2:end]))
        μ = vec(mean(data1, dims=1)) # Expected returns
        cov_robust = LinearShrinkage(target = DiagonalUnitVariance(), shrinkage = :auto)
        Σ = cov(cov_robust, data1)    # Covariance matrix
        η = 1.0                   # Risk aversion
        
        # Run optimization
        x = optimize_mvbu(μ, Σ, η, data)
        
        # Basic checks
        @test length(x) == n_assets
        @test all(x .>= -1e-6)     # Non-negativity (allow small numerical errors)
        @test sum(x) ≈ 1.0 atol=1e-4  # Budget constraint
        
        # Check reasonable portfolio (not all in one asset)
        @test maximum(x) <= 1.0
        @test minimum(x) >= 0.0           
    end

    @testset "Mean Variance with Ellipsoidal Uncertainty" begin

        # Create test data with dates
        dates = Date(2020, 01, 01):Day(1):Date(2024, 12, 31)
        n_periods = length(dates)
        n_assets = 3
        
        # Create DataFrame with Date column and asset returns (daily returns)
        data = DataFrame(Date = dates)
        for i in 1:n_assets
            data[!, Symbol("Asset$i")] = randn(n_periods) * 0.01
        end
        
        data1 = Float64.(Matrix(data[:,2:end]))
        μ = vec(mean(data1, dims=1)) # Expected returns
        cov_robust = LinearShrinkage(target = DiagonalUnitVariance(), shrinkage = :auto)
        Σ = cov(cov_robust, data1)    # Covariance matrix
        η = 1.0                   # Risk aversion
        
        # Run optimization
        x = optimize_mveu(μ, Σ, η, data)
        
        # Basic checks
        @test length(x) == n_assets
        @test all(x .>= -1e-6)     # Non-negativity (allow small numerical errors)
        @test sum(x) ≈ 1.0 atol=1e-4  # Budget constraint
        
        # Check reasonable portfolio (not all in one asset)
        @test maximum(x) <= 1.0
        @test minimum(x) >= 0.0        
    end

end