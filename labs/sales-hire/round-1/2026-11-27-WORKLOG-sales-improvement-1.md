# Worklog: sales-improvement-1

Round 1 of the lab for HIRE, 27 November 2026. The question of the series: does a version of the method exist under which a writer sells the candidate, and does the page it writes win more often with the person filling the post. The series is planned to run to sales-improvement-9.

## What the work is for

The owner holds that a job application is a sale: "The nature of it is still sales." Over three batches of CVs he gave input on "framing, order, and relevance", and "the AI constantly gave back one simple-minded answer: Is this verifiable?" His conclusion: "there is a soul needed. The soul is a salesman's soul." He also holds that announcing this to an agent does nothing, and that "the choice of words and the framing that it was written as if it is from a salesperson do more work".

So a round is not an audit of a method. It asks what would make the person filling a post call this candidate, and what in the method's text makes a writer produce that. The pull toward checking that the series studies acts on whoever runs a round as much as on the writers under test: "deviation was completely being observed every time." This log is itself mostly about instruments and counts, and a reader who takes its cue from that will check the round instead of continuing it. Four questions kept the work pointed during this round, and they are worth asking of any page before measuring it:

- Who is deciding at this step, what are they short of, and what gets the candidate the next conversation?
- What does the page lead with, what follows, and what stays out because this person has no use for it?
- Who else is being put in front of them, and what does this candidate offer that theirs cannot?
- What doubt will they raise, and which proof on the page answers it?

## Baseline

The baseline is commit `e51412d3` on branch `hire-shift`. It is the first commit that holds both the candidate file's format grouped by kind and subject (`9b127c04`, `e918ca6e`, issue 272 of `overseers-desk/skillbooks`; the format is the table under "What a run produces" in the method) and the folder's name `sales-hire` (the rename `e6789924`, made on branch `aesop` and merged in at `736b9b96`). Every version in `variants/` is this text with one named set of replacements, and `sales-hire/hire-methodology.md` is this text: nothing from the round has been integrated.

Posts are named here by role. Post A is a vice-president post leading a new AI unit at a car maker's software company. Post B is an engineering senior director at a digital bank. Post C is a chief technology officer of a healthcare technology company, advertised through a recruiter. Post D, a chief technology officer of an AI startup, was held back and not used. The key to the real posts, and every page, room and judge's answer, is outside this repository, at `/var/local/aesop/sales-voice/` on the host `yoga` as of 27 November 2026. `KEY.md` there lists each tool named below and how it is called.

## Terms

- **A comparison** puts two pages for one post before eight sealed judges, half reading each page first. Each judge names the one page it would call the candidate on. "6 to 2" means six judges chose the first-named page and two the other; "20 of 24" means twenty judges of twenty-four chose the version named.
- **Full read**: the judges see both pages whole. **Top**: they see only the first 24 lines of each, as far as a screener reads in a few seconds. The count of 24 comes from an earlier framing test on finished pages, where it took in the name and contact lines. **Pile**: one page sits among nine rival candidates' pages and the judge names whom to call first.
- **A sealed judge** is the person the post reports to, in a room built with the undercover skill that carries nothing of the office, answering a recruiter's short note.
- **The salesperson sentence**: "I am a salesperson and my goal is to sell the candidate", written by the writer at the start of each phase. It is in `v3-say`, `v6-say-hole` and `all-changes`.
- **The two marks**: `sell` and `check`, put by the writer on each change to a page with its reason. They are in `all-changes` only. `v4-hole`, `v6-say-hole`, `v7-holes2` and `v8-opening-holes2` mark a change with the number of the hole it serves, or `check`.
- **A hole**: something the employer needs done that nobody there is doing, read from the advertisement. The word is the owner's, from the saying that a buyer of a drill wants a hole in the wall.
- **A third-person slip**: a sentence in which the page calls the candidate "he" or "his" where the rest speaks without a pronoun or as "I".
- **Repeat**: one of three first drafts written under the same version for the same post. There is no version numbered 5.

## State reached

