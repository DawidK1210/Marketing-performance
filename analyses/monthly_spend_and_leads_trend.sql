-- Business question: how are total spend, leads and cost per lead moving month by month?
select
    report_month,
    sum(spend_zar)                                              as spend_zar,
    sum(leads)                                                  as leads,
    {{ safe_divide('sum(spend_zar)', 'sum(leads)') }}           as cost_per_lead_zar,
    lag({{ safe_divide('sum(spend_zar)', 'sum(leads)') }}) over (order by report_month) as prev_month_cpl
from {{ ref('mart_client_monthly_performance') }}
group by report_month
order by report_month
