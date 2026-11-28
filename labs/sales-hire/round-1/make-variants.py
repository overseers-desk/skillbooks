#!/usr/bin/env python3
"""Round 1 variants of the HIRE method. Each is the baseline text with one named set of replacements.

Baseline: sales-hire/hire-methodology.md as of commit e51412d3, read from git so that later changes to the method do not
move it. Run from the repository root:
    python3 labs/sales-hire/round-1/make-variants.py
It writes one file per variant into labs/sales-hire/round-1/variants/. h1-edit.md and h1-rewrite.md are the whole text
reworded, the first by an editor and the second by a rewrite; neither is a set of replacements and neither is made here.
v9-leads, v10-leads-stays-out, v11-several, v12-body, v13-first-post and v14-outside-trace are replacements on v7-holes2, the text put into the method at 323012ca. A
variant that names a module expects the files of labs/sales-hire/round-1/modules/ beside the method's own modules.
"""
import os, subprocess
HERE=os.path.dirname(os.path.abspath(__file__))
BASELINE='e51412d3'
base=subprocess.run(['git','show',BASELINE+':sales-hire/hire-methodology.md'],check=True,capture_output=True,text=True,cwd=HERE).stdout
def rep(s,a,b):
    assert s.count(a)==1, a[:60]
    return s.replace(a,b)
def holes2(s):
    s=rep(s,"\n\nAn inference in `brief.md` is an assumption","\n\nThen list the holes. A buyer of a drill wants a hole in the wall, and an employer filling a post wants things done that nobody there is doing. From the advertisement and what the employer has published, write them in `brief.md`, numbered in the order the employer would put them, each with where you read it. The advertisement's list of duties is the drill; ask what goes wrong for this employer while the post stays empty.\n\nAn inference in `brief.md` is an assumption")
    s=rep(s,"Whatever is chosen, the opening answers the first question this reader has about any applicant for the post, such as whether the person has led at this size or has a direction of their own, before it turns to what the candidate finds most interesting in the record.","Whatever is chosen, the top of the page shows the candidate filling the first holes, in the employer's order and a clause to each, before it turns to what the candidate finds most interesting in the record: a reader who stops there has seen the post answered.")
    s=rep(s,"so the candidate can see what was left out and why (`cases/a-true-detail-kept-because-it-was-known.md`).","so the candidate can see what was left out and why (`cases/a-true-detail-kept-because-it-was-known.md`). Set against each hole the most concrete thing the record holds for it: the rule the candidate set, the system built, the figure, named as someone doing that work would name it. Gather all the record holds for a hole before choosing. A hole answered only in general terms is still open, and where the record has nothing, the question goes to the candidate in the register and names the hole.")
    s=rep(s,"what it now repeats, what it now contradicts","what it now repeats, what it now contradicts, and whether the page still speaks of the candidate in one person")
    s=rep(s,"whoever ran it saves both.","whoever ran it saves both. Enter each change to the page in `examine.md` with the number of the hole it serves, meaning the page now shows more plainly that the candidate fills it. A change that serves no hole puts something right, and is entered as `check`.")
    s=rep(s,"This is the check that finds grain and inherited sentences, and it costs one call.","This is the check that finds grain and inherited sentences, and it costs one call. Before it opens the page, it lists from the advertisement alone what this employer most needs done; afterwards it says, for each, where the page shows the candidate doing it, or that it does not.")
    s=rep(s,"Then say plainly what remains: the rows left standing and why,","Then say plainly what remains: how many changes served each hole and how many were `check`, the rows left standing and why,")
    return s
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
def body(s):
    s=rep(s,'Gather all the record holds for a hole before choosing. A hole answered only in general terms is still open',"Gather all the record holds for a hole before choosing. Under each post, below the top, what the post holds for one hole goes in one line; the lines follow the holes' order, and each opens on the employer's own term for its hole and gives what is set against it before anything that explains it. Whether that term stands as a label is read from the candidate file's rulings and defaults on form. A hole answered only in general terms, or only at the top, is still open")
    s=rep(s,'A document states what was established, at what scale, and what the candidate is working on.',"A document states what was established, at what scale, and what the candidate is working on. Each entry carries what the record holds of the candidate's standing: who backed the work, whom it was done for, and the size of what the candidate ran (the people led and the layers under them, budgets, users, money moved, organisations served), each named and sized as the record states it, unless its `include` keeps it off.")
    s=rep(s,'Check each against must-not-conclude (`cases/a-tense-or-a-date-that-says-the-candidate-is-not-free.md`, `cases/a-true-detail-kept-because-it-was-known.md`).',"Check each against must-not-conclude (`cases/a-tense-or-a-date-that-says-the-candidate-is-not-free.md`, `cases/a-true-detail-kept-because-it-was-known.md`). Then name, for yourself and not on the page, the one or two doubts this reader will most likely hold against the candidate, such as a run of short posts. Each is answered by a fact about the work, set where the doubt would arise. The doubt is not named on the page and nothing there denies it, as this method's rule on a defence against a charge the reader has not made requires. A doubt the record cannot answer goes to the candidate in the register.")
    s=rep(s,'### 3. Voice','The same reader is then given `modules/body-proof.md`, for the page below its top. Where it finds a need with no line there, or only a general one, a post that leaves it to guess for whom or how big, or a doubt left unanswered where it arose, the writer puts that right as R sets out.\n\n### 3. Voice')
    return s

