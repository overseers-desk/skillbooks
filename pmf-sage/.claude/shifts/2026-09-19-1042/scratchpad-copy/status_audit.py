import re, subprocess, sys, glob, pathlib

raw = subprocess.run([sys.executable, sys.argv[1], "."], capture_output=True, text=True).stdout
stance = {}
for cid, st in re.findall(r"^card (\S+):.*?held value: ([a-z ]+);", raw, re.M):
    stance[cid] = st

for f in sorted(glob.glob("3-decisions/card-*.md")):
    t = pathlib.Path(f).read_text()
    cid = re.search(r"^## Card\s+(\S+)", t, re.M).group(1).rstrip("·").strip()
    st = stance.get(cid, "?")
    status = re.search(r'^status: "(.*)"$', t, re.M).group(1)
    tail = status[-260:]
    withheld = st.startswith("withheld")
    # a withheld card whose status ends claiming the line stands/carried, or vice versa
    bad = []
    if withheld and re.search(r"\b(stands|is carried|recommendation is carried)\b", tail) and "withheld" not in tail:
        bad.append("status tail says stands/carried but the line is withheld")
    if not withheld and re.search(r"\bis withheld\b", tail) and "stands" not in tail and "turned" not in tail and "followed" not in tail:
        bad.append("status tail says withheld but the line carries an option")
    print(f"card {cid:>2} [{st:<13}] {'OK' if not bad else 'CHECK: ' + '; '.join(bad)}")
    if bad:
        print("      ..." + tail)
