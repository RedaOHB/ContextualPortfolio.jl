struct  Backtest_Parameters
    estimation_horizon::Union{Int,Nothing}
    evaluation_horizon::Union{Int,Nothing}
    returns::DataFrame
    context::Union{DataFrame,Nothing}
    model::Union{Function,Symbol}
    η::Float64
    start_date::Date
    end_date::Date
    optimizer::Any

    function Backtest_Parameters(; estimation_horizon, evaluation_horizon, returns, context, model, η, start_date, end_date, optimizer=Clarabel.Optimizer)
        new(estimation_horizon, evaluation_horizon, returns, context, model, η, start_date, end_date, optimizer)
    end
end


"""
  backtest_portfolio(params::Backtest_Parameters)

  runs a portfolio backtest using a rolling rebalancing strategy. The function takes its inputs
  from the Backtest_Parameters structure and returns:
   - the sequence of portfolios generated over the rolling window
   - the corresponding performance measures for each portfolio
   - the average performance over the full evaluation period
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
   - `optimizer`: JuMP-compatible solver (default: `Clarabel.Optimizer`)

"""                               

function backtest_portfolio(params::Backtest_Parameters)

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
          elseif params.model == optimize_mveu
            X = params.model(μ_train, Σ_train, params.η, Train[:,1:n]; optimizer=params.optimizer)
            Optimization_model = "Mean Variance Ellipsoidal Uncertainty"
          else 
            X = fill(1.0/n, n)
            Optimization_model = "Uniform portfolio"
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
          elseif params.model == optimize_mveu
            X = params.model(μᵣ_ₛ, Σᵣ_ₛ, params.η, Train[:,1:n]; optimizer=params.optimizer)
            Optimization_model = "Mean Variance Ellipsoidal Uncertainty"
          else
            X = fill(1.0/n, n)
            Optimization_model = "Uniform portfolio"
          end

          portfolios = vcat(portfolios, X')   # store the generated portfolio

          # validation set
            Test = Test[:,1:size(Test,2)-size(params.context,2)+1]
 
        end

        println(size(Test))    


        # performance metrics
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

        last_context += params.evaluation_horizon
        first_context += params.evaluation_horizon

    end
    portfolio_performance.turnover = turn
    portfolio_performance.Cumulative_Return =  cumprod(1 .+ portfolio_performance.Return) .- 1  # calculte the cumulative return

    # evaluate the average/global performance (annual frequency)
      # store the average performance metrics 
        average_performance = DataFrame(Model=String[], mean_Return=Float64[], mean_Volatility=Float64[], mean_CVaR=Float64[], mean_Sharpe_ratio=Float64[], mean_Omega_ratio=Float64[], mean_No_Assets=Float64[], mean_HHI=Float64[], mean_turnover=Float64[])
      # store the global performance metrics
        global_performance = DataFrame(Model=String[], global_Return=Float64[], Volatility=Float64[], CVaR=Float64[], Sharpe_ratio=Float64[], Omega_ratio=Float64[])

         
      # ******************************* Average performance ********************************************
        μ = mean(portfolio_performance.Return)
        σ = mean(portfolio_performance.Volatility)
        C_VaR = mean(portfolio_performance.CVaR)
        Sharpe = mean(portfolio_performance.Sharpe_ratio)
        Omega = mean(portfolio_performance.Omega_ratio)
        No_Assets = mean(portfolio_performance.No_Assets)
        HHI = mean(portfolio_performance.HHI)
        turn = mean(portfolio_performance.turnover)

        push!(average_performance, (Optimization_model, μ, σ, C_VaR, Sharpe, Omega, No_Assets, HHI, turn))


      # ******************************* Global performance *********************************************
      aggregated_returns = portfolio_performance.Return

      # annualized returns: Total compounded return 
        μ = (prod(1 .+ aggregated_returns))^((12/params.evaluation_horizon)/length(aggregated_returns)) - 1 
       
      # annual volatility
        σ = volatility(aggregated_returns) * sqrt(12/params.evaluation_horizon)
      
      # annual Conditional Value at Risk
        A = floor(Int, 12/params.evaluation_horizon)
        B = floor(Int,length(aggregated_returns)/A)
        R_annual = [prod(1 .+ aggregated_returns[A*(i-1)+1:A*i]) - 1 for i in 1:B]
        if A*B != length(aggregated_returns)
          push!(R_annual, (prod(1 .+ aggregated_returns[A*B+1:end])^((12/params.evaluation_horizon)/length(aggregated_returns[A*B+1:end]))) - 1)
          #R_annual = vcat(R_annual, [(prod(1 .+ aggregated_returns[A*B+1:end])^((12/params.evaluation_horizon)/length(aggregated_returns[A*B+1:end]))) - 1 ])
        end

        C_VaR = Conditional_Value_at_Risk(R_annual, 0.95)

      # annual Sharpe ratio
        Sharpe = Sharpe_ratio(aggregated_returns, 0.0) * sqrt(12/params.evaluation_horizon)

      # Omega ratio
        Ω = Omega_ratio(aggregated_returns, 0.0) 


      push!(global_performance, (Optimization_model, μ, σ, C_VaR, Sharpe, Ω))


    return portfolios, portfolio_performance, average_performance, global_performance

end
