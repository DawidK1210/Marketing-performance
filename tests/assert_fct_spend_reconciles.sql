-- Fails if total spend in the fact table differs from staging by more than 1 rand.
-- Guards against joins that silently drop or duplicate rows.
with fct as (select sum(spend_zar) as total from {{ ref('fct_ad_performance_daily') }}),
     stg as (select sum(spend_zar) as total from {{ ref('stg_ad_performance') }})
select fct.total as fct_total, stg.total as stg_total
from fct, stg
where abs(fct.total - stg.total) > 1
