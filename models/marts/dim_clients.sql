select
    c.client_id,
    c.client_name,
    c.segment,
    c.province,
    c.onboarded_date,
    c.monthly_retainer_zar,
    count(distinct cam.campaign_id)   as campaigns_run,
    min(cam.start_date)               as first_campaign_start
from {{ ref('stg_clients') }} c
left join {{ ref('stg_campaigns') }} cam using (client_id)
group by all
