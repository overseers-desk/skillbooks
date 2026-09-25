#!/usr/bin/env python3
"""Merge coded shards on the class columns and compute agreement against a reliability sample.
Usage: merge_agree.py <coded-dir> <key-col-candidates> <class-col-prefix> <out.tsv> <reliability files...>"""
import csv, sys, os, glob, collections
d, keys, prefix, out = sys.argv[1], sys.argv[2].split(','), sys.argv[3], sys.argv[4]
rel_files = [os.path.join(d, f) for f in sys.argv[5:]]
def load(path):
    rows = {}
    with open(path, newline='', encoding='utf-8', errors='replace') as fh:
        r = csv.reader(fh, delimiter='\t', quoting=csv.QUOTE_NONE)
        hdr = next(r)
        k = next(i for i, h in enumerate(hdr) if h in keys)
        cls = [(i, h) for i, h in enumerate(hdr) if h.startswith(prefix) and not h.endswith(('_text', 'phrases', 'note', 'present', 'order', 'primary_addressee', 'multi_buyer', 'count', 'segment', 'unattributed', 'unrecoverable', 'basis'))]
        for row in r:
            if len(row) <= k or not row[k].strip(): continue
            key = os.path.basename(row[k].strip())
            rows[key] = {h: (row[i].strip() if i < len(row) else '') for i, h in cls}
    return rows
main = {}
for f in sorted(glob.glob(os.path.join(d, 'shard-*.tsv'))):
    main.update(load(f))
cols = sorted({c for v in main.values() for c in v})
with open(out, 'w', encoding='utf-8') as fh:
    fh.write('unit\t' + '\t'.join(cols) + '\n')
    for u in sorted(main): fh.write(u + '\t' + '\t'.join(main[u].get(c, '') for c in cols) + '\n')
print(len(main), 'units merged;', len(cols), 'class columns:', ' '.join(cols))
tot = collections.Counter(); 
for c in cols:
    tot[c] = sum(1 for v in main.values() if v.get(c) == '1')
print('coded 1 per class:', dict(tot))
rel = {}
for f in rel_files: rel.update(load(f))
both = [u for u in rel if u in main]
print(len(rel), 'in reliability sample;', len(both), 'matched to main coding')
agree = n = 0; per = {}
for c in cols:
    a = [(main[u].get(c, ''), rel[u].get(c, '')) for u in both if main[u].get(c, '') != '' and rel[u].get(c, '') != '']
    if not a: continue
    ag = sum(1 for x, y in a if x == y); per[c] = (ag, len(a)); agree += ag; n += len(a)
    # Cohen's kappa on the observed categories
    cats = sorted({x for p in a for x in p}); po = ag / len(a)
    pe = sum((sum(1 for x, _ in a if x == k) / len(a)) * (sum(1 for _, y in a if y == k) / len(a)) for k in cats)
    kappa = (po - pe) / (1 - pe) if pe < 1 else float('nan')
    print(f'{c}: {ag}/{len(a)} = {po:.2f}  kappa {kappa:.2f}')
print(f'overall raw agreement {agree}/{n} = {agree/n:.3f}' if n else 'no comparable cells')
