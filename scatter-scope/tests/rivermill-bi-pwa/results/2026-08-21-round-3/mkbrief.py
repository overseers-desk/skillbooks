#!/usr/bin/env python3
"""Assemble the blind oracle brief per scope-oracle-brief.md: README, size facts,
doc list, module list with lines and each module's own one-line doc. No measured
figure, no suspicion, no source line (INVARIANTS I1)."""
import json, os, re, subprocess
R = '/home/weiwu/code/rivermill-bi-pwa'
MEASURED = '/usr/local/ai/scope/round-3/measured.json'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'oracle-brief.md')
TESTS = ('/tests/', '.test.', '_test.', '/test/', 'selftest')
mods = sorted(r['file'] for r in json.load(open(MEASURED))['modules']
              if not any(t in r['file'] for t in TESTS))

def lines(p):
    try: return sum(1 for _ in open(os.path.join(R, p), errors='ignore'))
    except OSError: return 0

def docline(p):
    """The module's own first doc line: leading block comment, // line, or JSDoc."""
    try: txt = open(os.path.join(R, p), errors='ignore').read(4000)
    except OSError: return ''
    m = re.match(r'\s*/\*\*?(.*?)\*/', txt, re.S)
    if m:
        for l in m.group(1).splitlines():
            l = l.strip().lstrip('*').strip()
            if l: return l[:180]
    for l in txt.splitlines()[:6]:
        s = l.strip()
        if s.startswith('//'):
            s = s.lstrip('/').strip()
            if s: return s[:180]
        if s and not s.startswith(('#!', '/*', '*')): break
    return ''

tracked = subprocess.run(['git', '-C', R, 'ls-files'], capture_output=True, text=True).stdout.split()
SRC = ('.js', '.mjs', '.ts', '.tsx', '.jsx', '.tcl', '.tm')
pkgs = {}
for f in tracked:
    top = f.split('/')[0] if '/' in f else 'root'
    if top in ('.claude', '.design-sync'): continue
    if f.endswith(SRC) and 'web/src/locales/' not in f:
        d = pkgs.setdefault(top, [0, 0]); d[0] += 1; d[1] += lines(f)

o = []
o.append("# Blind estimation brief\n")
o.append("You are estimating, from a program's description alone, how widely each of its modules "
         "is used and spoken about. You have no access to the code and no tools. Answer with numbers.\n")
o.append("## 1. The program's own description\n")
o.append(open(os.path.join(R, 'README.md')).read().split('## Getting the code')[0].strip() + "\n")
o.append("(Installation and build detail cut.)\n")
o.append("## 2. Size facts\n")
o.append("Source files and lines by top-level area:\n")
o.append("| area | source files | lines |")
o.append("|---|---:|---:|")
for k, (n, l) in sorted(pkgs.items(), key=lambda x: -x[1][1]):
    o.append(f"| {k} | {n} | {l} |")
o.append("")
docs = sorted(f for f in tracked if f.endswith('.md'))
o.append(f"Documentation files ({len(docs)}), by name:\n")
o.append('\n'.join('- `%s`' % d for d in docs))
o.append("")
o.append("## 3. The module list\n")
o.append("Each row is a module to estimate: its path, its length in lines, and the module's own "
         "one-line doc as the file carries it (blank where the file carries none).\n")
o.append("| module | lines | its own doc line |")
o.append("|---|---:|---|")
for p in mods:
    o.append(f"| `{p}` | {lines(p)} | {docline(p).replace('|', '/')} |")
o.append("""
## The ask

**Part 1.** For every module in the list above, four integers, one row each, in this exact form
and nothing else on the line:

```
| path | A | B | C | D |
```

- **A**: other non-test source files that use a type, function or constant the module defines.
- **B**: other files of any kind (sources including tests, docs, manifests) that mention any of
  the module's distinctive identifiers or its file stem anywhere, comments and prose included.
- **C**: total such mentions across those files.
- **D**: other non-test source files whose types, functions or constants this module uses.

Give a row for every module. Do not explain, do not hedge, do not skip rows.

**Part 2.** Then the decided-once list: eight to twelve design facts a program of this
description decides once, each with the number of places in the code you would expect to edit
if the fact changed. One per line, in this exact form:

```
FACT | fact stated in a few words | expected places
```

Keep any prose outside the two tables under four hundred words.
""")
open(OUT, 'w').write('\n'.join(o))
print(len(mods), 'modules', os.path.getsize(OUT), 'bytes ->', OUT)
