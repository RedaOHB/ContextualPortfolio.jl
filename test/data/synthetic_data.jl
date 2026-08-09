using Distributions, LinearAlgebra, Statistics, Dates, DataFrames
using Random
 

function synthetic_data(n_assets, n_features, random_state, start_date, end_date)

    regime_switch = true

    dates = start_date:Day(1):end_date

    month_dates = start_date:Month(1):end_date
    n_months = length(month_dates)

    rng = MersenneTwister(random_state)

    # Parameters for regimes
    regimes = [0, 1]
    n_regimes = length(regimes)

    if regime_switch
        rho = [0.35, 0.2]                  # AR(1) coefficient per regime
        mu_z = [
            zeros(n_features),            # calm regime mean
            ones(n_features) * 0.25,       # stressed regime mean
        ]
        Sigma_z = [
            I(n_features) * 0.08,
            I(n_features) * 0.18,
        ]
        p00 = 0.92
        p11 = 0.85
    else
        rho = [0.3]
        mu_z = [zeros(n_features)]
        Sigma_z = [I(n_features) * 0.1]
        p00 = 1.0
        p11 = 1.0
    end

    # Baseline parameters for returns (unconditional)
      mu_0 = rand(rng, Uniform(0.00010, 0.00025), n_assets)

      B = rand(rng, Uniform(-0.00001, 0.00001), n_assets, n_features)

      vols = rand(rng, Uniform(0.005, 0.010), n_assets)

    base_corr = 0.15
    Corr = fill(base_corr, n_assets, n_assets)
    for i in 1:n_assets
        Corr[i, i] = 1.0
    end  

    D = Diagonal(vols)
    Sigma_0 = D * Corr * D

    # Regime-dependent covariance for returns
       Sigma_s = [
            Diagonal(Sigma_0 .* 0.9),   # calm: lower vol
            Diagonal(Sigma_0 .* 1.20),   # stressed: higher vol
        ]

    # Generate regimes (Markov chain)
       regimes_seq = zeros(Int, n_months)
       s_prev = 0
       for t in 1:n_months
        if t == 1
            s_prev = 0
        else
            if s_prev == 0
                s_prev = (rand(rng) < p00) ? 0 : 1
            else
                s_prev = (rand(rng) < p11) ? 1 : 0
            end
        end
        regimes_seq[t] = s_prev
       end

    # Generate monthly features (AR(1) with regime-dependent parameters)
      z_prev = zeros(n_features)
      monthly_features = zeros(n_months, n_features)

      for t in 1:n_months

        s = regimes_seq[t]
        rho_t = rho[s + 1]
        mu_z_t = mu_z[s + 1]
        Sigma_z_t = Sigma_z[s + 1]

        eps_z = rand(rng, MvNormal(zeros(n_features), Sigma_z_t))
        z_t = mu_z_t .+ rho_t .* (z_prev .- mu_z_t) .+ eps_z

        monthly_features[t, :] = z_t
        z_prev = z_t  
      end     

    # Generate daily returns
      total_days = length(dates)
      daily_returns = zeros(total_days, n_assets)
      daily_dates = Vector{Date}(undef, total_days)

      day_idx = 0
      for t in 1:n_months
        s = regimes_seq[t]
        z_t = monthly_features[t, :]

        # Unconditional mean with feature-dependent component (for realism)
        # Note: you can also set this to mu_0 only if you want fully unconditional returns
        mu_r_t = mu_0 .+ B * z_t

        # Covariance for this regime
        Sigma_r_t = Symmetric(Sigma_s[s + 1])

        # Generate days for this month
        month_start = month_dates[t]
        for d in 1:length(month_dates[t]:Day(1):month_dates[t]+Month(1))-1
            day = month_start + Day(d - 1)
            day_idx += 1
            daily_dates[day_idx] = day

            # Generate daily returns
            eps_daily = rand(rng, MvNormal(zeros(n_assets), Sigma_r_t))
            daily_returns[day_idx, :] = mu_r_t .+ eps_daily
        end
      end

    # Create DataFrame for returns and features
    returns = DataFrame(Date = daily_dates)
    features = DataFrame(Date = month_dates)
    for i in 1:n_assets
        returns[!,Symbol("Asset$i")] = daily_returns[:,i]
    end

    for i in 1:n_features
        features[!,Symbol("context$i")] = monthly_features[:,i]
    end

    return returns, features

end

