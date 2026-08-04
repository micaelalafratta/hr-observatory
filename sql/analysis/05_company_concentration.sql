-- Top companies by posting volume. Two caveats are built into the query rather
-- than left to the reader:
--   1. Company names carry case and whitespace variants (6 normalisation keys
--      had more than one spelling), so grouping uses a normalised key.
--   2. Many high-volume names are recruitment agencies or aggregators, not
--      hiring employers. The classification below is editorial, not derived
--      from the data, and is declared as such.

WITH normalised_companies AS (
  SELECT
    TRIM(LOWER(company)) AS company_key,
    ANY_VALUE(company)   AS company_display,
    search_category
  FROM `hr-observatory.raw.adzuna_postings_raw`
  WHERE company IS NOT NULL
  GROUP BY company_key, search_category, id
)
SELECT
  ANY_VALUE(company_display)              AS company,
  COUNT(*)                                AS postings,
  COUNT(DISTINCT search_category)         AS categories_present,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_named
FROM normalised_companies
GROUP BY company_key
ORDER BY postings DESC
LIMIT 20;

-- Concentration: how much of the dataset a handful of names accounts for.
-- 91 postings (9.6%) carry no company at all and are excluded from the
-- denominator, which must be stated wherever these percentages appear.
WITH company_volumes AS (
  SELECT TRIM(LOWER(company)) AS company_key, COUNT(*) AS postings
  FROM `hr-observatory.raw.adzuna_postings_raw`
  WHERE company IS NOT NULL
  GROUP BY company_key
)
SELECT
  COUNT(*)                                                      AS distinct_companies,
  SUM(postings)                                                 AS named_postings,
  ROUND(SUM(IF(rank_position <= 2, postings, 0)) / SUM(postings) * 100, 1)  AS pct_top_2,
  ROUND(SUM(IF(rank_position <= 10, postings, 0)) / SUM(postings) * 100, 1) AS pct_top_10,
  COUNTIF(postings = 1)                                         AS companies_with_one_posting
FROM (
  SELECT *, ROW_NUMBER() OVER (ORDER BY postings DESC) AS rank_position
  FROM company_volumes
);


-- Non-Spanish postings: French and international employers appear in a Spain
-- endpoint. Quantifies whether the dataset universe is actually the Spanish market.
SELECT
  COUNTIF(REGEXP_CONTAINS(LOWER(title), r'\bf/h\b|\bh/f\b|en stage|chargé|responsable de secteur')) AS french_pattern_titles,
FROM `hr-observatory.raw.adzuna_postings_raw`;


-- Are the French-pattern titles located in Spain or elsewhere? A Spanish
-- location means bilingual postings by French-owned employers; a foreign one
-- means the endpoint's universe is not strictly the Spanish market.
SELECT location_name, company, COUNT(*) AS postings
FROM `hr-observatory.raw.adzuna_postings_raw`
WHERE REGEXP_CONTAINS(LOWER(title), r'\bf/h\b|\bh/f\b|en stage|chargé|responsable de secteur')
GROUP BY location_name, company
ORDER BY postings DESC
LIMIT 15;
