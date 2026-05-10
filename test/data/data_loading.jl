"""
Data Loading Utilities for ContextualPortfolio.jl

This module provides helper functions to load financial data from various sources,
particularly the Tiingo API for historical returns.
"""


"""
   historical_returns(assets::Vector{String}, start_date::Date, end_date::Date, API_key::Union{String,Nothing}, frequency::String)

  Load historical returns from Tiingo API.

  # Parameters: 

   - `assets`: List of stock tickers (e.g., ["AAPL", "MSFT", "GOOGL"])
   - `start_date`: Start date for historical data
   - `end_date`: End date for historical data
   - `API_key`: 
   - `frequency`: Frequency of data (daily, weekly, monthly, quarterly or annually)

  # Results :

   - `DataFrame`: DataFrame with Date column and return columns for each ticker

  # Example
  ```julia
   # Using environment variable for API key
   tickers = ["AAPL", "MSFT", "GOOGL"]
   start_date = Date(2020, 1, 1)
   end_date = Date(2024, 1, 1)

   returns_df = historical_returns(tickers, start_date, end_date, api_key, "daily")
  ```

  # Notes :

   - Requires a Tiingo API key (free tier available at https://www.tiingo.com)
   - Data is alligned by date across all tickers
   - returns are on a daily basis. You can the basis in `url`

"""
 
# This automatically loads .env if it exists to use the api key
  if isfile(joinpath(@__DIR__, "..", "..", ".env"))
      DotEnv.load!(joinpath(@__DIR__, "..", "..", ".env"))
  end

function historical_returns(assets, start_date, end_date, API_key, frequency)


    # Get API key from argument or environment
      api_key = isnothing(API_key) ? get(ENV, "TIINGO_API_KEY", nothing) : API_key

    dfs = Dict{String,Dict{Date,Union{Missing,Float64}}}()

    # download and build a date-->return dictionary for each asset
    for ticker in assets
        url = "https://api.tiingo.com/tiingo/daily/$ticker/prices" *
              "?startDate=$start_date&endDate=$end_date&resampleFreq=$frequency&token=$api_key"

        response = HTTP.get(url)
        raw = JSON3.read(String(response.body))  

        if isempty(raw)
            @warn "$ticker: aucune donnée disponible"
            dfs[ticker] = Dict()   # empty: still not available
            continue
        end

        # extract dates and prices, then sort by ascending date.
        rows = [(Date(split(r.date, "T")[1]), Float64(r.adjClose)) for r in raw]
        sort!(rows, by = x->x[1])   # sort by ascending date

        dates = [r[1] for r in rows]
        prices = [r[2] for r in rows]

        if length(prices) < 2
            # insufficient data points to calculate a return
            dfs[ticker] = Dict()
            continue
        end

        # calculating aligned returns: ret[i] matches dates[i+1]
        rets = diff(prices) ./ prices[1:end-1]
        ret_dates = dates[2:end]

        # create a date-to-return dictionary
        m = Dict{Date,Float64}()
        for (d, rv) in zip(ret_dates, rets)
            m[d] = rv
        end

        dfs[ticker] = m
    end

    # create a date grid combining all available return date
    all_dates_set = Set{Date}()
    for m in values(dfs)
        for d in keys(m)
            push!(all_dates_set, d)
        end
    end
    all_dates = sort(collect(all_dates_set))

    final = DataFrame(Date = all_dates)

    # fill each column using the dictionary, assigning missing when a value is absent
    for ticker in assets
        m = dfs[ticker]   # date-to-return dictionary (possibly empty)
        col = Vector{Union{Missing,Float64}}(undef, length(all_dates))
        for (i, d) in enumerate(all_dates)
            col[i] = get(m, d, missing)
        end
        final[!, Symbol(ticker)] = col
    end

    return final
end



"""
   context_data(file_path::String, file_type::String)

  Load contextual features from Excel or CSV file.

  # Parameters :

   - `file_path`: Path to the data file
   - `file_type`: File type "XLSX" or "CSV"

  # Results :

   - `features`: DataFrame with date column and contextual features 

  # Exemple 
  ```julia
   # Load from Excel (FRED data)
   context_df = context_data("data/macro_indicators.xlsx", file_type="xlsx")

   # Load from CSV
   context_df = context_data("data/market_data.csv", file_type="csv")
  ```

"""

function context_data(file_path, file_type, sheet_name)

    if file_type == "xlsx"
        # Load contextual data from Excel file
          xf = XLSX.readxlsx(file_path)
          sheet = xf[sheet_name]
          data = sheet[:]   
        # Convert to DataFrame  
          headers = Symbol.(data[1, :])
          features = DataFrame([data[2:end, i] for i in 1:size(data, 2)], headers)
    else
        # Load contextual data from CSV file
          features = CSV.read("file_name.csv", DataFrame)
    end

    return features
end


export historical_returns, context_data
