"""Shared library for SPAR outreach pipeline scripts.

Provides campaign context loading, name handling, approach file operations,
and validation infrastructure used by update-campaign.py, spar-A-validate.py,
and spar-S-validate.py.
"""
from __future__ import annotations

import csv
import io
import re
import sys
import unicodedata
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None


# ── Campaign context ─────────────────────────────────────────────────────


def discover_campaign_yaml(base: Path, explicit: str | None = None) -> Path | None:
    """Find the campaign YAML file.

    If *explicit* is a file path, return it resolved.  If it is a directory,
    set *base* and auto-discover inside it.  Otherwise search *base* for
    ``campaign.yaml`` or the last ``campaign*.yaml`` by sort order.

    Returns None when no YAML is found.
    """
    if explicit:
        given = Path(explicit).resolve()
        if given.is_file():
            return given
        if given.is_dir():
            base = given
            # fall through to auto-discovery
        elif not given.exists():
            return None

    candidate = base / "campaign.yaml"
    if candidate.exists():
        return candidate
    candidates = sorted(base.glob("campaign*.yaml"))
    return candidates[-1] if candidates else None


def load_campaign_yaml(path: Path) -> dict | None:
    """Parse a campaign YAML file.  Returns None on failure."""
    if yaml is None:
        print("Warning: PyYAML not installed.", file=sys.stderr)
        return None
    try:
        with path.open(encoding="utf-8") as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Warning: could not parse {path.name}: {e}", file=sys.stderr)
        return None


def extract_campaign_context(
    data: dict | None,
    skip_args: list[str] | None = None,
) -> tuple[list[str] | None, set[str], dict]:
    """Extract segments, skip set, and the full dict from parsed campaign data.

    Returns ``(yaml_segments, skip_set, data)``.  *yaml_segments* is None when
    the YAML has no ``segments`` key (triggering directory-scan fallback).
    """
    if data is None:
        data = {}
    skip: set[str] = set()
    if skip_args:
        skip.update(skip_args)
    if isinstance(data.get("skip_segments"), list):
        skip.update(data["skip_segments"])
    yaml_segments: list[str] | None = None
    if isinstance(data.get("segments"), list):
        yaml_segments = data["segments"]
    return yaml_segments, skip, data


def discover_segments(
    base: Path,
    yaml_segments: list[str] | None,
    skip: set[str],
    require: str = "roster",
) -> list[tuple[Path, Path]]:
    """Iterate segments and return ``[(segment_dir, required_path), ...]``.

    *require* controls what file must exist in each segment:

    - ``"roster"`` — ``roster.tsv`` (used by progress, S-validate)
    - ``"approach"`` — ``approach/`` directory (used by A-validate)

    When *yaml_segments* is not None, only those segments (minus *skip*) are
    considered.  Otherwise falls back to scanning direct children of *base*.
    """
    segments: list[tuple[Path, Path]] = []
    if yaml_segments is not None:
        for seg_name in yaml_segments:
            if seg_name in skip:
                continue
            seg_dir = base / seg_name
            if require == "approach":
                req_path = seg_dir / "approach"
                if not req_path.is_dir():
                    continue
            else:
                req_path = seg_dir / "roster.tsv"
                if not req_path.exists():
                    print(
                        f"  WARNING: segment '{seg_name}' listed in YAML but roster.tsv not found",
                        file=sys.stderr,
                    )
                    continue
            segments.append((seg_dir, req_path))
    else:
        if require == "approach":
            for req_path in sorted(base.glob("*/approach")):
                seg_dir = req_path.parent
                if str(seg_dir.relative_to(base)) in skip:
                    continue
                segments.append((seg_dir, req_path))
        else:
            for req_path in sorted(base.glob("*/roster.tsv")):
                seg_dir = req_path.parent
                if str(seg_dir.relative_to(base)) in skip:
                    continue
                segments.append((seg_dir, req_path))
    return segments


def load_roster(roster_path: Path) -> list[dict]:
    """Read a roster TSV, return rows with at least one non-empty value.

    Normalises line endings (CRLF and bare CR become LF) so that in-field
    carriage returns do not split rows when the file uses CRLF line endings.
    """
    raw = roster_path.read_bytes().replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    reader = csv.DictReader(
        io.TextIOWrapper(io.BytesIO(raw), encoding="utf-8"), delimiter="\t"
    )
    return [r for r in reader if any(v for v in r.values() if v)]


# ── Name handling ────────────────────────────────────────────────────────


def slugify(s: str) -> str:
    """Lowercase, non-alphanumeric chars to hyphens, collapse, strip edges."""
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = s.lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")


