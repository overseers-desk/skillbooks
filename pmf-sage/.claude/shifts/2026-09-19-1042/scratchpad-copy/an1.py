exec(open('extract.py').read().split('json.dump')[0])
V=out
def cell(v):
    c=v["cell"]
    if c.startswith("United Kingdom —"): return "uk-farm"
    if c.startswith("United Kingdom /"): return "uk-nature"
    if c.startswith("AU-farm"): return "au-nz-ca"
    return c
reg=[v for v in V.values() if cell(v) in ("uk-farm","uk-nature","au-nz-ca")]
AU=[v for v in V.values() if v["country"].strip().lower().startswith("australia")]
QLD=[v for v in AU if "qld" in v["region"].lower() or "queensland" in v["region"].lower()]
print("reg",len(reg),"AU",len(AU),"QLD",len(QLD))
def has(v,f):
    s=(v.get(f) or "").strip().lower()
    if not s: return None
    for n in ("none","not listed","not stated","no ","nothing","not published","n/a","not available","not mentioned"):
        if s.startswith(n): return False
    return True
import sys
for f in ["curriculum_links","teacher_materials","risk_assessment_available","downloadable_pack","insurance_stated","child_safety_checks_stated","adults_free_ratio","participant_thresholds","staff_qualifications_stated"]:
    row=[]
    for pop,nm in ((reg,"reg189"),(AU,"AU%d"%len(AU)),(QLD,"QLD%d"%len(QLD))):
        y=sum(1 for v in pop if has(v,f)==True); n=sum(1 for v in pop if has(v,f)==False); m=sum(1 for v in pop if has(v,f) is None)
        row.append("%s y=%d n=%d ?=%d"%(nm,y,n,m))
    print(f.ljust(28),"  |  ".join(row))
