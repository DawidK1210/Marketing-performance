-- Grain: one row per lead. Stage labels arrive with mixed case and stray spaces
-- ("won ", "WON"), so they are trimmed and standardised.
select
    lead_id,
    campaign_id,
    created_date,
    upper(left(trim(stage), 1)) || lower(substr(trim(stage), 2))   as stage,
    deal_value_zar,
    closed_date
from {{ ref('raw_leads') }}