def normalise_name(s: str) -> str:
    """Strip accents, parentheticals, separators; collapse whitespace; lowercase."""
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    s = s.lower()
    s = re.sub(r"\(.*?\)", "", s)
    s = re.sub(r"[/&\u2014\u2013-]+", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def build_profile_index(profiles_dir: Path) -> dict[str, str]:
    """Return ``{normalised_name: filename}`` for profile documents."""
    index: dict[str, str] = {}
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
    """True if *contact* matches any entry in *profile_index* by prefix."""
    c = normalise_name(contact)
    if c in profile_index:
        return True
    for k in profile_index:
        if k.startswith(c) or c.startswith(k):
            return True
    return False


# ── Approach file operations ─────────────────────────────────────────────


def parse_star(val: str) -> int:
    """Parse a ``star_rating`` field to int; return 0 if unparseable."""
    val = val.strip()
    return int(val) if val.isdigit() else 0


def is_null(val) -> bool:
    """True for None, empty strings, YAML null representations."""
    return val is None or str(val).strip() in ("~", "None", "null", "")


def match_roster_to_stems(
    rows: list[dict],
    approach_dir: Path,
    filters: dict | None = None,
) -> tuple[dict[int, str], set[str]]:
    """Two-pass matching of roster rows to approach file stems.

    Pass 1 matches by full slugified contact_name prefix.  Pass 2 uses the
    first name token only, accepted when exactly one unclaimed stem matches.

    *filters* may contain ``exclude_invalid``, ``min_star``, ``require_email``
    to pre-filter rows.

    Returns ``(matched, claimed)`` where *matched* maps row index (into
    *rows*) to the stem string, and *claimed* is the set of all stems that
    were assigned.
    """
    if filters is None:
        filters = {}
    min_star = filters.get("min_star", 0)
    require_email = filters.get("require_email", False)
    exclude_invalid = filters.get("exclude_invalid", False)

    # Filter to qualifying rows, keeping original indices
    qualifying: list[tuple[int, dict, str]] = []  # (orig_idx, row, slug)
    for idx, r in enumerate(rows):
        name = (r.get("contact_name") or "").strip()
        if not name:
            continue
        if exclude_invalid and (r.get("date_found_invalid") or "").strip():
            continue
        if min_star and parse_star(r.get("star_rating") or "") < min_star:
            continue
        if require_email and "@" not in (r.get("email") or ""):
            continue
        qualifying.append((idx, r, slugify(name)))

    if not approach_dir.is_dir():
        return {}, set()

    all_stems = {yf.stem for yf in approach_dir.glob("*.yaml")}
    claimed: set[str] = set()
    matched: dict[int, str] = {}

    # Pass 1: full slug_name prefix match
    matched_qual_idx: set[int] = set()
    for qi, (orig_idx, r, slug_name) in enumerate(qualifying):
        for stem in all_stems:
            if stem not in claimed and (stem == slug_name or stem.startswith(slug_name + "-")):
                matched[orig_idx] = stem
                claimed.add(stem)
                matched_qual_idx.add(qi)
                break

    # Pass 2: first-name-only prefix for unmatched contacts
    for qi, (orig_idx, r, slug_name) in enumerate(qualifying):
        if qi in matched_qual_idx:
            continue
        tokens = slug_name.split("-")
        if len(tokens) < 2:
            continue
        first = tokens[0]
        candidates = [s for s in all_stems if s not in claimed and s.startswith(first + "-")]
        if len(candidates) == 1:
            matched[orig_idx] = candidates[0]
            claimed.add(candidates[0])

    return matched, claimed


def approach_final_round_status(path: Path) -> tuple[bool, bool, bool]:
    """Return ``(is_sent, is_email_sent, is_replied)`` for an approach file.

    - *is_sent* — any final-round message has ``actioned_date``
    - *is_email_sent* — a final-round email message has ``actioned_date``
    - *is_replied* — a final-round message has ``replied_date`` or a received reply
    """
    if yaml is None:
        return False, False, False
    is_sent = is_email_sent = is_replied = False
    try:
        data = yaml.safe_load(path.read_text(encoding="utf-8", errors="replace"))
        if isinstance(data, dict):
            for r in data.get("rounds", []):
                if r.get("type") == "final":
                    for msg in r.get("messages", []):
                        if not is_null(msg.get("actioned_date")):
                            is_sent = True
                            if msg.get("channel") == "email":
                                is_email_sent = True
                        if not is_null(msg.get("replied_date")):
                            is_replied = True
                    for reply in r.get("replies", []):
                        if reply.get("direction") == "received":
                            is_replied = True
    except Exception:
        pass
    return is_sent, is_email_sent, is_replied


def find_unsent_final_emails(data: dict) -> list[dict]:
    """Return unsent email messages from the final round of an approach dict."""
    result = []
    for r in data.get("rounds", []):
        if r.get("type") != "final":
            continue
        for msg in r.get("messages", []):
            if msg.get("channel") != "email":
                continue
            if is_null(msg.get("actioned_date")):
                result.append(msg)
    return result


# ── Validation infrastructure ────────────────────────────────────────────


class Checker:
    """Accumulates PASS/WARN/FAIL results for a segment."""

    def __init__(self, label: str):
        self.label = label
        self.results: list[tuple[str, str]] = []

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
