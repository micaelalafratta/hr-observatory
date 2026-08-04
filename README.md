# Spain Data & AI Labour Observatory

> A labour-market observatory for data, technology and governance roles in Spain, built as a working demonstration of DAMA/CDMP data-governance practice applied to its own pipeline.

**Status: Phase 1 — analysis complete, publication in progress.** The extraction pipeline, BigQuery raw layer, SQL analyses and governance documentation are built and documented. Findings below are measured; every one carries its limitations alongside it.

---

## What this project is

The Spanish labour market is opaque: pay is rarely published, the real requirements behind technical roles are buried in unstructured text, and the way automation and AI regulation are reshaping demand is unevenly documented. This project measures what can honestly be measured from public job-posting data, and documents the entire pipeline with governance criteria.

It is built with three simultaneous goals:

1. Exercise a full technical stack: API extraction, profiling in Python, loading into BigQuery, SQL analysis, visualisation.
2. Demonstrate DAMA/CDMP data-management practice by documenting the process itself, not only the output.
3. Produce original analysis of the Spanish labour market with real value for employers in the sector.

### How this project handles its own data

The governance layer is not an afterthought — it is what the repository is for. Concretely, that means:

- **Every figure carries its denominator and its exclusion threshold**, declared in the analysis query itself rather than buried in code. The geographic figures use 815 locatable postings, not 951; the salary threshold is Spain's statutory minimum wage, cited to its Royal Decree.
- **The raw layer preserves the source exactly as delivered, defects included.** Duplicates, provider test records and mixed salary periodicities are loaded unfiltered, so every defect documented here stays verifiable with SQL rather than merely asserted in a markdown file.
- **Column definitions live inside the BigQuery schema**, as `OPTIONS(description=...)` on every column. The data dictionary is a projection of the live schema, so the two cannot diverge.
- **Rejected hypotheses are retained, not just conclusions.** Two salary-provenance tests were considered and discarded as non-discriminating; the reasoning is in the lineage, not only the outcome.
- **Two of six planned analyses were dropped** once the source was measured. A discarded analysis with a stated cause is a governance result, not a gap.

Full documentation: [data dictionary](./docs/data_dictionary.md) · [data quality](./docs/data_quality.md) · [data lineage](./docs/data_lineage.md)

---

## Findings

All figures come from a single extraction of 951 postings on **2026-07-06 15:20:32 UTC** across four Adzuna categories. Read the scope note below before citing any of them.

### Geographic concentration

**Madrid and Barcelona account for 49.0% of locatable postings** — 400 of 815. Valencia, Spain's third city by population, reaches 3.2%.

*Denominator is 815, not 951: `location_name` is delivered at three levels of granularity, and 136 postings carry only the country-level string "España". Cities below the top two are sensitive to individual employers — 6 of the 12 Santa Cruz de Tenerife postings come from one company. Location records where a posting is published, not whether the work is on-site; the source has no remote-work field.*

### Salary field presence

**The salary field is populated in 58.5% of postings, ranging from 70.4% (consultancy) to 43.2% (HR)** — a 27-point spread. Presence rate and salary level rank in the same order across all four categories.

| Category         | Postings | With salary value | %    | Median |
|------------------|----------|-------------------|------|--------|
| consultancy-jobs | 250      | 176               | 70.4 | 70,000 |
| legal-jobs       | 201      | 141               | 70.1 | 100,000|
| it-jobs          | 250      | 131               | 52.4 | 60,000 |
| hr-jobs          | 250      | 108               | 43.2 | 50,000 |

*This measures whether the field carries a value — **not** whether an employer chose to publish pay. Salary provenance is not determinable from Adzuna data alone: the `salary_is_predicted` flag is the constant `'0'` across all 951 records, including the 395 with no salary at all, so it carries no discriminating information. The observed pattern is equally consistent with employer behaviour and with the platform's salary coverage being better in higher-paying segments. Four categories are a pattern, not a correlation.*

