-- q15_yoy_growth.sql
-- Business question : 05 Demand trends (analysis #15 in Model/handoff_plan.md)
--                     Is revenue growing year over year?
-- Filter   : excludes canceled + suspected fraud + low-coverage months (Oct 2017 - Jan 2018)
-- Method   : each month is compared with the SAME month one year earlier (LAG 12), so only
--            like-for-like months are compared. Because Oct 2017 - Jan 2018 are excluded, the
--            thin late-2017 data can't create a fake decline.
--            Also adds a 3-month rolling average to smooth month-to-month noise.
-- Skills   : LAG(.., 12), window frame ROWS BETWEEN 2 PRECEDING AND CURRENT ROW

WITH monthly AS (
    SELECT
        d.year_month,
        d.year,
        d.month,
        SUM(f.net_sales) AS net_revenue
    FROM fact_order_items f
    JOIN dim_date d ON f.order_date_key = d.date_key
    WHERE NOT f.is_canceled
      AND NOT f.is_suspected_fraud
      AND NOT f.is_low_coverage_period
    GROUP BY d.year_month, d.year, d.month
),
with_prior AS (
    SELECT
        *,
        LAG(net_revenue, 12) OVER (ORDER BY year_month) AS same_month_last_year,
        LAG(year_month, 12)  OVER (ORDER BY year_month) AS prior_year_month
    FROM monthly
)
SELECT
    year_month,
    ROUND(net_revenue, 0)                                                         AS net_revenue,
    ROUND(AVG(net_revenue) OVER (ORDER BY year_month
                                 ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0)    AS rolling_3m_revenue,
    ROUND(same_month_last_year, 0)                                                AS same_month_last_year,
    ROUND(100.0 * (net_revenue - same_month_last_year) / same_month_last_year, 1) AS yoy_pct
FROM with_prior
-- safety check: only compare when the month 12 rows back really is the same calendar month
WHERE prior_year_month IS NULL
   OR CAST(right(prior_year_month, 2) AS INTEGER) = month
ORDER BY year_month;
