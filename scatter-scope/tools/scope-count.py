#!/usr/bin/env python3
"""SCOPE Count: the measured table for every module of a codebase.

Inputs: a SCIP index as JSON (`scip print --json`, or tools/scip2json.py on the protobuf)
and the tree it was built from. For each file that defines symbols the tool reports

  A      files outside it, tests excluded, that reference a symbol it defines (the graph)
  D      files, tests excluded, whose symbols it references (its out-degree; a hub is high D)
  B      files of any kind that mention any name in its vocabulary (grep)
  C      total such mentions
  leak   B minus the files the graph already counted in A
  score  C x leak/B, the rank that puts a leaking module first with no oracle

A file's vocabulary is the set of names it alone defines, plus its stem, filtered so that
prose cannot inflate the count: a name with an underscore or an inner capital stays; a
capitalised name stays and is matched case-sensitively; a lowercase name or a stem goes when
it is an English word (dictionary file, inflections stripped); any name that also names a
symbol defined outside the tree (a standard-library or dependency type) goes. Names several files define
are not erased: each becomes a convention row in a second table, with the same A, B, C over
all its homes, because a name repeated across sibling modules is a concept with N homes.

Usage:
  scope-count.py --root <repo> --scip index.json [--corpus-ext .rs,.md,...]
                 [--exclude .git/,node_modules/,...] [--tests-mark /tests/,.test.]
                 [--json out.json] [--top 40]
"""
import argparse
import collections
import json
import os
import re

