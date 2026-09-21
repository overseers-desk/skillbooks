#!/usr/bin/env python3
"""Score the decomposed direct-API outputs against their keys.

Usage:
  decomposed-score.py ratings   <outputs-dir> <july-study-dir>
      star_rating from each rating-<stem>.md against the Sonnet baseline's
      (<stem>.beta.md): per contact, mean signed and mean absolute difference.
  decomposed-score.py ponyclub  <outputs-dir> <hosted-rows.tsv> [glob]
      union of the TSV rows in the pony club outputs (default ponyclub-chunk-*.md)
      against the hosted arm's rows from that source: hits, misses, extras.
  decomposed-score.py websearch <outputs-dir> <hosted-rows.tsv>
      per trade, names rostered by the per-query outputs against the hosted
      arm's web-search rows, matched on a normalised organisation name.

An output file may open with a <!-- thinking --> block; only the text after
<!-- /thinking --> is read. A TSV block is the run of lines with tabs
following the header line the prompt asked for; the Excluded section is
everything from a line starting "Excluded".
"""
import glob, os, re, sys

def answer(path):
    t = open(path).read()
    i = t.find("<!-- /thinking -->")
    return t[i + len("<!-- /thinking -->"):] if i >= 0 else t

def tsv_rows(text):
    rows, in_block = [], False
    for ln in text.splitlines():
        if re.match(r"^\s*Excluded", ln, re.I):
            break
        if "\t" in ln:
            cells = [c.strip() for c in ln.split("\t")]
            if cells[0].lower() in ("club", "name"):
                in_block = True; continue
            if in_block or len(cells) >= 3:
                rows.append(cells)
    return rows

def norm(s):
    s = s.lower()
    s = re.sub(r"\b(inc|incorporated|pty|ltd|the|pony|club|co|&|and)\b", " ", s)
    return re.sub(r"[^a-z0-9]+", " ", s).strip()

def ratings(out, july):
    diffs = []
    for f in sorted(glob.glob(os.path.join(out, "rating-*.md"))):
        stem = os.path.basename(f)[len("rating-"):-3]
        m = re.search(r"star_rating:\s*([1-5])", answer(f))
        b = re.search(r"^star_rating:\s*([1-5])", open(os.path.join(july, stem + ".beta.md")).read(), re.M)
        if not m or not b:
            print(f"{stem}\tlocal={'?' if not m else m.group(1)}\tsonnet={'?' if not b else b.group(1)}\tunparsed"); continue
        d = int(m.group(1)) - int(b.group(1)); diffs.append(d)
        print(f"{stem}\tlocal={m.group(1)}\tsonnet={b.group(1)}\tdiff={d:+d}")
    if diffs:
        print(f"n={len(diffs)}\tmean_signed={sum(diffs)/len(diffs):+.2f}\tmean_abs={sum(abs(d) for d in diffs)/len(diffs):.2f}\texact={sum(1 for d in diffs if d==0)}")

def key_names(tsv):
    names = []
    for i, ln in enumerate(open(tsv)):
        if i == 0: continue
        c = ln.rstrip("\n").split("\t")
        names.append((c[2] if len(c) > 2 and c[2] else c[1]))
    return [n for n in names if n]

def ponyclub(out, key, pattern="ponyclub-chunk-*.md"):
    found = []
    for f in sorted(glob.glob(os.path.join(out, pattern))):
        found += [r[0] for r in tsv_rows(answer(f)) if r and r[0]]
    hosted = key_names(key)
    hits = [h for h in hosted if any(norm(h) and norm(h) in norm(x) or norm(x) in norm(h) for x in found)]
    extras = [x for x in found if not any(norm(h) in norm(x) or norm(x) in norm(h) for h in hosted)]
    print(f"local rows={len(found)}\thosted={len(hosted)}\thits={len(hits)}\tmisses={len(hosted)-len(hits)}\textras={len(extras)}")
    print("hits:", "; ".join(hits)); print("misses:", "; ".join(h for h in hosted if h not in hits)); print("extras:", "; ".join(extras))

def websearch(out, key):
    hosted = {}
    for i, ln in enumerate(open(key)):
        if i == 0: continue
        c = ln.rstrip("\n").split("\t")
        hosted.setdefault(c[3].split(" (")[0] if len(c) > 3 else "?", []).append(c[2] if c[2] else c[1])
    found = {}
    for f in sorted(glob.glob(os.path.join(out, "query-*.md"))):
        trade = re.sub(r"^query-(.*)-(beaudesert|boonah|canungra|tamborine|jimboomba|toowoomba|kyogle|murwillumbah)-(qld|nsw)$", r"\1", os.path.basename(f)[:-3])
        found.setdefault(trade, []).extend(r[0] for r in tsv_rows(answer(f)) if r and r[0])
    allfound = [x for v in found.values() for x in v]
    for role, names in sorted(hosted.items()):
        hits = [h for h in names if any(norm(h) in norm(x) or norm(x) in norm(h) for x in allfound)]
        print(f"{role}\thosted={len(names)}\thit={len(hits)}\t{'; '.join(hits)}")
    print(f"local rows total={len(allfound)} across {len(found)} trades: " + ", ".join(f"{t}={len(v)}" for t, v in sorted(found.items())))

cmd = sys.argv[1]
if cmd == "ratings": ratings(sys.argv[2], sys.argv[3])
elif cmd == "ponyclub": ponyclub(sys.argv[2], sys.argv[3], *sys.argv[4:5])
elif cmd == "websearch": websearch(sys.argv[2], sys.argv[3])
else: sys.exit(__doc__)
