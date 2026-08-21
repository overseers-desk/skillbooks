#!/usr/bin/env python3
"""Operator instrument check: for a module, print the exact grep vocabulary scope-count.py
used and how many corpus files each word alone matches. Answers "which word carries B"."""
import json,os,re,collections,sys
R='/home/weiwu/code/rivermill-bi-pwa'
EXCL=['.git/','node_modules/','.claude/','ds-bundle/','.ds-sync/','.design-sync/learnings/','.design-sync/.cache/','data/','tmp/','dist/','web/src/locales/','/_ds/']
EXT=('.js','.mjs','.ts','.tsx','.jsx','.md','.json','.sql','.tcl','.tm','.css','.html','.yaml','.yml','.sh')
SUF=("ings","ing","ies","ers","er","ed","es","s")
words={l.strip().lower() for l in open('/usr/share/dict/words',errors='ignore')}
def eng(w):
    w=w.lower()
    if w in words: return True
    return any(w.endswith(s) and len(w)-len(s)>=3 and w[:-len(s)] in words for s in SUF)
def keep(n):
    if len(n)<5: return False
    if '_' in n or re.search(r'[a-z][A-Z]',n): return True
    if n[0].isupper() and not n.isupper(): return True
    return not eng(n)
idx=json.load(open('idx/index.json'))
home={};refs=collections.defaultdict(set)
for d in idx['documents']:
    for o in d['occurrences']:
        s=o['symbol']
        if s.startswith('local ') or s.endswith('/'): continue
        if o.get('symbol_roles',0)&1: home.setdefault(s,d['relative_path'])
        else: refs[s].add(d['relative_path'])
def nm(s):
    m=re.search(r"([A-Za-z_][A-Za-z0-9_]*)[#().]*$", s.split(" ")[-1].split("/")[-1]); return m.group(1) if m else None
ext={nm(s) for s in refs if s not in home}
names=collections.defaultdict(set); dfn=collections.defaultdict(set)
for s,f in home.items():
    n=nm(s)
    if n: names[f].add(n); dfn[n].add(f)
corpus={}
for dp,dirs,fs in os.walk(R):
    rel=os.path.relpath(dp,R); rel='' if rel=='.' else rel+'/'
    if any(e in rel for e in EXCL): dirs[:]=[]; continue
    for fn in fs:
        if fn.endswith(EXT) and fn!='package-lock.json':
            p=rel+fn
            if not any(e in p for e in EXCL): corpus[p]=open(os.path.join(dp,fn),errors='ignore').read()
for T in sys.argv[1:]:
    stem=os.path.splitext(os.path.basename(T))[0]
    ws={n for n in names[T] if len(dfn[n])==1 and keep(n) and n not in ext}
    if stem not in ('lib','mod','main','index') and len(stem)>=3 and not eng(stem): ws.add(stem)
    per={}
    for w in ws:
        pat=re.compile(r'\b'+re.escape(w)+r'\b')
        per[w]=sum(1 for g,t in corpus.items() if g!=T and pat.search(t))
    print(f"\n{T}  vocabulary {len(ws)} words")
    for w,c in sorted(per.items(),key=lambda x:-x[1])[:14]: print(f"   {w:24s} {c}")
