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
PII_COLUMNS = ["customer_email", "customer_password", "customer_fname", "customer_lname", "customer_street"]
NOT_REALISED = ["CANCELED", "SUSPECTED_FRAUD"]


def run_checks(df: pd.DataFrame) -> list[str]:
    """Return a list of failure messages (empty = all good)."""
    checks = {
        f"row count = {EXPECTED_ROWS:,}": len(df) == EXPECTED_ROWS,
        "order_item_id unique": df["order_item_id"].is_unique,
        "no PII columns": not set(PII_COLUMNS) & set(df.columns),
        "column names are snake_case": all(c == c.lower() and " " not in c for c in df.columns),
        "dates parsed": all(pd.api.types.is_datetime64_any_dtype(df[c]) for c in ["order_date", "shipping_date"]),
        "no nulls in dates": df[["order_date", "shipping_date"]].notna().all().all(),
        "shipping_date >= order_date": (df["shipping_date"] >= df["order_date"]).all(),
        "sales = product_price x quantity": ((df["sales"] - df["product_price"] * df["quantity"]).abs() < 0.01).all(),
        "net_sales = sales - discount (±0.01)": ((df["net_sales"] - (df["sales"] - df["discount_amount"])).abs() <= 0.0101).all(),
        "quantity 1-5": df["quantity"].between(1, 5).all(),
        "discount_rate 0-0.25": df["discount_rate"].between(0, 0.25).all(),
        "shipping days 0-6": df[["days_shipping_real", "days_shipping_scheduled"]].stack().between(0, 6).all(),
        "is_late is boolean": pd.api.types.is_bool_dtype(df["is_late"]),
        "no leading / trailing / double spaces": all(
            not df[c].dropna().str.contains(r"^\s|\s$|\s{2}", regex=True).any()
            for c in df.columns
            if pd.api.types.is_string_dtype(df[c])
        ),
    }
    return [name for name, passed in checks.items() if not passed]


def _money(df: pd.DataFrame) -> dict:
    return {
        "rows": len(df),
        "orders": int(df["order_id"].nunique()),
        "quantity": int(df["quantity"].sum()),
        "sales": round(float(df["sales"].sum()), 2),
        "discount_amount": round(float(df["discount_amount"].sum()), 2),
        "net_sales": round(float(df["net_sales"].sum()), 2),
        "profit": round(float(df["profit"].sum()), 2),
        "late_items": int(df["is_late"].sum()),
    }


def control_totals(df: pd.DataFrame) -> dict:
    realised = df[~df["order_status"].isin(NOT_REALISED)]
    return {
        "all_rows": {
            **_money(df),
            "customers": int(df["customer_id"].nunique()),
            "products": int(df["product_id"].nunique()),
            "order_date_min": str(df["order_date"].min()),
            "order_date_max": str(df["order_date"].max()),
        },
        "excl_canceled_and_fraud": _money(realised),
        "net_sales_by_market_all_rows": {
            m: round(float(v), 2) for m, v in df.groupby("market")["net_sales"].sum().sort_index().items()
        },
    }


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
