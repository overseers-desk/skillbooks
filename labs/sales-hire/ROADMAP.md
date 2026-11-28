# Roadmap: what selling has to teach HIRE, and what has been tested

A job application is a large sale to a committee, made in reply to a published requirement, with one unit to sell and the seller as the product. The lessons below are taken from the bodies of sales practice that fit that description. Each is something the method could make a writer do. A round of the lab picks some of them, writes each into a version of the method, and measures the pages that come out. The table's third column names, for each lesson, the code of round 1's test that bears on it.

## How the series is run

The work of a round is to find, by relentless experiment, the best way to bring the outcome. That has two parts. One is getting the judges to agree that a page is better. The other is correcting the judges where they do not behave as a person hiring would. Which route to take to either is for the session running the round to work out. The owner is not expected to supply step-by-step suggestions, and a question about how to run an experiment is settled by running one.

Rules of method that round 1 paid for:

- Measure by rank among other candidates' pages, the judge giving the whole order and the rivals being the nine nearest the page. Asking for three calls from ten, and drawing rivals by level, each gave no measure.
- Judge the examined page, the one that would be sent. A first draft's rank says little of it.
- Write the control in the same batch: pages of the unchanged text, enough to know what chance gives. The judges prefer one of two drafts of one text about as firmly as one text over another.
- Fix what counts before a page is judged.
- A test names the commit of the method and the commit of the candidate file it ran on. Before a paid test starts, say which changes are in it.
- Check that the candidate file holds the facts a test relies on before the test runs.
- Writers run blind: the folder a writer is pointed at says nothing of the version. A round records the conditions its writers ran under: the account, the reasoning effort set on the command line, the office's instructions loaded or not, and the state of the candidate's record.
- A change made by hand to a page proves nothing until the method carries it and a writer has run under it.
- Ask a judge nothing afterwards. Put a question to a writer at the end of its own run, and name the writer's own job in it.
- The session directs; subagents and scripts write, read and count, and a step ends in one screen.
- Writers' rooms hold a copy of the candidate's record: they stay outside this repository.

The owner's preference on a round's size: "I still prefer that the next agent to be able to finish a shape that ends within its context."

The series keeps one way of doing a thing. The owner's words: "We have 2 ways to do the same thing, which is not allowed. So one has to die."

## What a round is

A round tries changes to what the series keeps, and shows what each did by running the changed thing as it will be used. What the series keeps is whatever a later round starts from: the method's text and its modules, the way pages are judged, the tools both need. This section says what makes a piece of work a round, whatever it tests. It holds for every round and names no subject for any.

A round:

- **Starts from what exists.** Work done before the first round belongs to the first round, and work a round rests on belongs to that round, its code included. So before a round chooses what to do, it reads the earlier rounds' logs and the tools and results they point to, wherever those sit. It builds on what the owner took into the methodology from the round before, or, where he took nothing, on the methodology as it stands.
- **Names each dimension before it is tested.** A dimension is something that can be set more than one way and is expected to change the outcome the series is for. Each is stated as a change to one of the things the series keeps, with what would count as an improvement and how it will be seen, fixed before the result is read. A dimension already tried is taken up again only for a stated reason: something different in the change, or in how it is tested. A change to the judging is a dimension like any other: what would count as better judging is stated first, and the changed judging is shown against the judging it replaces on that count.
- **Carries each change through the whole chain with no hand in it.** The changed thing is used as it will be used when nobody is watching, and the outcome is whatever the chain then produces. A change made by hand to an outcome is a probe inside a round.
- **Counts an improvement only when the methodology carries it.** The owner's words: "The methods that I discovered to improve the outcome, but not integratable into methodology. is considered not achieved improving something because I'm not going to hand edit everything." So for whatever is found to improve the outcome, the update to the methodology exists, it is applied with nobody doing it by hand, and the methodology run unattended reproduces the gain. A gain the runner made by hand and could not bring into the methodology, after real attempts, is logged as not achieved. Where the dimension is the judging, what has to carry the improvement is the judging as the series runs it.
- **Measures against what it started from.** The outcome under the change is set beside the outcome without it, produced under the same conditions, and read against how much two outcomes of the unchanged thing differ.
- **Settles each dimension.** At its end each change is kept, dropped, or left open with what would settle it. A thing is kept on what was fixed, before the result was read, as counting for an improvement; a later round may overturn it.
- **Ends ready for release.** What a round kept can go into the methodology, and a new version be released, by mechanical work alone on the owner's decision. His words: "if testing are needed before release, then it's a sign that the round is not done."
- **Aims to improve something.** A round is planned so that it can end with at least one improvement the methodology carries. A round in which nothing is kept is still a round if every dimension was carried through and settled; it has not succeeded, and says so.
- **Leaves the next round able to start.** Its log opens with the dimensions considered, which were tested, the outcome of each, how large each improvement is, and what the round cost. The log, the data and the round's rows in this roadmap point to every tool and earlier result a newcomer would need, wherever those sit, and all of it is committed and pushed.

