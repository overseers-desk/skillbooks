exec(open('extract.py').read().split('json.dump')[0])
import re
AU=[v for v in out.values() if v["country"].strip().lower().startswith("australia")]
for v in sorted(AU,key=lambda x:x["name"]):
    a=re.sub(r"\s+"," ",(v.get("adults_free_ratio") or "")).strip()
    p=re.sub(r"\s+"," ",(v.get("participant_thresholds") or "")).strip()
    print("###",v["name"],"|",v["region"])
    print("  ADULTS:",a[:260])
    print("  THRESH:",p[:260])
