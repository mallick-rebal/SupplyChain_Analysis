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
MONEY_COLUMNS = ["product_price", "sales", "discount_amount", "discount_rate", "net_sales", "profit", "profit_ratio"]
COUNTRY_MAP_FILE = ROOT / "Clean" / "mappings" / "country_es_en.csv"
# from Oct 2017 the data only covers 2 markets and 31 products (see 01_profiling.ipynb §7)
LOW_COVERAGE_START = "2017-10-01"


def load_raw() -> pd.DataFrame:
    df = pd.read_csv(RAW_FILE, encoding="latin-1")
    df.columns = df.columns.str.strip()
    return df


def fix_shifted_addresses(df: pd.DataFrame) -> pd.DataFrame:
    """R10: 3 rows where the address slid one column right (city = "CA", state = a zipcode).

    Runs first because it needs Customer Street, which R01 drops.
    """
    shifted = df["Customer State"].str.fullmatch(r"\d{5}")
    df.loc[shifted, "Customer Zipcode"] = df.loc[shifted, "Customer State"].astype(float)
    df.loc[shifted, "Customer State"] = df.loc[shifted, "Customer City"]
    df.loc[shifted, "Customer City"] = df.loc[shifted, "Customer Street"]
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
    df["customer_zipcode"] = df["customer_zipcode"].astype("Int64").astype("string").str.zfill(5)
    for col in MONEY_COLUMNS:
        df[col] = df[col].round(2)
    return df


def standardise_text(df: pd.DataFrame) -> pd.DataFrame:
    """R08 trim / collapse spaces, R09 country names Spanish -> English."""
    text_cols = [c for c in df.columns if pd.api.types.is_string_dtype(df[c])]
    for col in text_cols:
        df[col] = df[col].str.strip().str.replace(r"\s{2,}", " ", regex=True)
    countries = pd.read_csv(COUNTRY_MAP_FILE).set_index("country_es")["country_en"]
    for col in ["order_country", "customer_country"]:
        unmapped = set(df[col]) - set(countries.index)
        assert not unmapped, f"{col} has countries missing from {COUNTRY_MAP_FILE.name}: {unmapped}"
        df[col] = df[col].map(countries)
    return df


def fix_known_errors(df: pd.DataFrame) -> pd.DataFrame:
    """R11 longitude sign, R12 duplicate category name. (R10 runs first, see fix_shifted_addresses.)"""
    # all stores are in the US / Puerto Rico, so longitude must be negative
    df["store_longitude"] = -df["store_longitude"].abs()
    # "Electronics" is used by two category ids in different departments
    ids_per_name = df.groupby("category_name")["category_id"].transform("nunique")
    dup = ids_per_name > 1
    df.loc[dup, "category_name"] = df.loc[dup, "category_name"] + " (" + df.loc[dup, "department_name"] + ")"
    return df


def add_flags(df: pd.DataFrame) -> pd.DataFrame:
    """R13 is_canceled, R14 is_suspected_fraud, R16 is_low_coverage_period."""
    df["is_canceled"] = df["order_status"] == "CANCELED"
    df["is_suspected_fraud"] = df["order_status"] == "SUSPECTED_FRAUD"
    df["is_low_coverage_period"] = df["order_date"] >= LOW_COVERAGE_START
    return df


def add_derived_fields(df: pd.DataFrame) -> pd.DataFrame:
    """R15 shipping_delay_days (positive = late), placed next to the shipping days."""
    delay = df["days_shipping_real"] - df["days_shipping_scheduled"]
    df.insert(df.columns.get_loc("days_shipping_scheduled") + 1, "shipping_delay_days", delay)
    return df


def save(df: pd.DataFrame) -> None:
    CLEAN_DIR.mkdir(parents=True, exist_ok=True)
    df.to_parquet(OUT_PARQUET, index=False)
    df.to_csv(OUT_CSV, index=False)


def clean(raw: pd.DataFrame) -> pd.DataFrame:
    """Apply every rule in order. Used by main() and by the notebooks."""
    df = (
        raw.copy()
        .pipe(fix_shifted_addresses)
        .pipe(drop_pii)
        .pipe(drop_unused_columns)
        .pipe(rename_columns)
        .pipe(fix_formats)
        .pipe(standardise_text)
        .pipe(fix_known_errors)
        .pipe(add_flags)
        .pipe(add_derived_fields)
    )
    assert len(df) == len(raw), "rows must never be dropped"
    return df


def main() -> None:
    df = clean(load_raw())
    save(df)
    print(f"Saved {len(df):,} rows x {df.shape[1]} cols -> {OUT_PARQUET.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
