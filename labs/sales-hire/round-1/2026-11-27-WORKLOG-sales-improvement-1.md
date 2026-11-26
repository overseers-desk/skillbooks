# Worklog: sales-improvement-1

Round 1 of the lab for HIRE, 27 November 2026. The question of the series: does a version of the method exist under which a writer sells the candidate, and does the page it writes win more often with the person filling the post. The series is planned to run to sales-improvement-9.

## Baseline

The baseline is commit `e51412d3` on branch `hire-shift`. It is the first commit that holds both the candidate file's format grouped by kind and subject (`9b127c04`, `e918ca6e`, issue 272 of `overseers-desk/skillbooks`; the format is the table under "What a run produces" in the method) and the folder's name `sales-hire` (the rename `e6789924`, made on branch `aesop` and merged in at `736b9b96`). Every version in `variants/` is this text with one named set of replacements. `sales-hire/hire-methodology.md` at the branch tip is the baseline text again (`2649d5a5`): nothing from this round has been integrated.

Posts are named here by role. Post A is a vice-president post leading a new AI unit at a car maker's software company. Post B is an engineering senior director at a digital bank. Post C is a chief technology officer of a healthcare technology company, advertised through a recruiter. Post D, a chief technology officer of an AI startup, was held back and not used. The key to the real posts, and every page, room and judge's answer, is outside this repository, at `/var/local/aesop/sales-voice/` on the host `yoga` as of 27 November 2026 (`KEY.md` there).

## Terms used below

- **A comparison** puts two pages for one post before eight sealed judges, half reading each page first. Each judge names the one page it would call the candidate on. "6 to 2" means six judges chose the first-named page and two the other.
- **Full read**: the judges see both pages whole. **Top**: they see only the first 24 lines of each, as far as a screener reads in a few seconds. **Pile**: one page sits among nine rival candidates' pages and the judge names whom to call first.
- **The salesperson sentence**: "I am a salesperson and my goal is to sell the candidate", written by the writer at the start of each phase. It is in `v3-say`, `v6-say-hole` and `all-changes`.
- **The two marks**: `sell` and `check`, put by the writer on each change to a page with its reason. They are in `all-changes` only. `v4-hole`, `v6-say-hole` and `v7-holes2` mark a change with the number of the hole it serves, or `check`.
- **A third-person slip**: a sentence in which the page calls the candidate "he" or "his" where the rest speaks without a pronoun or as "I".
- **Repeat**: one of three first drafts written under the same version for the same post. There is no version numbered 5.

`KEY.md`, outside the repository, lists each tool named below and how it is called.

## State reached

- The lab exists (`labs/sales-hire/`), with eight versions of the method for this round and `make-variants.py`, which defines seven of them from the baseline. `all-changes.md` is the method as it stood after six commits made directly on the branch (`9202090d` to `e16b5f63`) and since returned to the baseline.
- No version has been shown to produce a better whole page than the baseline. One version, `v8-opening-holes2`, improved the top of the page on each of the three posts tried, 64 judges of 72 (finding 12). On a full read no version is reliably ahead, and that one was behind on post B.
- One page for post A beats the page the candidate already had: seven judges of eight on a full read and five of seven on the top alone. It was joined by hand from the top of one run and the body of another, and no single run produced it. Its two parents disagree on one date, and it has not been traced to sources as one page.
- Four instruments exist outside the repository: sealed judges, runs that stop at the first full draft, an outside count of why each change to a page was made, and a count of the advertisement's asks a page proves.
- A lab rule agreed with the owner at the end of the round: a question put to a reader about the page is tested as a module file in the round's folder, and copied into `sales-hire/modules/` when it wins. Four edits in this round's versions are such questions written into the method's text, and are not yet lifted out (see Wishes).

## What was observed

