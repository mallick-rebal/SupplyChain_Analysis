# Cleaning tasks — Samir

Move to the GitHub board when ready (Backlog → Ready → In Progress → Review → Done).

## Setup
- [x] Scaffold `Clean/` folder, notebooks, script stubs, docs
- [ ] Install requirements, confirm notebooks open

## Profiling (`01_profiling.ipynb`)
- [ ] Shape, types, grain (is `Order Item Id` unique?)
- [ ] Null % per column
- [ ] Confirm redundant column pairs
- [ ] Categorical values + country names / encoding
- [ ] Numeric sanity checks
- [ ] Date ranges, ship-before-order cases
- [ ] Write findings into `cleaning_rules.md`

## Early handoff
- [ ] Ship a **v0** cleaned file (PII dropped, dates parsed, snake_case) so Samriti can start modelling

## Cleaning (`02_cleaning_decisions.ipynb` → `clean_pipeline.py`)
- [ ] R01–R08 tested in notebook
- [ ] Rules agreed with team (esp. canceled / fraud KPI filters)
- [ ] Rules ported into `clean_pipeline.py`

## Validation (`validate.py`)
- [ ] Implement checks
- [ ] Implement control totals
- [ ] Share control totals with Samriti + Rebal

## Docs + handoff
- [ ] Fill `data_dictionary.md`
- [ ] Final `cleaning_rules.md` with rows affected
- [ ] PR for review
- [ ] LinkedIn post for the cleaning step
