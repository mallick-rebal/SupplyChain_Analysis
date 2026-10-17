-- 03_dim_product.sql
-- Grain   : 1 row per product (118 rows)
-- Key     : product_id (natural key; verified one price + one category per product)

CREATE OR REPLACE TABLE dim_product AS
SELECT DISTINCT
    product_id,
    product_name,
    product_price,
    category_id,
    category_name,
    department_id,
    department_name
FROM stg_order_items;
