@testset "Data Splitting" begin

        # Create test data with dates
        dates = Date(2020, 01, 01):Day(1):Date(2024, 12, 31)
        n_periods = length(dates)
        n_assets = 10

        # Create DataFrame with Date column and asset returns (daily returns)
        data = DataFrame(Date = dates)
        for i in 1:n_assets
            data[!, Symbol("Asset$i")] = randn(n_periods) * 0.01
        end

        # Test parameters
        start_date = Date(2020, 01, 01)
        estimation_horizon = 48  # 48 months = 4 years
        evaluation_horizon = 12   # 12 months = 1 year

        # Split data
        Train_data, Test_data, μ_train, Σ_train = split_sample(
            data,
            start_date,
            estimation_horizon,
            evaluation_horizon
        )

        # Check dimensions
        @test size(Train_data, 1) > 0
        @test size(Train_data, 2) == n_assets               # 10 assets
        @test size(Test_data, 1) > 0
        @test size(Test_data, 2) == n_assets                # 10 assets

        # Check mean vector
        @test length(μ_train) == n_assets
        @test μ_train ≈ vec(mean(Train_data, dims=1)) atol=1e-10

        # Check covariance matrix
        @test size(Σ_train) == (n_assets, n_assets)
        @test Σ_train ≈ Σ_train'  # Symmetric

        # Check positive semi-definite
        eigenvals = eigvals(Σ_train)
        @test all(eigenvals .>= -1e-10)  # Allow small numerical errors

end
