exec(open('extract.py').read().split('json.dump')[0])
import re
V=out
def cell(v):
    c=v["cell"]
    if c.startswith("United Kingdom —"): return "uk-farm"
    if c.startswith("United Kingdom /"): return "uk-nature"
    if c.startswith("AU-farm"): return "au-nz-ca"
    return c
reg=[v for v in V.values() if cell(v) in ("uk-farm","uk-nature","au-nz-ca")]
AU=[v for v in V.values() if v["country"].strip().lower().startswith("australia")]
ALL=list(V.values())
# --- adult ratio ---
rx=re.compile(r"1\s*[:to]{1,2}\s*(\d{1,2})|one adult (?:per|to|for every)\s*(\d{1,2})|(\d{1,2})\s*(?:students?|children|pupils?)\s*(?:per|to|for every|:)\s*(?:1|one)\s*(?:adult|teacher|supervis)")
def ratios(v):
    txt=" ".join((v.get(f) or "") for f in ("participant_thresholds","adults_free_ratio","group_size_min_max"))
    return set(m.group(1) or m.group(2) or m.group(3) for m in rx.finditer(txt))
from collections import Counter
for pop,nm in ((reg,"reg189"),(AU,"AU56"),(ALL,"ALL215")):
    c=Counter()
    n=0
    for v in pop:
        r=ratios(v)
        if r: n+=1
        for x in r: c[x]+=1
    print(nm,"venues stating any adult:child ratio:",n,"| ratio values:",c.most_common(12))
# supervising-adult minimum wording
key=re.compile(r"supervis|accompany|chaperone|ratio",re.I)
for pop,nm in ((reg,"reg189"),(AU,"AU56")):
    print(nm,"venues whose thresholds/adults fields mention supervision/ratio:",sum(1 for v in pop if key.search(" ".join((v.get(f) or "") for f in ("participant_thresholds","adults_free_ratio","group_size_min_max")))))
