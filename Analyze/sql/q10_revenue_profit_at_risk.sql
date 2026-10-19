-- q10_revenue_profit_at_risk.sql
-- Business question : 03 Profitability (analysis #10 in Model/handoff_plan.md)
--                     How much revenue and profit is tied to late deliveries?
-- Filter   : excludes canceled + suspected fraud
-- Output   : one row per shipping mode plus a grand total, split into late vs on time / early
-- Skills   : conditional sums (CASE inside SUM), GROUP BY ROLLUP

SELECT
    CASE WHEN GROUPING(s.shipping_mode) = 1 THEN 'ALL MODES' ELSE s.shipping_mode END AS shipping_mode,
    COUNT(*)                                                                AS items,
    ROUND(SUM(f.net_sales), 0)                                              AS net_revenue,
    ROUND(SUM(CASE WHEN f.is_late THEN f.net_sales ELSE 0 END), 0)          AS revenue_at_risk,
    ROUND(100.0 * SUM(CASE WHEN f.is_late THEN f.net_sales ELSE 0 END)
                / SUM(f.net_sales), 1)                                      AS pct_revenue_at_risk,
    ROUND(SUM(f.profit), 0)                                                 AS profit,
    ROUND(SUM(CASE WHEN f.is_late THEN f.profit ELSE 0 END), 0)             AS profit_at_risk
FROM fact_order_items f
JOIN dim_shipping s ON f.shipping_key = s.shipping_key
WHERE NOT f.is_canceled
  AND NOT f.is_suspected_fraud
GROUP BY ROLLUP (s.shipping_mode)
ORDER BY GROUPING(s.shipping_mode), revenue_at_risk DESC;
