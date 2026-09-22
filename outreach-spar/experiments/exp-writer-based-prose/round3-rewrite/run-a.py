#!/usr/bin/env python3
"""Design A: one author call that drafts the letter, then reads it as the
recipient and writes it again, both in the same call.
usage: run-a.py <sessions-a.json> <config_dir> <out_dir> [concurrency]
sessions-a.json maps stem to the transcript of an earlier author session;
that session's first user message is the harness's author prompt for the
contact, reused verbatim with prompt-a.txt appended. The call runs with
file reads allowed, since the prompt tells the author which files to read."""
import sys, os, json, re, subprocess, concurrent.futures as cf
sess, cfg, out = sys.argv[1:4]
conc = int(sys.argv[4]) if len(sys.argv) > 4 else 3
os.makedirs(out, exist_ok=True)
S = json.load(open(sess))
APPENDIX = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'prompt-a.txt')).read().strip()
env = dict(os.environ, CLAUDE_CONFIG_DIR=cfg)
def author_prompt(transcript):
    for line in open(transcript):
        e = json.loads(line)
        if e.get('type') == 'user':
            c = e['message'].get('content')
            s = c if isinstance(c, str) else ' '.join(b.get('text', '') for b in c if isinstance(b, dict) and b.get('type') == 'text')
            if s.strip():
                return s
    raise SystemExit('no prompt in ' + transcript)
def one(stem):
    dst = os.path.join(out, stem + '.txt')
    if os.path.exists(dst) and os.path.getsize(dst) > 0:
        return stem, 'kept'
    prompt = author_prompt(S[stem]['transcript']) + '\n\n' + APPENDIX
    r = subprocess.run(['claude', '-p', '--model', 'opus', '--dangerously-skip-permissions', prompt],
                       capture_output=True, text=True, timeout=1800, env=env)
    text = r.stdout.strip()
    if r.returncode or not text or text.startswith('API Error'):
        open(dst + '.err', 'w').write(r.stdout + '\n---\n' + r.stderr)
        return stem, 'failed'
    open(dst, 'w').write(text + '\n')
    w = re.search(r'FIRST_START\n(.*?)\nFIRST_END', text, re.S); d = re.search(r'DRAFT_START\n(.*?)\nDRAFT_END', text, re.S)
    return stem, f'first {len(w.group(1).split()) if w else 0} words, final {len(d.group(1).split()) if d else 0} words'
with cf.ThreadPoolExecutor(conc) as ex:
    for stem, status in ex.map(one, sorted(S)):
        print(stem, status, flush=True)
