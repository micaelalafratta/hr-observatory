# Data Dictionary

> Field-by-field definitions for data extracted and transformed in this
> pipeline. Updated as decisions are made, not retroactively at the end
> of the project.

## Source of truth

**From 2026-08-04, this document describes the columns of
`hr-observatory.raw.adzuna_postings_raw` as loaded, not the nested shape of
the Adzuna API response.**

Every column carries an `OPTIONS(description="...")` clause in
`sql/schema/create_adzuna_postings_raw.sql`, so the authoritative definitions
live in the table schema itself. This file is a projection of that schema,
regenerable with:

```sql
SELECT column_name, data_type, description
FROM `hr-observatory.raw.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS`
WHERE table_name = 'adzuna_postings_raw'
ORDER BY column_name;
```

A dictionary maintained in parallel with a schema diverges from it. A
dictionary generated from the schema cannot.

**Nesting note:** the API returns `company`, `category` and `location` as
objects. The extraction flattens them to `company`, `category_label`,
`category_tag`, `location_name`, `latitude`, `longitude`. The API's
hierarchical `location.area` array was not retained; it is recoverable from
the raw JSON files in `data/raw/` if Phase 2 needs finer granularity.

**Dropped at flattening:** `adref` and `__CLASS__` carry no analytical value
and are absent from the loaded table.

## Source: Adzuna API — job search endpoint

