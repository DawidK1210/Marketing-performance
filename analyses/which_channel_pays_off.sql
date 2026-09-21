-- Business question: for each client segment, which channel gives the best
-- return on ad spend, and at what cost per lead?
select
    segment,
    channel,
    spend_zar,
    leads,
    cost_per_lead_zar,
    return_on_ad_spend,
    roas_rank_in_segment
from {{ ref('mart_channel_scorecard') }}
order by segment, roas_rank_in_segment
