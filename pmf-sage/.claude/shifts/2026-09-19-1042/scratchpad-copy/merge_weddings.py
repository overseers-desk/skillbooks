#!/usr/bin/env python3
import csv, glob, os, sys, collections, re
d=sys.argv[1]; out=sys.argv[2]
CLS=['V38_marrying_parties','V38_one_marrying_party','V38_family_of_couple','V38_planner_or_agent','V38_supplier_referrer','V38_organisation_buyer','V38_guest_as_buyer','V38_trade_intermediary','V38_other_buyer_class']
def load(path):
    rows=[]
    with open(path,newline='',encoding='utf-8',errors='replace') as fh:
        r=csv.reader(fh,delimiter='\t',quoting=csv.QUOTE_NONE); hdr=next(r)
        idx={h:i for i,h in enumerate(hdr)}
        for row in r:
            if not row or not row[0].strip(): continue
            p=row[0].strip(); basis=row[idx['basis']].strip() if 'basis' in idx and idx['basis']<len(row) else ''
            vals={c:(row[idx[c]].strip() if c in idx and idx[c]<len(row) else '') for c in CLS}
            if not any(v in ('0','1','8','9') for v in vals.values()): continue   # screened-out rows carry no class value
            stored = basis.lower().startswith('stored')
            if not stored: vals={c:('9' if v=='0' else v) for c,v in vals.items()}  # an earlier coder's silence is not the operator's
            seg=row[idx['V38_segment_verbatim']].strip() if 'V38_segment_verbatim' in idx and idx['V38_segment_verbatim']<len(row) else ''
            rows.append((p,'stored copy' if stored else 'unit record',vals,seg))
    return rows
main=[]
for f in sorted(glob.glob(os.path.join(d,'shard-*.tsv'))): main+=load(f)
with open(out,'w',encoding='utf-8') as fh:
    fh.write('unit\tbasis\t'+'\t'.join(CLS)+'\tsegment_verbatim\n')
    for p,b,v,s in main: fh.write(p+'\t'+b+'\t'+'\t'.join(v[c] for c in CLS)+'\t'+s+'\n')
print(len(main),'coded rows;', sum(1 for r in main if r[1]=='stored copy'),'from a stored copy')
for b in ('stored copy','unit record'):
    sub=[r for r in main if r[1]==b]
    print(b, len(sub), {c.replace('V38_',''): sum(1 for r in sub if r[2][c]=='1') for c in CLS})
print('segment qualifiers recorded:', sum(1 for r in main if r[3] and r[3] not in ('9','0','n/a','-','none','None')))
cnt=collections.Counter(p.split('::')[0] for p,_,_,_ in main); single={p for p,n in cnt.items() if n==1}
m={p:v for p,_,v,_ in main if p in single}
rel=[]
for f in ('reliability-a.tsv','reliability-b.tsv'): rel+=load(os.path.join(d,f))
rc=collections.Counter(p for p,_,_,_ in rel)
both=[(p,v) for p,_,v,_ in rel if rc[p]==1 and p in m]
print(len(rel),'reliability rows;',len(both),'single-unit files matched')
ag=n=0
for c in CLS:
    a=[(m[p][c],v[c]) for p,v in both if m[p][c] and v[c]]
    if not a: continue
    g=sum(1 for x,y in a if x==y); ag+=g; n+=len(a)
    cats=sorted({x for t in a for x in t}); po=g/len(a)
    pe=sum((sum(1 for x,_ in a if x==k)/len(a))*(sum(1 for _,y in a if y==k)/len(a)) for k in cats)
    print(f"{c}: {g}/{len(a)} = {po:.2f} kappa {((po-pe)/(1-pe) if pe<1 else float('nan')):.2f}")
print(f'overall {ag}/{n} = {ag/n:.3f}')
