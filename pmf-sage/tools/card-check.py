#!/usr/bin/env python3
"""Count what a card set must carry before it reaches the owner, and refuse what falls short.

Usage: card-check.py <run-dir>
Reads every card under <run-dir>/3-decisions/ written on forms/card.md.
Refuses: fewer than two options carrying a figure; a recommendation naming no option or stating its
margin in a unit other than the runner-up's; prior matches above one in ten across the set.
Reports: figured options per card, prior matches, mismatched margin units, legs marked differs.
"""
import re, sys
from pathlib import Path

NUM = re.compile(r"\d+(?:\.\d+)?")
STOP = {"the", "and", "with", "from", "that", "this", "over", "into", "than", "each", "about", "hour", "hours"}


def unit(figure):
    """The unit a figure is stated in: % where present, else its last word without digits."""
    if "%" in figure:
        return "%"
    tokens = [t for t in NUM.sub(" ", figure).split() if t not in ("of",)]
    return tokens[-1].strip(" ,;") if tokens else ""


def parse(text):
    card = {"options": []}
    m = re.search(r"^## Card\s+(\S+)", text, re.M)
    card["id"] = m.group(1).rstrip("·").strip() if m else "?"
    in_table = False
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("**Options**"):
            in_table = True
            continue
        if in_table and s.startswith("|"):
            cells = [c.strip() for c in s.strip("|").split("|")]
            if cells[0] in ("option", "---") or set(cells[0]) <= set("-: "):
                continue
            if len(cells) >= 2 and not cells[0].startswith("<"):
                card["options"].append({"name": cells[0], "figure": cells[1]})
            continue
        if in_table and s and not s.startswith("|"):
            in_table = False
        for key in ("Recommended", "Priors", "Measured in", "Ruled"):
            if s.startswith(f"**{key}:**"):
                card[key] = s.split("**", 2)[2].strip()
    return card


def prior_match(recommended, priors, options):
    """Inside the prior's stated range, or the prior's own word; a word every option shares is a unit, not a prior."""
    if not priors or priors.startswith("<"):
        return False
    rec_nums = [float(x) for x in NUM.findall(recommended)]
    for a, b in re.findall(r"(\d+(?:\.\d+)?)\s*(?:–|-|to)\s*(\d+(?:\.\d+)?)", priors):
        lo, hi = sorted((float(a), float(b)))
        if any(lo <= r <= hi for r in rec_nums):
            return True
    if any(float(p) in rec_nums for p in NUM.findall(priors)):
        return True
    shared = {w for w in re.findall(r"[a-z]{4,}", " ".join(o["name"].lower() for o in options))
              if sum(w in o["name"].lower() for o in options) >= 2}
    words = {w for w in re.findall(r"[a-z]{4,}", priors.lower())} - STOP - shared
    return any(w in recommended.lower() for w in words)


def main():
    run = Path(sys.argv[1]).resolve()
    cards = [parse(p.read_text(errors="replace")) for p in sorted((run / "3-decisions").glob("**/*.md"))
             if p.name != "review.md" and re.search(r"^## Card\s", p.read_text(errors="replace"), re.M)]
    refusals, matches, mismatched, differs = [], 0, 0, 0
    if not cards:
        print("REFUSED no card on forms/card.md found under 3-decisions/ (a `## Card N` heading per card)")
        sys.exit(1)
    for c in cards:
        figured = [o for o in c["options"] if NUM.search(o["figure"])]
        if len(figured) < 2:
            refusals.append(f"card {c['id']}: {len(figured)} figured option(s); back to Survey as a named gap")
        rec = c.get("Recommended", "")
        name = rec.split(";")[0].strip()
        chosen = next((o for o in c["options"] if o["name"] == name), None)
        if not chosen:
            refusals.append(f"card {c['id']}: recommended ruling names no option")
        else:
            others = [o for o in figured if o is not chosen]
            mm = re.search(r"margin:\s*([^;]+?)\s+over\s+(.+)$", rec)
            runner = next((o for o in others if mm and o["name"] == mm.group(2).strip()), None)
            if mm and runner and unit(mm.group(1)) != unit(runner["figure"]):
                mismatched += 1
                refusals.append(f"card {c['id']}: margin unit '{unit(mm.group(1))}' is not the runner-up's '{unit(runner['figure'])}'")
        matched = prior_match(rec, c.get("Priors", ""), c["options"])
        if matched:
            matches += 1
        differs += c.get("Measured in", "").lower().count("differs")
        print(f"card {c['id']}: {len(figured)} figured options; prior match: {matched}")
    if cards and matches / len(cards) > 0.1:
        refusals.append(f"{matches} of {len(cards)} recommendations match a prior; the set returns to the clerks")
    print(f"{len(cards)} cards; {matches} prior matches; {mismatched} mismatched margin units; {differs} legs marked differs")
    for r in refusals:
        print("REFUSED " + r)
    sys.exit(1 if refusals else 0)


if __name__ == "__main__":
    main()
