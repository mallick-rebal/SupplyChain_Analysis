# Clean — Data cleaning stage

Owner: **Samir** · Downstream: Samriti (star schema + SQL) → Rebal (Power BI)

## Handoff contract

| Output | Path | For |
|---|---|---|
| Cleaned order items (one flat table) | `Data/Cleaned/order_items_clean.parquet` (+ `.csv`) | Samriti's model, Rebal's Power BI |
| Control totals | `Data/Cleaned/control_totals.json` | Reconciliation: Python = SQL = Power BI |
| Column definitions | `Clean/data_dictionary.md` | Everyone |
| Cleaning decisions | `Clean/cleaning_rules.md` | Everyone / README |

## Settled decisions (2026-10-14)

- Cleaning delivers **one flat table**; the star schema is built by Samriti.
- **No rows are deleted.** CANCELED and SUSPECTED_FRAUD orders get flag columns (`is_canceled`, `is_suspected_fraud`); the team agrees which KPIs filter them.
- `tokenized_access_logs.csv` is **out of scope for V1** (Phase 2 idea). It stays untouched in `Data/Raw`.
- PII (email, names, password, street) is dropped before anything is published.

## Files

| File | Purpose |
|---|---|
| `01_profiling.ipynb` | Explore the raw data; propose rules |
| `02_cleaning_decisions.ipynb` | Test each rule, before/after, rows affected |
| `clean_pipeline.py` | Reproducible raw → cleaned script (the real pipeline) |
| `validate.py` | Quality checks + writes control totals |
| `cleaning_rules.md` | Decision log |
| `data_dictionary.md` | Output column definitions |
| `TASKS.md` | Task checklist |

## Run

```bash
pip install -r requirements.txt
python Clean/clean_pipeline.py
python Clean/validate.py
```
