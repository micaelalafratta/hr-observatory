# Data Quality Dimensions

> Explicit documentation of completeness, consistency, timeliness, and
> accuracy over this project's own data — following DAMA data quality
> dimensions.

## Completeness
### Completeness — categories
**Salary (`salary_min` / `salary_max`):** present in 556/951 postings
(58.46%) in the first full category extraction (n=951). Where absent,
the key is omitted entirely (not returned as null). The two fields are
always paired (556/556 identical).

*Superseded earlier figure:* an initial reading of ~2% (1/50 in an n=50
test, 0/10 in an n=10 test) was based on samples too small for
inference. It is NOT the project figure and should not be cited; it is
retained in `data_lineage.md` as record. The real-volume figure is
58.46%.

*Important — presence is not the whole story:* a present salary is not
confirmed to be employer-stated. See Accuracy below for why the 58.46%
should be read as "carries a salary value with `salary_is_predicted = 0`,
provenance unconfirmed" rather than as verified salary transparency. This
is a completeness figure, not an accuracy claim — the two are documented
separately on purpose.

### Completeness — search universe

The dataset is scoped to four Adzuna categories (`it-jobs`, `hr-jobs`,
`legal-jobs`, `consultancy-jobs`). This has known completeness limits
that are documented rather than hidden:

- **Data roles are dispersed.** Some data-analyst and data-related roles
  are classified by employers under `accounting-finance-jobs`,
  `scientific-qa-jobs`, or other categories not in scope. Those postings
  are not captured in Phase 1.
- **Governance roles split across categories.** DPO and compliance roles
  appear in both `legal-jobs` and `consultancy-jobs`; some may also sit
  in categories out of scope.
- **Trade-off accepted:** Narrower scope reduces noise and keeps Phase 1
  achievable in four weeks, at the cost of some recall. Scope is
  expandable in Phase 2.

### Completeness — relevance filtering

Relevance (data / AI / governance) is filtered by bilingual keyword
matching in the transform step. Spanish and English terms are both
covered (e.g. "data governance" / "gobernanza de datos", "GDPR" / "RGPD")
to avoid language-driven loss. Accent normalisation is applied before
matching to prevent missed matches (e.g. "gestión" vs "gestion").

### Completeness — extraction integrity

The first full extraction (July 6 2026) is expected to produce 5 pages
per category across 4 categories — 20 raw files. A file-count check per
category is run after extraction to confirm no pages are missing before
the transform step. This guards against silent data loss during the file
operations involved in organising `data/raw/` (moving test files to
`discarded/`, the category catalogue to `reference/`). Result: 20/20
files confirmed present. See `data_lineage.md` for the extraction event.

*Note on coverage vs. integrity: this check confirms that every page we
asked for was saved — it does not claim the 5-page cap captures the full
market. Per-category available volume is far higher; the cap is a Phase 1
exploration limit, revisited in Phase 2.*

*Per-category volume (n=951): `consultancy-jobs` 250, `hr-jobs` 250,
`it-jobs` 250, `legal-jobs` 201. Three categories hit exactly 250 (the
5-page cap), so the cap — not the market — limited them. `legal-jobs`
returned 201, meaning it was exhausted before page 5: Adzuna had fewer
than 250 postings for it at extraction time. So the cap is a self-imposed
limit for three categories but the true available volume for `legal-jobs`.
Any per-category comparison must account for this asymmetry. See
`data_lineage.md`, "First structural exploration."*

*Page-level confirmation (2026-08-04): `consultancy-jobs`, `hr-jobs`,
`it-jobs` return exactly 50/50 postings on every page p1–p5; `legal-jobs`
returns 50/50 through p4 and only 1/50 on p5 — direct page-level evidence
that legal-jobs exhaustion, not a truncated extraction, explains the 201
figure. See `data_lineage.md`, 2026-08-04 entry.*

**Pagination duplicate confirmation (2026-08-04, n=951):** the 4
duplicate posting ids found on 2026-07-13 (all within `it-jobs`) were
verified field-by-field — identical across every column except
`source_page`. This confirms genuine pagination overlap (the same
posting reappearing across Adzuna pages between calls), not an id
collision between distinct postings. **Decision:** dedupe by `id` in
the transform step, keeping the first occurrence.

## Consistency

**Company name variants (measured 2026-08-04, n=951):** `company`
normalized (lowercase, punctuation/whitespace stripped) and grouped by
the normalized key. 6 normalized keys resolve to more than one raw
spelling — the same company written inconsistently:
- `dLocal` / `Dlocal`
- `domestiko.com` / `Domestiko.com`
- `Erm` / `ERM`
- `Expert Executive Recruiters` / `Expert Executive Recruiters ` (trailing space)
- `Neoris` / `NEORIS`
- `thexpeople` / `Thexpeople`

