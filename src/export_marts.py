"""Export the finished mart tables to CSV so a BI tool can read them.

Tableau Public (free, works on Mac) can't connect to DuckDB directly, so run
this after `dbt build` and point the dashboard at the files in /exports.
"""
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "marketing.duckdb"
OUT = ROOT / "exports"
TABLES = ["mart_client_monthly_performance", "mart_channel_scorecard", "dim_clients", "dim_campaigns"]


def main() -> None:
    OUT.mkdir(exist_ok=True)
    con = duckdb.connect(str(DB), read_only=True)
    for table in TABLES:
        target = OUT / f"{table}.csv"
        con.execute(f"COPY (SELECT * FROM {table}) TO '{target}' (HEADER, DELIMITER ',')")
        rows = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"exports/{target.name}: {rows:,} rows")
    con.close()


if __name__ == "__main__":
    main()
