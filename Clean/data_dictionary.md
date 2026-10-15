# Data dictionary — `order_items_clean`

**File:** `Data/Cleaned/order_items_clean.parquet` (+ `.csv`) · **180,519 rows × 42 columns** · no nulls
**Grain:** one row per **order item** (`order_item_id` is unique). An order (`order_id`) has 1–5 items.
**Source:** `Data/Raw/DataCoSupplyChainDataset.csv` → `Clean/clean_pipeline.py`. Rule IDs refer to [cleaning_rules.md](cleaning_rules.md).

> **All money columns are item-level.** Summing them gives correct totals; for per-order figures, `GROUP BY order_id` first.

## Keys

| Column | Type | Description | Raw column | Notes |
|---|---|---|---|---|
| `order_item_id` | int | Unique ID of the order item (primary key) | Order Item Id | |
| `order_id` | int | Order the item belongs to | Order Id | 65,752 orders |
| `customer_id` | int | Customer who placed the order | Customer Id | 20,652 customers; = raw Order Customer Id |
| `product_id` | int | Product | Product Card Id | 118 products; = raw Order Item Cardprod Id |
| `category_id` | int | Product category | Category Id | 51 categories; use this as the key, not the name |
| `department_id` | int | Store department | Department Id | 11 departments |

## Dates

| Column | Type | Description | Raw column | Notes |
|---|---|---|---|---|
| `order_date` | datetime | When the order was placed | order date (DateOrders) | 2015-01-01 → 2018-01-31 |
| `shipping_date` | datetime | When the item shipped | shipping date (DateOrders) | Always ≥ `order_date` |

## Order

| Column | Type | Description | Raw column | Notes |
|---|---|---|---|---|
| `order_status` | text | COMPLETE, PENDING, PENDING_PAYMENT, PROCESSING, CLOSED, ON_HOLD, PAYMENT_REVIEW, CANCELED, SUSPECTED_FRAUD | Order Status | |
| `payment_type` | text | DEBIT, TRANSFER, PAYMENT, CASH | Type | Fully determined by `order_status` (synthetic-data artefact) |
| `customer_segment` | text | Consumer, Corporate, Home Office | Customer Segment | One segment per customer |

## Shipping

| Column | Type | Description | Raw column | Notes |
|---|---|---|---|---|
| `shipping_mode` | text | Standard Class, Second Class, First Class, Same Day | Shipping Mode | |
| `days_shipping_real` | int | Actual days from order to shipment (0–6) | Days for shipping (real) | |
| `days_shipping_scheduled` | int | Promised days (the SLA) | Days for shipment (scheduled) | Fixed per mode: Same Day 0, First 1, Second 2, Standard 4 |
| `shipping_delay_days` | int | Real − scheduled. **Positive = late**, negative = early | *derived* (R15) | −2 to 4 |
| `delivery_status` | text | Advance shipping, Shipping on time, Late delivery, Shipping canceled | Delivery Status | Shipping canceled = canceled or fraud orders |
| `is_late` | bool | Item shipped later than scheduled | Late_delivery_risk | Not a risk score; = `delivery_status` 'Late delivery' |

## Product

| Column | Type | Description | Raw column | Notes |
|---|---|---|---|---|
| `product_name` | text | Product name | Product Name | Trimmed (R08) |
| `product_price` | decimal | List price per unit, before discount | Product Price | One price per product; = raw Order Item Product Price |
| `category_name` | text | Category name | Category Name | Trimmed; `Electronics (Footwear)` / `Electronics (Outdoors)` disambiguated (R12) |
| `department_name` | text | Department name | Department Name | Trimmed |

## Money (item-level)

| Column | Type | Description | Raw column | Notes |
|---|---|---|---|---|
| `quantity` | int | Units of the product in this item (1–5) | Order Item Quantity | |
| `sales` | decimal | **Gross** revenue: `product_price × quantity` | Sales | |
| `discount_amount` | decimal | Discount in $ | Order Item Discount | Source of truth for discounts |
| `discount_rate` | decimal | Discount as listed (0–0.25) | Order Item Discount Rate | Doesn't always equal discount ÷ sales; use the amount for money |
| `net_sales` | decimal | **Net** revenue: `sales − discount_amount` (±$0.01) | Order Item Total | = raw Sales per customer. Use for revenue KPIs |
| `profit` | decimal | Profit on this item; can be negative | Order Profit Per Order | Misleading raw name: it's item-level. = raw Benefit per order |
| `profit_ratio` | decimal | `profit ÷ net_sales` (−2.75 to 0.5) | Order Item Profit Ratio | |

All money is rounded to 2 decimals (R07).

## Destination (where the order is delivered)

| Column | Type | Description | Raw column | Notes |
|---|---|---|---|---|
| `market` | text | Africa, Europe, LATAM, Pacific Asia, USCA | Market | |
| `order_region` | text | 23 world regions (e.g. Western Europe, South of USA) | Order Region | Trimmed |
| `order_country` | text | Destination country, **English** | Order Country | Translated from Spanish (R09); 164 countries |
| `order_state` | text | Destination state / province | Order State | Original language (often Spanish) |
| `order_city` | text | Destination city | Order City | Original language |

## Store (where the purchase was registered)

| Column | Type | Description | Raw column | Notes |
|---|---|---|---|---|
| `customer_city` | text | Store city | Customer City | 3 shifted rows fixed (R10) |
| `customer_state` | text | Store state (2-letter code) | Customer State | |
| `customer_zipcode` | text | Store zip, 5 characters | Customer Zipcode | Leading zeros restored (R06) |
| `customer_country` | text | United States or Puerto Rico | Customer Country | Translated (`EE. UU.` → United States) |
| `store_latitude` | decimal | Store latitude | Latitude | |
| `store_longitude` | decimal | Store longitude (always negative) | Longitude | 105 sign errors fixed (R11) |

> Use **destination** columns for fulfillment and market analysis. The `customer_*` / `store_*` columns are always US / Puerto Rico.

## Flags

| Column | Type | Description | Rows true | Rule |
|---|---|---|---|---|
| `is_canceled` | bool | `order_status` = CANCELED | 3,692 | R13 |
| `is_suspected_fraud` | bool | `order_status` = SUSPECTED_FRAUD | 4,062 | R14 |
| `is_low_coverage_period` | bool | `order_date` ≥ 2017-10-01; only 2 markets and 31 products, so not comparable for trends | 8,557 | R16 |

## Dropped raw columns (15)

| Reason | Columns |
|---|---|
| Personal data (R01) | Customer Email, Customer Password, Customer Fname, Customer Lname, Customer Street |
| No value (R02) | Product Description (empty), Product Status (constant), Product Image (URL), Order Zipcode (86% empty) |
| Exact duplicates (R03) | Benefit per order, Sales per customer, Order Customer Id, Product Category Id, Order Item Product Price, Order Item Cardprod Id |
