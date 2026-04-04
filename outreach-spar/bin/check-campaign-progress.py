#!/usr/bin/env python3
"""Show outreach pipeline progress per segment.

Each column (except Valid) shows count and percentage of its denominator:
  Valid     — roster rows where date_found_invalid is blank
  Profile   — valid entries with a matching profile file (/ Valid)
  3★+       — valid rows with star_rating >= 3 (/ Valid)
  w.✉       — 3★+ rows with an email address (/ 3★+)
  Approach  — approach files in approach/ (/ 3★+)
  Sent      — approach files with a sent date (/ Approach)
  Repl      — approach files with a reply marker (/ Sent)

Optional --missing [S|P|A] prints per-entry detail for actionable gaps.
"""
import argparse
import csv
import io
import os
import re
import sys
import unicodedata
from pathlib import Path

parser = argparse.ArgumentParser(
    description="Show outreach pipeline progress per segment.",
    formatter_class=argparse.RawDescriptionHelpFormatter,
)
parser.add_argument(
    "campaign_dir",
    nargs="?",
    default=".",
    help="Campaign directory (default: current directory).",
)
parser.add_argument(
    "--campaign",
    metavar="YAML",
    default=None,
    help="Campaign YAML file. If omitted, auto-discovers campaign*.yaml in campaign_dir.",
)
parser.add_argument(
    "--missing",
    nargs="*",
    metavar="STAGE",
    help=(
        "Print per-entry detail for actionable gaps.\n"
        "Stages: S (sweep), P (profile), A (approach).  R is not accepted.\n"
        "Omit STAGE to show all three."
    ),
)
parser.add_argument(
    "--skip",
    nargs="*",
    metavar="SEGMENT",
    default=None,
    help="Segment directory names to skip. If a campaign.yaml exists in the campaign dir, skip_segments from it are also used.",
)
args = parser.parse_args()

BASE = Path(args.campaign_dir).resolve()

if args.missing is not None:
    if len(args.missing) == 0:
        missing_stages = {"S", "P", "A"}
    else:
        bad = set(args.missing) - {"S", "P", "A", "R"}
        if bad:
            parser.error(f"Unknown stage(s): {', '.join(sorted(bad))}. Valid: S, P, A.")
        if "R" in args.missing:
            print("Note: R (reply) is not actionable; skipping.", file=sys.stderr)
        missing_stages = set(args.missing) & {"S", "P", "A"}
else:
    missing_stages = set()

# --- Locate and read campaign YAML ---
SKIP: set[str] = set()
if args.skip:
    SKIP.update(args.skip)

YAML_SEGMENTS: list[str] | None = None  # None = no YAML found; fall back to recursive scan

if args.campaign:
    _campaign_yaml = Path(args.campaign).resolve()
    if not _campaign_yaml.exists():
        print(f"Error: campaign file not found: {_campaign_yaml}", file=sys.stderr)
        sys.exit(1)
else:
    _campaign_yaml = BASE / "campaign.yaml"
    if not _campaign_yaml.exists():
        _candidates = sorted(BASE.glob("campaign*.yaml"))
        if _candidates:
            _campaign_yaml = _candidates[-1]  # last = most recent by date convention
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
        print("Warning: PyYAML not installed; falling back to recursive roster scan.", file=sys.stderr)
    except Exception as e:
        print(f"Warning: could not parse {_campaign_yaml.name}: {e}", file=sys.stderr)
else:
    print("Warning: no campaign YAML found; falling back to recursive roster scan.", file=sys.stderr)


def normalise_name(s: str) -> str:
    """Strip accents, hyphens, separators; collapse whitespace; lowercase."""
    # Unicode normalise → strip combining marks (accents)
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = s.lower()
    # Strip parentheticals
    s = re.sub(r"\(.*?\)", "", s)
    # Normalise separators: —, /, &, - to space
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


def parse_star(val: str) -> int:
    """Parse star_rating field to int; return 0 if unparseable."""
    val = val.strip()
    if val.isdigit():
        return int(val)
    return 0


