@testset "Backtest Integration" begin

    # Generate synthetic data
    Random.seed!(123)

    # Create data with dates
    dates = Date(2020, 01, 01):Day(1):Date(2024, 12, 31)
    n_periods = length(dates)
    n_assets = 5
    n_context = 2
        
    # Create DataFrame with Date column and asset returns (daily returns)
    returns = DataFrame(Date = dates)
    for i in 1:n_assets
        returns[!, Symbol("Asset$i")] = randn(n_periods) * 0.01 .+ 0.0005
    end

    # Create DataFrame with Date column and contextual features (monthly)
    dates = Date(2020, 01, 01):Month(1):Date(2024, 12, 31)
    n_periods = length(dates)
    # Create the first feature
    context_1 = DataFrame(Date = dates) 
    context_1[!, Symbol("Feature_1")] = randn(n_periods)
    # Create the second feature
    context_2 = DataFrame(Date = dates)
    context_2[!, Symbol("Feature_2")] = randn(n_periods)

    # Align contextual features by date
    context = align(context_1, context_2)

    # Choose optimization model
    model = optimize_mv  # Mean Variance model

    # Define the parameters structure 
    Parameters = backtestParameters( 
                estimation_horizon = 48,  # 48 months of estimation
                evaluation_horizon = 1,   # 1 month of evaluation
                returns = returns, 
                context = context, 
                model = model,            # optimize_mv, optimize_mvbu or optimize_mveu
                η = 1.0,                  # risk aversion
                start_date = Date(2020,01,01), 
                end_date = Date(2024,01,01) ) 

    # Run backtest   
    Portfolios, Portfolio_performance, Global_performance = backtest_portfolio(Parameters)
                
    # Just check it returns something
    @test !isnothing(Portfolios)
    @test !isnothing(Portfolio_performance)
    @test !isnothing(Global_performance)
    @test length(Portfolios) > 0
    @test length(Portfolio_performance) > 0
    @test length(Global_performance) > 0
        
    # Check weight constraints
    for w in eachrow(Portfolios)
        @test all(w .>= -1e-6)  # Non-negative (allow small numerical errors)
        @test sum(w) ≈ 1.0 atol=1e-4  # Budget constraint
    end
    
end