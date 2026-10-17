-- 04_dim_customer.sql
-- Grain   : 1 row per customer (20,652 rows)
-- Key     : customer_id
-- Note    : customer_* / store_* columns describe the STORE (US / Puerto Rico),
--           not the delivery destination. Destination lives in dim_geography.

CREATE OR REPLACE TABLE dim_customer AS
SELECT DISTINCT
    customer_id,
    customer_segment,
    customer_city     AS store_city,
    customer_state    AS store_state,
    customer_zipcode  AS store_zipcode,
    customer_country  AS store_country,
    store_latitude,
    store_longitude
FROM stg_order_items;
