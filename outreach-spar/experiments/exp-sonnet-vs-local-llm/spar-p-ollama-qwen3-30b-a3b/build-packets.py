#!/usr/bin/env python3
"""Assemble the blind judging packets that judge-brief.md describes: for each
stem with a profile in profiles/, the five July versions plus this run's,
each under a codename drawn at random per stem, order rotated per stem.

Usage: build-packets.py [--seed N]
Writes judging/<stem>/<codename>.md and judging/key.tsv (stem, codename,
version, position). Existing packets are rebuilt.
"""
import os, random, re, shutil, sys

HERE = os.path.dirname(os.path.abspath(__file__))
JULY = os.path.join(HERE, "..", "2026-07-02-blind-quality-12x5")
POOL = ["kappa", "lambda", "mu", "nu", "xi", "omicron", "rho", "sigma", "tau", "upsilon", "phi", "chi", "psi", "omega"]
JULY_CODES = ["alpha", "beta", "gamma", "delta", "epsilon"]
# Lines that would tell a judge which version came from this run: a home or
# source-tree path, a model or host name, the driver's own boilerplate.
LEAK = re.compile(r"/(home|Users)/|/usr/local/src|/tmp/|qwen|ollama|dappnode|PROFILE WRITTEN", re.I)

seed = int(sys.argv[sys.argv.index("--seed") + 1]) if "--seed" in sys.argv else 20260922
rng = random.Random(seed)
out = os.path.join(HERE, "judging")
if os.path.isdir(out):
    shutil.rmtree(out)
os.makedirs(out)
key = ["stem\tcodename\tversion\tposition"]

def strip_local(text):
    lines = [ln for ln in text.splitlines()
             if not re.match(r"^profile_date:", ln) and not LEAK.search(ln)]
    return "\n".join(lines).rstrip() + "\n"

for stem in sorted(s.strip() for s in open(os.path.join(HERE, "stems-12.txt")) if s.strip()):
    mine = os.path.join(HERE, "profiles", stem + ".md")
    if not os.path.exists(mine):
        continue
    versions = [(c, open(os.path.join(JULY, f"{stem}.{c}.md")).read()) for c in JULY_CODES]
    versions.append(("dappnode", strip_local(open(mine).read())))
    codes = rng.sample(POOL, len(versions))
    order = list(range(len(versions)))
    rng.shuffle(order)
    d = os.path.join(out, stem)
    os.makedirs(d)
    for pos, i in enumerate(order, 1):
        ver, text = versions[i]
        with open(os.path.join(d, codes[i] + ".md"), "w") as f:
            f.write(text)
        key.append(f"{stem}\t{codes[i]}\t{ver}\t{pos}")
open(os.path.join(out, "key.tsv"), "w").write("\n".join(key) + "\n")
print(f"{(len(key) - 1) // 6} packets under {out}")
