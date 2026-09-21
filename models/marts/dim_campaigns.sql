select
    cam.campaign_id,
    cam.campaign_name,
    cam.channel,
    cam.objective,
    cam.start_date,
    cam.end_date,
    cam.client_id,
    c.client_name,
    c.segment
from {{ ref('stg_campaigns') }} cam
join {{ ref('stg_clients') }} c using (client_id)
