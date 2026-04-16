@testset "Conditional Moments" begin

        # Create data with dates
        dates = Date(2020, 01, 01):Day(1):Date(2024, 12, 31)
        n_periods = length(dates)
        n_assets = 5
        n_context = 2
        
        # Create DataFrame with Date column and asset returns (daily returns)
        returns = DataFrame(Date = dates)
        for i in 1:n_assets
            returns[!, Symbol("Asset$i")] = randn(n_periods) * 0.01
        end

        # Create DataFrame with Date column and contextual features (monthly)
        dates = Date(2020, 01, 01):Month(1):Date(2024, 12, 31)
        n_periods = length(dates)
        context = DataFrame(Date = dates)
        for i in 1:n_context
            context[!, Symbol("Feature$i")] = randn(n_periods) 
        end

        # Aligning returns and contextual features by date
        data = align(returns, context)

        # Test parameters
        first_context = 1
        last_context = 48  # Last context observed in of estimation period

        # Test moment calculation
        μᵣ_ₛ, Σᵣ_ₛ = conditional_moments(returns, context, last_context, first_context)
        
        # Check dimensions
        @test size(μᵣ_ₛ) == (n_assets)
        @test size(Σᵣ_ₛ) == (n_assets, n_assets)
        
        # Check symmetry of covariance
        @test Σᵣ_ₛ ≈ Σᵣ_ₛ'
        
        # Check positive semi-definiteness
        eigenvals = eigvals(Σᵣ_ₛ)
        @test all(eigenvals .>= -1e-10)  # Allow small numerical errors
        
end