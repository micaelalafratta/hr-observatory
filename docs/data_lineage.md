# Data Lineage

> Origin, transformations, and cleaning decisions for each dataset in
> this project. Organized chronologically by pipeline event, not by
> field (see data_dictionary.md for field-level definitions).

## 2026-07-06 — Adzuna connection test (n=10)

- **Script:** `src/extract/adzuna_extract_test.py` (first version)
- **Action:** Made a test call to the Adzuna search endpoint (Spain,
  query "data", page 1, 10 results) to validate credentials and inspect
  the real response structure before building the full extractor.
- **Output:** Raw JSON saved to `data/raw/adzuna_test_20260706_095033.json`
- **Decision:** No transformation applied at this stage. This script
  only validates connectivity and structure — raw data is never edited
  by hand, per the extract/transform/load separation of this project.
- **Finding:** Confirmed 200 status code and successful authentication.
  Total available results for this query: 20,391 — confirms that the
  broad-category + keyword-filtering strategy (rather than searching a
  narrow niche term directly) is necessary, as planned in the roadmap.

## 2026-07-06 — Adzuna field consistency test (n=50)

- **Script:** `src/extract/adzuna_extract_test.py` (extended version —
  added comparison of field sets across all results, not just the
  first one)
- **Action:** Repeated the test call with `results_per_page=50` (the
  API's maximum per call) to check whether fields are consistently
  present across postings, or only appear in some.
- **Output:** Raw JSON saved to `data/raw/adzuna_test_20260706_100224.json`
- **Findings that shaped later decisions:**
  - 11 fields present in 100% of results: `id`, `title`, `company`,
    `category`, `location`, `created`, `redirect_url`, `adref`,
    `salary_is_predicted`, `description`, `__CLASS__`.
  - `latitude`/`longitude` present in only 25/50 (50%) — confirmed
    stable between the n=10 and n=50 samples.
  - `salary_min`/`salary_max` present in only 1/50 (2%) — consistent
    with 0/10 in the earlier sample, strengthening confidence in the
    salary opacity finding.
  - `contract_type`/`contract_time` (documented by Adzuna publicly) did
    not appear at all in either sample.
- **Downstream impact:**
  - This finding will directly affect the BigQuery schema design
    (Week 2): salary columns will need to be designed as sparse/nullable
    from the start, a decision to be discussed explicitly before
    implementing (per project's "no schema changes without discussion"
    principle).
  - See `data_quality.md` for the full write-up of these findings under
    Completeness and Accuracy.

## 2026-07-06 — Methodological review of the `description` field

- **Action:** No code run — a documentation-only decision point,
  triggered by manually reviewing the raw JSON and noticing that
  different companies structure job postings very differently (some
  open with company background, others with values statements, others
  with technical requirements).
- **Decision:** `description`-based keyword analysis (AI/governance
  mentions) will NOT be discarded, but will be split into two
  separately labeled metrics rather than reported as one:
  1. A primary, high-confidence metric based on `title`/`category` only.
  2. A secondary, explicitly exploratory metric based on the
     `description` snippet, always reported as a lower bound with the
     structural-variability caveat attached.
- **Rationale:** the project's other Phase 1 analyses (salary opacity,
  top companies, geographic distribution) rely entirely on structured
  fields and are unaffected by this limitation — the observatory does
  not depend on the `description` field being reliable.
- **Full reasoning documented in:** `data_quality.md`, under
  "Reliability of text-based analysis."
