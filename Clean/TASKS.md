# Cleaning tasks — Samir

Move to the GitHub board when ready (Backlog → Ready → In Progress → Review → Done).
Rule IDs refer to [cleaning_rules.md](cleaning_rules.md).

## Setup
- [x] Scaffold `Clean/` folder, notebooks, script stubs, docs
- [x] Install requirements (`pip install -r requirements.txt`, includes pyarrow)

## Profiling — done in planning, record it in `01_profiling.ipynb`
- [x] Shape, grain, nulls, duplicates, redundant columns
- [x] Categorical values, numbers, dates, text issues
- [x] Findings written into `cleaning_rules.md` and `cleaning_report.md`
- [x] Put the profiling code + outputs into `01_profiling.ipynb` (evidence for reviewers)

## Early handoff (unblocks Samriti)
- [x] **v0** file: R01–R05 + R08 (PII dropped, columns removed, snake_case, dates, trimmed text)
- [ ] Tell Samriti the **final** file is ready; point her to `Model/handoff_plan.md`

## Cleaning (`clean_pipeline.py`; re-run `02_cleaning_decisions.ipynb` after each rule)
- [x] `02_cleaning_decisions.ipynb` shows every rule by calling the pipeline functions
- [x] Create `Clean/mappings/country_es_en.csv` (166 names, 103 translated)
- [x] R01–R04 columns: drop + rename
- [x] R05–R07 formats: dates, zipcode, rounding
- [x] R08–R09 text: whitespace, country translation
- [x] R10–R12 known errors: shifted rows, longitude sign, Electronics name
- [x] R13–R16 flags + `shipping_delay_days`
- [x] Fill "rows affected" in `cleaning_rules.md`; set status → implemented

## Validation (`validate.py`)
- [x] v0 checks (rows, uniqueness, PII, names, dates, money math, ranges, whitespace)
- [x] Remaining checks: zipcode format, country translation, flags (24 checks, all passing)
- [x] Control totals: all rows · excl. canceled + fraud · excl. canceled + fraud + low coverage · net sales by market
- [ ] Share control totals with Samriti + Rebal

## Team decisions (next sync)
- [ ] Default KPI filters for canceled / fraud rows
- [ ] Trend charts: stop at Sep 2017 or show low-coverage months with a warning

## Docs + handoff
- [x] Fill `data_dictionary.md` (42 columns)
- [x] Final review of `cleaning_report.md` numbers against pipeline output
- [ ] PR for review
- [ ] LinkedIn post for the cleaning step
