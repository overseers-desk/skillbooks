#!/usr/bin/env python3
"""Run a stumble reader on one text and add the batch to its cell, runs/<prompt>+<format>/<model>+<text>.json.
usage: run.py <prompt> <format> <model> <text> <repeats> [key=value ...] [--dry-run]
The ids are the three-digit file names in prompts/, formats/ and texts/; the model is spelled as the
README's Models section gives it. A key=value pair replaces a value the files supply (reader,
description, table_reader), and the batch records it. --dry-run prints the assembled prompt and calls
nothing."""
import json, os, re, subprocess, sys, tempfile, time
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPLIT = re.compile(r'(?<=[.?!:])\s+(?=[A-Z"*])')


def load(path):
    """Front matter (key: value lines, a key may repeat) and the body after it."""
    s = open(path).read()
    meta = {}
    if s.startswith("---\n"):
        head, s = s[4:].split("\n---\n", 1)
        for line in head.split("\n"):
            k, v = line.split(": ", 1)
            if len(v) > 1 and v[0] == v[-1] == '"':
                v = v[1:-1]
            meta.setdefault(k, []).append(v)
    return meta, s[:-1] if s.endswith("\n") else s


def paragraphs(t):
    body = load(f"{ROOT}/texts/{t}.md")[1].split("\n", 1)[1].strip()  # the first line is the title
    return [p.strip() for p in body.split("\n\n") if p.strip()]


def sentences(t):
    return [s for p in paragraphs(t) for s in SPLIT.split(p)]


def render(p, f, t, overrides=None):
    pmeta, ptpl = load(f"{ROOT}/prompts/{p}.md")
    fmeta, ftpl = load(f"{ROOT}/formats/{f}.md")
    tmeta = load(f"{ROOT}/texts/{t}.md")[0]
    v = {"reader": tmeta.get("reader", [""])[0], "description": pmeta.get("description", [""])[0],
         "table_reader": fmeta.get("table_reader", [""])[0]}
    v.update(overrides or {})
    number = fmeta.get("numbering", ["{n}. "])[0]
    crit = "\n".join(number.replace("{n}", str(i)) + load(f"{ROOT}/criteria/{c.strip()}.md")[1].strip()
                     for i, c in enumerate(fmeta["criteria"][0].split(","), 1))
    text = "\n\n".join(f"[P{n}] {x}" for n, x in enumerate(paragraphs(t), 1))
    out = ptpl.replace("{reader}", v["reader"]).replace("{description}", v["description"])
    out = out.replace("{format}", ftpl.replace("{criteria}", crit).replace("{table_reader}", v["table_reader"]))
    return out.replace("{text}", text)


def cell_path(p, f, m, t):
    return f"{ROOT}/runs/{p}+{f}/{m}+{t}.json"


def append_batch(p, f, m, t, overrides, prompt, runs):
    path = cell_path(p, f, m, t)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    cell = json.load(open(path)) if os.path.exists(path) else {"prompt": p, "format": f, "model": m, "text": t, "sents": sentences(t), "batches": []}
    cell["batches"].append({"overrides": overrides, "assembled_prompt": prompt, "runs": runs})
    json.dump(cell, open(path, "w"), ensure_ascii=False, indent=0)


def call(prompt, model, n_scores, where):
    t0 = time.time()
    p = subprocess.run(["claude", "-p", "--model", model, "--tools", "", "--system-prompt", "You are a careful reader of prose.",
                        "--setting-sources", "", "--strict-mcp-config", "--output-format", "json"],
                       input=prompt, cwd=tempfile.gettempdir(), capture_output=True, text=True, timeout=900)
    try:
        res = json.loads(p.stdout[p.stdout.index("{"):]).get("result") or ""
    except ValueError:
        res = p.stdout[-300:]
    rows = {}
    for a, b, sc, why in re.findall(r"^\s*P?(\d+)\.(\d+)\t([\d ,]+)\t(.*)$", res, re.M):
        v = [int(x) for x in re.findall(r"\d", sc)][:n_scores]
        if len(v) == n_scores:
            rows[str(where.get((int(a), int(b)), -1))] = {"s": v, "why": why.strip()}
    return {"m": model, "valid": "END" in res and "API Error" not in res, "rows": rows, "secs": round(time.time() - t0), "raw": res[:4000]}


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    p, f, m, t, repeats = args[:5]
    overrides = dict(a.split("=", 1) for a in args[5:])
    prompt = render(p, f, t, overrides)
    if "--dry-run" in sys.argv:
        print(prompt)
        sys.exit()
    where, k = {}, 0
    for pi, x in enumerate(paragraphs(t), 1):
        for si, _ in enumerate(SPLIT.split(x), 1):
            k += 1
            where[(pi, si)] = k
    n_scores = len(load(f"{ROOT}/formats/{f}.md")[0]["criteria"][0].split(","))
    with ThreadPoolExecutor(6) as ex:
        runs = list(ex.map(lambda r: dict(call(prompt, m, n_scores, where), r=r), range(int(repeats))))
    append_batch(p, f, m, t, overrides, prompt, runs)
    print(cell_path(p, f, m, t), sum(r["valid"] for r in runs), "valid of", len(runs))
