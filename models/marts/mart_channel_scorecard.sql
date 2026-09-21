-- Grain: one row per channel and client segment, across the whole period.
-- Ranks channels within each segment so the best and worst performers are obvious.
with totals as (
    select
        segment,
        channel,
        sum(spend_zar)        as spend_zar,
        sum(leads)            as leads,
        sum(won_deals)        as won_deals,
        sum(won_revenue_zar)  as won_revenue_zar
    from {{ ref('mart_client_monthly_performance') }}
    group by segment, channel
)

select
    segment,
    channel,
    spend_zar,
    leads,
    won_deals,
    won_revenue_zar,
    {{ safe_divide('spend_zar', 'leads') }}                as cost_per_lead_zar,
    {{ safe_divide('won_revenue_zar', 'spend_zar') }}      as return_on_ad_spend,
    rank() over (partition by segment order by won_revenue_zar / nullif(spend_zar, 0) desc) as roas_rank_in_segment
from totals
