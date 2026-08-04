-- 04_description_coverage.sql
-- Purpose: measure how much posting text the source actually returns.
-- Finding: descriptions are truncated at a hard 500-character ceiling.
--          814 of 951 records (85.6%) sit exactly at that limit.
-- Outcome: the planned analysis of AI Act, GDPR and data governance term
--          prevalence was DROPPED. 500 characters cover roughly the opening
--          paragraph, so a term search would measure prominence in lead text
--          rather than whether a posting requires the skill. The truncation is
--          not random — longer, more detailed postings lose proportionally
--          more text — so any prevalence figure would be a biased floor.
-- Source:  hr-observatory.raw.adzuna_postings_raw

-- Descriptions are truncated by the provider. Before measuring term prevalence,
-- establish how much text is actually being searched: a term absent from a
-- truncated description is not evidence of absence from the real posting.
SELECT
  COUNTIF(description IS NULL)                        AS missing_descriptions,
  ROUND(AVG(LENGTH(description)), 0)                  AS mean_length,
  APPROX_QUANTILES(LENGTH(description), 2)[OFFSET(1)] AS median_length,
  MIN(LENGTH(description))                            AS min_length,
  MAX(LENGTH(description))                            AS max_length
FROM `hr-observatory.raw.adzuna_postings_raw`;


-- How many descriptions hit the 500-character ceiling? Those are truncated;
-- the rest are genuinely short. The ratio determines how much of the corpus
-- is missing, which bounds what term prevalence can mean.
SELECT
  COUNTIF(LENGTH(description) = 500) AS at_ceiling,
  COUNTIF(LENGTH(description) < 500) AS below_ceiling,
  ROUND(COUNTIF(LENGTH(description) = 500) / COUNT(*) * 100, 1) AS pct_truncated
FROM `hr-observatory.raw.adzuna_postings_raw`;