#!/usr/bin/env python3
"""Round 1 variants of the HIRE method. Each is the baseline text with one named set of replacements.

Baseline: sales-hire/hire-methodology.md as of commit e51412d3, read from git so that later changes to the method do not
move it. Run from the repository root:
    python3 labs/sales-hire/round-1/make-variants.py
It writes one file per variant into labs/sales-hire/round-1/variants/. There is no v5. Three variants are not made here.
all-changes.md is the method as it stood after the six commits 9202090d to e16b5f63 on branch hire-shift. h1-edit.md and
h1-rewrite.md are the whole text reworded, the first by an editor and the second by a rewrite; neither is a set of replacements.
v9-leads, v10-leads-stays-out and v11-several are replacements on v7-holes2, the text put into the method at 323012ca. A
variant that names a module expects the files of labs/sales-hire/round-1/modules/ beside the method's own modules.
"""
import os, subprocess
HERE=os.path.dirname(os.path.abspath(__file__))
BASELINE='e51412d3'
base=subprocess.run(['git','show',BASELINE+':sales-hire/hire-methodology.md'],check=True,capture_output=True,text=True,cwd=HERE).stdout
three='Three kinds of reader. The common-sense reading and the judges hold the advertisement and stand nearest the person hiring: what the page says, and what stays on it, is theirs to settle. The sentence and voice readers hear how a line reads: a row of theirs is a reason to say a line differently, and a line comes off on their word only where those who hold the advertisement prefer the page without it. A line the judges have put back stays through later sentence readings. The sources trace sees that each claim will hold when the candidate is asked about it in the conversation, or a referee is, and brings a claim back to what the candidate can stand behind. What the candidate has ruled off, and what the trace cannot support, still stay off.'
SAY="Begin by writing in this phase's notes: I am a salesperson and my goal is to sell the candidate."
def rep(s,a,b):
    assert s.count(a)==1, a[:60]
    return s.replace(a,b)
def opening(s):
    s=rep(s,"# HIRE — Writing a Candidacy","# HIRE — Putting a Candidate Forward")
    s=rep(s,"HIRE is a four-phase methodology by which an AI agent writes the document that puts one candidate forward for one post: a CV, and the written answers that travel with it.","HIRE is a four-phase methodology by which an AI agent, acting for one candidate, wins that candidate the first conversation about one post, by the page that goes in ahead of them: a CV, and the written answers that travel with it.")
    s=rep(s,"- **H** — Hirer. Establish who reads the document, how it reaches them, and what they lack that this candidate brings.","- **H** — Hirer. Establish who decides and who reads first, how the page reaches them, and what they are short of that this candidate brings.")
    s=rep(s,"- **R** — Reframe. Select from the record and write each fact as the answer to a question this reader has, at the candidate's level and in the candidate's voice.","- **R** — Reframe. Choose what the page opens on and argues, and write each fact as the answer to a question the person hiring has, at the candidate's level and in the candidate's voice.")
    s=rep(s,"An agent asked for a CV has the candidate's record in front of it and a strong habit of what a CV looks like. Left to both, it produces a document that is correct, complete and addressed to nobody. It arranges what it knows; a candidate who speaks to a reader arranges what the reader lacks.","Whoever fills a post has a pile of applications, reads a few words of each, and calls the few who look like what they are short of. An agent asked for a CV has the candidate's record in front of it and a strong habit of what a CV looks like. Left to both, it produces a page that is correct, complete and gives that person no reason to call. It arranges what it knows; a candidate who speaks to an employer arranges what the employer lacks.")
    s=rep(s,"HIRE answers the first by fixing the reader and taking the candidate's own telling before any sentence is written.","HIRE answers the first by settling who decides and what they are short of, and taking the candidate's own telling, before any sentence is written.")
    return s
def examine(s):
    s=rep(s,"and repair it, until the stop rule is met.","and repair it, until it is ready to send.")
    s=rep(s,"Examine runs cheap readers before dear ones, and the candidate last.",three+"\n\nExamine runs cheap readers before dear ones, and the candidate last.")
    s=rep(s,"whoever ran it saves both.","whoever ran it saves both. A question put to the candidate in the register says what the answer would let the page say, and on which applications.")
    s=rep(s,"This is the check that finds grain and inherited sentences, and it costs one call.","This is the check that finds grain and inherited sentences, and it costs one call. Last, from where the person filling the post stands: what does it take the candidate for from the top of the page, what did it look for and not find, and what would make it hesitate to call the candidate?")
    s=rep(s,"Stop when a full pass of checks 1 to 4 leads to no change, the rows this method says to leave not counted, and no version on file is preferred by the judges to the current one. The first full draft is one of those versions.","A page is ready to send when, in this order: the judges prefer no version on file to it, the first full draft among them; what the common-sense reader raised has been answered; the sources trace holds on the version that goes out; and everything the sentence and voice readers raised has been answered once, by saying the line differently, by leaving it where this section says to, or by putting it to the candidate.")
    return s
def say(s):
    for h in ("## H — Hirer","## I — Interview","## R — Reframe"):
        s=rep(s,h+"\n\n",h+"\n\n"+SAY+"\n\n")
    return rep(s,"## E — Examine\n\n","## E — Examine\n\n"+SAY+" Write it again before each check.\n\n")
def hole(s):
    s=rep(s,"\n\nAn inference in `brief.md` is an assumption","\n\nThen list the holes. A buyer of a drill wants a hole in the wall, and an employer filling a post wants something done that nobody there is doing. From the advertisement and what the employer has published, write in `brief.md` what those things are, numbered, the most pressing first, each with where you read it. The advertisement's list of duties is the drill; ask what goes wrong for this employer while the post stays empty.\n\nAn inference in `brief.md` is an assumption")
    s=rep(s,"so the candidate can see what was left out and why (`cases/a-true-detail-kept-because-it-was-known.md`).","so the candidate can see what was left out and why (`cases/a-true-detail-kept-because-it-was-known.md`). Set each fact you keep against the hole it fills, by number. A hole with nothing against it is where the page is weakest: search the whole record again for that one, and where the record has nothing, put the question to the candidate in the register and name the hole. The page takes the holes in the employer's order, and its opening shows the candidate filling the first.")
    s=rep(s,"whoever ran it saves both.","whoever ran it saves both. Enter each change to the page in `examine.md` with the number of the hole it serves, meaning the page now shows more plainly that the candidate fills it. A change that serves no hole puts something right, and is entered as `check`.")
    s=rep(s,"This is the check that finds grain and inherited sentences, and it costs one call.","This is the check that finds grain and inherited sentences, and it costs one call. Before it opens the page, it lists from the advertisement alone what this employer most needs done; afterwards it says, for each, where the page shows the candidate doing it, or that it does not.")
    s=rep(s,"Then say plainly what remains: the rows left standing and why,","Then say plainly what remains: how many changes served each hole and how many were `check`, the rows left standing and why,")
    return s
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
variants={'v1-opening':opening,'v2-examine':examine,'v3-say':say,'v4-hole':hole,'v6-say-hole':lambda s: hole(say(s)),'v7-holes2':holes2,'v8-opening-holes2':lambda s: holes2(opening(s)),'v9-leads':lambda s: leads(holes2(s)),'v10-leads-stays-out':lambda s: stays_out(holes2(s)),'v11-several':lambda s: several(holes2(s))}
for name,fn in variants.items():
    text=fn(base)
    open(os.path.join(HERE,'variants',name+'.md'),'w').write(text)
    print(name,len(text)-len(base),'characters added')
