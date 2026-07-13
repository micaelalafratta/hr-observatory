"""
EDA_utils.py
Loading and EDA helper functions for the Data & Governance Labour Observatory.

Design principle (kept from the original template): each function does one
thing and can be used/tested independently from the 1_EDA.ipynb notebook.

Governance note: the loading functions READ from data/raw/ and build an
in-memory DataFrame. Flattening Adzuna's nested JSON into columns is a read
convenience for EDA — it is NOT a pipeline transform and does not modify raw
files. The column set mirrors the fields documented in data_dictionary.md.
"""
import json
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

# Reuse the helpers already written for the structural exploration — no
# duplicated logic. MISSING is the sentinel get_nested returns for absent keys.
from src.support.parsing_utils import parse_filename, get_nested, MISSING


# ── Loading (Adzuna raw JSON → single DataFrame) ───────────────────────────────

# The fields pulled into the df, with dotted paths for nested ones.
# This dict IS the data dictionary made concrete: only documented, useful
# fields enter the df. __CLASS__ and adref are excluded on purpose (both
# marked "to be dropped" in data_dictionary.md).
DF_FIELDS = {
    "id":                  "id",
    "title":               "title",
    "company":             "company.display_name",
    "category_label":      "category.label",
    "category_tag":        "category.tag",
    "location_name":       "location.display_name",
    "salary_min":          "salary_min",
    "salary_max":          "salary_max",
    "salary_is_predicted": "salary_is_predicted",
    "latitude":            "latitude",
    "longitude":           "longitude",
    "contract_type":       "contract_type",
    "contract_time":       "contract_time",
    "created":             "created",
    "description":         "description",
    "redirect_url":        "redirect_url",
}


def load_one_file(path: Path) -> list:
    """
    Read a single raw Adzuna JSON file and return its postings as a list of
    flat dicts (one per posting), ready to become df rows.

    Two governance-relevant things happen here:
    1. 'search_category' comes from the FILENAME (via parse_filename), not
       from the posting body. It records WHICH category search the posting
       came from — the variable that lets us analyse by category later
       without reopening files. (The category inside the posting can differ;
       search_category is the extraction provenance.)
    2. get_nested returns MISSING for absent keys; we map that to None so
       pandas stores NaN. This preserves the absent -> NaN mapping documented
       in data_dictionary.md (missing = absent key, never null/empty).
    """
    category, page = parse_filename(path.name)

    with open(path, encoding="utf-8") as f:
        payload = json.load(f)

    rows = []
    for offer in payload.get("results", []):
        row = {}
        for col_name, dotted_path in DF_FIELDS.items():
            value = get_nested(offer, dotted_path)
            row[col_name] = None if value is MISSING else value  # absent -> NaN
        row["search_category"] = category   # provenance from filename
        row["source_page"] = page
        rows.append(row)
    return rows


def load_all(raw_dir) -> pd.DataFrame:
    """
    Walk every adzuna_*.json file in raw_dir, load each, and concatenate into
    ONE DataFrame of all postings. This is what lets you do generic EDA (whole
    dataset) AND per-category EDA (groupby 'search_category') from a single
    object — no need to explore files one by one.

    Note: reference/ and discarded/ subfolders are NOT included — glob is
    non-recursive, so only the active pipeline files at the root of raw_dir
    are read. That matches the raw/ zoning in data_lineage.md.
    """
    raw_dir = Path(raw_dir)
    all_rows = []
    for path in sorted(raw_dir.glob("adzuna_*.json")):
        all_rows.extend(load_one_file(path))
    return pd.DataFrame(all_rows)


# ── Basic EDA ──────────────────────────────────────────────────────────────────

