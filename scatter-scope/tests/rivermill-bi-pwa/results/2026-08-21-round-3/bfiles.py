#!/usr/bin/env python3
"""For one module concept, print the vocabulary the count used and the B files it matched,
with per-file and per-name site counts. The revival reads this to check the instrument.

Usage: bfiles.py <module path as it appears in measured.json> [more paths...]
"""
import json, os, re, sys
R = '/home/weiwu/code/rivermill-bi-pwa'
MEASURED = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'measured.json')
EXT = ('.js','.mjs','.ts','.tsx','.jsx','.md','.json','.sql','.tcl','.tm','.css','.html','.yaml','.yml','.sh')
EXCL = ['.git/','node_modules/','ds-bundle/','.ds-sync/','.design-sync/learnings/','.design-sync/.cache/',
        'data/','dist/','tmp/','.claude/','.venv/','web/src/locales/','themes/design/','/db/2026',
        'config/tok'+'en.json','docs/deploy.local.md']
SKIP = {'package-lock.json'}
DICT = '/usr/share/dict/words'
SUF = ("ings","ing","ies","ers","er","ed","es","s")
COMMONPLACE = set(open(os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','..','..','tools','scope-count.py')).read()
                  .split('COMMONPLACE = set("""')[1].split('""".split())')[0].split())
words = {l.strip().lower() for l in open(DICT, errors='ignore')}
def english(w):
    w = w.lower()
    if w in words or w in COMMONPLACE: return True
    return any(w.endswith(s) and len(w)-len(s) >= 3 and w[:-len(s)] in words for s in SUF)

corpus = {}
for dp, dirs, files in os.walk(R):
    rel = os.path.relpath(dp, R); rel = '' if rel == '.' else rel + '/'
    if any(e in rel for e in EXCL): dirs[:] = []; continue
    for fn in files:
        if fn.endswith(EXT) and fn not in SKIP:
            p = rel + fn
            if not any(e in p for e in EXCL):
                corpus[p] = open(os.path.join(dp, fn), errors='ignore').read()
def strip_prose(t):
    t = re.sub(r"/\*.*?\*/", "", t, flags=re.S)
    t = re.sub(r"(//|#(?!\[)|--)[^\n]*", "", t)
    return re.sub(r'"(?:\\.|[^"\\])*"', '""', t)
PROSE = ('.md','.txt','.rst','.html')
code = {g: strip_prose(t) for g, t in corpus.items() if not g.endswith(PROSE)}

mods = {r['file']: r for r in json.load(open(MEASURED))['modules']}
for target in sys.argv[1:]:
    r = mods[target]
    vocab = r.get('vocabulary', [])
    print(f"\n=== {target}   A={r['A']} D={r['D']} B={r['B']} C={r['C']} leak={r['leak']}")
    print(f"vocabulary ({len(vocab)}): {', '.join(vocab)}")
    per_file, per_name = {}, {}
    for w in vocab:
        pat = re.compile(r'\b' + re.escape(w) + r'\b')
        src = corpus if not english(w) else code
        for g, t in src.items():
            if g == target: continue
            n = len(pat.findall(t))
            if n:
                per_file.setdefault(g, {})[w] = n
                per_name[w] = per_name.get(w, 0) + n
    print(f"B files: {len(per_file)}  sites: {sum(per_name.values())}")
    print("sites per vocabulary word (highest first):")
    for w, n in sorted(per_name.items(), key=lambda x: -x[1]):
        print(f"   {n:6d}  {w}")
    print("B files (sites, then which words):")
    for g, d in sorted(per_file.items(), key=lambda x: -sum(x[1].values())):
        print(f"   {sum(d.values()):5d}  {g}   {', '.join(f'{k}:{v}' for k, v in sorted(d.items(), key=lambda x: -x[1]))}")
