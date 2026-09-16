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
    for p in sorted(decisions.glob("**/*.md")):
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
    counts = subprocess.run([sys.executable, str(here / "card-check.py"), str(run)], capture_output=True, text=True).stdout.strip()
    fields = (decisions / "integrator-fields.md").read_text(errors="replace") if (decisions / "integrator-fields.md").exists() else ""
    collisions = "\n".join(("- " + j for j in joints)) if joints else ""
    if section(fields, "Collisions"):
        collisions = (collisions + "\n\n" + section(fields, "Collisions")).strip()
    ledger = decisions / "joint-ledger.md"
    if ledger.exists():
        collisions = (collisions + "\n\n" + ledger.read_text(errors="replace").strip()).strip()
    out = (template.replace("{{counts}}", counts or "(no cards)")
           .replace("{{cards}}", "\n\n".join(cards) or "(no cards)")
           .replace("{{unlock}}", section(fields, "Unlock") or "(none)")
           .replace("{{collisions}}", collisions or "(none)"))
    (decisions / "review.md").write_text(out)
    print(f"wrote {decisions / 'review.md'} from {len(cards)} cards")


if __name__ == "__main__":
    main()