Work that is not a round, and is folded into the round it serves:

- measuring, re-measuring or checking what an earlier round produced, where nothing the series keeps is changed;
- building or rebuilding a tool, a measure or a script, where no statement was made of what it would improve and how that would be seen;
- a change made by hand to an outcome, however well it scores;
- an experiment already made, made again without a stated reason;
- any shape that leaves the thing to be improved out of the run, whatever it saves.

The test of a plan for a round, before it is put to the owner: which of the things the series keeps will be different when this is done, and what will have been run, unattended, to show it is better?

The features above are taken from round 1: lessons named, each written into a version of the method, writers run under each version and under the unchanged text, the pages judged, each version settled, and a log left with its data.

## The judges, and what they may know

A judge is a fresh session in a sealed room: a new home and settings folder, signed in with a token of an account that is not the office's. It is told it is the person the post reports to and is given only the advertisement and the pages. The owner decided on the sealed room: his name is in the office's plugin and he is the candidate, so a judge on the office's account can learn whose page it is. On the researcher's computer the token is kept at `~/.jail-claude-token`. That file belongs to one computer and is not guaranteed to exist. The owner allows a profile other than a session's own only for a reason stated to him. For the judges he has given it; any other use needs its own.

What keeps a judge in the seat is the decision it is asked to make, whom to call. A judge's room is checked from its own record: nothing but the note was sent before it chose, no hook ran and no tool was used. Round 1 also put a follow-up question to each judge after its choice. That turn is not clean: in about one room in thirty it arrived with context added by the office's hooks. The machine's managed settings turn the office's plugins on for every session, a room's safe mode does not switch them off, and in some rooms they have been installed into the room's own settings folder by the time of a second call. Nothing is read from a follow-up until a room can be resumed clean.

What round 1 measured of these judges:

- In pairs, eight to a comparison with half reading each page first: shown the same page twice, every judge chose the copy it read first; shown a damaged copy, or a page written for another post, they chose the sound page 8 to 0; and they tell two drafts of one text apart about as firmly as two texts.
- Ranking a page among nine other candidates' pages and giving the whole order: the same page ranked four times stayed within three quarters of a rank, so one page's rank is uncertain by about 0.3; a page written for another post fell four ranks; a copy with its figures and mechanisms made general fell a rank and a half; a generic summary over an unchanged body did not move.

These properties are worth measuring again whenever the way a judge is run or briefed changes, and for any new seat.

## The lessons

