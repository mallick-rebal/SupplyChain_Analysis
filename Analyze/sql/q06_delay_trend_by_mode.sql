-- q06_delay_trend_by_mode.sql
-- Business question : 02 SLA realism (analysis #6 in Model/handoff_plan.md)
--                     Is shipping getting better or worse over time, for each mode?
-- Filter   : excludes canceled + suspected fraud + low-coverage months (Oct 2017 - Jan 2018)
-- Output   : one row per month x shipping mode, with avg delay and a 3-month rolling average
-- Skills   : dim_date join, window function AVG() OVER (PARTITION BY ... ORDER BY ... ROWS BETWEEN)

WITH monthly AS (
    SELECT
        d.year_month,
        s.shipping_key,
        s.shipping_mode,
        ROUND(AVG(f.shipping_delay_days), 2)                          AS avg_delay_days,
        ROUND(100.0 * AVG(CASE WHEN f.is_late THEN 1 ELSE 0 END), 1)  AS late_pct,
        COUNT(*)                                                      AS items
    FROM fact_order_items f
    JOIN dim_date     d ON f.order_date_key = d.date_key
    JOIN dim_shipping s ON f.shipping_key   = s.shipping_key
    WHERE NOT f.is_canceled
      AND NOT f.is_suspected_fraud
      AND NOT f.is_low_coverage_period
    GROUP BY d.year_month, s.shipping_key, s.shipping_mode
)
SELECT
    year_month,
    shipping_mode,
    avg_delay_days,
    ROUND(AVG(avg_delay_days) OVER (
        PARTITION BY shipping_mode
        ORDER BY year_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3m_delay_days,
    late_pct,
    items
FROM monthly
ORDER BY shipping_key, year_month;
