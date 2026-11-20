---
name: prose-stethoscope
description: Before prose goes to its reader, hear where readers stumble or stop trusting it, sentence by sentence: a paragraph that leaves them waiting, a missing link, a total, a defensive or glib line. Scored and explained, no fixes. Triggers: prose-stethoscope, stethoscope, listen to this draft.
argument-hint: <draft-path> [--reader "<who reads it and what they have read>"] [--runs N]
---

# prose-stethoscope

A draft can be correct in every sentence and still lose its reader: a paragraph ends on something the next one never takes up, a sentence leans on a link the page never gives, a claim is stated as a total the passage does not support, a line answers an objection nobody raised. The writer cannot hear these, because the writer holds what the page leaves out. This skill puts fresh readers in front of the draft and reports, sentence by sentence, where a share of readers would stumble or start to doubt it.

It reports and does not prescribe. An agent handed a fix tends to apply it as an order, whether or not it helps the text, and a flag cleared by deleting the flagged sentence loses whatever the sentence carried. So each row says what a reader meets at that sentence and why, and leaves the change, if any, to the writer, who knows what the sentence is for.

## Procedure

1. The draft is a file on disk, paragraphs separated by blank lines. A first line starting with `#` is read as the title and skipped. Each list item, table row (cells joined by semicolons) and later heading is read as a unit of its own, so rows point at the right line in a CV or a bulleted page.
2. Run `python3 ${CLAUDE_PLUGIN_ROOT}/skills/prose-stethoscope/stethoscope.py <draft> --reader "<reader line>"`. The reader line says who reads the text and what they have read before it, for example what earlier chapters or messages they hold; scores are shares of that reader, so the line moves them. Without it the reader comes to the text fresh. The same line carries what the reader should know about the kind of text: a CV whose summary restates its experience section on purpose, say, so that repetition there is read as design. `--runs 3` repeats each pass, which is worth it when a decision rests on one flag.
3. The script runs two passes on `claude-opus-5-5` through stripped `claude -p` calls (no tools, a one-line system prompt, no settings), the conditions the passes were measured under:
   - **flow** (`flow.md`): forgotten beat, unanchored reference, missing link, out of order, repetition, contradiction, purpose unclear, register shift, long dependency. Where contradiction scores 5 or more the reader says whether the conflict is real or only apparent and why, without new wording.
   - **faults** (`faults.md`): a total the passage does not support, a defensive line answering a charge nobody made, a glib line, telling the reader what any adult knows, the author lowering their own standing.
4. Each output row names the pass, the run, the sentence (`paragraph.sentence`), every score of 2 or more with `*` on those of 4 or more, the reader's reason, and the sentence itself. A score is roughly how many intended readers in ten would meet the problem there; 4 or more is a stumble.

## Reading the rows

- Read the reason before the position. Readers sometimes count a short sentence together with the one before it, so a row can name the sentence next to the one its reason describes; the printed text shows which.
- A forgotten beat can land on either sentence of a paragraph join: on the line that opens something, or on the next paragraph's turn away from it.
- Judge each row against what the sentence is for before changing anything. A row is a reader's report, not a verdict: the right response is sometimes a bridge, sometimes a cut, sometimes nothing, and a change made only to clear the flag tends to remove what the sentence carried. A total flagged where the passage shows less can be met by showing more as well as by claiming less.

## What it does not hear

- Whether a passage serves its purpose. A smooth sentence that leads with the outcome where the point is the cause scores nothing.
- Faults that live in a paragraph or a whole passage: short-sentence rhythm, opening on a scene before the problem, the order of an argument.
- An example begun without a marker when a word links it back to the sentence before ("this" in "knows this"): scored about 3, under the cut-off.
- Telling the reader what they already know reaches 4 rarely; read its 3s.
- The flow break that opens many of these measures sits on the cut-off: the flow pass scores the original case 3 or 4. A single run can miss it; `--runs 3` hears it more often.

## Where the evidence is

`labs/prose-stethoscope/2026-11-reader-stumble-scores/` in the skillbooks repository holds the test texts, every criterion wording tried, the runs, and the matrix of each reader against what each text should and should not raise.
