#!/usr/bin/env python3
"""Fail any brief that fixes a buyer, product count or price shape without a mark behind it.
Tested: the brief itself and the files under briefs/ its read order names; survey records it names are evidence and pass.

Usage: launch-check.py <run-dir> [--check-only]
--check-only scans without writing the venue-situation paragraph (use against a run you do not own).
Reads every brief under <run-dir>/briefs/ and every file its read-order paragraph names.
Emits <run-dir>/briefs/venue-situation.md from the unstruck strike-list rows and the shape note.
"""
import re, sys
from pathlib import Path

BUYER_NOUNS = ["family", "families", "couple", "couples", "senior", "seniors", "school", "schools",
               "child", "children", "kid", "kids", "parent", "parents", "toddler", "toddlers",
               "teen", "teens", "coach party", "coach parties", "walking club", "photographer"]
FIXING = [r"\$\s?\d", r"\bper (head|person|adult|child|family|guest)\b",
          r"\b(one|single|two|several) (offer|offers|product|products)\b"]
MARK = re.compile(r"\b(RULED|DEFAULT)\b[\s:(]*([A-Za-z0-9._:-]+)")


def read_order_paths(text, run):
    for para in re.split(r"\n\s*\n", text):
        if para.lstrip().startswith("Read") and "`" in para:
            return [run / p if not p.startswith("/") else Path(p) for p in re.findall(r"`([^`]+)`", para)]
    return None


def ruled_refs(run):
    refs = set()
    for card in (run / "3-decisions").glob("**/*.md"):
        t = card.read_text(errors="replace")
        m = re.search(r"^## Card\s+(\S+)", t, re.M)
        ruled = re.search(r"^\*\*Ruled:\*\*\s*(.+)$", t, re.M)
        if m and ruled and ruled.group(1).strip().lower() not in ("", "open", "<>"):
            refs.add(m.group(1).rstrip("·").strip())
    sl = run / "3-decisions" / "strike-list.md"
    rows = []
    if sl.exists():
        t = sl.read_text(errors="replace")
        if re.search(r"^\*\*Returned:\*\*\s*\d", t, re.M):
            for line in t.splitlines():
                cells = [c.strip() for c in line.strip().strip("|").split("|")]
                if len(cells) == 6 and cells[0] not in ("buyer", "---") and not cells[0].startswith("<"):
                    if not cells[5]:
                        refs.add("strike-list:" + cells[0].lower().replace(" ", "-"))
                        rows.append(cells[0])
    return refs, rows


def findings(run):
    ids = set()
    for f in run.glob("**/findings*.md"):
        ids.update(re.findall(r"\b([A-Z]?-?\d+)\b", f.read_text(errors="replace")))
    return ids


def check_file(path, refs, finds, nouns, failures, is_brief):
    """Brief text is where scoping hides; a survey record naming a buyer or a price in a dated count is evidence.
    So the tests run over the brief and over the files under briefs/ it names, and over nothing else."""
    for n, line in enumerate(path.read_text(errors="replace").splitlines(), 1):
        # a cited path is a file's name, not a line fixing a buyer
        low = re.sub(r"`[^`]*`", " ", line).lower()
        fixing = any(re.search(p, low) for p in FIXING) or (is_brief and any(re.search(r"\b" + re.escape(w) + r"\b", low) for w in nouns))
        if not fixing:
            continue
        m = MARK.search(line)
        ok = m and ((m.group(1) == "RULED" and m.group(2) in refs) or (m.group(1) == "DEFAULT" and m.group(2) in finds))
        if not ok:
            failures.append(f"{path}:{n}: fixing line without a mark behind it: {line.strip()[:120]}")


def main():
    run = Path(sys.argv[1]).resolve()
    emit = "--check-only" not in sys.argv[2:]
    nouns = BUYER_NOUNS + [w.strip().lower() for w in (run / "buyer-nouns.txt").read_text().splitlines()] if (run / "buyer-nouns.txt").exists() else BUYER_NOUNS
    refs, rows = ruled_refs(run)
    finds = findings(run)
    failures = []
    briefs = sorted((run / "briefs").glob("*.md"))
    for brief in briefs:
        if brief.name == "venue-situation.md":
            continue
        text = brief.read_text(errors="replace")
        paths = read_order_paths(text, run)
        if paths is None:
            failures.append(f"{brief}: no read-order paragraph (see forms/brief-read-order.md)")
            continue
        check_file(brief, refs, finds, nouns, failures, True)
        for p in paths:
            if p.is_file() and p.suffix == ".md" and p.parent == run / "briefs" and p.name != "venue-situation.md":
                check_file(p, refs, finds, nouns, failures, True)
    shape = next(run.glob("**/shape-note.md"), None)
    situation = run / "briefs" / "venue-situation.md"
    if emit: situation.write_text("# Venue situation (generated; do not edit)\n\n"
                         + (shape.read_text(errors="replace").strip() + "\n\n" if shape else "")
                         + ("The frame reaches: " + ", ".join(rows) + ".\n" if rows else "No strike list has been returned; the frame reaches no buyer yet.\n"))
    for f in failures:
        print(f)
    print(f"{len(briefs)} briefs, {len(failures)} failures")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
