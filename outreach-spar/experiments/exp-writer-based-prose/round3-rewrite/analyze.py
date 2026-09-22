#!/usr/bin/env python3
"""Paired comparison, rewrite minus original, per source letter.
usage: analyze.py <key50.json> <scores50.tsv>"""
import sys, json, csv, collections
key = json.load(open(sys.argv[1]))
rows = {r['file'] + ('' if r['file'].endswith('.txt') else '.txt'): r
        for r in csv.DictReader(open(sys.argv[2]), delimiter='\t')}
COLS = ['nowhere', 'surp', 'surp45', 'false', 'unsup', 'sender', 'sent', 'words']
pairs = collections.defaultdict(dict)
for name, k in key.items():
    if name in rows:
        pairs[k['source']][k['kind']] = rows[name]
        pairs[k['source']]['arm'] = k['arm']; pairs[k['source']]['stem'] = k['stem']
full = {s: p for s, p in pairs.items() if 'original' in p and 'rewrite' in p}
print(f'{len(full)} complete pairs of {len(pairs)} sources\n')
def f(r, c): return float(r[c])
print('mean per letter        ' + ' '.join(f'{c:>8}' for c in COLS))
for kind in ('original', 'rewrite'):
    print(f'{kind:22s} ' + ' '.join(f'{sum(f(p[kind], c) for p in full.values())/len(full):8.2f}' for c in COLS))
print('\npaired delta (rewrite - original): mean, and count better / same / worse')
for c in COLS:
    d = [f(p['rewrite'], c) - f(p['original'], c) for p in full.values()]
    lower_is_better = c not in ('sent', 'words')
    b = sum(1 for x in d if (x < 0) == lower_is_better and x != 0)
    w = sum(1 for x in d if (x > 0) == lower_is_better and x != 0)
    s = sum(1 for x in d if x == 0)
    print(f'  {c:8s} {sum(d)/len(d):+7.2f}   {b:2d} / {s:2d} / {w:2d}')
print('\nby original arm (mean nowhere, sender: original -> rewrite)')
by = collections.defaultdict(list)
for p in full.values(): by[p['arm']].append(p)
for arm, ps in sorted(by.items()):
    print(f'  {arm:16s} n={len(ps)}  nowhere {sum(f(p["original"],"nowhere") for p in ps)/len(ps):.2f} -> {sum(f(p["rewrite"],"nowhere") for p in ps)/len(ps):.2f}'
          f'   sender {sum(f(p["original"],"sender") for p in ps)/len(ps):.2f} -> {sum(f(p["rewrite"],"sender") for p in ps)/len(ps):.2f}')
