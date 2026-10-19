-- q04_shipping_days_distribution.sql
-- Business question : 02 SLA realism (analysis #4 in Model/handoff_plan.md)
--                     For each shipping mode, how many days does shipping really take?
-- Filter   : excludes canceled + suspected fraud
-- Output   : one row per shipping mode x actual days, with the share of that mode's items
-- Skills   : window function SUM() OVER (PARTITION BY ...) for percent of group total

WITH days AS (
    SELECT
        s.shipping_key,
        s.shipping_mode,
        s.sla_days                AS promised_days,
        f.days_shipping_real      AS actual_days,
        COUNT(*)                  AS items
    FROM fact_order_items f
    JOIN dim_shipping s ON f.shipping_key = s.shipping_key
    WHERE NOT f.is_canceled
      AND NOT f.is_suspected_fraud
    GROUP BY s.shipping_key, s.shipping_mode, s.sla_days, f.days_shipping_real
)
SELECT
    shipping_mode,
    promised_days,
    actual_days,
    actual_days - promised_days                                              AS days_vs_promise,
    items,
    ROUND(100.0 * items / SUM(items) OVER (PARTITION BY shipping_mode), 1)   AS pct_of_mode
FROM days
ORDER BY shipping_key, actual_days;
