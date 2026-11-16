#!/usr/bin/env python3
"""Every row of a cell where an offence scores 4 or more, run by run, with the reader's reason.
usage: show.py <cell.json> [column, to show that column only]"""
import json, sys

cell = json.load(open(sys.argv[1]))
only = int(sys.argv[2]) if len(sys.argv) > 2 else None
for b in cell["batches"]:
    for r in b["runs"]:
        print(f"{r['m']} run {r.get('r')} {'valid' if r['valid'] else 'INVALID'}")
        for k, v in sorted(r["rows"].items(), key=lambda x: int(x[0])):
            hot = [i + 1 for i, x in enumerate(v["s"]) if x >= 4 and (only is None or i + 1 == only)]
            if hot:
                print(f"  s{k} offences {hot} {v['s']} | {v['why']}")
