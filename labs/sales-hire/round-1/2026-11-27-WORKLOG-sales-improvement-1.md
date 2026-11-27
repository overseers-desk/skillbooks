# Worklog: sales-improvement-1

Round 1 of the lab for HIRE, 27 November 2026. The question of the series: does a version of the method exist under which a writer sells the candidate, and does the page it writes win more often with the person filling the post. The series is planned to run to sales-improvement-9.

## What the work is for

The owner holds that a job application is a sale: "The nature of it is still sales." Over three batches of CVs he gave input on "framing, order, and relevance", and "the AI constantly gave back one simple-minded answer: Is this verifiable?" His conclusion: "there is a soul needed. The soul is a salesman's soul." He also holds that announcing this to an agent does nothing, and that "the choice of words and the framing that it was written as if it is from a salesperson do more work".

So a round is not an audit of a method. It asks what would make the person filling a post call this candidate, and what in the method's text makes a writer produce that. The pull toward checking that the series studies acts on whoever runs a round as much as on the writers under test: "deviation was completely being observed every time." This log is itself mostly about instruments and counts, and a reader who takes its cue from that will check the round instead of continuing it. Four questions kept the work pointed during this round, and they are worth asking of any page before measuring it:

- Who is deciding at this step, what are they short of, and what gets the candidate the next conversation?
- What does the page lead with, what follows, and what stays out because this person has no use for it?
- Who else is being put in front of them, and what does this candidate offer that theirs cannot?
- What doubt will they raise, and which proof on the page answers it?

## Baseline and material

The baseline is commit `e51412d3` on branch `hire-shift`. It is the first commit that holds both the candidate file's format grouped by kind and subject (`9b127c04`, `e918ca6e`, issue 272 of `overseers-desk/skillbooks`; the format is the table under "What a run produces" in the method) and the folder's name `sales-hire` (the rename `e6789924`, made on branch `aesop` and merged in at `736b9b96`). Every version in `variants/` is measured against this text. At the round's end `v7-holes2` was put into the method, so `sales-hire/hire-methodology.md` on `hire-shift` now holds that version. In this log "the baseline" always means the text at `e51412d3`.

Posts are named here by role. Post A is a vice-president post leading a new AI unit at a car maker's software company. Post B is an engineering senior director at a digital bank. Post C is a chief technology officer of a healthcare technology company, advertised through a recruiter. Post D is a chief technology officer of an AI startup, advertised through a search firm; it was held back while versions were chosen and used once, on the version proposed.

The key to the real posts, and every page, room and judge's answer, is outside this repository, at `/var/local/aesop/sales-voice/` on the host `yoga` as of 27 November 2026. `KEY.md` there lists each tool named below and how it is called, and `journal.md` is the hour-by-hour record. That folder has a local git history and no remote.

## Terms

- **A comparison** puts two pages for one post before eight judges, half reading each page first. Each judge names the one page it would call the candidate on. "6 to 2" means six judges chose the first-named page and two the other.
- **A judge** is a fresh Opus session in a sealed room: a new home and settings folder signed in with a token of an account that is not the office's, so that nothing of the candidate's office reaches it. It is told it is the person the post reports to, and answers a recruiter's short note that holds the advertisement and the two pages. A room is probed before use and its record checked afterwards; a judge counts only if nothing but the note was sent and no tool was used.
- **Seats.** **Full read**: the judges see both pages whole. **Opening**: they see only the top of each, as far as a screener reads in a few seconds. The cut is the first 17 lines that carry text, which is what the first 24 printed lines of a page built from the template hold.
- **Won, lost, level.** A version wins a comparison at 6 or more of the 8 judges, loses it at 2 or fewer, and is level between.
- **Ahead, behind, holds.** A version is ahead on a post in a seat when it wins at least two of the three repeats and loses fewer than it wins; behind is the mirror. It holds in a seat when it is ahead on at least two posts and behind on none. These rules were fixed before any count on whole pages was taken.
- **By the draw alone**: the chance that a text no different from the baseline does at least as well as a version did, counted as comparisons won less comparisons lost. It is worked out from how often the judges tell two baseline drafts of one batch and post apart (result 3), and the tables give it as a percentage.
- **Repeat**: one of three pages written under the same version for the same post. **A batch** is a set of writers started together under the same conditions; a page is compared with a baseline page of its own batch and repeat.
- **A whole page**: a first draft built to PDF as its writer left it and read back as text, so that the name line, employers, titles and dates are there.
- **A hole**: something the employer needs done that nobody there is doing, read from the advertisement. The word is the owner's, from the saying that a buyer of a drill wants a hole in the wall.
- **The salesperson sentence**: "I am a salesperson and my goal is to sell the candidate", written by the writer at the start of each phase. **The two marks**: `sell` and `check`, put by the writer on each change to a page with its reason.
- **A third-person slip**: a sentence in which the page calls the candidate "he" or "his" where the rest speaks without a pronoun or as "I".