1. **Three sessions that had each written a batch of CVs under the method were asked what the job had been.** Unprompted: "an inspector of the method's output"; "a checker" and "a foreman"; "a tester and a compliance checker". Each counted a page done when its checks had run. None of their pages met the method's stop rule, and each set a cap of its own. Two took proof of the candidate's standing off pages after their own judges had named it as deciding.

2. **Why changes were made, counted by a reader who held only the working records.** In four older records, 301 changes after the first draft: 245 to check something, 18 to sell, 38 unclear. A remark on a line was answered by deleting the line 34 times and by re-saying it or adding proof 194 times. The selling reasons came almost entirely from the judges. In one record written under `all-changes.md` without the salesperson sentence: 36, 2 and 2 of 40. In one written with the salesperson sentence and the two marks: 19 check, 11 sell and 4 unclear of 34, and the outside reader agreed with the writer's own marks on 24 of 29 entries.

3. **The pages the candidate already had beat this round's first pages** for posts A, B and C, eight judges of eight, on a full read and on the top alone. Those first pages were written from a copy of the record that left parts out, and the older pages predate some of the candidate's corrections, so the two pages of a pair disagree on facts. Judges remarked on such disagreements in up to seven answers of eight. This comparison is therefore not clean, and later comparisons are between pages written in the same round from the same candidate file.

4. **Full runs for post A, whole record, one run per version.** Minutes and dollars are for one writer on Opus.

| Version | Minutes | Dollars | Words | Third-person slips | Full read: this version to the best body (`v3-say`) | Top: this version to the best top (`all-changes`) |
|---|---|---|---|---|---|---|
| baseline | 71 | 8 | 635 | none | 4 to 4 | 0 to 7 |
| all-changes | 25 | 10 | 711 | none | 1 to 7 | (the best top) |
| v1-opening | 42 | 26 | 776 | none | 1 to 6 | 0 to 8 |
| v2-examine | 23 | 11 | 688 | yes | 4 to 4 | 0 to 8 |
| v3-say | 28 | 8 | 710 | none | (the best body) | 0 to 8 |
| v4-hole | 35 | 16 | 659 | yes | 2 to 6 | 0 to 8 |
| v6-say-hole | 33 | 11 | 608 | none | 3 to 5 | 0 to 8 |

5. **What the judges said decided it.** On the top: the first lines answer what the advertisement asks first, in its order. For post A that was leadership of an engineering organisation, then present hands-on work with coding agents, then a link to the employer's industry. A top that opened on a thesis about agents, or on a general label, lost. On the full read: a concrete instance for each central ask, a rule the candidate set or a system built, in terms the judge "can actually test in an interview".

6. **The joined page.** The best top over the best body beat the body's parent eight to nothing on both tests, beat the top's parent eight to nothing on a full read and tied it four to four on the top (the tops are the same text), and beat the page the candidate already had seven to one and five to two. So on this post those two choices decide, and a page that has both wins.

7. **First drafts for post A, three per version, each judged against the baseline's draft of the same repeat.** The version's count is given, of the judges whose answer could be counted.

| Version | Full read, repeats 1 to 3 | Total | Top, repeats 1 to 3 | Total |
|---|---|---|---|---|
| v1-opening | 4 of 8, 4 of 8, 8 of 8 | 16 of 24 | 6 of 8, 4 of 8, 8 of 8 | 18 of 24 |
| v3-say | 3 of 8, 0 of 8, 6 of 8 | 9 of 24 | 4 of 7, 0 of 8, 8 of 8 | 12 of 23 |
| v4-hole | 5 of 8, 0 of 8, 8 of 8 | 13 of 24 | 6 of 8, 2 of 7, 6 of 6 | 14 of 21 |
| v6-say-hole | 0 of 8, 4 of 8, 8 of 8 | 12 of 24 | 2 of 8, 7 of 7, 6 of 8 | 15 of 23 |
| v7-holes2 | 0 of 8, 4 of 8, 6 of 8 | 10 of 24 | 8 of 8, 5 of 8, 7 of 8 | 20 of 24 |

