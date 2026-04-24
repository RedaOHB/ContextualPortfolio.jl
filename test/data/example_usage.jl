"""
Example usage of data loading utilities for ContextualOptimization.jl

"""

include("data_loading.jl")

using Dates
using DotEnv

# ============================================================================
# Example 1: Load historical returns from Tiingo
# ============================================================================

println("\n=== Example 1: Loading historical returns ===\n")

tickers = ["AAPL", "NKE", "GOOGL", "AMZN", "META"]
start_date = Date(2020, 01, 01)
end_date = Date(2024, 12, 31)
frequency = "daily"

# This automatically loads .env if it exists to use the api key
  if isfile(joinpath(@__DIR__, "..", "..", ".env"))
      DotEnv.load!(joinpath(@__DIR__, "..", "..", ".env"))
  end

returns = historical_returns(tickers, start_date, end_date, nothing, frequency)

println(returns)


# ============================================================================
# Example 2: Load contextual features
# ============================================================================

println("\n\n=== Example 2: Loading contextual features ===\n")

# Exemple with CSV file (adjust path to your data)
  context = context_data("test/data/Features_example.csv", "csv")

println(context)