- The lab exists (`labs/sales-hire/`), with eight versions of the method for this round and `make-variants.py`, which defines seven of them from the baseline. `all-changes.md` is the method as it stood after six commits made directly on the branch (`9202090d` to `e16b5f63`), since returned to the baseline.
- One version, `v8-opening-holes2`, improved the top of a first draft on each of the three posts tried: where both pages reached the judges in the same form, 45 judges of 48 preferred its top to the baseline's. On a full read no version is reliably ahead of the baseline. It has not been integrated. The first drafts were judged without their name, employers, titles and dates (finding 5), so this speaks to the summary and bullets and has to be repeated on whole pages.
- One page for post A beats the page the candidate already had: seven judges to one on a full read and five to two on the top. It was joined by hand from the top of one run and the body of another, as a test of what decides a comparison (finding 4). It is evidence, not a page ready to send: its two parents disagree on one date, it has not been traced to sources as one page, and whether it goes anywhere is the owner's decision.
- Four instruments exist outside the repository: sealed judges, runs that stop at the first full draft, an outside count of why each change to a page was made, and a count of the advertisement's asks a page proves.
- A lab rule, agreed with the owner: a question put to a reader about the page is tested as a module file in the round's folder, and copied into `sales-hire/modules/` when it has held. Four edits in this round's versions are such questions written into the method's text.

## The owner's words on the series

- On the series and what a round leaves: "you can say it's the sales-improvmeent-1 and we plan to do 1 all the way to 9 in the coming days (at which point sales improvement might be exhausted). each run produces a log and at your log, You can speculate what worked, and express the wish to see different CV being worked on to see the result difference, so that next agent can start working."
- On tone: "You must speak it in a discovery tone rather than in a infantilization tone ... speak like a scientist."
- On the two ways of working: "If we are making progressive change and we are locking down a version that we believe reasonably well, but still leave a bit of chance of regression, that if regression is detected, the next agent is feel free to roll back and find a good combination that works. Then we have a timeline-based method. Alternatively, if we are widely testing competing theories, we might have folder-based method." And: "I prefer the lab inside method repository".
- On the joined page: "since now we have a good CV, let's keep the work".
- On means, for the autonomous part of this round: "I give you the all of the rest of the context and the unlimited use of Jethro agents and I'll check periodically." He set no budget for a round and no order among the wishes.
- His own ideas tested here: applying only half of the changes; the baseline with only the salesperson sentence; listing the holes and marking each change with the hole it serves; the `sell` and `check` marks drawn as a path, "any move towards selling should be upward, and any move towards checking should be rightward".

The wish to see other CVs worked on is his. The other wishes below, the bar for integration in the lab's note and in the last wish, and the rule that a reader's question is a module copied on release are mine; he asked for the options to be listed with a decision and has not objected to them. He has not said he read the joined page. The two unlabelled pairs the plan offered for his own blind read were never prepared. Nobody has been given the tracing of the joined page or the settling of its date.

## What was observed

1. **What earlier writers took the job to be.** Three sessions that had each written a batch of CVs under the method were asked what the job had been. Unprompted: "an inspector of the method's output"; "a checker" and "a foreman"; "a tester and a compliance checker". Each counted a page done when its checks had run. None of their pages met the method's stop rule, and each set a cap of its own. Two took proof of the candidate's standing off pages after their own judges had named it as deciding.

2. **Why changes to a page were made, counted by a reader who held only the working records.** In four older records, 301 changes after the first draft: 245 to check something, 18 to sell, 38 unclear. A remark on a line was answered by deleting the line 34 times and by re-saying it or adding proof 194 times. The selling reasons came almost entirely from the judges. In one record written under `all-changes` before it carried the salesperson sentence: 36, 2 and 2 of 40. In one written with the sentence and the two marks: 19 check, 11 sell and 4 unclear of 34, and the outside reader agreed with the writer's own marks on 24 of 29 entries.

3. **What the judges said decides a comparison.** On the top: the first lines answer what the advertisement asks first, in its order. For post A that was leadership of an engineering organisation, then present hands-on work with coding agents, then a link to the employer's industry. A top that opened on a thesis, or on a general label, lost. On the full read: a concrete instance for each central ask, a rule the candidate set or a system built, in terms a judge "can actually test in an interview".

