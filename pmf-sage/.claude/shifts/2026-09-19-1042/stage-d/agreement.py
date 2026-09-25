#!/usr/bin/env python3
"""Agreement between a first coding and a second, blind coding of the same units, column by column.
Tested: that the two codings of a sampled unit give the same value in each compared column, before any reconciliation.

Usage: agreement.py <first.tsv>[,<first.tsv>...] <second.tsv>[,<second.tsv>...] --columns <regex> [--keys <n>] [--out <merged.tsv>]
Each argument is one file, a comma-separated list or a glob. A later first-coding file replaces an earlier one's row for the same unit.
Every file's first column names the unit (a path's last component, without its extension, is the key); the header row names the columns.
--keys says how many leading columns key a row (default 1; a package row takes 2, an element row 3), compared without case.
--columns picks the columns compared, by a regular expression matched against the whole column name.
A cell is compared as a set: values separated by "; " in any order agree, and case, outer spaces and outer quotation marks are ignored.
Per column: units compared, raw agreement, Krippendorff's alpha (nominal, two coders; nan where neither coder varied), and each disagreeing pair (first>second) with its count.
--out writes the first coding's rows as one table, for the counts a findings file cites.
"""
import argparse, collections, glob, os, re, sys


def files(arg):
    out = []
    for part in arg.split(','):
        out += sorted(glob.glob(part)) or [part]
    return out


def load(paths, nkeys=1):
    rows, header = {}, None
    for path in paths:
        lines = open(path, encoding='utf-8', errors='replace').read().rstrip('\n').split('\n')
        hdr = lines[0].split('\t')
        header = header or hdr
        for line in lines[1:]:
            cells = line.split('\t')
            if not cells[0].strip():
                continue
            if len(cells) != len(hdr):
                sys.exit(f'{path}: a row of {len(cells)} cells under a header of {len(hdr)}: {cells[0]}')
            key = ' | '.join([os.path.splitext(os.path.basename(cells[0].strip()))[0]] + [c.strip(' "').lower() for c in cells[1:nkeys]])
            rows[key] = dict(zip(hdr[1:], (c.strip() for c in cells[1:])))
    return rows, header


def as_set(cell):
    return frozenset(v.strip(' "\'').lower() for v in cell.split(';') if v.strip(' "\''))


def show(value):
    return '+'.join(sorted(value)) or '(empty)'


ap = argparse.ArgumentParser()
ap.add_argument('first'); ap.add_argument('second'); ap.add_argument('--columns', required=True); ap.add_argument('--keys', type=int, default=1); ap.add_argument('--out')
a = ap.parse_args()
first, header = load(files(a.first), a.keys)
second, _ = load(files(a.second), a.keys)
if a.out:
    with open(a.out, 'w', encoding='utf-8') as fh:
        fh.write('\t'.join(header) + '\n')
        for unit in sorted(first):
            fh.write(unit.split(' | ')[0] + '\t' + '\t'.join(first[unit].get(c, '') for c in header[1:]) + '\n')
both = sorted(u for u in second if u in first)
print(f'{len(first)} units in the first coding, {len(second)} in the second, {len(both)} in both')
missing = sorted(u for u in second if u not in first)
if missing:
    print('in the second coding only:', '; '.join(missing))
only_first = sorted(u for u in first if u not in second) if a.keys > 1 else []
if only_first:
    print('in the first coding only:', '; '.join(only_first))
want = re.compile(a.columns)
for col in [c for c in header[1:] if want.fullmatch(c)]:
    pairs = [(as_set(first[u].get(col, '')), as_set(second[u].get(col, ''))) for u in both]
    n = len(pairs)
    agree = sum(1 for x, y in pairs if x == y)
    counts = collections.Counter(v for p in pairs for v in p)
    expected_apart = sum(counts[c] * counts[k] for c in counts for k in counts if c != k) / (2 * n * (2 * n - 1))
    alpha = 1 - ((n - agree) / n) / expected_apart if expected_apart else float('nan')
    apart = collections.Counter(f'{show(x)}>{show(y)}' for x, y in pairs if x != y)
    print(f'{col}\t{agree}/{n}\t{agree / n:.2f}\talpha {alpha:.2f}\t' + '  '.join(f'{k}: {v}' for k, v in apart.most_common()))
