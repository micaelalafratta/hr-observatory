# Data Quality Dimensions

> Explicit documentation of completeness, consistency, timeliness, and
> accuracy over this project's own data — following DAMA data quality
> dimensions.

## Completeness

**Salary (`salary_min` / `salary_max`):** in a test of 50 postings
obtained via a broad search ("data", Spain, page 1 of the Adzuna API,
July 6 2026), only 1 of 50 (2%) included salary data. The rest have the
field completely absent (not present as null — the key doesn't exist
at all). This finding is consistent with an earlier test of 10 results,
where 0 of 10 had salary data. It confirms the structural salary
opacity hypothesis that motivates this project.

*Sample caveat: small, non-random sample (a single search, a single
page). The percentage should be reassessed at higher volume once the
full extractor is built and run across multiple categories.*

## Consistency

*Pending: to be documented once the transform step handles company
name variants (e.g. "BBVA" vs. "Banco BBVA") — see `company` field in
data_dictionary.md.*

## Timeliness

*Pending: to be documented once extraction frequency is defined for
each source (Adzuna vs. quarterly EPA downloads vs. annual ILO index).*

## Accuracy

**Geocoding (`latitude` / `longitude`):** present in roughly 50% of
postings (25/50 in the July 6 2026 test). The remaining postings still
include a textual/hierarchical location (the `location` field, always
present), but without exact coordinates.

**Implication:** any geographic analysis relying on lat/long will have
partial coverage; analysis by autonomous community is more reliable if
based on `location` rather than coordinates.

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
