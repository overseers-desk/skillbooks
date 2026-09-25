import re,sys,html,os
def txt(s):
    s=re.sub(r'<[^>]+>',' ',s)
    s=html.unescape(s)
    return re.sub(r'\s+',' ',s).strip()
for path in sys.argv[1:]:
    src=open(path,encoding='utf-8',errors='replace').read()
    out=[]
    # document-order scan of interesting tokens
    pat=re.compile(r'(<label\b[^>]*>.*?</label>)|(<option\b[^>]*>.*?</option>)|(<textarea\b[^>]*>)|(<input\b[^>]*>)|(<select\b[^>]*>)|(</select>)|(<form\b[^>]*>)|(</form>)|(<h[1-6]\b[^>]*>.*?</h[1-6]>)|(<legend\b[^>]*>.*?</legend>)',re.S|re.I)
    for m in pat.finditer(src):
        g=m.group(0)
        low=g.lower()
        if low.startswith('<label'):
            t=txt(g)
            if t: out.append('LABEL: '+t)
        elif low.startswith('<option'):
            t=txt(g)
            out.append('  OPTION: '+t)
        elif low.startswith('<select'):
            ph=re.search(r'placeholder=["\']([^"\']*)',g,re.I)
            out.append('SELECT'+(' ph='+ph.group(1) if ph else ''))
        elif low.startswith('</select>'):
            out.append('/SELECT')
        elif low.startswith('<textarea'):
            ph=re.search(r'placeholder=["\']([^"\']*)',g,re.I)
            ar=re.search(r'aria-label=["\']([^"\']*)',g,re.I)
            out.append('TEXTAREA ph=%s aria=%s'%(ph.group(1) if ph else '-',ar.group(1) if ar else '-'))
        elif low.startswith('<input'):
            ty=re.search(r'\btype=["\']?([\w-]+)',g,re.I)
            ph=re.search(r'placeholder=["\']([^"\']*)',g,re.I)
            ar=re.search(r'aria-label=["\']([^"\']*)',g,re.I)
            va=re.search(r'\bvalue=["\']([^"\']*)',g,re.I)
            t=(ty.group(1) if ty else 'text').lower()
            if t in ('hidden',): continue
            out.append('INPUT[%s] ph=%s aria=%s val=%s'%(t,ph.group(1) if ph else '-',ar.group(1) if ar else '-',va.group(1) if va else '-'))
        elif low.startswith('<form'):
            out.append('=== FORM START ===')
        elif low.startswith('</form>'):
            out.append('=== FORM END ===')
        elif low.startswith('<legend'):
            out.append('LEGEND: '+txt(g))
        else:
            t=txt(g)
            if t: out.append('[h] '+t[:120])
    if out:
        print('##### '+path)
        for l in out: print(l)
