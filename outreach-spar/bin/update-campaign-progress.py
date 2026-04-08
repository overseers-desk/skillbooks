#!/usr/bin/env python3
from __future__ import annotations
"""Show outreach pipeline progress per segment, and update reply status from mailroom.

Each column (except Valid) shows count and percentage of its denominator:
  Valid     — roster rows where date_found_invalid is blank
  Profile   — valid entries with a matching profile file (/ Valid)
  3★+       — valid rows with star_rating >= 3 (/ Valid)
  A/3★+     — approach files matched to 3★+ contacts (/ 3★+)
  Email     — 3★+ rows with an email address (/ 3★+)
  A/Eml     — approach files matched to 3★+ contacts who have email (/ Email)
  LinkedIn  — 3★+ rows with a linkedin_url (/ 3★+)
  Facebook  — 3★+ rows with a facebook_url (/ 3★+)
  Phone-only— 3★+ rows with only phone (no email, linkedin, or facebook) (/ 3★+)
  Sent      — matched approach files with a sent date (/ A/3★+)
  Repl      — matched approach files with a reply marker (/ Sent)

After printing the file-based progress table, checks the campaign's mailroom
account for new replies and appends '### Email Replied (date)' sections to
matching approach files.  Uses a date high-water mark per approach file to
avoid re-processing already-recorded replies.

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
parser.add_argument(
    "--no-mailroom",
    action="store_true",
    help="Skip mailroom reply checking.",
)
parser.add_argument(
    "--update",
    action="store_true",
    help="Update approach files from mailroom without prompting.",
)
parser.add_argument(
    "--legend",
    action="store_true",
    help="Print column legend after the progress table.",
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

YAML_SEGMENTS: list[str] | None = None  # None = no YAML found; fall back to directory scan
_reply_check: dict = {}  # populated from campaign YAML reply_check section
_sender_email: str = ""  # populated from campaign YAML sender.email
_approach_filename_template: str = ""  # populated from campaign YAML approach_filename

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
            if isinstance(_cdata.get("reply_check"), dict):
                _reply_check = _cdata["reply_check"]
            if isinstance(_cdata.get("sender"), dict):
                _sender_email = (_cdata["sender"].get("email") or "").strip()
            _approach_filename_template: str = (_cdata.get("approach_filename") or "").strip()
        print(f"Campaign:    {_cdata.get('campaign', _campaign_yaml.name)}", file=sys.stderr)
    except ImportError:
        print("Warning: PyYAML not installed; falling back to directory roster scan.", file=sys.stderr)
    except Exception as e:
        print(f"Warning: could not parse {_campaign_yaml.name}: {e}", file=sys.stderr)
else:
    print("Warning: no campaign YAML found; falling back to directory roster scan.", file=sys.stderr)


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


def slugify(s: str) -> str:
    """Match the bash slugify: lowercase, non-alphanumeric → hyphen, collapse, strip."""
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")


def _approach_status(path: Path) -> tuple[bool, bool]:
    """Return (is_sent, is_replied) for an approach YAML file."""
    import yaml as _yaml
    is_sent = is_replied = False
    try:
        data = _yaml.safe_load(path.read_text(encoding="utf-8", errors="replace"))
        if isinstance(data, dict):
            for r in data.get("rounds", []):
                if r.get("type") == "final":
                    for msg in r.get("messages", []):
                        ad = msg.get("actioned_date")
                        if ad and str(ad) not in ("~", "None", "null"):
                            is_sent = True
                        rd = msg.get("replied_date")
                        if rd and str(rd) not in ("~", "None", "null"):
                            is_replied = True
                    for reply in r.get("replies", []):
                        if reply.get("direction") == "received":
                            is_replied = True
    except Exception:
        pass
    return is_sent, is_replied


class ApproachStats:
    """Result of classify_approach_gaps for a single segment."""
    __slots__ = ("matched", "matched_with_email", "sent", "replied", "missing_file", "unsent")

    def __init__(self):
        self.matched: int = 0
        self.matched_with_email: int = 0
        self.sent: int = 0
        self.replied: int = 0
        self.missing_file: list[tuple[str, str]] = []
        self.unsent: list[tuple[str, str]] = []


def classify_approach_gaps(
    star3_rows: list[dict],
    approach_dir: Path,
) -> ApproachStats:
    """Match 3★+ contacts to approach files and return stats + gap lists.

    Matching strategy (both passes use the approach file stem):
      Pass 1 — full slug_name prefix: stem == slug_name or stem.startswith(slug_name + "-")
      Pass 2 — first-name-only prefix for contacts unmatched in pass 1, accepted only when
               exactly one unclaimed stem starts with first_name + "-"

    This handles two naming conventions:
      New: {slug_name}-{slug_org_possibly_abbrev}.yaml  (full first+last name)
      Old: {slug_first}-{slug_org_possibly_abbrev}.yaml  (first name only)
    """
    stats = ApproachStats()

    if not approach_dir.is_dir():
        stats.missing_file = [
            (r.get("contact_name", "").strip(), r.get("organisation", "").strip())
            for r in star3_rows if r.get("contact_name", "").strip()
        ]
        return stats

    all_stems: dict[str, Path] = {yf.stem: yf for yf in approach_dir.glob("*.yaml")}
    claimed: set[str] = set()  # stems already assigned to a contact

    # Build slug_name for each row
    rows_with_slugs: list[tuple[dict, str]] = []
    for r in star3_rows:
        name = r.get("contact_name", "").strip()
        if not name:
            continue
        rows_with_slugs.append((r, slugify(name)))

    # Pass 1: match by full slug_name prefix
    matched: dict[int, str] = {}  # row index → stem
    for idx, (r, slug_name) in enumerate(rows_with_slugs):
        for stem in all_stems:
            if stem not in claimed and (stem == slug_name or stem.startswith(slug_name + "-")):
                matched[idx] = stem
                claimed.add(stem)
                break

    # Pass 2: first-name-only prefix for unmatched contacts
    for idx, (r, slug_name) in enumerate(rows_with_slugs):
        if idx in matched:
            continue
        tokens = slug_name.split("-")
        if len(tokens) < 2:
            continue  # single-token name — can't do first-name-only safely
        first = tokens[0]
        candidates = [s for s in all_stems if s not in claimed and s.startswith(first + "-")]
        if len(candidates) == 1:
            matched[idx] = candidates[0]
            claimed.add(candidates[0])

    for idx, (r, _) in enumerate(rows_with_slugs):
        name = r.get("contact_name", "").strip()
        org = r.get("organisation", "").strip()
        if idx not in matched:
            stats.missing_file.append((name, org))
        else:
            stats.matched += 1
            if (r.get("email") or "").strip():
                stats.matched_with_email += 1
            stem = matched[idx]
            is_sent, is_replied = _approach_status(all_stems[stem])
            if is_sent:
                stats.sent += 1
            else:
                stats.unsent.append((name, org))
            if is_replied:
                stats.replied += 1

    return stats


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
    """Return (total, sent, replied, to_map, unsent_subjects) from approach YAML files.

    to_map maps filename → To address from the final round.
    unsent_subjects is a list of (filename, subject) for files not yet sent.
    """
    import yaml as _yaml
    total = sent = replied = 0
    to_map: dict[str, str] = {}
    unsent_subjects: list[tuple[str, str]] = []
    if not approach_dir.is_dir():
        return total, sent, replied, to_map, unsent_subjects
    for yf in approach_dir.glob("*.yaml"):
        total += 1
        try:
            data = _yaml.safe_load(yf.read_text(encoding="utf-8", errors="replace"))
        except Exception:
            continue
        if not isinstance(data, dict):
            continue
        is_sent = False
        is_replied = False
        final_to = None
        final_subject = None
        for r in data.get("rounds", []):
            if r.get("type") == "final":
                for msg in r.get("messages", []):
                    ad = msg.get("actioned_date")
                    if ad and str(ad) not in ("~", "None", "null"):
                        is_sent = True
                    rd = msg.get("replied_date")
                    if rd and str(rd) not in ("~", "None", "null"):
                        is_replied = True
                    if msg.get("channel") == "email":
                        if msg.get("to") and not final_to:
                            final_to = str(msg["to"]).strip()
                        if msg.get("subject") and not final_subject:
                            final_subject = str(msg["subject"]).strip()
                for reply in r.get("replies", []):
                    if reply.get("direction") == "received":
                        is_replied = True
        if is_sent:
            sent += 1
        if is_replied:
            replied += 1
        if final_to:
            to_map[yf.name] = final_to
        if not is_sent and final_subject:
            unsent_subjects.append((yf.name, final_subject))
    return total, sent, replied, to_map, unsent_subjects


def build_approach_contact_index(approach_dir: Path) -> dict[str, tuple[str, str, bool]]:
    """Return {normalised_contact: (raw_name, raw_org, is_sent)} from approach YAML files.

    Extracts contact name/org from the roster_note or filename slug.
    """
    import yaml as _yaml
    index: dict[str, tuple[str, str, bool]] = {}
    if not approach_dir.is_dir():
        return index
    # Build a profile heading index for name/org lookup
    profile_dir = approach_dir.parent / "profiles"
    slug_to_nameorg: dict[str, tuple[str, str]] = {}
    if profile_dir.is_dir():
        for pf in profile_dir.glob("profile-*.md"):
            content = pf.read_text(encoding="utf-8", errors="replace")
            heading = re.search(r"^#\s+(?:Profile:\s*)?(.+?),\s*(.+)$", content, re.MULTILINE)
            if heading:
                slug = pf.stem.removeprefix("profile-")
                slug_to_nameorg[slug] = (heading.group(1).strip(), heading.group(2).strip())
    for yf in approach_dir.glob("*.yaml"):
        slug = yf.stem
        name, org = slug_to_nameorg.get(slug, ("", ""))
        if not name:
            tokens = slug.split("-")
            name = " ".join(t.title() for t in tokens[:2])
            org = " ".join(t.title() for t in tokens[2:])
        is_sent = False
        try:
            data = _yaml.safe_load(yf.read_text(encoding="utf-8", errors="replace"))
            if isinstance(data, dict):
                for r in data.get("rounds", []):
                    if r.get("type") == "final":
                        for msg in r.get("messages", []):
                            ad = msg.get("actioned_date")
                            if ad and str(ad) not in ("~", "None", "null"):
                                is_sent = True
        except Exception:
            pass
        if name:
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
    for child in sorted(BASE.iterdir()):
        if child.name.startswith(".") or not child.is_dir():
            continue
        roster_path = child / "roster.tsv"
        if roster_path.exists():
            rel = str(child.relative_to(BASE))
            if rel not in yaml_set:
                print(f"  NOTE: {rel}/roster.tsv exists but is not in this campaign", file=sys.stderr)
else:
    # Fallback: scan direct child directories only (subfolders are not segments)
    for child in sorted(BASE.iterdir()):
        if child.name.startswith(".") or not child.is_dir():
            continue
        roster_path = child / "roster.tsv"
        if not roster_path.exists():
            continue
        if child.name in SKIP:
            continue
        segments.append((child, roster_path))

def fmt_cell(count: int, denom: int) -> str:
    """Format 'count pct%' compactly for table cells."""
    if denom:
        pct = f"{count / denom * 100:3.0f}%"
    else:
        pct = "   -"
    return f"{count:>3} {pct}"


TABLE_HEADERS = ['Segment', 'Valid', 'Profile', '3★+', 'A/3★+', 'Email', 'A/Eml', 'LinkedIn', 'Facebook', 'Phone-only', 'Sent', 'Repl']
TABLE_ALIGNS = ['l', 'r', 'r', 'r', 'r', 'r', 'r', 'r', 'r', 'r', 'r', 'r']


def print_md_table(headers: list[str], rows: list[list[str]], aligns: list[str] | None = None) -> None:
    """Print a packed, aligned Markdown table."""
    if aligns is None:
        aligns = ['l'] + ['r'] * (len(headers) - 1)
    widths = [len(h) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(cell))

    def fmt_row(cells: list[str]) -> str:
        parts = []
        for cell, w, a in zip(cells, widths, aligns):
            parts.append(cell.rjust(w) if a == 'r' else cell.ljust(w))
        return '|' + '|'.join(parts) + '|'

    def sep_row() -> str:
        parts = []
        for w, a in zip(widths, aligns):
            parts.append('-' * (w - 1) + ':' if a == 'r' else ':' + '-' * (w - 1))
        return '|' + '|'.join(parts) + '|'

    print(fmt_row(headers))
    print(sep_row())
    for row in rows:
        print(fmt_row(row))


def build_progress_rows(
    segment_roster_data: list[tuple[str, int, int, int, int, int, int, int]],
    approach_stats_list: list[ApproachStats],
) -> list[list[str]]:
    """Build table rows (including TOTAL) from cached roster data and approach stats."""
    rows: list[list[str]] = []
    gt_v = gt_p = gt_s = gt_e = gt_l = gt_f = gt_po = gt_a = gt_ae = gt_sn = gt_r = 0
    for (label, n, profiled, n_star3, has_email, has_li, has_fb, has_phone_only), astats in zip(
        segment_roster_data, approach_stats_list
    ):
        rows.append([
            label,
            str(n),
            fmt_cell(profiled, n),
            fmt_cell(n_star3, n),
            fmt_cell(astats.matched, n_star3),
            fmt_cell(has_email, n_star3),
            fmt_cell(astats.matched_with_email, has_email),
            fmt_cell(has_li, n_star3),
            fmt_cell(has_fb, n_star3),
            fmt_cell(has_phone_only, n_star3),
            fmt_cell(astats.sent, astats.matched),
            fmt_cell(astats.replied, astats.sent),
        ])
        gt_v += n; gt_p += profiled; gt_s += n_star3; gt_e += has_email
        gt_l += has_li; gt_f += has_fb; gt_po += has_phone_only
        gt_a += astats.matched; gt_ae += astats.matched_with_email
        gt_sn += astats.sent; gt_r += astats.replied
    rows.append([
        'TOTAL',
        str(gt_v),
        fmt_cell(gt_p, gt_v),
        fmt_cell(gt_s, gt_v),
        fmt_cell(gt_a, gt_s),
        fmt_cell(gt_e, gt_s),
        fmt_cell(gt_ae, gt_e),
        fmt_cell(gt_l, gt_s),
        fmt_cell(gt_f, gt_s),
        fmt_cell(gt_po, gt_s),
        fmt_cell(gt_sn, gt_a),
        fmt_cell(gt_r, gt_sn),
    ])
    return rows


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
missing_approach_file: list[tuple[str, str, str]] = []   # no file at all
missing_approach_sent: list[tuple[str, str, str]] = []   # file exists but not sent

# Cached roster counts, approach stats, and star3 rows for potential reprint after mailroom update
segment_roster_data: list[tuple[str, int, int, int, int, int, int, int]] = []
segment_approach_stats: list[ApproachStats] = []
segment_star3_rows: list[list[dict]] = []

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
    has_li = sum(1 for r in star3 if (r.get("linkedin_url") or "").strip())
    has_fb = sum(1 for r in star3 if (r.get("facebook_url") or "").strip())
    has_phone_only = sum(1 for r in star3 if (r.get("phone") or "").strip()
                        and not (r.get("email") or "").strip()
                        and not (r.get("linkedin_url") or "").strip()
                        and not (r.get("facebook_url") or "").strip())
    n_star3 = len(star3)

    # Approach: match files to qualifying contacts (not raw file count)
    segment_star3_rows.append(star3)
    appr_stats = classify_approach_gaps(star3, approach_dir)
    segment_approach_stats.append(appr_stats)

    # Still need scan_approach_dir for duplicate recipient / subject tracking
    _, _, _, to_map, unsent_subjs = scan_approach_dir(approach_dir)
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

    segment_roster_data.append((label, n, profiled, n_star3, has_email, has_li, has_fb, has_phone_only))

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
        for contact, org in appr_stats.missing_file:
            missing_approach_file.append((label, contact, org))
        for contact, org in appr_stats.unsent:
            missing_approach_sent.append((label, contact, org))

table_rows = build_progress_rows(segment_roster_data, segment_approach_stats)
print_md_table(TABLE_HEADERS, table_rows, TABLE_ALIGNS)

if not args.legend:
    print()
    print("Run with --legend to see column definitions.")

if args.legend:
    print()
    print("Column legend:")
    print("  Valid      — roster rows where date_found_invalid is blank (/ total roster rows)")
    print("  Profile    — valid entries with a matching profile file (/ Valid)")
    print("  3★+        — valid rows with star_rating >= 3 (/ Valid)")
    print("  A/3★+      — 3★+ contacts matched to an approach file by name (/ 3★+)")
    print("  Email      — 3★+ rows with an email address (/ 3★+)")
    print("  A/Eml      — approach files for 3★+ contacts who have email (/ Email)")
    print("  LinkedIn   — 3★+ rows with a linkedin_url (/ 3★+)")
    print("  Facebook   — 3★+ rows with a facebook_url (/ 3★+)")
    print("  Phone-only — 3★+ rows with only phone (no email, LinkedIn, or Facebook) (/ 3★+)")
    print("  Sent       — matched approach files with an actioned final round (/ A/3★+)")
    print("  Repl       — matched approach files with a reply marker (/ Sent)")
    print()
    print("Approach matching uses the contact name slug as a prefix against approach filenames.")
    print("Orphaned files (for invalidated or downgraded contacts) are not counted.")

# Duplicate recipient report (only flag actual email addresses, skip placeholders)
dups = {addr: entries for addr, entries in all_to_map.items() if len(entries) > 1 and "@" in addr}
if dups:
    print()
    print("## Duplicate recipients")
    print()
    print("Same To: address in multiple approach files.")
    print()
    for addr, entries in sorted(dups.items()):
        print(f"- **{addr}**")
        for segment_label, fname in entries:
            print(f"  - {segment_label}/{fname}")

# Cross-segment duplicates by name
name_dups = {k: v for k, v in all_contacts_by_name.items() if len(set(ch for ch, *_ in v)) > 1}
if name_dups:
    print()
    print("## Duplicate contacts by name")
    print()
    print("Same person in multiple segments.")
    print()
    for nk, entries in sorted(name_dups.items(), key=lambda x: x[0]):
        display_name = entries[0][1]
        print(f"- **{display_name}**")
        for ch, _name, org, email in entries:
            print(f"  - [{ch}] {org}" + (f"  <{email}>" if email else ""))

# Cross-segment duplicates by email
email_dups = {k: v for k, v in all_contacts_by_email.items() if len(set(ch for ch, *_ in v)) > 1}
if email_dups:
    print()
    print("## Duplicate contacts by email")
    print()
    print("Same email in multiple segments.")
    print()
    for addr, entries in sorted(email_dups.items()):
        print(f"- **{addr}**")
        for ch, contact, org in entries:
            print(f"  - [{ch}] {contact} — {org}")

# Duplicate subject lines among unsent approach files
subj_dups = {s: entries for s, entries in all_unsent_subjects.items() if len(entries) > 1}
if subj_dups:
    print()
    print("## Identical subject lines in unsent approaches")
    print()
    for subj, entries in sorted(subj_dups.items()):
        print(f"- **Subject:** {subj}")
        for segment_label, fname in entries:
            print(f"  - {segment_label}/{fname}")

# --missing detail sections
if "S" in missing_stages and missing_sweep:
    print()
    print("## Sweep coverage (S)")
    print()
    print("Max sweep_iteration per segment.")
    print()
    for label, max_sweep in missing_sweep:
        print(f"- {label} \u2014 sweep {max_sweep}")
    print()
    print("> Caveat: cannot distinguish 'not yet swept' from 'swept with no result'.")

if "P" in missing_stages and missing_profile:
    print()
    print(f"## Missing profiles (P) \u2014 {len(missing_profile)} valid entries with no profile")
    print()
    for label, contact, org in missing_profile:
        print(f"- [{label}] {contact or '(no contact)'} \u2014 {org}")

if "A" in missing_stages and missing_approach_file:
    print()
    print(f"## Missing approach files (A) \u2014 {len(missing_approach_file)} contacts with no file")
    print()
    for label, contact, org in missing_approach_file:
        print(f"- [{label}] {contact} \u2014 {org}")

if "A" in missing_stages and missing_approach_sent:
    print()
    print(f"## Unsent approaches (A) \u2014 {len(missing_approach_sent)} files not yet sent")
    print()
    for label, contact, org in missing_approach_sent:
        print(f"- [{label}] {contact} \u2014 {org}")

# =============================================================================
# Reply update via mailroom
# =============================================================================


def extract_email_address(header: str) -> str:
    """Extract bare email from 'Name <email>' or bare 'email' format."""
    m = re.search(r"<([^>]+)>", header)
    if m:
        return m.group(1).lower()
    return header.strip().lower()


def html_to_text(body: str) -> str:
    """Strip HTML to plain text, excluding quoted-original blockquotes."""
    from html import unescape
    from html.parser import HTMLParser

    class Stripper(HTMLParser):
        def __init__(self):
            super().__init__()
            self.parts: list[str] = []
            self._bq_depth = 0

        def handle_starttag(self, tag, attrs):
            if tag == "blockquote":
                self._bq_depth += 1
            elif self._bq_depth == 0:
                if tag == "br":
                    self.parts.append("\n")
                elif tag in ("div", "p"):
                    if self.parts and self.parts[-1] not in ("\n", ""):
                        self.parts.append("\n")

        def handle_endtag(self, tag):
            if tag == "blockquote":
                self._bq_depth = max(0, self._bq_depth - 1)

        def handle_data(self, data):
            if self._bq_depth == 0:
                self.parts.append(data)

    s = Stripper()
    s.feed(unescape(body))
    text = "".join(s.parts)
    # Trim at forwarded-original markers and quoted text
    lines = text.split("\n")
    clean = []
    for line in lines:
        if re.match(r"^From:\s", line):
            break
        if re.match(r"^-{5,}.*Original Message", line):
            break
        if re.match(r"^>\s", line):
            break
        clean.append(line)
    text = "\n".join(clean)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def normalise_subject(s: str) -> str:
    """Strip Re:/RE:/Fwd:/FW: prefixes, collapse whitespace, lowercase."""
    s = re.sub(r"^(Re|RE|Fwd|FW)\s*:\s*", "", s)
    s = re.sub(r"\s+", " ", s)
    return s.lower().strip()


def collect_sent_approaches(
    segments: list, base: Path
) -> list[tuple[Path, str, set[str]]]:
    """Return [(approach_path, to_email, existing_fingerprints)] for sent approaches.

    Each fingerprint is (from_email_lower, date_string) joined with '|'.
    Legacy date-only values are stored as-is; a legacy fingerprint 'x|2026-04-07'
    matches any message from x on that date (see _fingerprint_match).
    """
    import yaml as _yaml
    results: list[tuple[Path, str, set[str]]] = []
    for segment_dir, _ in segments:
        approach_dir = segment_dir / "approach"
        if not approach_dir.is_dir():
            continue
        for yf in approach_dir.glob("*.yaml"):
            try:
                data = _yaml.safe_load(yf.read_text(encoding="utf-8", errors="replace"))
            except Exception:
                continue
            if not isinstance(data, dict):
                continue
            is_sent = False
            to_email = ""
            fingerprints: set[str] = set()
            for r in data.get("rounds", []):
                if r.get("type") != "final":
                    continue
                for msg in r.get("messages", []):
                    ad = msg.get("actioned_date")
                    if ad and str(ad) not in ("~", "None", "null"):
                        is_sent = True
                    if msg.get("channel") == "email":
                        if msg.get("to") and not to_email:
                            to_email = str(msg["to"]).strip().lower()
                for reply in r.get("replies", []):
                    rd = reply.get("date")
                    rf = reply.get("from", "")
                    if rd:
                        from_addr = extract_email_address(rf) if rf else ""
                        fingerprints.add(f"{from_addr}|{str(rd)}")
            if not is_sent or not to_email:
                continue
            results.append((yf, to_email, fingerprints))
    return results


def _fingerprint_match(existing: set[str], from_email: str, timestamp: str) -> bool:
    """Check if a message is already recorded.

    Exact match on full timestamp, or prefix match for legacy date-only entries
    (a legacy '2026-04-07' matches any timestamp starting with that date from
    the same sender).  Also matches entries with an empty from-address (manually
    added replies that omitted the from field).
    """
    candidate = f"{from_email}|{timestamp}"
    if candidate in existing:
        return True
    # Legacy: existing entry may be date-only
    date_only = f"{from_email}|{timestamp[:10]}"
    if date_only in existing:
        return True
    # Legacy: existing entry may have empty from_addr
    if from_email:
        if f"|{timestamp}" in existing or f"|{timestamp[:10]}" in existing:
            return True
    return False


def _append_reply_to_yaml(approach_path: Path, msg_timestamp: str, from_display: str, reply_text: str) -> None:
    """Append a received reply to the final round's replies list in a YAML approach file."""
    import yaml as _yaml
    data = _yaml.safe_load(approach_path.read_text(encoding="utf-8", errors="replace"))
    if not isinstance(data, dict):
        return
    final_round = None
    for r in data.get("rounds", []):
        if r.get("type") == "final":
            final_round = r
    if final_round is None:
        return
    if "replies" not in final_round:
        final_round["replies"] = []
    final_round["replies"].append({
        "direction": "received",
        "date": msg_timestamp,
        "from": from_display,
        "body": reply_text,
    })
    # Also set replied_date on email messages in the final round if not already set
    for msg in final_round.get("messages", []):
        if msg.get("channel") == "email":
            rd = msg.get("replied_date")
            if not rd or str(rd) in ("~", "None", "null"):
                msg["replied_date"] = msg_timestamp[:10]
    approach_path.write_text(
        _yaml.dump(data, default_flow_style=False, allow_unicode=True, sort_keys=False, width=200),
        encoding="utf-8",
    )


