#!/usr/bin/env python3
"""Design B: prompt the session that wrote each letter to write it again.
usage: rewrite-author.py <sessions.json> <config_dir> <out_dir> [concurrency]
sessions.json maps each blinded letter name to the author session id that
produced it (built by map-sessions.py). The prompt is prompt-author.txt.
Runs from the current directory; the resumed session holds its own context."""
import sys, os, json, subprocess, concurrent.futures as cf
sess, cfg, out = sys.argv[1:4]
conc = int(sys.argv[4]) if len(sys.argv) > 4 else 3
os.makedirs(out, exist_ok=True)
S = json.load(open(sess))
PROMPT = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'prompt-author.txt')).read().strip()
env = dict(os.environ, CLAUDE_CONFIG_DIR=cfg)
def one(name):
    dst = os.path.join(out, name)
    if os.path.exists(dst) and os.path.getsize(dst) > 0:
        return name, 'kept'
    sid = S[name]['session_id']
    r = subprocess.run(['claude', '-p', '--model', S[name].get('model', 'opus'), '--resume', sid, PROMPT],
                       capture_output=True, text=True, timeout=900, env=env)
    text = r.stdout.strip()
    if r.returncode or not text or text.startswith('API Error'):
        open(dst + '.err', 'w').write(r.stdout + '\n---\n' + r.stderr)
        return name, 'failed'
    open(dst, 'w').write(text + '\n')
    return name, f'{len(text.split())} words'
with cf.ThreadPoolExecutor(conc) as ex:
    for name, status in ex.map(one, sorted(S)):
        print(name, status, flush=True)
