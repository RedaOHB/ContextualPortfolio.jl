#=
  mean_variance_model(μ, Σ, η)

  defines and solves the mean–variance portfolio optimization problem, returning the optimal asset weights.
  
  /*\ Parameters:

  * `μ` is the mean vector of data
  * `Σ` is the covariance matrix of data
  * `η` the risk aversion parameter 

  /*\ mathematic formula:

  Assuming a set of 𝑛 assets with expected returns μ = (μ₁,μ₂,…,μₙ) and covariance matrix of returns Σ, the mean_variance model finds 
  the asset weights 𝐱 = (x₁,x₂,…,xₙ) that solve the following quadratic programming problem:

                                       minₓ  -μᵀ𝐱 + η𝐱ᵀΣ𝐱 
                                       s.t   1ᵀ𝐱 = 1
                                               𝐱 ≥ 0
=#


function mean_variance_model(μ, Σ, η)

    n = length(μ)  # number of assets

    model = Model(Gurobi.Optimizer)  # create an optimization model using the Gurobi solver

    # solver parameters ------------------------------------------------------
    set_optimizer_attribute(model, "TimeLimit", 600)
    set_optimizer_attribute(model, "OutputFlag", 1)
    # --------------------------------------------------------------------------

    #--- variables:
    @variable(model, x[1:n] >= 0)  # decision variables: weight invested in each asset 

    #--- constraints:
    @constraint(model, sum(x) == 1)  # budget constraint: the sum of portfolio weights must equal 1

    #---objective:
    @objective(model, Min, -sum(μ.*x) + η*x'*Σ*x)  # minimize variance and maximize return of portfolio 

    optimize!(model)

    println("Termination status: ", termination_status(model))  # the solver's termination status

    return value.(x)
end