**Official reference:** the structure and field set below are confirmed
against Adzuna's official API documentation — the job search endpoint
(https://developer.adzuna.com/docs/search) and the salary predictor
endpoint (https://developer.adzuna.com/docs/jobsworth). The response
examples in those docs show the fields, their nesting, and the
`salary_is_predicted` flag. Definitions below are written in this
project's own words from those examples plus the empirical extraction;
Adzuna does not publish a per-field text glossary, so field meaning for
un-annotated fields (e.g. `created` as publish date) is inferred from
the field name and example values, and labelled as such where relevant.

*Field-presence percentages are measured against the first full
category-based extraction (n=951 postings; 4 categories × up to 5 pages —
see `data_lineage.md`, "First structural exploration"). Where an earlier
n=10 / n=50 test gave a materially different number, that is noted as
superseded rather than deleted, for traceability.*

---

## Fields from the source

### id

- **Type:** STRING (`NOT NULL` — the only mandatory column in the raw table)
- **Definition:** Adzuna's unique identifier for the job posting.
- **Typing decision:** stored as STRING, not INT64. An external identifier is
  not a quantity: it is never arithmetically manipulated, and integer typing
  risks losing leading characters.
- **Presence:** always present (951/951).
- **Known limitation (duplicates):** 4/951 ids appear twice, all within
  `it-jobs`. Verified field-by-field (2026-08-04): identical across
  every column except `source_page` — genuine pagination overlap (the
  same posting reappearing on a later page), not an id collision
  between distinct postings. Dedupe by `id` in the transform step,
  keeping the first occurrence. The raw layer retains all 951 rows so the
  defect stays verifiable. Distinct ids: 947.

### title

- **Type:** STRING
- **Definition:** Job title as written by the advertiser. Free text,
  not standardized — the same role can appear under many different
  titles across postings. 910 distinct values across 951 rows.
- **Presence:** always present.
- **Known limitation (provider test records, measured 2026-08-04):** two
  postings carry titles indicating Adzuna test data rather than real
  vacancies — "Contract Dummy Job" and "Job for testing". Exclude by title
  pattern in the transform step. See `data_quality.md`, Validity.
- **Known limitation (language, measured 2026-08-04):** 37 postings (3.9%)
  carry French-language titles (`F/H`, `H/F`, `en stage`, `chargé`), all
  located in Spain — French-owned employers publishing in their corporate
  language. Language is not a proxy for market; a bilingual ES/EN filter
  would drop these silently.

### company

- **Type:** STRING (flattened from `{"display_name": "..."}`)
- **Definition:** Employer name as registered by Adzuna.
- **Presence:** 860/951 (90.43%). 91 postings carry no employer name at all —
  the key is absent, not null. (Supersedes the earlier "always present"
  assumption from the n=50 test.)
- **Known limitation (name variants):** the same company can appear with
  name variants. Measured on n=951 (2026-08-04): normalizing (case-fold +
  trim punctuation/whitespace) and grouping finds 6 normalized keys with
  more than one raw spelling (e.g. `dLocal`/`Dlocal`, `Erm`/`ERM`) —
  full list and normalization decision in `data_quality.md`, Consistency.
  474 raw spellings collapse to 468 normalised entities.
- **Known limitation (non-company values, measured 2026-08-04):** the field
  carries at least one value that is not a company — the string `Madrid`, in
  5 postings. The source applies no type constraint. Recorded under Validity
  in `data_quality.md`, distinct from the spelling variants above.
- **Known limitation (intermediaries, measured 2026-08-04):** the two
  highest-volume names account for 15.9% of named postings and are a
  recruitment agency and an aggregator, not employers; the top 10 reach only
  25.1%. 344 companies (73.5%) publish a single posting. **Consequence:** an
  employer ranking cannot be built from this field — it would measure
  intermediation, not demand. The source provides no field distinguishing
  agencies from employers; that classification is editorial and deferred to
  Phase 2.

### category_label

- **Type:** STRING (flattened from `category.label`)
- **Definition:** Human-readable category name returned by the provider, in
  Spanish (e.g. "Trabajos en informática"). Display label only.
- **Presence:** always present.

### category_tag

- **Type:** STRING (flattened from `category.tag`)
- **Provenance:** Adzuna — the category the provider assigns to the posting.
- **Definition:** Adzuna's own machine-readable job category classification.
  This is the "Adzuna categories" taxonomy referenced in the MDM mapping
  problem (see project roadmap) — it does not match CNO-2011 (EPA) or
  ISCO-08 (ILO).
- **Measured 2026-08-04:** identical to `search_category` in 951/951
  records — zero divergence.
- **Decision:** both retained despite the redundancy. They record different
  things — a provider classification and a request parameter — and divergence
  in a future extraction would itself be a finding. Collapsing them would make
  that change undetectable.
- **Presence:** always present.

### location_name

- **Type:** STRING (flattened from `location.display_name`)
- **Definition:** Textual location as delivered by the provider.
- **Presence:** always present (951/951, 0 nulls).
- **Known limitation (granularity):** depth is not uniform. Measured on
  n=951 (2026-08-04, refined in SQL): 644 records (67.7%) are
  "City, Region"; 171 (18.0%) are city or region only, with no comma; 136
  (14.3%) are the bare string "España". City-level aggregation uses the 815
  locatable records, treating comma-less city names as equivalent to their
  comma-separated form, and excludes the 136 country-level records. All
  published geographic percentages use 815 as denominator. See
  `data_quality.md`, Consistency.
- **Known limitation (not work modality):** records where a posting is
  published, not whether the work is on-site. The source carries no
  remote-work field.

### latitude / longitude

- **Type:** FLOAT64
- **Definition:** Exact geographic coordinates of the posting.
- **Presence:** 790/951 (83.07%) each, always paired.
- **Known limitation:** any geographic analysis relying on these fields will
  have partial coverage — prefer `location_name` (always present) for broad
  geographic breakdowns. (Supersedes the ~50% figure from the n=50 test,
  which understated coverage.)

### salary_min / salary_max

- **Type:** FLOAT64
- **Definition:** Minimum and maximum salary attached to the posting.
  Always paired (556/556 identical — Adzuna returns both or neither).
- **Presence:** 556/951 (58.46%). By category: consultancy 70.4%, legal
  70.1%, IT 52.4%, HR 43.2%.
- **Superseded figure:** an earlier reading of ~2% (1/50 in the n=50
  test, 0/10 in the n=10 test) was based on samples too small for
  inference and is NOT the project figure. Retained in `data_lineage.md`
  as record. The real-volume figure is 58.46%.
- **Critical caveat (provenance undetermined):** a present salary is NOT
  confirmed to be an employer-stated figure. All postings carry
  `salary_is_predicted = '0'`, and the values cluster into few round,
  repeated figures (~62 distinct values, mostly multiples of 10,000) —
  atypical of individually declared pay. But this is evidence, not proof:
  it cannot separate a platform estimate from rounded declared pay on
  Adzuna data alone, and Adzuna's docs do not define what a `0` value is.
  Treat these fields as a platform-provided reference of undetermined
  provenance, not verified employer-stated pay. **Do not describe field
  presence as "employer disclosure".** Full analysis (including the two
  rejected discriminating tests) in `data_quality.md` — Accuracy.
- **Known limitation (unit inconsistency):** pay periodicity is undeclared
  and mixed — hourly, daily, monthly and annual values share the same field
  with no unit flag. Confirmed 2026-08-04 via ratio test and manual
  `redirect_url` inspection; a Spanish-locale decimal-parsing explanation was
  tested and rejected. Affects both tails: 12 records fall below the annual
  floor, and at least one high-end record is an annualised freelance rate.
- **Exclusion threshold (declared):** records with `salary_min` below Spain's
  statutory minimum annual wage — **17,094 € (2026, RD 126/2026)** — are
  excluded from aggregate salary analysis. 12/556 records (2.2%), 8 of them
  in `hr-jobs`. The exclusion moves mean `salary_min` from 71,096 to 72,601.
  The threshold is robust: no observed value falls between the 2025 and 2026
  minimum-wage figures. **It removes demonstrable contamination only** —
  non-annual values above the threshold are indistinguishable from genuine
  figures. Median is reported in preference to mean throughout.
- **Range validity:** `salary_min > salary_max` checked directly on
  n=951 (2026-08-04) — 0 violations. The paired fields are internally
  consistent wherever both are present.

### salary_is_predicted

- **Type:** STRING ("0" or "1")
- **Typing decision:** stored as STRING, not BOOL. Casting to boolean at the
  raw layer would be an interpretation, and the field's meaning is precisely
  what is disputed.
- **Definition:** Adzuna flag. Per official docs
  (developer.adzuna.com/docs/jobsworth), `1` marks a salary generated by
  Adzuna's Salary Predictor (an estimate from title + description text).
  A `0` marks a salary *not* produced by that predictor — but the docs
  do NOT define precisely what a `0` value is (e.g. employer-stated vs.
  otherwise platform-derived).
- **Measured (2026-08-04):** the value is the literal string `'0'` in
  **951/951 records — including the 395 that carry no salary at all.** The
  field has zero variance and is present where the concept does not apply.
  **Consequence: it is not informative.** A constant field cannot discriminate
  provenance in either direction. This strengthens rather than resolves the
  "provenance undetermined" conclusion. See `data_quality.md` — Accuracy.
- **Presence:** always present (951/951), but never meaningful.

### contract_type / contract_time

- **Type:** STRING
- **Definition:** Per Adzuna's public documentation, these fields
  should indicate contract type (e.g. "permanent") and time
  arrangement (e.g. "full_time").
- **Status (measured on n=951):** `contract_type` present in 0/951
  (0.00%) — effectively never returned for this Spanish dataset.
  `contract_time` present in 27/951 (2.84%), values `full_time` and
  `part_time`. This resolves the earlier open question (n=10 / n=50 saw
  neither): the fields are not a sampling artifact, they are genuinely
  near-absent in Adzuna's Spain data. Do not rely on either for analysis;
  document as a coverage limitation.
- **Schema decision (2026-08-04):** `contract_type` is retained in the
  BigQuery schema despite being 0% populated. A structurally empty column
  documented as such is a completeness finding; an omitted column is lost
  information. Retaining it also means a future extraction that begins
  populating the field needs no schema migration.
- **Presence:** `contract_type` 0.00%; `contract_time` 2.84%.

### created

- **Type:** TIMESTAMP (delivered as an ISO 8601 string with `Z` suffix,
  parsed at load; all 951 values parsed without error)
- **Definition:** Date and time the posting was published on Adzuna.
- **Presence:** always present.
- **Known limitation (posting age, extended 2026-08-04):** ranges
  2024-03-08 to 2026-07-06. Measured against the extraction run:
  292 postings (30.7%) older than 30 days, 161 (16.9%) older than 90 days,
  60 (6.3%) older than one year.
- **Critical:** this field records publication date, **not vacancy status**.
  The source provides no field indicating whether a posting is still open, so
  every project figure describes what the source returned as active on
  2026-07-06, not verified current demand. See `data_quality.md`, Timeliness.

### description

- **Type:** STRING
- **Definition:** A snippet (truncated excerpt) of the full job
  posting text — not the complete description. Confirmed as a
  structural limitation of Adzuna's free-tier API (no parameter exists
  to request the full text).
- **Presence:** always present (as a snippet).
- **Known limitation (hard truncation, measured 2026-08-04):** the field is
  capped at exactly 500 characters. 814/951 records (85.6%) sit at the
  ceiling; mean 485, min 142, max 500 with no exceptions. Only 137 records
  carry full text.
- **Known limitation (structural variability):** companies write postings
  with different structures (some open with company background, others with
  values, others with technical requirements), so what survives the
  truncation is not randomly distributed — it correlates with each company's
  writing style, not just with what the role requires.
- **Decision (2026-08-04):** term prevalence analysis over this field is
  **DROPPED** for Phase 1. 500 characters covers roughly an opening
  paragraph, so a keyword search measures prominence in lead text rather than
  requirement, and the truncation is non-random — longer, more detailed
  postings lose proportionally more. The two-tier metric approach previously
  recorded is superseded. See `data_quality.md`, "Reliability of text-based
  analysis."

### redirect_url

- **Type:** STRING (URL)
- **Definition:** Adzuna redirection link to the original job posting.
- **Presence:** always present.
- **Use:** manual verification of individual records during profiling. Not a
  stable long-term reference — listings expire.

---

## Fields added by this project

These do not come from Adzuna. The distinction matters: they record what this
pipeline did, not what the source delivered.

### search_category

- **Type:** STRING
- **Provenance:** this project, not Adzuna.
- **Definition:** the category requested from the API by the extraction
  script. Four values: `it-jobs`, `hr-jobs`, `legal-jobs`,
  `consultancy-jobs`. Counts: 250 / 250 / 201 / 250.
- **Presence:** 951/951.

### source_page

- **Type:** STRING (`p1`–`p5`)
- **Provenance:** this project, not Adzuna.
- **Definition:** the API result page the record was retrieved from. The only
  field distinguishing the 4 duplicated ids.
- **Measured:** 50 records per page for every category except `legal-jobs` p5,
  which returned 1 — page-level evidence of source exhaustion rather than
  truncated extraction.
- **Presence:** 951/951.

### extracted_at

- **Type:** TIMESTAMP
- **Provenance:** this project, not Adzuna.
- **Definition:** the extraction-run timestamp, 2026-07-06 15:20:32 UTC. A
  single value for all 951 rows: it describes the run, not the individual
  file.
- **Why it exists:** it is the reference point against which posting
  staleness is measured, and the field that will distinguish extraction runs
  once loading is repeated. Without it the dataset supports prevalence
  analysis only, never analysis of change over time.
- **Presence:** 951/951.

---

## Cross-field note: missing = absent, never null/empty

Measured on n=951: when Adzuna lacks a value, it **omits the key entirely**
— across all fields, `null` and `empty` counts were zero. A missing field
is therefore an absent key, not an explicit null.

**Resolved 2026-08-04:** all columns except `id` are declared NULLABLE in
`sql/schema/create_adzuna_postings_raw.sql`, so an absent key loads as SQL
NULL. `id` is the only `NOT NULL` column: the raw layer must accept whatever
the source delivers, and declaring any other column mandatory would make a
future load fail on a legitimately absent value.

## Data source scope

**Source:** Adzuna API — Spain (`country = "es"`)

**Inclusion criteria:** Job postings are retrieved by Adzuna category,
not by free-text keyword search. The search universe is defined by four
categories:

| Category tag       | Label (EN)              | Rationale for inclusion                          |
|--------------------|-------------------------|--------------------------------------------------|
| `it-jobs`          | IT jobs                 | Core technology and most data roles              |
| `hr-jobs`          | HR jobs                 | Hiring-algorithm and labour-governance angle     |
| `legal-jobs`       | Legal jobs              | DPO, compliance, data protection roles           |
| `consultancy-jobs` | Consultancy jobs        | Data governance / compliance roles in consulting |

**Universe confirmed Spanish (2026-08-04):** the 37 French-language postings
are all located in Spain — French-owned employers publishing in their
corporate language, not postings from outside the target market.

**Excluded on purpose (Phase 1):** `accounting-finance-jobs` and
`scientific-qa-jobs` also contain scattered data roles but were excluded
to keep noise low for Phase 1. Candidates for inclusion in Phase 2.

**Relevance filtering:** Category search casts a wide net. Data / AI /
governance relevance was to be applied downstream in the transform step via
bilingual (ES/EN) keyword filtering. **Status 2026-08-04:** the keyword
analysis this filtering fed has been dropped for Phase 1 (see `description`
above), and the bilingual approach was in any case incomplete — French-language
postings would have been missed. See `data_quality.md`, Completeness.
