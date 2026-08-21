#!/usr/bin/env python3
"""SCOPE Pick: blind estimates against the measured table.

Inputs: the JSON scope-count.py wrote, and one file per estimator reply holding lines of the
form `path | A | B | C` or `path | A | B | C | D` (extra table decoration tolerated). Per
module the tool takes the median estimate per figure and the gap log3(measured / expected).

Flags: A outside the band either way (fewer consumers than expected is a real signal, since A
is exact); B above the band only (below the band is the vocabulary floor, not hiding); D above
the band only (a hub). C never flags; it is printed as density. The calibration summary at
the end is the per-run check the methodology asks for.

Usage: scope-pick.py --measured measured.json --out-dir <run folder> reply1.md reply2.md ...
"""
import argparse
import json
import math
import os
import re
import statistics

ROW = re.compile(r"^\s*\|?\s*`?([^\s|`]+\.[A-Za-z0-9]+)`?\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*(?:\|\s*(\d+)\s*)?\|?\s*$")


def gap(meas, exp):
    return math.log(max(meas, 0.5) / max(exp, 0.5), 3)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--measured", required=True)
    ap.add_argument("--out-dir", required=True)
    ap.add_argument("--band", type=float, default=1.0, help="flag beyond this many log3 units (1 = a factor of three)")
    ap.add_argument("replies", nargs="+")
    a = ap.parse_args()

    data = json.load(open(a.measured))
    modules = {r["file"]: r for r in data["modules"]}
    est = {}
    for p in a.replies:
        for line in open(p, errors="ignore"):
            m = ROW.match(line)
            if not m:
                continue
            f = m.group(1)
            key = f if f in modules else next((k for k in modules if k.endswith("/" + f) or k.endswith(f)), None)
            if key is None:
                continue
            e = est.setdefault(key, {"A": [], "B": [], "C": [], "D": []})
            e["A"].append(int(m.group(2))); e["B"].append(int(m.group(3))); e["C"].append(int(m.group(4)))
            if m.group(5) is not None:
                e["D"].append(int(m.group(5)))

    rows = []
    for f, e in est.items():
        r = modules[f]
        med = {k: statistics.median(v) for k, v in e.items() if v}
        if not {"A", "B"} <= set(med):
            continue
        gA, gB, gC = gap(r["A"], med["A"]), gap(r["B"], med["B"]), gap(r["C"], med.get("C", 0))
        gD = gap(r["D"], med["D"]) if "D" in med else None
        flags = []
        if gA > a.band: flags.append("A high")
        if gA < -a.band: flags.append("A low")
        if gB > a.band and not r.get("note"): flags.append("B high")
        if gD is not None and gD > a.band: flags.append("D high (hub)")
        if r["A"] < med["A"] and gB > a.band: flags.append("leak signature")
        rows.append(dict(file=f, A=r["A"], eA=med["A"], gA=round(gA, 2), B=r["B"], eB=med["B"], gB=round(gB, 2),
                         C=r["C"], eC=med.get("C"), gC=round(gC, 2), D=r["D"], eD=med.get("D"),
                         gD=None if gD is None else round(gD, 2), leak=r["leak"], note=r.get("note", ""),
                         flags=", ".join(flags), estimators=len(e["A"])))
    rows.sort(key=lambda r: -(abs(r["gA"]) + max(r["gB"], 0) + max(r["gD"] or 0, 0)))

    os.makedirs(a.out_dir, exist_ok=True)
    json.dump(rows, open(os.path.join(a.out_dir, "pick.json"), "w"), indent=1)
    with open(os.path.join(a.out_dir, "pick-table.md"), "w") as fh:
        fh.write("| module | A exp/meas | B exp/meas | D exp/meas | C exp/meas | gap A | gap B | gap D | flags | disposition |\n|---|---|---|---|---|---|---|---|---|---|\n")
        for r in rows:
            d = f"{r['eD']}/{r['D']}" if r["eD"] is not None else f"-/{r['D']}"
            fh.write(f"| `{r['file']}` | {r['eA']}/{r['A']} | {r['eB']}/{r['B']} | {d} | {r['eC']}/{r['C']} | {r['gA']:+.2f} | {r['gB']:+.2f} | {'' if r['gD'] is None else f'{r['gD']:+.2f}'} | {r['flags']} |  |\n")

    n = len(rows)
    print(f"modules with estimates: {n}; flagged: {sum(1 for r in rows if r['flags'])}")
    for k in ("A", "B", "C", "D"):
        gs = [r["g" + k] for r in rows if r.get("g" + k) is not None]
        if gs:
            inside = sum(1 for g in gs if abs(g) <= a.band)
            print(f"  {k}: inside band {inside}/{len(gs)} ({100 * inside // len(gs)}%), median gap {statistics.median(gs):+.2f} log3 (x{3 ** statistics.median(gs):.1f})")
    print(f"wrote {a.out_dir}/pick.json and pick-table.md (disposition column empty, for Explain to fill)")


if __name__ == "__main__":
    main()
