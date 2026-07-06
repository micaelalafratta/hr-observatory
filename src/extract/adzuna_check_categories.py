"""
check_categories.py
Fetches the official Adzuna job categories for Spain and saves the raw
response. Run this once before building search calls, so that the
`category` parameter only ever uses tags that actually exist.

Governance rationale: the set of valid categories defines the inclusion
scope of the dataset. Saving the raw response with a date gives us a
lineage record of what the taxonomy looked like when we built the pipeline.
"""

import json
import os
from datetime import date
from pathlib import Path

import requests
from dotenv import load_dotenv

# Load credentials from .env (never hard-coded, never committed to Git)
load_dotenv()
APP_ID = os.getenv("ADZUNA_APP_ID")
APP_KEY = os.getenv("ADZUNA_APP_KEY")

# Adzuna categories endpoint for Spain (country code "es")
URL = "https://api.adzuna.com/v1/api/jobs/es/categories"

# Credentials go as query params, per Adzuna's API design
params = {"app_id": APP_ID, "app_key": APP_KEY}

response = requests.get(URL, params=params)
response.raise_for_status()  # fail loudly if credentials or URL are wrong
data = response.json()

# Save the raw response for lineage: we keep exactly what the API returned,
# untransformed, tagged with the extraction date.
raw_dir = Path("data/raw")
raw_dir.mkdir(parents=True, exist_ok=True)
outfile = raw_dir / f"adzuna_categories_{date.today().isoformat()}.json"
outfile.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")

# Print a readable summary: the tag is what we use in search calls,
# the label is the human-readable name.
print(f"Saved raw response to: {outfile}\n")
print(f"{'TAG':<25} LABEL")
print("-" * 50)
for cat in data.get("results", []):
    print(f"{cat['tag']:<25} {cat['label']}")