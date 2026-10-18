-- 01_dim_date.sql
-- Grain   : 1 row per calendar day, 2015-01-01 -> 2018-02-06 (covers order and shipping dates)
-- Key     : date_key = yyyymmdd integer
-- Note    : generated, not taken from the data, so there are no gaps for Power BI time intelligence.

CREATE OR REPLACE TABLE dim_date AS
SELECT
    CAST(strftime(d, '%Y%m%d') AS INTEGER)        AS date_key,
    CAST(d AS DATE)                               AS full_date,
    year(d)                                       AS year,
    quarter(d)                                    AS quarter,
    'Q' || quarter(d)                             AS quarter_name,
    month(d)                                      AS month,
    strftime(d, '%B')                             AS month_name,
    strftime(d, '%Y-%m')                          AS year_month,
    weekofyear(d)                                 AS week_of_year,
    isodow(d)                                     AS weekday_number,   -- 1 = Monday
    strftime(d, '%A')                             AS weekday_name,
    isodow(d) IN (6, 7)                           AS is_weekend,
    d >= DATE '2017-10-01'                        AS is_low_coverage_period
FROM generate_series(DATE '2015-01-01', DATE '2018-02-06', INTERVAL 1 DAY) AS t(d);
