-- Staleness of "active" listings. The source returns as current postings
-- published up to two years earlier: the created field measures publication
-- date, not vacancy status. This is the Timeliness finding, and the only one
-- measured in the notebook but not yet reproducible from the repository.
SELECT
  COUNTIF(created < TIMESTAMP_SUB(TIMESTAMP '2026-07-06 15:20:32+00', INTERVAL 30 DAY))  AS older_than_30d,
  COUNTIF(created < TIMESTAMP_SUB(TIMESTAMP '2026-07-06 15:20:32+00', INTERVAL 90 DAY))  AS older_than_90d,
  COUNTIF(created < TIMESTAMP_SUB(TIMESTAMP '2026-07-06 15:20:32+00', INTERVAL 365 DAY)) AS older_than_1y,
  COUNT(*) AS total,
  MIN(created) AS earliest
FROM `hr-observatory.raw.adzuna_postings_raw`;