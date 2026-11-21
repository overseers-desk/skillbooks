# reader-stumble-scores

Cold readers that score every sentence of a text for what a reader meets there: a stumble in the flow, a line that costs the author the reader's trust, and, as questions of their own, faults that live above the sentence.

## Problem

AI writes sentences that read well one by one, and joins between them that skip a beat a human reader feels. The case this lab is built on comes from the chapter "Play for the goal" of the essay *Nobody hires the AI*. A paragraph ends on a model's answer, "Asked why, the model said the numbers did not match, so it checked them.", and the reader waits for the author's comment on it. The next paragraph names the chapter's first pillar instead. The session that wrote the chapter did not see the break, which this record calls the hiccup. The lab looks for a reader that does, without flagging sentences that read smoothly.

The same writing fails above the sentence. A CV reported an engineer's detail at the weight of leading a department, and kept lines because they were true. An essay chapter disowned, in its author's own first person, what the author knew. Every sentence of these read well. The CV and the essay are one author's, and he caught each fault by hand. The lab looks for questions that a reader scoring sentences can be asked which raise what the author objected to and stay quiet on what the author kept on purpose.

## The flow reader

Prompt 003 with format 006, on `claude-opus-5-5`. The skill ships it with format 015, which asks for the reason as what the reader meets and not a way to fix it, and has the reader give its ground for calling a conflict real or apparent and leave new wording to the writer. The figures in this section are format 006's. Under format 015 the hiccup scores 3, 3 and 4 in three runs where 006 scored it 4, 4 and 4, and the deliberate deferral 3 in all three (`runs/003+015/`). The reader is told who reads the text and what they have read before, then scores each sentence 0 to 9 on nine kinds of stumble and answers in the TSV that `TSV-FORMAT.md` describes. A score of 4 or more is a stumble. The forgotten beat counts at 4 or more on either sentence of a paragraph join, since readers place it on the sentence that sets something up as often as on the one that turns away.

What it does:

- It catches the hiccup in the chapter's opening (`texts/001.md`). It goes quiet once the join is repaired, by a bridging sentence (`texts/002.md`) or by turning the pillar sentence into a transition (`texts/003.md`). It leaves alone a question the text answers on purpose two paragraphs later (`texts/004.md`). Every wording of the forgotten-beat criterion, rule 1 of the format, that catches the hiccup asks whether the next paragraph takes up what a paragraph's last sentence opens; wordings that ask whether the writer forgot something miss it.
- Across runs it flags the same other problems: references with nothing behind them, jumps between paragraphs, tangled sentences, and contradictions, which it says are real or only apparent.

What it does not do:

- Its catch sits on the cut-off. The hiccup scores 4 and the deliberate deferral 3. Every change to the reader tried so far, adding a criterion or rewording one, has moved the hiccup down to 3 or the deferral up to 4, so a change is judged on both before anything else.
- It misses a case that starts without being marked as an example when a word links it back, as in "A person who goes to work knows this without being told." It catches the same fault without the link ("A company found that…") in about one run in three.
- It measures smoothness, not purpose. A smooth sentence that leads with the wrong thing for what its passage is for scores nothing (`texts/006.md`, sentence 22).
- Rule 1 was tuned on the chapter's opening, and the deliberate deferral is the only text held out from that tuning. Sonnet 5.5 does not catch the hiccup. Models from other vendors, and a reader that judges a passage whole against its stated purpose, are untried.

## The faults reader

Prompt 005 with format 016: five criteria, a total (a sentence allowing no exception) that the passage does not support, a defensive line answering a charge nobody made, a glib line, telling the reader what any adult knows, and the author lowering their own standing. Its prompt has no place for the line that tells the flow reader who reads the text. `matrix.py` shows its record on the essay's chapters V and VI and its introduction (`texts/013.md` to `texts/017.md`), where the expectations are the author's own objections to a first draft and his rewrite.

## Questions above the sentence

Each is one criterion asked alone in its own call, prompt 003 with a format of one criterion, since a criterion added to the flow reader moved its one tuned catch. Some need a fact that only whoever runs the skill holds, such as whom the author is to be taken for. The fact is one sentence, and the criterion has a slot for it. The skill calls each of these a module, and the criterion and format in the table are the pair it ships; `scripts/module.py` prints each pair as the skill's file.

