#!/usr/bin/env python3
"""Round 1 variants of the HIRE method. Each is the baseline text with one named set of replacements.

Baseline: sales-hire/hire-methodology.md as of commit e51412d3, which is what it holds now. Run from the repository root:
    python3 labs/sales-hire/round-1/make-variants.py
It writes one file per variant into labs/sales-hire/round-1/variants/. There is no v5. The variant all-changes.md is not made here:
it is the method as it stood after the six commits 9202090d to e16b5f63 on branch hire-shift.
"""
import os
HERE=os.path.dirname(os.path.abspath(__file__))
base=open(os.path.join(HERE,'..','..','..','sales-hire','hire-methodology.md')).read()
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
variants={'v1-opening':opening,'v2-examine':examine,'v3-say':say,'v4-hole':hole,'v6-say-hole':lambda s: hole(say(s)),'v7-holes2':holes2}
for name,fn in variants.items():
    text=fn(base)
    open(os.path.join(HERE,'variants',name+'.md'),'w').write(text)
    print(name,len(text)-len(base),'characters added')
