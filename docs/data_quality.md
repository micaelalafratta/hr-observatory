# Data Quality Dimensions

> Explicit documentation of completeness, consistency, validity, timeliness,
> and accuracy over this project's own data — following DAMA data quality
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

### Completeness — salary field presence by category

**Measured in SQL 2026-08-04** (`sql/analysis/03_salary_field_presence.sql`):

| Category         | Postings | With value | %    | Median (≥ SMI) |
|------------------|----------|------------|------|----------------|
| consultancy-jobs | 250      | 176        | 70.4 | 70,000         |
| legal-jobs       | 201      | 141        | 70.1 | 100,000        |
| it-jobs          | 250      | 131        | 52.4 | 60,000         |
| hr-jobs          | 250      | 108        | 43.2 | 50,000         |

**Framing correction (2026-08-04):** this analysis was initially written as
"salary disclosure" with a `pct_disclosing` metric. That contradicted the
Accuracy conclusion below — if provenance is undetermined, a populated field
cannot be attributed to employer disclosure. The query was renamed
`03_salary_field_presence.sql` and the metric `pct_with_salary_value`. What is
measured is whether the field carries a value, not whether an employer chose
to publish pay.

**Pattern observed:** presence rate and salary level rank in the same order
across all four categories — a 27-point spread between consultancy and HR.

**Interpretation not determinable:** the pattern is equally consistent with
employer behaviour (lower-paying roles publish pay less often) and with source
behaviour (Adzuna salary coverage is better in higher-paying segments). Four
categories are a pattern, not a correlation. The pattern is publishable; a
causal reading of it is not.

**Selection caveat:** medians reflect only postings carrying a value. If the
gap is employer-driven, observed medians are inflated and real gaps are wider
than measured. If it is source-driven, they are not. The direction of the bias
cannot be established from this source.

### Completeness — description field

**Measured 2026-08-04:** `description` is truncated by the provider at a hard
500-character ceiling. 814/951 records (85.6%) sit at exactly 500 characters;
mean 485, minimum 142, maximum 500 with no exceptions. Only 137 records carry
untruncated text. See "Reliability of text-based analysis" below for the
consequence.

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

**Limitation identified 2026-08-04:** bilingual (ES/EN) matching is
incomplete. 37 postings (3.9%) carry French-language titles, all located in
Spain — French-owned employers (DriiveMe, Children Worldwide Fashion España
SLU) publishing in their corporate language within the Spanish market.
Language is not a proxy for market, and a two-language filter would silently
drop these records. Recorded rather than fixed: relevance filtering is a
transform-step concern, and the keyword analysis it fed has since been dropped
(see "Reliability of text-based analysis").

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
the transform step, keeping the first occurrence. The raw layer retains
all 951 rows so the defect stays verifiable in SQL.

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

**SQL confirmation (2026-08-04):** grouping by the normalised key in
BigQuery returns 468 distinct companies against 474 raw spellings —
the 6 variants collapse exactly as measured.

**Location granularity (measured 2026-08-04, refined in SQL):**
`location_name` is delivered at three levels of depth within the same field,
and is 100% complete (0 nulls):

| Granularity             | Postings | %    |
|-------------------------|----------|------|
| City and region         | 644      | 67.7 |
| City or region only     | 171      | 18.0 |
| Country only ("España") | 136      | 14.3 |

The field is complete but not consistent. The 171 comma-less values are
largely identifiable cities written without their region ("Madrid",
"Barcelona"), not unusable data — only the 136 country-level records carry no
geographic signal.

**Decision:** city-level analysis uses the 815 locatable records, treating
comma-less city names as equivalent to their comma-separated form; the 136
country-level records are excluded. All published geographic percentages use
815 as denominator, not 951.

**Superseded figure:** Madrid + Barcelona at 42.1% was computed over all 951
values. Over the 815 locatable records the same cities account for **49.0%**
(Madrid 262, 32.1%; Barcelona 138, 16.9%). The 49.0% figure is the published
one; the 42.1% is retained here as record.

