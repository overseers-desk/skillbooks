#!/usr/bin/env python3
"""Merge the two SCIP JSON indexes onto repository-relative paths."""
import json, os
R='/home/weiwu/code/rivermill-bi-pwa'
docs={}
def norm(base, p):
    ap=os.path.normpath(os.path.join(base,p))
    return os.path.relpath(ap,R)
for name,base in (('web',R+'/web'),('server','/usr/local/ai/scope/round-3/servercfg')):
    d=json.load(open('idx/%s.json'%name))
    for doc in d['documents']:
        rp=norm(base,doc['relative_path'])
        if rp.startswith('..'):
            print('outside tree, dropped:',rp); continue
        if rp in docs:
            docs[rp]['occurrences'].extend(doc['occurrences'])
        else:
            docs[rp]={'relative_path':rp,'occurrences':doc['occurrences']}
json.dump({'documents':list(docs.values())},open('idx/index.json','w'))
print(len(docs),'documents merged')
