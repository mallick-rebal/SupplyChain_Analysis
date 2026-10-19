-- q02_late_by_mode_market.sql
-- Business question : 01 Fulfillment (analysis #2 in Model/handoff_plan.md)
--                     Is lateness driven by the market or by the shipping mode?
-- Filter   : excludes canceled + suspected fraud (no real delivery happened)
-- Output   : one row per shipping mode, one column per market (late %) = heatmap layout
-- Skills   : conditional aggregation (pivot with CASE WHEN inside AVG)

SELECT
    s.shipping_mode,
    s.sla_days AS promised_days,
    ROUND(100.0 * AVG(CASE WHEN g.market = 'Africa'       THEN CASE WHEN f.is_late THEN 1 ELSE 0 END END), 1) AS africa_late_pct,
    ROUND(100.0 * AVG(CASE WHEN g.market = 'Europe'       THEN CASE WHEN f.is_late THEN 1 ELSE 0 END END), 1) AS europe_late_pct,
    ROUND(100.0 * AVG(CASE WHEN g.market = 'LATAM'        THEN CASE WHEN f.is_late THEN 1 ELSE 0 END END), 1) AS latam_late_pct,
    ROUND(100.0 * AVG(CASE WHEN g.market = 'Pacific Asia' THEN CASE WHEN f.is_late THEN 1 ELSE 0 END END), 1) AS pacific_asia_late_pct,
    ROUND(100.0 * AVG(CASE WHEN g.market = 'USCA'         THEN CASE WHEN f.is_late THEN 1 ELSE 0 END END), 1) AS usca_late_pct,
    ROUND(100.0 * AVG(CASE WHEN f.is_late THEN 1 ELSE 0 END), 1)                                            AS all_markets_late_pct,
    COUNT(*) AS items
FROM fact_order_items f
JOIN dim_shipping  s ON f.shipping_key  = s.shipping_key
JOIN dim_geography g ON f.geography_key = g.geography_key
WHERE NOT f.is_canceled
  AND NOT f.is_suspected_fraud
GROUP BY s.shipping_mode, s.sla_days, s.shipping_key
ORDER BY s.shipping_key;
