#=
  These functions evaluate the portfolio performamce for the out-of-sample data
  
  * Contruction measures: 
                --> Assets_number
                --> Diversification
                --> Turnover
  * Performance measures:
                --> cumulative_return
                --> volatility
                --> Conditional_Value_at_Risk
                --> Sharpe_ratio
                --> Omega_ratio

=#

"""
  cumulative_return(𝐑) calculate the cumulative value of returns

  # Parameters: 
  
   - `𝐑` is a vector of portfolio returns evaluate for set of data, 𝐑 = R₁,R₂,...,Rₜ

  # mathematic formula:  μ = ∏(1 - 𝐑) - 1

"""
function cumulative_return(𝐑::Vector{Float64}) 

    μ = prod(1 .+ 𝐑) - 1

    return μ
end 
  

"""
  volatility(𝐑) evaluate the standard deviation of returns 

  # Parameters: 
  
   - `𝐑` is a vector of portfolio returns evaluate for set of data, 𝐑 = R₁,R₂,...,Rₜ

  # mathematic formula:  σ(𝐑) = √((1/(1-n))*∑(rᵢ - R̄)²) 
      with R̄ = (1/n) * ∑ rᵢ
"""
function volatility(𝐑::Vector{Float64})

    σ = sqrt(sum((𝐑 .- mean(𝐑)).^2)/(length(𝐑)-1))  

    return σ
end


"""
  Conditional_Value_at_Risk(𝐑, β) calculate the CVaR at β% of confidence level 

  # Parameters: 
  
   - `𝐑` is a vector of portfolio returns evaluate for set of data, 𝐑 = R₁,R₂,...,Rₜ
   - `β` is the confidence level

  # mathematic formula:  CVaRᵦ(L) = E[L|L ≥ VaRᵦ(L)] 
      with L = - 𝐑
"""
function Conditional_Value_at_Risk(𝐑::Vector{Float64}, β::Float64)

    losses = - 𝐑
    VaR = quantile(losses, β)
    CVaR = mean(losses[losses .>= VaR])

    return CVaR
end 


"""
  Sharpe_ratio(𝐑, rf) evaluate the risk-adjusted performance  

  # Parameters: 
  
   - `𝐑` is a vector of portfolio returns evaluate for set of data, 𝐑 = R₁,R₂,...,Rₜ
   - `rf` is the risk-free rate

  # mathematic formula:  Sharpe = (E[𝐑] - rf) / σ(𝐑) 
"""
function Sharpe_ratio(𝐑::Vector{Float64}, rf::Float64)

    expected_return = mean(𝐑)
    standard_deviation = sqrt(sum((𝐑 .- mean(𝐑)).^2)/(length(𝐑)-1))
    Sharpe = ((expected_return - rf) / standard_deviation) 

    return Sharpe
end


"""
  Omega_ratio(𝐑, τ) calculate the fraction gain/loss above a chosen threshold 

  # Parameters: 
  
   - `𝐑` is a vector of portfolio returns evaluate for set of data, 𝐑 = R₁,R₂,...,Rₜ
   - `τ` is the threshold

  # mathematic formula:  Ω = ∑ max(Rᵢ - τ, 0) / ∑ max(τ - Rᵢ, 0)
"""
function Omega_ratio(𝐑::Vector{Float64}, τ::Float64)

    Ω = sum(max.(𝐑 .- τ, 0)) / sum(max.(τ .- 𝐑, 0))

    return Ω
end


"""
  Assets_number(Portfolio) returns the number of assets including on the portfolio composition 

  # Parameters: 
  
   - `Portfolio` is a vector of weight, which represents the part investing in each asset
  
  Note that only assets with 1% investing are considered  
"""
function Assets_number(Portfolio)

    No_Assets = count(z -> z>=0.01, Portfolio) 
    
    return No_Assets
end


"""
  Diversification(Portfolio) gives the diversification level of the portfolio  

  # Parameters: 
  
   - `Portfolio` is a vector of weight, which represents the part investing in each asset

  # mathematic formula:  HHI = 1/∑ ωᵢ²
  where Portfolio = ω₁,ω₂,…,ωₙ
"""
function Diversification(Portfolio)

    X = Portfolio[Portfolio .> 0.01]
    HHI = sum((X/sum(X)).^2)    

    return HHI
end


"""
  Turnover(Portfolios) evaluate the changes of portfolio composition over time 

  # Parameters: 
  
   - `Portfolios` contains all portfolio's weight resulting by the rolling window approach (to calculate the Turnover)
     
     Portfolios = |ω₁₁ ω₁₂ … ω₁ₙ|  
                  |ω₂₁ ω₂₂ … ω₂ₙ|
                  | ⋮    ⋮     ⋮ | 
                  |ωₜ₁  ωₜ₂ … ωₜₙ |
      
      where ωₖᵢ represents the part investing in asset "i" at the kᵗʰ iteration of rolling window approach

  # mathematic formula:  Turnoverₜ = (1/2) * ∑ᵢ|ωₜ₋₁,ᵢ - ωₜ,ᵢ|
"""
function Turnover(Portfolios)

    turnover = [0.5*sum(abs.(Portfolios[i,:] - Portfolios[i-1,:])) for i in 2:size(Portfolios,1)]

    return turnover
end