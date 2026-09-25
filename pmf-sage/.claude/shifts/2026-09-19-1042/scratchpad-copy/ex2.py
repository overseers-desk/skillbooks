import os,re,sys,hashlib
from html.parser import HTMLParser
root="/usr/local/src/rivermill/product-development/weddings/2026-08-15-wedding-survey/4-collection/data/r1"

def parse(path):
    events=[]
    state={'d':0,'skip':0,'cur':None,'forms':[]}
    class P(HTMLParser):
        def handle_starttag(s,tag,attrs):
            a=dict(attrs)
            if tag in ('script','style','svg'): state['skip']+=1; return
            if tag=='form':
                state['d']+=1
                if state['d']==1: state['cur']=[('ID',a.get('action','') or a.get('id','') or a.get('class',''))]
                return
            if state['d']>=1 and state['cur'] is not None:
                if tag=='input':
                    ty=a.get('type','text')
                    if ty=='hidden': return
                    bits=[]
                    if a.get('placeholder'): bits.append('ph="%s"'%a['placeholder'])
                    if a.get('value') and ty in('submit','button'): bits.append('val="%s"'%a['value'])
                    if a.get('aria-label'): bits.append('aria="%s"'%a['aria-label'])
                    state['cur'].append(('IN:'+ty,' '.join(bits)))
                elif tag in ('textarea','select','button'):
                    bits=[]
                    if a.get('placeholder'): bits.append('ph="%s"'%a['placeholder'])
                    if a.get('aria-label'): bits.append('aria="%s"'%a['aria-label'])
                    state['cur'].append((tag.upper(),' '.join(bits)))
                elif tag=='option': state['cur'].append(('OPT',''))
                elif tag=='label': state['cur'].append(('LBL',''))
                elif tag=='iframe': state['cur'].append(('IFRAME',a.get('src','')[:150]))
        def handle_endtag(s,tag):
            if tag in ('script','style','svg'):
                if state['skip']: state['skip']-=1
                return
            if tag=='form':
                if state['d']==1 and state['cur'] is not None:
                    state['forms'].append(state['cur']); state['cur']=None
                if state['d']: state['d']-=1
        def handle_data(s,d):
            if state['skip'] or state['d']<1 or state['cur'] is None: return
            t=' '.join(d.split())
            if t: state['cur'].append(('T',t))
    p=P(convert_charrefs=True)
    try: p.feed(open(path,encoding='utf-8',errors='replace').read())
    except Exception: pass
    return state['forms']

def render(f):
    out=[]
    for k,v in f:
        if k=='T': out.append('t: '+v)
        elif k=='ID': out.append('FORM['+v[:80]+']')
        else: out.append(k+(' '+v if v else ''))
    return out

def sig(f):
    return hashlib.md5('|'.join(render(f)[1:]).encode()).hexdigest()

venues=sys.argv[1:]
for venue in venues:
    vd=os.path.join(root,venue)
    seen={}
    for fn in sorted(os.listdir(vd)):
        if not fn.endswith(('.html','.htm')): continue
        for f in parse(os.path.join(vd,fn)):
            s=sig(f)
            seen.setdefault(s,{'pages':[],'body':render(f)})
            seen[s]['pages'].append(fn)
    print("="*70); print("VENUE:",venue)
    for s,v in seen.items():
        print("\n  ## pages: %s"%(', '.join(v['pages'][:6])+(' (+%d more)'%(len(v['pages'])-6) if len(v['pages'])>6 else '')))
        prev=None; run=0
        for line in v['body']:
            print("     "+line[:200])
