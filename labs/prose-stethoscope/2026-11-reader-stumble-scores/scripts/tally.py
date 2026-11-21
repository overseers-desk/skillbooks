#!/usr/bin/env python3
"""Count a cell's expectations met and broken by the strength of their source, quoting none of them,
so that results on a text kept outside this lab can be reported here.
An expectation's label may open with its source in brackets; the first word inside is the strength.
Only runs made with the prompt as the files now assemble it are counted, so a cell rerun after a fact
or a criterion changed is not mixed with its earlier runs. An expectation is met, or a quiet broken,
when more than half of those runs score 4 or more on a named offence at a listed sentence.
usage: tally.py [--root <dir>] <prompt>+<format> ..."""
import glob, json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run
from run import ROOT, load

args = run.take_root(sys.argv[1:])
print("| Prompt+format | Text | Role | Runs | Flags met, by source | Quiets broken | Contested scored | Rows at 4+ per run | Sentences |")
print("|---|---|---|---|---|---|---|---|---|")
for pf in args:
    for path in sorted(glob.glob(f"{run.DATA}/runs/{pf}/*.json")):
        cell = json.load(open(path))
        meta = load(f"{run.DATA}/texts/{cell['text']}.md")[0]
        ids = [c.strip() for c in load(f"{ROOT}/formats/{cell['format']}.md")[0]["criteria"][0].split(",")]
        offence_of = [load(f"{ROOT}/criteria/{c}.md")[0]["offence"][0] for c in ids]
        now = run.render(cell["prompt"], cell["format"], cell["text"])
        runs = [r for b in cell["batches"] if b["assembled_prompt"] == now and not b.get("overrides") for r in b["runs"] if r["valid"]]
        met, total, counts = {}, {}, {"quiet": [0, 0], "contested": [0, 0]}
        for kind in ("flag", "quiet", "contested"):
            for line in meta.get(kind, []):
                offences, sents, label = line.split(" ", 2)
                cols = [i for i, o in enumerate(offence_of) if offences == "any" or o in offences.split(",")]
                if not cols or not runs:
                    continue
                hits = 0
                for r in runs:
                    keys = list(r["rows"]) if sents == "all" else sents.split(",")
                    hits += any(r["rows"][k]["s"][i] >= 4 for k in keys if k in r["rows"] for i in cols)
                won = hits * 2 > len(runs)
                if kind == "flag":
                    m = re.match(r"\[(\w+)", label)
                    src = m.group(1) if m else "unmarked"
                    total[src] = total.get(src, 0) + 1
                    met[src] = met.get(src, 0) + won
                else:
                    counts[kind][0] += won
                    counts[kind][1] += 1
        flags = ", ".join(f"{s} {met[s]}/{total[s]}" for s in total) or "none set"
        per_run = " ".join(str(sum(1 for v in r["rows"].values() if max(v["s"]) >= 4)) for r in runs)
        role = meta.get("role", [""])[0].split(":")[0]
        print(f"| {pf} | {cell['text']} | {role} | {len(runs)} | {flags} | {counts['quiet'][0]}/{counts['quiet'][1]} | {counts['contested'][0]}/{counts['contested'][1]} | {per_run} | {len(cell['sents'])} |")
