{#
  Divide two numbers without a division-by-zero error.
  Returns NULL when the denominator is 0 or NULL, so a day with zero clicks
  produces a blank cost-per-click instead of breaking the query.
  Usage: {{ safe_divide('sum(spend_zar)', 'sum(leads)') }}
#}
{% macro safe_divide(numerator, denominator, digits=2) %}
    round(cast({{ numerator }} as double) / nullif(cast({{ denominator }} as double), 0), {{ digits }})
{% endmacro %}
