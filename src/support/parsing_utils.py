"""
exploration_utils.py
Reusable helper functions for exploring Adzuna raw JSON.
These are PURE functions: they measure and classify, they do not transform
data nor write anything. Imported from exploration notebooks.

Governance note: keeping these here (not inline in the notebook) means the
logic that produces data_dictionary.md numbers lives in one versioned place,
so the measurement is reproducible across extractions.
"""

MISSING = object()  # unique sentinel: distinct from None, means "key not present at all"


def get_nested(record, dotted_path):
    """
    Read a nested value by dotted path, e.g. "company.display_name".
    Returns MISSING if the key path does not exist, so the caller can tell
    'key absent' apart from 'key present but null'. That distinction is the
    core of completeness vs structure in data_quality.md.
    """
    current = record
    for part in dotted_path.split("."):
        if isinstance(current, dict) and part in current:
            current = current[part]
        else:
            return MISSING
    return current


def classify(value):
    """
    Classify a value into one of four states for governance purposes:
      - 'absent'  : the key does not exist in the record
      - 'null'    : the key exists but is None
      - 'empty'   : present but an empty list or string
      - 'present' : present with an actual value
    Collapsing these would hide the salary-opacity signal (a null salary is
    present-but-empty at the record level, not absent).
    """
    if value is MISSING:
        return "absent"
    if value is None:
        return "null"
    if isinstance(value, (list, str)) and len(value) == 0:
        return "empty"
    return "present"


def parse_filename(filename):
    """
    Extract (category, page) from the filename convention:
      adzuna_{category}_p{page}_{date}_{time}.json
    Reading category from the filename lets us measure presence per category
    without reorganizing folders (achievability over ambition).
    The date/time in the name is our extraction timestamp = timeliness lineage.
    """
    stem = filename.replace("adzuna_", "").replace(".json", "")
    parts = stem.split("_")
    category = parts[0]   # e.g. legal-jobs
    page = parts[1]       # e.g. p3
    return category, page