def update_replies_from_mailroom(
    segments: list,
    base: Path,
    mailroom_account: str,
    mailroom_folder: str,
    sender_email: str,
) -> int:
    """Sync replies per-contact via mailroom. Return new-reply count, or -1 on error.

    Thread-based approach: for each sent approach, query mailroom for messages
    from the contact's email address. Dedup by (from, timestamp) fingerprint
    rather than a high-water mark, so no replies are missed due to clock skew
    or same-day collisions.
    """
    import json
    import subprocess

    approaches = collect_sent_approaches(segments, base)
    if not approaches:
        return 0

    # Check mailroom is available
    try:
        subprocess.run(["mailroom", "--help"], capture_output=True, timeout=5)
    except FileNotFoundError:
        print(
            "Warning: mailroom CLI not found. Install mailroom to enable reply checking.",
            file=sys.stderr,
        )
        return -1

    sender_lower = sender_email.lower()
    new_replies = 0

    # Group approaches by to_email to avoid duplicate queries
    by_to: dict[str, list[tuple[Path, set[str]]]] = {}
    for approach_path, to_email, fingerprints in approaches:
        by_to.setdefault(to_email, []).append((approach_path, fingerprints))

    for to_email, approach_entries in by_to.items():
        try:
            result = subprocess.run(
                [
                    "mailroom", "-a", mailroom_account,
                    "search", "-f", mailroom_folder,
                    "--limit", "50",
                    f"from:{to_email}",
                ],
                capture_output=True, text=True, timeout=15,
            )
        except subprocess.TimeoutExpired:
            print(f"  Warning: mailroom search timed out for {to_email}", file=sys.stderr)
            continue
        if result.returncode != 0:
            continue

        try:
            messages = json.loads(result.stdout)
        except json.JSONDecodeError:
            continue

        # Filter to messages addressed to the sender (not forwarded elsewhere)
        incoming = []
        for msg in messages:
            to_addrs = [extract_email_address(a) for a in (msg.get("to") or [])]
            if sender_lower in to_addrs:
                incoming.append(msg)

        incoming.sort(key=lambda m: m.get("date", ""))

        for msg in incoming:
            from_email = extract_email_address(msg.get("from", ""))
            date_str = msg.get("date", "")
            if not re.match(r"\d{4}-\d{2}-\d{2}", date_str):
                continue

            # If ANY approach file sharing this to_email already has the reply, skip
            if any(_fingerprint_match(fps, from_email, date_str)
                   for _, fps in approach_entries):
                continue

            # Fetch reply content once, add to first approach file only
            uid = msg.get("uid")
            reply_text = ""
            try:
                read_result = subprocess.run(
                    [
                        "mailroom", "-a", mailroom_account,
                        "read", "-f", mailroom_folder, "-u", str(uid),
                    ],
                    capture_output=True, text=True, timeout=15,
                )
                if read_result.returncode == 0:
                    email_data = json.loads(read_result.stdout)
                    body = email_data.get("body", "")
                    reply_text = html_to_text(body) if body else "(no text content)"
                else:
                    reply_text = (
                        f"(mailroom read failed -- review manually:\n"
                        f"  mailroom -a {mailroom_account} read -f {mailroom_folder} -u {uid})"
                    )
            except Exception:
                reply_text = (
                    f"(could not fetch -- review manually:\n"
                    f"  mailroom -a {mailroom_account} read -f {mailroom_folder} -u {uid})"
                )

            approach_path, fingerprints = approach_entries[0]
            from_display = msg.get("from", from_email)
            _append_reply_to_yaml(approach_path, date_str, from_display, reply_text)
            fingerprints.add(f"{from_email}|{date_str}")

            new_replies += 1
            label = str(approach_path.parent.parent.relative_to(base))
            print(f"  + {label}/{approach_path.name}: reply from {from_email} ({date_str})")

    return new_replies


