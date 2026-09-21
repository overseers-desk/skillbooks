#!/usr/bin/env python3
"""Build the prompt files for the decomposed web-search test: one prompt per
trade, carrying the segment definition with its catchment and the saved
search listings for that trade across every locality queried. The model is
asked for the sweep's own deliverable, in-scope rows and itemised exclusions,
from the listings alone.

Usage: decomposed-prompts.py <inputs-dir> <out-dir>
<inputs-dir> holds segment-and-catchment.txt and websearch/<trade>-<locality>-<state>.txt
files as the search collection wrote them (first line the query, then
title/URL/snippet blocks). One prompt file per trade lands in <out-dir>.
"""
import glob, os, sys

inputs, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
seg = open(os.path.join(inputs, "segment-and-catchment.txt")).read()
TRADES = ["farrier", "equine-vet", "horse-transport", "horse-agistment", "stockfeed-produce",
          "saddlery", "pony-club", "adult-riding-club", "horse-property-real-estate-agent"]

INSTRUCTION = """You are carrying out one step of a roster sweep for a business-development segment. You are given (a) the segment definition, with its discovery criteria, rating rubric and geographic catchment, and (b) web-search result listings, title, URL and snippet only, for one trade across several localities.

Task: from the listings alone, list every practitioner or business that belongs in the segment and sits inside the catchment. One row each: name, trade, locality, phone or website if a snippet carries it, and one short reason it is in scope. A directory or aggregator page (a listings site, a category page) is not a practitioner; use it only where its snippet names one. Do not invent anything a snippet does not say; leave a field empty instead. Then, under a heading "Excluded", list what you left out with one reason each, grouping entries that share a reason.

Output format: first a TSV block with the header line
name	trade	locality	contact	reason
then the Excluded section. No other prose.

=== SEGMENT DEFINITION ===
"""

for trade in TRADES:
    files = sorted(glob.glob(os.path.join(inputs, "websearch", trade + "-*.txt")))
    if not files:
        print("no listings for", trade); continue
    parts = [INSTRUCTION, seg, "\n=== SEARCH LISTINGS ===\n"]
    for f in files:
        parts.append("\n--- " + open(f).readline().strip() + " ---\n" + "".join(open(f).readlines()[1:]))
    path = os.path.join(out, "prompt-websearch-" + trade + ".txt")
    open(path, "w").write("".join(parts))
    print(path, os.path.getsize(path), "bytes,", len(files), "localities")
