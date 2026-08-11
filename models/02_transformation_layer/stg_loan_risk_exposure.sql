with loans as (
    select * from {{ ref('src_loans') }}
),

date_spine as (
    select distinct as_of_date::date as as_of_date
    from {{ ref('src_credit_ratings') }}
),

loan_months as (
    select loans.*, date_spine.as_of_date
    from loans
    cross join date_spine
),

ratings as (
    select *, as_of_date::date as rating_date
    from {{ ref('src_credit_ratings') }}
),

npl as (
    select *, as_of_date::date as npl_date
    from {{ ref('src_npl_status') }}
),

fx as (
    select *, rate_date::date as fx_date
    from {{ ref('src_fx_rates') }}
    where currency_pair = 'EUR/SEK'
),

collateral_by_loan as (
    select loan_id, sum(appraised_value) as collateral_value_local
    from {{ ref('src_collateral') }}
    group by loan_id
)

select
    lm.as_of_date,
    lm.loan_id,
    lm.customer_id,
    lm.country,
    lm.segment,
    lm.product_type,
    lm.currency,
    lm.outstanding_balance as outstanding_balance_local,
    case when lm.currency = 'SEK' then fx.rate else 1.0 end as fx_rate_used,
    case when lm.currency = 'SEK' then coalesce(fx.feed_status, 'Unknown') else 'N/A (EUR-native)' end as fx_feed_status,
    case when lm.currency = 'SEK' then round(lm.outstanding_balance / fx.rate, 2)
         else lm.outstanding_balance end as outstanding_balance_eur,
    case when lm.currency = 'SEK' then round(coalesce(cbl.collateral_value_local, 0) / fx.rate, 2)
         else coalesce(cbl.collateral_value_local, 0) end as collateral_value_eur,
    r.internal_rating,
    r.probability_of_default_pct,
    coalesce(r.rating_batch_status, 'MISSING - no batch') as rating_batch_status,
    n.days_past_due,
    n.npl_flag
from loan_months lm
left join ratings r on r.loan_id = lm.loan_id and r.rating_date = lm.as_of_date
left join npl n on n.loan_id = lm.loan_id and n.npl_date = lm.as_of_date
left join fx on fx.fx_date = lm.as_of_date
left join collateral_by_loan cbl on cbl.loan_id = lm.loan_id
