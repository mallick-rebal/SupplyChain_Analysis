# Cleaning Plan — Rules & Decision Log

Source: `Data/Raw/DataCoSupplyChainDataset.csv` (latin-1) · **180,519 rows × 53 columns** · grain = one row per order item.
Output: `Data/Cleaned/order_items_clean.parquet` · **180,519 rows × 42 columns** (no rows removed).

Each rule is tested in `02_cleaning_decisions.ipynb`, then implemented in `clean_pipeline.py`.
The reasoning behind every rule is in the [cleaning report](cleaning_report.md).
Status: `proposed` → `agreed` → `implemented`.

## Step 1 — Remove columns (53 → 38)

| ID | Rule | Columns | Evidence | Status |
|---|---|---|---|---|
| R01 | Drop PII | Customer Email, Customer Password, Customer Fname, Customer Lname, Customer Street | Email and password are masked (`XXXXXXXXX`) for every row; names and street identify people and add nothing to the analysis | implemented (v0) |
| R02 | Drop empty / constant / no-value columns | Product Description, Product Status, Product Image, Order Zipcode | Description 100% null; Product Status = 0 for every row; Image is a URL; Order Zipcode 86% null (US orders only) | implemented (v0) |
| R03 | Drop exact duplicate columns | Benefit per order, Sales per customer, Order Customer Id, Product Category Id, Order Item Product Price, Order Item Cardprod Id | Each is 100% identical to another kept column (see report §3) | implemented (v0) |

## Step 2 — Fix types and formats

| ID | Rule | Evidence | Status |
|---|---|---|---|
| R04 | Rename all columns to clear snake_case names (see output schema below) | Mixed case, spaces, trailing spaces in raw headers; some names are misleading (e.g. "Order Profit Per Order" is item-level) | implemented (v0) |
| R05 | Parse `order date` and `shipping date` to datetime (`%m/%d/%Y %H:%M`) | Stored as text. All parse; 0 ship dates before order date; order dates 2015-01-01 → 2018-01-31. **v0 result: 0 parse failures** | implemented (v0) |
| R06 | Customer zipcode → 5-char text with leading zeros | Stored as float; all 69,373 Puerto Rico zips lost their leading `00` (e.g. `725` → `00725`) | proposed |
| R07 | Round money columns to 2 decimals | 4,613 rows where net = sales − discount is off by exactly $0.01 (float storage artefact) | proposed |

## Step 3 — Fix values

| ID | Rule | Evidence | Status |
|---|---|---|---|
| R08 | Trim whitespace and collapse double spaces in all text columns | Trailing spaces in Category Name (1,475 rows), Product Name (1,774), Department Name (362), Order Region (17,925); e.g. `"South of  USA "`, `"As Seen on  TV!"`. **v0 result: 21,604 cells changed; no categories or products merged** | implemented (v0) |
| R09 | Translate country names Spanish → English (`order_country`, `customer_country`) via a mapping file `Clean/mappings/country_es_en.csv` | 164 destination countries in Spanish (`Estados Unidos`, `Francia`, `Alemania`…); customer country `EE. UU.` | proposed |
| R10 | Fix 3 shifted customer-address rows | City = `"CA"`, State = zip (`95758`, `91732`). Shift values back: city ← street, state ← `CA`, zipcode ← state | proposed |
| R11 | Fix store longitude sign | 105 rows of US stores (e.g. Las Vegas, Tampa, DC) with positive longitude → negate | proposed |
| R12 | Disambiguate duplicate category name | `Electronics` used by two IDs: 13 (Footwear dept) and 37 (Outdoors dept) → `Electronics (Footwear)` / `Electronics (Outdoors)` | proposed |

## Step 4 — Add flags and derived fields (38 → 42)

| ID | New column | Logic | Why | Status |
|---|---|---|---|---|
| R13 | `is_canceled` | order_status = `CANCELED` (3,692 rows) | Keep + flag (team decision) | proposed |
| R14 | `is_suspected_fraud` | order_status = `SUSPECTED_FRAUD` (4,062 rows) | Keep + flag (team decision) | proposed |
| R15 | `shipping_delay_days` | days_shipping_real − days_shipping_scheduled | Core SLA metric (Question 02) | proposed |
| R16 | `is_low_coverage_period` | order_date ≥ 2017-10-01 (8,557 rows) | Last 4 months contain only Europe + Pacific Asia, 31 products, ~1 item per order — not comparable for trends | proposed |

## Step 5 — Validate (`validate.py`)

- Row count = 180,519; `order_item_id` unique
- No PII columns present
- `sales = product_price × quantity` (100%), `net_sales = sales − discount_amount` (±0.01)
- shipping_date ≥ order_date; all dates parsed
- Ranges: quantity 1–5, discount_rate 0–0.25, days 0–6
- No country names left untranslated; no text with leading/trailing spaces
- Flags are boolean and match their source counts
- Write `control_totals.json`

## Output schema — `order_items_clean` (42 columns)

| Group | Columns |
|---|---|
| Keys | `order_item_id`, `order_id`, `customer_id`, `product_id`, `category_id`, `department_id` |
| Dates | `order_date`, `shipping_date` |
| Order | `order_status`, `payment_type`, `customer_segment` |
| Shipping | `shipping_mode`, `days_shipping_real`, `days_shipping_scheduled`, `shipping_delay_days`, `delivery_status`, `is_late` |
| Product | `product_name`, `product_price`, `category_name`, `department_name` |
| Money | `quantity`, `sales`, `discount_amount`, `discount_rate`, `net_sales`, `profit`, `profit_ratio` |
| Destination | `market`, `order_region`, `order_country`, `order_state`, `order_city` |
| Store / customer | `customer_city`, `customer_state`, `customer_zipcode`, `customer_country`, `store_latitude`, `store_longitude` |
| Flags | `is_canceled`, `is_suspected_fraud`, `is_low_coverage_period` |

## Not changed (on purpose)

- **No rows removed.** No duplicates exist; cancelled, fraud and loss-making rows are real business events.
- **Negative profit** (18.7% of rows, ratio down to −2.75) kept: this is the profit-leakage story, not an error.
- **`order_state` / `order_city`** left in their original (Spanish) form: 1,089 states and 3,597 cities are too many to translate by hand. Country is enough for maps.
- **`discount_rate`** kept as given, even though it doesn't always equal discount ÷ sales (10,029 rows, ~$1 off). `discount_amount` is the source of truth for money.

## Open questions for the team

- Default KPI filters: exclude `is_canceled` / `is_suspected_fraud` from revenue? From SLA metrics? (proposal in [handoff plan](../Model/handoff_plan.md))
- Trend charts: stop at Sep 2017, or show the low-coverage months with a warning?
