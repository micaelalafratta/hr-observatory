-- Postings per category, and evidence of whether the 5-page cap was reached.
-- legal-jobs returned fewer results than the others: this query distinguishes
-- source exhaustion (fewer postings available) from a truncated extraction
-- (our own limit), which is a distinction the data dictionary must record.
SELECT
  search_category,
  COUNT(*)                                   AS total_postings,
  COUNT(DISTINCT id)                         AS distinct_postings,
  COUNT(DISTINCT source_page)                AS pages_retrieved,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_dataset
FROM `hr-observatory.raw.adzuna_postings_raw`
GROUP BY search_category
ORDER BY total_postings DESC;

-- Page-level counts: 50 results per page indicates the cap was binding.
-- A page returning fewer than 50 indicates the source ran out of postings.
SELECT
  search_category,
  source_page,
  COUNT(*) AS postings_on_page
FROM `hr-observatory.raw.adzuna_postings_raw`
GROUP BY search_category, source_page
ORDER BY search_category, source_page;