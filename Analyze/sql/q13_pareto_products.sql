-- q13_pareto_products.sql
-- Business question : 04 Product performance (analysis #13 in Model/handoff_plan.md)
--                     How many products make 80% of revenue?
-- Filter   : excludes canceled + suspected fraud
-- Output   : every product ranked by revenue, with its running share of total revenue
--            and an A / B / C class (A = first 80%, B = next 15%, C = last 5%)
-- Skills   : running total with SUM() OVER (ORDER BY ... ROWS UNBOUNDED PRECEDING)

WITH product AS (
    SELECT
        p.product_name,
        p.department_name,
        SUM(f.net_sales) AS net_revenue
    FROM fact_order_items f
    JOIN dim_product p ON f.product_id = p.product_id
    WHERE NOT f.is_canceled
      AND NOT f.is_suspected_fraud
    GROUP BY p.product_id, p.product_name, p.department_name
),
running AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY net_revenue DESC)                                  AS revenue_rank,
        product_name,
        department_name,
        net_revenue,
        100.0 * net_revenue / SUM(net_revenue) OVER ()                                 AS pct_of_revenue,
        100.0 * SUM(net_revenue) OVER (ORDER BY net_revenue DESC
                                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
              / SUM(net_revenue) OVER ()                                               AS cumulative_pct
    FROM product
)
SELECT
    revenue_rank,
    product_name,
    department_name,
    ROUND(net_revenue, 0)    AS net_revenue,
    ROUND(pct_of_revenue, 2) AS pct_of_revenue,
    ROUND(cumulative_pct, 1) AS cumulative_pct,
    CASE
        WHEN cumulative_pct - pct_of_revenue < 80 THEN 'A'
        WHEN cumulative_pct - pct_of_revenue < 95 THEN 'B'
        ELSE 'C'
    END AS abc_class
FROM running
ORDER BY revenue_rank;
