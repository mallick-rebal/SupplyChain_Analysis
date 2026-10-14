"""Validate the cleaned table and write control totals.

Run from the repo root after clean_pipeline.py:
    python Clean/validate.py

Control totals are the numbers SQL (Samriti) and Power BI (Rebal) must reconcile to.
QA rule: if Python != SQL != Power BI, we do not ship.
"""

import json
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
CLEAN_FILE = ROOT / "Data" / "Cleaned" / "order_items_clean.parquet"
TOTALS_FILE = ROOT / "Data" / "Cleaned" / "control_totals.json"

EXPECTED_ROWS = 180_519


def run_checks(df: pd.DataFrame) -> list[str]:
    """Return a list of failure messages (empty = all good)."""
    failures = []
    if len(df) != EXPECTED_ROWS:
        failures.append(f"row count {len(df):,} != {EXPECTED_ROWS:,}")
    # TODO: unique order_item_id
    # TODO: no PII columns present
    # TODO: dates parsed, ship date >= order date
    # TODO: value ranges (quantity > 0, discount rate 0-1, ...)
    # TODO: flag columns exist and are boolean
    return failures


def control_totals(df: pd.DataFrame) -> dict:
    # TODO: revenue, profit, late %, on-time %, orders, customers, by-market splits
    return {"rows": len(df)}


def main() -> None:
    df = pd.read_parquet(CLEAN_FILE)
    failures = run_checks(df)
    for f in failures:
        print("FAIL:", f)
    TOTALS_FILE.write_text(json.dumps(control_totals(df), indent=2))
    print(f"{'FAILED' if failures else 'PASSED'} — totals -> {TOTALS_FILE.relative_to(ROOT)}")
    raise SystemExit(1 if failures else 0)


if __name__ == "__main__":
    main()
