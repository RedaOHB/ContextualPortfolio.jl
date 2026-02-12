#= 
  split_sample(data, start_date, estimation_horizon, validation_horizon)

  extract the estimation and evaluation data (in-sample and out-of-sample) from the full data starting on "start_date".
  Also calculate the mean vector and covariance matrix of training data for later usage.
  
  /*\ Parameters :

  * `data` represents the historical returns
  * `start_date` is the date on which estimation phase began
  * `estimation_horizon` is the period of training the model (frequency: monthly)
  * `validation_horizon` is the periode of testing (frequency: monthly)

  /*\ Results :

  * `Train_data` is the estimation set of the current period
  * `Test_data` is the validation set of the currect period 
  * `μ_train` represents the mean vector of training data
  * `Σ_train` represents the covariance matrix of training data  
=#

function split_sample(Data, start_date, estimation_horizon, validation_horizon)
    estimation_horizon = estimation_horizon/12  # convert the estimation_horizon to year frequency
    end_date = start_date + Year(estimation_horizon) - Day(1)  # end of the estimation period

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
        Test_set = filter(row -> end_date + Day(1) <= row.Date <= end_date + Month(validation_horizon), Data) 
        Test_set = Test_set[:,2:end]
        Test_data = Float64.(Matrix(Test_set))
  
    return Train_data, Test_data, μ_train, Σ_train
    
end
