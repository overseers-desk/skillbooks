#!/usr/bin/env python3
"""Second writing of each round-2 letter in a fresh context that holds only the
letter, the recipient's organisation and role, and today's date.
usage: rewrite.py <blind_dir> <key.json> <roster_dir> <out_dir> [concurrency]
The recipient is looked up by stem across <roster_dir>/*.tsv (columns stem,
organisation, role). Output file names match the input, so pairing is by name."""
import sys, os, json, csv, glob, subprocess, concurrent.futures as cf
blind, keyf, roster_dir, out = sys.argv[1:5]
conc = int(sys.argv[5]) if len(sys.argv) > 5 else 5
os.makedirs(out, exist_ok=True)
key = json.load(open(keyf))
def recipient(stem):
    for tsv in glob.glob(os.path.join(roster_dir, '*.tsv')):
        for r in csv.DictReader(open(tsv), delimiter='\t'):
            if r.get('stem') == stem:
                return r['organisation'], r['role'].split(' (')[0]
    raise SystemExit('no roster row for ' + stem)
PROMPT = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'prompt.txt')).read()
def one(path):
    name = os.path.basename(path)
    dst = os.path.join(out, name)
    if os.path.exists(dst) and os.path.getsize(dst) > 0:
        return name, 'kept'
    org, role = recipient(key[name]['stem'])
    prompt = PROMPT.format(org=org, role=role) + '\n\n' + open(path).read()
    r = subprocess.run(['claude', '-p', '--model', 'opus', prompt],
                       capture_output=True, text=True, timeout=900)
    text = r.stdout.strip()
    if r.returncode or not text:
        open(dst + '.err', 'w').write(r.stdout + '\n---\n' + r.stderr)
        return name, 'failed'
    open(dst, 'w').write(text + '\n')
    return name, f'{len(text.split())} words'
files = sorted(glob.glob(os.path.join(blind, '*.txt')))
with cf.ThreadPoolExecutor(conc) as ex:
    for name, status in ex.map(one, files):
        print(name, status, flush=True)
