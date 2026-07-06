"""
adzuna_extract.py — Week 1: first real extraction

Unlike adzuna_extract_test.py (a one-off connectivity/structure check),
this script is meant to be run repeatedly to build up the raw dataset.

Strategy (per project roadmap): pull whole Adzuna categories — IT,
HR, legal, consultancy — rather than narrow niche terms directly
against the API (no `what` keyword filter at this stage). Keyword-based
filtering for relevance (AI mentions, governance terms, data roles,
etc.) happens later in src/transform/, never here.

Governance decision: each page of results is saved exactly as the API
returns it, untouched, into data/raw/. No merging, no deduplication, no
field selection — that belongs to the transform step, to keep lineage
clean and every raw response individually traceable.
"""

import os
import json
import time
from datetime import datetime, timezone

import requests
from dotenv import load_dotenv

load_dotenv()

app_id = os.getenv("ADZUNA_APP_ID")
app_key = os.getenv("ADZUNA_APP_KEY")

if not app_id or not app_key:
    raise ValueError(
        "Missing credentials. Check that a .env file exists in the repo "
        "root with ADZUNA_APP_ID and ADZUNA_APP_KEY defined."
    )

COUNTRY = "es"
RESULTS_PER_PAGE = 50  # Adzuna's maximum per call
MAX_PAGES_PER_CATEGORY = 5  # exploration cap for this first extraction, not a quota limit
REQUEST_DELAY_SECONDS = 1  # be polite to the API between calls

# Broad category searches (Adzuna's own taxonomy), per the roadmap's
# strategy: cast a wide net here, filter for niche relevance
# (governance, AI, data roles) in the transform step.
CATEGORIES = ["it-jobs", "hr-jobs", "legal-jobs", "consultancy-jobs"]

OUTPUT_DIR = "data/raw"


def fetch_page(category, page):
    url = f"https://api.adzuna.com/v1/api/jobs/{COUNTRY}/search/{page}"
    params = {
        "app_id": app_id,
        "app_key": app_key,
        "results_per_page": RESULTS_PER_PAGE,
        "category": category,
        "content-type": "application/json",
    }
    return requests.get(url, params=params)


def save_raw(data, category, page, run_timestamp):
    filename = f"adzuna_{category}_p{page}_{run_timestamp}.json"
    output_path = os.path.join(OUTPUT_DIR, filename)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    return output_path


def extract_category(category, run_timestamp):
    print(f"\n--- Category: '{category}' ---")
    page = 1
    total_saved = 0

    while page <= MAX_PAGES_PER_CATEGORY:
        response = fetch_page(category, page)

        if response.status_code != 200:
            print(f"  Page {page}: call failed (status {response.status_code}). Stopping this category.")
            print(f"  Server response: {response.text}")
            break

        data = response.json()
        results = data.get("results", [])
        total_count = data.get("count", "not available")

        if not results:
            print(f"  Page {page}: no more results. Stopping this category.")
            break

        output_path = save_raw(data, category, page, run_timestamp)
        total_saved += len(results)
        print(f"  Page {page}: {len(results)} results saved to {output_path} (total available: {total_count})")

        # Stop once we've paged past all available results for this category
        if page * RESULTS_PER_PAGE >= total_count:
            print(f"  Reached the end of available results for '{category}'.")
            break

        page += 1
        time.sleep(REQUEST_DELAY_SECONDS)

    return total_saved


if __name__ == "__main__":
    run_timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    print(f"Starting Adzuna extraction run ({COUNTRY}) — categories: {CATEGORIES}")

    grand_total = 0
    for category in CATEGORIES:
        grand_total += extract_category(category, run_timestamp)

    print(f"\nExtraction run complete. Total results saved: {grand_total}")
