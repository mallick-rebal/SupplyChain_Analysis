# Cleaning rules — decision log

Each rule is tested in `02_cleaning_decisions.ipynb` and implemented in `clean_pipeline.py`.
Status: `proposed` → `agreed` → `implemented`.

| ID | Rule | Why | Rows / cols affected | Status |
|---|---|---|---|---|
| R01 | Drop PII columns (Customer Email, Fname, Lname, Password, Street) | Repo is public; not needed for analysis | | proposed |
| R02 | Drop empty / useless columns (e.g. Product Description, Product Image) | No analytical value | | proposed |
| R03 | Drop redundant duplicate columns (after confirming identical) | Avoid conflicting definitions downstream | | proposed |
| R04 | Rename all columns to snake_case | Easier SQL / DAX | | proposed |
| R05 | Parse order and shipping dates to datetime | Stored as text | | proposed |
| R06 | Standardise text / country names, fix encoding | Spanish names, latin-1 artefacts | | proposed |
| R07 | Add `is_canceled`, `is_suspected_fraud` flags; keep all rows | Team decision — keeps totals reconcilable | | proposed |
| R08 | Derived fields (e.g. `shipping_delay_days`) | Needed for SLA analysis | | proposed |

## Open questions for the team

- Which KPIs exclude canceled / fraud orders? (agree with Samriti + Rebal)
