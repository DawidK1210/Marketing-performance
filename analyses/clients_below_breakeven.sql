-- Business question: which clients spent more on ads than they won back, and
-- which channel is dragging them down? (ROAS below 1 = lost money on ads.)
select
    client_name,
    channel,
    sum(spend_zar)                                              as spend_zar,
    sum(won_revenue_zar)                                        as won_revenue_zar,
    {{ safe_divide('sum(won_revenue_zar)', 'sum(spend_zar)') }} as return_on_ad_spend
from {{ ref('mart_client_monthly_performance') }}
group by client_name, channel
having sum(won_revenue_zar) < sum(spend_zar)
order by return_on_ad_spend
