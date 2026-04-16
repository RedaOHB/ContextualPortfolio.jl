#=
  BacktestParameters

  container for all parameters required to run the portfolio backtesting procedure. It specifies the estimation and evaluation horizons, start
  date, input data, optional contextual information, the portfolio optimization model to be used, and its associated parameters.
=#

include("models.jl")
include("moments.jl")
include("splitting.jl")
include("utils.jl")
include("performance.jl")

struct  backtestParameters
    estimation_horizon::Union{Int,Nothing}
    evaluation_horizon::Union{Int,Nothing}
    returns::DataFrame
    context::Union{DataFrame,Nothing}
    model::Function
    η::Float64
    start_date::Date
    end_date::Date
      
    function backtestParameters(; estimation_horizon, evaluation_horizon, returns, context, model, η, start_date, end_date)
        new(estimation_horizon, evaluation_horizon, returns, context, model, η, start_date, end_date)
    end
end


"""
  backtest_portfolio(params::backtestParameters)

  runs a portfolio backtest using a rolling rebalancing strategy (rolling window). Its parameters are provided through the "BacktestParameters" structure.
  The function returns three objects:
   - the sequence of portfolios obtained over the rolling window
   - the corresponding performance measures for each portfolio
   - the aggregated (global) performance over the full evaluation period

  # Parameters:

   - `estimation_horizon`: number of months used for estimation 
   - `evaluation_horizon`: number of months used for evaluation
   - `returns`: historical returns
   - `context`: Joints contextual data
   - `model`: Optimization model
   - `η`: Risk aversion
   - `start_date`: Start date for data
   - `end_date`: End date for data

"""

function backtest_portfolio(params::backtestParameters)

    final_Date = params.start_date + Month(params.estimation_horizon) - Day(1)   # end of the first rolling window

    # stores the performance metrics 
      portfolio_performance = DataFrame(Start_Period=Date[], End_Period=Date[], Return=Float64[], Volatility=Float64[], CVaR=Float64[], Sharpe_ratio=Float64[], Omega_ratio=Float64[], No_Assets=Float64[], HHI=Float64[])
    
    # stores all portfolios 
      if params.context == :nothing
        portfolios = zeros(0,size(params.returns[:,2:end],2))
        data = returns                  
      else
        portfolios = zeros(0,size(params.returns[:,2:end],2))
        data = align(returns, context) 
      end

    n = size(returns[:,2:end], 2)  # number of assets
    d = size(context[:,2:end], 2)  # number of contextual features

    Start = params.start_date  
    End = params.end_date
      
    global Optimization_model = nothing    

    while final_Date <= params.end_date - Month(params.evaluation_horizon) + Day(1)  # the rolling window approach

      # define the training and validation sets
         global Train, Test, μ_train, Σ_train = split_sample(data, Start, params.estimation_horizon, params.evaluation_horizon)
        
        if (params.context == :nothing) 
          
          if params.model == optimize_mv
            X = params.model(μ_train, Σ_train, params.η)
            Optimization_model = "Mean Variance"
          elseif params.model == optimize_mvbu
            X = params.model(μ_train, Σ_train, params.η, Train[:,1:n])
            Optimization_model = "Mean Variance Box Uncertainty"
          else            
            X = params.model(μ_train, Σ_train, params.η, Train[:,1:n])
            Optimization_model = "Mean Variance Elliposoidal Uncertainty"
          end
          portfolios = vcat(P, X')   # store the obtained portfolio
                                               
        else
          
          first_context = 1
          last_context = params.estimation_horizon  # the last context observed (index)

          μᵣ_ₛ, Σᵣ_ₛ = conditional_moments(Train, params.context, last_context, first_context)

          if params.model == optimize_mv
            X = params.model(μᵣ_ₛ, Σᵣ_ₛ, params.η)
            Optimization_model = "Mean Variance"
          elseif params.model == optimize_mvbu
            X = params.model(μᵣ_ₛ, Σᵣ_ₛ, params.η, Train[:,1:n])
            Optimization_model = "Mean Variance Box Uncertainty"
          else            
            X = params.model(μᵣ_ₛ, Σᵣ_ₛ, params.η, Train[:,1:n])
            Optimization_model = "Mean Variance Elliposoidal Uncertainty"
          end

          portfolios = vcat(portfolios, X')   # store the obtained portfolio

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

        push!(portfolio_performance, (final_Date+Day(1),final_Date+Month(params.evaluation_horizon), μ, σ, C_VaR, Sharpe, Ω, No_Assets, HHI))

        # slide the time window by "evaluation_horizon" month
          Start = Start + Month(params.evaluation_horizon)
          final_Date = Start + Month(params.estimation_horizon) - Day(1)
            
        last_context += 1
        first_context += 1

    end
    T = Turnover(portfolios)
    pushfirst!(T, 0)
    portfolio_performance.turnover = T

    # evaluate the global performance (annual frequency)
      # stores the global performance metrics
        global_performance = DataFrame(Model=String[], Mean_return=Float64[], Volatility=Float64[], CVaR=Float64[], Sharpe_ratio=Float64[], Omega_ratio=Float64[], No_Assets=Float64[], HHI=Float64[], Turnover=Float64[]) 
      
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
        turnover = mean(portfolio_performance[:,"turnover"])

      push!(global_performance, (Optimization_model, μ, σ, C_VaR, Sharpe, Ω, No_Assets, HHI, turnover))
      
    return portfolios, portfolio_performance, global_performance

end