def first_post(s):
    s=rep(s,"The sequence of the candidate's posts, each with its title and years, is the form of the document and stands whole: a post left out is a gap the reader notices.","The sequence of the candidate's posts, each with its title and years, is the form of the document and stands whole: a post left out is a gap the reader notices, and the first post listed is read as what the candidate is now. Where that post's title or its employer's trade would have this reader take the candidate for someone other than `taken-for`, a heading over its entry names the work in that post that this reader is hiring for, the posts after it that the heading does not describe stand under a heading of their own, and the entry leads on the candidate's part in that work and says of the employer's trade only what this reader needs. The title, employer and dates stay as that post's subjects in `experience` give them, and those subjects' `rulings` and `corrections` say how the candidate wants the post stated. Whether the list of posts may carry such headings is read from the candidate file's rulings and defaults on form.")
    s=rep(s,'a reader who cannot has been given an index of a career (`cases/an-opening-that-indexes-the-career.md`).',"a reader who cannot has been given an index of a career (`cases/an-opening-that-indexes-the-career.md`). Then it answers `modules/first-post.md`; where its answer is no, the head of the list of posts and the first entry's lead are written again by R's rule for the first post.")
    return s

def outside_trace(s):
    s=rep(s,'Every figure and every claim of fact in the document is traced to an entry in `brief.md`, in a trace written down','Every figure and every claim of fact in the document is traced to an entry in `brief.md` by a fresh agent, in a trace written down')
    s=rep(s,'and a step past the source passes (`cases/a-sources-check-made-without-the-sources-words.md`). A row holds when the document\'s verb and its limiting words are the source\'s. The source\'s year or its nouns under a stronger verb, or without the place or the "most" that bounded the claim, is a step past it.','and a step past the source passes; with them, the writer still reads its own step past the source as the source, since it holds the thought behind the sentence (`cases/a-sources-check-made-without-the-sources-words.md`). The agent gets the document, the advertisement, what `brief.md` marks as coming from the candidate or a named source, the files those name, and `modules/sources.md`, which says when a row holds, and nothing else the writer wrote. Its trace is saved in `examine/`.')
    s=rep(s,"A quoted claim is read against its source past the quotation marks, to the end of the sentence. One that traces to the writer's inference is taken out.","The writer acts on the rows as they stand, with one exception. A claim the trace finds no source for goes back to the record: where the record holds it, the writer enters the source in `brief.md` and the claim stays for the next trace; where it does not, the claim traces to the writer's inference and is taken out.")
    s=rep(s,'since that is what it is for. A superlative needs a source a reader could open, and a title or a date is given as the referee would give it. Check that','since that is what it is for. Check that')
    s=rep(s,'a document without them is not complete, and its row says so.','a document without them is not complete, and `examine.md` says so.')
    return s
variants={'v7-holes2':holes2,'v9-leads':lambda s: leads(holes2(s)),'v10-leads-stays-out':lambda s: stays_out(holes2(s)),'v11-several':lambda s: several(holes2(s)),'v12-body':lambda s: body(holes2(s)),'v13-first-post':lambda s: first_post(holes2(s)),'v14-outside-trace':lambda s: outside_trace(holes2(s))}
for name,fn in variants.items():
    text=fn(base)
    open(os.path.join(HERE,'variants',name+'.md'),'w').write(text)
    print(name,len(text)-len(base),'characters added')
