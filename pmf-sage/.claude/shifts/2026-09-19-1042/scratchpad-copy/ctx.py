import re,sys,glob,os
pat = sys.argv[1]
seen=set()
for v in sys.argv[2:]:
    print("################", v)
    for f in sorted(glob.glob(os.path.join(v,'*.txt'))):
        t=open(f,encoding='utf-8',errors='replace').read()
        for m in re.finditer(pat,t,re.I):
            s=max(0,m.start()-130); snip=' '.join(t[s:m.end()+200].split())
            if snip in seen: continue
            seen.add(snip); print(' ', os.path.basename(f),'|',snip)
