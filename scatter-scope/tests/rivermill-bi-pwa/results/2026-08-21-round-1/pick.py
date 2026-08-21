#!/usr/bin/env python3
"""SCOPE Pick: median of estimator replies vs measured, gap = log3(measured/expected)."""
import json, math, re, sys, os, statistics
RUN=sys.argv[1]
rows={r['file']: r for r in json.load(open(os.path.join(RUN,'measured.json')))}
est={}
for p in sys.argv[2:]:
    tag=os.path.basename(p).split('.')[0]
    for line in open(p):
        m=re.match(r'^\s*\|?\s*`?([\w./\-]+\.(?:js|mjs|ts|tsx))`?\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|?\s*$', line)
        if m:
            f=m.group(1)
            est.setdefault(f,{'A':[],'B':[],'C':[]})
            for k,g in (('A',2),('B',3),('C',4)):
                est[f][k].append(int(m.group(g)))
def lg(meas, exp):
    return math.log(max(meas,0.5)/max(exp,0.5), 3)
out=[]
for f, r in rows.items():
    if f not in est: continue
    e={k: statistics.median(v) for k,v in est[f].items() if v}
    if len(e)<3: continue
    gA, gB = lg(r['A'], e['A']), lg(r['B'], e['B'])
    flag=[]
    if gA>1: flag.append('A high')
    if gA<-1: flag.append('A low')
    if gB>1: flag.append('B high')
    if gB<-1: flag.append('B low')
    out.append(dict(file=f, lines=r['lines'], A=r['A'], eA=e['A'], gA=round(gA,2),
                    B=r['B'], eB=e['B'], gB=round(gB,2), C=r['C'], eC=e['C'],
                    leak=r['leak'], score=r['score'], flag=', '.join(flag),
                    n=len(est[f]['A'])))
out.sort(key=lambda r: -(abs(r['gB'])+abs(r['gA'])))
json.dump(out, open(os.path.join(RUN,'pick.json'),'w'), indent=1)
tot=len(out)
inband=sum(1 for r in out if not r['flag'])
print(f"modules estimated: {tot}; inside band on both A and B: {inband} ({100*inband//max(tot,1)}%)")
for k in ('A','B'):
    gs=[r['g'+k] for r in out]
    print(f"  {k}: median gap {statistics.median(gs):+.2f} log3, inside +-1: {sum(1 for g in gs if abs(g)<=1)}/{tot}")
gcs=[lg(r['C'], r['eC']) for r in out]
print(f"  C: median gap {statistics.median(gcs):+.2f} log3, inside +-1: {sum(1 for g in gcs if abs(g)<=1)}/{tot}")
print()
print("| module | A meas | A exp | gap A | B meas | B exp | gap B | leak | flag |")
print("|---|---:|---:|---:|---:|---:|---:|---:|---|")
for r in out[:35]:
    print(f"| {r['file']} | {r['A']} | {r['eA']:g} | {r['gA']:+.2f} | {r['B']} | {r['eB']:g} | {r['gB']:+.2f} | {r['leak']} | {r['flag']} |")
