with agg as (
    select
        as_of_date,
        country,
        segment,
        sum(outstanding_balance_eur) as total_exposure_eur,
        sum(case when npl_flag = true then outstanding_balance_eur else 0 end) as npl_exposure_eur,
        count(*) as loan_count
    from {{ ref('stg_loan_risk_exposure') }}
    group by as_of_date, country, segment
)

select
    as_of_date,
    country,
    segment,
    total_exposure_eur,
    npl_exposure_eur,
    loan_count,
    round(100.0 * npl_exposure_eur / nullif(total_exposure_eur, 0), 3) as npl_ratio_pct,
    3.0 as threshold_pct,
    (round(100.0 * npl_exposure_eur / nullif(total_exposure_eur, 0), 3) > 3.0) as breach_flag,
    'NPL Ratio by Segment' as kri_name
from agg
