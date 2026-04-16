"""
   align(returns::DataFrame, context::DataFrame)
  
  Ensures alignment of returns and contextual data  

  # Parameters :

   - `returns`: Historical returns
   - `context`: Contextual features

  # Results :

   - `Data`: A DataFrame containing a date column and contextual features aligned with the returns. 

  # Exemple 
  ```julia
   Data = align(returns, context)
   
  ```

"""

function align(returns::DataFrame, context::DataFrame)

    if size(returns, 1) == size(context, 1) 
        Data = leftjoin(returns, context, on=[:Date])
    else
        n = size(returns, 2)
        # add columns for months and years to enable duplication
          col = names(context)[1]
          context.month = Dates.month.(context[!,col])
          context.year = Dates.year.(context[!,col])
          returns.month = Dates.month.(returns.Date)
          returns.year = Dates.year.(returns.Date)
        # merge return and contextual data
          Data = leftjoin(returns, context, on=[:year, :month], makeunique=true)
        # remove the auxiliary columns added for each dataset
          select!(Data, Not([:month, :year, propertynames(Data)[n+3]]))
          select!(context, Not([:month, :year]))
          select!(returns, Not([:month, :year]))
    end

    return Data

end