DEFAULT_EXT = ".rs,.toml,.md,.js,.mjs,.cjs,.ts,.tsx,.jsx,.py,.go,.java,.kt,.swift,.c,.h,.cpp,.hpp,.sql,.yaml,.yml,.json,.tcl,.sh,.css,.html"
DEFAULT_EXCLUDE = ".git/,node_modules/,target/,dist/,build/,.claude/,vendor/"
DEFAULT_SKIP_FILES = "package-lock.json,Cargo.lock,yarn.lock,pnpm-lock.yaml"
SUFFIXES = ("ings", "ing", "ies", "ers", "er", "ed", "es", "s")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    ap.add_argument("--scip", required=True, help="SCIP index as JSON")
    ap.add_argument("--corpus-ext", default=DEFAULT_EXT)
    ap.add_argument("--exclude", default=DEFAULT_EXCLUDE,
                    help="path fragments that keep a directory or file out of the corpus")
    ap.add_argument("--skip-files", default=DEFAULT_SKIP_FILES, help="file names left out of the corpus")
    ap.add_argument("--tests-mark", default="/tests/,.test.,_test.,/test/",
                    help="path fragments that mark test code, excluded from A and D")
    ap.add_argument("--dict", default="/usr/share/dict/words")
    ap.add_argument("--min-name", type=int, default=5)
    ap.add_argument("--json", help="also write both tables here")
    ap.add_argument("--top", type=int, default=40)
    a = ap.parse_args()

    exts = tuple(a.corpus_ext.split(","))
    excl = [e for e in a.exclude.split(",") if e]
    skip_files = set(a.skip_files.split(","))
    tests_marks = [m for m in a.tests_mark.split(",") if m]

    def is_test(p):
        return any(m in p for m in tests_marks)

    words = set()
    if os.path.exists(a.dict):
        words = {l.strip().lower() for l in open(a.dict, errors="ignore")}

    def english(w):
        w = w.lower()
        if w in words:
            return True
        for s in SUFFIXES:
            if w.endswith(s) and len(w) - len(s) >= 3 and w[:-len(s)] in words:
                return True
        return False

    def keep(name, stem):
        if len(name) < a.min_name:
            return False
        if "_" in name or re.search(r"[a-z][A-Z]", name):
            return True
        if name[0].isupper() and not name.isupper():
            return True                      # capitalised type name, matched case-sensitively
        return not english(name)             # lowercase word, all-caps constant, or the stem

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

    external = {name_of(s) for s in refs if s not in home}   # names of symbols defined outside the tree
    names_in = collections.defaultdict(set)        # file -> names it defines
    defined_in = collections.defaultdict(set)      # name -> files defining it
    graph_in = collections.defaultdict(set)        # file -> non-test files referencing its symbols
    graph_out = collections.defaultdict(set)       # file -> non-test files whose symbols it references
    for s, f in home.items():
        n = name_of(s)
        if n and not n.startswith("impl"):
            names_in[f].add(n)
            defined_in[n].add(f)
        for g in refs[s]:
            if g != f and not is_test(g):
                graph_in[f].add(g)
                if not is_test(f):
                    graph_out[g].add(f)

    corpus = {}
    for dirpath, dirs, files in os.walk(a.root):
        rel = os.path.relpath(dirpath, a.root)
        rel = "" if rel == "." else rel + "/"
        if any(e in rel for e in excl):
            dirs[:] = []
            continue
        for fn in files:
            if fn.endswith(exts) and fn not in skip_files:
                p = rel + fn
                if any(e in p for e in excl):
                    continue
                with open(os.path.join(dirpath, fn), errors="ignore") as fh:
                    corpus[p] = fh.read()

    def grep(ws, exclude_files):
        pat = re.compile(r"\b(?:" + "|".join(sorted(map(re.escape, ws), key=len, reverse=True)) + r")\b")
        files = {g for g, t in corpus.items() if g not in exclude_files and pat.search(t)}
        sites = sum(len(pat.findall(corpus[g])) for g in files)
        return files, sites

    modules = []
    for f, ns in names_in.items():
        stem = os.path.splitext(os.path.basename(f))[0]
        ws = {n for n in ns if len(defined_in[n]) == 1 and keep(n, stem) and n not in external}
        if stem not in ("lib", "mod", "main", "index") and len(stem) >= 3 and not english(stem):
            ws.add(stem)
        if not ws:
            modules.append(dict(file=f, A=len(graph_in[f]), D=len(graph_out[f]), B=0, C=0, leak=0,
                                score=0, vocab=[], note="no distinctive vocabulary; B not measured"))
            continue
        gfiles, sites = grep(ws, {f})
        leak = gfiles - graph_in[f]
        score = round(sites * (len(leak) / max(len(gfiles), 1)))
        modules.append(dict(file=f, A=len(graph_in[f]), D=len(graph_out[f]), B=len(gfiles), C=sites,
                            leak=len(leak), score=score, vocab=sorted(ws, key=len)[:6], note=""))
    modules.sort(key=lambda r: (-r["score"], -r["B"]))

    conventions = []
    for n, homes in defined_in.items():
        if len(homes) < 2 or not keep(n, "") or n in external:
            continue
        consumers = set()
        for s, f in home.items():
            if name_of(s) == n:
                consumers |= {g for g in refs[s] if g not in homes and not is_test(g)}
        gfiles, sites = grep({n}, homes)
        conventions.append(dict(name=n, homes=len(homes), sample_homes=sorted(homes)[:4],
                                A=len(consumers), B=len(gfiles), C=sites))
    conventions.sort(key=lambda r: (-r["homes"], -r["B"]))

    print("MODULES   score | leak |  A  |  D  |  B  |  C   | file | vocabulary sample")
    for r in modules[:a.top]:
        print(f"{r['score']:5d} {r['leak']:5d} {r['A']:4d} {r['D']:4d} {r['B']:5d} {r['C']:6d}  {r['file']:44s} {','.join(r['vocab'])}{'  ' + r['note'] if r['note'] else ''}")
    unmeasured = sum(1 for r in modules if r["note"])
    if unmeasured:
        print(f"({unmeasured} modules with no distinctive vocabulary: B, C not measured, A and D still hold)")
    print("\nCONVENTIONS (one name, several defining files)   homes |  A  |  B  |  C   | name | homes sample")
    for r in conventions[:a.top]:
        print(f"{r['homes']:5d} {r['A']:4d} {r['B']:5d} {r['C']:6d}  {r['name']:30s} {', '.join(r['sample_homes'])}")
    if a.json:
        json.dump({"modules": modules, "conventions": conventions}, open(a.json, "w"), indent=1)


if __name__ == "__main__":
    main()
