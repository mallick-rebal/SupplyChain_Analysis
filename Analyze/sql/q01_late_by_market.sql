-- q01_late_by_market.sql
-- Business question : 01 Fulfillment (analysis #1 in Model/handoff_plan.md) - where are late deliveries concentrated?
-- Filter   : excludes canceled + suspected fraud (no real delivery happened)
-- Grain    : market > region drill-down (ROLLUP adds subtotals and a grand total)
-- Skills   : star-schema joins, GROUP BY ROLLUP + GROUPING(), conditional aggregation

SELECT
    CASE WHEN GROUPING(g.market) = 1 THEN 'ALL MARKETS' ELSE g.market END             AS market,
    CASE WHEN GROUPING(g.order_region) = 1 THEN '(subtotal)' ELSE g.order_region END  AS order_region,
    COUNT(*)                                 AS items,
    ROUND(100.0 * AVG(CASE WHEN f.is_late THEN 1 ELSE 0 END), 1) AS late_pct,
    ROUND(SUM(f.net_sales), 0)                                   AS net_revenue,
    ROUND(SUM(CASE WHEN f.is_late THEN f.net_sales ELSE 0 END), 0) AS revenue_at_risk
FROM fact_order_items f
JOIN dim_geography g ON f.geography_key = g.geography_key
WHERE NOT f.is_canceled
  AND NOT f.is_suspected_fraud
GROUP BY ROLLUP (g.market, g.order_region)
ORDER BY GROUPING(g.market), g.market, GROUPING(g.order_region) DESC, g.order_region;
