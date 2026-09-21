-- Grain: one row per client, channel and month. This is the main table the
-- dashboard connects to.
select
    cl.client_id,
    cl.client_name,
    cl.segment,
    cam.channel,
    date_trunc('month', f.report_date)::date                       as report_month,
    sum(f.spend_zar)                                               as spend_zar,
    sum(f.impressions)                                             as impressions,
    sum(f.clicks)                                                  as clicks,
    sum(f.leads)                                                   as leads,
    sum(f.qualified_leads)                                         as qualified_leads,
    sum(f.won_deals)                                               as won_deals,
    sum(f.won_revenue_zar)                                         as won_revenue_zar,
    {{ safe_divide('sum(f.clicks)', 'sum(f.impressions)', 4) }}    as ctr,
    {{ safe_divide('sum(f.spend_zar)', 'sum(f.clicks)') }}         as cost_per_click_zar,
    {{ safe_divide('sum(f.spend_zar)', 'sum(f.leads)') }}          as cost_per_lead_zar,
    {{ safe_divide('sum(f.won_deals)', 'sum(f.leads)', 4) }}       as lead_to_win_rate,
    {{ safe_divide('sum(f.won_revenue_zar)', 'sum(f.spend_zar)') }} as return_on_ad_spend
from {{ ref('fct_ad_performance_daily') }} f
join {{ ref('dim_campaigns') }} cam using (campaign_id)
join {{ ref('dim_clients') }} cl on cam.client_id = cl.client_id
group by all
