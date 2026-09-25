#!/usr/bin/env python3
"""Build entry-cut.tsv: one row per type A unit of the 45, copying the coded
V25 paid-entry fields from coded-whom-sold-to.tsv and the survey's coded V7
price-basis fields from each unit's own profile, with card 11's list marked."""

import os
import re
import sys

RUN = "/usr/local/src/rivermill/product-development/party-packages/2026-08-15-how-party-packages-were-decided"
SURVEY = "/usr/local/src/rivermill/product-development/party-packages/2026-08-15-party-survey"
CODED = os.path.join(SURVEY, "4-collection", "coded")
TSV = os.path.join(RUN, "0-comparables", "whom-sold-to", "coded-whom-sold-to.tsv")
OUT = os.path.join(RUN, "0-comparables", "whom-sold-to", "entry-cut.tsv")

DROP = {
    "gold-coast-aquatic-centre", "gold-coast-equine-connections",
    "jummps-indoor-trampoline-park", "golden-ridge-animal-farm",
    "own-site", "README",
}

# Hand-marked. Source: card-12-who-runs-the-party.md, Corrections line of
# 2026-09-20, which names the seventeen card 11 sets aside.
CARD11_17 = {
    "bellas-wonderland", "chipmunks-playland-robina",
    "doodlebugs-indoor-play-party-centre", "game-over-gold-coast",
    "bounce-gold-coast", "strike-bowling-gold-coast",
    "zone-bowling-surfers-paradise", "timezone-robina",
    "slideways-go-karting-gold-coast", "topgolf-gold-coast",
    "event-cinemas-gold-coast", "city-of-gold-coast-community-venues",
    "kdv-sport", "gold-coast-turf-club", "the-star-gold-coast",
    "currumbin-rsl-waterside-events", "tugun-tavern",
}

V25_COLS = [
    "V25_general_entry_fee", "V25_entry_free", "V25_party_entry_included",
    "V25_party_entry_extra", "V25_party_adults_entry_separate",
    "V25_prepaid_ticket_required", "V25_entry_not_addressed", "V25_summary",
]

V7_FIELDS = [
    "per_head", "flat", "per_hour", "per_room", "tier_headcount",
    "tier_day", "tier_season", "min_spend", "per_extra_guest", "addon_priced",
]


def strip_cell(s):
    return s.strip().strip('"').strip()


def load_coded():
    rows = {}
    with open(TSV, encoding="utf-8") as fh:
        header = [strip_cell(c) for c in fh.readline().rstrip("\n").split("\t")]
        idx = {name: i for i, name in enumerate(header)}
        for line in fh:
            cells = [strip_cell(c) for c in line.rstrip("\n").split("\t")]
            key = os.path.basename(cells[idx["profile_file"]])
            if key.endswith(".md"):
                key = key[:-3]
            if key in rows:
                continue  # type A profiles give one row; first wins
            rows[key] = {c: (cells[idx[c]] if idx[c] < len(cells) else "") for c in V25_COLS}
            rows[key]["note"] = cells[idx["note"]] if idx["note"] < len(cells) else ""
    return rows


FIELD_RE = re.compile(r"`?V7_([a-z_]+)`?\s*(?:=|:)?\s*\*{0,2}(\d)")


def v7_for(path):
    """Return {field: set(values)} read from the profile's V7 section."""
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    m = re.search(r"^#+ *(?:\d+\.\s*)?V7\b.*$", text, re.M)
    if not m:
        return None
    rest = text[m.end():]
    m2 = re.search(r"^#+ *(?:\d+\.\s*)?V8\b", rest, re.M)
    section = rest[:m2.start()] if m2 else rest
    found = {}
    for line in section.splitlines():
        if line.lstrip().startswith("|"):
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            fm = re.search(r"V7_([a-z_]+)", cells[0]) if cells else None
            if not fm:
                continue
            for cell in cells[1:]:
                vm = re.match(r"\*{0,2}(\d)", cell.strip())
                if vm:
                    found.setdefault(fm.group(1), set()).add(vm.group(1))
        else:
            hits = list(FIELD_RE.finditer(line))
            for i, m in enumerate(hits):
                name, val = m.group(1), m.group(2)
                found.setdefault(name, set()).add(val)
                # a coder who writes a field 1 and then "recorded as **8**"
                # in the same clause has logged the cell as unclear
                end = hits[i + 1].start() if i + 1 < len(hits) else len(line)
                for bold in re.findall(r"\*\*(\d)\*\*", line[m.end():end]):
                    found[name].add(bold)
    return found


def main():
    coded = load_coded()
    out_rows = []
    for cell in ("r1", "r2c"):
        d = os.path.join(CODED, cell)
        for fn in sorted(os.listdir(d)):
            if not fn.endswith(".md"):
                continue
            key = fn[:-3]
            if key in DROP:
                continue
            v7 = v7_for(os.path.join(d, fn))
            if v7 is None:
                print("no V7 section: %s" % key, file=sys.stderr)
                v7 = {}
            basis = ",".join(f for f in V7_FIELDS if "1" in v7.get(f, set())) or "none"
            unclear = ",".join(f for f in V7_FIELDS if "8" in v7.get(f, set())) or "none"
            c = coded.get(key)
            if c is None:
                print("no coded row: %s" % key, file=sys.stderr)
                c = {k: "" for k in V25_COLS}
                c["note"] = ""
            row = {
                "profile_key": key,
                "cell": cell,
                "on_card_11_list": "1" if key in CARD11_17 else "0",
                "V7_basis_stated": basis,
                "V7_unclear": unclear,
            }
            for col in V25_COLS:
                row[col] = c.get(col, "")
            row["doubt"] = doubt_for(row, c.get("note", ""))
            out_rows.append(row)

    cols = (["profile_key", "cell"] + V25_COLS +
            ["V7_basis_stated", "V7_unclear", "on_card_11_list", "doubt"])
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\t".join(cols) + "\n")
        for r in out_rows:
            fh.write("\t".join(str(r[c]) for c in cols) + "\n")
    print("wrote %d rows to %s" % (len(out_rows), OUT))


def doubt_for(row, note):
    """Every clause is derived from the copied cells by rule, not read off a page."""
    d = []
    if row["V25_summary"] in ("9", ""):
        d.append("V25 not captured")
    if row["V25_general_entry_fee"] == "9":
        d.append("general entry fee not captured")
    if row["V25_entry_free"] == "8":
        d.append("entry-free cell undecidable")
    if row["V25_entry_not_addressed"] == "1":
        d.append("fee stated and the party's position at it not addressed")
    if (row["on_card_11_list"] == "1" and row["V25_general_entry_fee"] != "1"
            and "per_head" not in row["V7_basis_stated"]):
        d.append("on card 11's list with neither a coded entry fee nor a per-head basis")
    if row["V7_unclear"] != "none":
        d.append("price basis coded 8 at " + row["V7_unclear"])
    if row["V7_basis_stated"] == "none":
        d.append("no price basis stated")
    return "; ".join(d) if d else "none"


main()
