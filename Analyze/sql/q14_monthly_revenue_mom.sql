-- q14_monthly_revenue_mom.sql
-- Business question : 05 Demand trends (analysis #14 in Model/handoff_plan.md)
--                     How does revenue move month to month, per department?
-- Filter   : excludes canceled + suspected fraud + low-coverage months (Oct 2017 - Jan 2018)
-- Output   : one row per month x department, with month-over-month % change
-- Skills   : LAG() window function partitioned by department

WITH monthly AS (
    SELECT
        d.year_month,
        p.department_name,
        SUM(f.net_sales) AS net_revenue,
        COUNT(*)         AS items
    FROM fact_order_items f
    JOIN dim_date    d ON f.order_date_key = d.date_key
    JOIN dim_product p ON f.product_id     = p.product_id
    WHERE NOT f.is_canceled
      AND NOT f.is_suspected_fraud
      AND NOT f.is_low_coverage_period
    GROUP BY d.year_month, p.department_name
)
SELECT
    year_month,
    department_name,
    items,
    ROUND(net_revenue, 0) AS net_revenue,
    ROUND(LAG(net_revenue) OVER (PARTITION BY department_name ORDER BY year_month), 0) AS prev_month_revenue,
    ROUND(100.0 * (net_revenue - LAG(net_revenue) OVER (PARTITION BY department_name ORDER BY year_month))
                / NULLIF(LAG(net_revenue) OVER (PARTITION BY department_name ORDER BY year_month), 0), 1) AS mom_pct
FROM monthly
ORDER BY department_name, year_month;
