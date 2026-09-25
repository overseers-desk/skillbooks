#!/usr/bin/env python3
"""Re-fetch the pages a set of profiles say they were read from, as raw files and as text, into a folder outside git.
Tested: nothing is judged here; the log says, page by page, what came back.

Usage: refetch-pages.py <shard.txt>[,<shard.txt>...] <profiles-base-dir> <out-dir> [--whole]
A shard file lists profile paths, one a line, relative to <profiles-base-dir>. A profile's pages are the addresses in its
front matter or its capture record (everything above its second "## " heading), or anywhere in it with --whole, for a profile that holds several listings. Each profile gets a folder named after its
file, holding NN.raw and NN.txt in the order the addresses appear, and <out-dir>/fetch-log.tsv records address, status and text length.
"""
import datetime, os, re, subprocess, sys

shards, base, out = sys.argv[1].split(','), sys.argv[2], sys.argv[3]
UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36'
today = datetime.date.today().isoformat()
os.makedirs(out, exist_ok=True)
log = open(os.path.join(out, 'fetch-log.tsv'), 'a')
for shard in shards:
    for rel in (l.strip() for l in open(shard) if l.strip()):
        text = open(os.path.join(base, rel)).read()
        head = text if '--whole' in sys.argv else '## '.join(text.split('\n## ')[:2])
        urls = []
        for u in re.findall(r'https?://[^\s"\'<>|)\]]+', head):
            u = u.rstrip('.,;`')
            if u not in urls:
                urls.append(u)
        folder = os.path.join(out, os.path.basename(rel)[:-3])
        os.makedirs(folder, exist_ok=True)
        for i, url in enumerate(urls, 1):
            raw, txt = f'{folder}/{i:02d}.raw', f'{folder}/{i:02d}.txt'
            r = subprocess.run(['curl', '-sL', '-A', UA, '--max-time', '40', '-o', raw, '-w', '%{http_code} %{content_type}', url],
                               capture_output=True, text=True)
            code, _, ctype = r.stdout.partition(' ')
            body = ''
            if os.path.exists(raw):
                if 'pdf' in ctype or open(raw, 'rb').read(5) == b'%PDF-':
                    body = subprocess.run(['pdftotext', '-layout', raw, '-'], capture_output=True, text=True, errors='replace').stdout
                else:
                    body = subprocess.run(['w3m', '-dump', '-T', 'text/html', '-cols', '200', raw], capture_output=True, text=True, errors='replace').stdout
            open(txt, 'w').write(f'SOURCE: {url}\nFETCHED: {today}, http {code}\n\n{body}')
            log.write(f'{os.path.basename(rel)}\t{i}\t{url}\t{code}\t{len(body)}\n'); log.flush()
