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
  functions in `src/support/parsing_utils.py` (`get_nested`,
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

## 2026-08-04 — Extended EDA: salary bounds, duplicate confirmation, consistency, and temporal distribution

- **Script:** `notebooks/1_EDA.ipynb`, extended cells following the
  2026-07-13 exploration. Read-only over the same n=951 DataFrame; no
  transformation, no writes to raw.
- **Action:** Closed gaps left open by the first exploration — the low
  end of the salary range had been investigated but not the high end,
  `salary_min > salary_max` had never been checked directly, the 4
  duplicate ids found on 2026-07-13 had not been verified row-by-row,
  the `company` variant issue flagged as "pending" in `data_quality.md`
  had not been measured, `location_name` granularity was unexamined, and
  `created` had only a min/max range with no distribution.
- **Salary unit inconsistency (low end), resolved:** 11/556 salaried
  postings (2.0%) carry `salary_min` under 12,000 — implausible as an
  annual figure. A Spanish-locale decimal-parsing hypothesis
  ("28.000 €" misread as "28.0") was tested and rejected: all 11 values
  are integers, and multiplying by 1,000 does not land most of them back
  inside the observed normal range. The min/max ratio for these postings
  (mostly 1.04–1.36, e.g. 360–480, 30–35) instead matches an hourly-rate
  pattern, confirmed by manually opening 3 of the 11 `redirect_url`
  links in a browser. **Conclusion:** these postings store an hourly (or
  otherwise sub-annual) rate in the same field as annual salaries, with
  no unit flag to distinguish them. Applying Spain's minimum annual wage
  (17,094 €) as an exclusion threshold affects 12/556 postings (2.2%)
  and shifts mean `salary_min` from 71,096 to 72,601 — a quantified,
  non-negligible bias if the low cluster is left uncorrected. Full
  reasoning in `data_quality.md`, Accuracy — "Salary unit inconsistency."
- **Salary unit inconsistency (high end), unresolved:** the same
  gap/ratio method was applied to the top of the range. `salary_min`
  203,112 and 187,200 sit above a clean gap before the next cluster
  (120,000, repeated many times); `salary_max` reaches 395,200. No
  unit-parsing or rate-type defect was confirmed for these two —
  candidates for the same manual `redirect_url` check applied at the low
  end, not yet done.
- **Range validity confirmed:** `salary_min > salary_max` checked
  directly across all 951 postings — 0 violations. The paired salary
  fields are internally consistent wherever both are present.
- **Duplicate posting ids confirmed as pagination overlap:** the 4
  duplicate ids found on 2026-07-13 (all within `it-jobs`) were compared
  field-by-field. All 4 are identical across every column except
  `source_page` — the same posting reappearing on a later page, not an
  id collision between distinct postings. **Decision:** dedupe by `id`
  in the transform step, keeping the first occurrence.
- **Company name variants measured:** `company` normalized
  (lowercase, punctuation/whitespace stripped) and grouped — 6
  normalized keys resolve to more than one raw spelling: `dLocal`/
  `Dlocal`, `domestiko.com`/`Domestiko.com`, `Erm`/`ERM`, `Expert
  Executive Recruiters`/`Expert Executive Recruiters ` (trailing space),
  `Neoris`/`NEORIS`, `thexpeople`/`Thexpeople`. This resolves the
  "Pending" Consistency item left open in `data_quality.md` on
  2026-07-13. **Decision:** normalize `company` (case-fold + trim)
  before any grouping/aggregation in the transform step; raw value
  stays untouched at extraction.
- **Location granularity measured:** 307/951 postings (32.28%) carry
  `location_name` with no comma — a country- or region-level string
  only, not "City, Region". 136 of those are the bare string "España".
  Any city-level aggregation (e.g. "top cities") must filter or flag
  these first, or it will silently count country-level postings as a
  city. Madrid + Barcelona account for 42.1% of all `location_name`
  values once counted correctly.
- **Posting-age distribution measured (Timeliness):** 161/951 postings
  (16.93%) are more than 90 days older than the latest `created` date in
  the extraction (2026-07-06). Volume is heavily concentrated in the
  weeks immediately preceding extraction, with a long thin tail back to
  2024-03-08. A "current market snapshot" framing should account for
  this tail rather than assume every posting reflects live demand at
  extraction time.
- **`legal-jobs` exhaustion confirmed at page level:** page-by-page
  breakdown shows `consultancy-jobs`, `hr-jobs`, `it-jobs` at exactly
  50/50 postings on every page p1–p5; `legal-jobs` at 50/50 through p4
  and only 1/50 on p5. This is page-level evidence for the exhaustion
  conclusion already reached on 2026-07-13 (legal-jobs ran out of
  postings before the 5-page cap, rather than the extraction being
  truncated).
- **Downstream impact:** `data_dictionary.md` (`company`, `location`,
  `salary_min`/`salary_max`, `id`, `created`) and `data_quality.md`
  (Consistency, Timeliness, Accuracy, Completeness) updated to reference
  this event. Transform-step decisions now pending implementation:
  dedupe by `id`, normalize `company`, and flag/exclude the 11 sub-12,000
  `salary_min` values (or split into a separate hourly-rate field) before
  any salary-level analysis.

## 2026-08-04 — UTC timezone consistency check

- **Action:** No code run — a verification pass over the extraction
  script and the `created` field, prompted by the need to confirm
  timezone consistency before the Week-2 BigQuery schema design.
- **Verified:**
  1. The raw filename timestamp is generated with
     `datetime.now(timezone.utc)` in `src/extract/adzuna_extract.py`
     (~line 108), format
     `adzuna_{category}_p{page}_{YYYYMMDD}_{HHMMSS}.json`. This is UTC,
     not Europe/Madrid local time (which runs 1-2 hours ahead of UTC
     depending on daylight saving).
  2. The `created` field returned by Adzuna is ISO 8601 with a `Z`
     suffix — also UTC. Parsed in the notebook with
     `pd.to_datetime(..., utc=True)`.
- **Conclusion:** every timestamp in this project — extraction-run time
  and posting-publication time alike — is UTC, consistently. There is
  no timezone mixing between the two, and no conversion is needed
  anywhere in the current pipeline.
- **Why this matters:** extraction time and publication time are
  compared directly in several places (e.g. the posting-age analysis
  above). If one were UTC and the other Europe/Madrid local time, that
  comparison would be silently off by 1-2 hours — small enough to miss
  in a spot check, large enough to corrupt a "posting age" metric.
  Confirming both are UTC before the BigQuery schema is designed rules
  this out permanently, rather than leaving it as an implicit
  assumption.
- **No code changed:** `src/extract/adzuna_extract.py` is correct as
  written; this entry documents the verification, not a fix.
- **Extraction run timestamp confirmed:** 2026-07-06 15:20:32 UTC —
  matches the `_152032` suffix already recorded in the raw filenames
  (see "First full extraction by category" above). See
  `data_quality.md`, Timeliness, for why a single extraction run limits
  this project to measuring prevalence, not evolution, over time.

## 2026-08-04 — BigQuery raw layer: schema design, load, and first SQL analyses

- **Artefacts:** `sql/schema/create_adzuna_postings_raw.sql`,
  `src/load/bigquery_load.py`, `sql/analysis/00`–`06`.
- **Action:** Designed and created the BigQuery raw table, loaded the full
  extraction unfiltered, and ran the Phase 1 analyses in SQL. Two planned
  analyses were dropped after measurement showed the source could not
  support them.

### Layer architecture decision

One table per source, one dataset per layer. The Adzuna schema depends only
on the Adzuna extraction and required no knowledge of the EPA or ILO
sources: those enter as separate tables in Phase 2, and cross-source
reconciliation (the CNO-2011 / ISCO-08 / Adzuna crosswalk) belongs in a
later `marts` layer, not in `raw`. Deforming the raw schema to anticipate
future sources would break traceability to origin, which is the raw layer's
only job.

Dataset location is set to `EU` and is immutable after creation — a
deliberate choice for a project analysing Spanish labour-market data under
a GDPR framing.

### Schema decisions

Recorded because they are reversible only by migration.

- **`id` typed STRING, not INT64.** An external identifier is not a
  quantity. It is also the only `NOT NULL` column: the raw layer must
  accept whatever the source delivers, and declaring any other column
  mandatory would make a future load fail on a legitimately absent value.
- **`salary_is_predicted` typed STRING, not BOOL.** Preserves the literal
  `'0'` the source returns. Casting to boolean at the raw layer would be an
  interpretation, and the field's meaning is precisely what is disputed.
- **`contract_type` retained despite being 0% populated.** A structurally
  empty column documented as such is a completeness finding; an omitted
  column is lost information. Retaining it also means a future extraction
  that begins populating the field needs no schema migration.
- **`extracted_at` added — not a source field.** Provenance: this project.
  Set to the single extraction-run timestamp 2026-07-06 15:20:32 UTC for
  all rows, because it describes the run, not the individual file. Without
  it the dataset supports prevalence analysis only and could never support
  analysis of change over time.
- **No partitioning, no clustering.** At 951 rows partition pruning saves
  nothing; an unjustified partitioning scheme would be decoration rather
  than design. Recorded as a decision rather than an omission, revisitable
  if volume grows.

### Column descriptions embedded in the DDL

Every column carries an `OPTIONS(description="...")` clause recording its
measured presence, its known defects, and any exclusion threshold that
applies to it. Consequence: the data dictionary and the table schema are the
same object and cannot diverge. `data_dictionary.md` becomes a projection of
the live schema, generated from `INFORMATION_SCHEMA.COLUMN_FIELD_PATHS`,
rather than a parallel document maintained by hand.

### Load decision: unfiltered

All 951 rows loaded as delivered — duplicates, provider test records, mixed
salary periodicities and heterogeneous location granularity included. No
deduplication, no unit correction, no name normalisation at load.

Rationale: every quality defect documented in `data_quality.md` must remain
verifiable with SQL against the loaded table. Filtering at load would
convert those findings from demonstrable evidence into unsupported
assertions. The transform-step decisions recorded on 2026-07-13 and earlier
today — dedupe by `id`, normalise `company`, exclude sub-minimum-wage
salaries, exclude provider test records — apply downstream, not here.

`WRITE_EMPTY` is used as the write disposition so an accidental second run
fails loudly rather than silently doubling every count and invalidating
every field-presence percentage already documented.

**Load verification:** all figures reconciled against the pandas profiling —
951 rows, 947 distinct ids, 556 with salary, 91 without company, 790 with
coordinates, 0 with `contract_type`, 27 with `contract_time`, `created`
spanning 2024-03-08 to 2026-07-06. No discrepancies.

### Description truncation quantified — supersedes the 2026-07-06 decision

The 2026-07-06 methodological review decided to keep `description`-based
keyword analysis as an explicitly labelled secondary metric rather than
discard it. Direct measurement today supersedes that decision.

`description` is truncated at a **hard 500-character ceiling**: 814 of 951
records (85.6%) sit at exactly 500 characters; mean 485, minimum 142,
maximum 500 with no exceptions. Only 137 records carry their full text.

500 characters is roughly an opening paragraph. Technical requirements,
certifications and regulatory references appear later in a real posting — in
the portion that does not survive. A keyword search over this field measures
whether a term is prominent enough to appear in the lead text, not whether
the role requires it.

The truncation is also non-random in the direction that matters: longer,
more detailed postings — typically larger employers with more regulatory
obligations — lose proportionally more text. Any prevalence figure would be
a floor biased against precisely the terms the project set out to measure.
The structural-variability problem identified on 2026-07-06 still applies
and compounds it.

**Decision:** the planned analysis of AI Act, GDPR, data governance, DPO and
data steward term prevalence is dropped for Phase 1. The two-tier metric
approach recorded on 2026-07-06 is superseded: the secondary tier has no
usable corpus. The finding is reframed — the source does not permit
measuring technical requirements from posting text, and that limitation is
the result.

**Phase 3 impact:** the planned language-bias analysis over posting
descriptions is not viable from this endpoint either. It would require a
different source, or scraping via `redirect_url` with its own legal and
ethical assessment under this project's own FRIA layer. Not a Phase 1
concern; recorded so it is not rediscovered later.

### Employer ranking dropped

`05_company_concentration` was planned as a "top companies hiring" analysis.
Measurement shows it cannot be built from this source:

- 468 distinct normalised company names across 860 named postings
  (confirming the 6 spelling variants collapse as expected from 474).
- The two highest-volume names account for 15.9% of named postings and are
  a recruitment agency and an aggregator, not employers.
- The top 10 account for 25.1% — only 9.2 points more than the top 2, so
  concentration is almost entirely intermediary-driven.
- 344 of 468 companies (73.5%) publish a single posting.
- 91 postings (9.6%) carry no employer name at all.

Excluding intermediaries, no employer concentration is visible: ranks 3 to
20 span 14 to 4 postings, which does not distinguish signal from noise.

**Decision:** no employer ranking is published. The finding is the market
structure — a long tail of single-posting employers, with the visible top
occupied by intermediation rather than demand. Separating agencies from
employers requires editorial classification, not SQL: the source provides no
field for it. That classification is deferred to Phase 2 if the ranking is
ever needed.

### Geographic granularity refined

The earlier 2026-08-04 EDA recorded 307 postings (32.28%) without a comma.
SQL classification splits that figure into two materially different cases:

| Granularity             | Postings | %    |
|-------------------------|----------|------|
| City and region         | 644      | 67.7 |
| City or region only     | 171      | 18.0 |
| Country only ("España") | 136      | 14.3 |
| Missing                 | 0        | 0.0  |

The 171 comma-less values are largely identifiable cities written without
their region ("Madrid", "Barcelona"), not unusable data. Only the 136
country-level records carry no geographic signal.

**Decision:** city-level analysis uses the 815 locatable records, treating
comma-less city names as equivalent to their comma-separated form. The 136
country-level records are excluded.

**Reconciliation of two figures:** the 42.1% recorded earlier for Madrid +
Barcelona was computed over all 951 `location_name` values. Over the 815
locatable records the same cities account for **49.0%** (Madrid 262, 32.1%;
Barcelona 138, 16.9%). Both are arithmetically correct. The published figure
is 49.0% of locatable postings, because including country-level records in
the denominator understates concentration among postings that actually name
a place. The 42.1% is superseded for publication and retained as record.

**Long-tail caution:** Santa Cruz de Tenerife ranks fifth (12 postings), but
6 of those 12 come from a single company (Atlantis). Cities below the top
two are sensitive to individual hiring campaigns and should not be read as
market signal. Verified before publication rather than after.

### Salary framing correction

The analysis was initially written as "salary disclosure" with a
`pct_disclosing` column. This contradicted the conclusion already documented
in `data_quality.md`, Accuracy: salary provenance is not determinable from
Adzuna data alone, so a populated field cannot be attributed to employer
disclosure.

**Correction applied:** the query is renamed `03_salary_field_presence.sql`
and the metric renamed `pct_with_salary_value`. What is measured is whether
the field carries a value, not whether an employer chose to publish pay.

| Category         | Postings | With value | %    | Median (≥ SMI) |
|------------------|----------|------------|------|----------------|
| consultancy-jobs | 250      | 176        | 70.4 | 70,000         |
| legal-jobs       | 201      | 141        | 70.1 | 100,000        |
| it-jobs          | 250      | 131        | 52.4 | 60,000         |
| hr-jobs          | 250      | 108        | 43.2 | 50,000         |

**Pattern observed:** presence rate and salary level rank in the same order
across all four categories, a 27-point spread between consultancy and HR.

**Interpretation not determinable:** the pattern is equally consistent with
employer behaviour (lower-paying roles publish pay less often) and with
source behaviour (Adzuna salary coverage is better in higher-paying
segments). Four categories are a pattern, not a correlation. The pattern is
publishable; a causal reading of it is not.

**Selection caveat corrected:** an earlier draft stated that real gaps are
likely wider than measured. That holds only if the absence is employer-driven.
If it is source-driven it does not hold. The direction of the bias cannot be
established from this source, and the caveat is written accordingly.

### Salary threshold robustness

No observed `salary_min` value falls between the 2025 minimum wage (16,576 €)
and the 2026 figure (17,094 €, RD 126/2026) — the next value above 16,200 is
18,000. The exclusion count is therefore insensitive to which year's figure
is used, so the threshold does not depend on having picked the exact
statutory value. Recorded because a threshold that survives its own
sensitivity check is a stronger claim than one that merely sounds
authoritative.

### Provider test records found in production data

Two postings are Adzuna test records that reached the production response:
"Contract Dummy Job" and "Job for testing", both with salary 360–480. These
are not vacancies. They fall among the 12 records excluded by the
minimum-wage threshold, so they do not affect salary aggregates, but they are
counted in every volume figure. Recorded as a Validity finding; exclusion by
title pattern is a transform-step decision.

### Non-company values in the `company` field

`Madrid` appears as a company name in 5 postings. The field is not
type-constrained by the source and contains at least one city name. Recorded
as a Validity finding, distinct from the case and whitespace variants already
recorded under Consistency: those are the same entity written differently,
this is not an entity at all.

### French-language postings — universe confirmed correct

37 postings (3.9%) carry French-language title patterns (`F/H`, `H/F`,
`en stage`, `chargé`). All are located in Spain. These are French-owned
employers — DriiveMe, Children Worldwide Fashion España SLU — publishing in
their corporate language within the Spanish market, not postings from outside
the target universe.

**Implication:** language is not a reliable proxy for market, and the
bilingual (ES/EN) keyword strategy recorded in `data_dictionary.md` was
incomplete: French-language postings would have been missed entirely by it.

### Staleness figures extended

The 90-day figure recorded earlier today is extended with two further
thresholds, measured against the extraction-run timestamp:

| Threshold        | Postings | %    |
|------------------|----------|------|
| Older than 30 d  | 292      | 30.7 |
| Older than 90 d  | 161      | 16.9 |
| Older than 1 y   | 60       | 6.3  |

Earliest posting: 2024-03-08, 28 months before extraction.

**Implication, and it qualifies every other analysis in this project:** the
source returns as active postings that have been published for up to 28
months. `created` records publication date; the source provides no field
indicating whether a posting is still open. Every figure this project
publishes describes what Adzuna returned as active on 2026-07-06, not
verified current market demand.

### Phase 1 analysis outcome summary

Six analyses were planned. Four produced findings; two were dropped or
reframed after measurement. Both outcomes are recorded because a discarded
analysis with a stated reason is itself a governance result — it demonstrates
source evaluation, not failure to execute.

| Query | Outcome |
|-------|---------|
| `00_load_verification` | Reconciled, no discrepancies |
| `01_category_frequency` | `legal-jobs` exhaustion confirmed at page level |
| `02_geographic_distribution` | Madrid + Barcelona 49.0% of 815 locatable |
| `03_salary_field_presence` | 27-point spread; interpretation undetermined |
| `04_description_coverage` | Term prevalence analysis DROPPED |
| `05_company_concentration` | Employer ranking DROPPED; market structure reported |
| `06_posting_staleness` | 30.7% older than 30 days at extraction |
