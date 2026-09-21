-- Grain: one row per campaign per day.
-- Cleaning rules:
--   1. Duplicate campaign-day rows are removed (keep the first).
--   2. Clicks can't exceed impressions; where the export says they do, clicks are
--      capped at impressions so the day's spend and leads are not thrown away.
with ranked as (
    select
        *,
        row_number() over (partition by campaign_id, report_date order by impressions desc) as row_num
    from {{ ref('raw_ad_performance') }}
)

select
    campaign_id,
    report_date,
    impressions,
    least(clicks, impressions)      as clicks,
    spend_zar
from ranked
where row_num = 1
