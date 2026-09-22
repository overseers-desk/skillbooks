#!/usr/bin/env python3
"""Shuffle originals and rewrite arms into one folder under fresh random
names, key written beside it. Pairing survives through the key.
usage: blind50.py <out_dir> <round2_key.json> original=<dir> <kind>=<dir> ..."""
import sys, os, glob, json, random, shutil
out, keyf = sys.argv[1:3]
arms = [a.split('=', 1) for a in sys.argv[3:]]
os.makedirs(out, exist_ok=True)
k2 = json.load(open(keyf))
random.seed(20260923)
items = [(f, kind) for kind, d in arms for f in sorted(glob.glob(os.path.join(d, '*.txt')))]
random.shuffle(items)
key, used = {}, set()
for path, kind in items:
    src = os.path.basename(path)
    while True:
        name = f"ltr-{random.randrange(10**6):06d}.txt"
        if name not in used: used.add(name); break
    shutil.copy(path, os.path.join(out, name))
    meta = k2.get(src, {'arm': 'round4-A', 'stem': src[:-4]})
    key[name] = {'kind': kind, 'source': src, 'arm': meta['arm'], 'stem': meta['stem'],
                 'words': len(open(path).read().split())}
json.dump(key, open(os.path.join(out, os.pardir, 'key50.json'), 'w'), indent=1)
print(len(key), 'letters written;', {k: sum(1 for v in key.values() if v['kind'] == k) for k, _ in arms})
