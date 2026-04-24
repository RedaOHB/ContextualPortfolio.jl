# Data Loading Utilities

This directory contains helper functions for loading financial data used in ContextualOptimization.jl examples and tests.

## Quick Start
```julia
include("test/data/data_loading.jl")

# Load historical returns from Tiingo
  tickers = ["AAPL", "MSFT", "GOOGL"]
  start_date = Date(2020, 01, 01)
  end_date = Date(2024, 12, 31)
  API_key = "example_of_api_key"
  frequency = "daily"

  returns = historical_returns(tickers, start_date, end_date, API_key, frequency)
```

## Setup

### 1. Install Required Packages
```julia
using Pkg
Pkg.add(["HTTP", "JSON3", "DataFrames", "Dates", "DotEnv", "CSV", "XLSX"])
```

### 2. Get Tiingo API Key

1. Sign up for a free account at [https://www.tiingo.com](https://www.tiingo.com)
2. Navigate to your account settings to find your API key
3. Free tier allows 500 requests/hour and up to 5 years of historical data

### 3. Configure API Key

**Option A: Environment Variable**
```bash
export TIINGO_API_KEY="your_api_key_here"
```

**Option B: .env File**

Create a `.env` file in the package root directory:
```text
TIINGO_API_KEY=your_api_key_here
```

See `.env.example` for template.

**Option C: Pass Directly to Function**
```julia
returns = historical_returns(tickers, start_date, end_date, 
                                  api_key="your_api_key_here", frequency)
```


## Available Functions

### `historical_returns(tickers, start_date, end_date, API_key, frequency)`

Load historical returns from Tiingo API.

**Parameters:**
- `tickers`: Vector of stock tickers (e.g., `["AAPL", "GOOGL"]`)
- `start_date`: Start date (`Date` object)
- `end_date`: End date (`Date` object)
- `API_key` (optional): Tiingo API key
- `frequency`: `"daily"` (`"monthly"`, `"weekly"`or `"annually"`)

**Results:** DataFrame with Date column and return columns for each ticker.

### `context_data(file_path, file_type)`

Load contextual features from Excel or CSV file.

**Parameters:**
- `file_path`: Path to data file
- `file_type`: `"xlsx"` or `"csv"`

**Results:** DataFrame with contextual features.

## Examples

See `example_usage.jl` for complete examples.

### Basic Usage
```julia
include("data_loading.jl")
using Dates

# Load historical returns
tickers = ["AAPL", "NKE", "GOOGL", "AMZN", "META"]
returns = historical_returns(tickers, Date(2020,01,01), Date(2024,12,31),"your_api_key", "daily")

# Load context features
context = context_data("Features_example.csv", "csv")
```

## Data sources

### Returns data (via Tiingo)
- Stocks, ETFs, mutual funds
- Daily, weekly, monthly or annually frequency
- Adjusted for splits and dividends
- Up to 30+ years of history

### Contextual features

**FRED (Federal Reserve Economic Data)**
- Source: https://fred.stlouisfed.org
- Available as CSV or Excel downloads
- Examples: GDP, Inflation, Unemployment, Interest Rates

## Troubleshooting

**Error: "Tiingo API key not found"**
- Ensure API key is set in environment or .env file
- Check that .env file is in package root directory

**Error: "Failed to fetch data"**
- Check your internet connection
- Verify ticker symbols are valid
- Ensure you haven't exceeded API rate limits

