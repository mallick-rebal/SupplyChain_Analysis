-- q12_top_bottom_products_by_market.sql
-- Business question : 04 Product performance (analysis #12 in Model/handoff_plan.md)
--                     Are the best and worst products the same in every market?
-- Filter   : excludes canceled + suspected fraud
-- Rule     : only products with at least 50 items in that market, so tiny samples don't top the list
-- Output   : top 3 products by profit in each market, and bottom 3 only where the market has
--            at least 20 qualifying products. With fewer (e.g. Africa: 9), the "bottom 3" are
--            still big sellers and would be misleading.
-- Skills   : ROW_NUMBER() OVER (PARTITION BY market ...), both directions

WITH product_market AS (
    SELECT
        g.market,
        p.product_name,
        COUNT(*)                                            AS items,
        ROUND(SUM(f.profit), 0)                             AS profit,
        ROUND(100.0 * SUM(f.profit) / SUM(f.net_sales), 1)  AS margin_pct
    FROM fact_order_items f
    JOIN dim_geography g ON f.geography_key = g.geography_key
    JOIN dim_product   p ON f.product_id    = p.product_id
    WHERE NOT f.is_canceled
      AND NOT f.is_suspected_fraud
    GROUP BY g.market, p.product_id, p.product_name
    HAVING COUNT(*) >= 50
),
ranked AS (
    SELECT
        *,
        COUNT(*) OVER (PARTITION BY market)                          AS qualifying_products,
        ROW_NUMBER() OVER (PARTITION BY market ORDER BY profit DESC) AS top_rank,
        ROW_NUMBER() OVER (PARTITION BY market ORDER BY profit ASC)  AS bottom_rank
    FROM product_market
)
SELECT
    market,
    qualifying_products,
    CASE WHEN top_rank <= 3 THEN 'Top ' || top_rank ELSE 'Bottom ' || bottom_rank END AS position,
    product_name,
    items,
    profit,
    margin_pct
FROM ranked
WHERE top_rank <= 3
   OR (bottom_rank <= 3 AND qualifying_products >= 20)
ORDER BY market, top_rank;
