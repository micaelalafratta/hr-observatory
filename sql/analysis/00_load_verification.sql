-- 00_load_verification.sql
-- Purpose: reconcile the loaded table against the profiling done in pandas.
-- Expected: 951 rows, 947 distinct ids, 556 with salary, 91 without company,
--           790 with coordinates, 0 with contract_type, 27 with contract_time,
--           created spanning 2024-03-08 to 2026-07-06.
-- Rationale: the raw layer must not alter the source. A mismatch on any figure
--            means the load transformed the data and must be investigated
--            before any analysis is built on it.
-- Source:   hr-observatory.raw.adzuna_postings_raw

-- Load verification: every figure must match the profiling done in the notebook.
-- A mismatch means the load altered the data, which the raw layer must not do.
SELECT
  COUNT(*)                                        AS total_rows,
  COUNT(DISTINCT id)                              AS distinct_ids,
  COUNTIF(salary_min IS NOT NULL)                 AS with_salary,
  COUNTIF(company IS NULL)                        AS without_company,
  COUNTIF(latitude IS NOT NULL)                   AS with_coordinates,
  COUNTIF(contract_type IS NOT NULL)              AS with_contract_type,
  COUNTIF(contract_time IS NOT NULL)              AS with_contract_time,
  MIN(created)                                    AS earliest_posting,
  MAX(created)                                    AS latest_posting,
  MIN(extracted_at)                               AS extraction_run
FROM `hr-observatory.raw.adzuna_postings_raw`;