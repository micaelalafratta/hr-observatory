# Data Lineage

> Origin, transformations, and cleaning decisions for each dataset in
> this project. Organized chronologically by pipeline event, not by
> field (see data_dictionary.md for field-level definitions).

**Reference data note:** `adzuna_categories_{date}.json` is a one-off
reference download of Adzuna's category catalogue for Spain. It is not
job-posting data; it serves as evidence of the inclusion criteria (the
four chosen categories) and is excluded from the transform step. It
lives in `data/raw/reference/`, physically separated from job postings.

**Raw data organisation (`data/raw/`):**
- `data/raw/*.json` — extracted job postings (transform input)
- `data/raw/reference/` — reference data (Adzuna category catalogue);
  evidence of inclusion criteria, excluded from the transform
- `data/raw/discarded/` — early exploratory test extractions, kept for
  process transparency, not part of the active pipeline

**Raw file naming convention:**
`adzuna_{category}_p{page}_{YYYYMMDD}_{HHMMSS}.json`

Each raw file is self-describing: source, category, page, and extraction
timestamp (date + time). A timestamp to the second means re-running an
extraction on the same day never overwrites a previous run — every run
is preserved. The category in the filename gives origin traceability
without opening the file.

## 2026-07-06 — Adzuna connection test (n=10)

- **Script:** `src/extract/adzuna_extract_test.py` (first version)
- **Action:** Made a test call to the Adzuna search endpoint (Spain,
  query "data", page 1, 10 results) to validate credentials and inspect
  the real response structure before building the full extractor.
- **Output:** Raw JSON saved to `data/raw/adzuna_test_20260706_095033.json`
  (later moved to `data/raw/discarded/` once the category-based extractor
  replaced these exploratory tests).
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
  (later moved to `data/raw/discarded/`, as above).
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

## 2026-07-06 — Extraction method change: keyword search → category search

- **Action:** No new data kept — a method decision that supersedes the
  exploratory tests above.
- **Earlier (discarded) approach:** the first exploratory extractions
  used free-text keyword search (`what = "data" / "tecnologia" / "rrhh"`).
  This made the search universe depend on individual word choice, which
  hurt reproducibility and language coverage (a `what` search for "data"
  misses postings that say "datos"; "rrhh" misses "recursos humanos").
- **Current approach:** category-based search over four Adzuna category
  tags (`it-jobs`, `hr-jobs`, `legal-jobs`, `consultancy-jobs`). The
  category defines *where* postings come from (a stable, documentable
  universe); bilingual keyword filtering in the transform step defines
  *what is kept*. This matches the roadmap's wide-net-then-filter
  strategy and is documented as the inclusion criterion in
  `data_dictionary.md`.
- **Note on discarded extraction:** the raw files from the free-text
  `what` extraction were deleted from `data/raw/`. The files are gone;
  this decision and its rationale are retained here as the lineage
  record. (Raw data is disposable; the reasoning is not.)

## 2026-07-06 — First full extraction by category (4 categories × 5 pages)

- **Script:** `src/extract/` extractor (category-based version)
- **Action:** Ran the first real extraction across the four in-scope
  categories, capped at 5 pages per category (`max_pages_per_query = 5`),
  50 results per page (`results_per_page = 50`, the Adzuna maximum),
  with a 1-second delay between calls (`request_delay = 1s`) as
  rate-limit courtesy. Country: `es`.
- **Output:** 20 raw JSON files in `data/raw/`, one per category-page:
  `adzuna_{it-jobs|hr-jobs|legal-jobs|consultancy-jobs}_p{1..5}_20260706_152032.json`
- **Integrity check:** file count verified per category after
  extraction — 5 pages × 4 categories = 20 files, all present. This
  guards against silent data loss during file operations (see
  `data_quality.md`, "Completeness — extraction integrity").
- **Decision:** no transformation applied at this stage; raw data saved
  untouched, per the extract/transform/load separation.
- **Next step:** exploration of the extracted volume (total postings,
  salary presence at real scale, `description` snippet behaviour) before
  designing the BigQuery schema in Week 2.
- **Caveat carried forward:** `max_pages_per_query = 5` is a Phase 1
  exploration cap, not a claim of complete market coverage. The true
  number of available postings per category is far higher (see the
  n=10 connection test: ~20k results for a single query). Full-coverage
  extraction is a Phase 2 concern, to be discussed before changing.
