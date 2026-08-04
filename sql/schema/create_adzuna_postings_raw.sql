-- =============================================================================
-- Table: adzuna_postings_raw
-- Layer:  raw
-- Source: Adzuna API (adzuna.es), category-based extraction, 5 pages per category
--
-- GOVERNANCE PRINCIPLE FOR THIS LAYER
-- The raw layer preserves the source exactly as delivered, defects included.
-- No deduplication, no unit correction, no name normalisation, no filtering.
-- Every cleaning decision belongs in the staging layer, so that the defects
-- documented during profiling remain verifiable against the loaded data.
--
-- All column descriptions below record measured values from the profiling of
-- the initial extraction (n = 951 rows, 947 distinct posting ids).
-- =============================================================================

CREATE TABLE `hr-observatory.raw.adzuna_postings_raw`
(
  -- ---------------------------------------------------------------------------
  -- Identity
  -- ---------------------------------------------------------------------------
  id STRING NOT NULL
    OPTIONS(description =
      "Adzuna posting identifier. Typed as STRING, not INT64: this is an external identifier, not a quantity, and must not be arithmetically manipulated or stripped of leading characters. Present in 100% of records. Not unique in the raw layer: 4 of 951 rows repeat an id because Adzuna pagination is not stable across requests, so a posting can reappear on a later page. Duplicates are byte-identical except for source_page. Deduplication is a staging-layer decision."),

  -- ---------------------------------------------------------------------------
  -- Descriptive content
  -- ---------------------------------------------------------------------------
  title STRING
    OPTIONS(description =
      "Job title as published. 910 distinct values across 951 rows. Free text, no controlled vocabulary. Contains provider test records: titles matching 'Contract Dummy Job' and 'Job for testing' are Adzuna test data that leaked into the production response and are not real vacancies."),

  description STRING
    OPTIONS(description =
      "Posting description as returned by the API. Truncated by the provider: full advertisement text is not available through this endpoint. Suitable for keyword prevalence analysis (GDPR, AI Act, data governance, DPO, data steward) but not for any analysis requiring complete text."),

  company STRING
    OPTIONS(description =
      "Employer name as published. Absent in 91 of 951 records (9.57%): Adzuna omits the key entirely rather than returning null or an empty string. 474 distinct raw spellings, of which 6 normalisation keys carry more than one spelling (case and trailing-whitespace variants such as 'ERM' / 'Erm'), giving 468 distinct entities. Values are frequently recruitment agencies or aggregators rather than hiring employers: the two most frequent names account for 14.2% of all postings. Any 'top employers' analysis must declare this."),

  redirect_url STRING
    OPTIONS(description =
      "Adzuna redirection URL to the original listing. Used for manual verification of individual records during profiling. Not a stable long-term reference: listings expire."),

  -- ---------------------------------------------------------------------------
  -- Classification
  -- ---------------------------------------------------------------------------
  search_category STRING
    OPTIONS(description =
      "Category requested from the API by the extraction script. Provenance: this project, not Adzuna. Four values: it-jobs, hr-jobs, legal-jobs, consultancy-jobs. Counts are 250 / 250 / 201 / 250. The legal-jobs shortfall is source exhaustion, not truncated extraction: page 5 returned a single result against the 50 returned for every other page."),

  category_tag STRING
    OPTIONS(description =
      "Category assigned to the posting by Adzuna in its response. Provenance: the provider. Identical to search_category in 100% of records in this extraction. Retained despite the redundancy because the two fields record different things — one a request parameter, one a provider classification — and divergence in a future extraction would itself be a finding."),

  category_label STRING
    OPTIONS(description =
      "Human-readable category name returned by the provider, in Spanish (for example 'Trabajos en informática'). Display label only; category_tag is the machine-readable equivalent."),

  -- ---------------------------------------------------------------------------
  -- Location
  -- ---------------------------------------------------------------------------
  location_name STRING
    OPTIONS(description =
      "Location display name as delivered. Granularity is NOT uniform and this is the field's principal limitation: 307 of 951 values (32.3%) contain no comma and are region- or country-level only, including 136 records whose entire location is 'España'. Where a comma is present the format is 'City, Region'. Splitting on the comma without first handling the no-comma cases produces a city ranking in which 'España' appears as a city. The API also returns a hierarchical location array that this extraction did not retain; it is recoverable from the raw JSON files if finer granularity is required later."),

  latitude FLOAT64
    OPTIONS(description =
      "Latitude of the posting location. Present in 790 of 951 records (83.1%). Absent where the provider supplies no coordinates."),

  longitude FLOAT64
    OPTIONS(description =
      "Longitude of the posting location. Present in 790 of 951 records (83.1%), co-occurring with latitude."),

  -- ---------------------------------------------------------------------------
  -- Compensation
  -- ---------------------------------------------------------------------------
  salary_min FLOAT64
    OPTIONS(description =
      "Lower salary bound as delivered. Present in 556 of 951 records (58.5%), with presence varying by category from 43.2% (hr-jobs) to 70.4% (consultancy-jobs). CRITICAL LIMITATION: pay periodicity is undeclared and mixed. Values are variously hourly, daily, monthly and annual with no field distinguishing them, and the same mixing affects both tails — 12 records fall below the Spanish statutory minimum annual wage, and 2 records above 150,000 are annualised freelance rates. Values below the statutory minimum are excluded from aggregate analysis; contamination above that threshold is indistinguishable from genuine figures and cannot be removed. Only 62 distinct values across 556 records, heavily clustered on round figures. Report median in preference to mean."),

  salary_max FLOAT64
    OPTIONS(description =
      "Upper salary bound as delivered. Co-occurs with salary_min in all 556 records where a salary is present. Subject to the same undeclared periodicity mixing. Validity check passed: no record has salary_min greater than salary_max."),

  salary_is_predicted STRING
    OPTIONS(description =
      "Provider flag intended to indicate whether the salary is estimated rather than employer-stated. Typed as STRING to preserve the source representation. NOT INFORMATIVE in this extraction: the value is the literal string '0' in 100% of records, including all 395 records that carry no salary at all. A field with zero variance, present even where the concept does not apply, cannot discriminate provenance. Salary provenance therefore remains undeterminable from Adzuna data alone."),

  -- ---------------------------------------------------------------------------
  -- Contract terms
  -- ---------------------------------------------------------------------------
  contract_type STRING
    OPTIONS(description =
      "Contract type (permanent / contract). STRUCTURALLY EMPTY: absent in 951 of 951 records (100%). Retained in the schema deliberately rather than omitted, so that a future extraction in which the provider begins populating the field requires no schema migration, and so that its absence is recorded as a completeness finding rather than lost as missing information."),

  contract_time STRING
    OPTIONS(description =
      "Working time. Present in 27 of 951 records (2.8%). Observed values: full_time, part_time. Coverage is too sparse to support any analysis of working-time distribution; the sparsity is itself the finding."),

  -- ---------------------------------------------------------------------------
  -- Temporal
  -- ---------------------------------------------------------------------------
  created TIMESTAMP
    OPTIONS(description =
      "Publication timestamp of the posting. Delivered as an ISO 8601 UTC string and parsed at load; all 951 values parsed without error. Observed range spans from 2024-03-08 to 2026-07-06, and 161 records (16.9%) were more than 90 days old at extraction time. Listings returned as active therefore include substantially stale postings: this field measures publication date, not current vacancy status."),

  -- ---------------------------------------------------------------------------
  -- Extraction provenance
  -- ---------------------------------------------------------------------------
  source_page STRING
    OPTIONS(description =
      "API result page from which the record was retrieved (p1 to p5). Provenance: this project, not Adzuna. Records the extraction position and is the only field distinguishing the 4 duplicated ids. Page counts are 50 per page for every category except legal-jobs page 5, which returned 1."),

  extracted_at TIMESTAMP
    OPTIONS(description =
      "Timestamp at which the extraction run was executed. Provenance: this project, not Adzuna. Distinguishes extraction runs once loading becomes repeated, and is the reference point against which the staleness of the created field is measured. Without it the dataset supports prevalence analysis only, never analysis of change over time.")
)
OPTIONS(
  description =
    "Job postings extracted from the Adzuna Spain API by category (it-jobs, hr-jobs, legal-jobs, consultancy-jobs), 5 pages per category, 50 results per page. Raw layer: the source is preserved as delivered, including duplicates, provider test records, mixed salary periodicities and heterogeneous location granularity. All cleaning occurs downstream. Field-level descriptions record measured values from the profiling of the initial extraction (n = 951). Not partitioned or clustered: at this volume partition pruning would provide no benefit, and an unjustified partitioning scheme would be decoration rather than design. Revisit if the table grows past a scale where full scans become material."
);
