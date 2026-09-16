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
        for line in t.splitlines():
            s = line.strip()
            if s.startswith("## Card") or s.startswith("**Question:**") or s.startswith("**Recommended:**") or s.startswith("**Ruled:**") or s.startswith("**Chip:**") or s.startswith("**Corrections:**"):
                keep.append(line)
            elif s.startswith("**Options**"):
                in_table = True
                keep.append(line)
            elif in_table and s.startswith("|"):
                keep.append(line)
            elif in_table and s:
                in_table = False
            jm = re.search(r"\*\*Joint:\*\*\s*([^·*]+?)(?:\s*·|$)", s)
            if jm and jm.group(1).strip():
                joints.append(f"{keep[0].lstrip('# ').split(' ·')[0]}: {jm.group(1).strip()}")
        cards.append("\n".join(keep))
    raw = subprocess.run([sys.executable, str(here / "card-check.py"), str(run)], capture_output=True, text=True).stdout.strip()
    # the owner reads facts in words; the check's own lines stay in the run record
    m = re.search(r"(\d+) cards; (\d+) prior matches; (\d+) returned by third derivation; (\d+) outstanding; (\d+) mismatched margin units", raw)
    diverged = [c.split(" ·")[0].replace("## ", "") for c in cards if re.search(r"\*\*Corrections:\*\*.*\b(diverg|did not reach|landed on a different)", c, re.I)]
    if m:
        n, matched, returned, outstanding, mism = (int(x) for x in m.groups())
        counts = (f"{n} cards. Every card offers at least two ways the market sells this, each with a figure. "
                  f"{matched} recommendations landed on a value an internal document already held; {returned} of them were re-derived blind by a fresh clerk"
                  + (f", {returned - len(diverged)} agreeing and {len(diverged)} diverging ({', '.join(diverged)}); both readings sit on those cards' Corrections lines." if diverged else ", all agreeing.")
                  + (f" {outstanding} matched recommendations have no blind re-derivation yet." if outstanding else "")
                  + (f" {mism} margins are stated in a unit other than their runner-up's." if mism else ""))
        (decisions / "card-check.txt").write_text(raw + "\n")
    else:
        counts = raw
    fields = (decisions / "integrator-fields.md").read_text(errors="replace") if (decisions / "integrator-fields.md").exists() else ""
    collisions = "\n".join(("- " + j for j in joints)) if joints else ""
    if section(fields, "Collisions"):
        collisions = (collisions + "\n\n### Where rulings collide\n\n" + section(fields, "Collisions")).strip()
    ledger = decisions / "joint-ledger.md"
    if ledger.exists():
        collisions = (collisions + "\n\n" + ledger.read_text(errors="replace").strip()).strip()
    # a phrase Unlock credits to a card's Joint line must appear in that line verbatim; the integrator's prose has no other check
    unlock = section(fields, "Unlock")
    joint_by_card = {j.split(":")[0]: j for j in joints}
    for line in unlock.splitlines():
        for card_ref, quoted in re.findall(r"(Card \d+)'s (?:own )?Joint line states[^\"]*\"([^\"]+)\"", line):
            if card_ref in joint_by_card and quoted not in joint_by_card[card_ref]:
                print(f"UNLOCK MISQUOTE: {card_ref} does not say \"{quoted[:60]}\"", file=sys.stderr)
    out = (template.replace("{{counts}}", counts or "(no cards)")
           .replace("{{cards}}", "\n\n".join(cards) or "(no cards)")
           .replace("{{unlock}}", section(fields, "Unlock") or "(none)")
           .replace("{{collisions}}", collisions or "(none)"))
    (decisions / "review.md").write_text(out)
    print(f"wrote {decisions / 'review.md'} from {len(cards)} cards")


if __name__ == "__main__":
    main()
