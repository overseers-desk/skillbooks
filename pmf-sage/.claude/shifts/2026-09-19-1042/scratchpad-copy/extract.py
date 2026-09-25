import os,re,sys,html
from html.parser import HTMLParser

class F(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.depth=0; self.out=[]; self.cur=None; self.stack=[]
        self.forms=[]
        self.skip=0
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag in ('script','style'): self.skip+=1; return
        if tag=='form':
            self.depth+=1
            if self.depth==1:
                self.cur=[]; self.cur.append(('FORMSTART',str(a.get('action','') or a.get('id','') or a.get('class',''))[:120]))
            return
        if self.depth>=1:
            if tag in ('input','textarea','select','button'):
                ph=a.get('placeholder'); ty=a.get('type','')
                bits=[]
                if ph: bits.append('placeholder="%s"'%ph)
                if a.get('value') and ty in ('submit','button'): bits.append('value="%s"'%a['value'])
                if a.get('aria-label'): bits.append('aria-label="%s"'%a['aria-label'])
                if a.get('title'): bits.append('title="%s"'%a['title'])
                self.cur.append(('<%s type=%s>'%(tag,ty),' '.join(bits)))
            elif tag=='option':
                self.cur.append(('<option>',''))
            elif tag=='label':
                self.cur.append(('<label>',''))
            elif tag=='iframe':
                self.cur.append(('<iframe>',a.get('src','')[:160]))
    def handle_endtag(self,tag):
        if tag in ('script','style'):
            if self.skip: self.skip-=1
            return
        if tag=='form':
            if self.depth==1 and self.cur is not None:
                self.forms.append(self.cur); self.cur=None
            if self.depth: self.depth-=1
    def handle_data(self,d):
        if self.skip: return
        if self.depth>=1 and self.cur is not None:
            t=' '.join(d.split())
            if t: self.cur.append(('TEXT',t))

def run(path):
    t=open(path,encoding='utf-8',errors='replace').read()
    p=F()
    try: p.feed(t)
    except Exception as e: print("PARSE ERR",e)
    for i,f in enumerate(p.forms):
        print("--- FORM %d in %s"%(i+1,path))
        for k,v in f:
            if k=='TEXT': print("   txt: %s"%v[:300])
            else: print("   %s %s"%(k,v[:300]))
        print()

for path in sys.argv[1:]:
    run(path)
