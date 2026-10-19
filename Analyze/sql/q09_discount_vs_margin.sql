-- q09_discount_vs_margin.sql
-- Business question : 03 Profitability (analysis #9 in Model/handoff_plan.md)
--                     Do bigger discounts destroy profit?
-- Filter   : excludes canceled + suspected fraud
-- Method   : group items into discount bands using the EFFECTIVE rate = discount_amount / sales.
--            (The listed discount_rate doesn't always match the money; see Clean/data_dictionary.md.)
-- Skills   : CASE banding, aggregation by band

WITH banded AS (
    SELECT
        f.discount_amount / NULLIF(f.sales, 0) AS effective_rate,
        CASE
            WHEN f.discount_amount / NULLIF(f.sales, 0) <  0.05 THEN '1. 0-4%'
            WHEN f.discount_amount / NULLIF(f.sales, 0) <  0.10 THEN '2. 5-9%'
            WHEN f.discount_amount / NULLIF(f.sales, 0) <  0.15 THEN '3. 10-14%'
            WHEN f.discount_amount / NULLIF(f.sales, 0) <  0.20 THEN '4. 15-19%'
            ELSE                              '5. 20-25%'
        END AS discount_band,
        f.*
    FROM fact_order_items f
    WHERE NOT f.is_canceled
      AND NOT f.is_suspected_fraud
)
SELECT
    discount_band,
    COUNT(*)                                                      AS items,
    ROUND(SUM(net_sales), 0)                                      AS net_revenue,
    ROUND(SUM(profit), 0)                                         AS profit,
    ROUND(100.0 * SUM(profit) / SUM(net_sales), 1)                AS margin_pct,
    ROUND(100.0 * AVG(CASE WHEN profit < 0 THEN 1 ELSE 0 END), 1) AS pct_items_at_loss
FROM banded
GROUP BY discount_band
ORDER BY discount_band;