**Long-tail caution:** cities below the top two are sensitive to individual
employers — 6 of the 12 Santa Cruz de Tenerife postings come from a single
company. Only the top ranks should be read as market signal.

**Location is not work modality:** `location_name` records where a posting is
published, not whether the work is on-site. The source carries no remote-work
field, so no claim about physical work location can be made from it.

## Validity

Fields that carry values of the wrong kind — as distinct from missing values
(Completeness) or inconsistently formatted values (Consistency).

**Provider test records (measured 2026-08-04):** two postings are Adzuna test
data that reached the production response — "Contract Dummy Job" and "Job for
testing", both with salary 360–480. These are not vacancies. They fall among
the 12 records excluded by the minimum-wage threshold, so salary aggregates
are unaffected, but they are counted in every volume figure. **Decision:**
exclude by title pattern in the transform step.

**Non-company values in `company` (measured 2026-08-04):** the string `Madrid`
appears as a company name in 5 postings. The source applies no type constraint
to this field. Distinct from the case and whitespace variants recorded under
Consistency: those are the same entity written differently; this is not an
entity at all.

**Salary unit inconsistency:** the field mixes hourly, daily, monthly and
annual figures with no unit declared. Recorded under Accuracy rather than here
because the type is correct and each value is real — what is wrong is
comparability across records. See "Salary unit inconsistency" below.

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

**Posting-age distribution (measured 2026-08-04, extended in SQL, n=951):**
`created` ranges 2024-03-08 to 2026-07-06. Measured against the
extraction-run timestamp:

| Threshold       | Postings | %    |
|-----------------|----------|------|
| Older than 30 d | 292      | 30.7 |
| Older than 90 d | 161      | 16.9 |
| Older than 1 y  | 60       | 6.3  |

Volume concentrates in the weeks preceding extraction, with a long thin tail
reaching 28 months back.

**Implication, and it qualifies every other figure in this project:**
`created` records publication date, not vacancy status, and the source
provides no field indicating whether a posting is still open. Every figure
this project publishes describes what the source returned as active on
2026-07-06, not verified current market demand.

*Pending: cross-source extraction frequency is still to be defined
(Adzuna vs. quarterly EPA downloads vs. annual ILO index) — this is a
separate question from the within-dataset age distribution above.*

## Accuracy

**Geocoding (`latitude` / `longitude`):** present in 790/951 postings
(83.07%) on n=951 — higher than the ~50% seen in the earlier n=50 test,
which understated coverage. The remaining ~17% still include a
textual location (`location_name`, always present), but without exact
coordinates.

**Implication:** any geographic analysis relying on lat/long will have
partial coverage; analysis by autonomous community is more reliable if
based on `location_name` rather than coordinates.

**Salary provenance (`salary_min` / `salary_max` / `salary_is_predicted`):**
this is the clearest completeness-vs-accuracy case in the project, and is
documented in full because the distinction is the point.

- **Completeness:** salary is present in 58.46% of postings (see above).
- **Accuracy problem:** a present salary is not confirmed to be a figure
  the employer stated in the posting. Three observations, in order of
  confidence:
  1. *Measured:* all 951 postings carry `salary_is_predicted = '0'`
     (string) — including the 395 that carry no salary at all. The field
     has zero variance and is present where the concept does not apply,
     so it cannot discriminate provenance in either direction.
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
  genuinely employer-stated pay, the place to look would be salary figures
  written in the `description` text. That route is now closed for Phase 1:
  the field is truncated at 500 characters (see below), so it does not
  reliably contain the pay section of a posting.

*Note: this analysis reinforces the completeness ≠ accuracy principle. A
field can be 58% complete and still 0% verifiable as what its name
implies. Documenting the limit is the governance value, not hiding it.*

