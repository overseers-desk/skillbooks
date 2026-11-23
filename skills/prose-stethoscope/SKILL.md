---
name: prose-stethoscope
description: Before prose goes to its reader, hear where readers stumble or stop trusting it, sentence by sentence: a paragraph that leaves them waiting, a missing link, a total, a defensive or glib line. Further modules, run when named, hear faults above the sentence in a CV or other text read to size up its author: an author who sounds junior or unsure, a line the reader has no use for or draws the wrong conclusion from. Scored and explained, no fixes. Triggers: prose-stethoscope, stethoscope, listen to this draft.
argument-hint: <draft-path> [--reader "<who reads it and what they have read>"] [--module <name or path>]... [--fact <name>="<one sentence>"]... [--runs N]
---

# prose-stethoscope

A draft can be correct in every sentence and still lose its reader: a paragraph ends on something the next one never takes up, a sentence leans on a link the page never gives, a claim is stated as a total, with no exception allowed, that the passage does not support, a line answers an objection nobody raised. The writer cannot hear these, because the writer holds what the page leaves out. This skill puts fresh readers in front of the draft, model calls that hold nothing but the draft and a line saying who reads it, and reports, sentence by sentence, where a share of readers would stumble or start to doubt it.

It reports and does not prescribe. An agent handed a fix tends to apply it as an order, whether or not it helps the text, and a flag cleared by deleting the flagged sentence loses whatever the sentence carried. So each row of its output says what a reader meets at one sentence and why, and leaves the change, if any, to the writer, who knows what the sentence is for.

## Procedure

1. The draft is a file on disk, paragraphs separated by blank lines. A first line starting with `#` is read as the title and skipped. Each list item, table row (cells joined by semicolons) and later heading is read as a unit of its own, so output rows point at the right line in a CV or a bulleted page. Fenced blocks are skipped. Markup that a template turns into words, such as a macro wrapping a job title and its dates, is read as it stands. Where a draft has such lines, run the script on a copy in which they are replaced by the words the reader will see.
2. Run `python3 ${CLAUDE_PLUGIN_ROOT}/skills/prose-stethoscope/stethoscope.py <draft> --reader "<reader line>"`. The reader line says who reads the text and what they have read before it, for example what earlier chapters or messages they hold. Scores are shares of that reader, so the line moves them, in every module but faults, whose prompt takes none. Without it the reader comes to the text fresh.
3. Each question put to the readers is a module: one file holding a prompt, run as a pass of its own on `claude-opus-5-5` through a stripped `claude -p` call (no tools, a one-line system prompt, no settings), the conditions the modules were measured under. Two run when none is named:
   - **flow** (`flow.md`): forgotten beat, meaning a paragraph that ends on something the next never takes up; unanchored reference; missing link; out of order; repetition; contradiction; purpose unclear; register shift; long dependency. Where contradiction scores 5 or more the reader says whether the conflict is real or only apparent and why, without new wording.
   - **faults** (`faults.md`): a total the passage does not support, a defensive line answering a charge nobody made, a glib line, among them a pair of clauses shaped as a saying ("X is where …, and Y is how …"), telling the reader what any adult knows, the author lowering their own standing.

   `--runs 3` repeats each module's pass, which is worth it when a decision rests on one row. The calls, one for each module and run, go six at a time and take a minute or more each, and the rows print only when all are done, so run the script in the background.
4. The script prints one table. Its first line is the header: `sentence` (`paragraph.sentence`, where each unit of step 1 counts as a paragraph), `run`, a column for each module that ran, `why` and `text`. A module's header gives its name and, after the colon, what it scores, in order: `faults:total,defensive,glib,explained-to,lowered-standing`. Its cell holds the scores for that sentence in the same order, comma-separated, with `*` on a score of 4 or more, and is empty where the module returned nothing. A score is roughly how many intended readers in ten would meet the problem there. 4 is the cut-off: a score with a `*` is a stumble, and this page calls it a flag. `why` gives each module's reason, led by its name. With `--runs`, a sentence has a row for each run, and the run number pairs different modules' passes by order only. A row whose sentence is `-` and whose cell reads `no complete reply` is a call that failed; run that module again.

## Modules for what lives above the sentence

Some faults are not in any sentence's wording. They are in what kind of author the text shows, what it spends its lines on, and what it lets the reader conclude. These modules ask about them. Each still scores sentence by sentence, because a reader meets the fault somewhere. Give each its own `--module`. Those named are the ones that run, so name `flow` and `faults` as well to keep them. Their files sit beside the script, as `${CLAUDE_PLUGIN_ROOT}/skills/prose-stethoscope/<name>.md`.

| Module | What the reader meets at the sentence | Fact it needs |
|---|---|---|
| `height` | The author stands below their own subject: still finding it out, guessing at it, or taking from others what the reader expects them to know for themselves. | none |
| `level` | The author is placed lower than the standing the document claims for them, by what they chose to report of their own part. | `taken-for`: whom the reader should take the author to be |
| `learning-path` | The reader is given the story of how the author came to know or do a thing, where they wanted what the author knows or did. | none |
| `work` | The sentence's subject is something other than what the reader came for, and nothing later uses it. | `reading-for`: what the reader is reading the text for |
| `must-not-conclude` | The sentence leads the reader toward a conclusion the author does not want drawn. Its reason names the conclusion. | `must-not-conclude`: the conclusions the author does not want drawn |

