-- 06_posting_staleness.sql
-- Purpose: how much of what the source returns as active is actually recent.
-- Finding: 292 of 951 postings (30.7%) are more than 30 days old at extraction
--          time, 161 (16.9%) more than 90 days, 60 (6.3%) more than one year.
--          Earliest is 2024-03-08, 28 months before extraction.
-- Caveat:  `created` records publication date, not vacancy status. The source
--          provides no field indicating whether a posting is still open, so
--          all project figures describe what the source returned as active on
--          2026-07-06, not verified current demand.
-- Source:  hr-observatory.raw.adzuna_postings_raw

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