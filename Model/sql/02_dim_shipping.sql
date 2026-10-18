-- 02_dim_shipping.sql
-- Grain   : 1 row per shipping mode (4 rows). This table IS the SLA rule.
-- Key     : shipping_key (surrogate, ordered fastest -> slowest)

CREATE OR REPLACE TABLE dim_shipping AS
SELECT
    ROW_NUMBER() OVER (ORDER BY days_shipping_scheduled) AS shipping_key,
    shipping_mode,
    days_shipping_scheduled                              AS sla_days
FROM (
    SELECT DISTINCT shipping_mode, days_shipping_scheduled
    FROM stg_order_items
);
