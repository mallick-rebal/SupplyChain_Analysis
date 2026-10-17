-- q05_realistic_sla.sql
-- Question : 02 SLA realism - are the promised shipping times achievable?
-- Filter   : excludes canceled + suspected fraud
-- Method   : compare the fixed SLA per mode with what actually happens.
--            p90_days = the day count 90% of items really meet ("realistic SLA").
-- Skills   : PERCENTILE_CONT, comparing a business rule against the data

SELECT
    s.shipping_mode,
    s.sla_days                                                   AS promised_days,
    ROUND(AVG(f.days_shipping_real), 2)                          AS avg_actual_days,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.days_shipping_real) AS median_days,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY f.days_shipping_real) AS p90_days,
    ROUND(100.0 * AVG(CASE WHEN f.is_late THEN 1 ELSE 0 END), 1) AS late_pct,
    COUNT(*)                                                     AS items
FROM fact_order_items f
JOIN dim_shipping s ON f.shipping_key = s.shipping_key
WHERE NOT f.is_canceled
  AND NOT f.is_suspected_fraud
GROUP BY s.shipping_mode, s.sla_days, s.shipping_key
ORDER BY s.shipping_key;
