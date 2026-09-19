#!/usr/bin/env python3
"""Assemble the decision review from the card files; the integrator's prose enters only through named fields.

Usage: assemble-review.py <run-dir>
Reads <run-dir>/3-decisions/**/*.md cards (quoting each card's Joint line into Collisions), <run-dir>/3-decisions/integrator-fields.md (on forms/integrator-fields.md, sections
## Unlock and ## Collisions) and <run-dir>/3-decisions/joint-ledger.md if present.
Writes <run-dir>/3-decisions/review.md from forms/review.md beside this script.
"""
import re, subprocess, sys
from pathlib import Path


def section(text, title):
    m = re.search(rf"^## {title}\s*\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    return m.group(1).strip() if m else ""


def main():
    run = Path(sys.argv[1]).resolve()
    here = Path(__file__).resolve().parent
    template = (here.parent / "forms" / "review.md").read_text()
    decisions = run / "3-decisions"
    cards, joints = [], []
    def card_number(path):
        m = re.search(r"^## Card\s+(\d+)", path.read_text(errors="replace"), re.M)
        return int(m.group(1)) if m else 10**6
    files = [p for p in decisions.glob("**/*.md") if p.name != "review.md"]
    for p in sorted(files, key=card_number):
        t = p.read_text(errors="replace")
        if not re.search(r"^## Card\s", t, re.M) or re.search(r"^## Third derivation", t, re.M):
            continue
        keep = []
        in_table = False
        field = None
        for line in t.splitlines():
            s = line.strip()
            fm = re.match(r"\*\*([A-Za-z ]+):?\*\*", s)
            if fm:
                field = fm.group(1)
            if s.startswith("## Card") or s.startswith("**Question:**") or s.startswith("**Recommended:**") or s.startswith("**Ruled:**") or s.startswith("**Chip:**"):
                keep.append(line)
            elif s.startswith("**Corrections:**") and s != "**Corrections:**":
                keep.append(line)
            elif s.startswith("**Options**"):
                in_table = True
                keep.append(line)
            elif in_table and s.startswith("|"):
                keep.append(line)
            elif s and not fm and not s.startswith("#") and not s.startswith("|") and not s.startswith("-") and keep:
                in_table = False
                # the card's face is the question, the options, the recommendation and what the clerk wrote beside them; prose under any other field is not in the review
                if field in ("Question", "Recommended"):
                    keep.append("")
                    keep.append(line)
                elif field != "Cost lines":
                    # the form asks for cost lines one to a line, so plain lines there are the form kept, not a paragraph lost
                    print(f"DROPPED {p.name}: paragraph under {field}: {s[:70]}", file=sys.stderr)
            elif in_table and s:
                in_table = False
            # the line runs to the next field label or the line's end; a bullet after the label and emphasis inside the text are both the clerk's
            jm = re.search(r"\*\*Joint:\*\*\s*(?:·\s*)?(.*?)(?=\s*(?:·\s*)?\*\*[A-Za-z ]+:\*\*|$)", s)
            if jm and jm.group(1).strip():
                joints.append(f"{keep[0].lstrip('# ').split(' ·')[0]}: {jm.group(1).strip()}")
        cards.append("\n".join(keep))
    raw = subprocess.run([sys.executable, str(here / "card-check.py"), str(run)], capture_output=True, text=True).stdout.strip()
    # the owner reads facts in words; the check's own lines stay in the run record
    m = re.search(r"(\d+) cards; (\d+) prior matches; (\d+) returned by third derivation; (\d+) outstanding; (\d+) mismatched margin units", raw)
    # derivations and agreements are counted from the cards' own Corrections lines; the match count comes from the check
    with_third = [c for c in cards if re.search(r"\*\*Corrections:\*\*.*`[^`]*third-[^`]*`", c)]
    name = lambda c: c.split(" ·")[0].replace("## ", "")
    diverged = [name(c) for c in with_third if re.search(r"\*\*Corrections:\*\*.*\b(diverg|did not reach|landed on a different)", c, re.I)]
    agreed = [name(c) for c in with_third if name(c) not in diverged]
    if m:
        n, matched, returned, outstanding, mism = (int(x) for x in m.groups())
        extra = len(with_third) - returned
        counts = (f"{n} cards. Every card offers at least two ways the market sells this, each with a figure. "
                  f"{matched} recommendations landed on a value an internal document already held, and each was re-derived blind by a fresh clerk"
                  + (f"; {extra} more were re-derived for a reason each card's Corrections line states" if extra > 0 else "")
                  + f". Of the {len(with_third)} blind re-derivations ({', '.join(name(c) for c in with_third)}), {len(agreed)} agreed with the first"
                  + (f" and {len(diverged)} diverged ({', '.join(diverged)}); both readings sit on those cards' Corrections lines." if diverged else ".")
                  + (f" {outstanding} matched recommendations have no blind re-derivation yet." if outstanding else "")
                  + (f" {mism} margins are stated in a unit other than their runner-up's." if mism else ""))
        (decisions / "card-check.txt").write_text(raw + "\n")
    else:
        counts = raw
    # a card's own words about its match must agree with the check's count of it
    checked = {int(a): b == "True" for a, b in re.findall(r"^card (\d+):.*?prior match: (True|False)", raw, re.M)}
    for c in cards:
        cid = re.search(r"^## Card\s+(\d+)", c, re.M)
        if not cid or int(cid.group(1)) not in checked:
            continue
        audit = " ".join(l for l in c.splitlines() if l.startswith("**Chip:**") or l.startswith("**Corrections:**"))
        says_no = re.search(r"\b(did|does) not match a prior|not among the nine matched|re-derived for another reason", audit)
        if checked[int(cid.group(1))] and says_no:
            print(f"MISMATCH: Card {cid.group(1)} says it did not match a prior; the check counts it as matched", file=sys.stderr)
        if not checked[int(cid.group(1))] and re.search(r"\bmatched a prior on the check|counts among the nine", audit):
            print(f"MISMATCH: Card {cid.group(1)} says it matched a prior on the check; the check does not count it", file=sys.stderr)
    fields = (decisions / "integrator-fields.md").read_text(errors="replace") if (decisions / "integrator-fields.md").exists() else ""
    collisions = "\n".join(("- " + j for j in joints)) if joints else ""
    # the integrator's two fields print under one heading, and only where they say something the Joint lines do not
    beyond = [section(fields, name) for name in ("Collisions", "Unlock")]
    beyond = [b for b in beyond if b and not b.lstrip("(").lower().startswith("none")]
    if beyond:
        collisions = (collisions + "\n\n### Beyond the Joint lines\n\n" + "\n\n".join(beyond)).strip()
    ledger = decisions / "joint-ledger.md"
    if ledger.exists():
        collisions = (collisions + "\n\n" + ledger.read_text(errors="replace").strip()).strip()
    # a phrase Unlock or Collisions credits to a card's Joint line must appear in that line verbatim; the integrator's prose has no other check
    unlock = section(fields, "Unlock")
    joint_by_card = {j.split(":")[0]: j for j in joints}
    for line in (unlock + "\n" + section(fields, "Collisions")).splitlines():
        for card_ref, quoted in re.findall(r"(Card \d+)'s (?:own )?Joint line states[^\"]*\"([^\"]+)\"", line):
            if card_ref in joint_by_card and quoted not in joint_by_card[card_ref]:
                print(f"MISQUOTE: {card_ref} does not say \"{quoted[:60]}\"", file=sys.stderr)
    out = (template.replace("{{counts}}", counts or "(no cards)")
           .replace("{{cards}}", "\n\n".join(cards) or "(no cards)")
           .replace("{{collisions}}", collisions or "(none)"))
    (decisions / "review.md").write_text(out)
    print(f"wrote {decisions / 'review.md'} from {len(cards)} cards")


if __name__ == "__main__":
    main()
