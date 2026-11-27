#!/usr/bin/env python3
"""Round 2 variants of the HIRE method. Each is the released text with one named set of replacements.

The released text is sales-hire/hire-methodology.md as of commit 323012ca, read from git so that later changes to the
method do not move it. Run from the repository root:
    python3 labs/sales-hire/round-2/make-variants.py
It writes one file per variant into labs/sales-hire/round-2/variants/. A variant that names a module expects the
files of labs/sales-hire/round-2/modules/ beside the method's own modules.
"""
import os, subprocess
HERE=os.path.dirname(os.path.abspath(__file__))
RELEASED='323012ca'
base=subprocess.run(['git','show',RELEASED+':sales-hire/hire-methodology.md'],check=True,capture_output=True,text=True,cwd=HERE).stdout
def rep(s,a,b):
    assert s.count(a)==1, a[:60]
    return s.replace(a,b)
HOLES_END="ask what goes wrong for this employer while the post stays empty."
TOP="Whatever is chosen, the top of the page shows the candidate filling the first holes, in the employer's order and a clause to each, before it turns to what the candidate finds most interesting in the record: a reader who stops there has seen the post answered."
READER_END="afterwards it says, for each, where the page shows the candidate doing it, or that it does not."
JUDGES_END="- Judges do not hear dryness, and they prefer the advertisement's own words and the cadence of machine-written prose."
FIRST_LINES="Whatever is chosen, the first lines of the page answer the first thing this reader has to know of any applicant, as `brief.md` gives it, with the largest the record holds for it, told as a referee would tell it. The top then shows the candidate filling the first holes, in the employer's order and a clause to each, before it turns to what the candidate finds most interesting in the record: a reader who stops there has seen the post answered."
def leads(s):
    s=rep(s,HOLES_END,HOLES_END+" Above the list, write the first thing this reader has to know of any applicant before the rest of a page matters to them, such as whether the person has led at this size, with where you read it.")
    s=rep(s,TOP,FIRST_LINES)
    s=rep(s,READER_END,READER_END+" It is also given the question in `modules/first-thing.md`. Where it answers that the first lines did not tell it what it first had to know, they are written again from what the record holds for that, and the page is read whole again.")
    return s
def stays_out(s):
    s=leads(s)
    s=rep(s,FIRST_LINES,FIRST_LINES+" What this reader has no use for in choosing whom to speak to, such as the trade of a post in another field or the case for work the advertisement does not ask about, stays out of the top and stands in the entry it belongs to.")
    s=rep(s,"and the page is read whole again.","and the page is read whole again. It is given `modules/top-no-use.md` as well. A line it had no use for moves to the entry it belongs to, or is said again as the answer to something this reader asks; nothing leaves the page by this.")
    return s
def several(s):
    return rep(s,JUDGES_END,JUDGES_END+"\n\nWhere a post is worth more than one attempt, the page is written afresh several times, each time from an empty folder by an agent that sees none of the other attempts, and each attempt is taken through checks 1 to 4. The judges then choose among the finished pages, every pair of them in both orders, and the page that wins the most pairs is the one sent. The register records the choice and its margin.")
variants={'v9-leads':leads,'v10-leads-stays-out':stays_out,'v11-several':several}
os.makedirs(os.path.join(HERE,'variants'),exist_ok=True)
for name,fn in variants.items():
    text=fn(base)
    open(os.path.join(HERE,'variants',name+'.md'),'w').write(text)
    print(name,len(text)-len(base),'characters added')
