#!/usr/bin/env python3
"""Compare two SPAR rosters of the same segment: counts, overlap, and a fact-check sample.

Implements half two (the fact-check sample) and half three (the counts that need no
judgement) of METHOD.md in this directory. Half one (blind quality judging) is a
separate, human/agent process and is not this script's job.

MATCHING RULE. Rows are matched on (normalised organisation name, postcode), not on
`stem`. `stem` is rejected as a join key because it is coined independently by each
sweep: two arms that find the same business will very often name it differently
(e.g. "casey-armstrong-drayhorse" vs "drayhorse-shires-casey-armstrong"), so a stem
join reports near-total non-overlap between two rosters that in fact agree, and the
count is meaningless as a result. Matching on organisation name is the closest thing
to a shared key the two arms actually agree on, provided the name is normalised first,
since one sweep will write "Smith Stables Pty Ltd" and the other "The Smith Stables"
for the same business. Postcode is included in the key because organisation names are
short and generic enough (e.g. "Riverside Stables") that two unrelated businesses in
different towns can collide on name alone.

Normalisation: fold to lower case, strip all punctuation, collapse whitespace, then
drop a leading "the" and drop trailing/embedded company-suffix words (pty, ltd,
limited, inc, incorporated, llc, co) that the two sweeps routinely disagree on
whether to include.

THE COLLISION GUARD. Some rosters carry rows whose "organisation" column is not a
business name at all but a category label, e.g. "QOTT Acknowledged Retrainer" in
`supplier-horse-rehoming`, with the actual identity sitting in `contact_name`. Under
(organisation, postcode) alone, several such rows collapse into one key, and a key
that is not unique within a single roster cannot identify a business across two. So
each roster is checked on its own for (organisation, postcode) keys that more than
one of its rows share. Where a key collides in EITHER roster, every row carrying that
key, in both rosters, is matched on the longer key (organisation, postcode, normalised
contact name) instead. Checking both rosters, not just the one under comparison, is
what keeps a business matching across the two when the collision only shows up on one
side: the other roster's rows for the same organisation/postcode may look unique in
isolation, but they must be keyed the same way as their colliding counterpart or the
join misses them. The contact name is normalised the same way as the organisation
name, minus the company-suffix stripping, since a suffix like "Pty Ltd" belongs to a
company, not a person.

THE SAMPLE (half two). Under --sample, print up to 8 rows per roster (or every row,
whichever file holds fewer than 8), chosen by sorting the roster's rows by `stem` and
then taking evenly spaced indices across that sorted order, so the picked rows span
the file and the same file always yields the same sample regardless of who runs this
or when.
"""
import argparse
import csv
import re
import sys
from collections import Counter

REQUIRED_COLUMNS = [
    "stem", "contact_name", "organisation", "role", "phone", "email",
    "linkedin_url", "facebook_url", "sweep_iteration", "discovered_via",
    "date_excluded", "s_note", "p_note", "star_rating", "postcode",
]

SUFFIX_WORDS = {"pty", "ltd", "limited", "inc", "incorporated", "llc", "co"}
LEADING_ARTICLES = {"the"}


def _normalise(name, strip_suffixes):
    """Fold case, strip punctuation, drop a leading article, and, if asked,
    company-suffix words."""
    name = name.lower()
    name = re.sub(r"[^a-z0-9\s]", " ", name)
    words = name.split()
    if strip_suffixes:
        words = [w for w in words if w not in SUFFIX_WORDS]
    if words and words[0] in LEADING_ARTICLES:
        words = words[1:]
    return " ".join(words)


def normalise_organisation(name):
    """Fold case, strip punctuation, and drop company suffixes / leading articles."""
    return _normalise(name, strip_suffixes=True)


def normalise_contact_name(name):
    """Same normalisation as an organisation name, minus company-suffix stripping."""
    return _normalise(name, strip_suffixes=False)


def read_roster(path):
    """Read a roster TSV, returning its rows as a list of dicts.

    Fails loudly if a required column is missing. Blank lines are skipped rather
    than counted as rows.
    """
    with open(path, newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        if reader.fieldnames is None:
            sys.exit(f"error: {path}: file has no header row")
        missing = [c for c in REQUIRED_COLUMNS if c not in reader.fieldnames]
        if missing:
            sys.exit(
                f"error: {path}: missing expected column(s): {', '.join(missing)}"
            )
        rows = []
        for row in reader:
            if any(value is not None and value.strip() for value in row.values()):
                rows.append(row)
    return rows


def base_key(row):
    return (normalise_organisation(row["organisation"]), row["postcode"].strip())


def colliding_base_keys(rows):
    counts = Counter(base_key(r) for r in rows)
    return {key for key, count in counts.items() if count > 1}


def match_key(row, collisions):
    """The join key for a row.

    A base key that is unique in both rosters is used as-is. A base key that
    collides in either roster is not safe to identify a business by, in that
    roster or the other one, so every row carrying it, on both sides, is keyed
    with the normalised contact name added.
    """
    key = base_key(row)
    if key in collisions:
        return key + (normalise_contact_name(row["contact_name"]),)
    return key


def evenly_spaced_sample(rows, sample_size=8):
    """Pick up to sample_size rows, sorted by stem, spread evenly across the file."""
    ordered = sorted(rows, key=lambda r: r["stem"])
    n = len(ordered)
    if n <= sample_size:
        return ordered
    # Evenly spaced indices across [0, n-1], including both ends, deterministic.
    indices = sorted({round(i * (n - 1) / (sample_size - 1)) for i in range(sample_size)})
    # Rounding can collapse two targets onto the same index on a short, uneven span;
    # top up from the unused indices, in order, to keep the sample at sample_size.
    if len(indices) < sample_size:
        unused = [i for i in range(n) if i not in indices]
        indices = sorted(set(indices) | set(unused[: sample_size - len(indices)]))
    return [ordered[i] for i in indices]


def describe_row(row):
    return f"{row['organisation']} ({row['postcode']}) [{row['stem']}]"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("control", help="path to the control roster TSV")
    parser.add_argument("local", help="path to the local-arm roster TSV")
    parser.add_argument(
        "--sample", action="store_true",
        help="also print the fact-check sample (up to 8 evenly spaced rows per roster)",
    )
    args = parser.parse_args()

    control_rows = read_roster(args.control)
    local_rows = read_roster(args.local)

    collisions = colliding_base_keys(control_rows) | colliding_base_keys(local_rows)

    control_keys = {match_key(r, collisions): r for r in control_rows}
    local_keys = {match_key(r, collisions): r for r in local_rows}

    both = set(control_keys) & set(local_keys)
    only_control = set(control_keys) - set(local_keys)
    only_local = set(local_keys) - set(control_keys)

    print(f"control roster: {args.control}")
    print(f"  rows: {len(control_rows)}")
    print(f"local roster:   {args.local}")
    print(f"  rows: {len(local_rows)}")
    print()
    print(f"in both:        {len(both)}")
    print(f"only in control: {len(only_control)}")
    print(f"only in local:   {len(only_local)}")

    if only_control:
        print()
        print("unique to control:")
        for key in sorted(only_control):
            print(f"  {describe_row(control_keys[key])}")

    if only_local:
        print()
        print("unique to local:")
        for key in sorted(only_local):
            print(f"  {describe_row(local_keys[key])}")

    if args.sample:
        print()
        print("fact-check sample, control:")
        for row in evenly_spaced_sample(control_rows):
            print(f"  {describe_row(row)}")
        print()
        print("fact-check sample, local:")
        for row in evenly_spaced_sample(local_rows):
            print(f"  {describe_row(row)}")


if __name__ == "__main__":
    main()