*Pay periodicity is undeclared and mixed — hourly, daily, monthly and annual values share the same field. Records below Spain's statutory minimum annual wage (€17,094, RD 126/2026) are excluded from salary levels: 12 of 556, moving mean `salary_min` from €71,096 to €72,601. That threshold removes demonstrable contamination only; non-annual values above it are indistinguishable from genuine figures. Median is reported in preference to mean throughout.*

### Market structure

**344 of 468 companies (73.5%) publish a single posting.** The two highest-volume names account for 15.9% of named postings — and neither is an employer: one is a recruitment agency, the other an aggregator.

*The top 10 reach only 25.1%, just 9.2 points above the top 2, so visible concentration is almost entirely intermediary-driven. Excluding intermediaries, no employer concentration is visible: ranks 3 to 20 span 14 to 4 postings, which does not distinguish signal from noise. 91 postings (9.6%) carry no employer name at all.*

**Consequence: no employer ranking is published.** A "top companies hiring" list built on this source would measure intermediation, not demand.

### Posting staleness

**30.7% of postings returned as active were more than 30 days old at extraction time.** 16.9% exceed 90 days and 6.3% exceed one year; the oldest was published 28 months earlier, in March 2024.

*`created` records publication date, not vacancy status, and the source provides no field indicating whether a posting is still open. **This caveat qualifies every other figure above.** All of them describe what Adzuna returned as active on 2026-07-06, not verified current market demand.*

### Source coverage

**`legal-jobs` exhausted before the extraction cap.** It returned 201 postings against 250 for the other three categories, and its fifth page returned a single result against 50 on every other page. Only the legal figure reflects available market volume; 250 is a self-imposed limit, not a measurement.

---

## Analyses dropped, and why

Two planned Phase 1 analyses were discarded after measuring the source. Both are documented in full in [`docs/data_lineage.md`](./docs/data_lineage.md).

### Term prevalence (AI Act, GDPR, data governance, DPO, data steward)

`description` is truncated by the provider at a **hard 500-character ceiling**: 814 of 951 records (85.6%) sit at exactly that limit; only 137 carry full text.

500 characters is roughly an opening paragraph. Technical requirements, certifications and regulatory references appear later in a real posting — in the portion that does not survive. A term search over this field would measure whether a term is prominent enough to appear in the lead text, not whether the role requires it.

The truncation is also non-random in the direction that matters: longer, more detailed postings — typically larger employers with more regulatory obligations — lose proportionally more text. Any prevalence figure would be a floor biased against precisely the terms this project set out to measure.

**The limitation is the finding:** this source does not permit measuring technical requirements from posting text. A methodological approach previously recorded here — reporting description-based mentions as an explicitly labelled lower bound — was superseded once the ceiling was quantified. The secondary tier has no usable corpus.

### Employer ranking

Documented under Market structure above. The source provides no field distinguishing recruitment agencies from hiring employers; separating them requires editorial classification, which is deferred to Phase 2 if the ranking is ever needed.

---

## Scope note

**This project measures prevalence, not evolution.** A single extraction run captures one moment. Any claim that a term or a pattern is growing or declining is out of scope for Phase 1 and would require repeated extractions at defined intervals — planned for Phase 2.

The extraction timestamp is stored per record in `extracted_at` precisely so that repeated extractions become comparable later.

---

## Data source and scope

