-- 06_fact_order_items.sql
-- Grain   : 1 row per order item (180,519 rows)
-- Keys    : order_item_id (PK), order_id (degenerate dimension)
-- FKs     : order_date_key, ship_date_key -> dim_date
--           customer_id -> dim_customer, product_id -> dim_product
--           geography_key -> dim_geography, shipping_key -> dim_shipping
-- Note    : no rows are filtered here. Canceled / fraud / low-coverage rows are
--           flagged and filtered in the analysis layer.
--           Joins use IS NOT DISTINCT FROM so a NULL in a key column can't silently drop rows.

CREATE OR REPLACE TABLE fact_order_items AS
SELECT
    s.order_item_id,
    s.order_id,
    CAST(strftime(s.order_date,    '%Y%m%d') AS INTEGER) AS order_date_key,
    CAST(strftime(s.shipping_date, '%Y%m%d') AS INTEGER) AS ship_date_key,
    s.customer_id,
    s.product_id,
    g.geography_key,
    sh.shipping_key,
    s.order_date,
    s.shipping_date,
    s.order_status,
    s.payment_type,
    s.delivery_status,
    s.quantity,
    s.sales,
    s.discount_amount,
    s.discount_rate,
    s.net_sales,
    s.profit,
    s.profit_ratio,
    s.days_shipping_real,
    s.shipping_delay_days,
    s.is_late,
    s.is_canceled,
    s.is_suspected_fraud,
    s.is_low_coverage_period
FROM stg_order_items s
JOIN dim_geography g
  ON  g.market        IS NOT DISTINCT FROM s.market
  AND g.order_region  IS NOT DISTINCT FROM s.order_region
  AND g.order_country IS NOT DISTINCT FROM s.order_country
  AND g.order_state   IS NOT DISTINCT FROM s.order_state
  AND g.order_city    IS NOT DISTINCT FROM s.order_city
JOIN dim_shipping sh
  ON  sh.shipping_mode IS NOT DISTINCT FROM s.shipping_mode;
