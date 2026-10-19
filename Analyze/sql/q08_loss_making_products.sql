-- q08_loss_making_products.sql
-- Business question : 03 Profitability (analysis #8 in Model/handoff_plan.md)
--                     How much money is lost on items sold at a loss, and in which products?
-- Filter   : excludes canceled + suspected fraud
-- Method   : an item is "loss-making" when profit < 0. Products are ranked by total loss.
-- Skills   : CASE inside SUM (conditional sums), CTE, share of total

WITH product_loss AS (
    SELECT
        p.product_name,
        p.category_name,
        COUNT(*)                                                     AS items,
        SUM(CASE WHEN f.profit < 0 THEN 1 ELSE 0 END)                AS loss_items,
        ROUND(SUM(f.net_sales), 0)                                   AS net_revenue,
        ROUND(SUM(f.profit), 0)                                      AS net_profit,
        ROUND(SUM(CASE WHEN f.profit < 0 THEN f.profit ELSE 0 END), 0) AS total_loss
    FROM fact_order_items f
    JOIN dim_product p ON f.product_id = p.product_id
    WHERE NOT f.is_canceled
      AND NOT f.is_suspected_fraud
    GROUP BY p.product_name, p.category_name
)
SELECT
    product_name,
    category_name,
    items,
    ROUND(100.0 * loss_items / items, 1)                              AS pct_items_at_loss,
    net_revenue,
    net_profit,
    total_loss,
    ROUND(100.0 * total_loss / SUM(total_loss) OVER (), 1)            AS pct_of_all_losses
FROM product_loss
ORDER BY total_loss
LIMIT 10;