def print_updated_table(
    segment_roster_data: list[tuple[str, int, int, int, int, int, int, int]],
    segments: list,
    base: Path,
):
    """Reprint progress table with recomputed approach stats (picks up new replies)."""
    global segment_approach_stats
    segment_approach_stats = [
        classify_approach_gaps(star3, seg_dir / "approach")
        for star3, (seg_dir, _) in zip(segment_star3_rows, segments)
    ]
    print()
    print("Updated progress:")
    print_md_table(TABLE_HEADERS, build_progress_rows(segment_roster_data, segment_approach_stats), TABLE_ALIGNS)


# --- Run mailroom reply check ---

if args.no_mailroom:
    pass
elif not _reply_check:
    print()
    print(
        "Note: no reply_check section in campaign YAML. "
        "Add reply_check.mailroom_account and reply_check.folder to enable reply checking.",
        file=sys.stderr,
    )
elif not _sender_email:
    print()
    print("Note: no sender.email in campaign YAML; cannot check replies.", file=sys.stderr)
else:
    mr_account = _reply_check.get("mailroom_account", "")
    mr_folder = _reply_check.get("folder", "")
    if not mr_account or not mr_folder:
        print()
        print(
            "Note: reply_check.mailroom_account and reply_check.folder must both be set.",
            file=sys.stderr,
        )
    else:
        if args.update:
            answer = "y"
        else:
            print()
            try:
                answer = input("Update reply status from mailroom? [y/N] ").strip().lower()
            except EOFError:
                print("No input — you're probably a bot, that's fine. Mailroom skipped, progress is above.")
                answer = ""
        if answer == "y":
            print(f"Checking email replies ({mr_account}, folder: {mr_folder})...")
            n_new = update_replies_from_mailroom(
                segments, BASE, mr_account, mr_folder, _sender_email
            )
            if n_new > 0:
                print(f"  {n_new} new repl{'ies' if n_new != 1 else 'y'} recorded.")
                print_updated_table(segment_roster_data, segments, BASE)
            elif n_new == 0:
                print("  No new replies.")