def scan_approach_dir(approach_dir: Path) -> tuple[int, int, int, dict, list]:
    """Return (total, sent, replied, to_map, unsent_subjects) from approach files.

    to_map maps filename → To address extracted from the Final draft section.
    unsent_subjects is a list of (filename, subject) for files not yet sent.
    """
    total = sent = replied = 0
    to_map: dict[str, str] = {}
    unsent_subjects: list[tuple[str, str]] = []
    if not approach_dir.is_dir():
        return total, sent, replied, to_map, unsent_subjects
    for md in approach_dir.glob("approach-*.md"):
        total += 1
        content = md.read_text(encoding="utf-8", errors="replace")
        is_sent = bool(re.search(r"^### .+\((Sent|Called) \d{4}-\d{2}-\d{2}\)", content, re.MULTILINE))
        if is_sent:
            sent += 1
        if re.search(r"^### .+ Replied\b", content, re.MULTILINE):
            replied += 1
        fd = re.search(r"^## Final draft", content, re.MULTILINE)
        if fd:
            after = content[fd.start():]
            m = re.search(r"^To: (.+)$", after, re.MULTILINE)
            if m:
                to_map[md.name] = m.group(1).strip()
            if not is_sent:
                sm = re.search(r"^Subject: (.+)$", after, re.MULTILINE)
                if sm:
                    unsent_subjects.append((md.name, sm.group(1).strip()))
    return total, sent, replied, to_map, unsent_subjects


def build_approach_contact_index(approach_dir: Path) -> dict[str, tuple[str, str, bool]]:
    """Return {normalised_contact: (raw_name, raw_org, is_sent)} from approach headings."""
    index: dict[str, tuple[str, str, bool]] = {}
    if not approach_dir.is_dir():
        return index
    sent_pat = re.compile(r"^### .+\((Sent|Called) \d{4}-\d{2}-\d{2}\)", re.MULTILINE)
    for md in approach_dir.glob("approach-*.md"):
        content = md.read_text(encoding="utf-8", errors="replace")
        heading = re.match(r"^# Approach:\s*(.+?),\s*(.+)$", content, re.MULTILINE)
        if not heading:
            continue
        name = heading.group(1).strip()
        org = heading.group(2).strip()
        is_sent = bool(sent_pat.search(content))
        index[normalise_name(name)] = (name, org, is_sent)
    return index


# --- Discover segments ---
segments = []
if YAML_SEGMENTS is not None:
    for seg_name in YAML_SEGMENTS:
        if seg_name in SKIP:
            continue
        seg_dir = BASE / seg_name
        roster = seg_dir / "roster.tsv"
        if not roster.exists():
            print(f"  WARNING: segment '{seg_name}' listed in YAML but roster.tsv not found", file=sys.stderr)
            continue
        segments.append((seg_dir, roster))
    # Warn about roster.tsv files on disk not listed in the YAML
    yaml_set = set(YAML_SEGMENTS) | SKIP
    for roster_path in sorted(BASE.rglob("roster.tsv")):
        rel = str(roster_path.parent.relative_to(BASE))
        if rel not in yaml_set and "/" not in rel:  # top-level segment dirs only
            print(f"  WARNING: {rel}/roster.tsv exists but is not listed in campaign YAML", file=sys.stderr)
else:
    # Fallback: recursive scan (no YAML available)
    for roster_path in sorted(BASE.rglob("roster.tsv")):
        segment_dir = roster_path.parent
        rel = segment_dir.relative_to(BASE)
        if str(rel) in SKIP:
            continue
        segments.append((segment_dir, roster_path))

has_over_100 = False


def fmt_cell(count: int, denom: int) -> str:
    """Format 'count pct%' with fixed sub-field widths: 3 + 1 + 5 = 9 chars."""
    global has_over_100
    if denom:
        pct_val = count / denom * 100
        if pct_val > 100:
            has_over_100 = True
            pct = f"{pct_val:3.0f}%†"
        else:
            pct = f"{pct_val:3.0f}% "
    else:
        pct = "   - "
    return f"{count:>3} {pct}"


HDR = (
    f"{'Segment':<35}|{'Valid':>5}"
    f"|{'Profile':>9}"
    f"|{'3*+':>9}"
    f"|{'w. Email':>9}"
    f"|{'Approach':>9}"
    f"|{'Sent':>9}"
    f"|{'Repl':>9}"
)
SEP = "-" * len(HDR)

print(HDR)
print(SEP)

gt_valid = gt_prof = gt_star = gt_has_email = gt_appr = gt_sent = gt_replied = 0

