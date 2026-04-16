"""
  conditional_moments(data, Contextual_information, last_context, first_context)

  estimates the joint distribution of returns and contextual variables, and computes the conditional mean vector and conditional covariance matrix of returns given the provided context.

  # Parameters:

   - `data` contains the joints data (returns + context)
   - `contextual_information` is the conditioning variables 
   - `last_context` index of the last observed context of the current period
   - `first_context` index of the first observed context of the current period 
"""
 
function conditional_moments(data, contextual_information, last_context, first_context)
 
    n = size(data,2) 
    d = size(contextual_information[:,2:end],2)  
    side_information = Float64.(Matrix(contextual_information[:,2:end]))
       
    # data standardization for consistency     
      # standardization parameters
        μ_return = mean(data[:,1:n-d], dims=1)  # mean of historical returns
        σ_return = std(data[:,1:n-d], dims=1)  # standard deviation of historical return
        μ_context = mean(side_information[first_context:last_context,:], dims=1)  # mean of contextual information
        σ_context = std(side_information[first_context:last_context,:], dims=1)  # standard deviation of contextual information
        
      # standardization 
        data[:,1:n-d] = (data[:,1:n-d] .- μ_return) ./ σ_return
        data[:,n-d+1:end] = (data[:,n-d+1:end] .- μ_context) ./ σ_context

    # estimation of the joint distribution
      # the mean
        μ = mean(data, dims=1)  # joint mean
        μᵣ = μ[1:n-d]  # mean return
        μₛ = μ[n-d+1:end]  # mean of contextual variables
      # the covariance
        data_center = data .- μ
        Σ = (data_center' * data_center) / (size(data,1) - 1)  # joint covariance 
        Σᵣᵣ = Σ[1:n-d,1:n-d]  # covariance between returns
        Σᵣₛ = Σ[1:n-d,n-d+1:end]  # covariance between returns and contextual variables
        Σₛᵣ = Σ[n-d+1:end,1:n-d]  # Σₛᵣ = Σᵣₛᵀ
        Σₛₛ = Σ[n-d+1:end,n-d+1:end]  # covariance between contextual variables

    # conditional moments    
      # condition on the last contextual variable observed 
        μ_stand_context = mean(side_information[first_context:last_context,:], dims=1)
        σ_stand_context = std(side_information[first_context:last_context,:], dims=1) 
        s = (side_information[last_context,:] .- vec(μ_stand_context)) ./ vec(σ_stand_context)  # standarization

      # conditional mean
        μᵣ_ₛ = μᵣ + Σᵣₛ * (Σₛₛ \ (s - μₛ))      # μᵣ + Σᵣₛ * inv(Σₛₛ) * (s - μₛ)  
      # conditional covariance
        Σᵣ_ₛ = Σᵣᵣ - Σᵣₛ * (Σₛₛ \ Σₛᵣ)     # Σᵣᵣ - Σᵣₛ * inv(Σₛₛ) * Σₛᵣ 
                 
      # destandardization (rescaling to the original values)
        μᵣ_ₛ =  vec((μᵣ_ₛ' .* σ_return) + μ_return)  # conditional mean
        Σᵣ_ₛ = diagm(vec(σ_return)) * Σᵣ_ₛ * diagm(vec(σ_return))  # conditional covariance 
        Σᵣ_ₛ = Hermitian(Σᵣ_ₛ)
    
    return μᵣ_ₛ, Σᵣ_ₛ     
end