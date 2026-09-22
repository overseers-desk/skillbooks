#!/usr/bin/env python3
"""Split each design-A output into its first draft and its final message,
email only, as subject-and-body text files named by stem.
usage: split-a.py <drafts_a_dir> <first_out_dir> <final_out_dir>"""
import sys, os, glob, re
src, out1, out2 = sys.argv[1:4]
os.makedirs(out1, exist_ok=True); os.makedirs(out2, exist_ok=True)
def email_only(block):
    # keep from the first Subject: line to the end of the email; drop a phone
    # script or platform note that follows under its own heading
    m = re.search(r'^.*Subject:.*$', block, re.M)
    if not m: return None
    tail = block[m.start():]
    cut = re.search(r'\n\s*(#+\s*|\*\*)?(Phone|Platform|LinkedIn|SMS|Follow-up call|Call script)', tail, re.I)
    body = tail[:cut.start()] if cut else tail
    body = re.sub(r'^\s*#+\s*', '', body)             # a markdown heading before Subject
    body = re.sub(r'^\*\*Subject:\*\*', 'Subject:', body)
    return body.strip() + '\n'
n = 0
for f in sorted(glob.glob(os.path.join(src, '*.txt'))):
    stem = os.path.basename(f)[:-4]; t = open(f).read()
    a = re.search(r'FIRST_START\n(.*?)\nFIRST_END', t, re.S); b = re.search(r'DRAFT_START\n(.*?)\nDRAFT_END', t, re.S)
    if not (a and b): print(stem, 'markers missing'); continue
    e1, e2 = email_only(a.group(1)), email_only(b.group(1))
    if not (e1 and e2): print(stem, 'no Subject line'); continue
    open(os.path.join(out1, stem + '.txt'), 'w').write(e1); open(os.path.join(out2, stem + '.txt'), 'w').write(e2); n += 1
    print(stem, len(e1.split()), '->', len(e2.split()), 'words')
print(n, 'pairs')
