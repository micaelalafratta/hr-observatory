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