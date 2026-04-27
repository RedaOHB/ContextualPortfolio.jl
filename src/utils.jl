"""
   align(data_1::DataFrame, data_2::DataFrame)
  
   ensures that the observations in data_1 and data_2 are properly aligned by matching their corresponding 
   indices (e.g., dates) so that both datasets are synchronized for consistent analysis.

  # Parameters :

   - `data_1`: a DataFrame containing observations, where the first column represents the date (e.x., historical returns)
   - `context`: a DataFrame containing observations, where the first column represents the date (e.x., contextul features)

  # Results :

   - `Data`: a DataFrame containing a date column and observations from data_1 aligned with those in data_2

  # Exemple 
  ```julia
   Data = align(returns, context)
   
  ```

"""

function align(data_1::DataFrame, data_2::DataFrame)

    if size(data_1, 1) == size(data_2, 1) 
        Data = leftjoin(data_1, data_2, on=[:Date])
    else
        n = size(data_1, 2)
        # add columns for months and years to enable duplication
          col = names(data_2)[1]
          data_2.month = Dates.month.(data_2[!,col])
          data_2.year = Dates.year.(data_2[!,col])
          data_1.month = Dates.month.(data_1.Date)
          data_1.year = Dates.year.(data_1.Date)
        # merge observation from data_1 and those in data_2
          Data = leftjoin(data_1, data_2, on=[:year, :month], makeunique=true)
        # remove the auxiliary columns added for each dataset
          select!(Data, Not([:month, :year, propertynames(Data)[n+3]]))
          select!(data_2, Not([:month, :year]))
          select!(data_1, Not([:month, :year]))
    end

    return Data

end