**Source:** [Adzuna API](https://developer.adzuna.com/) — Spain (`country = "es"`), free tier.

**Inclusion criteria:** postings are retrieved by Adzuna **category**, not by free-text keyword search. An earlier exploratory version used keyword search and was replaced: the search universe then depended on individual word choice and missed bilingual variants (a search for "data" misses "datos"; "rrhh" misses "recursos humanos"). Category-based search gives a stable, documentable universe.

Four in-scope categories:

| Category tag       | Postings | Rationale for inclusion                          |
|--------------------|----------|--------------------------------------------------|
| `it-jobs`          | 250      | Core technology and most data roles              |
| `hr-jobs`          | 250      | Hiring-algorithm and labour-governance angle     |
| `legal-jobs`       | 201      | DPO, compliance, data protection roles           |
| `consultancy-jobs` | 250      | Data governance / compliance roles in consulting |

Two categories (`accounting-finance-jobs`, `scientific-qa-jobs`) contain scattered data roles but are **excluded on purpose** in Phase 1 to keep noise low. This is logged as a completeness limitation, expandable in Phase 2.

**Universe confirmed Spanish.** 37 postings (3.9%) carry French-language titles; all are located in Spain — French-owned employers publishing in their corporate language. Language is not a proxy for market, and a bilingual ES/EN filter would have dropped these silently.

---

## Governance documentation

Written as decisions are made, not reconstructed afterwards.

- **[Data Dictionary](./docs/data_dictionary.md)** — every column defined empirically, with its measured presence rate and known limitations. Since the BigQuery table carries `OPTIONS(description=...)` on every column, this document is a *projection* of the live schema rather than a parallel file: a dictionary maintained alongside a schema diverges from it; one generated from the schema cannot.
- **[Data Quality](./docs/data_quality.md)** — completeness, consistency, validity, timeliness and accuracy documented over the project's own data, including quantified defects and declared exclusion thresholds.
- **[Data Lineage](./docs/data_lineage.md)** — a chronological record of every pipeline event and decision, **including rejected hypotheses and discarded approaches**. The keyword-search extraction was deleted but its reasoning is retained; two salary-provenance tests were considered and rejected as non-discriminating, and the rejection is recorded rather than the conclusion alone.

Planned governance work for later phases: MDM mapping between occupational taxonomies (CNO-2011, ISCO-08, Adzuna categories), and a Data Ethics / FRIA section on appropriate use and limitations.

---

## Tech stack

| Component      | Tool                          |
|----------------|-------------------------------|
| Extraction     | Python + requests             |
| Profiling      | Python + Pandas               |
| Storage        | Google BigQuery (EU region)   |
| Analysis       | SQL                           |
| Visualisation  | Power BI *(planned)*          |
| Documentation  | Markdown governance docs      |

---

## Repository structure

```
.
├── src/
│   ├── extract/        # API extraction scripts
│   ├── load/           # BigQuery load
│   └── support/        # profiling and parsing utilities
├── sql/
│   ├── schema/         # DDL, with column descriptions embedded
│   └── analysis/       # numbered analysis queries, each with its caveats
├── notebooks/          # exploratory profiling
├── data/
│   ├── raw/             # immutable raw extractions (timestamped JSON)
│   │   ├── reference/   # Adzuna category catalogue (inclusion-criteria evidence)
│   │   └── discarded/   # early test extractions, kept for transparency
│   ├── processed/       # reserved, currently empty — BigQuery loads directly
│   │                    # from raw/, so no cleaning step sits between them yet
│   └── README.md        # documents the raw/ vs processed/ split
├── docs/                # DAMA governance documentation
└── README.md
```

Every analysis query carries a header stating its purpose, its finding and its caveats — including the two that state why no finding was published. Raw data is never edited by hand: a strict extract/transform/load separation. Credentials are kept outside the repository and have never been committed.

---

## Reproducibility

The BigQuery table is defined by `sql/schema/create_adzuna_postings_raw.sql` and populated by `src/load/bigquery_load.py`. Both are versioned here, so the warehouse can be rebuilt from scratch: the repository is the durable artefact, not the infrastructure.

---

## Roadmap

- **Phase 1 (current):** documented extraction pipeline, BigQuery raw layer, SQL analysis, governance docs, public repository.
- **Phase 2:** pipeline automation and repeated extraction; incorporate INE-EPA microdata and the ILO AI-exposure index; sector-by-sector regulatory table mapped to the EU AI Act; metadata catalogue; dashboard.
- **Phase 3:** original composite "automation-pressure by sector" index; gender/automation cross-analysis; automated quarterly report.

---

## About

Built by Micaela Lafratta Ramos — Data Governance & Analytics professional, CDMP certified (DAMA International).

Portfolio: [micaelalafratta.com](https://www.micaelalafratta.com) · GitHub: [@micaelalafratta](https://github.com/micaelalafratta)
