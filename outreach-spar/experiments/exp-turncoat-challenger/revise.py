#!/usr/bin/env python3
"""One author revision for each letter whose Gaslight 1 said bin: the author's
forked session (its original drafting only) is resumed with the method's
revise template, Turncoat's text standing as the challenger's feedback.
The fork transcript is copied into the run configuration's projects dir so
it resumes there. Writes runs/<letter>/revision.txt with the new draft.
usage: revise.py <letters.json> <sessions-b-fork.json> <source config dir> <revise template>
Environment: TURNCOAT_AUTHOR_MODEL, CLAUDE_CONFIG_DIR, working directory the run dir."""
import sys, os, re, json, glob, shutil, subprocess
here = os.path.dirname(os.path.abspath(__file__))
L = json.load(open(sys.argv[1])); F = json.load(open(sys.argv[2])); SRC = sys.argv[3]; T = open(sys.argv[4]).read()
MODEL = os.environ['TURNCOAT_AUTHOR_MODEL']; CFG = os.environ['CLAUDE_CONFIG_DIR']
for letter in sorted(L):
    d = os.path.join(here, 'runs', letter[:-4]); s1 = open(os.path.join(d, 'gaslight-1.txt')).read().strip()
    if s1.split('\n')[-1].strip().lower().strip('.') != 'bin': continue
    if os.path.exists(os.path.join(d, 'revision.txt')): print(letter, 'kept'); continue
    sid = F[letter]['session_id']; src = glob.glob(os.path.join(SRC, 'projects', '*', sid + '.jsonl'))[0]
    dst_dir = os.path.join(CFG, 'projects', os.path.basename(os.path.dirname(src))); os.makedirs(dst_dir, exist_ok=True)
    shutil.copy(src, os.path.join(dst_dir, sid + '.jsonl')); os.chmod(os.path.join(dst_dir, sid + '.jsonl'), 0o600)
    feedback = open(os.path.join(d, 'gaslight-1.txt')).read() + '\n\n' + open(os.path.join(d, 'turncoat.txt')).read()
    prompt = T.replace('__PASS__', '1').replace('__CHALLENGER_FEEDBACK__', feedback)
    open(os.path.join(d, 'revision.prompt.txt'), 'w').write(prompt)
    r = subprocess.run(['claude', '-p', '--model', MODEL, '--resume', sid, prompt], capture_output=True, text=True, timeout=900)
    out = r.stdout.strip() or 'ERR ' + r.stderr[-400:]
    open(os.path.join(d, 'revision.raw.txt'), 'w').write(out + '\n')
    m = re.search(r'DRAFT_START\n(.*?)\nDRAFT_END', out, re.S)
    open(os.path.join(d, 'revision.txt'), 'w').write((m.group(1) if m else out) + '\n')
    print(letter, 'revised', len((m.group(1) if m else out).split()), 'words', flush=True)
