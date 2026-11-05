-- q17_priority_score.sql
-- Business question : 06 Management priority (analysis #17 in Model/handoff_plan.md)
--                     What should operations investigate first?
-- Filter   : excludes canceled + suspected fraud
-- Grain    : market x product category, minimum 100 items (smaller segments are too noisy to rank)
-- Method   : agreed with the team - a transparent weighted score, not a multiplication.
--            1. Turn each component into a percentile score from 0 to 1 (PERCENT_RANK),
--               so no single measure dominates because of its scale:
--                 late_score    = how late this segment is compared with the others
--                 risk_score    = how much revenue is tied to late items
--                 volume_score  = how many items the segment ships
--            2. Priority score = 40% late + 35% revenue at risk + 25% volume, shown on 0-100.
--            Change the weights in the `weights` CTE below; they must add up to 1.
-- Caveats  : revenue at risk grows with volume (rank correlation ~0.89), so in practice size
--            carries about 60% of the score, not 25%.
--            products_in_segment shows when a "category" is really one product
--            (e.g. Fishing = only the Field & Stream gun safe in every market).
-- Output   : every segment ranked; the dashboard's Operations Priority page reads this
-- Skills   : multi-CTE pipeline, PERCENT_RANK() normalisation, weighted score, RANK()

WITH weights AS (
    SELECT 0.40 AS w_late, 0.35 AS w_risk, 0.25 AS w_volume
),
segment AS (
    SELECT
        g.market,
        p.category_name,
        COUNT(*)                                                       AS items,
        COUNT(DISTINCT p.product_id)                                   AS products_in_segment,
        AVG(CASE WHEN f.is_late THEN 1.0 ELSE 0.0 END)                 AS late_rate,
        SUM(CASE WHEN f.is_late THEN f.net_sales ELSE 0 END)           AS revenue_at_risk,
        SUM(f.net_sales)                                               AS net_revenue
    FROM fact_order_items f
    JOIN dim_geography g ON f.geography_key = g.geography_key
    JOIN dim_product   p ON f.product_id    = p.product_id
    WHERE NOT f.is_canceled
      AND NOT f.is_suspected_fraud
    GROUP BY g.market, p.category_name
    HAVING COUNT(*) >= 100
),
scored AS (
    SELECT
        *,
        PERCENT_RANK() OVER (ORDER BY late_rate)       AS late_score,
        PERCENT_RANK() OVER (ORDER BY revenue_at_risk) AS risk_score,
        PERCENT_RANK() OVER (ORDER BY items)           AS volume_score
    FROM segment
)
SELECT
    RANK() OVER (ORDER BY 100 * (w.w_late * s.late_score + w.w_risk * s.risk_score + w.w_volume * s.volume_score) DESC)
                                                                               AS priority_rank,
    s.market,
    s.category_name,
    s.products_in_segment,
    s.items,
    ROUND(100 * s.late_rate, 1)                                                AS late_pct,
    ROUND(s.revenue_at_risk, 0)                                                AS revenue_at_risk,
    ROUND(s.net_revenue, 0)                                                    AS net_revenue,
    ROUND(100 * s.late_score, 0)                                               AS late_score,
    ROUND(100 * s.risk_score, 0)                                               AS risk_score,
    ROUND(100 * s.volume_score, 0)                                             AS volume_score,
    ROUND(100 * (w.w_late * s.late_score + w.w_risk * s.risk_score + w.w_volume * s.volume_score), 1)
                                                                               AS priority_score
FROM scored s
CROSS JOIN weights w
ORDER BY priority_rank;
