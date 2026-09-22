#!/usr/bin/env python3
"""Extract each approach file's final message (subject + body) to a plain-text
file under a random name, flat and shuffled, with the key written beside it.
usage: blind.py <out_dir> <arm_dir> [<arm_dir> ...]   (arm name = dir basename)"""
import sys,os,glob,random,json,yaml
out=sys.argv[1]; os.makedirs(out,exist_ok=True); key={}
random.seed(20260922)
files=[]
for d in sys.argv[2:]:
    arm=os.path.basename(d.rstrip('/'))
    for f in sorted(glob.glob(os.path.join(d,'*.yaml'))): files.append((arm,f))
random.shuffle(files)
def final_message(path):
    try: doc=yaml.safe_load(open(path))
    except Exception as e: return None,None,f'unparsed: {e.__class__.__name__}'
    rounds=doc.get('rounds') or []
    finals=[r for r in rounds if r.get('type')=='final'] or rounds
    if not finals: return None,None,'no rounds'
    msgs=(finals[-1].get('messages') or [])
    em=[m for m in msgs if m.get('channel')=='email']
    m=em[0] if em else (msgs[0] if msgs else None)
    if not m: return None,None,'no messages'
    body=m.get('body') or m.get('text') or ''
    if not body and m.get('script'):
        body='\n'.join(str(p.get('text','')) for p in m['script'])
    return (m.get('subject') or f"(no subject; channel {m.get('channel')})"), body, m.get('channel')
n=0
for arm,f in files:
    subj,body,ch=final_message(f)
    if body is None:
        key[os.path.basename(f)]={'arm':arm,'stem':os.path.basename(f)[:-5],'skipped':ch}; continue
    name=f"msg-{random.randrange(10**6):06d}.txt"
    open(os.path.join(out,name),'w').write(f"Subject: {subj}\n\n{body.strip()}\n")
    key[name]={'arm':arm,'stem':os.path.basename(f)[:-5],'channel':ch,'words':len(body.split())}
    n+=1
json.dump(key,open(os.path.join(out,os.pardir,'key.json'),'w'),indent=1)
print(n,'messages written;',len(key)-n,'skipped')
