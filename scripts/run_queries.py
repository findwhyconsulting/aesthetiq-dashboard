#!/usr/bin/env python3
"""Run all BigQuery queries and save results as JSON files in data/."""

import json
import sys
from pathlib import Path
from google.cloud import bigquery

PROJECT_ID = "aesthetiq-490506"

QUERIES = [
    ("sql/platform_kpis.sql",         "data/kpis.json"),
    ("sql/chart_areas.sql",           "data/chart_areas.json"),
    ("sql/chart_combos.sql",          "data/chart_combos.json"),
    ("sql/chart_protocols.sql",       "data/chart_protocols.json"),
    ("sql/chart_demographics.sql",    "data/chart_age.json"),
    ("sql/chart_cross.sql",           "data/chart_cross.json"),
    ("sql/chart_trend.sql",           "data/chart_trend.json"),
    ("sql/chart_clinics.sql",         "data/chart_clinics.json"),
    ("sql/chart_clinic_trend.sql",    "data/chart_clinic_trend.json"),
    ("sql/chart_clinic_protocols.sql","data/chart_clinic_protocols.json"),
    ("sql/chart_clinic_age.sql",      "data/chart_clinic_age.json"),
    ("sql/chart_clinic_areas.sql",    "data/chart_clinic_areas.json"),
]


def serialize(val):
    """Convert non-JSON-serializable types (dates, datetimes) to strings."""
    if hasattr(val, "isoformat"):
        return val.isoformat()
    return val


errors = []

for sql_file, output_file in QUERIES:
    print(f"\n>>> Running {sql_file}")
    try:
        query = Path(sql_file).read_text()
        client = bigquery.Client(project=PROJECT_ID)
        rows = list(client.query(query).result())
        data = [{k: serialize(v) for k, v in dict(row).items()} for row in rows]
        Path(output_file).write_text(json.dumps(data))
        print(f"    OK  -> {output_file}  ({len(data)} rows)")
    except Exception as e:
        print(f"    FAILED: {e}", file=sys.stderr)
        errors.append((sql_file, str(e)))

if errors:
    print("\n=== FAILED QUERIES ===", file=sys.stderr)
    for sql_file, err in errors:
        print(f"  {sql_file}: {err}", file=sys.stderr)
    sys.exit(1)

print("\nAll queries completed successfully.")
