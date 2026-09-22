#!/usr/bin/env python3
"""Assemble the paired numbers for ab-evaluation.html from a key and its
scores: per arm, means before and after, better/same/worse counts, and
the per-letter pairs the slope charts draw.
usage: page-data.py <key.json> <scores.tsv> <name>=<after>:<before>:<beforelabel>:<afterlabel> ..."""
import sys, json, csv, collections
key = json.load(open(sys.argv[1]))
norm = lambda s: s if s.endswith('.txt') else s + '.txt'
rows = {norm(r['file']): r for r in csv.DictReader(open(sys.argv[2]), delimiter='\t')}
COLS = [['nowhere', 'unresolved references'], ['surp45', 'sentences surprising 4-5'], ['false', 'false claims'],
        ['unsup', 'unsupported claims'], ['sender', 'sender-side sentences'], ['sent', 'sentences'], ['words', 'words']]
pairs = collections.defaultdict(dict)
for name, k in key.items():
    if name in rows: pairs[k['source']][k['kind']] = rows[name]
arms = []
for spec in sys.argv[3:]:
    name, rest = spec.split('=', 1); after, before, bl, al = rest.split(':')
    full = [p for p in pairs.values() if before in p and after in p]
    arm = {'name': name, 'before': bl, 'after': al, 'n': len(full), 'means': {}, 'pairs': {}, 'rows': {}}
    for k, _ in COLS:
        b = [float(p[before][k]) for p in full]; a = [float(p[after][k]) for p in full]
        arm['means'][k] = [sum(b) / len(b), sum(a) / len(a)]
        lower = k not in ('sent', 'words')
        d = [x - y for x, y in zip(a, b)]
        arm['pairs'][k] = [sum(1 for x in d if x != 0 and (x < 0) == lower), sum(1 for x in d if x == 0), sum(1 for x in d if x != 0 and (x > 0) == lower)]
        arm['rows'][k] = [[y, x] for x, y in zip(a, b)]
    arms.append(arm)
print(json.dumps({'cols': COLS, 'arms': arms}))
