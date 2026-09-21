-- Fails if any campaign has more than one row for the same day after cleaning.
select campaign_id, report_date, count(*) as row_count
from {{ ref('stg_ad_performance') }}
group by campaign_id, report_date
having count(*) > 1
