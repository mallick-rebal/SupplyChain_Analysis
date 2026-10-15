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
- [ ] Put the profiling code + outputs into `01_profiling.ipynb` (evidence for reviewers)

## Early handoff (unblocks Samriti)
- [x] **v0** file: R01–R05 + R08 (PII dropped, columns removed, snake_case, dates, trimmed text)
- [ ] Tell Samriti v0 is ready; point her to `Model/handoff_plan.md`

## Cleaning (`02_cleaning_decisions.ipynb` → `clean_pipeline.py`)
- [ ] Create `Clean/mappings/country_es_en.csv` (164 countries + `EE. UU.`)
- [x] R01–R04 columns: drop + rename
- [ ] R05–R07 formats: ~~dates~~ (done), zipcode, rounding
- [ ] R08–R09 text: ~~whitespace~~ (done), country translation
- [ ] R10–R12 known errors: shifted rows, longitude sign, Electronics name
- [ ] R13–R16 flags + `shipping_delay_days`
- [ ] Fill "rows affected" column in `cleaning_rules.md`; set status → implemented

## Validation (`validate.py`)
- [x] v0 checks (rows, uniqueness, PII, names, dates, money math, ranges, whitespace)
- [ ] Remaining checks: zipcode format, country translation, flags
- [x] Control totals: all rows, excl. canceled + fraud, net sales by market (matches raw exactly)
- [ ] Share control totals with Samriti + Rebal

## Team decisions (next sync)
- [ ] Default KPI filters for canceled / fraud rows
- [ ] Trend charts: stop at Sep 2017 or show low-coverage months with a warning

## Docs + handoff
- [ ] Fill `data_dictionary.md` (42 columns)
- [ ] Final review of `cleaning_report.md` numbers against pipeline output
- [ ] PR for review
- [ ] LinkedIn post for the cleaning step
