select
    client_id,
    trim(client_name)               as client_name,
    segment,
    province,
    onboarded_date,
    monthly_retainer_zar
from {{ ref('raw_clients') }}
