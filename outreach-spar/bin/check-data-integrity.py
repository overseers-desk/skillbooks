#!/usr/bin/env python3
from __future__ import annotations
"""Check SPAR campaign roster data integrity.

Validates roster files against the canonical column set (spar-roster-format.md)
and quality checklist (SPAR-S §10).  Reports structural problems, content gaps,
file completeness, and cross-segment duplicates.

Usage:
    python3 bin/check-data-integrity.py campaign-2026-04.yaml
"""
import argparse
import csv
import io
import os
import re
import sys
import unicodedata
from pathlib import Path

# ── Required columns (from spar-roster-format.md §Core columns) ──────────
REQUIRED_COLUMNS = [
    "organisation",
    "contact_name",
    "role",
    "phone",
    "email",
    "linkedin_url",
    "facebook_url",
    "sweep_iteration",
    "discovered_via",
    "discovery_source",
    "verified",
    "date_found_invalid",
]

parser = argparse.ArgumentParser(
    description="Check SPAR campaign roster data integrity.",
    formatter_class=argparse.RawDescriptionHelpFormatter,
)
parser.add_argument(
    "campaign",
    nargs="?",
    default=None,
    help="Campaign YAML file (default: auto-discover campaign*.yaml in cwd).",
)
parser.add_argument(
    "--skip",
    nargs="*",
    metavar="SEGMENT",
    default=None,
    help="Segment directory names to skip.",
)
args = parser.parse_args()

# Derive campaign directory from the YAML path (or use cwd)
if args.campaign:
    _given = Path(args.campaign).resolve()
    if _given.is_file():
        BASE = _given.parent
    elif _given.is_dir():
        BASE = _given
        args.campaign = None  # trigger auto-discovery below
    else:
        print(f"Error: {_given} does not exist", file=sys.stderr)
        sys.exit(1)
else:
    BASE = Path(".").resolve()

# ── Locate and read campaign YAML ─────────────────────────────────────────
SKIP: set[str] = set()
if args.skip:
    SKIP.update(args.skip)

YAML_SEGMENTS: list[str] | None = None

if args.campaign and Path(args.campaign).resolve().is_file():
    _campaign_yaml = Path(args.campaign).resolve()
else:
    _campaign_yaml = BASE / "campaign.yaml"
    if not _campaign_yaml.exists():
        _candidates = sorted(BASE.glob("campaign*.yaml"))
        if _candidates:
            _campaign_yaml = _candidates[-1]
        else:
            _campaign_yaml = None

if _campaign_yaml and _campaign_yaml.exists():
    try:
        import yaml
        with open(_campaign_yaml) as _f:
            _cdata = yaml.safe_load(_f)
        if _cdata:
            if isinstance(_cdata.get("skip_segments"), list):
                SKIP.update(_cdata["skip_segments"])
            if isinstance(_cdata.get("segments"), list):
                YAML_SEGMENTS = _cdata["segments"]
        print(f"Campaign:    {_cdata.get('campaign', _campaign_yaml.name)}", file=sys.stderr)
    except ImportError:
        print("Warning: PyYAML not installed; falling back to directory roster scan.",
              file=sys.stderr)
    except Exception as e:
        print(f"Warning: could not parse {_campaign_yaml.name}: {e}", file=sys.stderr)
else:
    print("Warning: no campaign YAML found; falling back to directory roster scan.",
          file=sys.stderr)


# ── Helpers ───────────────────────────────────────────────────────────────

