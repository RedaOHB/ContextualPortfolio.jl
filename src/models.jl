"""
  optimize_mv(μ, Σ, η; optimizer=Clarabel.Optimizer)

  defines and solves the mean–variance portfolio optimization problem, returning the optimal asset weights.

  # Parameters:

   - `μ` is the mean vector of data
   - `Σ` is the covariance matrix of data
   - `η` the risk aversion parameter
   - `optimizer`: the JuMP-compatible solver to use (default: `Clarabel.Optimizer`)

  # mathematic formula:

  Assuming a set of 𝑛 assets with expected returns μ = (μ₁,μ₂,…,μₙ) and covariance matrix of returns Σ, the mean_variance model finds
  the asset weights 𝐱 = (x₁,x₂,…,xₙ) that solve the following quadratic programming problem:

                                       minₓ  -μᵀ𝐱 + η𝐱ᵀΣ𝐱
                                       s.t   1ᵀ𝐱 = 1
                                               𝐱 ≥ 0
"""


function optimize_mv(μ, Σ, η; optimizer=Clarabel.Optimizer)

    n = length(μ)  # number of assets

    model = Model(optimizer)
    set_time_limit_sec(model, 600)
    set_silent(model)

    #--- variables:
    @variable(model, x[1:n] >= 0)  # decision variables: weight invested in each asset

    #--- constraints:
    @constraint(model, sum(x) == 1)  # budget constraint: the sum of portfolio weights must equal 1

    #---objective:
    @objective(model, Min, -sum(μ.*x) + η*x'*Σ*x)  # minimize variance and maximize return of portfolio

    optimize!(model)

    println("Termination status: ", termination_status(model))

    return value.(x)
end



"""
  optimize_mvbu(μ, Σ, η, data; optimizer=Clarabel.Optimizer)

  solve mean-variance optimization under box uncertainty on parameters

  # Parameters:

   - `μ`: mean vector of data
   - `Σ`: covariance matrix of data
   - `η`: risk aversion parameter
   - `data`: historical returns
   - `optimizer`: the JuMP-compatible solver to use (default: `Clarabel.Optimizer`)

  # mathematic formula:

  Assuming a set of 𝑛 assets with expected returns μ = (μ₁,μ₂,…,μₙ) and covariance matrix of returns Σ, the mean_variance model finds
  the asset weights 𝐱 = (x₁,x₂,…,xₙ) that solve the following quadratic programming problem:

                                       minₓ  -μᵀ𝐱 + η𝐱ᵀΣ𝐱 + ϵᵀ𝐱
                                       s.t   1ᵀ𝐱 = 1
                                               𝐱 ≥ 0

  where ϵ: the size (radius) of the ellipsoidal uncertainty set

"""

function optimize_mvbu(μ, Σ, η, data; optimizer=Clarabel.Optimizer)

      n = length(μ)  # number of assets
      S = std(data, dims=1)   # standard deviation of each asset's returns
      ϵ = 1.96 .* S ./ sqrt(size(data,1))   # the half-width of the 95% confidence interval for each mean return

      model = Model(optimizer)
      set_time_limit_sec(model, 600)
      set_silent(model)

      #---variables:
      @variable(model, x[1:n] >= 0)  # decision variables: weight invested in each asset

      #---constraints:
      @constraint(model, sum(x) == 1)  # budget constraint: the sum of portfolio weights must equal 1

      #---objective:
      @objective(model, Min, -sum(μ.*x) + η*x'*Σ*x + (ϵ*x)[1])  # minimize uncertainty penalty + variance and maximize return of portfolio
      # (ϵ * x)[1] represents the worst-case mean deviation due to uncertainty

      optimize!(model)

      println("Termination status: ", termination_status(model))

      return value.(x)
end


"""
  optimize_mveu(μ, Σ, η, data; optimizer=Clarabel.Optimizer)

  solve mean-variance optimization under ellipsoidal uncertainty on parameters

  # Parameters:

   - `μ`: mean vector of data
   - `Σ`: covariance matrix of data
   - `η`: risk aversion parameter
   - `data`: historical returns
   - `optimizer`: the JuMP-compatible solver to use (default: `Clarabel.Optimizer`)

  # mathematic formula:

  Assuming a set of 𝑛 assets with expected returns μ = (μ₁,μ₂,…,μₙ) and covariance matrix of returns Σ, the mean_variance model finds
  the asset weights 𝐱 = (x₁,x₂,…,xₙ) that solve the following quadratic programming problem:

                                       minₓ  -μᵀ𝐱 + η𝐱ᵀΣ𝐱 + ϵ*(𝐱ᵀ*Σ_mu*𝐱ᵀ)
                                       s.t   1ᵀ𝐱 = 1
                                               𝐱 ≥ 0

  where Σ_mu: variance of the estimation error of the mean
        ϵ: the size (radius) of the ellipsoidal uncertainty set
"""

function optimize_mveu(μ, Σ, η, data; optimizer=Clarabel.Optimizer)

    n = length(μ)  # number of assets
    Σ_mu = zeros(n,n)  # initialize the covariance matrix of estimation errors in expected returns
    Σ_mu[diagind(Σ_mu)] = diag(Σ)  # start with the diagonal of Σ (asset return variances)
    for i in 1:n
        Σ_mu[i,i] = sqrt(Σ_mu[i,i])/sqrt(size(data,1))
    end
    # Convert variance of returns into variance of the estimation error of the mean:
    # Var(μ̂) = σ² / T
    # where T = number of observations

    χ₂ = Chisq(n)   # the chi-square distribution with n degrees of freedom
    𝒒_alpha = quantile(χ₂, 0.95)   # 95% quantile of the chi-square distribution
    ϵ = sqrt(𝒒_alpha)  # size (radius) of the ellipsoidal uncertainty set

    model = Model(optimizer)
    set_time_limit_sec(model, 600)
    set_silent(model)

    #---variables:
    @variable(model, x[1:n] >= 0)  # decision variables: weight invested in each asset

    #---constraints:
    @constraint(model, sum(x) == 1)  # budget constraint: the sum of portfolio weights must equal 1

    #---objective:
    @objective(model, Min, -sum(μ.*x) + η*x'*Σ*x + ϵ*(x'*Σ_mu*x) )  # minimize: variance + uncertainty-adjustment and maximize return of portfolio
    # x' Σ_mu x     = uncertainty penalty from ellipsoidal mean estimation error

    optimize!(model)

    println("Termination status: ", termination_status(model))

    return value.(x)
end
