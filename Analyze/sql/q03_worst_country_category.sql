-- q03_worst_country_category.sql
-- Business question : 01 Fulfillment (analysis #3 in Model/handoff_plan.md)
--                     Which country x product category combinations are late most often?
-- Filter   : excludes canceled + suspected fraud
-- Rule     : only combinations with at least 100 items, so tiny samples don't top the list
-- Output   : top 10 by late %, with the revenue at risk for each
-- Skills   : CTE, HAVING, RANK() window function

WITH combo AS (
    SELECT
        g.order_country,
        p.category_name,
        COUNT(*)                                                       AS items,
        ROUND(100.0 * AVG(CASE WHEN f.is_late THEN 1 ELSE 0 END), 1)   AS late_pct,
        ROUND(SUM(CASE WHEN f.is_late THEN f.net_sales ELSE 0 END), 0) AS revenue_at_risk
    FROM fact_order_items f
    JOIN dim_geography g ON f.geography_key = g.geography_key
    JOIN dim_product   p ON f.product_id    = p.product_id
    WHERE NOT f.is_canceled
      AND NOT f.is_suspected_fraud
    GROUP BY g.order_country, p.category_name
    HAVING COUNT(*) >= 100
),
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY late_pct DESC, revenue_at_risk DESC) AS late_rank
    FROM combo
)
SELECT late_rank, order_country, category_name, items, late_pct, revenue_at_risk
FROM ranked
WHERE late_rank <= 10
ORDER BY late_rank;
