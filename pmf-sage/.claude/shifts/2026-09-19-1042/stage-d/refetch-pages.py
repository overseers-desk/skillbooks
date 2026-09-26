#!/usr/bin/env python3
"""Re-fetch the pages a set of profiles say they were read from, into a batch corpus/ folder.
Tested: nothing is judged here; the log says, page by page, what came back.

Usage: refetch-pages.py <shard.txt>[,<shard.txt>...] <profiles-base-dir> <corpus-dir> [--whole]
A shard file lists profile paths, one a line, relative to <profiles-base-dir>. A profile's pages are the addresses in its
front matter or its capture record (everything above its second "## " heading), or anywhere in it with --whole, for a profile that holds several listings. Each profile is a unit named after its file (without .md).
Raw fetches land at <corpus-dir>/raw/<date>/<unit>/NN.<ext>. Extracted pages become members <unit>/NN.md of
<corpus-dir>/<date>-pages.tar.zst, each with front matter url, fetched, http, raw, then the extracted text; a page whose
fetch yielded no text gets a fetch-log row but no member. <corpus-dir>/<date>-fetch-log.tsv gets one header row (unit, NN,
url, http, bytes, sha256, raw, former_path, archived) and then one row per page, as bin/corpus-grep describes.
"""
import datetime, hashlib, os, re, shutil, subprocess, sys, tempfile

shards, base, corpus = sys.argv[1].split(','), sys.argv[2], sys.argv[3]
UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36'
today = datetime.date.today().isoformat()

raw_root = os.path.join(corpus, 'raw', today)
os.makedirs(raw_root, exist_ok=True)
stage = tempfile.mkdtemp()
members = []

log_path = os.path.join(corpus, f'{today}-fetch-log.tsv')
log_is_new = not os.path.exists(log_path)
log = open(log_path, 'a')
if log_is_new:
    log.write('unit\tNN\turl\thttp\tbytes\tsha256\traw\tformer_path\tarchived\n')

for shard in shards:
    for rel in (l.strip() for l in open(shard) if l.strip()):
        text = open(os.path.join(base, rel)).read()
        head = text if '--whole' in sys.argv else '## '.join(text.split('\n## ')[:2])
        urls = []
        for u in re.findall(r'https?://[^\s"\'<>|)\]]+', head):
            u = u.rstrip('.,;`')
            if u not in urls:
                urls.append(u)
        unit = os.path.basename(rel)[:-3]
        unit_raw_dir = os.path.join(raw_root, unit)
        unit_stage_dir = os.path.join(stage, unit)
        os.makedirs(unit_raw_dir, exist_ok=True)
        os.makedirs(unit_stage_dir, exist_ok=True)
        for i, url in enumerate(urls, 1):
            nn = f'{i:02d}'
            tmp = f'{unit_raw_dir}/{nn}.tmp'
            r = subprocess.run(['curl', '-sL', '-A', UA, '--max-time', '40', '-o', tmp, '-w', '%{http_code} %{content_type}', url],
                               capture_output=True, text=True)
            code, _, ctype = r.stdout.partition(' ')
            body, raw_rel = '', ''
            if os.path.exists(tmp):
                is_pdf = 'pdf' in ctype or open(tmp, 'rb').read(5) == b'%PDF-'
                subtype = ctype.split(';')[0].split('/')[-1] if '/' in ctype else ''
                ext = 'pdf' if is_pdf else (subtype or 'html')
                if is_pdf:
                    body = subprocess.run(['pdftotext', '-layout', tmp, '-'], capture_output=True, text=True, errors='replace').stdout
                else:
                    body = subprocess.run(['w3m', '-dump', '-T', 'text/html', '-cols', '200', tmp], capture_output=True, text=True, errors='replace').stdout
                raw_final = f'{unit_raw_dir}/{nn}.{ext}'
                os.rename(tmp, raw_final)
                raw_rel = f'raw/{today}/{unit}/{nn}.{ext}'
            if body:
                front = f'---\nurl: "{url}"\nfetched: "{today}"\nhttp: "{code}"\nraw: "{raw_rel}"\n---\n\n'
                open(f'{unit_stage_dir}/{nn}.md', 'w').write(front + body)
                members.append(f'{unit}/{nn}.md')
            bbytes = body.encode()
            log.write(f'{unit}\t{nn}\t{url}\t{code}\t{len(bbytes)}\t{hashlib.sha256(bbytes).hexdigest()}\t{raw_rel}\t\t\n')
            log.flush()

log.close()

if members:
    tarbin = shutil.which('gtar') or shutil.which('tar')
    archive = os.path.join(corpus, f'{today}-pages.tar.zst')
    subprocess.run([tarbin, '--zstd', '-cf', archive, '-C', stage] + members, check=True)
shutil.rmtree(stage, ignore_errors=True)
