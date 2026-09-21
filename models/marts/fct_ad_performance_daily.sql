-- Grain: one row per campaign per day.
-- Attribution rule: leads and won revenue are credited to the day the LEAD WAS
-- CREATED (a cohort view), not the day the deal closed. This ties revenue back
-- to the spend that generated it, and is stated in the documentation.
with performance as (
    select * from {{ ref('stg_ad_performance') }}
),

leads_by_day as (
    select
        campaign_id,
        created_date                                                        as report_date,
        count(*)                                                            as leads,
        count(*) filter (where stage in ('Qualified', 'Proposal', 'Won'))   as qualified_leads,
        count(*) filter (where stage = 'Won')                               as won_deals,
        coalesce(sum(deal_value_zar) filter (where stage = 'Won'), 0)       as won_revenue_zar
    from {{ ref('stg_leads') }}
    group by campaign_id, created_date
)

select
    p.campaign_id,
    p.report_date,
    p.impressions,
    p.clicks,
    p.spend_zar,
    coalesce(l.leads, 0)             as leads,
    coalesce(l.qualified_leads, 0)   as qualified_leads,
    coalesce(l.won_deals, 0)         as won_deals,
    coalesce(l.won_revenue_zar, 0)   as won_revenue_zar
from performance p
left join leads_by_day l
    on p.campaign_id = l.campaign_id
   and p.report_date = l.report_date
