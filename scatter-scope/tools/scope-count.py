#!/usr/bin/env python3
"""SCOPE Count: the measured table for every module of a codebase.

Inputs: a SCIP index printed as JSON (for Rust: `rust-analyzer scip <root> --output
index.scip`, then `scip print --json index.scip > index.json`) and the tree it was built
from. For each file that defines symbols, the tool reports

  A      files outside it, tests excluded, that reference a symbol it defines (the graph)
  B      files of any kind that mention any name in its vocabulary (grep)
  C      total such mentions
  leak   B minus the files the graph already counted
  score  C x leak/B, the rank that puts a leaking module first with no oracle

The vocabulary of a file is the set of symbol names it defines plus its stem, less
common English words (a dictionary file, when present) and less stems that are English
words; names with an underscore or an inner capital stay. Usage:

  scope-count.py --root <repo> --scip index.json [--corpus-ext .rs,.md,.toml]
                 [--exclude .claude/,target/] [--tests-mark /tests/] [--json out.json]
"""
import argparse
import collections
import json
import os
import re


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    ap.add_argument("--scip", required=True, help="SCIP index printed as JSON")
    ap.add_argument("--corpus-ext", default=".rs,.md,.toml")
    ap.add_argument("--exclude", default=".claude/,target/,.git/",
                    help="path fragments that keep a file out of the corpus")
    ap.add_argument("--tests-mark", default="/tests/",
                    help="path fragment that marks a file as test code for A")
    ap.add_argument("--dict", default="/usr/share/dict/words")
    ap.add_argument("--min-name", type=int, default=5)
    ap.add_argument("--json", help="also write the table here")
    ap.add_argument("--top", type=int, default=40)
    a = ap.parse_args()

    exts = tuple(a.corpus_ext.split(","))
    excl = [e for e in a.exclude.split(",") if e]
    tests_mark = a.tests_mark

    index = json.load(open(a.scip))
    home, refs = {}, collections.defaultdict(set)
    for doc in index["documents"]:
        f = doc["relative_path"]
        for o in doc.get("occurrences", []):
            s = o["symbol"]
            if s.startswith("local ") or s.endswith("/"):
                continue
            if o.get("symbol_roles", 0) & 1:
                home.setdefault(s, f)
            else:
                refs[s].add(f)

    def name_of(sym):
        m = re.search(r"([A-Za-z_][A-Za-z0-9_]*)[#().]*$", sym.split(" ")[-1].split("/")[-1])
        return m.group(1) if m else None

    words = set()
    if os.path.exists(a.dict):
        words = {l.strip().lower() for l in open(a.dict, errors="ignore")}

    vocab, graph_files = collections.defaultdict(set), collections.defaultdict(set)
    for s, f in home.items():
        n = name_of(s)
        if n and len(n) >= a.min_name and not n.startswith("impl"):
            vocab[f].add(n)
        graph_files[f] |= {g for g in refs[s] if g != f and tests_mark not in g}
    for f in list(vocab):
        stem = os.path.splitext(os.path.basename(f))[0]
        if stem not in ("lib", "mod", "main", "index") and stem.lower() not in words:
            vocab[f].add(stem)

    corpus = {}
    for dirpath, dirs, files in os.walk(a.root):
        rel = os.path.relpath(dirpath, a.root)
        rel = "" if rel == "." else rel + "/"
        if any(e in rel for e in excl):
            dirs[:] = []
            continue
        for fn in files:
            if fn.endswith(exts):
                p = rel + fn
                with open(os.path.join(dirpath, fn), errors="ignore") as fh:
                    corpus[p] = fh.read()

    defined_in = collections.Counter()
    for ws in vocab.values():
        for w in ws:
            defined_in[w] += 1

    rows = []
    for f, ws in vocab.items():
        stem = os.path.splitext(os.path.basename(f))[0]
        ws = {w for w in ws if defined_in[w] == 1 and (
            w == stem or "_" in w or re.search(r"[a-z][A-Z]", w)
            or (w.lower() not in words and not w.isupper()))}
        if not ws:
            continue
        pat = re.compile(r"\b(?:" + "|".join(sorted(map(re.escape, ws), key=len, reverse=True)) + r")\b")
        grep_files = {g for g, t in corpus.items() if g != f and pat.search(t)}
        sites = sum(len(pat.findall(corpus[g])) for g in grep_files)
        g = graph_files[f]
        leak = grep_files - g
        score = round(sites * (len(leak) / max(len(grep_files), 1)))
        rows.append(dict(file=f, A=len(g), B=len(grep_files), C=sites, leak=len(leak),
                         score=score, vocab=sorted(ws, key=len)[:6]))
    rows.sort(key=lambda r: (-r["score"], -r["B"]))

    print("score | leak |  A  |  B  |  C   | file | vocabulary sample")
    for r in rows[:a.top]:
        print(f"{r['score']:5d} {r['leak']:5d} {r['A']:4d} {r['B']:5d} {r['C']:6d}  {r['file']:40s} {','.join(r['vocab'])}")
    if a.json:
        json.dump(rows, open(a.json, "w"), indent=1)


if __name__ == "__main__":
    main()
