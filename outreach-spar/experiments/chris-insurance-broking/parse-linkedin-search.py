#!/usr/bin/env python3
"""Parse a LinkedIn people-search result page (archived HTML) into rows.

Usage: parse-linkedin-search.py <file.html>
Emits TSV: stem<TAB>contact_name<TAB>headline<TAB>location<TAB>degree

Extraction is strictly per-card: each `role="listitem"` block is a self-
contained unit; fields are read from positional lines within that block
(name=line 0, headline=line 2, location=line 3), so content from one
card cannot bleed into another.

Locale-defensive: this parser does not assume any UI chrome language.
It reads structural positions, not substrings of the rendered text.
"""
import html
import re
import sys


# Phrases that indicate we have walked OUT of the data slots and into the
# card's contextual tail (mutuals, keywords, role history). Used only to
# detect whether the expected structural positions (lines 0/2/3) are the
# actual data, not to filter legitimate content like "Sídney y alrededores"
# which is LinkedIn's Spanish rendering of a real location ("Sydney area").
NON_NAME_MARKERS = (
    "• 1º", "• 2º", "• 3º", "• 3er", "• 1st", "• 2nd", "• 3rd",
    "contacto más en común", "contactos más en común",
    "mutual connection", "mutual connections",
    "seguidores", "followers",
    "Anterior:", "Actual:", "Aptitudes:", "Certificaciones:",
    "Previous:", "Current:", "Skills:", "Certifications:",
)


def looks_like_non_name(line: str) -> bool:
    """True if this line cannot be the person's display name."""
    if not line or line in (",", "…", "•", "y", "and"):
        return True
    return any(marker in line for marker in NON_NAME_MARKERS)


def parse_card(card_html: str) -> dict | None:
    m = re.search(r'href="https://www\.linkedin\.com/in/([a-zA-Z0-9_-]+)', card_html)
    if not m:
        return None
    stem = m.group(1).rstrip("/")

    text = re.sub(r"<script[^>]*>.*?</script>", "", card_html, flags=re.DOTALL)
    text = re.sub(r"<style[^>]*>.*?</style>", "", text, flags=re.DOTALL)
    text = re.sub(r"<[^>]+>", "\n", text)
    text = html.unescape(text)
    lines = [l.strip() for l in text.split("\n") if l.strip()]
    if len(lines) < 4:
        return None

    # Structural slots: first non-chrome line is the name, then degree
    # indicator, then headline, then location. We do not search past
    # line 3 for any of these slots.
    name = lines[0]
    degree_line = lines[1] if len(lines) > 1 else ""
    headline = lines[2] if len(lines) > 2 else ""
    location = lines[3] if len(lines) > 3 else ""

    # Only reject if the name slot obviously isn't a name. Headline and
    # location can contain language-specific legitimate strings ("Sídney y
    # alrededores" is a real location) and should not be filtered here.
    if looks_like_non_name(name):
        return None

    # Strip URL-slug suffix from display name (e.g. "Troy Clarry 8032339")
    name = re.sub(r"\s+[0-9A-Fa-f]{6,}$", "", name)

    degree = ""
    dm = re.search(r"(1º|1er|2º|2nd|3º|3er\+?)", degree_line)
    if dm:
        d = dm.group(1)
        if d.startswith("1"):
            degree = "1"
        elif d.startswith("2"):
            degree = "2"
        elif d.startswith("3"):
            degree = "3+"

    # Split headline into (role, organisation) where possible. LinkedIn
    # headlines commonly separate role and employer with " at ", " @ ",
    # " — " or " | ". If no separator is present we leave org blank and
    # put the whole headline in role; the P-harness will fetch the
    # profile and resolve organisation from the About/Experience section.
    role, organisation = headline, ""
    for sep in (" at ", " @ ", " - ", " — ", " | "):
        if sep in headline:
            role, organisation = headline.split(sep, 1)
            role = role.strip()
            organisation = organisation.strip()
            break

    # Country from the location string.
    country = ""
    loc_lower = location.lower()
    if "australia" in loc_lower:
        country = "AU"
    elif "zelanda" in loc_lower or "zealand" in loc_lower:
        country = "NZ"

    return {
        "stem": stem,
        "contact_name": name,
        "headline": headline,
        "role": role,
        "organisation": organisation,
        "location": location,
        "country": country,
        "degree": degree,
    }


def parse_file(path: str) -> list[dict]:
    with open(path, encoding="utf-8") as fh:
        page = fh.read()
    starts = [m.start() for m in re.finditer(r'<div[^>]*role="listitem"[^>]*>', page)]
    ends = starts[1:] + [len(page)]
    rows = []
    for s, e in zip(starts, ends):
        row = parse_card(page[s:e])
        if row:
            rows.append(row)
    return rows


def main():
    if len(sys.argv) < 2:
        print("usage: parse-linkedin-search.py <file.html> [...]", file=sys.stderr)
        sys.exit(2)
    cols = ("stem", "contact_name", "role", "organisation", "headline", "location", "country", "degree")
    print("\t".join(cols))
    for path in sys.argv[1:]:
        for row in parse_file(path):
            print("\t".join(row[k] for k in cols))


if __name__ == "__main__":
    main()