def normalise_name(s: str) -> str:
    """Strip accents, hyphens, separators; collapse whitespace; lowercase."""
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = s.lower()
    s = re.sub(r"\(.*?\)", "", s)
    s = re.sub(r"[/&\u2014\u2013-]+", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def build_profile_index(profiles_dir: Path) -> dict[str, str]:
    """Returns {normalised_name: filename} for all profiles in the dir."""
    index = {}
    for md in profiles_dir.glob("profile-*.md"):
        with md.open(encoding="utf-8") as f:
            for line in f:
                m = re.match(r"^# Profile:\s*(.+)", line)
                if m:
                    name = normalise_name(m.group(1))
                    index[name] = md.name
                    break
    return index


def name_matches(contact: str, profile_index: dict[str, str]) -> bool:
    c = normalise_name(contact)
    if c in profile_index:
        return True
    for k in profile_index:
        if k.startswith(c) or c.startswith(k):
            return True
    return False


HEADER_FRAGMENTS = {
    "date_found_invalid", "contact_name", "organisation", "role", "phone",
    "email", "linkedin_url", "facebook_url", "sweep_iteration",
    "discovered_via", "discovery_source", "verified", "p_note",
    "star_rating", "response_likelihood", "s_note", "a_note", "r_note",
    "postcode",
}


# ── Discover segments ─────────────────────────────────────────────────────
segments: list[tuple[Path, Path]] = []
if YAML_SEGMENTS is not None:
    for seg_name in YAML_SEGMENTS:
        if seg_name in SKIP:
            continue
        seg_dir = BASE / seg_name
        roster = seg_dir / "roster.tsv"
        if not roster.exists():
            print(f"  WARNING: segment '{seg_name}' listed in YAML but roster.tsv not found",
                  file=sys.stderr)
            continue
        segments.append((seg_dir, roster))
else:
    for roster_path in sorted(BASE.glob("*/roster.tsv")):
        segment_dir = roster_path.parent
        rel = str(segment_dir.relative_to(BASE))
        if rel in SKIP:
            continue
        segments.append((segment_dir, roster_path))


# ── Per-segment checks ────────────────────────────────────────────────────

class Checker:
    """Accumulates PASS/WARN/FAIL results for a segment."""

    def __init__(self, label: str):
        self.label = label
        self.results: list[tuple[str, str]] = []  # (level, message)

    def _add(self, level: str, msg: str):
        self.results.append((level, msg))

    def passed(self, msg: str):
        self._add("PASS", msg)

    def warn(self, msg: str):
        self._add("WARN", msg)

    def fail(self, msg: str):
        self._add("FAIL", msg)

    def print_section(self):
        print(f"\n── {self.label} ──")
        for level, msg in self.results:
            print(f"  [{level}] {msg}")


# Cross-segment accumulators
all_emails: dict[str, list[tuple[str, str, str]]] = {}   # email → [(segment, name, org)]
all_names: dict[str, list[tuple[str, str, str]]] = {}    # norm_name → [(segment, name, org)]

checkers: list[Checker] = []
totals = {"PASS": 0, "WARN": 0, "FAIL": 0}

for segment_dir, roster_path in segments:
    label = str(segment_dir.relative_to(BASE))
    ck = Checker(label)
    checkers.append(ck)

    # Read raw bytes, normalise line endings
    raw = roster_path.read_bytes().replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    lines = raw.decode("utf-8").splitlines()

    if not lines:
        ck.fail("Roster file is empty")
        continue

    header_line = lines[0]
    headers = header_line.split("\t")

    # ── Check 1: required columns ─────────────────────────────────────
    missing_cols = [c for c in REQUIRED_COLUMNS if c not in headers]
    if missing_cols:
        ck.warn(f"Missing required columns: {', '.join(missing_cols)}")
    else:
        ck.passed("All required columns present")

    n_cols = len(headers)

    # Parse data via csv.DictReader (same approach as update-campaign-progress.py)
    reader = csv.DictReader(
        io.TextIOWrapper(io.BytesIO(raw), encoding="utf-8"), delimiter="\t"
    )

    all_rows_raw: list[dict[str, str]] = []
    blank_row_count = 0
    col_mismatch_rows: list[int] = []
    header_fragment_rows: list[tuple[int, str]] = []

    for row_num, row in enumerate(reader, start=2):  # row 1 is the header
        values = list(row.values())
        non_empty = [v for v in values if v and v.strip()]

        # ── Check 3: blank/empty data rows ────────────────────────────
        if not non_empty:
            blank_row_count += 1
            continue

        all_rows_raw.append(row)

        # ── Check 2: column count consistency ─────────────────────────
        # csv.DictReader stores extra fields under None key, missing fields
        # are absent from the dict.  Count actual tab-delimited fields from
        # the raw line instead.
        raw_line = lines[row_num - 1] if row_num - 1 < len(lines) else ""
        raw_field_count = len(raw_line.split("\t"))
        if raw_field_count != n_cols:
            col_mismatch_rows.append(row_num)

        # ── Check 4: header fragments in data rows ───────────────────
        org_val = (row.get("organisation") or "").strip().lower()
        name_val = (row.get("contact_name") or "").strip().lower()
        for val, col_name in [(org_val, "organisation"), (name_val, "contact_name")]:
            if val in HEADER_FRAGMENTS:
                header_fragment_rows.append((row_num, val))

    # Report check 2
    if col_mismatch_rows:
        sample = col_mismatch_rows[:5]
        extra = f" (and {len(col_mismatch_rows) - 5} more)" if len(col_mismatch_rows) > 5 else ""
        ck.fail(f"Column count mismatch on {len(col_mismatch_rows)} row(s): "
                f"lines {', '.join(str(r) for r in sample)}{extra} (expected {n_cols})")
    else:
        ck.passed("Column count consistent across all rows")

    # Report check 3
    if blank_row_count:
        ck.warn(f"{blank_row_count} blank spacer row(s) found")
    else:
        ck.passed("No blank spacer rows")

    # Report check 4
    if header_fragment_rows:
        sample = header_fragment_rows[:5]
        desc = "; ".join(f"line {r}: '{v}'" for r, v in sample)
        ck.fail(f"Header fragment(s) in data rows: {desc}")
    else:
        ck.passed("No header fragments in data rows")

    # Use all_rows_raw (non-blank rows) for content checks
    rows = all_rows_raw

    # ── Check 5: every row has contact_name (unless date_found_invalid) ─
    nameless = 0
    for r in rows:
        name = (r.get("contact_name") or "").strip()
        dfi = (r.get("date_found_invalid") or "").strip()
        if not name and not dfi:
            nameless += 1
    if nameless:
        ck.fail(f"{nameless} row(s) missing contact_name without date_found_invalid")
    else:
        ck.passed("Every row has contact_name (or is a negative-cache entry)")

    # ── Check 6: duplicate (contact_name, organisation) pairs ──────────
    seen_pairs: dict[tuple[str, str], int] = {}
    dup_pairs: list[tuple[str, str]] = []
    for r in rows:
        name = normalise_name(r.get("contact_name") or "")
        org = normalise_name(r.get("organisation") or "")
        if not name:
            continue
        key = (name, org)
        if key in seen_pairs:
            dup_pairs.append(key)
        else:
            seen_pairs[key] = 1

    if dup_pairs:
        sample = dup_pairs[:5]
        desc = "; ".join(f"({n}, {o})" for n, o in sample)
        ck.fail(f"{len(dup_pairs)} duplicate (contact_name, organisation) pair(s): {desc}")
    else:
        ck.passed("No duplicate (contact_name, organisation) pairs")

    # ── Check 7: valid rows have at least one contact channel ──────────
    unreachable = []
    for r in rows:
        dfi = (r.get("date_found_invalid") or "").strip()
        if dfi:
            continue
        name = (r.get("contact_name") or "").strip()
        if not name:
            continue
        has_email = bool((r.get("email") or "").strip())
        has_li = bool((r.get("linkedin_url") or "").strip())
        has_fb = bool((r.get("facebook_url") or "").strip())
        if not (has_email or has_li or has_fb):
            unreachable.append(name)
    if unreachable:
        sample = unreachable[:5]
        extra = f" (and {len(unreachable) - 5} more)" if len(unreachable) > 5 else ""
        ck.warn(f"{len(unreachable)} valid row(s) lack email/linkedin/facebook: "
                f"{', '.join(sample)}{extra}")
    else:
        ck.passed("Every valid row has at least one contact channel")

    # ── Check 8: sweep_iteration populated ─────────────────────────────
    no_sweep = 0
    for r in rows:
        si = (r.get("sweep_iteration") or "").strip()
        if not si:
            no_sweep += 1
    if no_sweep:
        ck.fail(f"{no_sweep} row(s) missing sweep_iteration")
    else:
        ck.passed("Every row has sweep_iteration")

    # ── Check 9: segment.yaml (or legacy goal.md) exists ────────────────
    if (segment_dir / "segment.yaml").exists():
        ck.passed("segment.yaml exists")
    elif (segment_dir / "goal.md").exists():
        ck.passed("goal.md exists (legacy — migrate to segment.yaml)")
    else:
        ck.warn("segment.yaml missing")

    # ── Check 10: summary file exists ──────────────────────────────────
    seg_slug = segment_dir.name
    summary = segment_dir / f"summary-{seg_slug}.md"
    if summary.exists():
        ck.passed(f"summary-{seg_slug}.md exists")
    else:
        ck.warn(f"summary-{seg_slug}.md missing")

    # ── Check 11: profiles directory exists ────────────────────────────
    profiles_dir = segment_dir / "profiles"
    if profiles_dir.is_dir():
        ck.passed("profiles/ directory exists")
    else:
        ck.warn("profiles/ directory missing")

    # ── Check 12: profiled contacts have star_rating ───────────────────
    profile_index = build_profile_index(profiles_dir) if profiles_dir.is_dir() else {}
    unrated = []
    for r in rows:
        dfi = (r.get("date_found_invalid") or "").strip()
        if dfi:
            continue
        name = (r.get("contact_name") or "").strip()
        if not name:
            continue
        sr = (r.get("star_rating") or "").strip()
        if sr == "" and name_matches(name, profile_index):
            unrated.append(name)
    if unrated:
        sample = unrated[:5]
        extra = f" (and {len(unrated) - 5} more)" if len(unrated) > 5 else ""
        ck.warn(f"{len(unrated)} profiled contact(s) without star_rating: "
                f"{', '.join(sample)}{extra}")
    elif profile_index:
        ck.passed("All profiled contacts have star_rating")
    else:
        ck.passed("No profiles to check (profiles/ empty or missing)")

    # ── Accumulate cross-segment data ──────────────────────────────────
    for r in rows:
        dfi = (r.get("date_found_invalid") or "").strip()
        if dfi:
            continue
        name = (r.get("contact_name") or "").strip()
        org = (r.get("organisation") or "").strip()
        if not name:
            continue
        email = (r.get("email") or "").strip().lower()
        if email:
            all_emails.setdefault(email, []).append((label, name, org))
        nk = normalise_name(name)
        all_names.setdefault(nk, []).append((label, name, org))


# ── Cross-segment checks ─────────────────────────────────────────────────
cross_ck = Checker("CROSS-SEGMENT")
checkers.append(cross_ck)

# ── Check 13: duplicate emails across segments ────────────────────────
dup_emails = {e: locs for e, locs in all_emails.items() if len(locs) > 1}
# Only flag if they appear in different segments
dup_emails_cross = {}
for email, locs in dup_emails.items():
    segs = set(seg for seg, _, _ in locs)
    if len(segs) > 1:
        dup_emails_cross[email] = locs

if dup_emails_cross:
    lines_out = []
    for email, locs in sorted(dup_emails_cross.items()):
        entries = ", ".join(f"{seg}/{name}" for seg, name, _ in locs)
        lines_out.append(f"    {email}: {entries}")
    cross_ck.warn(f"{len(dup_emails_cross)} email(s) duplicated across segments:\n"
                  + "\n".join(lines_out))
else:
    cross_ck.passed("No duplicate emails across segments")

# ── Check 14: duplicate contact names across segments ─────────────────
dup_names_cross = {}
for nk, locs in all_names.items():
    segs = set(seg for seg, _, _ in locs)
    if len(segs) > 1:
        dup_names_cross[nk] = locs

if dup_names_cross:
    lines_out = []
    for nk, locs in sorted(dup_names_cross.items()):
        entries = ", ".join(f"{seg}/{name}" for seg, name, _ in locs)
        lines_out.append(f"    {nk}: {entries}")
    cross_ck.warn(f"{len(dup_names_cross)} contact name(s) duplicated across segments:\n"
                  + "\n".join(lines_out))
else:
    cross_ck.passed("No duplicate contact names across segments")


# ── Print all results ─────────────────────────────────────────────────────
for ck in checkers:
    ck.print_section()
    for level, _ in ck.results:
        totals[level] = totals.get(level, 0) + 1

# ── Summary ───────────────────────────────────────────────────────────────
print(f"\n{'=' * 50}")
print(f"SUMMARY: {totals.get('PASS', 0)} PASS, "
      f"{totals.get('WARN', 0)} WARN, "
      f"{totals.get('FAIL', 0)} FAIL")
if totals.get("FAIL", 0):
    sys.exit(1)