The baseline's own draft varies as much as any version's. Its second draft beat four of five versions on a full read, and its third lost to all five. A repeat's result is therefore largely a statement about that repeat's baseline draft.

8. **One instruction reproduced.** `v7-holes2` has the writer list what the employer needs done, in the employer's order, and requires the top of the page to show the candidate filling the first of those, a clause to each. Its top beat the baseline draft's top in all three repeats. Its other instruction, to set the most concrete thing on record against each need, shows no effect on the full read.

9. **The same version opens differently on different runs.** Each of four versions chose a different opening on its full run and on its first draft. The method's own way of choosing an opening, its internal judges on three approaches, was reported by several writers as following reading order.

10. **Third-person slips** appeared in three of the eight full pages written in this round: `v2-examine`, `v4-hole`, and the first page for post A, written under `all-changes` from the reduced copy of the record and not in the table above. A sealed judge shown a page with three such sentences against the same page without them chose the clean one eight times of eight.

11. **The sealed judges.** Each is the person the post reports to, in a room built with the undercover skill, answering a recruiter's note. Shown the same page twice, they chose the first one read seven times of eight. Shown a real difference, they chose by content, with the first-read copy chosen exactly four times of eight. Every difference large enough to see came out eight to nothing, so they rank two pages and do not grade them. Most guessed that one applicant was trying two versions. A pile test, one page among nine rival pages, drew no such guess and costs about eighty cents a judge against five to eleven.

12. **Two more posts, and the two leading changes combined.** `v8-opening-holes2` is `v1-opening` and `v7-holes2` together. Three first drafts per version on posts B and C, and three of the combined version on post A, each judged against the baseline's draft of the same repeat. The version's count is given.

| Post | Version | Full read, repeats 1 to 3 | Total | Top, repeats 1 to 3 | Total |
|---|---|---|---|---|---|
| A | v8-opening-holes2 | 0 of 8, 8 of 8, 8 of 8 | 16 of 24 | 8 of 8, 7 of 8, 8 of 8 | 23 of 24 |
| B | v1-opening | 3 of 8, 0 of 8, 0 of 8 | 3 of 24 | 3 of 8, 4 of 7, 2 of 8 | 9 of 23 |
| B | v7-holes2 | 8 of 8, 4 of 8, 0 of 8 | 12 of 24 | 6 of 8, 2 of 8, 6 of 8 | 14 of 24 |
| B | v8-opening-holes2 | 4 of 8, 0 of 8, 0 of 8 | 4 of 24 | 8 of 8, 4 of 8, 8 of 8 | 20 of 24 |
| C | v1-opening | 4 of 8, 7 of 8, 2 of 8 | 13 of 24 | 6 of 8, 6 of 7, 0 of 8 | 12 of 23 |
| C | v7-holes2 | 8 of 8, 7 of 7, 4 of 8 | 19 of 23 | 4 of 8, 8 of 8, 7 of 8 | 19 of 24 |
| C | v8-opening-holes2 | 4 of 8, 8 of 8, 0 of 8 | 12 of 24 | 5 of 8, 8 of 8, 8 of 8 | 21 of 24 |

On the top, the combined version was level with or ahead of the baseline's draft in all nine repeats, and `v7-holes2` in eight of nine. On a full read the picture is mixed for every version, and the combined version lost two repeats of three on post B eight to nothing. `v1-opening` alone did not hold outside post A.

## Ground already covered

