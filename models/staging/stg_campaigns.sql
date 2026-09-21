-- One row per campaign. Channel labels arrive in several spellings from different
-- platform exports, so they are mapped to four standard channels.
select
    campaign_id,
    client_id,
    case
        when lower(trim(channel)) in ('google ads', 'google')                         then 'Google Ads'
        when lower(trim(channel)) in ('meta ads', 'facebook', 'facebook/instagram')   then 'Meta Ads'
        when lower(trim(channel)) in ('linkedin ads', 'linkedin')                     then 'LinkedIn Ads'
        when lower(trim(channel)) in ('property portal', 'portal')                    then 'Property Portal'
        else 'Unmapped'
    end                             as channel,
    objective,
    campaign_name,
    start_date,
    end_date
from {{ ref('raw_campaigns') }}