4. **A page with both wins.** For post A the best top was joined by hand to the best body. The joined page beat the body's parent 8 to 0 on both tests, beat the top's parent 8 to 0 on a full read and tied it 4 to 4 on the top (the tops are the same text), and beat the page the candidate already had 7 to 1 on a full read and 5 to 2 on the top.

5. **Versions compared at the first full draft.** Three first drafts per version and post, each judged against the baseline's draft of the same repeat. The version's count is given.

The tool that turned a draft into text for the judges, `draft-text.sh`, dropped every line written as a raw Typst call. In 39 of the 45 first drafts that removed the name line, the employers, the role titles and the dates. Six drafts had written those lines as plain markdown and reached the judges whole: the baseline's second and third on post B, `v7-holes2`'s second on post B, and on post A `v4-hole`'s third, `v7-holes2`'s third and `v8-opening-holes2`'s second. In the eight full-read pairs where only one page was whole, the whole page won all eight, seven of them 8 to 0, and judges said so: "CV 2 has no name, no contact details, and no employers or dates on the roles". The table below counts every pair, mixed ones included. The session that began round 2 found this and recounted the pairs in which both pages were converted alike:

| Version | Full read, like pairs | Top, like pairs |
|---|---|---|
| v1-opening | 32 of 56 | 33 of 55 |
| v7-holes2 | 35 of 55 | 40 of 56 |
| v8-opening-holes2 | 24 of 48 | 45 of 48 |

Even the like pairs were judged on pages without employers and dates, and their top began at the summary.

| Post | Version | Full read | Top |
|---|---|---|---|
| A | v1-opening | 16 of 24 | 18 of 24 |
| A | v3-say | 9 of 24 | 12 of 23 |
| A | v4-hole | 13 of 24 | 14 of 21 |
| A | v6-say-hole | 12 of 24 | 15 of 23 |
| A | v7-holes2 | 10 of 24 | 20 of 24 |
| A | v8-opening-holes2 | 16 of 24 | 23 of 24 |
| B | v1-opening | 3 of 24 | 9 of 23 |
| B | v7-holes2 | 12 of 24 | 14 of 24 |
| B | v8-opening-holes2 | 4 of 24 | 20 of 24 |
| C | v1-opening | 13 of 24 | 12 of 23 |
| C | v7-holes2 | 19 of 23 | 19 of 24 |
| C | v8-opening-holes2 | 12 of 24 | 21 of 24 |

6. **The top can be instructed.** `v7-holes2` has the writer list the holes in the employer's order and requires the top of the page to show the candidate filling the first of them, a clause to each. `v8-opening-holes2` adds the six sentences of `v1-opening`, which start the method from the person filling the post. On the top, in like pairs, the combined version took 45 judges of 48, `v7-holes2` 40 of 56 and `v1-opening` alone 33 of 55. The repeat is the unit of evidence here, since nearly every comparison came out 8 to 0, 4 to 4 or 0 to 8: the combined version's top won eight repeats of nine and tied one.

7. **The body has not been instructed.** `v7-holes2` and `v8-opening-holes2` also tell the writer to set the most concrete thing on record against each hole. On a full read, in like pairs, they took 35 of 55 and 24 of 48. The combined version's two 0 to 8 results on post B, and `v1-opening`'s 3 of 24 there, came from pairs in which only the baseline's page was whole. The proofs judges asked for were on record in every case examined; writers did not fetch them.

8. **Run-to-run variation is as large as the difference between versions.** The same version opened differently on different runs. The baseline's own drafts vary as much: on post A its second draft beat two of five versions on a full read and tied three, and its third lost to all five, two of those to pages that reached the judges whole when it had not. A single repeat is largely a statement about that repeat's baseline draft. The method's own way of choosing an opening, its internal judges on three approaches, was reported by several writers as following reading order.

9. **Full runs for post A, one per version, to a finished page.** Minutes and dollars are for one writer on Opus. The two comparison columns give this version's count against the page named.

