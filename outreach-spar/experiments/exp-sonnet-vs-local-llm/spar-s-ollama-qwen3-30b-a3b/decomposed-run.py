#!/usr/bin/env python3
"""One decomposed sweep step against a local model by direct API: the model is
handed the page text and the question, nothing else, so what is measured is
reading and judgement without the agent loop around them.

Usage: decomposed-run.py <model> <run-name> <prompt-file> <out-file> [--think]
                         [--runs-tsv PATH] [--server URL]

The prompt file is sent verbatim. The response goes to <out-file>; one line of
measurements (tokens in and out, prefill and decode seconds, queue-inclusive
wall-clock) is appended to the runs TSV. No context length is requested, so a
server holding the model at its Modelfile length does not reload it.
"""
import argparse, json, os, re, sys, time, urllib.request

ap = argparse.ArgumentParser()
ap.add_argument("model"); ap.add_argument("run_name"); ap.add_argument("prompt_file"); ap.add_argument("out_file")
ap.add_argument("--think", action="store_true")
ap.add_argument("--runs-tsv", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), "decomposed-runs.tsv"))
ap.add_argument("--server", default="http://127.0.0.1:11434")
ap.add_argument("--timeout", type=int, default=14400)
ap.add_argument("--max-tokens", type=int, default=8192,
                help="generation cap; a roster-shaped answer needs a few thousand, and on a shared server a smaller cap bounds the wait of whoever is queued behind it")
a = ap.parse_args()

prompt = open(a.prompt_file).read()
req = {"model": a.model, "prompt": prompt, "stream": False, "think": a.think,
       "options": {"temperature": 0, "num_predict": a.max_tokens}}
t0 = time.time()
r = urllib.request.urlopen(urllib.request.Request(
    a.server + "/api/generate", json.dumps(req).encode(), {"Content-Type": "application/json"}),
    timeout=a.timeout)
j = json.loads(r.read()); wall = time.time() - t0
# A repeated run keeps the earlier output: the same prompt can take a
# different path and both answers are evidence.
out_file = a.out_file
n = 2
while os.path.exists(out_file):
    out_file = re.sub(r"(\.[^.]+)$", f"-{n}\\1", a.out_file); n += 1
with open(out_file, "w") as f:
    if j.get("thinking"):
        f.write("<!-- thinking -->\n" + j["thinking"] + "\n<!-- /thinking -->\n\n")
    f.write(j.get("response", ""))
ns = 1e9
row = [a.run_name, a.model, "on" if a.think else "off",
       str(j.get("prompt_eval_count", "")), str(j.get("eval_count", "")),
       f"{j.get('prompt_eval_duration', 0)/ns:.0f}", f"{j.get('eval_duration', 0)/ns:.0f}",
       f"{j.get('total_duration', 0)/ns:.0f}", f"{wall:.0f}",
       str(len((j.get("thinking") or ""))), time.strftime("%Y-%m-%dT%H:%M:%S")]
new = not os.path.exists(a.runs_tsv)
with open(a.runs_tsv, "a") as f:
    if new:
        f.write("run\tmodel\tthink\tprompt_tokens\toutput_tokens\tprefill_s\tdecode_s\tserver_total_s\twall_s\tthinking_chars\tfinished\n")
    f.write("\t".join(row) + "\n")
print("\t".join(row))