| Module | Criterion and format | Asks how likely the reader is to | Fact |
|---|---|---|---|
| height | 036 in 019 | feel that the author stands below their own subject: still finding it out, guessing, or taking from others what the reader expects them to know | |
| level | 043 in 027 | place the author lower than the standing claimed, by what the author chose to tell of their own part | `taken-for` |
| learning-path | 037 in 028 | feel they are told the story of how the author came to know a thing, where they wanted what the author knows | |
| must-not-conclude | 039 in 023 | be led toward a conclusion the author does not want drawn | `must-not-conclude` |
| work | 044 in 029 | wonder why they are told this, because the sentence's subject is something other than what they came for and nothing later uses it | `reading-for` |

### How they were tested

The author's own record is what the modules are tested against: what he objected to in these texts, and what he kept on purpose.

The texts:

- Tuned on: the CV in two earlier versions; two CV lines the author spoke as examples of a line told wrongly; the essay's chapter V in its first draft and its rewrite (`texts/015.md`, `texts/016.md`); a published autobiography's account of learning to write (`texts/018.md`); and, made for this lab, one set of facts told from above and from below (`texts/019.md`, `texts/020.md`).
- Held out: the CV's final version; the chapter "Play for the goal" whole, at three commits; and chapter VI in its first draft and its rewrite (`texts/013.md`, `texts/014.md`).
- For the rate of rows on CVs nobody here objected to: four other people's CVs, two judged good and two judged weak in earlier work outside this lab, where AI judges compared CVs in pairs.

The CV in every version, the other people's CVs, the whole chapter, and the fuller expectations for chapters V and VI with the modules' run records on those chapters, are private. They sit in private repositories, in folders read through `--root`. Their location is left out of this record, which gives their results as counts from `tally.py`.

An expectation is a place where a module should score, a flag, or should not, a quiet. It comes from the author's record, never from the criterion it tests, and carries the strength of its source: `owner`, he objected in words; `accepted`, someone working with him objected and he accepted it; `audit`, an AI cut the line in its own audit and he did not restore it; `reading`, a supervising session's reading alone, where a row is evidence for the reading and a miss is no failure. Where a result below gives his view, his words are in the private record. Expectations were committed before the wording they test was run.

Two sessions did the work. One worded the criteria and ran them. The other, the supervising session, had studied the author's record, wrote the expectations, and kept those of the held-out texts to itself. The wording session did not open a held-out text. It ran each frozen wording there without reading the rows, and the supervising session read the cells and gave its verdict. Once every wording was frozen the supervising session released its held-out expectations, written before the runs, and they were entered on the private texts, a prediction that failed staying as an expectation that failed. The held-out counts below are `tally.py`'s over those lines.

A run is one call of a reader on a text, and a cell is all the runs of one wording on one text. Scores below are given run by run, so "6 and 5" is one sentence in two runs. A cell had two runs, and a third where the two disagreed on an expectation; the two constructed controls had one. A flag is met when more than half the runs score 4 or more at any of its sentences, since a reader can place a row one sentence off. A quiet is broken when some one of its sentences scores 4 or more in more than half the runs, so two runs that each score a different sentence of a long passage once do not break it. The author had bounded a test of one wording at twelve runs. That bound was applied to each wording across its tuning texts, with at most three wordings to a module, so that a wording could not be fitted to its texts by repetition. One cell exceeds it by two runs, made to settle a kept line that had scored at the cut-off.

After a held-out result two things were changed, both described below: work's criterion was reworded once, and learning-path's format gained an instruction. Nothing else was.

Held-out results for the wordings the skill ships, two runs each:

| Module | Text | Flags met | Quiets broken |
|---|---|---|---|
| height | the whole chapter, latest version | none set | 1 of 6: the quiet on the whole chapter, by two kept sentences that lean on another voice |
| height | the whole chapter, two earlier versions | `owner` 0 of 2, `reading` 0 of 1 | none set |
| height | chapter VI, draft and rewrite | none set | 0 of 2 |
| height | the final CV | none set | 1 of 1: a prediction of no row, broken by one sentence at 4 and 4 |
| learning-path | the whole chapter, two earlier versions | `owner` 2 of 2 | none set |
| learning-path | the final CV | `reading` 2 of 2 | none set |
| level | the final CV | `reading` 1 of 1 | 1 of 1: a line the author shaped himself, at 6 and 6 |
| must-not-conclude | the final CV | none set | 1 of 1: a prediction of no row; on reading the two sentences the supervising session judged the module right |
| work | chapter VI, draft | `owner` 0 of 1 | none set |
| work | chapter VI, rewrite | none set | 0 of 1 |
| work | the final CV | none set | none set; no sentence scores in both runs |

