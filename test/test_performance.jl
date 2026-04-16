@testset "Performance Metrics" begin

    @testset "Cumulative return" begin

        # Simple test returns
        returns = [0.01, 0.02, -0.01, 0.03, -0.02]
        
        # Test cumulative return
        μ = cumulative_return(returns)
        @test μ ≈ 0.029485... atol=1e-3
    end

    @testset "Volatility" begin

        returns = [0.01, 0.02, -0.01, 0.03, -0.02]
        
        # Test volatility
        σ = volatility(returns)
        @test σ > 0
    end

    @testset "CVaR Calculation" begin

        returns = randn(1000) * 0.01
        
        # Calculate 95% CVaR
        CVaR = Conditional_Value_at_Risk(returns, 0.95)
        
        @test CVaR >= quantile(-returns, 0.95)  # CVaR >= Var
        @test CVaR > 0  # Should be positive (it's a loss)
    end
    
    @testset "Sharpe Ratio" begin

        returns = [0.01, 0.02, 0.015, 0.01, 0.02]
        rf = 0.0
        
        Sharpe = Sharpe_ratio(returns, rf)
        @test Sharpe > 0
    end

    @testset "Omega Ratio" begin

        returns = [0.01, 0.02, 0.015, 0.01, 0.02]
        τ = 0.0
        
        Ω = Omega_ratio(returns, τ)
        @test Ω > 0
    end

    @testset "Assets Number" begin

        Portfolio = fill(0.1, 10)  # Equal weights
        No_Assets = Assets_number(Portfolio) 

        @test sum(No_Assets) == 10
    end
    
    @testset "HHI" begin

        # Equal weights - minimum concentration
        Portfolio_equal = fill(0.1, 10)
        HHI_equal = Diversification(Portfolio_equal)
        @test HHI_equal ≈ 0.1
        
        # Concentrated portfolio
        Portfolio_conc = [0.8, 0.2, zeros(8)...]
        HHI_conc = Diversification(Portfolio_conc)
        @test HHI_conc ≈ 0.68
        @test HHI_conc > HHI_equal
    end
    
    @testset "Turnover" begin

        Portfolios = [0.5, 0.3, 0.2 ,    # Portfolio at t
                     0.4, 0.4, 0.2]      # Portfolio at t1
        
        turnover = Turnover(Portfolios)
        @test turnover[1] ≈ 0.1
    end
end