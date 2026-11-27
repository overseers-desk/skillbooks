# Roadmap: what selling has to teach HIRE, and what has been tested

A job application is a large sale to a committee, made in reply to a published requirement, with one unit to sell and the seller as the product. The lessons below are taken from the bodies of sales practice that fit that description. Each is something the method could make a writer do. A round of the lab picks some of them, writes each into a version of the method, and measures the pages that come out. Each round's worklog names the items it tested by the letters and numbers here.

## How the series is run

The work of a round is to find, by relentless experiment, the best way to bring the outcome. That has two parts. One is getting the judges to agree that a page is better. The other is correcting the judges where they do not behave as a person hiring would. Which route to take to either is for the session running the round to work out. The owner is not expected to supply step-by-step suggestions, and a question about how to run an experiment is settled by running one.

A version's record is read against what two drafts of the baseline give. Round 1 found that the judges tell two baseline drafts of one post apart about as firmly as they tell a version from the baseline: in 14 of 18 comparisons on the opening of the page and 10 of 18 on a full read. A batch therefore includes comparisons of baseline drafts with each other, and a version's count of comparisons won and lost is reported with the chance of doing as well by the draw alone. Three drafts against three baseline drafts can show only a large effect.

A round records the conditions its writers ran under: the account, the reasoning effort set for the writers' model, the office's instructions loaded or not, and the state of the candidate's record. Round 1 found the effort to be a setting of the profile a writer runs under, different between two accounts on one machine, and not recorded for its first batch.

## The judges, and what they may know

A judge is a fresh session in a sealed room: a new home and settings folder, signed in with a token of an account that is not the office's. It is told it is the person the post reports to and is given only the advertisement and the pages. The owner decided on the sealed room: his name is in the office's plugin and he is the candidate, so a judge on the office's account can learn whose page it is. On the researcher's computer the token is kept at `~/.jail-claude-token`. That file belongs to one computer and is not guaranteed to exist. The owner allows a profile other than a session's own only for a reason stated to him. For the judges he has given it; any other use needs its own.

What keeps a judge in the seat is the decision it is asked to make, whom to call. Shown two versions of one page, most judges guess that one applicant is trying two versions, and they still decide whom to call. Each judge is asked afterwards whether anything suggested the note came from someone other than the recruiter, and its answer is kept with its choice.

What round 1 measured of these judges, eight to a comparison with half reading each page first:

- Shown the same page twice, every judge chose the copy it read first.
- Shown a damaged copy of a page, or a page written for another post, they chose the sound page 8 to 0.
- Shown two different drafts, they lean to the page read second. On a full read, 14 of 36 comparisons came out 4 to 4 in that way, each judge naming true differences in favour of the page it had just read.
- They rank and do not grade: more than half of all comparisons come out 8 to 0.

These properties are worth measuring again whenever the way a judge is run or briefed changes, and for any new seat. A seat that ranks the candidate's page among other candidates' pages has had no fairness test.

## The lessons