- **Rewording the whole text in a seller's voice, with every rule kept.** Tried twice with subagents, once through the speak-like skill and once as a direct rewrite. Readers cast as a salesperson and as a placer of candidates did not believe a seller wrote either, and a reader asked only what the author does for a living moved from "prompt or methodology engineer" to "CV writer or career-services consultant". A fresh session that read only the text described the job and "finished" the same way before and after. A check for changed rules found seven, one of them a rule that could be read backwards: an observation recast as "do X and Y follows" reads as an order to do X.
- **The cold reader of the this-guy-aint skill as a gate for the method's text.** It objects to features any procedure for agents has, such as addressing its reader as an agent. It gives useful leads and cannot be passed.
- **Plain `claude -p` sessions as judges.** Where an office's hooks load from managed settings they survive `--settings`, as they did here; three of twelve answers opened with the office's own lines.
- **An invented easy case as a test of drafting.** A candidate who supplies her own pitch for exactly the post draws a selling first draft from the baseline, and separates nothing.
- **Counting the advertisement's asks a page proves, as a score.** The page the candidate already had proved 6 of 14 and beat pages that proved 7 and 8. The count shows which asks a page leaves bare and does not predict the judges.
- **A stop rule that lets a later pass read only what changed.** A page went out whose last edits no reader had seen whole, with third-person slips in it.
- **Giving writers a reduced copy of the record.** It changed what a writer opened on. It was not why the proofs were missing: the lines the judges wanted were in the reduced copy too, and the writers did not fetch them.

## What may have worked, as speculation

- The top instruction of `v7-holes2` may work because it turns an open choice into a derivation: the writer no longer picks an opening, it reads the order off the advertisement. If so, the same move could be tried on the body, where the writer still chooses what counts as proof.
- The salesperson sentence with the two marks moved the reasons writers gave from about one selling reason in twenty to one in three, on one run. Whether reasons of that kind change the page is not known: that page still lost its comparison.
- `v1-opening`, six sentences at the head of the method that start from the person filling the post, was level with or ahead of the baseline's draft in every repeat on both tests. I did not expect that from the smallest change, and three repeats against a varying baseline do not establish it. On posts B and C it did not hold alone (finding 12); combined with the top instruction it did on the top.
- The checking phase may add little to a page. The older pages were ahead before their checks ran, the writers' own judges often preferred a first draft to its repaired version, and the baseline's 71-minute run tied a 28-minute one on a full read.

## Wishes for the rounds that follow

- **The combined version before it is integrated.** Its effect on the top meets the bar below on three posts. Its full read fell behind on post B, and nothing here says why: reading the judges' answers for those two repeats, under `sealed/runs/dr2-07-…` and `dr3-07-…` outside the repository, would be the first step. Post D stays held back for whatever text is proposed for integration.
- **A fixed point of comparison.** Each draft judged against one common reference page, or several baseline drafts per round, since the baseline's draw decided much of each repeat here.
- **The body.** A version in which the proof for each need is gathered where it can be checked, for instance in `selection.md`, before any sentence is written.
- **Modules.** The four reader's questions now written into versions' text lifted into module files: what the reader takes the candidate for, looked for and did not find, and would hesitate over (in `v2-examine`, the sentence beginning "Last, from where the person filling the post stands"); the reader's own list of the employer's needs and where the page shows each (in `v4-hole` and `v7-holes2`, "Before it opens the page"); the check that the page speaks of the candidate in one person (in `v7-holes2`); and a line-by-line reader, not yet written, that says of each line whether the person hiring is more or less inclined to call. Every reader in the checking phase except the judges now reports only what is wrong, which may be why nearly every change is a correction.
- **The checking phase on one fixed draft,** with and without that module, measured by the outside count of selling and checking changes and by the judges.
- **The pile seat** for any page proposed as better, since it is the only seat that sets the page against other candidates.
- **The candidate file.** Whether a file that states facts as "he" is where the third-person slips come from, and whether the file's regrouping changed what writers pick up, by writing one post under the baseline from the file as it was before and after.
- **A bar for integration.** A version's replacements enter the method when the effect has shown on at least two posts and three runs each. This round shows the bar has to name the seat: a version can pass it on the top and fail it on the full read. Which seat decides a call is what the pile seat could answer.
