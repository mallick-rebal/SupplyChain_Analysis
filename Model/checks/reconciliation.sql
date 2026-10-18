-- reconciliation.sql
-- Purpose : prove the star schema matches the Clean stage before anything is shared.
-- Rule    : every row must say PASS. If anything says FAIL, do not export.

WITH ct AS (
    SELECT * FROM read_json_auto('Data/Cleaned/control_totals.json')
),
model AS (
    SELECT
        COUNT(*)                         AS rows,
        COUNT(DISTINCT order_id)         AS orders,
        SUM(quantity)                    AS quantity,
        ROUND(SUM(sales), 2)             AS sales,
        ROUND(SUM(net_sales), 2)         AS net_sales,
        ROUND(SUM(profit), 2)            AS profit,
        SUM(CASE WHEN is_late THEN 1 ELSE 0 END) AS late_items
    FROM fact_order_items
),
model_excl AS (
    SELECT
        COUNT(*)                 AS rows,
        ROUND(SUM(net_sales), 2) AS net_sales,
        ROUND(SUM(profit), 2)    AS profit
    FROM fact_order_items
    WHERE NOT is_canceled AND NOT is_suspected_fraud
),
checks AS (
    -- 1. Totals vs control_totals.json (all rows)
    SELECT 'rows = control total'         AS check_name, m.rows::DOUBLE      AS model_value, ct.all_rows.rows::DOUBLE      AS expected FROM model m, ct
    UNION ALL SELECT 'orders = control total',     m.orders,     ct.all_rows.orders     FROM model m, ct
    UNION ALL SELECT 'quantity = control total',   m.quantity,   ct.all_rows.quantity   FROM model m, ct
    UNION ALL SELECT 'sales = control total',      m.sales,      ct.all_rows.sales      FROM model m, ct
    UNION ALL SELECT 'net_sales = control total',  m.net_sales,  ct.all_rows.net_sales  FROM model m, ct
    UNION ALL SELECT 'profit = control total',     m.profit,     ct.all_rows.profit     FROM model m, ct
    UNION ALL SELECT 'late_items = control total', m.late_items, ct.all_rows.late_items FROM model m, ct
    -- 2. Totals with the default KPI filter (excl. canceled + fraud)
    UNION ALL SELECT 'rows excl canceled+fraud',      e.rows,      ct.excl_canceled_and_fraud.rows      FROM model_excl e, ct
    UNION ALL SELECT 'net_sales excl canceled+fraud', e.net_sales, ct.excl_canceled_and_fraud.net_sales FROM model_excl e, ct
    UNION ALL SELECT 'profit excl canceled+fraud',    e.profit,    ct.excl_canceled_and_fraud.profit    FROM model_excl e, ct
    -- 3. Primary key is unique
    UNION ALL SELECT 'order_item_id unique', COUNT(DISTINCT order_item_id), COUNT(*) FROM fact_order_items
    -- 4. Every foreign key finds its dimension row (0 orphans expected)
    UNION ALL SELECT 'orphan order_date_key', COUNT(*), 0 FROM fact_order_items f LEFT JOIN dim_date d ON f.order_date_key = d.date_key WHERE d.date_key IS NULL
    UNION ALL SELECT 'orphan ship_date_key',  COUNT(*), 0 FROM fact_order_items f LEFT JOIN dim_date d ON f.ship_date_key  = d.date_key WHERE d.date_key IS NULL
    UNION ALL SELECT 'orphan customer_id',    COUNT(*), 0 FROM fact_order_items f LEFT JOIN dim_customer c  ON f.customer_id   = c.customer_id   WHERE c.customer_id   IS NULL
    UNION ALL SELECT 'orphan product_id',     COUNT(*), 0 FROM fact_order_items f LEFT JOIN dim_product p   ON f.product_id    = p.product_id    WHERE p.product_id    IS NULL
    UNION ALL SELECT 'orphan geography_key',  COUNT(*), 0 FROM fact_order_items f LEFT JOIN dim_geography g ON f.geography_key = g.geography_key WHERE g.geography_key IS NULL
    UNION ALL SELECT 'orphan shipping_key',   COUNT(*), 0 FROM fact_order_items f LEFT JOIN dim_shipping s  ON f.shipping_key  = s.shipping_key  WHERE s.shipping_key  IS NULL
    -- 5. Dimension keys are unique (no accidental duplicates from DISTINCT)
    UNION ALL SELECT 'dim_product 1 row per product',   COUNT(DISTINCT product_id),  COUNT(*) FROM dim_product
    UNION ALL SELECT 'dim_customer 1 row per customer', COUNT(DISTINCT customer_id), COUNT(*) FROM dim_customer
)
SELECT
    check_name,
    model_value,
    expected,
    CASE WHEN ABS(model_value - expected) <= 0.01 THEN 'PASS' ELSE 'FAIL' END AS result
FROM checks;
