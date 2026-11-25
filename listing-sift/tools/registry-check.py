#!/usr/bin/env python3
"""Check a SIFT campaign's registry against its configuration and the registry format.

Usage: registry-check.py <campaign-directory>
Reads campaign.yaml and registry.tsv in the directory. Prints one line per finding, as
"check<TAB>row id<TAB>what is wrong", then a count per check. Exits 1 when there is a finding.
The checks are the registry format's quality checklist and what follows from the configuration:
the id format, a column per dimension with scores on its scale, stars and pct against their
formulas, amplifier tags, and columns whose values the configuration lists. A scored row may lack a
score for a dimension named under `unconfirmed`, since Fit goes back over scored rows only for
dimensions the operator has agreed to.
"""
import math, re, sys
from collections import Counter
from pathlib import Path

import yaml

CORE = ("id date_found date_posted source_name title location url source alive notes_sweep "
        "stars pct pct_base hard_gates notes_fit decision date_responded status notes_target").split()
CORE_VALUES = {
    "alive": {"yes", "no", "unverified"},
    "decision": {"respond", "skip", "watch", "network-approach"},
    "status": {"not-started", "responded", "screening", "advanced", "final", "accepted", "closed", "withdrawn"},
}
PCT_CAP = 95

findings = []


def find(check, row_id, what):
    findings.append((check, row_id, what))


def number(cell):
    """A registry cell as a number, or None. A typographic minus and a leading plus are read as signs."""
    try:
        return float(cell.strip().replace("−", "-"))
    except ValueError:
        return None


def check_configuration(cfg, directory, scored, decided):
    needed = ["kind", "operator_profile", "id_format", "sources", "dimensions"]
    needed += ["amplifiers"] if scored else []
    needed += ["thresholds"] if decided else []
    for key in needed:
        if not cfg.get(key):
            find("configuration", "-", f"`{key}` is missing or empty")
    for path in cfg.get("operator_profile") or []:
        if not (directory / path).exists():
            find("configuration", "-", f"operator_profile names {path}, which is not there")
    names = []
    for dim in cfg.get("dimensions") or []:
        name = dim.get("name", "")
        names.append(name)
        if not re.fullmatch(r"[a-z][a-z0-9_]*", name):
            find("configuration", "-", f"dimension name {name!r} is not lowercase words joined by underscores")
        scale = dim.get("scale") or {}
        if not scale or any(not isinstance(k, (int, float)) or not v for k, v in scale.items()):
            find("configuration", "-", f"dimension {name}: `scale` needs each score as a number with its anchor")
    for name, n in Counter(names).items():
        if n > 1:
            find("configuration", "-", f"dimension {name} is defined {n} times")
    known = set(cfg) | set(names) | set(cfg.get("other") or {})
    for key in cfg.get("unconfirmed") or []:
        if key not in known:
            find("configuration", "-", f"`unconfirmed` names {key}, which is no key, dimension or name under `other`")


