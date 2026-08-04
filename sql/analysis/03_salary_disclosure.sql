-- Salary disclosure by category. This is the project's core finding: how much
-- of the Spanish market publishes pay at all. Two thresholds apply and both are
-- declared rather than hidden in the code:
--   1. Records below the statutory minimum annual wage are excluded from
--      salary levels: their periodicity is not annual (hourly, daily, monthly)
--      and the source declares no unit.
--   2. Median is reported alongside mean because the distribution is skewed
--      and only 62 distinct values exist across 556 records.


WITH salary_classification AS (
  SELECT
    search_category,
    salary_min,
    salary_min IS NOT NULL AS has_salary,
    salary_min >= 17094 AS is_usable_annual  -- Spanish SMI 2026, RD 126/2026
  FROM `hr-observatory.raw.adzuna_postings_raw`
)
SELECT
  search_category,
  COUNT(*)                                              AS total_postings,
  COUNTIF(has_salary)                                   AS with_salary,
  ROUND(COUNTIF(has_salary) / COUNT(*) * 100, 1)        AS pct_disclosing,
  COUNTIF(has_salary AND NOT is_usable_annual)          AS excluded_non_annual,
  ROUND(AVG(IF(is_usable_annual, salary_min, NULL)), 0) AS mean_salary_min,
  ROUND(APPROX_QUANTILES(IF(is_usable_annual, salary_min, NULL), 2)[OFFSET(1)], 0) AS median_salary_min
FROM salary_classification
GROUP BY search_category
ORDER BY pct_disclosing DESC;