**Decision:** normalize `company` (case-fold + trim) before any
grouping or "top companies" aggregation, in the transform step. The raw
value is preserved as extracted; normalization is a staging-layer
transform, not a raw-layer edit. See `data_dictionary.md`, `company`.

**Location granularity (measured 2026-08-04, n=951):** `location_name`
is not uniform in depth. 307/951 postings (32.28%) carry only a
country- or region-level string with no comma-separated breakdown —
136 of those are the bare string "España". Any city-level aggregation
("top cities") must filter or flag these first, or it will silently
count country-level postings as a city. See `data_dictionary.md`,
`location`.

## Timeliness

**Extraction window:** a single extraction run, 2026-07-06 15:20:32 UTC
(see `data_lineage.md`, "First full extraction by category"). All
timestamps in this project are UTC, confirmed consistent across the
extraction-run timestamp and the `created` field (see `data_lineage.md`,
"UTC timezone consistency check") — no conversion is needed to compare
them. **Critical implication:** with a single extraction run, this
project measures the PREVALENCE of postings and terms at one point in
time, not their EVOLUTION over time. Any trend claim ("X is
growing/declining") is out of scope for Phase 1 and would require
repeated extractions at defined intervals.

**Posting-age distribution within this extraction (measured 2026-08-04,
n=951):** `created` ranges 2024-03-08 to 2026-07-06 (see
`data_lineage.md`). 161/951 postings (16.93%) are more than 90 days
older than the latest posting in the extraction — a real tail of stale
listings, not an artifact. Volume is heavily concentrated in the weeks
immediately preceding the extraction date. **Implication:** a "current
market snapshot" framing should account for this tail rather than
assume every posting reflects live demand at extraction time.

*Pending: cross-source extraction frequency is still to be defined
(Adzuna vs. quarterly EPA downloads vs. annual ILO index) — this is a
separate question from the within-dataset age distribution above.*

## Accuracy

**Geocoding (`latitude` / `longitude`):** present in 790/951 postings
(83.07%) on n=951 — higher than the ~50% seen in the earlier n=50 test,
which understated coverage. The remaining ~17% still include a
textual/hierarchical location (the `location` field, always present),
but without exact coordinates.

**Implication:** any geographic analysis relying on lat/long will have
partial coverage; analysis by autonomous community is more reliable if
based on `location` rather than coordinates.

**Salary provenance (`salary_min` / `salary_max` / `salary_is_predicted`):**
this is the clearest completeness-vs-accuracy case in the project, and is
documented in full because the distinction is the point.

- **Completeness:** salary is present in 58.46% of postings (see above).
- **Accuracy problem:** a present salary is not confirmed to be a figure
  the employer stated in the posting. Three observations, in order of
  confidence:
  1. *Measured:* all 556 salaried postings carry
     `salary_is_predicted = '0'` (string). None are flagged `1`.
  2. *Inspected:* sample salaried postings show round, repeated values
     rather than the irregular figures typical of individually
     employer-stated pay — see the distribution finding below.
  3. *Documented (official source):* Adzuna's docs
     (developer.adzuna.com/docs/jobsworth) confirm a Salary Predictor
     exists and that `salary_is_predicted = 1` marks its estimates. The
     docs do **not** define what a `0` value is — so a `0` cannot be
     read as "employer-stated" on the strength of the documentation.
- **Distribution finding (EDA, 2026-07-13):** across the 556 salaried
  postings there are only ~62 distinct `salary_min` values, and the most
  frequent are round multiples of 10,000 (70k appears 111 times, 60k 103
  times, 80k 72 times, etc.). This concentration into few round, heavily
  repeated values is atypical of individually employer-stated pay, which
  usually shows dispersed, irregular figures. It is *more consistent with*
  some form of grid-based assignment than with per-employer disclosure.
- **What this does and does not prove (honest limit):** the round-value
  pattern is evidence, not proof. It cannot, on Adzuna data alone,
  conclusively separate "platform estimate" from "employer-stated pay
  that happens to be rounded" (many employers do post round figures).
  Two further tests were considered and rejected as non-discriminating:
  salary scaling with title seniority (the real market scales too) and
  salary dispersion within a repeated exact title (identical titles can
  be genuinely different roles — e.g. 1 vs 5 years required — so
  dispersion proves nothing either). Conclusion: the exact nature of the
  salary value (platform estimate, rounded declared range, or a mix) is
  **not determinable from Adzuna data alone**.
- **Conclusion (what can honestly be claimed):** 58.46% of postings carry
  a salary value with the predicted-flag at `0`. The values cluster into
  few round figures, a pattern atypical of individually declared pay, but
  their exact provenance is **not determinable from Adzuna data alone**.
  The project therefore treats `salary_min`/`salary_max` as a
  platform-provided reference, not as verified employer-stated pay, and
  does not publish "X% of employers disclose salary" as a finding.
- **Where verified salary would live:** if the project later needs
  genuinely employer-stated pay, the place to look is salary figures
  written in the `description` text, not these structured fields — a
  text-analysis task for a later phase, not Phase 1.

*Note: this analysis reinforces the completeness ≠ accuracy principle. A
field can be 58% complete and still 0% verifiable as what its name
implies. Documenting the limit is the governance value, not hiding it.*

### Salary unit inconsistency (Validity)

**Low end — resolved (2026-08-04):** 11/556 salaried postings (2.0%)
carry `salary_min` under 12,000 — implausible as an annual figure. A
Spanish-locale decimal-parsing hypothesis ("28.000 €" misread as an
English decimal, "28.0") was tested and rejected: all 11 values are
integers, and multiplying by 1,000 does not land most of them back
inside the observed normal range (e.g. 6,875 → 6,875,000). The
min/max ratio for these postings instead matches an hourly-rate pattern
(mostly 1.04–1.36, e.g. 360–480, 30–35), confirmed by manually opening
3 of the 11 `redirect_url` links in a browser. **Conclusion:** these
postings store an hourly (or otherwise sub-annual) rate in the same
field as annual salaries, with no unit flag to distinguish them.
Applying Spain's minimum annual wage (17,094 €) as an exclusion
threshold instead affects 12/556 postings (2.2%) and shifts mean
`salary_min` from 71,096 to 72,601 — a quantified, non-negligible bias
if the low cluster is left uncorrected.

**High end — unresolved (2026-08-04):** the same gap/ratio method was
applied to the top of the range. `salary_min` 203,112 and 187,200 sit
above a clean gap before the next-highest cluster (120,000, repeated
many times); `salary_max` reaches 395,200. No unit-parsing or
rate-type defect was confirmed for these two — they remain unresolved
outliers pending the same manual `redirect_url` check applied at the
low end.

**Range validity — confirmed clean (2026-08-04):** `salary_min >
salary_max` checked directly across all 951 postings — 0 violations.
The paired salary fields are internally consistent wherever both are
present.

Full investigation trail in `data_lineage.md`, 2026-08-04 entry.

## Reliability of text-based analysis (description field)

This section documents a methodological decision, not just a data
limitation, because the reasoning behind it matters for interpreting
any future finding based on this field.

**Two distinct problems identified with `description`:**

1. **Truncation:** Adzuna's free-tier API returns only a snippet of
   the full job posting, confirmed via their official documentation.
   There is no parameter to retrieve the complete text. Any
   keyword-mention count (AI, governance, GDPR, DPO, etc.) based on
   this field is necessarily a **lower bound**, not a complete count.

2. **Structural variability across employers:** manual review of the
   raw data (July 6 2026) showed that companies structure job postings
   very differently — some begin with company background, others with
   values statements, others directly with technical requirements.
   Since the snippet only captures the beginning of the text, what
   survives truncation is not randomly distributed: it correlates with
   each company's writing style, not necessarily with what the role
   actually requires. This means keyword counts from this field could
   partly reflect "which companies write postings in a get-to-the-point
   style" rather than "which companies genuinely require this skill."

**Decision:** rather than discarding text-based analysis or treating it
as equally reliable to structured-field analysis, this project reports
it as two separate, explicitly labeled metrics:

- **Primary metric (high confidence):** keyword mentions found in
  `title` or `category` only — structured fields, low bias, but also
  low recall (most postings won't mention "GDPR" in a job title).
- **Secondary metric (exploratory):** keyword mentions found in the
  `description` snippet — higher recall, but always reported with both
  caveats above attached, and never presented as a definitive
  percentage (e.g. avoid phrasing like "23% of postings mention AI";
  prefer "at least 23% of postings show visible mentions of AI in the
  available text").

**Why this field is not dropped entirely:** none of this project's
other Phase 1 dimensions (salary opacity, top companies, geographic
distribution) depend on `description` being reliable — they rely on
structured fields instead. The observatory's core findings do not
collapse if this one dimension carries a lower confidence label.
