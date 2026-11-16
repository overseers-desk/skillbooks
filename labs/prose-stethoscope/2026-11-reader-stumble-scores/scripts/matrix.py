#!/usr/bin/env python3
"""For every cell and every expectation its text declares, how many valid runs meet it.
An expectation names one or more offences (comma-separated, or "any"), the sentences (comma-separated,
or "all") and what is there. A flag expectation is met when a listed sentence scores 4 or more on a
criterion of a named offence; a quiet one is broken the same way. A cell whose format has no criterion
of the named offences skips the expectation. usage: matrix.py"""
import glob, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from run import ROOT, load

print("| Prompt+format | Model | Text | Expectation | Result |")
print("|---|---|---|---|---|")
for path in sorted(glob.glob(f"{ROOT}/runs/*/*.json")):
    cell = json.load(open(path))
    meta = load(f"{ROOT}/texts/{cell['text']}.md")[0]
    ids = [c.strip() for c in load(f"{ROOT}/formats/{cell['format']}.md")[0]["criteria"][0].split(",")]
    offence_of = [load(f"{ROOT}/criteria/{c}.md")[0]["offence"][0] for c in ids]
    runs = [r for b in cell["batches"] for r in b["runs"] if r["valid"]]
    for kind in ("flag", "quiet"):
        for line in meta.get(kind, []):
            offences, sents, label = line.split(" ", 2)
            cols = [i for i, o in enumerate(offence_of) if offences == "any" or o in offences.split(",")]
            if not cols:
                continue
            hits = 0
            for r in runs:
                keys = list(r["rows"]) if sents == "all" else sents.split(",")
                hits += any(r["rows"][k]["s"][i] >= 4 for k in keys if k in r["rows"] for i in cols)
            result = f"{hits}/{len(runs)}" + (" flagged" if kind == "quiet" else "")
            print(f"| {cell['prompt']}+{cell['format']} | {cell['model']} | {cell['text']} | {kind} {offences} at {sents}: {label} | {result} |")
