# Data Dictionary

> Field-by-field definitions for data extracted and transformed in this
> pipeline. Updated as decisions are made, not retroactively at the end
> of the project.

## Source: Adzuna API — job search endpoint

Fields observed empirically in test calls (Spain, query "data",
July 6 2026, n=10 then n=50). This list reflects what Adzuna *actually*
returns, which does not fully match its public documentation.

### id
- **Type:** string
- **Definition:** Adzuna's unique identifier for the job posting.
- **Presence:** always present (11/11 core fields, confirmed in both
  test samples).

### title
- **Type:** string
- **Definition:** Job title as written by the advertiser. Free text,
  not standardized — the same role can appear under many different
  titles across postings.
- **Presence:** always present.

### company
- **Type:** object (`{"display_name": "..."}`)
- **Definition:** Employer name as registered by Adzuna.
- **Known limitation:** the same company can appear with name variants
  (e.g. "BBVA" vs. "Banco BBVA"). To be handled in the transform step
  as a consistency issue, not fixed at extraction time.
- **Presence:** always present.

### category
- **Type:** object (`{"label": "...", "tag": "..."}`)
- **Definition:** Adzuna's own job category classification. This is
  the "Adzuna categories" taxonomy referenced in the MDM mapping problem
  (see project roadmap) — it does not match CNO-2011 (EPA) or ISCO-08
  (ILO).
- **Presence:** always present.

### location
- **Type:** object (`{"area": [...], "display_name": "..."}`)
- **Definition:** Hierarchical, textual location (e.g. country → region
  → city). This is more reliable than lat/long for geographic analysis
  (see Data Quality — Accuracy).
- **Presence:** always present.

### latitude / longitude
- **Type:** float
- **Definition:** Exact geographic coordinates of the posting.
- **Known limitation:** present in only ~50% of postings (25/50 in the
  July 6 2026 test). Any geographic analysis relying on these fields
  will have partial coverage — prefer `location` for broad geographic
  breakdowns (e.g. by autonomous community).
- **Presence:** inconsistent (~50%).

### created
- **Type:** string (ISO 8601 timestamp)
- **Definition:** Date and time the posting was published on Adzuna.
- **Presence:** always present.

### redirect_url
- **Type:** string (URL)
- **Definition:** Link to the original job posting.
- **Presence:** always present.

### adref
- **Type:** string
- **Definition:** Internal Adzuna ad-tracking reference, used for
  click/redirect tracking. No analytical value for this project.
- **Decision:** to be dropped in the transform step.
- **Presence:** always present.

### salary_is_predicted
- **Type:** string ("0" or "1")
- **Definition:** Indicates whether a salary value (when present) is
  an Adzuna-estimated prediction rather than a figure stated by the
  employer.
- **Presence:** always present, but only meaningful when
  `salary_min`/`salary_max` are also present.

### salary_min / salary_max
- **Type:** float
- **Definition:** Minimum and maximum salary stated or estimated for
  the posting.
- **Known limitation:** present in only 1 of 50 postings (2%) in the
  July 6 2026 test. See Data Quality — Completeness for full analysis.
  This is the central empirical evidence for the project's salary
  opacity hypothesis.
- **Presence:** rare (~2%).

### description
- **Type:** string
- **Definition:** A snippet (truncated excerpt) of the full job
  posting text — not the complete description. Confirmed as a
  structural limitation of Adzuna's free-tier API (no parameter exists
  to request the full text).
- **Known limitation (two distinct issues):**
  1. **Truncation:** any keyword-mention analysis based on this field
     (AI, governance, GDPR, etc.) is a lower bound, not a complete count.
  2. **Structural variability:** companies write postings with
     different structures (some open with company background, others
     with values, others with technical requirements), so what survives
     the truncation is not randomly distributed — it correlates with
     each company's writing style, not just with what the role requires.
- **Decision:** see Data Quality — "Reliability of text-based analysis"
  for how this project handles the field methodologically (two-tier
  metric approach, not discarded but downgraded in confidence).
- **Presence:** always present (as a snippet).

### __CLASS__
- **Type:** string
- **Definition:** Internal Adzuna metadata indicating the object type
  in their system. No analytical value.
- **Decision:** to be dropped in the transform step.
- **Presence:** always present.

### contract_type / contract_time
- **Type:** string (not yet observed)
- **Definition:** Per Adzuna's public documentation, these fields
  should indicate contract type (e.g. "permanent") and time
  arrangement (e.g. "full_time").
- **Status:** NOT observed in either test sample (n=10, n=50). To be
  monitored once the full extractor runs across more categories and
  volume — it's unclear yet whether these fields are rare (like salary)
  or simply absent from this particular query.
