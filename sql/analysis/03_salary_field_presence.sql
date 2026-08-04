-- 03_salary_field_presence.sql
-- Purpose: how often the salary field carries a value, and at what level.
-- Finding: presence ranges from 70.4% (consultancy) to 43.2% (HR), a 27-point
--          gap. Presence rate and salary level rank in the same order across
--          all four categories.
-- Framing: this measures whether the field is POPULATED, not whether an
--          employer chose to publish pay. Salary provenance is not
--          determinable from Adzuna data alone (see data_quality.md,
--          Accuracy), so "disclosure" would be an unsupported attribution.
--          The observed pattern is equally consistent with employer behaviour
--          (lower-paying roles publish pay less often) and with source
--          behaviour (Adzuna salary coverage is better in higher-paying
--          segments). Four categories are a pattern, not a correlation.
-- Caveats: pay periodicity is undeclared and mixed (hourly, daily, monthly,
--          annual). Records below the 2026 statutory minimum annual wage
--          (€17,094, RD 126/2026) are excluded from salary levels; 12 records
--          in total, 8 of them in hr-jobs. Contamination above that threshold
--          is indistinguishable from genuine figures. Medians reflect only
--          postings carrying a value: if the gap is employer-driven they are
--          inflated and real gaps are wider, but the direction of the bias
--          cannot be established.
-- Source:  hr-observatory.raw.adzuna_postings_raw

-- Salary field presence by category. Two thresholds apply and both are
-- declared here rather than hidden in the code:
--   1. Records below the statutory minimum annual wage are excluded from
--      salary levels: their periodicity is not annual (hourly, daily,
--      monthly) and the source declares no unit.
--   2. Median is reported alongside mean because the distribution is skewed
--      and only 62 distinct values exist across 556 records.

WITH salary_classification AS (
  SELECT
    search_category,
    salary_min,
    salary_min IS NOT NULL AS has_salary_value,
    salary_min >= 17094 AS is_usable_annual  -- Spanish SMI 2026, RD 126/2026
  FROM `hr-observatory.raw.adzuna_postings_raw`
)
SELECT
  search_category,
  COUNT(*)                                                    AS total_postings,
  COUNTIF(has_salary_value)                                   AS with_salary_value,
  ROUND(COUNTIF(has_salary_value) / COUNT(*) * 100, 1)        AS pct_with_salary_value,
  COUNTIF(has_salary_value AND NOT is_usable_annual)          AS excluded_non_annual,
  ROUND(AVG(IF(is_usable_annual, salary_min, NULL)), 0)       AS mean_salary_min,
  ROUND(APPROX_QUANTILES(IF(is_usable_annual, salary_min, NULL), 2)[OFFSET(1)], 0) AS median_salary_min
FROM salary_classification
GROUP BY search_category
ORDER BY pct_with_salary_value DESC;