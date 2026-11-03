-- q16_seasonality_index.sql
-- Business question : 05 Demand trends (analysis #16 in Model/handoff_plan.md)
--                     Are some months of the year always stronger or weaker?
-- Filter   : excludes canceled + suspected fraud + low-coverage months (Oct 2017 - Jan 2018)
-- Method   : seasonality index = average revenue for that calendar month
--                                / average revenue across all months x 100
--            100 = a normal month, 110 = 10% above normal, 90 = 10% below normal
--            Jan-Sep have 3 years of data (2015-2017), Oct-Dec have 2 (2015-2016).
-- Skills   : two-step aggregation (month totals, then average by month of year), AVG() OVER ()

WITH monthly AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        SUM(f.net_sales) AS net_revenue
    FROM fact_order_items f
    JOIN dim_date d ON f.order_date_key = d.date_key
    WHERE NOT f.is_canceled
      AND NOT f.is_suspected_fraud
      AND NOT f.is_low_coverage_period
    GROUP BY d.year, d.month, d.month_name
),
by_month AS (
    SELECT
        month,
        month_name,
        COUNT(*)         AS years_of_data,
        AVG(net_revenue) AS avg_revenue
    FROM monthly
    GROUP BY month, month_name
)
SELECT
    month,
    month_name,
    years_of_data,
    ROUND(avg_revenue, 0)                                     AS avg_monthly_revenue,
    ROUND(100.0 * avg_revenue / AVG(avg_revenue) OVER (), 1)  AS seasonality_index
FROM by_month
ORDER BY month;
