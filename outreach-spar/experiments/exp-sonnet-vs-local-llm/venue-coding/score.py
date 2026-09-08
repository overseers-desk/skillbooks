#!/usr/bin/env python3
# Scores engine outputs against gold.tsv. Two parsers: Sonnet #TABLE fragments, and the
# local models' loose line formats (facts questionnaire or FIELD\tENTITY\tVALUE\tQUOTE).
import sys, re, csv, pathlib, json

base = pathlib.Path(__file__).parent
gold = {r['venue_key']: r for r in csv.DictReader(open(base/'gold.tsv'), delimiter='\t')}

def parse_fragment(path):
    out = {'V6': set(), 'V4': set(), 'V21': set(), 'V22': set(), 'V9_deposit': '0',
           'offers': 0, 'pcrs': 0, 'amounts': 0}
    table = None
    for line in open(path, errors='replace'):
        line = line.rstrip('\n')
        if line.startswith('#TABLE '):
            table = line.split()[1]; continue
        if not line or line.startswith('venue_key\t'):
            continue
        f = line.split('\t')
        if table == 'offers': out['offers'] += 1
        elif table == 'pcrs': out['pcrs'] += 1
        elif table == 'amounts': out['amounts'] += 1
        elif table == 'codes' and len(f) >= 6:
            field, value = f[4], f[5]
            if field in ('V6_value', 'V6'): out['V6'].add(value)
            if field in ('V4_max_band', 'V4'): out['V4'].add(value)
            if field.startswith('V21_') and value == '1': out['V21'].add(field[4:])
            if field.startswith('V22_') and value == '1': out['V22'].add(field[4:])
            if field == 'V9_deposit' and value == '1': out['V9_deposit'] = '1'
    return out

def parse_loose(paths):
    text = '\n'.join(open(p, errors='replace').read() for p in paths if p.exists())
    out = {'V6': set(), 'V4': set(), 'V21': set(), 'V22': set(), 'V9_deposit': '0',
           'offers': 0, 'pcrs': None, 'amounts': 0}
    m = re.findall(r'V6_value\t(\d)', text) + re.findall(r'^V6\t\S*\t(\d)', text, re.M)
    out['V6'] = set(m)
    m = re.findall(r'V4_max_band\t(?:\S*\t)?(\d)', text)
    out['V4'] = set(m)
    out['amounts'] = len(re.findall(r'(?:^|\t)AMOUNT\t', text, re.M))
    m = re.search(r'V21_routes\t([a-z_,\s]+)', text)
    if m: out['V21'] = {t.strip() for t in m.group(1).split(',') if t.strip() and 'none' not in t}
    m = re.search(r'V22_tour\t([a-z_ ]+)', text)
    if m and 'not stated' not in m.group(1): out['V22'] = {m.group(1).strip()}
    if re.search(r'V9_deposit\t1', text): out['V9_deposit'] = '1'
    for fld in re.findall(r'(V2[12]_[a-z_]+)\t[^\t]*\t?1', text):
        (out['V21'] if fld.startswith('V21') else out['V22']).add(fld[4:])
    offers = set()
    for m in re.finditer(r'OFFER\t([^\t\n]+)', text):
        offers.update(x.strip() for x in m.group(1).split(',') if x.strip())
    out['offers'] = len(offers)
    return out

ROUTE_MAP = {'form': 'enquiry_form', 'pack_request': 'pack_request', 'email': 'email',
             'phone': 'phone', 'online_booking': 'calendar_shown', 'by_appointment': 'tour_by_appointment'}

def score(venue, got):
    g = gold[venue]
    gv21 = set(g['V21_routes'].split(',')) - {'-'}
    gv22 = set(g['V22_fields'].split(',')) - {'-'}
    ev21 = {ROUTE_MAP.get(x, x) for x in got['V21']}
    ev22 = {ROUTE_MAP.get(x, x) for x in got['V22']}
    v6_ok = g['V6'] in got['V6'] and len(got['V6']) <= 2
    v4_ok = g['V4_max_band'] in got['V4'] if got['V4'] else g['V4_max_band'] == '0'
    return {'venue': venue,
            'V6': 'ok' if v6_ok else f"got {sorted(got['V6'])} want {g['V6']}",
            'V4': 'ok' if v4_ok else f"got {sorted(got['V4'])} want {g['V4_max_band']}",
            'offers': f"{got['offers']}/{g['offer_row_count']}",
            'amounts': f"{got['amounts']}/{g['amount_count']}",
            'V21_jacc': round(len(gv21 & ev21) / max(1, len(gv21 | ev21)), 2),
            'V22_jacc': round(len(gv22 & ev22) / max(1, len(gv22 | ev22)), 2),
            'V9_dep': 'ok' if got['V9_deposit'] == g['V9_deposit'] else 'X'}

mode, engine = sys.argv[1], sys.argv[2]
rows = []
for venue in gold:
    if mode == 'fragment':
        p = base/'sonnet'/f'{venue}.tsv'
        if not p.exists(): continue
        rows.append(score(venue, parse_fragment(p)))
    else:
        paths = [base/'responses'/engine/f'{venue}.{g}.out' for g in
                 (['facts'] if mode == 'facts' else ['price', 'money', 'offer', 'routes'])]
        if not any(p.exists() for p in paths): continue
        rows.append(score(venue, parse_loose(paths)))
print(json.dumps(rows, indent=1))
