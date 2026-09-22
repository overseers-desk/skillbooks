#!/usr/bin/env python3
"""Fork each author session at the point before any rewrite prompt, so a
second writing can be asked of a session that holds only the original
drafting. Writes a copy of the transcript under a fresh id, ending at the
last assistant record before the first rewrite prompt, in the compact
serialisation the CLI's session lookup expects.
usage: fork-sessions.py <sessions.json> <config_dir> <out.json> <model>"""
import sys, os, json, glob, uuid
sess, cfg, outp, model = sys.argv[1:5]
S = json.load(open(sess)); out = {}
for name, v in S.items():
    src = glob.glob(os.path.join(cfg, 'projects', '*', v['session_id'] + '.jsonl'))[0]
    recs = [json.loads(l) for l in open(src) if l.strip()]
    cut = next((i for i, e in enumerate(recs) if e.get('type') == 'user'
                and 'Write the letter again for its reader' in json.dumps(e.get('message', {}).get('content'))), len(recs))
    last = max(i for i, r in enumerate(recs[:cut]) if r.get('type') == 'assistant'); end = last + 1
    while end < cut and recs[end].get('type') in ('system', 'last-prompt', 'cost-state'): end += 1
    new = str(uuid.uuid4()); dst = os.path.join(os.path.dirname(src), new + '.jsonl')
    with open(dst, 'w') as fh:
        for r in recs[:end]:
            if 'sessionId' in r: r['sessionId'] = new
            fh.write(json.dumps(r, separators=(',', ':'), ensure_ascii=False) + '\n')
    os.chmod(dst, 0o600); os.makedirs(os.path.join(os.path.dirname(src), new, 'tool-results'), exist_ok=True)
    out[name] = dict(v, session_id=new, forked_from=v['session_id'], model=model)
    print(name, v['session_id'][:8], '->', new[:8], end, 'of', len(recs), 'records')
json.dump(out, open(outp, 'w'), indent=1); print(len(out), 'forks')
