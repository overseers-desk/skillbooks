#!/usr/bin/env python3
"""Paired comparison, each rewrite kind minus original, per source letter.
usage: analyze.py <key50.json> <scores.tsv>"""
import sys, json, csv, collections
key = json.load(open(sys.argv[1]))
rows = {r['file'] + ('' if r['file'].endswith('.txt') else '.txt'): r
        for r in csv.DictReader(open(sys.argv[2]), delimiter='\t')}
COLS = ['nowhere', 'surp', 'surp45', 'false', 'unsup', 'sender', 'sent', 'words']
pairs = collections.defaultdict(dict)
kinds = []
for name, k in key.items():
    if k['kind'] not in kinds: kinds.append(k['kind'])
    if name in rows:
        pairs[k['source']][k['kind']] = rows[name]
        pairs[k['source']]['arm'] = k['arm']
def f(r, c): return float(r[c])
print('mean per letter        ' + ' '.join(f'{c:>8}' for c in COLS))
for kind in kinds:
    ps = [p for p in pairs.values() if kind in p]
    print(f'{kind:22s} n={len(ps):2d} ' + ' '.join(f'{sum(f(p[kind], c) for p in ps)/len(ps):8.2f}' for c in COLS))
for kind in kinds[1:]:
    full = [p for p in pairs.values() if 'original' in p and kind in p]
    print(f'\n{kind} minus original, {len(full)} pairs: mean delta, and count better / same / worse')
    for c in COLS:
        d = [f(p[kind], c) - f(p['original'], c) for p in full]
        lower = c not in ('sent', 'words')
        b = sum(1 for x in d if x != 0 and (x < 0) == lower)
        w = sum(1 for x in d if x != 0 and (x > 0) == lower)
        print(f'  {c:8s} {sum(d)/len(d):+7.2f}   {b:2d} / {len(d)-b-w:2d} / {w:2d}')
    print(f'  by original arm, nowhere and sender, original -> {kind}')
    by = collections.defaultdict(list)
    for p in full: by[p['arm']].append(p)
    for arm, ps in sorted(by.items()):
        m = lambda k, c: sum(f(p[k], c) for p in ps) / len(ps)
        print(f'    {arm:16s} n={len(ps)}  nowhere {m("original","nowhere"):.2f} -> {m(kind,"nowhere"):.2f}   sender {m("original","sender"):.2f} -> {m(kind,"sender"):.2f}')
