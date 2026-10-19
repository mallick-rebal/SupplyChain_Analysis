-- q07_profit_by_market_department.sql
-- Business question : 03 Profitability (analysis #7 in Model/handoff_plan.md)
--                     Where do we make money, and where is margin weak?
-- Filter   : excludes canceled + suspected fraud (revenue never realised)
-- Output   : profit and margin by market x department, plus subtotals per market and a grand total
-- Skills   : GROUP BY ROLLUP + GROUPING(), margin = SUM(profit) / SUM(net_sales)

SELECT
    CASE WHEN GROUPING(g.market) = 1 THEN 'ALL MARKETS' ELSE g.market END                AS market,
    CASE WHEN GROUPING(p.department_name) = 1 THEN '(subtotal)' ELSE p.department_name END AS department,
    COUNT(*)                                                         AS items,
    ROUND(SUM(f.net_sales), 0)                                       AS net_revenue,
    ROUND(SUM(f.profit), 0)                                          AS profit,
    ROUND(100.0 * SUM(f.profit) / SUM(f.net_sales), 1)               AS margin_pct,
    ROUND(100.0 * SUM(f.discount_amount) / SUM(f.sales), 1)          AS discount_pct
FROM fact_order_items f
JOIN dim_geography g ON f.geography_key = g.geography_key
JOIN dim_product   p ON f.product_id    = p.product_id
WHERE NOT f.is_canceled
  AND NOT f.is_suspected_fraud
GROUP BY ROLLUP (g.market, p.department_name)
ORDER BY GROUPING(g.market), g.market, GROUPING(p.department_name) DESC, profit DESC;
