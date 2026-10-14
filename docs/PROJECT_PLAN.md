# Project Plan — SupplyChainIQ

Internal working plan. The public overview is in the [README](../README.md).

## Roles

| Stage | Folder | Owner | Output |
|---|---|---|---|
| Clean + validate | `Clean/` → `Data/Cleaned/` | Samir | One flat cleaned order-item table, data dictionary, control totals |
| Model | `Model/` | Samriti | Star schema built from the cleaned table |
| Analyze | `Analyze/` | Samriti | SQL analyses, EDA, KPIs |
| Act | `Business Act/` | Rebal | 6-page Power BI dashboard + report |

Roles rotate between projects, so nobody repeats their last role.
**Shared by everyone:** data-quality decisions, code review, QA, README, business recommendations, final demo.

## Execution Plan (4–6 weeks)

| Step | Focus | Deliverable |
|---|---|---|
| 1 | Charter + KPIs | Business questions, data dictionary |
| 2 | Clean + validate | Data-quality rules, cleaned dataset |
| 3 | Model | Star schema |
| 4 | Fulfillment | SLA / late-delivery SQL findings |
| 5 | Profitability | Product / market financial exposure |
| 6 | Demand trends | Seasonality and trends |
| 7 | Power BI + QA | Dashboard MVP, reconciled totals |
| 8 | Release | Recommendations, README, demo |

## Team Rhythm

- 30-min weekly sync
- GitHub board: Backlog → Ready → In Progress → Review → Done
- Feature branches + pull requests; major merges reviewed
- One LinkedIn post per step, rotating between team members

## Team Decisions

- Cleaning hands off **one flat table**; the star schema is built in the Model stage.
- **No rows are deleted.** CANCELED and SUSPECTED_FRAUD orders are kept and flagged (`is_canceled`, `is_suspected_fraud`); the team agrees which KPIs filter them.
- **PII is dropped** (email, names, password, street) before anything is published.
- No external database: everything lives in GitHub.
- `tokenized_access_logs.csv` is out of scope for V1.

## Definition of Done

- [ ] Reproducible cleaning + validation pipeline
- [ ] Documented data-quality rules
- [ ] Star schema
- [ ] 15+ meaningful SQL analyses
- [ ] 6-page Power BI decision dashboard
- [ ] Python / SQL / Power BI totals reconciled
- [ ] Architecture diagram + data dictionary
- [ ] Executive recommendations
- [ ] README with full findings + 5–10 minute demo

**QA rule:** if Python ≠ SQL ≠ Power BI, we do not ship.
