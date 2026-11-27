# Worklog: sales-improvement-2

Round 2 of the lab for HIRE, begun 27 November 2026. It starts from the method as released at commit `323012ca` on `hire-shift`, which holds the hole step, and from round 1's log, data and tools. The key to the real posts and every page, room and judge's answer are outside this repository, in the folder round 1's log names; `KEY.md` there lists the tools.

## The dimensions of the round, named before any page is written

| Dimension | What is changed | Ground | Outcome |
|---|---|---|---|
| The top of the page: what leads | `v9-leads`: the brief names the first thing the reader has to know of any applicant, the first lines of the page answer it from the record, and a reader in Examine says whether they did | Seen by hand in round 1: opening on the largest organisation led bettered two finished pages by 0.6 of a rank among other candidates. Reasoned: a reader holding ten pages sorts on level and scale before reading further | open until the first stage is read |
| The top of the page: what stays out | `v10-leads-stays-out`: `v9-leads`, and what the reader has no use for in choosing whom to speak to stands lower on the page | Seen by hand in round 1: of the sixteen best and worst placed pages, the six that name no unrelated trade and carry no long summary for other work are all in the best eight; made by hand, each choice leaned the right way | open until the first stage is read |
| How many pages are written, and how one is chosen | `v11-several`: the page is written afresh more than once and the method's judges choose among the finished pages | Seen in round 1: finished pages of one text differ by about a rank, and between two pages of one text the winner of a pair ranks better among other candidates 14 times against 1 | open until the first stage is read |

Round 1's list of dimensions stands as the wider list, in its log and in `../ROADMAP.md`. Two facts from its pages placed these three first. The record's large facts are already on the page: of eighteen pages for post A, first drafts and finished, all carry the largest count of users and the backer, and fifteen the count of merchants, before the checks and after. So where a fact stands is open, and whether it is selected is not. And the released text's three finished pages for post A open three different ways, one of them on the organisation led. The first two dimensions rewrite the sentence the hole step put into the method, so they carry on the one direction round 1 kept.

## What counts as an improvement, fixed before any count

Every finished page is judged both ways round 1 judged: placed fifth among the same nine other candidates' pages for its post before eight judges who give the whole order, and compared in pairs with pages of the released text, the released text's pages with each other included. No follow-up question is put to a judge.

- **A version of the top is kept** when three quarters or more of its finished pages open as asked, its pages rank better among the other candidates than the released text's by a one-sided test at 5 per cent, and it is not behind in pairs read against the draw. How a page opens is counted by a reader who is not told the text, given the advertisement and the page and the question in `modules/first-thing.md`, for the released text's pages as for the versions'.
- **It is dropped** when after the first stage its pages rank behind the released text's by half a rank or more, or when its first drafts do not open as asked under three wordings, four first drafts a wording.
- **It is left open** otherwise, with the number of pages that would settle it. Where rank and pairs disagree it is left open and both are reported.
- **Several pages and a choice is kept** when, over the sets of four pages written under one text for one post, the page chosen ranks better than the mean of its set by half a rank or more on the mean, by a one-sided test at 5 per cent. It is dropped when the chosen page is no better than its set's mean. The choice is made by an agent following the version's text, with nobody else's hand in it, and again by the lab's pair judges, and the two are reported side by side.

What this size can show: eight pages a text see a difference of about 1.2 ranks four times in five, and sixteen about one rank. The hand edit was worth 0.6. So for a version of the top that works as the hand edit did, the likeliest ending is that its pages open as asked, lean better, and are left open with the count that would settle it. The choice among several is measured inside each set and can be settled at this size.

## Design

- **Texts.** The released text and the three versions above, defined in `make-variants.py` as the released text with named replacements; the reader's questions are files in `modules/`.
- **Writers.** One Opus session a page, as in round 1's later batches: started in a room that holds the candidate's record at the commit round 1 used, pointed at a folder whose name says nothing, reasoning effort medium set on the command line, the office's instructions loaded, the owner's account. Finished pages, each run's first full draft kept.
- **Stages.** First, the wording: four first drafts under each version of the top, two a post. Then four finished pages a text a post for the released text, `v9-leads` and `v10-leads-stays-out`, on posts A and D: 24 runs. Then four more a post for the released text and the leading version: 16 runs. Round 1's three finished pages under the released text for post A are placed too and reported apart, to show whether the two batches agree.
- **`v11-several`** needs no writing of its own: each set of four pages written under one text for one post stands for one application written four times. An agent given the set and the version's text makes the choice.
- **Size.** 24 to 40 finished runs and 8 to 24 first drafts: about 400 to 750 dollars as the runs report it and five to nine hours at four writers at once; judges about 80 dollars.

## Decided without the owner

His words on the round: "I do not see anything I have to decide. A round was already done. You just need to do another round. Your goal is to improve the outcome by exploring the dimensions. The dimensions include the sales framework that was already known."

- The candidate file carries a note for management posts against head-counts on a senior CV, pointing at his words, and marks the engineers led as included by outcome. Round 1's writers read that as allowing the figure, and some opened on it. The record stands as it is and writers read it as they do.
- A version is kept on rank among other candidates with pairs as the check, since being called ahead of others is the outcome the series is for.
- Writing several pages for one costs that many times the writing on every application. The round measures the gain and states the price; whether it is worth paying is decided when a version is released.

## Limits

One candidate. One model writes and judges. The other candidates' pages were not written for the advertisement. The hand evidence for the top is two pages, and a test of 25 November saw no opening win on a shortlist of three, a measure round 1 found gives no grade. A set of four pages written by a script's four writers stands in for one agent writing a page four times.