### Salary unit inconsistency

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
Applying Spain's minimum annual wage (17,094 €, RD 126/2026) as an
exclusion threshold instead affects 12/556 postings (2.2%) and shifts mean
`salary_min` from 71,096 to 72,601 — a quantified, non-negligible bias
if the low cluster is left uncorrected.

**Threshold robustness (2026-08-04):** no observed `salary_min` value falls
between the 2025 minimum wage (16,576 €) and the 2026 figure (17,094 €) — the
next value above 16,200 is 18,000. The exclusion count is therefore
insensitive to which year's figure is used, so the threshold does not depend
on having picked the exact statutory value.

**Category distribution of excluded records:** of the 12 excluded, 8 are in
`hr-jobs`, 3 in `it-jobs`, 1 in `legal-jobs`. Consistent with hourly and daily
rates being more common in staffing and recruitment roles, but 8 observations
are not a finding — recorded as a pattern, not published as one.

**High end — unresolved (2026-08-04):** the same gap/ratio method was
applied to the top of the range. `salary_min` 203,112 and 187,200 sit
above a clean gap before the next-highest cluster (120,000, repeated
many times); `salary_max` reaches 395,200. One of the two is a freelance
posting billed at 8–20 hrs/week, which suggests an annualised rate rather
than an annual salary — the same undeclared-periodicity defect seen at the
low end, in the opposite direction. Neither was confirmed by manual
`redirect_url` check.

**Consequence for reporting:** the mixed-periodicity defect affects both
tails. The minimum-wage threshold removes demonstrable contamination at the
low end only; contamination above the threshold is indistinguishable from
genuine figures and cannot be removed. Median is reported in preference to
mean throughout, because the distribution is skewed and only 62 distinct
values exist across 556 records.

**Range validity — confirmed clean (2026-08-04):** `salary_min >
salary_max` checked directly across all 951 postings — 0 violations.
The paired salary fields are internally consistent wherever both are
present.

Full investigation trail in `data_lineage.md`, 2026-08-04 entries.

## Reliability of text-based analysis (description field)

**Superseded 2026-08-04.** The two-tier metric approach recorded on
2026-07-06 — a primary high-confidence metric on `title`/`category` and a
secondary exploratory metric on `description` — assumed the snippet carried
usable text. Direct measurement shows it does not. The original reasoning is
retained in `data_lineage.md`, 2026-07-06 entry.

**Measured (2026-08-04, n=951):** `description` is truncated at a hard
500-character ceiling. 814 postings (85.6%) sit at exactly 500 characters;
mean length 485, minimum 142, maximum 500 with no exceptions. Only 137
postings carry untruncated text.

**Why this ends the analysis rather than qualifying it:** 500 characters is
roughly an opening paragraph. Technical requirements, certifications and
regulatory references appear later in a real posting — in the portion that
does not survive truncation. A term search over this field measures whether a
term is prominent enough to appear in the lead text, not whether the role
requires it.

The truncation is also non-random in the direction that matters: longer, more
detailed postings — typically larger employers with more regulatory
obligations — lose proportionally more text. Any prevalence figure would be a
floor biased against precisely the terms the project set out to measure. The
structural-variability problem identified on 2026-07-06 (companies open their
postings differently, so what survives correlates with writing style) still
applies, and compounds it.

**Decision:** the planned analysis of AI Act, GDPR, data governance, DPO and
data steward term prevalence is **dropped for Phase 1**. The secondary tier is
not downgraded in confidence — it has no usable corpus. The limitation is the
finding: this source does not permit measuring technical requirements from
posting text.

**Why the project does not collapse without it:** none of the other Phase 1
dimensions (salary field presence, geographic distribution, market structure,
posting staleness) depend on `description`. They rely on structured fields.

**Phase 3 impact:** the planned language-bias analysis over posting
descriptions is not viable from this endpoint either. It would require a
different source, or scraping via `redirect_url` — which carries its own legal
and ethical assessment under this project's own FRIA layer. Recorded so it is
not rediscovered later.
