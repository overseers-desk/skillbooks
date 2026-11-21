#!/usr/bin/env python3
"""Print a prompt and format as the skill ships them: one module file, its columns in the front matter
and the caller's slots left open. usage: module.py <prompt> <format>"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from run import ROOT, load

p, f = sys.argv[1:3]
fmeta, ftpl = load(f"{ROOT}/formats/{f}.md")
ids = [c.strip() for c in fmeta["criteria"][0].split(",")]
number = fmeta.get("numbering", ["{n}. "])[0]
crit = "\n".join(number.replace("{n}", str(i)) + load(f"{ROOT}/criteria/{c}.md")[1].strip() for i, c in enumerate(ids, 1))
columns = ", ".join(load(f"{ROOT}/criteria/{c}.md")[0]["offence"][0] for c in ids)
print(f"---\ncolumns: {columns}\n---\n" + load(f"{ROOT}/prompts/{p}.md")[1].replace("{format}", ftpl.replace("{criteria}", crit)))
