#!/usr/bin/env python3
"""Stumbles (any offence scored 4 or more) per sentence, grouped by authorship.tsv.
usage: by-author.py <authorship.tsv> <cell.json>..."""
import csv, json, sys
groups = {}
for row in csv.DictReader(open(sys.argv[1]), delimiter="\t", quoting=csv.QUOTE_NONE):
    groups.setdefault(row["author"], []).append(int(row["sentence"]))
runs = [r for f in sys.argv[2:] for b in json.load(open(f))["batches"] for r in b["runs"] if r["valid"]]
print(f"{len(runs)} valid runs")
print("author     sentences  stumbles/sentence  forgotten-beat-or-missing-link/sentence  sentences flagged")
for g, ss in groups.items():
    total = joins = 0; flagged = set()
    for r in runs:
        rows = {int(k): v["s"] for k, v in r["rows"].items()}
        for s in ss:
            hits = [i for i, x in enumerate(rows.get(s, [0] * 9)) if x >= 4]
            total += len(hits); joins += sum(1 for i in hits if i in (0, 2))
            if hits: flagged.add(s)
    n = len(ss) * len(runs)
    print(f"{g:10} {len(ss):9}  {total / n:17.2f}  {joins / n:39.2f}  {sorted(flagged)}")