The `owner` flag on the two earlier versions of the whole chapter is one sentence: height was expected to score it and did not, and it was then given to learning-path, which does.

Before any wording, the flow and faults readers were run on the two CV versions and on chapter V. At the lines the author had objected to in words they raised his objection at none. At about half they scored the same sentence for another reason, an unintroduced name or a figure given twice.

### height

Wordings 035 and 036, and 036 in a format (020) that invited a row for a problem lying in a run of sentences.

- Tuning. Of four lines the author objected to, three are met: both sentences of chapter V's first draft that disown his knowledge (6 and 6, 4 and 4), and a CV line he spoke as an example of telling a finding as a discovery (6 and 5). The second disowning sentence is the one the faults reader's lowered-standing misses in 0 of 3. The fourth is missed in all three variants: an analogy placed before the author's account of the matter, so that it read as the way he had worked the matter out. No reader felt anything at any sentence of it.
- Quiets. None of six broken on chapter V. The published control drew nothing above 2 and the facts told from above nothing above 2, though both narrate a self who did not yet know. The facts told from below scored 5 to 8 on all five planted lines and nothing on the story sentences shared with the other version. So the plain wording separates the teller from the self in the story, and no carve-out was added for it.
- Wording 035 asked whether the author "commands" what they tell and scored sentences for giving no source. That cuts against the author's stance, that a writer who knows has no need to show credentials, so 036 asks whether the author stands below the subject.
- Held out, the whole chapter. A story of some fifty sentences, told by an author who knows about a self who did not, drew nothing above 2. A line he had rejected as told from the wrong position drew 0 and 0; learning-path hears that line, below. On each version of the whole chapter two sentences he kept score 4 in both runs, one for leaning on a named authority and one for guessing at what others think, and on the final CV one sentence scores 4 and 4.
- Held out, chapter VI: nothing scores in both runs on either version; three sentences drew 4 in one run each.
- Weakness. A sentence that cites press for the author's own work, or reports research in the passive, scores at the cut-off: 4, 3, 3 on a CV line he kept, 4 and 4 on a sentence of chapter V's rewrite.
- Other people's CVs, one run each: 0, 1, 1 and 1 rows at 4 or more, on 20 to 133 sentences.

### level

Wordings 038, 041 and 043, with the fact that the author is to be taken for someone who already leads at the scale of the post the CV applies for.

- Tuning, on the first CV draft. Of five lines he objected to, four are met by 2 of 3 runs, with his reason: counts of scripts and tools, and implementation detail, reported by a candidate for a post leading thirty engineers. The fifth, a line taking pride in still doing a junior's work, scores 3, 3, 2 with the right reason. Both `accepted` lines are met, at 6. Two audit cuts, lists of tools, stay at 3.
- Quiets. None of eight broken.
- Wording 038 let the reader weigh "what it shows them doing, counting or dwelling on", and the reader measured every number against the thirty in the fact. Wording 041 asked what the author chose to tell and still scored 4, 3, 4 a line the author wrote himself, in which a system directs twenty staff, as his own headcount. Wording 043 adds "about their own part", and that line draws no row.
- Held out, the final CV: 3 and 2 rows of 52. The supervising session's one prediction is met at 5 and 5. One line the author shaped himself scores 6 and 6, against a prediction of quiet.
- Other people's CVs, one run each: 1 and 5 rows at 4 or more on the two judged good, 7 and 23 on the two judged weak. The reasons name a senior director's bullet about code he wrote himself, lists of editors and build tools, weekly summaries.

### learning-path

One criterion, 037, in two answer formats: plain (021), and with a special instruction (028) modelled on the flow reader's for contradiction. With the instruction, at 4 or more the reason also says which of two things the passage is doing: resting the point on how the author came by it, or telling a story that an author who already holds the point has chosen. The score stays what the reader feels. The skill ships the second.