def eda_report(df: pd.DataFrame):
    """
    Print a structured EDA overview of the postings DataFrame.

    Adapted from a satisfaction-survey template. Two blocks from that context
    were removed because they assumed survey data and would mislead here:
      - a 0-10 "range validation" (Adzuna numerics are salaries/coordinates,
        not 0-10 scores — a 65000 salary is not out of range);
      - treating 0 as encoded missing (here, missing is NaN from an absent
        key, documented in data_dictionary.md — a 0 is not a missingness flag).
    """
    print("=" * 60)
    print("EDA REPORT")
    print("=" * 60)

    # 1. General information
    print("\nDATASET SHAPE")
    print(f"Rows: {df.shape[0]}, Columns: {df.shape[1]}")

    print("\nDATA TYPES")
    print(df.dtypes)

    # 2. Missing values
    # For this dataset, NaN == absent key in the Adzuna response (see
    # data_dictionary.md). So null counts here ARE the field-presence gaps.
    print("\nMISSING VALUES (NaN = field absent in Adzuna response)")
    nulls = df.isnull().sum().sort_values(ascending=False)
    if len(nulls[nulls > 0]) > 0:
        print(nulls[nulls > 0])
        print("\nMissing as % of rows:")
        print((df.isnull().mean() * 100).round(2).sort_values(ascending=False)
              .loc[lambda s: s > 0])
    else:
        print("No missing values.")

    # 3. Duplicates
    # 'id' is Adzuna's unique posting id — duplicates there would mean the
    # same posting captured twice (e.g. appearing on two pages). Worth a look.
    print("\nDUPLICATES")
    print(f"Duplicate rows (all columns): {df.duplicated().sum()}")
    if "id" in df.columns:
        print(f"Duplicate posting ids:       {df['id'].duplicated().sum()}")

    # 4. Descriptive statistics (numeric)
    print("\nDESCRIPTIVE STATISTICS (numeric columns)")
    numeric_cols = df.select_dtypes(include=["int64", "float64"]).columns
    if len(numeric_cols) > 0:
        print(df[numeric_cols].describe().T)
    else:
        print("No numeric columns detected (check dtypes — salary/coords may "
              "be read as object if strings).")

    # 5. Categorical overview
    # Kept from the template but capped: printing full value_counts for a
    # free-text field like 'title' or 'description' would flood the output.
    print("\nCATEGORICAL / TEXT COLUMNS (top values)")
    cat_cols = df.select_dtypes(include="object").columns
    skip_freetext = {"title", "description", "redirect_url", "id",
                     "location_name", "company"}
    for col in cat_cols:
        if col in skip_freetext:
            print(f"\n{col}: {df[col].nunique()} unique values "
                  f"(free-text/high-cardinality — value_counts skipped)")
        else:
            print(f"\n{col}")
            print(df[col].value_counts(dropna=False).head(10))

    print("\nEDA COMPLETE")


# ── Summary statistics ──────────────────────────────────────────────────────────

def summary_stats(df: pd.DataFrame, cols: list) -> pd.DataFrame:
    """
    Build a summary table for a list of numeric columns.

    Adapted from the template: the original 'zero_pct' column was removed.
    In the survey project a 0 could be missing-data-encoded-as-zero; here,
    missing is NaN from an absent key (data_dictionary.md), so null_pct is
    the meaningful missingness metric and zero_pct would only mislead.

    Columns returned:
      mean, median, std  — central tendency and spread
      min, max           — range of values
      null_pct           — % of rows with NaN (= field absent in Adzuna)
    """
    rows = []
    for col in cols:
        non_null = df[col].dropna()
        rows.append({
            "column":   col,
            "count":    non_null.shape[0],
            "mean":     round(non_null.mean(), 2) if non_null.shape[0] else np.nan,
            "median":   round(non_null.median(), 2) if non_null.shape[0] else np.nan,
            "std":      round(non_null.std(), 2) if non_null.shape[0] else np.nan,
            "min":      non_null.min() if non_null.shape[0] else np.nan,
            "max":      non_null.max() if non_null.shape[0] else np.nan,
            "null_pct": round(df[col].isna().mean() * 100, 1),
        })
    return pd.DataFrame(rows).set_index("column")
