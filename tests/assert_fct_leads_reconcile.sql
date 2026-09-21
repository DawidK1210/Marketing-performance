-- Fails if the fact table has a different number of leads than the cleaned lead list.
-- This catches leads that fall on days with no ad-performance row.
with fct as (select sum(leads) as total from {{ ref('fct_ad_performance_daily') }}),
     stg as (select count(*) as total from {{ ref('stg_leads') }})
select fct.total as fct_leads, stg.total as stg_leads
from fct, stg
where fct.total != stg.total
