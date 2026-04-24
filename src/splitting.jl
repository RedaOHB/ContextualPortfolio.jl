""" 
  split_sample(data, start_date, estimation_horizon, evaluation_horizon)

  extracts the in-sample (estimation) and out-of-sample (evaluation) datasets from the full dataset starting at start_date.
  It also computes the mean vector and covariance matrix of the training (estimation) data for later use.
  
    # Parameters :

   - `data`: historical returns
   - `start_date`: the date at which the estimation phase begins
   - `estimation_horizon`: length of the training period (monthly frequency)
   - `evaluation_horizon`: length of the testing period (monthly frequency)

    # Results :

   - `Train_data`: estimation (in-sample) dataset for the current period
   - `Test_data`: validation (out-of-sample) dataset for the current period
   - `μ_train` mean vector computed from the training data
   - `Σ_train` covariance matrix computed from the training data 
"""

function split_sample(Data, start_date, estimation_horizon, evaluation_horizon)
    end_date = start_date + Month(estimation_horizon) - Day(1)  # end of the estimation period

    # training data
      # extract the training data
        Train_set = filter(row -> start_date <= row.Date <= end_date, Data) 
        Train_set = Train_set[:,2:end]
        Train_data = Float64.(Matrix(Train_set))
      # mean vector of the training set
        μ_train = vec(mean(Train_data,dims=1))
      # covariance matrix of the training set
        cov_robust = LinearShrinkage(target = DiagonalUnitVariance(), shrinkage = :auto)
        Σ_train = cov(cov_robust, Train_data)
    
    # validation (test) data                       
      # extract the testing data
        Test_set = filter(row -> end_date + Day(1) <= row.Date <= end_date + Month(evaluation_horizon), Data) 
        Test_set = Test_set[:,2:end]
        Test_data = Float64.(Matrix(Test_set))
  
    return Train_data, Test_data, μ_train, Σ_train
    
end
