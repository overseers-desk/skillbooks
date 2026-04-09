#!/usr/bin/env python3
from __future__ import annotations
"""SPAR-A approach file validation.

Validates approach YAML files against the approach JSON Schema and
cross-file quality expectations.  Reports structural problems and
channel-contact inconsistencies.

Usage:
    python3 bin/spar-A-validate.py campaign-2026-04.yaml
"""
import argparse
import re
import sys
from pathlib import Path

import jsonschema
import yaml

import spar_lib

SCRIPT_DIR = Path(__file__).resolve().parent
SCHEMA_PATH = SCRIPT_DIR.parent / "approach-schema.yaml"

parser = argparse.ArgumentParser(
    description="Check SPAR campaign approach file integrity.",
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
_campaign_yaml = spar_lib.discover_campaign_yaml(BASE, args.campaign)
_cdata = spar_lib.load_campaign_yaml(_campaign_yaml) if _campaign_yaml else None
YAML_SEGMENTS, SKIP, _cdata = spar_lib.extract_campaign_context(_cdata, args.skip)
if _cdata and _campaign_yaml:
    print(f"Campaign:    {_cdata.get('campaign', _campaign_yaml.name)}", file=sys.stderr)
elif not _campaign_yaml:
    print("Warning: no campaign YAML found; falling back to directory scan.",
          file=sys.stderr)

# ── Load JSON Schema ─────────────────────────────────────────────────────
if not SCHEMA_PATH.exists():
    print(f"Error: approach schema not found: {SCHEMA_PATH}", file=sys.stderr)
    sys.exit(1)
_approach_schema = yaml.safe_load(SCHEMA_PATH.read_text(encoding="utf-8"))


# ── Checker class (from spar_lib) ────────────────────────────────────────

Checker = spar_lib.Checker


# ── Discover segments ─────────────────────────────────────────────────────
segments: list[Path] = [
    seg_dir for seg_dir, _ in spar_lib.discover_segments(
        BASE, YAML_SEGMENTS, SKIP, require="approach"
    )
]


# ── Per-segment checks ────────────────────────────────────────────────────

checkers: list[Checker] = []
totals = {"PASS": 0, "WARN": 0, "FAIL": 0}

# Cross-segment accumulators
all_final_emails: dict[str, list[tuple[str, str]]] = {}  # email → [(segment, filename)]

for segment_dir in segments:
    label = str(segment_dir.relative_to(BASE))
    ck = Checker(label)
    checkers.append(ck)

    approach_dir = segment_dir / "approach"
    approach_files = sorted(approach_dir.glob("*.yaml"))

    if not approach_files:
        ck.warn("No approach files found in approach/ directory")
        continue

    # Load roster for cross-referencing (channel-roster consistency)
    roster_rows = spar_lib.load_roster(segment_dir / "roster.tsv") if (segment_dir / "roster.tsv").exists() else []
    roster_emails: dict[str, str] = {
        (r.get("contact_name") or "").strip().lower(): (r.get("email") or "").strip()
        for r in roster_rows if (r.get("contact_name") or "").strip()
    }

    # Per-file tracking
    schema_errors: list[tuple[str, str]] = []           # (filename, error message)
    yaml_parse_errors: list[tuple[str, str]] = []       # (filename, error)
    channel_roster_mismatch: list[tuple[str, str]] = []  # (filename, detail)

    for af in approach_files:
        fname = af.name

        # Parse YAML
        try:
            with open(af) as f:
                data = yaml.safe_load(f)
        except Exception as e:
            yaml_parse_errors.append((fname, str(e)))
            continue

        if not isinstance(data, dict):
            yaml_parse_errors.append((fname, "file does not parse as a YAML mapping"))
            continue

        # ── Schema validation ───────────────────────────────────────
        try:
            jsonschema.validate(data, _approach_schema)
        except jsonschema.ValidationError as e:
            schema_errors.append((fname, e.message))
            # Still attempt cross-file checks if basic structure is present

        # ── Channel-roster consistency (final round) ────────────────
        decisions = data.get("decisions", {})
        if isinstance(decisions, dict):
            channel_decision = (decisions.get("channel") or "").strip().lower()
            file_slug = fname.replace(".yaml", "").replace("-", " ").lower()

            matched_roster_email = None
            for roster_name, roster_email in roster_emails.items():
                name_words = roster_name.split()
                if len(name_words) >= 2 and all(w in file_slug for w in name_words):
                    matched_roster_email = roster_email
                    break

            if matched_roster_email is not None:
                if "email" in channel_decision and "@" not in matched_roster_email:
                    channel_roster_mismatch.append(
                        (fname,
                         f"channel '{decisions.get('channel')}' but roster email "
                         f"is '{matched_roster_email}'"))

        # ── Accumulate final-round emails for cross-segment check ────
        for rnd in (data.get("rounds") or []):
            if not isinstance(rnd, dict) or rnd.get("type") != "final":
                continue
            for msg in (rnd.get("messages") or []):
                if not isinstance(msg, dict):
                    continue
                if (msg.get("channel") or "").strip().lower() == "email":
                    to_val = msg.get("to")
                    to_str = str(to_val).strip().lower() if to_val is not None else ""
                    if "@" in to_str:
                        addr = re.split(r"\s*\(", to_str)[0].strip()
                        all_final_emails.setdefault(addr, []).append((label, fname))

    # ── Report: YAML parse errors ────────────────────────────────────
    if yaml_parse_errors:
        sample = yaml_parse_errors[:5]
        desc = "; ".join(f"{f}: {e}" for f, e in sample)
        extra = f" (and {len(yaml_parse_errors) - 5} more)" if len(yaml_parse_errors) > 5 else ""
        ck.fail(f"{len(yaml_parse_errors)} file(s) failed YAML parsing: {desc}{extra}")
    else:
        ck.passed(f"All {len(approach_files)} approach file(s) parse as valid YAML")

    # ── Report: Schema validation ────────────────────────────────────
    if schema_errors:
        sample = schema_errors[:5]
        desc = "; ".join(f"{f}: {e}" for f, e in sample)
        extra = f" (and {len(schema_errors) - 5} more)" if len(schema_errors) > 5 else ""
        ck.fail(f"{len(schema_errors)} file(s) failed schema validation: {desc}{extra}")
    else:
        ck.passed("All files pass schema validation")

    # ── Report: Channel-roster consistency ───────────────────────────
    if channel_roster_mismatch:
        sample = channel_roster_mismatch[:5]
        desc = "; ".join(f"{f}: {detail}" for f, detail in sample)
        extra = f" (and {len(channel_roster_mismatch) - 5} more)" if len(channel_roster_mismatch) > 5 else ""
        ck.warn(f"{len(channel_roster_mismatch)} channel-roster mismatch(es): {desc}{extra}")
    else:
        ck.passed("Channel decisions consistent with roster email data")


# ── Cross-segment checks ─────────────────────────────────────────────────
cross_ck = Checker("CROSS-SEGMENT")
checkers.append(cross_ck)

# Duplicate final-round email addresses across segments
dup_emails_cross = {}
for email, locs in all_final_emails.items():
    segs = set(seg for seg, _ in locs)
    if len(segs) > 1:
        dup_emails_cross[email] = locs

if dup_emails_cross:
    lines_out = []
    for email, locs in sorted(dup_emails_cross.items()):
        entries = ", ".join(f"{seg}/{fname}" for seg, fname in locs)
        lines_out.append(f"    {email}: {entries}")
    cross_ck.warn(f"{len(dup_emails_cross)} email address(es) targeted by approach files in "
                  f"multiple segments:\n" + "\n".join(lines_out))
else:
    cross_ck.passed("No email addresses duplicated across segments")


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
