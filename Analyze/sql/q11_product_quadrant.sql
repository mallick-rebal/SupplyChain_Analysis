-- q11_product_quadrant.sql
-- Business question : 04 Product performance (analysis #11 in Model/handoff_plan.md)
--                     Which products sell a lot, and which actually make money?
-- Filter   : excludes canceled + suspected fraud
-- Method   : split products into high/low volume and high/low margin at the median (NTILE(2)),
--            giving four quadrants:
--              Star          = high volume, high margin   -> protect
--              Volume driver = high volume, low margin    -> fix price / cost
--              Niche winner  = low volume,  high margin   -> grow
--              Problem item  = low volume,  low margin    -> review / drop
-- Skills   : CTE, NTILE() window function, CASE

WITH product AS (
    SELECT
        p.product_id,
        p.product_name,
        p.department_name,
        SUM(f.quantity)                                  AS units,
        ROUND(SUM(f.net_sales), 0)                       AS net_revenue,
        ROUND(SUM(f.profit), 0)                          AS profit,
        ROUND(100.0 * SUM(f.profit) / SUM(f.net_sales), 1) AS margin_pct
    FROM fact_order_items f
    JOIN dim_product p ON f.product_id = p.product_id
    WHERE NOT f.is_canceled
      AND NOT f.is_suspected_fraud
    GROUP BY p.product_id, p.product_name, p.department_name
),
split AS (
    SELECT
        *,
        NTILE(2) OVER (ORDER BY units)      AS volume_half,   -- 2 = top half
        NTILE(2) OVER (ORDER BY margin_pct) AS margin_half    -- 2 = top half
    FROM product
)
SELECT
    CASE
        WHEN volume_half = 2 AND margin_half = 2 THEN '1. Star'
        WHEN volume_half = 2 AND margin_half = 1 THEN '2. Volume driver'
        WHEN volume_half = 1 AND margin_half = 2 THEN '3. Niche winner'
        ELSE                                          '4. Problem item'
    END AS quadrant,
    product_name,
    department_name,
    units,
    net_revenue,
    profit,
    margin_pct
FROM split
ORDER BY quadrant, net_revenue DESC;
