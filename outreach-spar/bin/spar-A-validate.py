#!/usr/bin/env python3
from __future__ import annotations
"""SPAR-A approach file validation.

Validates approach YAML files against the approach schema and quality
expectations.  Reports structural problems, invalid email targets, and
channel-contact inconsistencies.

Usage:
    python3 bin/spar-A-validate.py campaign-2026-04.yaml
"""
import argparse
import csv
import io
import os
import re
import sys
from pathlib import Path

import spar_lib

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

# PyYAML is required for approach file validation
try:
    import yaml
except ImportError:
    print("Error: PyYAML is required for approach file validation.", file=sys.stderr)
    sys.exit(1)


# ── Helpers ───────────────────────────────────────────────────────────────

def is_valid_email(value: str) -> bool:
    """Return True if the value looks like a deliverable email address.

    Accepts addresses with optional parenthetical notes after the address
    (e.g. 'a@b.com (verify domain)') as long as the address part has @.
    Rejects placeholders, contact form URLs, phone numbers, names, tildes,
    and any string without @.
    """
    if not value or not value.strip():
        return False
    s = value.strip()
    # Reject YAML null
    if s == "~":
        return False
    # Must contain @
    if "@" not in s:
        return False
    # Extract the part before any parenthetical note
    # e.g. "a@b.com (verify domain)" → "a@b.com"
    addr_part = re.split(r"\s*\(", s)[0].strip()
    # Basic email shape: something@something.something
    if not re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", addr_part):
        return False
    return True


def load_roster_emails(segment_dir: Path) -> dict[str, str]:
    """Load roster.tsv and return {normalised_contact_name: email_value}."""
    roster_path = segment_dir / "roster.tsv"
    if not roster_path.exists():
        return {}
    raw = roster_path.read_bytes().replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    reader = csv.DictReader(
        io.TextIOWrapper(io.BytesIO(raw), encoding="utf-8"), delimiter="\t"
    )
    result = {}
    for row in reader:
        name = (row.get("contact_name") or "").strip().lower()
        email = (row.get("email") or "").strip()
        if name:
            result[name] = email
    return result


