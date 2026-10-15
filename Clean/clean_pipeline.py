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

PII_COLUMNS = [
    "Customer Email",
    "Customer Password",
    "Customer Fname",
    "Customer Lname",
    "Customer Street",
]

NO_VALUE_COLUMNS = [
    "Product Description",  # 100% null
    "Product Status",  # always 0
    "Product Image",  # URL
    "Order Zipcode",  # 86% null, US orders only
]

# dropped column -> identical column that is kept
DUPLICATE_COLUMNS = {
    "Benefit per order": "Order Profit Per Order",
    "Sales per customer": "Order Item Total",
    "Order Customer Id": "Customer Id",
    "Product Category Id": "Category Id",
    "Order Item Product Price": "Product Price",
    "Order Item Cardprod Id": "Product Card Id",
}

# raw name -> clean name, listed in output order
RENAME_MAP = {
    # keys
    "Order Item Id": "order_item_id",
    "Order Id": "order_id",
    "Customer Id": "customer_id",
    "Product Card Id": "product_id",
    "Category Id": "category_id",
    "Department Id": "department_id",
    # dates
    "order date (DateOrders)": "order_date",
    "shipping date (DateOrders)": "shipping_date",
    # order
    "Order Status": "order_status",
    "Type": "payment_type",
    "Customer Segment": "customer_segment",
    # shipping
    "Shipping Mode": "shipping_mode",
    "Days for shipping (real)": "days_shipping_real",
    "Days for shipment (scheduled)": "days_shipping_scheduled",
    "Delivery Status": "delivery_status",
    "Late_delivery_risk": "is_late",
    # product
    "Product Name": "product_name",
    "Product Price": "product_price",
    "Category Name": "category_name",
    "Department Name": "department_name",
    # money (all item-level)
    "Order Item Quantity": "quantity",
    "Sales": "sales",
    "Order Item Discount": "discount_amount",
    "Order Item Discount Rate": "discount_rate",
    "Order Item Total": "net_sales",
    "Order Profit Per Order": "profit",
    "Order Item Profit Ratio": "profit_ratio",
    # destination
    "Market": "market",
    "Order Region": "order_region",
    "Order Country": "order_country",
    "Order State": "order_state",
    "Order City": "order_city",
    # store / customer
    "Customer City": "customer_city",
    "Customer State": "customer_state",
    "Customer Zipcode": "customer_zipcode",
    "Customer Country": "customer_country",
    "Latitude": "store_latitude",
    "Longitude": "store_longitude",
}

DATE_FORMAT = "%m/%d/%Y %H:%M"


def load_raw() -> pd.DataFrame:
    df = pd.read_csv(RAW_FILE, encoding="latin-1")
    df.columns = df.columns.str.strip()
    return df


def drop_pii(df: pd.DataFrame) -> pd.DataFrame:
    """R01: email, password, first/last name, street."""
    return df.drop(columns=PII_COLUMNS)


def drop_unused_columns(df: pd.DataFrame) -> pd.DataFrame:
    """R02 empty / constant columns, R03 exact duplicate columns."""
    for dropped, kept in DUPLICATE_COLUMNS.items():
        assert df[dropped].equals(df[kept]), f"{dropped} is not identical to {kept}"
    return df.drop(columns=NO_VALUE_COLUMNS + list(DUPLICATE_COLUMNS))


def rename_columns(df: pd.DataFrame) -> pd.DataFrame:
    """R04: snake_case names in output order; is_late 0/1 -> bool."""
    missing = set(df.columns) ^ set(RENAME_MAP)
    assert not missing, f"unexpected / missing columns: {missing}"
    df = df[list(RENAME_MAP)].rename(columns=RENAME_MAP)
    df["is_late"] = df["is_late"].astype(bool)
    return df


def fix_formats(df: pd.DataFrame) -> pd.DataFrame:
    """R05 dates, R06 zipcode as 5-char text, R07 round money to 2 dp."""
    for col in ["order_date", "shipping_date"]:
        df[col] = pd.to_datetime(df[col], format=DATE_FORMAT)
    # TODO R06, R07 (after v0)
    return df


def standardise_text(df: pd.DataFrame) -> pd.DataFrame:
    """R08 trim / collapse spaces, R09 country names Spanish -> English."""
    text_cols = [c for c in df.columns if pd.api.types.is_string_dtype(df[c])]
    for col in text_cols:
        df[col] = df[col].str.strip().str.replace(r"\s{2,}", " ", regex=True)
    # TODO R09 (after v0)
    return df


def fix_known_errors(df: pd.DataFrame) -> pd.DataFrame:
    """R10 shifted address rows, R11 longitude sign, R12 duplicate category name."""
    return df


def add_flags(df: pd.DataFrame) -> pd.DataFrame:
    """R13 is_canceled, R14 is_suspected_fraud, R16 is_low_coverage_period."""
    return df


def add_derived_fields(df: pd.DataFrame) -> pd.DataFrame:
    """R15 shipping_delay_days."""
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
        .pipe(fix_formats)
        .pipe(standardise_text)
        .pipe(fix_known_errors)
        .pipe(add_flags)
        .pipe(add_derived_fields)
    )
    assert len(df) == raw_rows, "rows must never be dropped"
    save(df)
    print(f"Saved {len(df):,} rows x {df.shape[1]} cols -> {OUT_PARQUET.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
