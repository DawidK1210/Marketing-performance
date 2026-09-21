-- Fails if any day reports more clicks than impressions.
select campaign_id, report_date, clicks, impressions
from {{ ref('fct_ad_performance_daily') }}
where clicks > impressions