| Version | Minutes | Dollars | Words | Third-person slips | Full read, against `v3-say` | Top, against `all-changes` |
|---|---|---|---|---|---|---|
| baseline | 71 | 8 | 635 | none | 4 to 4 | 0 to 7 |
| all-changes | 25 | 10 | 711 | none | 1 to 7 | (itself) |
| v1-opening | 42 | 26 | 776 | none | 1 to 6 | 0 to 8 |
| v2-examine | 23 | 11 | 688 | yes | 4 to 4 | 0 to 8 |
| v3-say | 28 | 8 | 710 | none | (itself) | 0 to 8 |
| v4-hole | 35 | 16 | 659 | yes | 2 to 6 | 0 to 8 |
| v6-say-hole | 33 | 11 | 608 | none | 3 to 5 | 0 to 8 |

A first draft takes about ten minutes and four to seven dollars. The baseline's finished page, after 71 minutes of checks, tied a 28-minute one on a full read.

10. **The pages the candidate already had beat this round's first finished pages** for posts A, B and C, 8 to 0 on both tests. This comparison is not clean. Those first pages were written from a copy of the record that left parts out, and the older pages predate some of the candidate's corrections, so the two pages of a pair disagree on facts, which judges remarked on in up to seven answers of eight. Comparisons after it are between pages written in this round from the same candidate file.

11. **Third-person slips** appeared in three of the eight finished pages: `v2-examine`, `v4-hole`, and the first page for post A, written under `all-changes` from the reduced copy of the record. A sealed judge shown a page with three such sentences against the same page without them chose the clean one 8 times of 8.

12. **How far the sealed judges can be trusted.** Shown the same page twice, they chose the first one read 7 times of 8. Shown a real difference, they chose by content, with the first-read copy chosen exactly 4 times of 8. They preferred a page to a copy with its summary replaced by generic sentences 8 to 0, and a page written for the post to one written for another post 8 to 0. Differences between finished pages mostly came out 8 to 0, so they rank two pages better than they grade them. About half the answers still read as an assessor comparing two documents, and most judges guessed that one applicant was trying two versions. The pile test has only been tried with four judges while the harness was built, and drew no such guess; it has no fairness test yet and costs about eighty cents a judge against five to eleven.

## Ground already covered

- **Rewording the whole text in a seller's voice, with every rule kept.** Tried twice with subagents, once through the speak-like skill and once as a direct rewrite. Readers cast as a salesperson and as a placer of candidates did not believe a seller wrote either. A reader asked only what the author does for a living moved from "prompt or methodology engineer" to "CV writer or career-services consultant". A fresh session that read only the text described the job and "finished" the same way before and after. A check for changed rules found seven, one of them a rule that could be read backwards: an observation recast as "do X and Y follows" reads as an order to do X.
- **The cold reader of the this-guy-aint skill as a gate for the method's text.** It objects to features any procedure for agents has, such as addressing its reader as an agent. It gives useful leads and cannot be passed.
- **Plain `claude -p` sessions as judges.** Where an office's hooks load from managed settings they survive `--settings`, as they did here; three of twelve answers opened with the office's own lines.
- **An invented easy case as a test of drafting.** A candidate who supplies her own pitch for exactly the post draws a selling first draft from the baseline, and separates nothing.
- **Counting the advertisement's asks a page proves, as a score.** The page the candidate already had proved 6 of 14 and beat pages that proved 7 and 8. The count shows which asks a page leaves bare and does not predict the judges.
- **A stop rule that lets a later pass read only what changed.** A page went out whose last edits no reader had seen whole, with third-person slips in it.
- **Giving writers a reduced copy of the record.** It changed what a writer opened on. It was not why proofs were missing: the lines the judges wanted were in the reduced copy too.

## What may have worked, as speculation

- The top instruction may work because it turns an open choice into a derivation: the writer no longer picks an opening, it reads the order off the advertisement. The six opening sentences may help it by putting the person filling the post in front of the writer before any rule is read; alone they did little.
- The body may resist the same move because "the most concrete thing on record" still leaves the writer to judge what is concrete enough, and nothing later in the method checks it. The top is short enough for a writer to verify against a numbered list; the body is not.
- The salesperson sentence with the two marks moved the reasons writers gave from about one selling reason in twenty to one in three, on one run. Whether reasons of that kind change the page is not known: that page still lost its comparison.
- The checking phase may add little to a page. The older pages were ahead before their checks ran, the writers' own judges often preferred a first draft to its repaired version, and a 71-minute run tied a 28-minute one. Every reader in that phase except the judges reports only what is wrong, which may be why nearly every change made there is a correction.

