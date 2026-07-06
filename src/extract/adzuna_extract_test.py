"""
adzuna_extract_test.py — Week 1: connection test + field consistency check

Purpose of this script:
This is NOT the final extractor. It's a controlled test to:
  1. Confirm that the credentials in .env actually work
  2. See the REAL structure of an Adzuna response
     (official docs and real responses sometimes differ)
  3. Check whether ALL results in the page share the same fields,
     or whether some fields (like salary) only appear on some postings
  4. Save that raw response into data/raw/ as the first piece
     of lineage evidence

Governance decision: we save the raw JSON exactly as it arrives,
untouched. Any transformation happens in src/transform/, never here.
This keeps the lineage clean from day 1.
"""

import os
import json
from datetime import datetime, timezone

import requests
from dotenv import load_dotenv

# Loads the variables from the .env file into the system's environment variables
load_dotenv()

app_id = os.getenv("ADZUNA_APP_ID")
app_key = os.getenv("ADZUNA_APP_KEY")

# Explicit check: if a credential is missing, the script stops here
# with a clear message instead of failing later with a cryptic
# API error (a bare 401 with no context).
if not app_id or not app_key:
    raise ValueError(
        "Missing credentials. Check that a .env file exists in the repo "
        "root with ADZUNA_APP_ID and ADZUNA_APP_KEY defined."
    )

# Parameters for the test call.
# Country "es" = Spain. Page 1. Broad search ("data") for now —
# the category + keyword strategy will be refined in the final script.
country = "es"
page = 1
url = f"https://api.adzuna.com/v1/api/jobs/{country}/search/{page}"

params = {
    "app_id": app_id,
    "app_key": app_key,
    "results_per_page": 50,   # small number to avoid burning quota on a test first. 10 attempted, need to broaden results to 50. 
    "what": "data",           # broad test query
    "content-type": "application/json",
}

print(f"Making a test call to Adzuna ({country})...")
response = requests.get(url, params=params)

# We don't assume success: check the status code explicitly.
print(f"Status code: {response.status_code}")

if response.status_code != 200:
    print("The call failed. Server response:")
    print(response.text)
else:
    data = response.json()
    results = data.get("results", [])

    print(f"Total results available: {data.get('count', 'not available')}")
    print(f"Results received on this page: {len(results)}")

    # --- Field consistency check across ALL results in this page ---
    # Instead of only looking at the first result, we collect the field
    # names from every result and compare them. This tells us which
    # fields are ALWAYS present vs. which ones only show up sometimes
    # (salary being the one we most suspect, given the project's
    # salary opacity hypothesis).
    all_field_sets = [set(result.keys()) for result in results]

    # Fields present in every single result (the intersection of all sets)
    fields_always_present = set.intersection(*all_field_sets) if all_field_sets else set()

    # Fields present in at least one result but not all (the union minus the intersection)
    fields_sometimes_present = set.union(*all_field_sets) - fields_always_present if all_field_sets else set()

    print("\nFields present in ALL results on this page:")
    for field in sorted(fields_always_present):
        print(f"  - {field}")

    print("\nFields present in SOME results only (inconsistent across postings):")
    if fields_sometimes_present:
        for field in sorted(fields_sometimes_present):
            # Count in how many of the 10 results this field actually appears
            count = sum(1 for field_set in all_field_sets if field in field_set)
            print(f"  - {field} (present in {count}/{len(results)} results)")
    else:
        print("  (none — every result had exactly the same fields)")

    # Save the full raw JSON into data/raw/, with a timestamp in the filename
    # so we don't overwrite previous tests while exploring.
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    output_path = f"data/raw/adzuna_test_{timestamp}.json"

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\nRaw response saved to: {output_path}")
