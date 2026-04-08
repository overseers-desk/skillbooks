#!/usr/bin/env python3
from __future__ import annotations
"""Show outreach pipeline progress per segment, and update reply status from mailroom.

Each column (except Valid) shows count and percentage of its denominator:
  Valid     — roster rows where date_found_invalid is blank
  Profile   — valid entries with a matching profile file (/ Valid)
  3★+       — valid rows with star_rating >= 3 (/ Valid)
  E         — 3★+ rows with an email address (/ 3★+)
  L         — 3★+ rows with a linkedin_url (/ 3★+)
  F         — 3★+ rows with a facebook_url (/ 3★+)
  ☎only     — 3★+ rows with only phone (no email, linkedin, or facebook) (/ 3★+)
  Approach  — approach files in approach/ (/ 3★+)
  Sent      — approach files with a sent date (/ Approach)
  Repl      — approach files with a reply marker (/ Sent)

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
    for roster_path in sorted(BASE.glob("*/roster.tsv")):
        rel = str(roster_path.parent.relative_to(BASE))
        if rel not in yaml_set:
            print(f"  NOTE: {rel}/roster.tsv exists but is not in this campaign", file=sys.stderr)
else:
    # Fallback: scan direct child directories only (subfolders are not segments)
    for roster_path in sorted(BASE.glob("*/roster.tsv")):
        segment_dir = roster_path.parent
        rel = segment_dir.relative_to(BASE)
        if str(rel) in SKIP:
            continue
        segments.append((segment_dir, roster_path))

has_over_100 = False


def fmt_cell(count: int, denom: int) -> str:
    """Format 'count pct%' compactly for table cells."""
    global has_over_100
    if denom:
        pct_val = count / denom * 100
        if pct_val > 100:
            has_over_100 = True
            pct = f"{pct_val:3.0f}%†"
        else:
            pct = f"{pct_val:3.0f}%"
    else:
        pct = "   -"
    return f"{count:>3} {pct}"


TABLE_HEADERS = ['Segment', 'Valid', 'Profile', '3★+', 'Email', 'LinkedIn', 'Facebook', 'Phone-only', 'Approach', 'Sent', 'Repl']
TABLE_ALIGNS = ['l', 'r', 'r', 'r', 'r', 'r', 'r', 'r', 'r', 'r', 'r']


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
    segments: list,
) -> list[list[str]]:
    """Build table rows (including TOTAL) from cached roster data and current approach files."""
    rows: list[list[str]] = []
    gt_v = gt_p = gt_s = gt_e = gt_l = gt_f = gt_po = gt_a = gt_sn = gt_r = 0
    for (label, n, profiled, n_star3, has_email, has_li, has_fb, has_phone_only), (segment_dir, _) in zip(
        segment_roster_data, segments
    ):
        approach_dir = segment_dir / "approach"
        appr_total, appr_sent, appr_replied, _, _ = scan_approach_dir(approach_dir)
        rows.append([
            label,
            str(n),
            fmt_cell(profiled, n),
            fmt_cell(n_star3, n),
            fmt_cell(has_email, n_star3),
            fmt_cell(has_li, n_star3),
            fmt_cell(has_fb, n_star3),
            fmt_cell(has_phone_only, n_star3),
            fmt_cell(appr_total, n_star3),
            fmt_cell(appr_sent, appr_total),
            fmt_cell(appr_replied, appr_sent),
        ])
        gt_v += n; gt_p += profiled; gt_s += n_star3; gt_e += has_email
        gt_l += has_li; gt_f += has_fb; gt_po += has_phone_only
        gt_a += appr_total; gt_sn += appr_sent; gt_r += appr_replied
    rows.append([
        'TOTAL',
        str(gt_v),
        fmt_cell(gt_p, gt_v),
        fmt_cell(gt_s, gt_v),
        fmt_cell(gt_e, gt_s),
        fmt_cell(gt_l, gt_s),
        fmt_cell(gt_f, gt_s),
        fmt_cell(gt_po, gt_s),
        fmt_cell(gt_a, gt_s),
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
missing_approach: list[tuple[str, str, str, str]] = []

# Cached roster counts for potential reprint after mailroom update
segment_roster_data: list[tuple[str, int, int, int, int, int, int, int]] = []

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

table_rows = build_progress_rows(segment_roster_data, segments)
print_md_table(TABLE_HEADERS, table_rows, TABLE_ALIGNS)

if has_over_100:
    print()
    print("† Exceeds 100% because approach files exist for entries that were subsequently invalidated or rated below the 3★ threshold.")

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

if "A" in missing_stages and missing_approach:
    print()
    print(f"## Missing/unsent approaches (A) \u2014 {len(missing_approach)} entries")
    print()
    for label, contact, org, reason in missing_approach:
        print(f"- [{label}] {contact} \u2014 {org} ({reason})")

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


def collect_sent_approach_data(
    segments: list, base: Path
) -> tuple[dict[str, list[tuple[Path, str | None]]], dict[str, list[tuple[Path, str, str | None]]]]:
    """Build lookup maps for sent approach files.

    Returns (by_email, by_subject):
      by_email:   {to_email_lower: [(approach_path, latest_reply_date), ...]}
      by_subject: {normalised_subject: [(approach_path, to_email_lower, latest_reply_date), ...]}
    """
    by_email: dict[str, list[tuple[Path, str | None]]] = {}
    by_subject: dict[str, list[tuple[Path, str, str | None]]] = {}
    for segment_dir, _ in segments:
        approach_dir = segment_dir / "approach"
        if not approach_dir.is_dir():
            continue
        for md in approach_dir.glob("approach-*.md"):
            content = md.read_text(encoding="utf-8", errors="replace")
            if not re.search(
                r"^### .+\((Sent|Called) \d{4}-\d{2}-\d{2}\)", content, re.MULTILINE
            ):
                continue
            fd = re.search(r"^## Final draft", content, re.MULTILINE)
            if not fd:
                continue
            after = content[fd.start() :]
            to_m = re.search(r"^To: (.+)$", after, re.MULTILINE)
            if not to_m:
                continue
            to_email = to_m.group(1).strip().lower()
            subj_m = re.search(r"^Subject: (.+)$", after, re.MULTILINE)
            subject = subj_m.group(1).strip() if subj_m else ""
            reply_dates = re.findall(
                r"^### .+ Replied \((\d{4}-\d{2}-\d{2})\)", content, re.MULTILINE
            )
            latest = max(reply_dates) if reply_dates else None
            by_email.setdefault(to_email, []).append((md, latest))
            if subject:
                ns = normalise_subject(subject)
                by_subject.setdefault(ns, []).append((md, to_email, latest))
    return by_email, by_subject


def update_replies_from_mailroom(
    segments: list,
    base: Path,
    mailroom_account: str,
    mailroom_folder: str,
    sender_email: str,
) -> int:
    """Fetch replies from mailroom, append Replied sections. Return new-reply count, or -1 on error."""
    import json
    import subprocess

    by_email, by_subject = collect_sent_approach_data(segments, base)
    if not by_email:
        return 0

    try:
        result = subprocess.run(
            [
                "mailroom", "-a", mailroom_account,
                "search", "-f", mailroom_folder, "--limit", "500",
            ],
            capture_output=True, text=True, timeout=30,
        )
    except FileNotFoundError:
        print(
            "Warning: mailroom CLI not found. Install mailroom to enable reply checking.",
            file=sys.stderr,
        )
        return -1
    except subprocess.TimeoutExpired:
        print("Warning: mailroom search timed out.", file=sys.stderr)
        return -1

    if result.returncode != 0:
        print(f"Warning: mailroom search failed: {result.stderr.strip()}", file=sys.stderr)
        return -1

    try:
        messages = json.loads(result.stdout)
    except json.JSONDecodeError:
        print("Warning: could not parse mailroom output.", file=sys.stderr)
        return -1

    sender_lower = sender_email.lower()

    # Filter to incoming replies.
    # A message is outgoing if from == sender without DMARC rewrite ("via").
    # A message is incoming if to contains the sender address AND it's not outgoing.
    incoming = []
    for msg in messages:
        from_header = msg.get("from", "")
        from_email = extract_email_address(from_header)
        if from_email == sender_lower and " via " not in from_header:
            continue  # outgoing message from the campaign sender
        to_addrs = [extract_email_address(a) for a in (msg.get("to") or [])]
        if sender_lower in to_addrs:
            incoming.append(msg)

    # Sort by date ascending so high-water marks update in order
    incoming.sort(key=lambda m: m.get("date", ""))

    new_replies = 0
    unmatched = []
    for msg in incoming:
        from_email = extract_email_address(msg.get("from", ""))
        date_str = msg.get("date", "")
        date_match = re.match(r"(\d{4}-\d{2}-\d{2})", date_str)
        if not date_match:
            continue
        msg_date = date_match.group(1)

        # Match by sender email (normal case)
        matched_entries = by_email.get(from_email, [])

        # Fallback: match by subject (DMARC-rewritten replies)
        if not matched_entries:
            subj = normalise_subject(msg.get("subject", ""))
            if subj:
                matched_entries = [
                    (path, latest) for path, _email, latest in by_subject.get(subj, [])
                ]

        if not matched_entries:
            # Unknown reply — warn if it looks like a real reply (has Re: prefix)
            raw_subj = msg.get("subject", "")
            if re.match(r"(?i)^(Re|RE|Fwd|FW)\s*:", raw_subj):
                unmatched.append((from_email, raw_subj, msg_date))
            continue

        for approach_path, latest_reply_date in matched_entries:
            if latest_reply_date and msg_date <= latest_reply_date:
                continue

            # Fetch reply content
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

            from_display = msg.get("from", from_email)
            section = (
                f"\n\n### Email Replied ({msg_date})\n\n"
                f"From: {from_display}\n\n"
                f"{reply_text}\n"
            )
            with open(approach_path, "a", encoding="utf-8") as f:
                f.write(section)

            # Update high-water mark in memory
            entries = by_email.get(from_email, [])
            for i, (p, _d) in enumerate(entries):
                if p == approach_path:
                    entries[i] = (p, msg_date)
                    break

            new_replies += 1
            label = str(approach_path.parent.parent.relative_to(base))
            print(f"  + {label}/{approach_path.name}: reply from {from_email} ({msg_date})")

    if unmatched:
        print()
        print("  Unmatched incoming replies (no approach file found):")
        for addr, subj, dt in unmatched:
            print(f"    {addr}  {subj}  ({dt})")

    return new_replies


def print_updated_table(
    segment_roster_data: list[tuple[str, int, int, int, int, int, int, int]],
    segments: list,
    base: Path,
):
    """Reprint progress table with updated reply counts from approach files."""
    print()
    print("Updated progress:")
    print_md_table(TABLE_HEADERS, build_progress_rows(segment_roster_data, segments), TABLE_ALIGNS)


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