- Tuning. The one line of the author's own among the tuning texts, a spoken example of a growth story in a CV, scores 8 and 8 in both formats. A supervising session's readings on the CV versions, lines that name a method by where it came from, are recognised with the right reason at 2 to 4 in the plain format and at 4 to 5 with the instruction. No quiet broken.
- Held out in the plain format, the final CV: rows fall on the two places predicted and nowhere else.
- Held out in the plain format, the whole chapter: 22 and 19 rows at 4 or more on its latest version, twelve to twenty of them a run inside a long story the author chose to tell. Read for its scores on an essay, the module would lead an editor to delete that story. A sentence at the head of the story in the two earlier versions, which the author had rejected, scores 6 and 5; height had given it 0 and 0.
- The instruction was added after those results, at the supervising session's proposal, on the model of the author's own ruling for contradiction, and was worded without sight of the held-out texts. It moves scores: up by about one on the CV, and on the latest version of the whole chapter from 22 and 19 rows at 4 or more to 12 and 8.
- With the instruction, the final CV: the same two places and no other, the first at 4 and 4 where it had been 3 and 3. The reader says there that the derivation stands where the method should be.
- With the instruction, the whole chapter. The rejected sentence scores 6 in all four runs of the two earlier versions, each time diagnosed as resting the point on how the author came by it, and the sentences after it are diagnosed the same way in three runs of four. In the latest version, with the author's replacement at the head, the replacement draws no row and the same stretch sits mostly at 4, diagnosed as a story chosen to show the point. On that chapter the diagnosis separates what the score alone does not. It is not steady: it splits between runs on three or four sentences, and gives the first diagnosis to two sentences the author kept.
- With the instruction, chapter VI: a limit. On both versions one passage scores 5 and 6, and on the rewrite a second scores 5 and 5, each diagnosed as resting the point on how the author came by it. The author's record of that chapter values those passages as claims sized to what he can show, told as what he has found. Two of his standards meet there, speaking from knowledge and claiming no more than the support carries, and the module cannot tell which he chose. A row with that diagnosis is a report to weigh.
- Beside height. On the tuning texts both score the same lines. They part where an author who plainly knows the subject still tells how he came to it: such a line in a CV version scores 2 on height and 4 to 5 here, and height gave the first predicted place of the final CV 3 and 3.
- Other people's CVs, one run each in the plain format: 1, 0, 0 and 1 rows at 4 or more.

### must-not-conclude

One wording, 039, whose reason names what the reader concludes.

- Tuning. All six lines the author objected to are met, at 6 to 9: a stated country of residence, roles dated to the present, a company founded this year. No quiet of eight broken.
- The fact decides what it hears. Told that the reader should form no view of where the author lives, it scored each line pointing to any country, among them two that pointed where he was content to be placed. Told that the reader should not conclude he lives outside two named countries, it scored those two lines 2 and went on scoring the rest.
- Held out, the final CV: two sentences score 5 and 4 in both runs, for a conclusion the author had named as his fear. The supervising session had predicted no row, and on reading the two sentences it judged the module right.

### work

Wordings 040, 042 and 044, with the fact of what the reader is reading for.

- Tuning, the first CV draft. The author's one line, on a venue's reopening, visitor numbers and prize in the CV of the person who ran it, scores 4 and 4. Three of five audit cuts are met, at 5; two smaller boasts draw no row. No quiet of ten broken, on the CV versions or on chapter V.
- Wording 040 asked whether the sentence "does nothing for what they are reading for", and the reader took that to mean it is not about the field of the post. It scored 4 and 4 two client rows the author kept through every version, and eight more lines of his earlier career in each run. The author had warned of this reader: a cure for saying too much that leaves a very dry text, removing text that does work. Wording 042 asks about the sentence's subject. Rows at 4 or more on that version fell from eight a run to one and three, and the kept rows to 2 and 3.
- Held out with 042, the whole chapter. It left alone the long story, its main example, the opening story and an anecdote. In both runs it scored two things the author had fought to keep: a credential mentioned in passing, 6 and 6, one run placing its row a sentence early, and a vivid detail, 4 and 4. The tally counts three of seven quiets broken, the third being two neighbouring sentences of the long story scored once each.
- So wording 044 adds the kinds of work a sentence can be doing, in the author's terms made general: it helps the reader understand, ties the matter to something they know, sets up what follows, gives the author standing to speak, leaves a picture they will remember, or lets them smile in recognition. This is the one criterion reworded after a held-out result. The whole chapter is a tuning text for work from that point, and chapter VI is its held-out essay.
- With 044. On the whole chapter the vivid detail is quiet in both runs and the credential falls to 4 and 4 with the same reason, that nothing later uses it: one of seven quiets broken. On the CV his line holds at 4 and 4, so naming standing as a kind of work did not excuse a prize that is the venue's.
- Held out, the final CV. With 042 nothing scores in both runs and two kept lines drew 4 in one run each; with 044 nothing scores in both runs and one sentence drew 4 once.
- Held out with 044, chapter VI. On the rewrite nothing reaches 3. On the first draft the passage where, by the author's record, the draft opened on the picture and not the problem draws no row, so that fault is unheard. Three sentences describing a product by name score 4, one of them in both runs (`runs/003+029/claude-opus-5-5+013.json`, sentences 121 to 123).
- Other people's CVs, one run each with 042: 1, 0, 0 and 3 rows at 4 or more. The three are hobbies. 044 was not run on them.
- It is a quiet reader. It hears a line whose subject is something else and lets smaller trivia pass. It also scored the one supposition in the record, a made-up use case in a CV, at 5 under 040 and 3 to 4 after.

