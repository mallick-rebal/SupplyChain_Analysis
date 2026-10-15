# Data Cleaning Report

**Project:** SupplyChainIQ · **Stage:** Clean + Validate · **Owner:** Samir Omer
**Dataset:** DataCo Smart Supply Chain (`DataCoSupplyChainDataset.csv`)

This report explains **what we found in the raw data and why we cleaned it the way we did**.
The rule-by-rule plan is in [cleaning_rules.md](cleaning_rules.md).

---

## 1. Summary

| | Raw | Clean |
|---|---|---|
| Rows | 180,519 | 180,519 |
| Columns | 53 | 42 |
| Duplicate rows | 0 | 0 |
| PII columns | 5 | 0 |
| Text in Spanish | country names | English |

**Main principle: fix the data, never hide it.** We removed columns, not rows. Every unusual row (cancelled, fraud, loss-making, low-coverage period) is kept and **flagged**, so any total can be traced back to the raw file. This is what lets us apply our QA rule: *Python = SQL = Power BI*.

## 2. What the data is

- **Grain:** one row per order item. `order_item_id` is unique.
- **Scale:** 65,752 orders · 20,652 customers · 118 products · 51 categories · 11 departments · 5 markets · 164 destination countries.
- **Time span:** orders from **Jan 2015 to Jan 2018** (37 months).
- **Two kinds of geography.** This is easy to confuse:
  - *Customer / store* columns (customer city, state, country, latitude, longitude) are the **store where the purchase was registered**. They are all in the **US or Puerto Rico**.
  - *Order* columns (market, region, country, state, city) are the **delivery destination**. These are **global**.

  → Delivery and fulfillment analysis must use the **order (destination)** columns.

## 3. Why we removed 15 columns

### Privacy (5 columns)
Email and password are already masked (`XXXXXXXXX` in every row), so they carry no information. First name, last name and street identify real people and are not needed for any of our six questions. The repo is public, so these never leave the raw file.

### No information (4 columns)
| Column | Problem |
|---|---|
| Product Description | 100% empty |
| Product Status | Same value (0) in every row |
| Product Image | A URL, not analytical |
| Order Zipcode | 86% empty; only filled for US orders |

### Exact duplicates (6 columns)
We checked every suspected pair row by row. Each is **100% identical** to another column:

| Dropped | Identical to (kept) |
|---|---|
| Benefit per order | Order Profit Per Order → `profit` |
| Sales per customer | Order Item Total → `net_sales` |
| Order Customer Id | Customer Id |
| Product Category Id | Category Id |
| Order Item Product Price | Product Price |
| Order Item Cardprod Id | Product Card Id |

**Why it matters:** two columns with the same meaning invite two analysts to pick different ones, and then the totals stop matching.

## 4. Why we renamed columns

Some raw names are **misleading**, not just messy:

| Raw name | What it actually is | Clean name |
|---|---|---|
| Order Profit Per Order | Profit of **one order item** | `profit` |
| Sales | Gross: price × quantity (before discount) | `sales` |
| Order Item Total | Net: sales − discount | `net_sales` |
| Type | Payment type | `payment_type` |
| Late_delivery_risk | Not a risk score: 1 = the item **was** late | `is_late` |
| Latitude / Longitude | Store location, not customer or destination | `store_latitude` / `store_longitude` |

Summing "profit per order" across items is correct, but only if you know it is item-level. Clear names stop that mistake before it happens.

## 5. Why we fixed these values

| Issue | Found | Fix | Why it matters |
|---|---|---|---|
| Dates stored as text | 2 columns | Parse to datetime | Needed for trends, MoM / YoY |
| Puerto Rico zips lost leading zeros | 69,373 rows (`725` instead of `00725`) | 5-char text | Zips are codes, not numbers |
| Spanish country names | 164 countries (`Estados Unidos`, `Alemania`…) | Translate via mapping file | English dashboard; Power BI maps recognise English names |
| Trailing / double spaces | 21,604 cells (e.g. `"South of  USA "`) | Trim + collapse | Clean labels and safe joins: `"Cameras "` ≠ `"Cameras"` in SQL. (No duplicate categories existed in the raw data, so nothing merged.) |
| Shifted address columns | 3 rows (city = `"CA"`, state = a zipcode) | Shift values back | Wrong state breaks state-level grouping |
| Wrong longitude sign | 105 US store rows with positive longitude (would plot in Asia) | Negate | Map visuals |
| Same name, two categories | `Electronics` = ID 13 (Footwear) and ID 37 (Outdoors) | Add department to the name | Grouping by name would merge two different categories |
| 1-cent rounding gaps | 4,613 rows where net ≠ sales − discount by $0.01 | Round money to 2 dp | Totals reconcile exactly |

## 6. Why we flag instead of delete

| Flag | Rows | Why we keep these rows |
|---|---|---|
| `is_canceled` | 3,692 | Cancellations are a fulfillment KPI (Question 01). Deleting them would make the cancellation rate disappear. |
| `is_suspected_fraud` | 4,062 | Same as above. Also: these rows still have revenue, which must be excluded on purpose, not by accident. |
| `is_low_coverage_period` | 8,557 | See §7. |
| `is_late` | 98,977 | Kept from the source; matches "Late delivery" status exactly. |

Each downstream KPI chooses its filter explicitly (see the [handoff plan](../Model/handoff_plan.md)). Deleting rows would hard-code one choice for every analysis.

## 7. The most important finding for analysis: the last 4 months are different

From **October 2017 to January 2018**, the data changes shape:

| | Jan 2015 – Sep 2017 | Oct 2017 – Jan 2018 |
|---|---|---|
| Orders per month (items) | ~5,200 | ~2,100 |
| Markets | All 5 | Only Europe + Pacific Asia |
| Products sold | 100 | 31 (18 of them new) |
| Items per order | ~3.0 | ~1.0 |

This looks like a change in how data was collected, not a real collapse in demand. If trend charts include these months without a warning, they will show a **false 60% sales drop**. We keep the rows and flag them, and recommend trend analysis use **Jan 2015 – Sep 2017** (33 full months).

## 8. Things that look wrong but are kept

| Observation | Decision | Reason |
|---|---|---|
| 18.7% of items have **negative profit** (ratio down to −2.75) | Keep | This is the profit-leakage story (Question 03), not an error |
| `discount_rate` ≠ discount ÷ sales in 10,029 rows (~$1 off) | Keep both; `discount_amount` is the money source of truth | The amount reconciles to net sales; the rate is a label |
| Cancelled orders still have "real shipping days" | Keep; exclude from SLA metrics | Shipping time for a cancelled order is meaningless |
| `order_state` / `order_city` stay in Spanish | Keep | 1,089 states / 3,597 cities; country-level is enough for V1 |

## 9. Dataset quirks worth knowing

These aren't errors to fix. They're signs that DataCo is partly **synthetic data**, which we mention honestly in the final report:

- **Payment type is fully determined by order status** (e.g. every `CLOSED` order is `CASH`, every `COMPLETE` is `DEBIT`).
- **Scheduled shipping days are fully determined by shipping mode** (Same Day = 0, First = 1, Second = 2, Standard = 4). The "SLA" is a fixed rule per mode.
- **55% of items are late**, which is very high for a real business.

## 10. How to reproduce

```bash
python Clean/clean_pipeline.py   # raw → Data/Cleaned/order_items_clean.parquet
python Clean/validate.py         # checks + Data/Cleaned/control_totals.json
```
