import os,re,glob,html,sys
root="/usr/local/src/rivermill/product-development/weddings/2026-08-15-wedding-survey/4-collection/data/r1"
for venue in sorted(os.listdir(root)):
    vd=os.path.join(root,venue)
    if not os.path.isdir(vd): continue
    for f in sorted(os.listdir(vd)):
        if not f.endswith(('.html','.htm')): continue
        p=os.path.join(vd,f)
        t=open(p,encoding='utf-8',errors='replace').read()
        nform=len(re.findall(r'<form\b',t,re.I))
        ninput=len(re.findall(r'<input\b',t,re.I))
        nlabel=len(re.findall(r'<label\b',t,re.I))
        nph=len(re.findall(r'placeholder\s*=',t,re.I))
        ntext=len(re.findall(r'<textarea\b',t,re.I))
        nsel=len(re.findall(r'<select\b',t,re.I))
        nifr=len(re.findall(r'<iframe\b',t,re.I))
        if nform or ninput or nlabel or nph or ntext or nsel:
            print(f"{venue}/{f}\tform={nform} input={ninput} label={nlabel} ph={nph} ta={ntext} sel={nsel} iframe={nifr} size={len(t)}")
