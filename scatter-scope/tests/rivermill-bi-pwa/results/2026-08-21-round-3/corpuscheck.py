import os,subprocess
R='/home/weiwu/code/rivermill-bi-pwa'
EXT=('.js','.mjs','.ts','.tsx','.jsx','.md','.json','.sql','.tcl','.tm','.css','.html','.yaml','.yml','.sh')
EXCL=['.git/','node_modules/','ds-bundle/','.ds-sync/','.design-sync/learnings/','.design-sync/.cache/','data/','dist/','tmp/','.claude/','.venv/','web/src/locales/','desktop/theme-design/','migration/walls/create.sql','migration/shell-auth/create.sql']
SKIP={'package-lock.json'}
corpus=set()
for dp,dirs,files in os.walk(R):
    rel=os.path.relpath(dp,R); rel='' if rel=='.' else rel+'/'
    if any(e in rel for e in EXCL): dirs[:]=[]; continue
    for fn in files:
        if fn.endswith(EXT) and fn not in SKIP:
            p=rel+fn
            if not any(e in p for e in EXCL): corpus.add(p)
tracked=set(subprocess.run(['git','-C',R,'ls-files'],capture_output=True,text=True).stdout.split())
print('corpus',len(corpus))
untracked=sorted(corpus-tracked)
print('in corpus but untracked:',len(untracked))
for u in untracked[:40]: print('  ',u)
missing=sorted(f for f in tracked-corpus if f.endswith(EXT))
print('tracked with corpus ext but excluded:',len(missing))
import collections
print(collections.Counter(m.split('/')[0]+'/'+(m.split('/')[1] if '/' in m else '') for m in missing))
