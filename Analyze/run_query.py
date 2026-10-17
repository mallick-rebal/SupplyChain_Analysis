"""Run one analysis SQL file against the star schema and show the result.

Run from the repo root, after Model/build_model.py:
    python Analyze/run_query.py Analyze/sql/q01_late_by_market.sql
Add --csv to also save the result to Analyze/results/<name>.csv
"""
import sys
from pathlib import Path
import duckdb

if len(sys.argv) < 2:
    raise SystemExit("Usage: python Analyze/run_query.py <path to .sql file> [--csv]")

sql_file = Path(sys.argv[1])
con = duckdb.connect("Model/supplychain.duckdb", read_only=True)
df = con.sql(sql_file.read_text()).df()
con.close()

with __import__("pandas").option_context("display.max_rows", 50, "display.width", 200):
    print(df)

if "--csv" in sys.argv:
    out = Path("Analyze/results") / f"{sql_file.stem}.csv"
    out.parent.mkdir(exist_ok=True)
    df.to_csv(out, index=False)
    print(f"\nsaved {out}")