### Named and not built

Two more modules were named when the set was designed. A supposition, meaning a made-up case in a kind of text with no room for one, had one case in the author's record, and work scored it. A story opened and never taken up had no case there, and the flow reader's forgotten beat is its nearest neighbour. Either can be supplied to the skill as a module of the caller's own.

### What none of them hears

- Where a passage stands. The analogy placed before the author's account drew no row in any variant of height, and the chapter that opened on a picture before its problem drew none from work.
- Machine English: a subject that shifts with no noun marking the change, cadence, diction. The flow reader's unanchored reference scored the opening of chapter V's rewrite, which the author called machine-written, in 0 of 2 runs (`runs/003+015/claude-opus-5-5+016.json`).
- A line removed. A cross-reference the author wanted kept is gone from chapter V's rewrite, and a row needs a sentence to land on.

## Layout

`TSV-FORMAT.md` describes what the reader returns and why it has that shape. Everything that varies sits in a folder, one file per item, named by a three-digit id:

- `texts/`: the text under test. Its front matter gives the reader line, its role (tuned on, held out, control or case), any fact a criterion asks the caller for, and the expectations it is checked against: `flag` lines a reader should raise, `quiet` lines it should not, and `contested` lines the record leaves undecided, each as the offences that should or should not fire (or `any`), the sentences (or `all`), and what is there, which may open with its source in brackets.
- `criteria/`: one criterion wording, with the offence it measures in its front matter, so an expectation finds its column in any format. A `{slot}` in it is filled from the text's front matter, and a slot nothing fills stops the run.
- `formats/`: a TSV definition, the criteria in column order and the rules around them.
- `prompts/`: how the reader is told to read.
- `runs/<prompt>+<format>/<model>+<text>.json`: one cell, the model spelled as in Models below. A folder holds one prompt and format; its files sort by model, so one model's record across the texts sits together, and a model added later lands beside the others. Its batches record any value overridden for that batch, the assembled prompt as sent, and each run's raw reply and parsed rows.

## Models

A model is spelled as the command that calls it takes it. Claude models take the spelling of `claude --model`: `claude-opus-5-5`, `claude-sonnet-5-5`, `claude-opus-4-6`, each with thinking at its default effort. A model from another vendor takes the model name its own API uses, added here when it is first run. A run's `m` field is the name passed to `claude --model`; the alias `opus` there resolved to `claude-opus-5-5` when those runs were made.

## Running

```
scripts/run.py <prompt> <format> <model> <text> <repeats> [key=value ...] [--root <dir>] [--dry-run]
scripts/matrix.py [--root <dir>] [--any]
scripts/tally.py [--root <dir>] <prompt>+<format> ...
scripts/module.py <prompt> <format>
scripts/show.py runs/<prompt>+<format>/<model>+<text>.json [column]
scripts/by-author.py texts/001.authorship.tsv runs/003+006/claude-opus-5-5+001.json
```

`run.py` assembles the prompt from the folders, makes stripped `claude -p` calls (no tools, a one-line system prompt, no setting sources) and adds a batch to the cell. Hooks installed on the running machine still inject text into these calls, so check the raw replies for it. `--root` names a directory whose `texts/` and `runs/` are used in place of the lab's, for texts that stay private; prompts, formats and criteria are always the lab's. `matrix.py` prints every cell against every expectation its text declares, and with `--any` shows what a reader raises where another offence is expected. `tally.py` counts a cell's expectations met and broken by the strength of their source and quotes none of them. `module.py` prints a prompt and format as the one file the skill ships. `show.py` lists one cell's stumbles with the reader's reasons. `by-author.py` counts stumbles by who wrote each sentence of the chapter's opening.
