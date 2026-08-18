#!/usr/bin/env python3
"""Facts-fed SPAR-P batch for the GPU-Workstation (CUDA, ollama). For each stem:
reconstruct neutral source facts from the Sonnet profile (front-matter + the
Relevance-assessment and Verification-corrections verdict sections removed), feed
them one-shot to an ollama model, and write the model's profile to that model's
worktree. Records wall time and context per profile (incl. failures).

Usage: cuda-factsfed-batch.py <ollama-model> <stems-file> <src-profiles-dir> \
                              <dest-profiles-dir> <instructions-file> <progress-file> <raw-dir>
"""
import json, sys, os, re, time, urllib.request

model, stems_file, src_dir, dest_dir, instr_file, progress_file, raw_dir = sys.argv[1:8]
os.makedirs(dest_dir, exist_ok=True)
os.makedirs(raw_dir, exist_ok=True)
instr = open(instr_file).read()
stems = [s.strip() for s in open(stems_file) if s.strip()]

def reconstruct_facts(md: str) -> str:
    lines = md.splitlines()
    # drop leading front-matter block (--- ... ---)
    if lines and lines[0].strip() == "---":
        end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), 0)
        lines = lines[end + 1:]
    out, skip = [], False
    for ln in lines:
        if re.match(r"^##\s+(Relevance assessment|Verification corrections)", ln):
            skip = True; continue
        if skip and re.match(r"^##\s+", ln):
            skip = False
        if not skip:
            out.append(ln)
    return "\n".join(out).strip()

def gen(prompt: str):
    req = {"model": model, "prompt": prompt, "stream": False, "think": False,
           "options": {"num_ctx": 8192, "temperature": 0, "num_predict": 4096}}
    body = json.dumps(req).encode()
    r = urllib.request.urlopen(urllib.request.Request(
        "http://127.0.0.1:11434/api/generate", body,
        {"Content-Type": "application/json"}), timeout=1800)
    return json.loads(r.read())

def clean(text: str) -> str:
    t = text.strip()
    t = re.sub(r"^```(?:markdown)?\s*", "", t)
    t = re.sub(r"\s*```$", "", t)
    i = t.find("---")
    return t[i:] if i > 0 else t

pf = open(progress_file, "a")
for stem in stems:
    src = os.path.join(src_dir, stem + ".md")
    if not os.path.exists(src):
        pf.write(f"{stem}\toutcome=fail-nosource\tmodel={model}\n"); pf.flush(); continue
    facts = reconstruct_facts(open(src).read())
    prompt = instr + "\n\n=== SOURCE FACTS ===\n\n" + facts
    t0 = time.time(); outcome = "fail-unknown"; star = ""; yld = ""; pe = ec = 0
    try:
        resp = gen(prompt)
        text = clean(resp.get("response", ""))
        pe = resp.get("prompt_eval_count") or 0
        ec = resp.get("eval_count") or 0
        open(os.path.join(raw_dir, stem + ".raw.txt"), "w").write(resp.get("response", ""))
        if text.startswith("---") and "star_rating" in text:
            open(os.path.join(dest_dir, stem + ".md"), "w").write(text + "\n")
            m = re.search(r"^star_rating:\s*(\d+)", text, re.M); star = m.group(1) if m else ""
            y = re.search(r"^yield:\s*(\d+)", text, re.M); yld = y.group(1) if y else ""
            outcome = "success" if star else "fail-nostar"
        else:
            outcome = "fail-noprofile"
    except Exception as e:
        outcome = "fail-error"; open(os.path.join(raw_dir, stem + ".err"), "w").write(str(e))
    dur = round(time.time() - t0, 1)
    peak = pe + ec  # total context used (prompt + generated)
    pf.write(f"{stem}\toutcome={outcome}\tstar={star}\tyield={yld}\tdur_s={dur}"
             f"\tpeak_ctx={peak}\tout_tok={ec}\tmodel={model}\n"); pf.flush()
    print(f"{stem}: {outcome} star={star} dur={dur}s ctx={peak}")
pf.close()
print(f"=== {model} batch done: {sum(1 for _ in open(progress_file) if 'outcome=success' in _)} success lines total ===")
