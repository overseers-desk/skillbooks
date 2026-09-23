#!/usr/bin/env python3
"""Build letters.json for the test: the chosen round-2 letters, each with
its contact's name from the roster and the dated messages we sent to that
contact's address, from the mail index.
usage: letters.py <writer-based-prose experiment dir> <segments dir> <letter> ..."""
import sys, os, json, csv, glob, re, subprocess
X, SEG = sys.argv[1:3]; pick = sys.argv[3:]
key = json.load(open(os.path.join(X, 'key-round2.json')))
roster = {}
for tsv in glob.glob(os.path.join(SEG, '*.tsv')):
    for r in csv.DictReader(open(tsv), delimiter='\t'): roster[r.get('stem')] = r
def prior(addr):
    if not addr: return []
    out = subprocess.run(['courier', '-A', 'search', f'to:{addr}', '--format', 'text', '--limit', '10'], capture_output=True, text=True, timeout=120).stdout
    seen = []
    for m in re.finditer(r'^(\d{4}-\d{2}-\d{2})\s+(.+)$', out, re.M):
        if [m.group(1), m.group(2).strip()] not in seen: seen.append([m.group(1), m.group(2).strip()])
    return seen
L = {}
for n in pick:
    stem = key[n]['stem']; r = roster[stem]
    L[n] = {'stem': stem, 'name': r['contact_name'], 'email_path': os.path.abspath(os.path.join(X, 'round2-blind', n)), 'prior': prior(r.get('email', '').strip()), 'round2_verdict': 'DONE', 'arm': key[n]['arm']}
json.dump(L, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'letters.json'), 'w'), indent=1)
print({n: (v['stem'][:14], len(v['prior'])) for n, v in L.items()})
