-- Purpose: geographic distribution of postings across Spain.
-- Caveats: location_name granularity is not uniform. Country-level records
--          ("España", 136) are excluded; the denominator for city figures is
--          815 locatable postings, not 951. Long-tail cities are sensitive to
--          single employers — see the concentration check below.
-- Source:  hr-observatory.raw.adzuna_postings_raw


-- Geographic distribution. location_name granularity is NOT uniform: some values
-- are "City, Region", others are region- or country-level only. Splitting on the
-- comma without handling that produces a city ranking in which "España" appears
-- as a city. This query classifies granularity first, then ranks within it.
SELECT
  CASE
    WHEN location_name IS NULL           THEN 'missing'
    WHEN location_name = 'España'        THEN 'country_level'
    WHEN STRPOS(location_name, ',') = 0  THEN 'region_or_city_only'
    ELSE 'city_and_region'
  END AS granularity,
  COUNT(*) AS postings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1) AS pct
FROM `hr-observatory.raw.adzuna_postings_raw`
GROUP BY granularity
ORDER BY postings DESC;


-- City ranking restricted to records where a city can actually be identified.
-- The country-level records are excluded rather than silently counted, and the
-- excluded volume is reported alongside so the denominator stays honest.

WITH city_level_postings AS (
  SELECT TRIM(SPLIT(location_name, ',')[OFFSET(0)]) AS city
  FROM `hr-observatory.raw.adzuna_postings_raw`
  WHERE location_name IS NOT NULL
    AND location_name != 'España'
)
SELECT
  city,
  COUNT(*) AS postings,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1) AS pct_of_locatable
FROM city_level_postings
GROUP BY city
ORDER BY postings DESC
LIMIT 15;


-- Is a single employer driving the Tenerife volume? Concentration in one
-- company would make the figure an artefact of one hiring campaign rather
-- than a signal about the local market.
SELECT company, COUNT(*) AS postings
FROM `hr-observatory.raw.adzuna_postings_raw`
WHERE location_name LIKE 'Santa Cruz de Tenerife%'
GROUP BY company
ORDER BY postings DESC;