| Item | The lesson | Tested in | How | What was found |
|---|---|---|---|---|
| A1 | Each step sells only the next step: the page is there to win the first conversation | round 1 | `v1-opening`; the ready-to-send rule in `v2-examine` | alone, within what the draw gives; added to the hole step it added nothing that could be measured |
| A2 | The first reader can refuse a candidate and cannot hire one; the one who decides reads later, and each needs something different to say yes | | | |
| A3 | A buyer buys an answer to a need they have stated: find the need before the pitch (the holes) | round 1 | `v4-hole`, `v6-say-hole`, `v7-holes2`, `v8-opening-holes2` | the holes in the employer's order, made to dictate the top, improved the opening on three posts in a batch that was not blind; written blind, the version led both seats at the first draft on one post and the full read of the finished page, and led only the full read on a fourth post; with every unsupported claim taken out of both sides its finished pages kept the lead on a full read; put into the method at the end of round 1 |
| A4 | The buyer's objections, not the seller's fears: list what this buyer will hold against the candidate, and answer each on the page or leave it for the conversation | round 1, in part | one question to the reader with the advertisement, in `v2-examine` | not separable; untested as a step of its own |
| B1 | Tender practice: answer each stated requirement in the buyer's words and order, with one proof beside it, in a grid drawn up before any sentence | round 1, for the top | `v7-holes2`, `v8-opening-holes2` | order at the top works; the grid for the body is untested |
| B2 | What this candidate offers that the others being put forward cannot | | the baseline asks it in its first phase | |
| C1 | The buyer files a candidate under a kind within seconds; choose the kind | round 1 | every comparison on the opening; the joined page; the judges' stated reasons | the first lines decide the opening, and judges read the first job listed as what the candidate is now; a page joined from the best top and the best body beat both parents |
| C2 | Order follows the buyer's interest, on the page and inside each post | round 1, for the top | `v7-holes2`, `v8-opening-holes2`; the judges' stated reasons | holds for the opening, where the order of the top is the reason judges most often give against a page; untested below it |
| D1 | A concrete proof for each claim, of a kind a stranger could check | round 1 | "the most concrete thing on record" in `v7-holes2`, `v8-opening-holes2`; the judges' stated reasons | on a full read judges cite a mechanism or a figure more than anything else; the instruction showed no effect there that can be told from the draw |
| D2 | Standing is a selling point for any buyer: who backed the candidate, whom they worked for, the size of what they ran | | | |
| D3 | Proof is for closing, and checking protects a won deal: a claim matters because it will be tested in the conversation and by a referee | round 1, on one page | the joined page for post A, corrected by a trace to sources | the lines that had won its opening were the ones past their source; corrected, the page lost the opening 0 to 8 and won the full read 6 to 2; all six finished pages traced by outside readers carried unsupported claims that the method's own trace had passed, 9 on three baseline pages and 16 on three pages of the hole version |
| E1 | Know what there is to sell: the candidate's strongest results, and why earlier employers and clients chose them | | | |
| F1 | Feedback as a customer gives it: would call or would not, what was looked for and not found, what would stop them, line by line as well as overall | round 1, in part | questions to one reader in `v2-examine` and `v4-hole` | not separable; the line-by-line reader is unwritten and the checking phase unstudied |
| F2 | The seller's own stance kept in view: saying at each step that one is selling, and marking each change as made to sell or to check | round 1 | `v3-say`, `v6-say-hole`, `all-changes`; nine writers asked afterwards what their own job had been | the reasons writers gave moved from one selling reason in twenty to one in three, on one run; no effect on the page shown; under every wording tried a writer says its job is carrying the method through |
| G1 | The buyer's answer is the only verdict: record what comes back after a page is sent | | belongs to the second stage, the application | |
| G2 | Some posts no page can win; deciding whether to apply comes first | round 1, observed | outside the method, which starts from a post judged worth answering; the judges' stated reasons | what judges looked for and found on neither page of a pair was in the candidate's record and not in the method: the size of organisation led, named technologies, the employer's industry |
| G3 | The route outweighs the wording: a page that arrives through someone inside does better than one that arrives cold | | belongs to the second stage | |
| H1 | The whole text of the method in a seller's voice, with every rule kept | round 1 | `h1-edit` and `h1-rewrite`, each on nine first drafts; readers of the two texts | readers cast as sellers believed neither text; `h1-edit`, which mostly turns statements into commands, lost no full read of nine, the furthest any full-read record lay from the draw; `h1-rewrite` was behind on one post; seven and two of their rules differ from the method's; neither changed what a writer takes its job to be |

The letters group the lessons by where they come from: A, selling to large accounts; B, tender and proposal practice; C, positioning; D, proof and risk; E, discovery of what is for sale; F, feedback and the seller's stance; G, the pipeline around the page; H, voice.

## What the results so far suggest for the order of work

The owner's steer: "the direction that already showed signs of improvement should be explored first." One direction has shown it, the hole step, and written blind its lead sits on the full read of the finished page. It is in the method from the end of round 1. What no test has yet asked is whether the candidate is called ahead of anyone else.

So round 2 is shaped in two stages, each sized to end within one session. The first writes nothing: it builds the ranking of a page among other candidates' pages, which the owner asked for, proves it on controls, places the blind batches' pages in it as written and as corrected to the record, and tries the next lever by hand on a finished page. The second is one written batch of finished pages under few texts, approved on the first stage's numbers. The round-1 worklog gives the steps and the objections that shaped them.

A round costs most in the session that runs it, then in writers, then in judges. The control comes before the versions, reading goes to subagents, and a follow-up question goes to one judge in eight.

Beyond that: B1's grid is the hole step applied to the body, and is the first lever to try. A4 and E1 would change what there is to put in the grid. H1 has a lead in the edited text with its rules repaired. F2 has one in defining the writer's job by the employer's reply. D3 has become a need: a trace that the writer of the page does not run. D2 is small and could ride with any of these. A2 needs a way to show a page to the two readers separately. G1 and G3 wait for the second stage.
