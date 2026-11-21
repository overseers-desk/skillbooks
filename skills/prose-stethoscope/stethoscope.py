#!/usr/bin/env python3
"""Listen to a prose draft: run each module on it as a pass of its own and print every sentence a reader
scored, with the scores and the reader's reason.
usage: stethoscope.py <draft.md> [--reader "who reads it and what they have read"] [--module M ...]
       [--fact name="..." ...] [--runs N] [--model M]
A module is a file: front matter naming its columns, then the prompt, with {text} where the draft goes
and a {slot} for each thing the caller supplies. --module takes the name of one beside this script or
the path of one anywhere; without it the flow and faults modules run. --fact fills a module's slot, and
a slot left unfilled stops the run.
A first line starting with '#' is taken as the title and not read. Paragraphs are separated by blank lines;
each list item, table row and later heading is read as a unit of its own, and fenced blocks and ::: fence
lines are skipped."""
import argparse, json, os, re, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
SPLIT = re.compile(r'(?<=[.?!:])\s+(?=[A-Z"*“‘])')


def template(module):
    """A module's name, columns and prompt, from a name beside this script or a path."""
    path = module if os.sep in module or module.endswith(".md") else os.path.join(HERE, f"{module}.md")
    head, body = open(path).read()[4:].split("\n---\n", 1)
    meta = dict(line.split(": ", 1) for line in head.split("\n"))
    return os.path.splitext(os.path.basename(path))[0], [c.strip() for c in meta["columns"].split(",")], body.rstrip("\n")


def units(lines):
    """Paragraphs of prose, with each list item, table row and heading as a unit of its own."""
    out, cur, fenced = [], [], False
    def flush():
        if cur:
            out.append(" ".join(cur)); cur.clear()
    for raw in lines:
        line = raw.strip()
        if re.match(r"^(```|~~~)", line):
            flush(); fenced = not fenced; continue
        if fenced:
            continue
        if not line or line.startswith(":::"):
            flush(); continue
        if re.match(r"^\|?\s*:?-{3,}", line):
            continue
        if line.startswith("|"):
            flush(); out.append("; ".join(c.strip() for c in line.strip("|").split("|") if c.strip())); continue
        if re.match(r"^#+\s", line):
            flush(); out.append(re.sub(r"^#+\s+", "", line)); continue
        if re.match(r"^([-*+]\s|\d+[.)]\s)", line):
            flush(); cur.append(re.sub(r"^([-*+]|\d+[.)])\s+", "", line)); continue
        cur.append(line)
    flush()
    return [u for u in out if u]


def call(prompt, model):
    p = subprocess.run(["claude", "-p", "--model", model, "--tools", "", "--system-prompt", "You are a careful reader of prose.",
                        "--setting-sources", "", "--strict-mcp-config", "--output-format", "json"],
                       input=prompt, cwd=tempfile.gettempdir(), capture_output=True, text=True, timeout=900)
    try:
        return json.loads(p.stdout[p.stdout.index("{"):]).get("result") or ""
    except ValueError:
        return p.stdout[-300:] or p.stderr[-300:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("draft")
    ap.add_argument("--reader", default="The intended reader comes to this text fresh and has read nothing before it.")
    ap.add_argument("--module", action="append")
    ap.add_argument("--fact", action="append", default=[])
    ap.add_argument("--runs", type=int, default=1)
    ap.add_argument("--model", default="claude-opus-5-5")
    a = ap.parse_args()
    lines = open(a.draft).read().strip().split("\n")
    if lines and lines[0].startswith("#"):
        lines = lines[1:]
    paras = units(lines)
    text = "\n\n".join(f"[P{n}] {p}" for n, p in enumerate(paras, 1))
    sents = {(pi, si): s for pi, p in enumerate(paras, 1) for si, s in enumerate(SPLIT.split(p), 1)}

    facts = dict(f.split("=", 1) for f in a.fact)
    facts.setdefault("reader", a.reader)
    jobs = []
    for module in a.module or ["flow", "faults"]:
        name, cols, body = template(module)
        for k, v in facts.items():
            body = body.replace("{" + k + "}", v)
        unfilled = sorted(set(re.findall(r"\{([a-z][a-z-]*)\}", body)) - {"text"})
        if unfilled:
            sys.exit(f"the {name} module needs " + " ".join(f'--fact {k}="..."' for k in unfilled))
        jobs += [(name, cols, body.replace("{text}", text), r) for r in range(1, a.runs + 1)]
    def run(j):
        reply = call(j[2], a.model)
        print(f"{j[0]} pass, run {j[3]}: done", file=sys.stderr, flush=True)
        return reply
    print(f"{len(jobs)} calls on {a.model}, a minute or more each", file=sys.stderr, flush=True)
    with ThreadPoolExecutor(6) as ex:
        replies = list(ex.map(run, jobs))

    print("pass\trun\tsentence\tscores (2 or more; * marks 4 or more, a stumble)\twhy\ttext")
    for (name, cols, _, r), reply in zip(jobs, replies):
        if "END" not in reply or "API Error" in reply:
            print(f"{name}\t{r}\t-\tno complete reply\t{reply.strip()[:200]}\t")
            continue
        for p, s, sc, why in re.findall(r"^\s*P?(\d+)\.(\d+)\t([\d ,]+)\t(.*)$", reply, re.M):
            v = [int(x) for x in re.findall(r"\d", sc)][:len(cols)]
            marks = ", ".join(f"{c}={x}{'*' if x >= 4 else ''}" for c, x in zip(cols, v) if x >= 2)
            print(f"{name}\t{r}\t{p}.{s}\t{marks}\t{why.strip()}\t{sents.get((int(p), int(s)), '(no sentence at this position)')}")


if __name__ == "__main__":
    sys.exit(main())