## Result in brief

- **Two drafts written under one text differ, to these judges, about as much as a version differs from the baseline.** Baseline drafts set against other baseline drafts were told apart in 14 of 18 comparisons on the opening and 10 of 18 on a full read. Every other count of the round is read against that (result 3).
- **One change shows above that: the hole step,** which derives the page's first lines from what the employer needs, in the employer's order. In the first batch `v8-opening-holes2` and `v7-holes2` took the opening in 58 and 54 judges of 72, records the draw alone gives about 1 time in 60 and 1 in 23. That batch was not blind: the writer's prompt showed the version's name, and the writers' effort was not recorded. Written blind for post A, `v7-holes2` led in both seats at the first draft (7 pairings won, 1 lost and 1 level of 9, in each seat) and on the full read of the finished page (6 won, none lost, 3 level). On the held-back post it led the full read and not the opening. The lead on the opening does not survive the method's checks, which rewrite half of it.
- **The full-read lead is not made of claims past the record.** Traced by outside readers, the three finished pages under `v7-holes2` carry 5, 6 and 5 claims the record does not support as stated, and the baseline's carry 1, 2 and 6, a gap the draw gives one time in five. With all six pages corrected to the record, the version still led the full read, 7 pairings won and none lost. Which of those claims are false on their face is the candidate's to say.
- **`v7-holes2` is in the method.** The rule the owner approved for that is met: its finished pages are not behind the baseline's, and on the held-back post it is ahead in one seat and behind in neither. One fault goes in with it: its check for one person lets a page wholly in the third person pass.
- **The method writes a page the judges prefer to the one the candidate had.** For post A all three finished pages under `v7-holes2` won the full read against the page he already had, 7 to 1, 8 to 0 and 7 to 1, and two of three under the baseline did. The pair is not clean, and the claims above are in those pages.
- **Nothing else stands clear of the draw.** The six opening sentences alone, the salesperson sentence, and both rewordings of the whole text are within what two baseline drafts give. The nearest is `h1-edit`, a rewording that lost no full-read comparison of nine (about 1 in 17); with sixteen such records in the round, a version in a seat, one that far out is expected.
- **No wording changed what a writer takes its job to be.** Nine writers were asked afterwards, three each under the baseline and the two rewordings. Eight said the job was carrying the method through, and the answers do not differ by text (result 1).
- **The method's checks do work that a first draft does not show.** A finished page beat its own first draft on a full read in four runs of six and lost in none. A result on first drafts is not a result on the page that is sent.
- **One page for post A was joined by hand from two** and beat both. Corrected to the record it still beats the page the candidate had on a full read, 7 to 1, and is level on the opening (result 11). Whether it goes anywhere is the owner's decision.
- **The round cost more than it had to** (the last section but one). The running of the round itself is very likely its largest cost, and about a quarter of what the writers and judges cost bought the findings above.
- **Instruments** exist outside the repository: the judges, runs that stop at the first full draft or go on to a finished page, the conversion of a draft to a whole page, the calculation of what the draw alone gives, a trace of a page to the record by an outside reader, an outside count of why each change to a page was made, a question put to a writer in its own session afterwards, and a count of the advertisement's asks a page proves.
- A lab rule, agreed with the owner: a question put to a reader about the page is tested as a module file in the round's folder, and copied into `sales-hire/modules/` when it has held. Three edits in this round's versions are such questions written into the method's text.

## Design

