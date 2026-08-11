with agg as (
    select
        as_of_date,
        country,
        segment,
        sum(outstanding_balance_eur) as exposure_eur,
        avg(probability_of_default_pct) as avg_pd_pct,
        100.0 * count(probability_of_default_pct) / count(*) as pd_coverage_pct,
        sum(coalesce(probability_of_default_pct, 0) * (coalesce(outstanding_balance_eur, 0) + 1e-9))
            / sum(coalesce(outstanding_balance_eur, 0) + 1e-9) as weighted_avg_pd_pct
    from {{ ref('stg_loan_risk_exposure') }}
    group by as_of_date, country, segment
)

select
    as_of_date,
    country,
    segment,
    round(exposure_eur, 2) as exposure_eur,
    round(avg_pd_pct, 4) as avg_pd_pct,
    round(pd_coverage_pct, 2) as pd_coverage_pct,
    round(weighted_avg_pd_pct, 4) as weighted_avg_pd_pct,
    round(0.45 * exposure_eur * (weighted_avg_pd_pct / 100), 2) as expected_loss_eur,
    'Weighted Avg PD / Expected Loss by Segment' as kri_name
from agg
