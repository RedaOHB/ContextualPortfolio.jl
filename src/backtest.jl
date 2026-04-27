struct  backtestParameters
    estimation_horizon::Union{Int,Nothing}
    evaluation_horizon::Union{Int,Nothing}
    returns::DataFrame
    context::Union{DataFrame,Nothing}
    model::Function
    η::Float64
    start_date::Date
    end_date::Date
    optimizer::Any

    function backtestParameters(; estimation_horizon, evaluation_horizon, returns, context, model, η, start_date, end_date, optimizer=HiGHS.Optimizer)
        new(estimation_horizon, evaluation_horizon, returns, context, model, η, start_date, end_date, optimizer)
    end
end


"""
  backtest_portfolio(params::backtestParameters)

  runs a portfolio backtest using a rolling rebalancing strategy. The function takes its inputs
  from the BacktestParameters structure and returns:
   - the sequence of portfolios generated over the rolling window
   - the corresponding performance measures for each portfolio
   - the aggregated (overall) performance over the full evaluation period

  # Parameters:

   - `estimation_horizon`: number of months used for estimation
   - `evaluation_horizon`: number of months used for evaluation
   - `returns`: historical returns data
   - `context`: Joint contextual data
   - `model`: optimization model used
   - `η`: Risk aversion parameter
   - `start_date`: starting date of the dataset
   - `end_date`: ending date of the dataset
   - `optimizer`: JuMP-compatible solver (default: `HiGHS.Optimizer`)

"""

function backtest_portfolio(params::backtestParameters)

    final_Date = params.start_date + Month(params.estimation_horizon) - Day(1)   # end of the first rolling window

    # stores the performance metrics
      portfolio_performance = DataFrame(Start_Period=Date[], End_Period=Date[], Return=Float64[], Volatility=Float64[], CVaR=Float64[], Sharpe_ratio=Float64[], Omega_ratio=Float64[], No_Assets=Float64[], HHI=Float64[])

    # stores all portfolios
      if isnothing(params.context)
         portfolios = zeros(0,size(params.returns[:,2:end],2))
        data = params.returns
      else
         portfolios = zeros(0,size(params.returns[:,2:end],2))
        data = align(params.returns, params.context)
      end

    n = size(params.returns[:,2:end], 2)  # number of assets
    d = isnothing(params.context) ? 0 : size(params.context[:,2:end], 2)  # number of contextual features

    Start = params.start_date
    End = params.end_date
    turn = Float64[]

    Optimization_model = nothing
    first_context = 1
    last_context = params.estimation_horizon

    while final_Date <= params.end_date - Month(params.evaluation_horizon) + Day(1)  # the rolling window approach

      # define the training and validation sets
        Train, Test, μ_train, Σ_train = split_sample(data, Start, params.estimation_horizon, params.evaluation_horizon)

        if isnothing(params.context)

          if params.model == optimize_mv
            X = params.model(μ_train, Σ_train, params.η; optimizer=params.optimizer)
            Optimization_model = "Mean Variance"
          elseif params.model == optimize_mvbu
            X = params.model(μ_train, Σ_train, params.η, Train[:,1:n]; optimizer=params.optimizer)
            Optimization_model = "Mean Variance Box Uncertainty"
          else
            X = params.model(μ_train, Σ_train, params.η, Train[:,1:n]; optimizer=params.optimizer)
            Optimization_model = "Mean Variance Ellipsoidal Uncertainty"
          end
          portfolios = vcat(portfolios, X')   # store the generated portfolio

        else

          μᵣ_ₛ, Σᵣ_ₛ = conditional_moments(Train, params.context, last_context, first_context)

          if params.model == optimize_mv
            X = params.model(μᵣ_ₛ, Σᵣ_ₛ, params.η; optimizer=params.optimizer)
            Optimization_model = "Mean Variance"
          elseif params.model == optimize_mvbu
            X = params.model(μᵣ_ₛ, Σᵣ_ₛ, params.η, Train[:,1:n]; optimizer=params.optimizer)
            Optimization_model = "Mean Variance Box Uncertainty"
          else
            X = params.model(μᵣ_ₛ, Σᵣ_ₛ, params.η, Train[:,1:n]; optimizer=params.optimizer)
            Optimization_model = "Mean Variance Ellipsoidal Uncertainty"
          end

          portfolios = vcat(portfolios, X')   # store the generated portfolio

          # validation set
            Test = Test[:,1:size(Test,2)-size(params.context,2)+1]

        end

        𝐑 = Test * X

        No_Assets = Assets_number(X)
        HHI = Diversification(X)
        μ = cumulative_return(𝐑)
        σ = volatility(𝐑) * sqrt(length(𝐑))
        Ω = Omega_ratio(𝐑, 0.0)
        Sharpe = Sharpe_ratio(𝐑, 0.0) * sqrt(length(𝐑))
        C_VaR = Conditional_Value_at_Risk(𝐑, 0.95) * sqrt(length(𝐑))

        if size(portfolios, 1) == 1
          push!(turn, 0.0)
        else
          T = Turnover(portfolios[end-1,:], portfolios[end,:])
          push!(turn, T)
        end


        push!(portfolio_performance, (final_Date+Day(1),final_Date+Month(params.evaluation_horizon), μ, σ, C_VaR, Sharpe, Ω, No_Assets, HHI))

        # slide the time window by "evaluation_horizon" months
          Start = Start + Month(params.evaluation_horizon)
          final_Date = Start + Month(params.estimation_horizon) - Day(1)

        last_context += 1
        first_context += 1

    end
    portfolio_performance.turnover = turn

    # evaluate the global performance (annual frequency)
      # store the global performance metrics
        global_performance = DataFrame(Model=String[], Mean_return=Float64[], Volatility=Float64[], CVaR=Float64[], Sharpe_ratio=Float64[], Omega_ratio=Float64[], No_Assets=Float64[], HHI=Float64[], turnover=Float64[])

      aggregated_returns = portfolio_performance[:,"Return"]

      # annual mean returns
        μ = mean(aggregated_returns) * (12/params.evaluation_horizon)
      # annual volatility
        σ = volatility(aggregated_returns) * sqrt(12/params.evaluation_horizon)
      # annual Conditional Value at Risk
        C_VaR = Conditional_Value_at_Risk(aggregated_returns, 0.95) * sqrt(12/params.evaluation_horizon)
      # annual Sharpe ratio
        Sharpe = Sharpe_ratio(aggregated_returns, 0.0) * sqrt(12/params.evaluation_horizon)
      # Omega ratio
        Ω = Omega_ratio(aggregated_returns, 0.0)
      # Average of assets number, HHI and Turnover
        No_Assets = mean(portfolio_performance[:,"No_Assets"])
        HHI = mean(portfolio_performance[:,"HHI"])
        Turn = mean(portfolio_performance[:,"turnover"])

      push!(global_performance, (Optimization_model, μ, σ, C_VaR, Sharpe, Ω, No_Assets, HHI, Turn))

    return portfolios, portfolio_performance, global_performance

end
