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

## Consistency

*Pending: to be documented once the transform step handles company
name variants (e.g. "BBVA" vs. "Banco BBVA") — see `company` field in
data_dictionary.md.*

## Timeliness

*Pending: to be documented once extraction frequency is defined for
each source (Adzuna vs. quarterly EPA downloads vs. annual ILO index).*

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
