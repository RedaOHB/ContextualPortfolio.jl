"""
  cumulative_return(𝐑) computes the cumulative value of returns

  # Parameters: 
  
   - `𝐑`: vector of portfolio returns evaluated over a set of data, 𝐑 = R₁,R₂,...,Rₙ

  # mathematic formula:  μ = ∏(1 - 𝐑) - 1

"""
function cumulative_return(𝐑) 

    μ = prod(1 .+ 𝐑) - 1

    return μ
end    
  

"""
  volatility(𝐑) computes the standard deviation of returns 

  # Parameters: 
  
   - `𝐑`: vector of portfolio returns evaluated over a set of data, 𝐑 = R₁,R₂,...,Rₙ

  # mathematic formula:  σ(𝐑) = √((1/(1-n))*∑(rᵢ - R̄)²) 
      with R̄ = (1/n) * ∑ rᵢ
"""
function volatility(𝐑)

    σ = sqrt(sum((𝐑 .- mean(𝐑)).^2)/(length(𝐑)-1))  

    return σ
end


"""
  Conditional_Value_at_Risk(𝐑, β) computes the Conditional Value at Risk (CVaR) of returns at a confidence level of β%.

  # Parameters: 
  
   - `𝐑`: vector of portfolio returns evaluated over a set of data, 𝐑 = R₁,R₂,...,Rₙ
   - `β`: the confidence level 

  # mathematic formula:  CVaRᵦ(L) = E[L|L ≥ VaRᵦ(L)] 
      with L = - 𝐑
"""
function Conditional_Value_at_Risk(𝐑, β)

    losses = - 𝐑
    VaR = quantile(losses, β)
    CVaR = mean(losses[losses .>= VaR])

    return CVaR
end 


"""
  Sharpe_ratio(𝐑, rf) evaluates the risk-adjusted performance of returns relative to the risk-free rate rf.

  # Parameters: 
  
   - `𝐑`: vector of portfolio returns evaluated over a set of data, 𝐑 = R₁,R₂,...,Rₙ
   - `rf`: the risk-free rate

  # mathematic formula:  Sharpe = (E[𝐑] - rf) / σ(𝐑) 
"""
function Sharpe_ratio(𝐑, rf)

    expected_return = mean(𝐑)
    standard_deviation = sqrt(sum((𝐑 .- mean(𝐑)).^2)/(length(𝐑)-1))
    Sharpe = ((expected_return - rf) / standard_deviation) 

    return Sharpe
end


"""
  Omega_ratio(𝐑, τ) measures the ratio of gains to losses of returns above a chosen threshold τ.

  # Parameters: 
  
   - `𝐑`: vector of portfolio returns evaluated over a set of data, 𝐑 = R₁,R₂,...,Rₙ
   - `τ`: the threshold level

  # mathematic formula:  Ω = ∑ max(Rᵢ - τ, 0) / ∑ max(τ - Rᵢ, 0)
"""
function Omega_ratio(𝐑, τ)

    Ω = sum(max.(𝐑 .- τ, 0)) / sum(max.(τ .- 𝐑, 0))

    return Ω
end


"""
  Assets_number(Portfolio) returns the number of assets included in the portfolio composition. 

  # Parameters: 
  
   - `Portfolio`: vector of weights representing the proportion invested in each asset.

  Note that only assets with at least 1% allocation are considered.
"""
function Assets_number(Portfolio)

    No_Assets = count(z -> z>=0.01, Portfolio) 
    
    return No_Assets
end


"""
  Diversification(Portfolio) measures the diversification level of the portfolio.  

  # Parameters: 
  
   - `Portfolio`: vector of weights representing the proportion invested in each asset.

  # mathematic formula:  HHI = 1/∑ ωᵢ²
    where Portfolio = ω₁,ω₂,…,ωₙ
"""
function Diversification(Portfolio)

    X = Portfolio[Portfolio .> 0.01]
    HHI = sum((X/sum(X)).^2)    

    return HHI
end


"""
  Turnover(Xₜ₋₁, Xₜ) measures changes in portfolio composition over time.

  # Parameters: 
  
   - `Xₜ₋₁` and `Xₜ`: portfolio weight vectors at t-1 and t respectively.
     
     Xₜ₋₁ = |ωₜ₋₁,₁ ωₜ₋₁,₂ … ωₜ₋₁,ₙ|
     Xₜ₋₁ = |ωₜ,₁ ωₜ,₂ … ωₜ,ₙ|
                  
      where ωₖᵢ represents the proportion invested in asset i at the kᵗʰ iteration of the rolling window approach

  # mathematic formula:  Turnoverₜ = (1/2) * ∑ᵢ|ωₜ₋₁,ᵢ - ωₜ,ᵢ|
"""
function Turnover(Xₜ₋₁, Xₜ)        

    turnover = 0.5*sum(abs.(Xₜ - Xₜ₋₁))

    return turnover
end