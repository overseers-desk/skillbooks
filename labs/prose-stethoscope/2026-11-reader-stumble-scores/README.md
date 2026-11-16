# reader-stumble-scores

A cold reader that scores every sentence of a text for the places a reader stumbles, including a paragraph that ends by opening something the next paragraph drops.

## Problem

AI writes sentences that read well one by one, and joins between them that skip a beat a human reader feels. The case this lab is built on comes from the chapter "Play for the goal" of the essay *Nobody hires the AI*. A paragraph ends on a model's answer, "Asked why, the model said the numbers did not match, so it checked them.", and the reader waits for the author's comment on it. The next paragraph names the chapter's first pillar instead. The session that wrote the chapter did not see the break. The lab looks for a reader that does, without flagging sentences that read smoothly.

## The reader

Prompt 003 with format 006, on `claude-opus-5-5`. The reader is told who reads the text and what they have read before, then scores each sentence 0 to 9 on nine kinds of stumble and answers in the TSV that `TSV-FORMAT.md` describes. A score of 4 or more is a stumble. The forgotten beat counts at 4 or more on either sentence of a paragraph join, since readers place it on the sentence that sets something up as often as on the one that turns away.

What it does:

- It catches the hiccup in the chapter's opening (`texts/001.md`). It goes quiet once the join is repaired, by a bridging sentence (`texts/002.md`) or by turning the pillar sentence into a transition (`texts/003.md`). It leaves alone a question the text answers on purpose two paragraphs later (`texts/004.md`). Every rule-1 wording that catches the hiccup asks whether the next paragraph takes up what a paragraph's last sentence opens; wordings that ask whether the writer forgot something miss it.
- Across runs it flags the same other problems: references with nothing behind them, jumps between paragraphs, tangled sentences, and contradictions, each of which it says is real or only apparent.

What it does not do:

- Its catch sits on the cut-off. The hiccup scores 4 and the deliberate deferral 3. Every change to the reader tried so far, adding a criterion or rewording one, has moved the hiccup down to 3 or the deferral up to 4, so a change is judged on both before anything else.
- It misses a case that starts without being marked as an example when a word links it back, as in "A person who goes to work knows this without being told." It catches the same fault without the link ("A company found that…") in about one run in three.
- It measures smoothness, not purpose. A smooth sentence that leads with the wrong thing for what its passage is for scores nothing (`texts/006.md`, sentence 22).
- Rule 1 was tuned on the chapter's opening, and the deliberate deferral is the only text held out from that tuning. Sonnet 5.5 does not catch the hiccup. Models from other vendors, and a reader that judges a passage whole against its stated purpose, are untried.

## Layout

`TSV-FORMAT.md` describes what the reader returns and why it has that shape. Everything that varies sits in a folder, one file per item, named by a three-digit id:

- `texts/`: the text under test. Its front matter gives the reader line, its role (tuned on, held out, control or case), and the expectations it is checked against: `flag` lines a reader should raise and `quiet` lines it should not, each as the offences that should or should not fire (or `any`), the sentences (or `all`), and what is there.
- `criteria/`: one criterion wording, with the offence it measures in its front matter, so an expectation finds its column in any format.
- `formats/`: a TSV definition, the criteria in column order and the rules around them.
- `prompts/`: how the reader is told to read.
- `runs/<prompt>+<format>/<model>+<text>.json`: one cell, the model spelled as in Models below. A folder holds one prompt and format; its files sort by model, so one model's record across the texts sits together, and a model added later lands beside the others. Its batches record any value overridden for that batch, the assembled prompt as sent, and each run's raw reply and parsed rows.

## Models

A model is spelled as the command that calls it takes it. Claude models take the spelling of `claude --model`: `claude-opus-5-5`, `claude-sonnet-5-5`, `claude-opus-4-6`, each with thinking at its default effort. A model from another vendor takes the model name its own API uses, added here when it is first run. A run's `m` field is the name passed to `claude --model`; the alias `opus` there resolved to `claude-opus-5-5` when those runs were made.

## Running

```
scripts/run.py <prompt> <format> <model> <text> <repeats> [key=value ...] [--dry-run]
scripts/matrix.py
scripts/show.py runs/<prompt>+<format>/<model>+<text>.json [column]
scripts/by-author.py texts/001.authorship.tsv runs/003+006/claude-opus-5-5+001.json
```

`run.py` assembles the prompt from the folders, makes stripped `claude -p` calls (no tools, a one-line system prompt, no setting sources) and adds a batch to the cell. Hooks installed on the running machine still inject text into these calls, so check the raw replies for it. `matrix.py` prints every cell against every expectation its text declares. `show.py` lists one cell's stumbles with the reader's reasons. `by-author.py` counts stumbles by who wrote each sentence of the chapter's opening.