def extract_contact_name_from_filename(filename: str) -> str:
    """Best-effort extraction of contact name from approach filename.

    Filenames follow the pattern: {slug_name}-{slug_org}.yaml
    e.g. roberto-giammellucca-sourdough-science-academy.yaml
    We cannot reliably split name from org, so return the full slug
    for fuzzy matching against the roster.
    """
    return filename.replace(".yaml", "").replace("-", " ").lower()


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

    # Load roster for cross-referencing
    roster_emails = load_roster_emails(segment_dir)

    # Per-file tracking
    invalid_email_to: list[tuple[str, str]] = []       # (filename, to_value)
    missing_decisions: list[str] = []                    # filenames
    missing_rounds: list[str] = []                       # filenames
    missing_final: list[str] = []                        # filenames
    bad_round_structure: list[tuple[str, str]] = []      # (filename, issue)
    bad_message_structure: list[tuple[str, str]] = []    # (filename, issue)
    channel_roster_mismatch: list[tuple[str, str]] = []  # (filename, detail)
    yaml_parse_errors: list[tuple[str, str]] = []        # (filename, error)

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

        # ── Check 2: Required top-level keys ─────────────────────────
        if "decisions" not in data:
            missing_decisions.append(fname)
        if "rounds" not in data:
            missing_rounds.append(fname)
            continue  # cannot check rounds structure without rounds

        rounds = data.get("rounds")
        if not isinstance(rounds, list) or len(rounds) == 0:
            missing_rounds.append(fname)
            continue

        # ── Check 3a: Has a final round ──────────────────────────────
        has_final = any(
            isinstance(r, dict) and r.get("type") == "final"
            for r in rounds
        )
        if not has_final:
            missing_final.append(fname)

        # ── Check 3b: Round structure ────────────────────────────────
        for i, rnd in enumerate(rounds):
            if not isinstance(rnd, dict):
                bad_round_structure.append((fname, f"round {i+1} is not a mapping"))
                continue

            rtype = rnd.get("type")
            if rtype not in ("draft", "review", "final"):
                bad_round_structure.append((fname, f"round {i+1} has invalid type '{rtype}'"))

            # Draft and final rounds should have messages
            if rtype in ("draft", "final"):
                if rnd.get("number") is None and rtype == "draft":
                    bad_round_structure.append((fname, f"round {i+1} (draft) missing 'number'"))

                msgs = rnd.get("messages")
                if not isinstance(msgs, list) or len(msgs) == 0:
                    bad_round_structure.append((fname, f"round {i+1} ({rtype}) has no messages"))
                    continue

                # ── Check 3c: Message structure ──────────────────────
                for j, msg in enumerate(msgs):
                    if not isinstance(msg, dict):
                        bad_message_structure.append(
                            (fname, f"round {i+1} message {j+1} is not a mapping"))
                        continue

                    channel = (msg.get("channel") or "").strip().lower()
                    if not channel:
                        bad_message_structure.append(
                            (fname, f"round {i+1} message {j+1} missing 'channel'"))
                        continue

                    # ── Check 1: Email channel has valid to: ─────────
                    if channel == "email":
                        to_val = msg.get("to")
                        # YAML null (~) becomes Python None
                        to_str = str(to_val).strip() if to_val is not None else ""

                        if not is_valid_email(to_str):
                            # Only flag on the final round (the one that matters for sending)
                            if rtype == "final":
                                invalid_email_to.append((fname, to_str or "(empty)"))

                        # Check subject exists for email
                        if not msg.get("subject") and not msg.get("body"):
                            bad_message_structure.append(
                                (fname, f"round {i+1} email message {j+1} missing subject and body"))

            # Review rounds should have verdict or in_character
            if rtype == "review":
                if rnd.get("number") is None:
                    bad_round_structure.append((fname, f"round {i+1} (review) missing 'number'"))

        # ── Check 4: Channel-contact consistency (final round) ───────
        # If decisions say "Email only" but roster has no valid email
        decisions = data.get("decisions", {})
        if isinstance(decisions, dict):
            channel_decision = (decisions.get("channel") or "").strip().lower()
            # Extract contact name slug from filename for roster lookup
            file_slug = extract_contact_name_from_filename(fname)

            # Try to find the matching roster entry
            matched_roster_email = None
            for roster_name, roster_email in roster_emails.items():
                # Check if the roster name words appear in the file slug
                name_words = roster_name.split()
                if len(name_words) >= 2 and all(w in file_slug for w in name_words):
                    matched_roster_email = roster_email
                    break

            if matched_roster_email is not None:
                if "email" in channel_decision and not is_valid_email(matched_roster_email):
                    channel_roster_mismatch.append(
                        (fname,
                         f"channel '{decisions.get('channel')}' but roster email "
                         f"is '{matched_roster_email}'"))

        # ── Accumulate final-round emails for cross-segment check ────
        for rnd in rounds:
            if not isinstance(rnd, dict) or rnd.get("type") != "final":
                continue
            for msg in (rnd.get("messages") or []):
                if not isinstance(msg, dict):
                    continue
                if (msg.get("channel") or "").strip().lower() == "email":
                    to_val = msg.get("to")
                    to_str = str(to_val).strip().lower() if to_val is not None else ""
                    if is_valid_email(to_str):
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

    # ── Report: Check 1 — email to: validity (final round only) ──────
    if invalid_email_to:
        sample = invalid_email_to[:5]
        desc = "; ".join(f"{f}: to='{v}'" for f, v in sample)
        extra = f" (and {len(invalid_email_to) - 5} more)" if len(invalid_email_to) > 5 else ""
        ck.fail(f"{len(invalid_email_to)} final-round email(s) with invalid to: field: {desc}{extra}")
    else:
        ck.passed("All final-round email messages have valid to: addresses")

    # ── Report: Check 2 — required top-level keys ────────────────────
    if missing_decisions:
        sample = missing_decisions[:5]
        extra = f" (and {len(missing_decisions) - 5} more)" if len(missing_decisions) > 5 else ""
        ck.fail(f"{len(missing_decisions)} file(s) missing 'decisions': {', '.join(sample)}{extra}")
    else:
        ck.passed("All files have 'decisions' key")

    if missing_rounds:
        sample = missing_rounds[:5]
        extra = f" (and {len(missing_rounds) - 5} more)" if len(missing_rounds) > 5 else ""
        ck.fail(f"{len(missing_rounds)} file(s) missing or empty 'rounds': {', '.join(sample)}{extra}")
    else:
        ck.passed("All files have 'rounds' key with content")

    # ── Report: Check 3a — final round exists ────────────────────────
    if missing_final:
        sample = missing_final[:5]
        extra = f" (and {len(missing_final) - 5} more)" if len(missing_final) > 5 else ""
        ck.warn(f"{len(missing_final)} file(s) missing a 'type: final' round: {', '.join(sample)}{extra}")
    else:
        ck.passed("All files have a final round")

    # ── Report: Check 3b — round structure ───────────────────────────
    if bad_round_structure:
        sample = bad_round_structure[:5]
        desc = "; ".join(f"{f}: {issue}" for f, issue in sample)
        extra = f" (and {len(bad_round_structure) - 5} more)" if len(bad_round_structure) > 5 else ""
        ck.warn(f"{len(bad_round_structure)} round structure issue(s): {desc}{extra}")
    else:
        ck.passed("All rounds have valid structure (type, number)")

    # ── Report: Check 3c — message structure ─────────────────────────
    if bad_message_structure:
        sample = bad_message_structure[:5]
        desc = "; ".join(f"{f}: {issue}" for f, issue in sample)
        extra = f" (and {len(bad_message_structure) - 5} more)" if len(bad_message_structure) > 5 else ""
        ck.warn(f"{len(bad_message_structure)} message structure issue(s): {desc}{extra}")
    else:
        ck.passed("All messages have valid structure (channel, subject/body)")

    # ── Report: Check 4 — channel-roster consistency ─────────────────
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
