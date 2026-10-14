"""Raw DataCo order items -> one flat cleaned table.

Run from the repo root:
    python Clean/clean_pipeline.py

Every rule here must have a matching entry (R01, R02, ...) in Clean/cleaning_rules.md.
Rows are never deleted: canceled / suspected-fraud orders are flagged instead.
"""

from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW_FILE = ROOT / "Data" / "Raw" / "DataCoSupplyChainDataset.csv"
CLEAN_DIR = ROOT / "Data" / "Cleaned"
OUT_PARQUET = CLEAN_DIR / "order_items_clean.parquet"
OUT_CSV = CLEAN_DIR / "order_items_clean.csv"


def load_raw() -> pd.DataFrame:
    return pd.read_csv(RAW_FILE, encoding="latin-1")


def drop_pii(df: pd.DataFrame) -> pd.DataFrame:
    """R01"""
    return df


def drop_unused_columns(df: pd.DataFrame) -> pd.DataFrame:
    """R02 + R03: empty and redundant columns."""
    return df


def rename_columns(df: pd.DataFrame) -> pd.DataFrame:
    """R04"""
    return df


def parse_dates(df: pd.DataFrame) -> pd.DataFrame:
    """R05"""
    return df


def standardise_text(df: pd.DataFrame) -> pd.DataFrame:
    """R06"""
    return df


def add_flags(df: pd.DataFrame) -> pd.DataFrame:
    """R07: is_canceled, is_suspected_fraud."""
    return df


def add_derived_fields(df: pd.DataFrame) -> pd.DataFrame:
    """R08"""
    return df


def save(df: pd.DataFrame) -> None:
    CLEAN_DIR.mkdir(parents=True, exist_ok=True)
    df.to_parquet(OUT_PARQUET, index=False)
    df.to_csv(OUT_CSV, index=False)


def main() -> None:
    df = load_raw()
    raw_rows = len(df)
    df = (
        df.pipe(drop_pii)
        .pipe(drop_unused_columns)
        .pipe(rename_columns)
        .pipe(parse_dates)
        .pipe(standardise_text)
        .pipe(add_flags)
        .pipe(add_derived_fields)
    )
    assert len(df) == raw_rows, "rows must never be dropped"
    save(df)
    print(f"Saved {len(df):,} rows x {df.shape[1]} cols -> {OUT_PARQUET.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
