-- 05_dim_geography.sql
-- Grain   : 1 row per delivery destination (market > region > country > state > city)
-- Key     : geography_key (surrogate)
-- Use this for all fulfillment and market analysis.

CREATE OR REPLACE TABLE dim_geography AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY market, order_region, order_country, order_state, order_city
    ) AS geography_key,
    market,
    order_region,
    order_country,
    order_state,
    order_city
FROM (
    SELECT DISTINCT market, order_region, order_country, order_state, order_city
    FROM stg_order_items
);
