# Spain Data & AI Labour Observatory

> A labour-market observatory for data, technology and governance roles in Spain, built as a working demonstration of DAMA/CDMP data-governance practice applied to its own pipeline.

**Status: Phase 1 — in progress.** This repository currently contains the foundation and extraction layer: a documented, reproducible pipeline and its governance documentation. Analysis and findings are being added as the project advances. Nothing here is presented as a finished result unless it is labelled as one.

---

## What this project is

The Spanish labour market is opaque: salaries are rarely disclosed, the real requirements behind technical roles are buried in unstructured text, and the way automation and AI regulation are reshaping demand is unevenly documented. This project measures that with real job-posting data and documents the entire pipeline with governance criteria.

It is built with three simultaneous goals:

1. Exercise a full technical stack: API extraction, cleaning in Python, loading into BigQuery, SQL analysis, visualisation.
2. Demonstrate DAMA/CDMP data-management practice by documenting the process itself, not only the output.
3. Produce original analysis of the Spanish labour market with real value for employers in the sector.

The governance layer is not an afterthought — it is the point. Every extraction, cleaning and scope decision is recorded as it is made, with its rationale, so the repository reads as evidence of *how* data is managed, not just *what* was found.

---

## Current status (what is built)

- **Repository scaffolding** with an extract / transform / load structure and a documented Python virtual environment.
- **Adzuna API integration validated.** Category catalogue downloaded and stored as reference evidence of the inclusion criteria.
- **First full extraction complete.** ~1,000 raw job postings extracted across four categories, saved as immutable timestamped JSON, with an integrity check confirming no pages were lost.
- **Three core governance documents** written and kept current with every decision: data dictionary, data quality, data lineage.

### Not yet built (planned)

- Transform step (cleaning, bilingual keyword filtering, deduplication)
- BigQuery schema and load
- SQL analysis and first findings
- Visualisation dashboard

---

## Data source and scope

**Source:** [Adzuna API](https://developer.adzuna.com/) — Spain (`country = "es"`), free tier.

**Inclusion criteria:** postings are retrieved by Adzuna **category**, not by free-text keyword search. An earlier exploratory version used keyword search and was replaced: the search universe then depended on individual word choice and missed bilingual variants (a search for "data" misses "datos"; "rrhh" misses "recursos humanos"). Category-based search gives a stable, documentable universe.

Four in-scope categories:

| Category tag       | Rationale for inclusion                          |
|--------------------|--------------------------------------------------|
| `it-jobs`          | Core technology and most data roles              |
| `hr-jobs`          | Hiring-algorithm and labour-governance angle     |
| `legal-jobs`       | DPO, compliance, data protection roles           |
| `consultancy-jobs` | Data governance / compliance roles in consulting |

Two categories (`accounting-finance-jobs`, `scientific-qa-jobs`) contain scattered data roles but are **excluded on purpose** in Phase 1 to keep noise low. This is logged as a completeness limitation, expandable in Phase 2.

Data / AI / governance relevance is filtered downstream in the transform step via bilingual (ES/EN) keyword matching — not at the API level.

---

## Key finding so far

Even at the extraction-validation stage, the data confirms the hypothesis that motivates the project:

- **Salary is present in roughly 2% of postings.** The field is absent, not null — most employers disclose no salary at all. This is the central empirical evidence for the structural salary-opacity thesis.
- **Geographic coordinates appear in only ~50% of postings.** Broad geographic analysis is more reliable using the textual `location` field than exact coordinates.
- **The `description` field is a truncated snippet, not full text.** Any keyword analysis on it is treated as a lower bound, never as a complete count.

*These percentages come from extraction-validation samples and will be re-measured against the full extracted volume before being treated as settled.*

---

## Governance layer (DAMA/CDMP)

This is the differentiating part of the project. Documentation lives in [`docs/`](./docs) and is written as decisions are made, not reconstructed afterwards.

- **[Data Dictionary](./docs/data_dictionary.md)** — every extracted field defined empirically, with its real presence rate and known limitations. Reflects what Adzuna *actually* returns, which does not fully match its public documentation.
- **[Data Quality](./docs/data_quality.md)** — completeness, consistency, timeliness and accuracy documented over the project's own data, including an extraction-integrity check and the trade-offs accepted in scoping.
- **[Data Lineage](./docs/data_lineage.md)** — a chronological record of every pipeline event and decision, including the discarded keyword-search approach: the raw files were deleted, but the reasoning is retained.

A **two-tier confidence approach** governs text analysis: mentions found in structured fields (`title`, `category`) are reported as high-confidence; mentions in the truncated `description` are reported separately as an explicit lower bound. Structured-field findings do not depend on the description being reliable.

Planned governance work for later phases: MDM mapping between occupational taxonomies (CNO-2011, ISCO-08, Adzuna categories), and a Data Ethics / FRIA section on appropriate use and limitations.

---

## Tech stack

| Component      | Tool                          |
|----------------|-------------------------------|
| Extraction     | Python + requests             |
| Cleaning       | Python + Pandas               |
| Storage        | Google BigQuery               |
| Visualisation  | Looker Studio *(planned)*     |
| Documentation  | Markdown governance docs      |

---

## Repository structure

```
.
├── src/
│   ├── extract/        # API extraction scripts
│   ├── transform/      # cleaning & filtering (planned)
│   └── load/           # BigQuery load (planned)
├── data/
│   └── raw/            # immutable raw extractions (timestamped JSON)
│       ├── reference/  # Adzuna category catalogue (inclusion-criteria evidence)
│       └── discarded/  # early test extractions, kept for transparency
├── docs/               # DAMA governance documentation
└── README.md
```

Raw data is never edited by hand — a strict extract/transform/load separation. Credentials are kept outside the repository and are never committed.

---

## Roadmap

- **Phase 1 (current):** documented extraction pipeline, governance docs, SQL analysis, public repository.
- **Phase 2:** pipeline automation; incorporate INE-EPA microdata and the ILO AI-exposure index; sector-by-sector regulatory table mapped to the EU AI Act; dashboard.
- **Phase 3:** original composite "automation-pressure by sector" index; gender/automation cross-analysis; automated quarterly report.

---

## About

Built by Micaela Lafratta Ramos — Data Analyst & Data Governance professional, CDMP certified (DAMA International).

Portfolio: [micaelalafratta.com](https://www.micaelalafratta.com) · GitHub: [@micaelalafratta](https://github.com/micaelalafratta)
