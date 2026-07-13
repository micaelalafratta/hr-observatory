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

## 2026-07-13 — First structural exploration of the full extraction (n=951)

- **Note on dating:** this event analyses the 2026-07-06 category
  extraction, but is dated 2026-07-13 — the date the exploration was
  actually run and committed to git. Lineage events are dated by when the
  work happened (and was pushed), not by the date of the underlying data,
  so the documentary record and the git history agree.

- **Script:** exploration notebook in `notebooks/`, using pure helper
  functions in `src/support/exploration_utils.py` (`get_nested`,
  `classify`, `parse_filename`). Read-only over `data/raw/`; no
  transformation, no schema, no writes to raw.
- **Action:** Measured field presence across all 20 raw files from the
  category extraction above, classifying every field per posting into
  present / null / empty / absent, both globally and per category.
- **Total volume confirmed:** 951 postings, verified directly (`id`
  present in 951/951 — the total is read from the data, not inferred).
- **Per-category distribution:**
  - `consultancy-jobs`: 250
  - `hr-jobs`: 250
  - `it-jobs`: 250
  - `legal-jobs`: 201
- **Coverage finding (category exhaustion):** three categories returned
  exactly 250 (= 5 pages × 50, the Phase 1 cap), meaning the cap — not
  the market — limited them; more postings were available and left
  uncollected by design. `legal-jobs` returned only 201, meaning it was
  *exhausted* before page 5: Adzuna had fewer than 250 postings for it
  at extraction time. So the 5-page cap is a self-imposed limit for
  three categories but the true available volume for `legal-jobs`. This
  distinction matters for any per-category comparison and is recorded
  rather than assumed.
- **Field-presence findings (n=951), replacing the earlier n=10 / n=50
  test figures:**
  - 100% present (951/951): `id`, `title`, `description`, `created`,
    `location.display_name`, `location.area`, `category.label`,
    `category.tag`, `salary_is_predicted`, `redirect_url`.
  - `company.display_name`: 860/951 (90.43%) — NOT always present, as
    the earlier tests had assumed. 91 postings carry no employer name.
  - `salary_min` / `salary_max`: 556/951 (58.46%) each, always paired
    (identical counts — Adzuna returns both or neither).
  - `latitude` / `longitude`: 790/951 (83.07%) each — substantially
    higher than the ~50% seen in the n=50 test.
  - `contract_time`: 27/951 (2.84%). `contract_type`: 0/951 (0.00%).
- **Structural finding (all gaps are `absent`, never `null`/`empty`):**
  across every field, missing data means Adzuna omits the key entirely,
  never returns it as null or empty. This has direct schema implications
  for Phase 2 (an omitted key is not the same as an explicit null) and
  is recorded here rather than assumed.
- **Correction to the salary-opacity figure:** the earlier ~2% salary
  presence was based on n=10 and n=50 exploratory samples — too small
  for inference. It is superseded by 58.46% salary presence on n=951.
  The ~2% is retained in this project's history as record, marked
  superseded; it should not be cited as a project finding.
- **Salary value nature — investigated within this exploration (short
  form; full reasoning in `data_quality.md`, Accuracy):** all 556
  salaried postings carry `salary_is_predicted = '0'`. Initial inspection
  suggested platform-derived ranges; the distribution supports this
  weakly (only ~62 distinct values, mostly round multiples of 10,000,
  heavily repeated — atypical of individually declared pay). However, two
  candidate confirmatory tests were considered and **rejected as
  non-discriminating**: (a) salary scaling with title seniority — the
  real market scales too, so it does not separate estimate from reality;
  (b) salary dispersion within a repeated exact title — identical titles
  can be genuinely different roles (e.g. 1 vs 5 years required), so
  dispersion proves nothing. Adzuna's docs confirm what a `1` means but
  not what a `0` means. **Final conclusion:** the exact nature of the
  salary value is *not determinable from Adzuna data alone*; it is
  documented as "58.46% carry a salary with the flag at 0, provenance
  undetermined," not as employer-stated salary. This note records the
  reasoning as it evolved during the exploration, including the rejected
  tests, per the project's traceability practice.
- **Downstream impact:** these real-volume figures are what the Week-2
  BigQuery schema design should use — salary columns sparse (~58%, of
  uncertain provenance), `contract_type` effectively empty,
  geocoordinates ~83%. `data_dictionary.md` and `data_quality.md` are
  updated to reference this event.