# {to_address: [(segment_label, filename), ...]} — for duplicate detection
all_to_map: dict[str, list[tuple[str, str]]] = {}
# Cross-segment duplicate detection: name → [(segment, contact_name, org, email)]
all_contacts_by_name: dict[str, list[tuple[str, str, str, str]]] = {}
# email → [(segment, contact_name, org)]
all_contacts_by_email: dict[str, list[tuple[str, str, str]]] = {}
# subject → [(segment_label, filename)] — for unsent duplicate subject detection
all_unsent_subjects: dict[str, list[tuple[str, str]]] = {}

# --missing collectors
missing_sweep: list[tuple[str, int]] = []
missing_profile: list[tuple[str, str, str]] = []
missing_approach: list[tuple[str, str, str, str]] = []

for segment_dir, roster_path in segments:
    label = str(segment_dir.relative_to(BASE))
    profiles_dir = segment_dir / "profiles"
    approach_dir = segment_dir / "approach"

    profile_index = build_profile_index(profiles_dir) if profiles_dir.is_dir() else {}

    raw = roster_path.read_bytes().replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    reader = csv.DictReader(
        io.TextIOWrapper(io.BytesIO(raw), encoding="utf-8"), delimiter="\t"
    )
    has_segment_col = reader.fieldnames and "segment" in reader.fieldnames
    rows = [
        r for r in reader
        if any(v for v in r.values() if v)
        and (not has_segment_col or (r.get("segment") or "").strip())
    ]

    valid_rows = [
        r for r in rows
        if not (r.get("date_found_invalid") or "").strip()
        and (r.get("contact_name") or "").strip()
    ]

    # Warn on star_rating blank for valid rows that have a profile (profiled but not rated)
    for r in valid_rows:
        contact = (r.get("contact_name") or "").strip()
        if not contact:
            continue
        sr = (r.get("star_rating") or "").strip()
        if sr == "" and name_matches(contact, profile_index):
            print(f"  WARNING: {label}: {contact} has profile but no star_rating", file=sys.stderr)

    profiled = sum(
        1 for r in valid_rows
        if (r.get("contact_name") or "").strip()
        and name_matches(r["contact_name"], profile_index)
    )

    star3 = [r for r in valid_rows if parse_star(r.get("star_rating") or "") >= 3]
    has_email = sum(1 for r in star3 if (r.get("email") or "").strip())
    n_star3 = len(star3)

    appr_total, appr_sent, appr_replied, to_map, unsent_subjs = scan_approach_dir(approach_dir)
    for fname, addr in to_map.items():
        all_to_map.setdefault(addr, []).append((label, fname))
    for fname, subj in unsent_subjs:
        all_unsent_subjects.setdefault(subj, []).append((label, fname))

    for r in valid_rows:
        contact = (r.get("contact_name") or "").strip()
        org = (r.get("organisation") or "").strip()
        email = (r.get("email") or "").strip().lower()
        if not contact:
            continue
        # Given name + surname key (normalised)
        nk = normalise_name(contact)
        all_contacts_by_name.setdefault(nk, []).append((label, contact, org, email))
        if email:
            all_contacts_by_email.setdefault(email, []).append((label, contact, org))

    n = len(valid_rows)

    print(
        f"{label:<35}|{n:>5}"
        f"|{fmt_cell(profiled, n)}"
        f"|{fmt_cell(n_star3, n)}"
        f"|{fmt_cell(has_email, n_star3)}"
        f"|{fmt_cell(appr_total, n_star3)}"
        f"|{fmt_cell(appr_sent, appr_total)}"
        f"|{fmt_cell(appr_replied, appr_sent)}"
    )

    # --missing collection
    if "S" in missing_stages:
        max_sweep = 0
        for r in rows:
            si = (r.get("sweep_iteration") or "").strip()
            if si.isdigit():
                max_sweep = max(max_sweep, int(si))
        missing_sweep.append((label, max_sweep))

    if "P" in missing_stages:
        for r in valid_rows:
            contact = (r.get("contact_name") or "").strip()
            org = (r.get("organisation") or "").strip()
            if not contact or name_matches(contact, profile_index):
                continue
            missing_profile.append((label, contact, org))

    if "A" in missing_stages:
        appr_idx = build_approach_contact_index(approach_dir)
        for r in star3:
            contact = (r.get("contact_name") or "").strip()
            org = (r.get("organisation") or "").strip()
            if not contact:
                continue
            nc = normalise_name(contact)
            matched = None
            if nc in appr_idx:
                matched = appr_idx[nc]
            else:
                for k in appr_idx:
                    if k.startswith(nc) or nc.startswith(k):
                        matched = appr_idx[k]
                        break
            if matched is None:
                missing_approach.append((label, contact, org, "no approach file"))
            elif not matched[2]:
                missing_approach.append((label, contact, org, "not yet sent"))

    gt_valid += n
    gt_prof += profiled
    gt_star += n_star3
    gt_has_email += has_email
    gt_appr += appr_total
    gt_sent += appr_sent
    gt_replied += appr_replied