def check_registry(cfg, header, rows):
    if header[:len(CORE)] != CORE:
        find("header", "-", "the first columns are not the core columns in the registry format's order")
    width = len(header)
    ids, urls = Counter(r.get("id", "") for r in rows), Counter(r.get("url", "") for r in rows)
    prefix, digits = re.fullmatch(r"(\D*)(\d+)", str(cfg.get("id_format") or "0")).groups()
    id_form = re.compile(re.escape(prefix) + r"\d{%d,}" % len(digits))
    dims = {d.get("name"): {float(k) for k in (d.get("scale") or {}) if isinstance(k, (int, float))}
            for d in cfg.get("dimensions") or []}
    amplifiers = cfg.get("amplifiers") or {}
    tags, factor = set(amplifiers.get("tags") or {}), amplifiers.get("factor")
    unconfirmed = set(cfg.get("unconfirmed") or [])
    waiting = set(dims) if "dimensions" in unconfirmed else unconfirmed & set(dims)
    listed = dict(CORE_VALUES, **{c: set(map(str, v)) for c, v in (cfg.get("values") or {}).items()})

    for column in list(dims) + [c for c in listed if c not in CORE_VALUES]:
        if column not in header:
            find("header", "-", f"no column `{column}`, which the configuration calls for")

    for row in rows:
        rid = row.get("id") or f"line {row['_line']}"
        if row["_width"] != width:
            find("fields", rid, f"{row['_width']} fields where the header has {width}")
        if not row.get("id"):
            find("id", rid, "empty id")
        elif ids[row["id"]] > 1:
            find("id", rid, "id is shared with another row")
        elif not id_form.fullmatch(row["id"]):
            find("id", rid, f"id is not in the configuration's format ({cfg.get('id_format')})")
        if not row.get("url"):
            find("url", rid, "empty url")
        elif urls[row["url"]] > 1:
            find("url", rid, "url is shared with another row")

        stars, pct = row.get("stars", ""), row.get("pct", "")
        if bool(stars) != bool(pct):
            find("scores", rid, "one of stars and pct is filled and the other is empty")
        if row.get("decision") == "respond" and not (stars and pct):
            find("decision", rid, "marked respond without both scores")
        if row.get("alive") == "no" and row.get("decision") not in ("", "skip"):
            find("decision", rid, f"dead listing with decision {row.get('decision')}")

        for column, allowed in listed.items():
            cell = row.get(column, "")
            if cell and cell not in allowed:
                find("values", rid, f"{column} holds {cell!r}, which is not among its listed values")

        if not stars:
            continue
        scores, complete = [], True
        for name, scale in dims.items():
            if not row.get(name, "") and name in waiting:
                continue
            score = number(row.get(name, ""))
            if score is None or score not in scale:
                find("dimension", rid, f"{name} holds {row.get(name, '')!r}, which is not on its scale")
                complete = False
            else:
                scores.append(score)
        if number(stars) is None:
            find("stars", rid, f"stars holds {stars!r}, which is not a number")
        elif complete and scores:
            expected = min(5.0, max(1.0, sum(scores)))
            if abs(number(stars) - expected) > 0.01:
                find("stars", rid, f"stars is {stars} and the dimensions sum to {sum(scores):g}, which clamps to {expected:g}")
        applied = [t.strip() for t in row.get("pct_amplifier", "").split(",") if t.strip()]
        for tag in applied:
            if tag not in tags:
                find("amplifier", rid, f"tag {tag!r} is not among the campaign's")
        base, got = number(row.get("pct_base", "")), number(pct)
        if base is None or got is None or not isinstance(factor, (int, float)):
            find("pct", rid, f"pct {pct!r}, pct_base {row.get('pct_base', '')!r} and the factor do not make a sum")
        else:
            expected = min(PCT_CAP, base * factor ** len(applied))
            if abs(got - expected) > 0.5 + 1e-9:
                find("pct", rid, f"pct is {pct}; {row['pct_base']} at {len(applied)} tag(s) and factor {factor} gives {min(PCT_CAP, math.floor(expected + 0.5))}")


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    directory = Path(sys.argv[1])
    cfg = yaml.safe_load((directory / "campaign.yaml").read_text()) or {}
    with open(directory / "registry.tsv", newline="\n") as f:
        lines = f.read().split("\n")
    header = lines[0].split("\t")
    rows = []
    for n, line in enumerate(lines[1:], 2):
        if line:
            cells = line.split("\t")
            rows.append(dict(zip(header, cells), _line=n, _width=len(cells)))
    check_configuration(cfg, directory, any(r.get("stars") for r in rows), any(r.get("decision") for r in rows))
    check_registry(cfg, header, rows)
    for check, rid, what in findings:
        print(f"{check}\t{rid}\t{what}")
    print(f"{len(rows)} rows checked; {len(findings)} findings" + ("" if findings else "."))
    for check, n in Counter(c for c, _, _ in findings).most_common():
        print(f"  {check}: {n}")
    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()
