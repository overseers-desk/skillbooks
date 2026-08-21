#!/usr/bin/env python3
"""Decode a SCIP protobuf index to the JSON shape scope-count.py reads, without the scip CLI.

Usage: scip2json.py index.scip index.json
"""
import sys, json

def varint(b, i):
    r = 0; s = 0
    while True:
        x = b[i]; i += 1
        r |= (x & 0x7f) << s
        if not x & 0x80: return r, i
        s += 7

def fields(b):
    i = 0; n = len(b)
    while i < n:
        k, i = varint(b, i)
        f, w = k >> 3, k & 7
        if w == 0:
            v, i = varint(b, i); yield f, 0, v
        elif w == 2:
            ln, i = varint(b, i); yield f, 2, b[i:i+ln]; i += ln
        elif w == 5: yield f, 5, b[i:i+4]; i += 4
        elif w == 1: yield f, 1, b[i:i+8]; i += 8
        else: raise ValueError("wire %d" % w)

def zz(v):  # int32 in proto3 non-sint is plain varint (two's complement)
    return v - (1 << 64) if v >= (1 << 63) else v

data = open(sys.argv[1], 'rb').read()
docs = []
for f, w, v in fields(data):
    if f != 2: continue
    path = None; occ = []
    for df, dw, dv in fields(v):
        if df == 1 and dw == 2: path = dv.decode('utf8', 'replace')
        elif df == 2 and dw == 2:
            sym = None; roles = 0
            for of, ow, ov in fields(dv):
                if of == 2 and ow == 2: sym = ov.decode('utf8', 'replace')
                elif of == 3 and ow == 0: roles = zz(ov)
            if sym: occ.append({"symbol": sym, "symbol_roles": roles})
    if path is not None: docs.append({"relative_path": path, "occurrences": occ})
json.dump({"documents": docs}, open(sys.argv[2], 'w'))
print(len(docs), "documents", file=sys.stderr)
