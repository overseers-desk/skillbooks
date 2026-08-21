#!/usr/bin/env python3
"""Instrument check: recompute B and C for each flagged module with the file stem
removed from its vocabulary, and with stems shared by several files removed.
scope-count.py adds the stem unconditionally (no multi-home guard, no external guard),
so a module named for a common domain word greps the whole tree."""
import json, os, re, collections, sys
R='/home/weiwu/code/rivermill-bi-pwa'
EXCL=['.git/','node_modules/','.claude/','ds-bundle/','.ds-sync/','.design-sync/learnings/',
      '.design-sync/.cache/','data/','tmp/','dist/','web/src/locales/','/_ds/']
EXT=('.js','.mjs','.ts','.tsx','.jsx','.md','.json','.sql','.tcl','.tm','.css','.html','.yaml','.yml','.sh')
corpus={}
for dp,dirs,fs in os.walk(R):
    rel=os.path.relpath(dp,R); rel='' if rel=='.' else rel+'/'
    if any(e in rel for e in EXCL): dirs[:]=[]; continue
    for fn in fs:
        if fn.endswith(EXT) and fn!='package-lock.json':
            p=rel+fn
            if any(e in p for e in EXCL): continue
            corpus[p]=open(os.path.join(dp,fn),errors='ignore').read()
meas={r['file']:r for r in json.load(open('measured.json'))['modules']}
stem_homes=collections.Counter(os.path.splitext(os.path.basename(f))[0] for f in meas)
rows=json.load(open('pick.json'))
out=[]
for r in rows:
    if 'B high' not in r['flags']: continue
    m=meas[r['file']]; stem=os.path.splitext(os.path.basename(r['file']))[0]
    ws=[w for w in m['vocab'] if w!=stem]   # vocab sample is truncated to 6; recount is indicative
    # exact: rebuild from measured vocab is not available (sample only), so grep the stem alone
    pat=re.compile(r'\b'+re.escape(stem)+r'\b')
    sfiles={g for g,t in corpus.items() if g!=r['file'] and pat.search(t)}
    ssites=sum(len(pat.findall(corpus[g])) for g in sfiles)
    out.append(dict(file=r['file'], stem=stem, stem_homes=stem_homes[stem], B=r['B'], eB=r['eB'],
                    gB=r['gB'], stemB=len(sfiles), stemC=ssites, leak=r['leak'],
                    share=round(len(sfiles)/max(r['B'],1),2)))
out.sort(key=lambda x:-x['share'])
json.dump(out, open('stem-check.json','w'), indent=1)
tot=len(out); heavy=[x for x in out if x['share']>=0.8]
print(f"B-high modules: {tot}; stem alone accounts for >=80% of B in {len(heavy)}")
print(f"{'module':50s} {'stem':16s} homes  B  stemB share")
for x in out[:40]:
    print(f"{x['file']:50s} {x['stem']:16s} {x['stem_homes']:3d} {x['B']:5d} {x['stemB']:5d}  {x['share']}")
