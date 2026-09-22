#!/usr/bin/env python3
"""Put the scored numbers into ab-evaluation.html: the arms' data block,
the phrase counts, the examples and the verdict lines.
usage: fill-page.py <page.html> <data.json> [<data.json> ...]"""
import sys, json, re, glob, os
page = sys.argv[1]; arms = []; cols = None
for f in sys.argv[2:]:
    d = json.load(open(f)); cols = d['cols']; arms += d['arms']
notsale = re.compile(r"(not (on sale|advertised|available|being sold|public|listed)|aren'?t (on sale|advertised|available)|never (went|go) on sale|not on public sale|no public sale|not sold anywhere)", re.I)
sel = re.compile(r"held in your name|picked|hand[- ]?picked|chose|chosen|select|set aside|reserved|yours is one|one of them|a short list|a handful|a few local|a few publications|a few organisations|offering (?:them|these) to|on that list", re.I)
def count(d, names=None):
    fs = sorted(glob.glob(d + '/*.txt')); fs = [f for f in fs if names is None or os.path.basename(f) in names]
    t = [open(f).read() for f in fs]
    return {'n': len(t), 'notsale': sum(bool(notsale.search(x)) for x in t), 'sel': sum(bool(sel.search(x)) for x in t)}
bnames = {os.path.basename(f) for f in glob.glob('rewrites-author-fork-clean/*.txt')}
lex = [dict(name='A first, Opus 5', **count('drafts-a-o5-first')), dict(name='A final, Opus 5', **count('drafts-a-o5-final')),
       dict(name='B before, Opus 5', **count('originals-b', bnames)), dict(name='B after, Opus 5', **count('rewrites-author-fork-clean'))]
if os.path.isdir('sel55'):
    lex += [dict(name='A first, 5.5', **count('sel55/a55-first')), dict(name='A final, 5.5', **count('sel55/a55-final')),
            dict(name='B before, 5.5', **count('sel55/orig')), dict(name='B after, 5.5', **count('sel55/b55'))]
cols = [c for c in cols if c[0] not in ('false', 'unsup')]   # the claim counts belong to the brief's truth, kept in the repository
data = {'cols': cols, 'arms': arms, 'lex': lex,
        'lexcols': [['n', 'letters'], ['notsale', '"not on sale" or "not advertised"'], ['sel', '"picked", "set aside", "a handful", "on that list"']],
        'examples': [
          {'text': 'The final draft keeps every sentence of the first, moves the show title into the opening line, and adds the street address to the sender\'s introduction.', 'who': 'Design A, a retirement village, first draft against final.'},
          {'text': 'There is nothing to pay and nothing to buy. What I need from you is a rough number. The number commits the shed to nothing, and there is nobody to organise.', 'who': 'Design B, the same shed: three sentences the second writing added. Nothing was removed.'}],
        'evidence': {}, 'pill': {}}
def ev(a):
    s = a['pairs']['sender']; w = a['pairs']['words']; n = a['pairs']['nowhere']
    return f"Sender-side sentences better in {s[0]}, same in {s[1]}, worse in {s[2]}; unresolved references {n[0]} / {n[1]} / {n[2]}; longer in {w[2]} of {a['n']}."
for a in arms:
    k = 'A' if a['name'].startswith('Design A') else 'B'
    if '5.5' not in a['name']:
        data['evidence'][k] = ev(a); data['pill'][k] = 'no improvement'
t = open(page).read()
t = re.sub(r'const DATA = .*?;\n', 'const DATA = ' + json.dumps(data) + ';\n', t, count=1, flags=re.S)
open(page, 'w').write(t); print('page filled with', len(arms), 'arms')
