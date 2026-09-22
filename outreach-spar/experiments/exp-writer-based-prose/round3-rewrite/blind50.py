#!/usr/bin/env python3
"""Shuffle originals and rewrites into one folder under fresh random names,
key written beside it. Pairing survives through the key.
usage: blind50.py <out_dir> <round2_key.json> <originals_dir> <rewrites_dir>"""
import sys, os, glob, json, random, shutil
out, keyf, orig, rew = sys.argv[1:5]
os.makedirs(out, exist_ok=True)
k2 = json.load(open(keyf))
random.seed(20260923)
items = [(f, 'original') for f in sorted(glob.glob(os.path.join(orig, '*.txt')))] + \
        [(f, 'rewrite') for f in sorted(glob.glob(os.path.join(rew, '*.txt')))]
random.shuffle(items)
key, used = {}, set()
for path, kind in items:
    src = os.path.basename(path)
    while True:
        name = f"ltr-{random.randrange(10**6):06d}.txt"
        if name not in used: used.add(name); break
    shutil.copy(path, os.path.join(out, name))
    key[name] = {'kind': kind, 'source': src, 'arm': k2[src]['arm'], 'stem': k2[src]['stem'],
                 'words': len(open(path).read().split())}
json.dump(key, open(os.path.join(out, os.pardir, 'key50.json'), 'w'), indent=1)
print(len(key), 'letters written')