| Item | The lesson | Tested in round 1 | What was found |
|---|---|---|---|
| A1 | Each step sells only the next step: the page is there to win the first conversation | `first`, as `v1-opening` | in pairs on first drafts, within what chance gives; never ranked among other candidates |
| A2 | The first reader can refuse a candidate and cannot hire one; the one who decides reads later, and each needs something different to say yes | no | |
| A3 | A buyer buys an answer to a need they have stated: find the need before the pitch | `examined`, `placement`; inside the final method | as a rule that the employer's needs dictate the top, its pages led in pairs on one post and showed no lead among other candidates on two; it is in the method as an item of the brief with no rule for the page, at the owner's requirement that one selling framework be applied, and tested only together with the other changes |
| A4 | The buyer's objections, not the seller's fears: list what this buyer will hold against the candidate, and answer each on the page or leave it for the conversation | `v12-to-v14`, with B1 and D2 | not separable; see B1 |
| B1 | Tender practice: answer each stated requirement in the buyer's words and order, with one proof beside it, in a grid drawn up before any sentence | `v12-to-v14`, as `v12-body` | its four examined pages rank a third of a rank ahead of the text it was written on, inside the spread between pages of one text, and none of the four does as the version asks, so the checks undo it |
| B2 | What this candidate offers that the others being put forward cannot | no | |
| C1 | The buyer files a candidate under a kind within seconds; choose the kind | `v12-to-v14`, as `v13-first-post` | a heading over the first post listed: four pages of four carry it and they rank 0.8 behind; `v9-leads` was written and never judged |
| C2 | Order follows the buyer's interest, on the page and inside each post | `v12-to-v14`, as `v13-first-post` | see C1; `v10-leads-stays-out` was written and never judged |
| D1 | A concrete proof for each claim, of a kind a stranger could check | `placement`, `j0` | a copy with its figures and mechanisms made general falls a rank and a half among rivals; a page without its most cited fact falls half a rank; a generic summary over the same body does not move |
| D2 | Standing is a selling point for any buyer: who backed the candidate, whom they worked for, the size of what they ran | `v12-to-v14`, inside `v12-body` | not separable; see B1 |
| D3 | Proof is for closing, and checking protects a won deal: a claim matters because it will be tested in the conversation and by a referee | `examined`, `placement`; `v12-to-v14`, as `v14-outside-trace` | every examined page carried one to six claims past the record that the method's own trace had passed; corrected to the record, the pages keep their standing; a trace made by a fresh agent ranks about a place behind and costs two and a half times as much |
| E1 | Know what there is to sell: the candidate's strongest results, and why earlier employers and clients chose them | no | |
| F1 | Feedback as a customer gives it: would call or would not, what was looked for and not found, what would stop them, line by line as well as overall | no | |
| F2 | The seller's own stance kept in view: saying at each step that one is selling, and marking each change as made to sell or to check | `first` as `v3-say`, `first-examined`, `reworded`, `records-read` | the salesperson sentence, in pairs on first drafts, within what chance gives; under three texts, eight of nine writers said their job was carrying the method through; in one run under a text with the salesperson sentence and each change marked sell or check, 11 of 34 changes were to sell, against 2 of 40 in a run without them; of 301 changes made to pages after the first draft, 245 were to check and 18 to sell |
| G1 | The buyer's answer is the only verdict: record what comes back after a page is sent | no; belongs to the application | |
| G2 | Some posts no page can win; deciding whether to apply comes first | `ladder`, `b2-33dd2626`, observed | the page the candidate had stands 6th of 31 in the pool for one post and 9th of 31 for another; on ten real applications the method's pages rank from 1.00 to 4.88 |
| G3 | The route outweighs the wording: a page that arrives through someone inside does better than one that arrives cold | no; belongs to the application | |
| H1 | The whole text of the method in a seller's voice, with every rule kept | `reworded` | neither of two rewordings changed what a writer takes its job to be; no page under them was ranked among other candidates, and neither is in the method |

The letters group the lessons by where they come from: A, selling to large accounts; B, tender and proposal practice; C, positioning; D, proof and risk; E, discovery of what is for sale; F, feedback and the seller's stance; G, the pipeline around the page; H, voice.

## What round 1 leaves for the order of work

The owner's steer: "the direction that already showed signs of improvement should be explored first."

The method as round 1 changed it ranks 0.34 better than the pages written before the round over eight posts, with a standard error of 0.25. The changes are three to the text (repeated statements said once, what the employer needs done as an item of the brief, the candidate file as the writers' record) and the folder's name, `sales-hire`; they were not told apart. The gain is where the old page stood low: four of the five that ranked 3.0 or worse gained three quarters of a rank or more, and neither of the two that ranked better than 2.0 gained.

The selling frame the series was begun for is in the method since 29 November 2026, and round 2 ranks CVs written under it. It first stood in the text for two hours on 27 November (commit `e16b5f63`), was tried in pairs on first drafts, where it did not stand clear of chance and which cannot show rank, and was taken out against the owner's wish. Round 1's log has the account under "The selling frame".

Choosing among several pages is the one change tried in round 1 that was shown to move rank: in four sets of four examined pages the page that won its set's pairs ranked 0.62 better than its set's mean, and an agent following `v11-several` chose that page every time. Its price is one writer for every page written. No rewording of the text has bettered, among other candidates' pages, the text it was written on.

A page's rank is uncertain by about 0.3 and pages of one text differ by about a rank, so a test of one page a post shows only an effect near a full rank.

`round-1/2026-11-27-WORKLOG-sales-improvement-1.md` holds the round as one experiment. `round-2/` holds round 2, which ranks CVs under the selling frame, and `round-2/PLAN.md` lists ideas no page has been judged under.
