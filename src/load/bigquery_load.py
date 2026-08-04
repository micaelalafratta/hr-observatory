"""Load the raw Adzuna extraction into BigQuery.

GOVERNANCE PRINCIPLE
This script performs no cleaning. The raw layer preserves the source exactly as
delivered, so that every data quality defect documented during profiling remains
verifiable with SQL against the loaded table rather than only asserted in
documentation. Duplicates, provider test records, mixed salary periodicities and
heterogeneous location granularity are all loaded as received.

The only field added is extracted_at, which does not come from Adzuna and without
which there is no traceability of when the extraction ran.

Run from the project root:
    python -m src.load.bigquery_load
"""

from pathlib import Path

import pandas as pd
from google.cloud import bigquery

from src.support.EDA_utils import load_all

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
PROJECT_ID = "hr-observatory"
DATASET_ID = "raw"
TABLE_ID = "adzuna_postings_raw"
DESTINATION_TABLE = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"

PROJECT_ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = PROJECT_ROOT / "data" / "raw"

# Timestamp of the extraction run, taken from the raw filenames. A single value
# for all records: extracted_at describes the run, not the individual file.
# Recorded in UTC because the extraction script uses datetime.now(timezone.utc)
# and Adzuna returns created in UTC, so the whole project stays on one timezone.
EXTRACTION_RUN_TIMESTAMP = pd.Timestamp("2026-07-06 15:20:32", tz="UTC")

# Column order must match the DDL in schema/create_adzuna_postings_raw.sql.
SCHEMA_COLUMN_ORDER = [
    "id",
    "title",
    "description",
    "company",
    "redirect_url",
    "search_category",
    "category_tag",
    "category_label",
    "location_name",
    "latitude",
    "longitude",
    "salary_min",
    "salary_max",
    "salary_is_predicted",
    "contract_type",
    "contract_time",
    "created",
    "source_page",
    "extracted_at",
]


def prepare_dataframe_for_load(postings: pd.DataFrame) -> pd.DataFrame:
    """Apply the only two transformations the load requires.

    Both are representation changes, not cleaning: parsing a timestamp string
    into a timestamp type preserves the value, and extracted_at records
    provenance that the source does not supply.
    """
    prepared_postings = postings.copy()

    # created arrives as an ISO 8601 string with a Z suffix. TIMESTAMP is a
    # faithful representation of that same instant, not an interpretation of it.
    prepared_postings["created"] = pd.to_datetime(
        prepared_postings["created"], utc=True, errors="raise"
    )

    prepared_postings["extracted_at"] = EXTRACTION_RUN_TIMESTAMP

    # Fail loudly rather than loading a partial table if the DataFrame and the
    # DDL have drifted apart.
    missing_columns = set(SCHEMA_COLUMN_ORDER) - set(prepared_postings.columns)
    unexpected_columns = set(prepared_postings.columns) - set(SCHEMA_COLUMN_ORDER)
    if missing_columns or unexpected_columns:
        raise ValueError(
            f"Schema mismatch. Missing: {sorted(missing_columns)}. "
            f"Unexpected: {sorted(unexpected_columns)}."
        )

    return prepared_postings[SCHEMA_COLUMN_ORDER]


def load_postings_to_bigquery(prepared_postings: pd.DataFrame) -> None:
    """Load the DataFrame into the existing table.

    WRITE_EMPTY makes the job fail if the table already contains rows. This is
    deliberate: an accidental second run would otherwise silently double every
    count and invalidate the field-presence percentages already documented.
    To reload intentionally, change to WRITE_TRUNCATE.
    """
    bigquery_client = bigquery.Client(project=PROJECT_ID)

    # No schema is declared here. The destination table already defines it,
    # including the column descriptions, so the load validates against the DDL
    # instead of overwriting it with an inferred schema.
    job_configuration = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_EMPTY,
        autodetect=False,
    )

    load_job = bigquery_client.load_table_from_dataframe(
        prepared_postings, DESTINATION_TABLE, job_config=job_configuration
    )
    load_job.result()  # Blocks until the job finishes, raising on failure.

    loaded_table = bigquery_client.get_table(DESTINATION_TABLE)
    print(f"Loaded {loaded_table.num_rows} rows into {DESTINATION_TABLE}")


def main() -> None:
    postings = load_all(RAW_DIR)
    print(f"Read {len(postings)} records from {RAW_DIR}")

    prepared_postings = prepare_dataframe_for_load(postings)
    print(f"Prepared {len(prepared_postings)} records, "
          f"{len(prepared_postings.columns)} columns")

    load_postings_to_bigquery(prepared_postings)


if __name__ == "__main__":
    main()

