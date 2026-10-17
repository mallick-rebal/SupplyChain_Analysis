-- 00_staging.sql
-- Purpose : point DuckDB at the cleaned file handed off from the Clean stage.
-- Source  : Data/Cleaned/order_items_clean.parquet (180,519 rows x 42 cols)
-- Run from the repo root.

CREATE OR REPLACE VIEW stg_order_items AS
SELECT *
FROM read_parquet('Data/Cleaned/order_items_clean.parquet');