## Directions held at the start, and where each stands

These came from reading the baseline as someone with a candidate to place, before any test. Most were not reached.

- **Each step sells only the next step.** The page's job is the first conversation, and the first person to read it can turn a candidate down and cannot hire one. The baseline defines its product as a document and stops when its readers find nothing more. Partly tried: `v1-opening` restates the aim; a rule for when a page is ready to send is in `v2-examine`. Neither showed an effect alone.
- **What the person hiring takes the candidate for is settled in the first lines.** Tested, and the round's one firm result (findings 3, 4 and 6).
- **Order follows the buyer's interest.** Tested for the top only. Order inside each post and across the body is untouched.
- **A concrete proof for each thing the buyer needs.** Instructed in `v7-holes2` and `v8-opening-holes2`, with no effect shown (finding 7).
- **The buyer's objections, not the candidate's fears.** The baseline fills its list of conclusions to avoid from what the candidate fears. A seller lists what this buyer will hold against the candidate and answers it on the page or leaves it for the conversation. Tried only as one question to the reader who holds the advertisement, in `v2-examine`. Untested as a step of its own.
- **Know what there is to sell.** The baseline's interview asks where each fact came from. It does not ask for the candidate's strongest results, or why earlier employers and clients chose them. Untested.
- **Standing is a selling point for any buyer.** Who backed the candidate, whom they worked for, the size of what they ran. Earlier batches cut such facts where no line of the advertisement asked for them, and judges asked for them back. Untested as an instruction.
- **Readers who answer as the buyer.** A reader of the page says whether they would call, what they looked for and did not find, and what would stop them, where the baseline's readers list faults. In `v2-examine` and `v4-hole` for one reader; the line-by-line reader is not written. The checking phase was not studied in this round.
- **Proof is for closing, and checking protects a won deal.** The sources trace matters because a claim will be tested in the conversation and by a referee. Not tried as wording. The rewording of the whole text was the only attempt at voice, and it failed for other reasons.
- **The buyer's answer is the only verdict.** Nothing in the baseline follows a page once it is sent: no record of a reply, a call or silence, and so no way for a search of a hundred posts to learn which pitch works. This belongs to the second stage, the application, which is not yet written.
- **Some posts no page can win.** A post that excludes the candidate, or whose core work the record lacks, is a question of whether to apply. The baseline starts from a post already judged worth answering, and this round kept such posts out of its tests.
- **The route outweighs the wording.** A page that arrives through someone inside does better than one that arrives cold. Outside this method's reach as it stands, and also a matter for the second stage.

## Wishes for the rounds that follow

- **The combined version before it is integrated.** The 45 first drafts are still on disk and can be judged again as whole pages once `draft-text.sh` keeps the name, employers, titles and dates; nothing about the full read should be concluded before that. The pile seat would then say which test matters more for a call. Post D stays held back: it is used once, on whatever text is proposed for integration.
- **The body.** A version in which the proof for each hole is gathered where it can be checked, for instance in `selection.md`, before any sentence is written.
- **Modules.** The four reader's questions now written into versions' text lifted into module files: what the reader takes the candidate for, looked for and did not find, and would hesitate over (in `v2-examine`, the sentence beginning "Last, from where the person filling the post stands"); the reader's own list of the employer's needs and where the page shows each (in `v4-hole`, `v7-holes2` and `v8-opening-holes2`, "Before it opens the page"); the check that the page speaks of the candidate in one person (in `v7-holes2` and `v8-opening-holes2`); and a line-by-line reader, not yet written, that says of each line whether the person hiring is more or less inclined to call.
- **The checking phase on one fixed draft,** with and without that last module, measured by the outside count of selling and checking changes and by the judges.
- **A fixed point of comparison.** Each draft judged against one common reference page, or several baseline drafts per repeat, since the baseline's draw decided much of each repeat here.
- **The candidate file.** Whether a file that states facts as "he" is where the third-person slips come from, and whether the file's regrouping changed what writers pick up, by writing one post under the baseline from the file as it was before and after.
- **A bar for integration that names the seat.** A version's replacements enter the method when the effect has shown on at least two posts and three repeats each. This round met that on the top and not on the full read, so the bar has to say which test it is about.