A fact is one full sentence, each given with its own `--fact`, as in `--fact taken-for="The author is to be taken for …"`. The facts are the author's. Take them from what the author has told you, and ask for any that is missing before running; a module run without its fact stops and names it. What a fact says decides what its module hears. `must-not-conclude`, told that the reader should form no view of where the author lives, scored each line of a CV that pointed to any country. Told that the reader should not conclude the author lives outside two named countries, it scored only the lines that pointed elsewhere.

Which modules suit a text:

- **A CV, or another text read to size up its author:** `flow`, `faults` and all five.
- **An essay or a chapter:** `flow`, `faults` and `height`, and those three only. The other four were tested for a text read to size up its author, and the two that were also tried on essays misled there. `learning-path` scores a story the author chose to tell: an essay may tell how its author learned a thing, as a writer who now knows it, and an editor who worked through those rows would delete the story. `work` scores a credential given once in passing, which the author may have put there to earn the standing to speak, and it missed the one fault it was aimed at. So the skill has no answer to whether anything in an essay should go. Where an author asks that of an essay, say so, and leave `work` and `learning-path` off. `height` asks a different thing, whether the author knows the subject now, and a story of once not knowing drew nothing above 2 from it.

A module of your own is a file in the form of the shipped ones: front matter with `columns:` naming what it scores, then the prompt, with `{text}` where the draft goes, `{reader}` for the reader line, and a `{name}` for each fact it needs. Give its path to `--module`. The script reads the TSV that the shipped prompts ask for, so copy from one of them the paragraph that begins "Write a TSV and nothing else", and make its count of scores match your `columns:`.

## Reading the rows

- Read the reason before the sentence number. Readers sometimes count a short sentence together with the one before it, so a row can name the sentence next to the one its reason describes; the printed text shows which.
- A forgotten beat can land on either sentence at the join between two paragraphs: on the line that opens something, or on the next paragraph's turn away from it.
- Judge each row against what the sentence is for before changing anything. A row is a reader's report, not a verdict: the right response is sometimes a bridge, sometimes a cut, sometimes nothing, and a change made only to clear the flag tends to remove what the sentence carried. A total flagged where the passage shows less can be met by showing more as well as by claiming less.
- On a CV, flow's repetition scores the body for repeating the summary, and its unanchored reference scores names the document has not introduced. A CV is built that way, so most of those rows report its form, and the ones worth the author's attention are the few that would trouble this reader.
- `level` and `work` can score most of the sentences under one job in a CV. Where they do, the reader stumbles on what that part of the CV is spent on, and rewording its sentences one at a time will not clear the rows.
- `height` scores at the cut-off a sentence that leans on another voice: one that cites press for the author's own work, reports research in the passive, hands a point to a named authority, or says what other people must think. Where the author means that voice as support, leave the sentence as it is.

## What it does not hear

A draft that draws no flag has not been cleared of these.

- Whether a passage serves its purpose. A smooth sentence that leads with the outcome where the point is the cause scores nothing.
- Where a passage stands. An analogy that comes before the author's own account of the matter, and so reads as the way the author worked the matter out, drew no row from `height` in three variants of its prompt, one of which invited a row for a run of sentences. A chapter that opens on a scene before its reader has the problem drew none from `work` when that was tried. `height` may still score a sentence elsewhere that makes the placing a fault, such as one disowning the author's knowledge.
- Faults that live in a paragraph or a whole passage: short-sentence rhythm, the cadence and diction of machine-written prose, the order of an argument.
- A sentence that is gone. Rows land on sentences, so a cut that lost something the text needed draws nothing.
- An example that is not introduced as one and leans on the sentence before through a word such as "this" ("A person who goes to work knows this without being told."). flow scores it about 3.
- A forgotten beat, in a single run. It sits on the cut-off, at 3 or 4 on the passage flow was tuned on, and `--runs 3` hears it more often.
- A reader talked down to. In faults, telling the reader what they already know reaches 4 rarely; read its 3s.
- A senior author's pride in still doing a junior's work. `level` scored such a line 3 where its author objected to it; read its 3s.
- Small asides. `work` is a quiet reader: it hears a line whose subject is something else, such as a venue's prize in the CV of the person who ran it, and lets lesser trivia pass.
- A mild case of telling the route. `learning-path` scores a plain story of learning a skill 8, and a line that names a method by where it came from 3 to 5; read its 3s.

## Where the evidence is

`labs/prose-stethoscope/2026-11-reader-stumble-scores/` in the skillbooks repository holds the test texts, every criterion wording tried, the runs, and the matrix of each reader against what each text should and should not raise. The modules above the sentence were tested on one author's CV and essay chapters, for which his objections, and what he kept on purpose, were on record. The CV and one whole chapter are private, so the lab gives their results as counts. Four other people's CVs were run to check that the modules do not score a CV for being one, and that is the only evidence from outside his writing. The lab also holds what was tried on essays and is not shipped: a form of `learning-path` whose reason says what the passage is doing, and `work`'s results on chapters.
