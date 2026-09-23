#!/usr/bin/env python3
"""One session per letter, three turns: stage 1 the triage, stage 2 the slow
read, stage 3 the reveal, each a resumed turn of the same session so no
later stage is in context earlier. Transcripts land under runs/<letter>/.
usage: run-turncoat.py <letters.json>
letters.json: {letter file name: {stem, name, email_path, prior: [[date, subject], ...]}}
Environment: SPAR_SEGMENTS (segment dir with rosters and profiles),
TURNCOAT_MODEL, CLAUDE_CONFIG_DIR, and the working directory is the run dir."""
import sys, os, re, json, uuid, glob, subprocess, concurrent.futures as cf
here = os.path.dirname(os.path.abspath(__file__))
L = json.load(open(sys.argv[1])); SEG = os.environ['SPAR_SEGMENTS']; MODEL = os.environ['TURNCOAT_MODEL']
P = {n: open(os.path.join(here, 'prompts', f)).read() for n, f in (('s1', 'stage1-triage.txt'), ('s2', 'stage2-matrix.txt'), ('s3', 'stage3-turncoat.txt'))}
def facts(stem):
    t = open(glob.glob(os.path.join(SEG, '*', stem + '.md'))[0]).read()
    body = t.split('\n---\n', 1)[1] if t.startswith('---') else t
    i = body.find('# Profile'); body = body[i:] if i >= 0 else body
    cut = min([m.start() for m in re.finditer(r'^## (Catalogue evidence|Relevance assessment|Verification corrections)', body, re.M)] or [len(body)])
    body = body[:cut].rstrip()
    return re.sub(r'(?i)\bcampaign ?', '', body) if 'Who they know' in body else body
def call(args, prompt):
    r = subprocess.run(['claude', '-p', '--model', MODEL] + args + [prompt], capture_output=True, text=True, timeout=900)
    return (r.stdout.strip() or 'ERR ' + r.stderr[-400:])
def one(letter):
    v = L[letter]; d = os.path.join(here, 'runs', letter[:-4]); os.makedirs(d, exist_ok=True)
    sid = str(uuid.uuid4()); name = v['name']
    prior = ('### Prior correspondence\n' + '\n'.join(f'- {dt}: {sj}' for dt, sj in v['prior']) + '\n\n') if v['prior'] else ''
    s1 = P['s1'].replace('__NAME__', name).replace('__PROFILE_FACTS__', facts(v['stem'])).replace('__PRIOR_CORRESPONDENCE__', prior).replace('__EMAIL__', open(v['email_path']).read().strip())
    open(os.path.join(d, 'stage1.prompt.txt'), 'w').write(s1)
    out1 = call(['--session-id', sid], s1); open(os.path.join(d, 'stage1.txt'), 'w').write(out1 + '\n')
    if out1.startswith('ERR'): return letter, 'stage1 failed'
    s2 = P['s2'].replace('__NAME__', name); out2 = call(['--resume', sid], s2); open(os.path.join(d, 'stage2.txt'), 'w').write(out2 + '\n')
    s3 = P['s3'].replace('__NAME__', name); out3 = call(['--resume', sid], s3); open(os.path.join(d, 'stage3.txt'), 'w').write(out3 + '\n')
    open(os.path.join(d, 'session.txt'), 'w').write(sid + '\n')
    last = (out1.strip().split('\n')[-1]).strip().lower().strip('.')
    return letter, f'stage1 last word: {last}; stage2 {len(out2.split())} w; stage3 {len(out3.split())} w'
with cf.ThreadPoolExecutor(4) as ex:
    for letter, status in ex.map(one, sorted(L)): print(letter, status, flush=True)