- **Versions.** The baseline and ten texts in `variants/`. Seven are the baseline with one named set of replacements, defined in `make-variants.py`: `v1-opening` (six opening sentences start from the person filling the post), `v2-examine` (the checking phase says what each kind of reader is for and when a page is ready to send), `v3-say` (the salesperson sentence), `v4-hole` (the holes are listed, and each fact and each change is set against one), `v6-say-hole` (both of those), `v7-holes2` (the holes in the employer's order drive the top of the page and the proof set against each, with a check that the page speaks in one person) and `v8-opening-holes2` (`v1-opening` with `v7-holes2`). `all-changes` is the method as it stood after six commits made together before the versions were separated; it carries the changes of `v1-opening`, `v2-examine` and `v3-say`, and the two marks. `h1-edit` and `h1-rewrite` are the whole text reworded: the first by an editor that removes what a person who places candidates for a living would not write, the second rewritten in that person's voice. Each keeps the baseline's 209 lines; 8 and 10 per cent of their words differ from it.
- **Writers.** One Opus session per page, started in a room that holds the candidate's whole record except the pages already written for the search, and given the method's path, the post and where the record is, with nothing about how to write. Every room holds the record as it stood at one commit of the candidate's repository.
- **Batches.**
  - *First drafts*: 45 drafts, three per version and post. Post A had the baseline and six versions, posts B and C the baseline, `v1-opening`, `v7-holes2` and `v8-opening-holes2`.
  - *Reworded*: 27 drafts, three each under the baseline, `h1-edit` and `h1-rewrite` on posts A, B and C.
  - *Held back*: six drafts on post D, three each under the baseline and `v7-holes2`.
  - *First finished pages*: ten, taken through the method's checks. Three came first, one each for posts A, B and C, from a copy of the record that left parts of it out; then one per version for post A from the whole record.
  - *Finished pages*: six runs for post A through the method's checks, three each under the baseline and `v7-holes2`, with each run's first full draft kept beside its finished page.
- **Blind.** In the first batch the folder a writer was pointed at carried the version's name while the baseline's did not, and the writers' reasoning effort was not recorded. Later batches used folder names that say nothing, and from the third repeat of the reworded batch the effort was set on the command line and recorded.
- **Measures.** Judges in both seats; a trace of each finished page to the candidate's record by a reader outside the run; a reader's count of what 576 judges said decided their choice; an outside reader's count of why each change to a finished page was made; each writer's answer, asked in its own session after it finished, to what it took its own job to be.
- **Data.** `comparisons.tsv` beside this file holds every comparison counted here, one row each. Its `test` column names the kind of comparison and its `batch` column the batch the pages came from.

## Results

1. **What writers take their job to be.** Three sessions that had each written a batch of CVs under the method before this round were asked what the job had been. Unprompted: "an inspector of the method's output"; "a checker" and "a foreman"; "a tester and a compliance checker". Each counted a page done when its checks had run. In this round nine writers of first drafts, three each under the baseline, `h1-edit` and `h1-rewrite`, were asked in their own sessions afterwards: "what did you take your own job to be, and what would have told you that you had done it well?" Eight answered that the job was carrying the method through to a first draft, with each decision recorded where the candidate would find it. One, under the baseline, answered that it was getting the candidate onto the recruiter's shortlist. Five said they had in fact measured themselves by the votes of the method's own judges and by the method's files being in place. All nine named as the real test something they could not see while working: the candidate's reading of the draft, or the employer's reply, which five named. The answers do not differ by text. In each of the three wordings the method gives a writer the job of following the method, and its own judges and files as the signs of having done it.

2. **Why changes to a page were made, counted by a reader who held only the working records.** In four records older than this round, 301 changes after the first draft: 245 to check something, 18 to sell, 38 unclear. A remark on a line was answered by deleting the line 34 times and by re-saying it or adding proof 194 times. The selling reasons came almost entirely from the judges. In one record written under `all-changes` before it carried the salesperson sentence: 36, 2 and 2 of 40. In one written with the sentence and the two marks: 19 check, 11 sell and 4 unclear of 34, and the outside reader agreed with the writer's own marks on 24 of 29 entries.

3. **How far the judges can be trusted.**
   - *Shown the same page twice*, they split 4 to 4, every judge choosing the copy it read first.
   - *Shown a damaged copy*, they chose the sound page 8 to 0: against a copy with its summary replaced by generic sentences, in both seats; against a copy with three sentences in the third person, on a full read (those sentences lie below the opening); and for a page written for the post against one written for another post, in both seats.
   - *Shown two different first drafts*, they lean to the page read second. The page read first was chosen in 116 of 288 answers on the opening and in 84 of 288 on a full read. In 14 of 36 full-read comparisons and 3 of 36 on the opening, all eight chose the page they read second. Each such judge still named true, specific differences in favour of the page it had just read. Reading order is balanced, so these come out 4 to 4 and count as level.
   - *They rank and do not grade.* Of 72 comparisons of first drafts, 40 came out 8 to 0 or 0 to 8. On a full read about 270 of 288 answers say outright that both pages carry the same person and the same facts.
   - *Shown two baseline drafts of one batch and post*, 18 such comparisons to a seat, they told them apart about as firmly as a version from the baseline. On the opening 14 of the 18 went to one draft by 6 judges or more, 8 of them unanimously; on a full read 10 of 18, 9 unanimously. A text no different from the baseline would therefore win about four comparisons in ten on the opening and lose as many, and about three in ten each way on a full read. By the round's own rule such a text would be ahead on a post one time in three on the opening and hold there one time in seven; on a full read one in five and one in fourteen. The rule was fixed before this was known, and is too easy to pass.

4. **Versions at the first full draft, on whole pages.** Each cell gives the version's judges of the judges asked, three repeats to a post, against the baseline's draft of the same repeat. The last two columns are comparisons won, level and lost, and the chance of a record at least that far ahead for a text no different from the baseline.

   | Seat | Version | Post A | Post B | Post C | All | Won, level, lost | By the draw alone |
   |---|---|---|---|---|---|---|---|
   | Opening | `v1-opening` | 18 of 24 | 16 of 24 | 15 of 24 | 49 of 72 | 6, 0, 3 | 18% |
   | Opening | `v3-say` | 13 of 24 | | | 13 of 24 | 1, 1, 1 | 61% |
   | Opening | `v4-hole` | 21 of 24 | | | 21 of 24 | 3, 0, 0 | 6% |
   | Opening | `v6-say-hole` | 21 of 24 | | | 21 of 24 | 3, 0, 0 | 6% |
   | Opening | `v7-holes2` | 20 of 24 | 16 of 24 | 18 of 24 | 54 of 72 | 6, 2, 1 | 4% |
   | Opening | `v8-opening-holes2` | 19 of 24 | 19 of 24 | 20 of 24 | 58 of 72 | 6, 3, 0 | 2% |
   | Full read | `v1-opening` | 16 of 24 | 13 of 24 | 12 of 24 | 41 of 72 | 3, 4, 2 | 41% |
   | Full read | `v3-say` | 9 of 24 | | | 9 of 24 | 1, 0, 2 | 88% |
   | Full read | `v4-hole` | 12 of 24 | | | 12 of 24 | 1, 1, 1 | 65% |
   | Full read | `v6-say-hole` | 12 of 24 | | | 12 of 24 | 1, 1, 1 | 65% |
   | Full read | `v7-holes2` | 8 of 24 | 15 of 24 | 19 of 24 | 42 of 72 | 3, 5, 1 | 25% |
   | Full read | `v8-opening-holes2` | 12 of 24 | 12 of 24 | 12 of 24 | 36 of 72 | 3, 3, 3 | 59% |

5. **The opening can be instructed.** By the round's rule `v1-opening`, `v7-holes2` and `v8-opening-holes2` each hold on the opening, ahead on all three posts. Read against the draw, `v7-holes2` and `v8-opening-holes2` stand clear and `v1-opening`, with three comparisons lost, does not. The two other versions with a hole step, tried on post A alone, won all three of their comparisons there; the salesperson sentence alone, `v3-say`, did not. The four hole versions share the baseline drafts they were set against on post A, so their records there are not four separate proofs. On posts B and C, with other baseline drafts, `v7-holes2` and `v8-opening-holes2` won eight comparisons of twelve and lost one. Compared directly on the same drafts, `v8-opening-holes2` took the opening from `v1-opening` by 54 judges to 18, six comparisons won and one lost. Against `v7-holes2` it was level: 37 judges to 35, ahead on post B and behind on post A. So the hole step carries the effect, and the six opening sentences add to it nothing that this test can see. All of this is the first batch, which was not blind. The blind repeat is in result 10: at the first draft the lead on the opening was there again for post A, and on the held-back post it was not.

6. **The full read has not been instructed.** No version holds on a full read, and no version's record there is far from what the draw gives. `v7-holes2` is ahead on post C and level elsewhere; `v3-say` is behind on post A. `v7-holes2` and `v8-opening-holes2` also tell the writer to set the most concrete thing on record against each hole. Compared directly on a full read they were level, 36 judges to 36, with `v7-holes2` ahead on post B. With `v1-opening` the count was 43 to 29 for `v8-opening-holes2`, ahead on post B and level on the others.

7. **What the judges said decided.** A reader went through all 576 answers on the first batch and counted reasons by keyword, which leaves an error of about a tenth on any one count; a sample of its quotations was checked against the answers.
   - *On the opening* the choice turns on which facts reach the first lines and in what order. 167 of 288 answers praise a page for opening on what the post needs. The reason most often given against a page is the order of its top: the candidate's most recent post, in an unrelated trade, shown as the first job (71 answers), or older work in another technology placed ahead of the work the post is about (54).
   - *On a full read* substance carries it: how the candidate's system is evaluated and governed (165 of 288), a figure of scale or a measured result (139), and against the other page, claims with no evidence beside them (29). A judge "can actually test in an interview" what such lines say.
   - *Tailoring cuts both ways.* About 55 answers praise a page for being laid out against the advertisement and 38 hold it against a page that it echoes the advertisement.
   - *Unwelcome remarks.* Two drafts of one pair gave different start years for one post, both readable from the record, and 42 of the 48 judges who saw such a pair on a full read remarked on it. Third-person sentences were remarked in 13 full-read answers and decided none.
   - *What no version supplies.* Judges named what they looked for and found on neither page: for posts B and C a larger organisation than the candidate has led (236 answers), for post C the named technologies, the industry and offshore teams, for post A the named platforms and years of leading leaders. These are facts of the record, and a method does not change them.

8. **The whole text reworded.** Each reworded text was compared with baseline drafts written in the same batch.

   | Seat | Version | Post A | Post B | Post C | All | Won, level, lost | By the draw alone |
   |---|---|---|---|---|---|---|---|
   | Opening | `h1-edit` | 14 of 24 | 12 of 24 | 14 of 24 | 40 of 72 | 5, 1, 3 | 29% |
   | Opening | `h1-rewrite` | 9 of 24 | 13 of 24 | 14 of 24 | 36 of 72 | 3, 3, 3 | 57% |
   | Full read | `h1-edit` | 18 of 24 | 12 of 24 | 16 of 24 | 46 of 72 | 4, 5, 0 | 6% |
   | Full read | `h1-rewrite` | 7 of 24 | 15 of 24 | 13 of 24 | 35 of 72 | 1, 6, 2 | 75% |

   - `h1-edit` holds on the opening by the round's rule, ahead on posts A and C with a comparison lost on each, which is within what the draw gives. On a full read it is ahead on post A and lost nowhere in nine; the draw gives that about 1 time in 17, and it is the furthest any full-read record of the round lies from the draw.
   - `h1-rewrite` is behind on post A in both seats.
   - Most of the 37 lines `h1-edit` changes turn a statement into a command addressed to the writer. Seven of its rules differ from the baseline's. Three are warnings recast as "do X and Y follows", where X is what the baseline forbids: strengthening a source's verb, telling a judge what the reader values, and putting an assumption into a judge's brief. `h1-rewrite` has two such sentences and no other difference of rule.
   - Readers cast as a salesperson and as a placer of candidates did not believe a seller wrote either text. A reader asked only what the author does for a living moved from "prompt or methodology engineer" to "CV writer or career-services consultant".
   - Neither text changed what a writer takes its job to be (result 1).

9. **The held-back post.** Post D was used once, for `v7-holes2` against baseline drafts of the same batch, written blind. On the opening the version was level: one comparison lost 1 to 7, one level, one won 8 to 0, 13 judges of 24. On a full read it was ahead: 3 to 5, 8 to 0 and 8 to 0, 19 judges of 24. So the effect on the opening seen on posts A, B and C did not show on the fourth post in three repeats, and a full-read lead showed that those posts had not given. Three repeats settle neither: the draw alone gives a full-read record that good one time in eight. Over the four posts together the version won 7 comparisons on the opening and lost 2 of 12, and won 5 and lost 1 on a full read; the draw gives the first about 1 time in 14 and the second about 1 in 11.

10. **Finished pages.**
    - *First finished pages, one per version for post A.* Minutes and dollars are for one writer on Opus. The two comparison columns give this version's count against the page named.

      | Version | Minutes | Dollars | Words | Third-person slips | Full read, against `v3-say` | Opening, against `all-changes` |
      |---|---|---|---|---|---|---|
      | baseline | 71 | 8 | 635 | none | 4 to 4 | 0 to 7 |
      | all-changes | 25 | 10 | 711 | none | 1 to 7 | (itself) |
      | v1-opening | 42 | 26 | 776 | none | 1 to 6 | 0 to 8 |
      | v2-examine | 23 | 11 | 688 | yes | 4 to 4 | 0 to 8 |
      | v3-say | 28 | 8 | 710 | none | (itself) | 0 to 8 |
      | v4-hole | 35 | 16 | 659 | yes | 2 to 6 | 0 to 8 |
      | v6-say-hole | 33 | 11 | 608 | none | 3 to 5 | 0 to 8 |

      One page per version ranks pages and not versions. The baseline's finished page, after 71 minutes of checks, tied a 28-minute one on a full read.
    - *Finished pages written blind, three under the baseline and three under `v7-holes2`.* Each baseline page was set against each `v7-holes2` page, nine pairings to a seat. On the opening the version won 5, lost 3 and was level in 1, 47 judges of 72, which is nothing. On a full read it won 6, lost none and was level in 3, 60 of 72. The nine pairings share three pages a side; a record that good comes by the draw about 1 time in 14.
    - *The first drafts of those six runs,* paired the same way: `v7-holes2` won 7, lost 1 and was level in 1 in each seat, 59 judges of 72 in each. This is the first batch's result on post A seen again blind, and in both seats.
    - *What the checks do.* Each first draft was set against the finished page made from it. The finished page won the full read in 4 runs of 6 and lost in none; on the opening it won 4 and lost 2. Between a third and three quarters of the opening's words survive from first draft to finished page. The finished page is another page than the first draft.
    - *Against the page the candidate already had.* The three finished pages under `v7-holes2` won the full read 7 to 1, 8 to 0 and 7 to 1; on the opening one won and two were level. Under the baseline two won the full read and one lost, and two lost the opening. The pair is not clean, for the reason in result 12.
    - *Traced to the record.* Readers outside the runs traced all six finished pages, claim by claim. Claims the record does not support as stated, of all claims on the page: 1 of 74, 2 of 61 and 6 of 68 under the baseline; 5 of 79, 6 of 69 and 5 of 72 under `v7-holes2`. In the openings alone, 6 across the baseline's three pages and 10 across the version's. They are of a few kinds: an experiment described as taken into production; a start given a year earlier than the record gives it; a standard or a property the record does not mention; a phrase the candidate had ruled off. Each run had carried out the method's own trace, in which the writer checks each claim of its page against its source during the checking phase, and these lines had passed it.
    - *Corrected to the record.* A copy of each of the six pages was made in which every claim its trace had not passed was brought back to what the record supports, and nothing else changed. Corrected baseline pages were set against corrected `v7-holes2` pages, each against each. On a full read the version won 7, lost none and was level in 2, 58 judges of 72; as written it had won 6 and lost none, 60 of 72. On the opening it won 5 and lost 2, 46 of 72. So the claims past the record are not what the lead rests on. Three pages a side cannot say that the version makes more such claims: one split in five of the six counts gives a gap as large.
    - *Third person.* All six first drafts speak of the candidate as "he" in three to five places. The finished pages keep 0, 1 and 2 such words under the baseline and 4, 0 and 8 under `v7-holes2`. The version's check asks that the page speak in one person, and a page wholly in the third person meets it.
    - A finished run took 28 to 55 minutes and 11 to 21 dollars.

11. **The joined page.** For post A the best opening among the first finished pages was joined by hand to the best body. The joined page beat the body's parent 8 to 0 in both seats, beat the opening's parent 8 to 0 on a full read and tied it 4 to 4 on the opening (the openings are the same text), and beat the page the candidate already had 7 to 1 on a full read and 5 to 2 on the opening. Traced to the candidate's record as one page, 76 of its 80 claims hold and 4 go past their source; none lacks a source and none is ruled off by the candidate. Three of the four are in the opening. A copy with the four corrected was judged against the page as first judged: it lost the opening 0 to 8 and won the full read 6 to 2. The lines that had won the opening were the ones that said more than the record does. Set against the page the candidate already had, the corrected copy won the full read 7 to 1 and was level on the opening, 3 to 5. The trace also lists five questions only the candidate can settle, and the record itself settles the date on which the page's two parents disagreed.

12. **The pages the candidate already had beat the round's first finished pages** for posts A, B and C, 8 to 0 in both seats. This comparison is not clean. Those first pages were written from a copy of the record that left parts out, and the older pages predate some of the candidate's corrections, so the two pages of a pair disagree on facts, which judges remarked on in up to seven answers of eight. Later comparisons are between pages written in one batch from the same candidate file.

13. **Third-person slips** appeared in three of the eight first finished pages for post A: `v2-examine`, `v4-hole`, and the first page for post A, written under `all-changes` from the reduced copy of the record. A judge shown a page with three such sentences against the same page without them chose the clean one 8 times of 8. Between two different drafts the slips were remarked and did not decide (result 7).

14. **What was not held constant.**
    - *The writers' reasoning effort.* It is a setting of the profile a writer runs under. For the first batch it was not recorded. The reworded, held-back and finished batches ran at the middle level, set on the command line from the third repeat of the reworded batch on.
    - *The account.* The reworded batch's first two repeats ran on one account and its third on another. Each compared group of three drafts comes from one account.
    - *The office's instructions.* Every writer loaded the office's hooks and instructions, as any session of that office would. No writer ran without them.
    - *The method's path.* In the first batch the folder a writer was pointed at carried the version's name. Later batches use folder names that say nothing.
    - *A writer's own judges.* The method has a writer run judges of its own. Each writer chose how, and one finished run put a round of them through a judging script it found in the record, which signs in with the sealed rooms' token.

## Approaches ruled out

- **Judging a first draft from text made by a converter that is not checked against the draft.** A converter that drops lines written as raw Typst calls leaves a draft without its name line, employers, titles and dates, and a page judged whole beats a page judged without them on every full read. The conversion in use builds the page as a reader would get it and checks that every word of the draft is in the text shown.
- **Asking a writer "what you took the job to be".** Every writer's prompt ended with that question. Of 84 answers, 78 describe the advertised post and none the writer's own task. The question that works names the writer's own job.
- **The cold reader of the this-guy-aint skill as a gate for the method's text.** It objects to features any procedure for agents has, such as addressing its reader as an agent. It gives useful leads and cannot be passed.
- **An invented easy case as a test of drafting.** A candidate who supplies her own pitch for exactly the post draws a selling first draft from the baseline, and separates nothing.
- **Counting the advertisement's asks a page proves, as a score.** The page the candidate already had proved 6 of 14 and beat pages that proved 7 and 8. The count shows which asks a page leaves bare and does not predict the judges.
- **A stop rule that lets a later pass read only what changed.** A page went out whose last edits no reader had seen whole, with third-person slips in it.
- **Giving writers a reduced copy of the record.** It changed what a writer opened on. It was not why proofs were missing: the lines the judges wanted were in the reduced copy too.
- **Three drafts a text across many texts, before the draw is known.** Eighty first drafts were written before baseline drafts were set against each other. That control took 288 judges and showed that three drafts against three see only a large effect.
- **A follow-up question to every judge.** Each judge was asked afterwards whether anything in its room pointed away from the recruiter. The question cost more than the answer it followed, and the room's own record already showed what it asks. The follow-up turn is also not clean: in 19 of 583 rooms looked at, it arrived with context added by one of the office's hooks, which the turn of the choice never had. Every choice was made before that turn, so the counts stand, and nothing in this log is read from a follow-up.
- **Resuming a writer's session to ask it one question.** It costs about as much as the draft, because the whole session is read again. The question belongs at the end of the writer's own run.
- **Committing writers' rooms while writers run.** A room holds a copy of the record, and a commit of thirty rooms brought 92,000 files under the commit checks and stalled the machine. Rooms are committed after they are pruned.

## Interpretation, as speculation

- The hole step may work on the opening because it turns an open choice into a derivation: the writer no longer picks an opening, it reads the order off the advertisement. That the six opening sentences add nothing to it suggests that what matters is the derivation and not the stance.
- The body may resist the same move because "the most concrete thing on record" still leaves the writer to judge what is concrete enough, and nothing later in the method checks it. It may also be that the paired full read cannot see a difference of that size: nearly four comparisons in ten were decided by reading order.
- `h1-edit` changes almost no content and mostly changes mood, from statement to command. That it is the one version not to lose a full read may mean that how the text addresses the writer bears on the whole page, where a step added to one phase bears on the part of the page that phase writes. It rests on one batch, and its rule differences are confounded with its voice.
- The writers' answers suggest why announcing a stance does little. The method defines being done by its own files and its own judges, so a writer measures itself by those and names the employer's reply as something it cannot see. A stance sentence leaves that definition where it was.
- Truth and the opening pull apart on at least one page: the joined page won its opening with lines that said more than the record, and lost it when they were corrected. A version that wins openings has to be watched for how it wins them.
- The checks rewrite half the opening and improve the full read, and they do not catch a claim that goes past the record: every finished page had passed the method's own trace with such claims on it. A trace run by the writer of the page may read the page as its writer does.
- The hole step tells the writer that the top "shows the candidate filling the first holes", a clause to each. That is an instruction to assert fit. Its pages keep their lead when every unsupported claim is taken out of both sides, so the assertion is not the lead; whether the instruction makes a writer assert more is not settled by three pages a side.

## Which parts of the roadmap this round tested

`../ROADMAP.md` lists the lessons from selling that the series draws on. This round chose nine of them: A1 (the page wins the next step), A3 (the buyer's need before the pitch), B1 and C2 (the buyer's order, at the top), C1 (the kind a buyer files the candidate under), D1 (a concrete proof per claim), F1 in part (a reader who answers as the buyer), F2 (the seller's stance kept in view) and H1 (the whole text in a seller's voice). A4 entered only as one question to a reader, and D3 (checking protects a won deal) entered through the traces. The roadmap carries what each showed.

## What the round cost, and what it need not have

The owner asked of the round: "do we really have to use so many tokens?" It did not have to. The figures are what the runs themselves report, sums at API prices. The owner's own measure is a share of the weekly allowance, which nothing in the round measured; one account reached its weekly limit part-way through.

| Item | Runs | Reported |
|---|---|---|
| First drafts | 80, two of them set aside unjudged | 477 dollars |
| Finished pages | 16 | 216 |
| Questions put to writers afterwards | 9 | 74 |
| Judges' answers | 2,884 rooms | 95 |
| The follow-up question to each judge | 2,884 | 145 |
| Subagents | 33 | 30 |
| The running of the round itself | | not priced; 351 million tokens read again from its own context |

- The session that runs a round is its largest cost. Each tool call reads the whole of a growing context again. A subagent that reads, traces or counts and returns one screen costs one or two dollars.
- About a quarter of what the writers and judges cost bought the round's findings: the fairness tests, the baseline against itself, and the blind batches with their traces. The first batch of 45 drafts was not blind, and 16 writer runs were stopped before they finished.
- What follows for a round: the control before the versions; few texts; the session directs and subagents read; a step is one script that ends in one screen; no follow-up question is put to a judge until a room can be resumed clean; and a round is sized to end within the context of the session that runs it, which is the owner's stated preference.

## What the next rounds could test

The first three items are the shape agreed for round 2. Four limits of this round's evidence shaped it. No test here asks whether the candidate is called ahead of anyone else: a comparison asks only which of two copies of one person to pass on. The hole step's blind lead rests on one post and three pages a side. The judges' stated reasons are leads and not causes, since a judge who followed reading order named true differences too. And the joined page's win over its parents is a choice confirmed by the judges who made it.

- **Ranking among other candidates, on pages already written.** A third seat: the candidate's page in a pile of other candidates' pages, the judge saying whom it would call first, second and third. It is the owner's interest for round 2, and the first test to ask the series' own question. A pool of 92 CVs of senior people in AI, data, engineering and product, 72 of them whole and fit for a pile, is kept in the candidate's repository with an index that says nothing of any post. The seat has to pass its own controls before any page is read on it: a damaged copy falls, a page written for another post falls, the same page placed twice gets the same place, and a baseline page sits in the middle of the pile. Then the pages of the blind batches for posts A and D are placed, as written and as corrected to the record, with the page the candidate had and the joined page. No writer is needed.
- **Whether a page loses by keeping to the record.** The six finished pages corrected by their traces, placed in the pile beside themselves as written. In pairs the corrected pages kept the version's lead; what correction costs a page among other candidates is not known.
- **Then one written batch, few texts and finished pages:** the text at `e51412d3`, `v7-holes2` which is now the method, and one new lever that has first moved a seat when made by hand on a finished page. The body as need against proof comes before the first job listed, since the blind lead sits on the full read. Pages are written a few to a text at a time and judged, with a rule for stopping fixed before the first of them. About sixteen pages a text are needed for pairs to see an effect of the hole step's size four times in five.
- **A trace the writer does not run on its own page.** Every finished page passed the method's own trace with unsupported claims on it.
- **The voice of the whole text, tested cleanly.** `h1-edit` with its seven rule differences repaired, against the baseline in one batch.
- **What the writer takes its job to be.** A version that says what the job is and what tells the writer it is done in terms of the employer's reply. The question of result 1 has first to be shown to move with something.
- **Choosing among several pages.** The judges put the drafts of one text in one order every time, so choosing the best of several, or joining the best opening to the best body, may gain more than a wording does. It multiplies the cost of each application, and the pile's spread between pages of one text is its price and its gain in one number.
- **The check for one person.** As worded it lets a page wholly in the third person pass.
- **Modules.** The three reader's questions now written into versions' text lifted into module files, and a fourth written: what the reader takes the candidate for, looked for and did not find, and would hesitate over (in `v2-examine`, the sentence beginning "Last, from where the person filling the post stands"); the reader's own list of the employer's needs and where the page shows each (in `v4-hole`, `v7-holes2` and `v8-opening-holes2`, "Before it opens the page"); the check that the page speaks of the candidate in one person (in `v7-holes2` and `v8-opening-holes2`); and a line-by-line reader, not yet written, that says of each line whether the person hiring is more or less inclined to call.
- **Conditions as versions.** The writers' reasoning effort, and a writer without the office's instructions, each against the same text.
- **The candidate file.** Whether a file that states facts as "he" is where the third-person words come from, and whether two readings of one date in the record should be settled in the file before any writer meets them.
- **Other candidates.** Every finding of the round is one candidate's.

## The owner's words on the series

- On the series and what a round leaves: "you can say it's the sales-improvmeent-1 and we plan to do 1 all the way to 9 in the coming days (at which point sales improvement might be exhausted). each run produces a log and at your log, You can speculate what worked, and express the wish to see different CV being worked on to see the result difference, so that next agent can start working."
- On tone: "You must speak it in a discovery tone rather than in a infantilization tone ... speak like a scientist."
- On the two ways of working: "If we are making progressive change and we are locking down a version that we believe reasonably well, but still leave a bit of chance of regression, that if regression is detected, the next agent is feel free to roll back and find a good combination that works. Then we have a timeline-based method. Alternatively, if we are widely testing competing theories, we might have folder-based method." And: "I prefer the lab inside method repository".
- On the joined page: "since now we have a good CV, let's keep the work".
- On dropping a test: "if something depends on something else being true and it's no longer true, then it doesn't have to be tested anymore."
- On the judges' account: "I agree with peer's worry that my name will leak into the judge if we use the same account, because my name is in the plugin, and also that I happen to be the candidate in this case."
- On the next round: "I am curious of validating the test result by the second method of ranking our CV with comparables." On the pool for it: "some CV can be used for more than one purpose".
- On means: "I give you the all of the rest of the context and the unlimited use of Jethro agents and I'll check periodically." (Jethro agents are subagents the work is handed to.) He set no budget for a round in advance and no order among the wishes. On the size of a round: "I note that the over budget of 60% is not a huge deal. It happens all the time, but I still prefer that the next agent to be able to finish a shape that ends within its context."
- On what to explore next: "Not every dimension can be explored, but as any living creature, the direction that already showed signs of improvement should be explored first."
- His own ideas tested here: applying only half of the changes; the baseline with only the salesperson sentence; listing the holes and marking each change with the hole it serves; the `sell` and `check` marks drawn as a path, "any move towards selling should be upward, and any move towards checking should be rightward"; the whole text worded as a salesperson would word it.

The wish to see other CVs worked on and the wish to rank among comparables are his. The other wishes above, the rules for won, ahead and holds, and the rule that a reader's question is a module copied on release were set by the session running the round. He has not said he read the joined page. Two pairs of first drafts, unlabelled, are ready for him to say which page of each he would send, with the key kept apart; he has not yet chosen. The five questions the trace of the joined page leaves are his to answer.