print(SEP)
print(
    f"{'TOTAL':<35}|{gt_valid:>5}"
    f"|{fmt_cell(gt_prof, gt_valid)}"
    f"|{fmt_cell(gt_star, gt_valid)}"
    f"|{fmt_cell(gt_has_email, gt_star)}"
    f"|{fmt_cell(gt_appr, gt_star)}"
    f"|{fmt_cell(gt_sent, gt_appr)}"
    f"|{fmt_cell(gt_replied, gt_sent)}"
)

if has_over_100:
    print()
    print("† Exceeds 100% because approach files exist for entries that were")
    print("  subsequently invalidated or rated below the 3★ threshold.")

# Duplicate recipient report (only flag actual email addresses, skip placeholders)
dups = {addr: entries for addr, entries in all_to_map.items() if len(entries) > 1 and "@" in addr}
if dups:
    print()
    print("DUPLICATE RECIPIENTS (same To: address in multiple approach files):")
    print("-" * 72)
    for addr, entries in sorted(dups.items()):
        print(f"  {addr}")
        for segment_label, fname in entries:
            print(f"    {segment_label}/{fname}")

# Cross-segment duplicates by name
name_dups = {k: v for k, v in all_contacts_by_name.items() if len(set(ch for ch, *_ in v)) > 1}
if name_dups:
    print()
    print("DUPLICATE CONTACTS BY NAME (same person in multiple segments):")
    print("-" * 72)
    for nk, entries in sorted(name_dups.items(), key=lambda x: x[0]):
        display_name = entries[0][1]
        print(f"  {display_name}")
        for ch, _name, org, email in entries:
            print(f"    [{ch}] {org}" + (f"  <{email}>" if email else ""))

# Cross-segment duplicates by email
email_dups = {k: v for k, v in all_contacts_by_email.items() if len(set(ch for ch, *_ in v)) > 1}
if email_dups:
    print()
    print("DUPLICATE CONTACTS BY EMAIL (same email in multiple segments):")
    print("-" * 72)
    for addr, entries in sorted(email_dups.items()):
        print(f"  {addr}")
        for ch, contact, org in entries:
            print(f"    [{ch}] {contact} - {org}")

# Duplicate subject lines among unsent approach files
subj_dups = {s: entries for s, entries in all_unsent_subjects.items() if len(entries) > 1}
if subj_dups:
    print()
    print("IDENTICAL SUBJECT LINES IN UNSENT APPROACHES:")
    print("-" * 72)
    for subj, entries in sorted(subj_dups.items()):
        print(f"  Subject: {subj}")
        for segment_label, fname in entries:
            print(f"    {segment_label}/{fname}")

# --missing detail sections
if "S" in missing_stages and missing_sweep:
    print()
    print("SWEEP COVERAGE (S) \u2014 max sweep_iteration per segment:")
    print("-" * 50)
    for label, max_sweep in missing_sweep:
        print(f"  {label:<35} sweep {max_sweep}")
    print()
    print("  Caveat: cannot distinguish 'not yet swept' from 'swept with no result'.")

if "P" in missing_stages and missing_profile:
    print()
    print(f"MISSING PROFILES (P) \u2014 {len(missing_profile)} valid entries with no profile:")
    print("-" * 72)
    for label, contact, org in missing_profile:
        print(f"  [{label}]  {contact or '(no contact)'} \u2014 {org}")

if "A" in missing_stages and missing_approach:
    print()
    print(f"MISSING/UNSENT APPROACHES (A) \u2014 {len(missing_approach)} entries:")
    print("-" * 72)
    for label, contact, org, reason in missing_approach:
        print(f"  [{label}]  {contact} \u2014 {org}  ({reason})")
