"""Build the SupplyChainIQ star schema in DuckDB, reconcile it, and export it for Power BI.

Run from the repo root:
    python Model/build_model.py
"""
from pathlib import Path
import duckdb

ROOT = Path(__file__).resolve().parent.parent
SQL_DIR = ROOT / "Model" / "sql"
CHECKS = ROOT / "Model" / "checks" / "reconciliation.sql"
OUT_DIR = ROOT / "Model" / "output"
DB_PATH = ROOT / "Model" / "supplychain.duckdb"
TABLES = ["dim_date", "dim_shipping", "dim_product", "dim_customer",
          "dim_geography", "fact_order_items"]


def main() -> None:
    con = duckdb.connect(str(DB_PATH))
    con.execute(f"SET file_search_path = '{ROOT.as_posix()}'")

    # 1. Build: run 00_ ... 06_ in order
    for sql_file in sorted(SQL_DIR.glob("*.sql")):
        con.execute(sql_file.read_text())
        print(f"built  {sql_file.name}")

    # 2. Row counts
    print()
    for t in TABLES:
        n = con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
        print(f"{t:<18}{n:>10,}")

    # 3. Reconcile: stop if any check fails
    results = con.execute(CHECKS.read_text()).fetchall()
    failed = [r for r in results if r[3] != "PASS"]
    print(f"\nreconciliation: {len(results) - len(failed)}/{len(results)} checks pass")
    for name, got, expected, result in results:
        if result != "PASS":
            print(f"  FAIL  {name}: model={got} expected={expected}")
    if failed:
        raise SystemExit("Reconciliation failed: not exporting.")

    # 4. Export for Power BI
    OUT_DIR.mkdir(exist_ok=True)
    for t in TABLES:
        con.execute(f"COPY {t} TO '{(OUT_DIR / f'{t}.parquet').as_posix()}' (FORMAT PARQUET)")
    print(f"exported {len(TABLES)} tables to Model/output/")
    con.close()


if __name__ == "__main__":
    main()
