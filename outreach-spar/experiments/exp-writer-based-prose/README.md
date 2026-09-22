# exp-writer-based-prose

A letter drafted from a campaign brief carries the brief to the reader: a code and a link that were never introduced, a call that has not happened, reasons for the offer the reader did not ask for. The method already has what looks like the perfect detector for this. Before any fact-check, a context-isolated agent plays the recipient, with the recipient's profile and nothing of ours, and reacts. A reader who does not hold what the writer holds should be exactly the one who trips on a reference to nothing. It did not trip. It read the nonsense references, made sense of them, and passed letters that were not sendable. This experiment is about why, and about what, if anything, around the drafting loop can be made to catch what that reader did not.

Fourteen arms across four rounds, 22 and 23 September 2026. None worked. The faults that survived were all written before drafting began, in the campaign's own inputs, where no guard around the loop can reach them.

The short answer to why the reader passes them, worked out in the sections below and confirmed by the rounds: it was asked to react, and a reaction is robust to gaps, because reading is repair; it was not given the date, so an impossible ask read as advance notice; and it was not given the facts, so a false claim read as information. The same model asked to point at every expression it cannot resolve, before reacting, finds three to four per letter. The capacity was there; the task did not call it, and the isolation that kept our framing out took the reader's own world with it.

## Problem

Writer-based prose, in Linda Flower's sense, is prose organised by the writer's own path through a problem rather than by what the reader needs. A drafting agent produces it in a recognisable form: it names a thing with a definite article that the reader has never met, and it answers questions the reader never asked.

The letters under test invited local organisations to a circus season at a venue. Three specimens, from a campaign whose messages had already been through the mandatory A2 spar:

- "Reply and I will send you **the** booking link and **the** code" — no code and no link have been mentioned.
- "Following **our call**" — a template written before the call it follows. The phone-only pattern produces it by design: SPAR-A §4.2 asked for an email "for once an address is obtained on the call", so the follow-up is drafted in the past tense about an event that has not happened.
- "The opening-week seats aren't on sale to groups" and "an excursion in two days isn't realistic" — both answer a question the recipient never asked. The second caveats an offer the letter has not yet made.

The existing guard is SPAR-A §4.6 Step 1: a context-isolated agent plays the recipient and reacts before any fact-check. It passed all three. Its own words on the first, recorded in the approach file: *"nothing about the email itself smells like spam — it's specific, personalised, and low-pressure"*, with `REPLY_PCT: 55`.

## Why the existing guard misses it

Four reasons, all structural rather than a failure of the agent.

**The persona construes.** A model told to react in character makes sense of whatever it is given. Faced with "an excursion in two days isn't realistic" it infers an excursion was offered and carries on. A real recipient with a room full of children does the same, faster. So the reader who would notice the gap is exactly the reader the role-play is not.

**The persona does not know what day it is.** §4.6 Step 1 gives C2 the profile and the draft and nothing else, so our framing cannot contaminate the reaction. That isolation also removes the fact that decides whether a time-bound offer is actionable. In the draft for Songbirds Early Learning at Pimpama, a vacation-care service, the persona read a show two days away as advance notice: *"this is talking about September, so it's not solving my immediate problem, but a heads-up for later is fine"*, and *"I'd probably reply within a day or two if it fits our calendar"* — a reply time that lands after the show. Controlled comparison: the same persona, same draft, one line added ("Today is Tuesday 22 September 2026") opened with *"first thing I notice: that's two days away"* and rejected the ask on permission forms, bus booking and ratios.

**The persona is asked to react, not to point.** A reaction is the end of reading, and reading is repair: by the time a reader can say how they feel about an offer, every gap has been filled in. The same model given the same letters and asked instead to list each expression it cannot resolve, before any reaction, finds three to four per letter (the round-3 and round-4 scorers, one pass each over 55 to 75 letters). Pointing has to precede reacting; a reader who has already reacted has repaired the gaps without noticing them.

**The persona does not know the facts.** "Not on sale anywhere" and "you were picked" are information to a reader with no way to check them, and the registry the fact-check treats as authority is where those claims are written. Falsity needs the facts, and the persona is given neither the facts nor a reason to doubt what it reads.

## Attempts

Fourteen arms across four rounds. Rounds 1 and 2, five arms each, were delivered through `prompt_appendices`; no method document or prompt was edited. Round 3 took the round-2 letters as finished and had a second writer, holding only the letter, write each again. Round 4 had the author itself write again, two ways. Every prompt text is in [prompts.md](prompts.md).

### Round 1 — 22 September, eight contacts per arm, author Sonnet

| Arm | Guard |
|---|---|
| N | none |
| A | author-side rule: every sentence about what the reader gets or does |
| C | challenger-side pointing list before the reaction |
| B | both |
| N2 | none, re-run after three method fixes landed mid-experiment |

Measured by an independent reader under one rubric: references resolving nowhere, false claims, unsupported claims, words.

| Arm | Nowhere/msg | False/msg | Unsupported/msg | Words |
|---|---|---|---|---|
| prev (14 earlier drafts) | 1.86 | 2.07 | 0.64 | 174 |
| N | 1.50 | 1.38 | 0.88 | 171 |
| A | 1.88 | 1.38 | 0.63 | 151 |
| C | 1.88 | 2.00 | 0.63 | 213 |
| B | 1.88 | 1.38 | 0.63 | 170 |
| N2 | 1.63 | 1.75 | 0.38 | 191 |

Nothing separated. The pointing list alone (C) was the worst: longest letters, most false claims. Told to point at unintroduced referents, the author introduced them by explaining, and explaining is where the campaign's claims and the writer's reasoning re-enter.

### Round 2 — 22 September, five contacts per arm, author Opus 5, placebo added

The Director supplied two methods after rejecting the agent's own proposals: a reader's reference map with a separate resolvability score, and per-sentence scores for confusing / surprising / interesting with the author naming the question behind any surprising sentence. The rejected proposals were a code-detected referent list, a four-slot template the author writes into, and a two-reader paraphrase comparison; the first because code cannot judge whether a name needs introducing for this reader, the second because it reproduces the fault it prevents, the third as weaker than either. A placebo arm, an unrelated analytical pre-task on the challenger, tests whether any pre-task alone sharpens it. It is shorter than the method texts and carries no author-side half, so it is a weaker control than intended; see prompts.md.

Scored blind: one reader, 25 letters as plain subject and body under random names, no arm labels, key held apart ([blind.py](blind.py), [key-round2.json](key-round2.json), [scores-round2.tsv](scores-round2.tsv)).

| Arm | n | Nowhere | Surprise | Surprising 4-5 | False | Words |
|---|---|---|---|---|---|---|
| none | 5 | 4.2 | 1.17 | 0.8 | 1.2 | 269 |
| placebo | 5 | 4.2 | 1.18 | 1.2 | 2.0 | 268 |
| method 1, reference map | 4 | 3.0 | 1.21 | 0.75 | 1.75 | 227 |
| method 2, sentence scores | 4 | 3.25 | 1.49 | 1.5 | 2.25 | 230 |
| method 1+2 | 4 | 5.0 | 1.21 | 1.0 | 1.5 | 247 |
| earlier Sonnet run (round 1's N2, rescored) | 3 | 2.67 | 2.00 | 2.0 | 2.33 | 181 |

Paired on the two contacts present in all five arms, nowhere counts: seniors club 6 / 3 / 3 / 2 / 7; playgroup 5 / 4 / 3 / 4 / 4 (none / placebo / m1 / m2 / m12).

On the playgroup, method 1 is lowest. On the seniors club it ties the placebo at 3 and sits above method 2 at 2. So the honest reading is that method 1 is lowest on one paired contact and equal-to-placebo on the other, not lowest on both. Four or five messages per arm separates nothing statistically, and no arm here is shown to beat the placebo.

### Why the composed arm is not a test of the composition

In the composed arm the challenger returned DONE at pass 1 on four of four drafts. No revision ran, so the author never saw a single score. Its numbers describe a first draft under a guard whose author-side half never fired.

Method 1 is only half-tested for the same reason. Its cost logs show two of five contacts revised (one contact at two revisions, one at one) and the rest settled at the first pass, one of them with no challenger pass recorded at all. So its author-side rule, which says to cut a sentence rather than introduce the thing it names, fired on two letters of five.

Method 2 alone went to revision on four of five, so its author step did fire. That is the one arm whose author-side instruction was properly exercised, and it scores worst of the three on the reader's surprise measure.

### Round 3 — 22 September, a second writing of each round-2 letter

Round 3 tests the reader's half of the arrangement on its own: not the writer transforming its own draft, which is Flower's remedy and the subject of round 4, but a second writer who holds nothing of the first one's inputs. Each of the 25 scored round-2 letters was handed to a fresh Opus 5 context holding only the letter, the recipient's organisation and role, and the date, with the instruction to write it again for that reader, keeping every fact they need to act and adding none. The letter's inputs, plan block and registry, were out of reach, so nothing the writer's process holds could re-enter except through the letter itself.

Two arms, same prompt, differing in what the headless session carried. The office arm ran under the operator's normal configuration, where the office plugin injects its writing methodology at session start. The bare arm ran under a config directory holding credentials only. Originals and both rewrites, 75 letters, were blinded together and scored in one pass by one Opus 5 reader under the round-2 rubric plus a fourth count, sender-side sentences: why the offer is made, how the recipient came to be written to, what is not on offer or not possible, or the sender's own situation ([round3-rewrite/](round3-rewrite/)).

| Letters, n=25 each | Nowhere | Surprise | Surprising 4-5 | False | Sender-side | Words |
|---|---|---|---|---|---|---|
| original | 3.72 | 1.65 | 2.68 | 2.80 | 3.40 | 254 |
| second writing, office context | 3.80 | 1.61 | 2.44 | 2.84 | 3.28 | 256 |
| second writing, bare context | 3.96 | 1.64 | 2.72 | 3.20 | 3.44 | 275 |

Paired per letter, the office rewrite changed little: on sender-side sentences 15 of 25 pairs are identical and the rest split 6 better, 4 worse; on unresolved references 11 identical, 7 and 7. Read side by side it is the original with a paragraph moved. The bare rewrite changed more and for the worse: 21 words longer on average, false claims up in 12 pairs and down in 2, unresolved references up in 10 and down in 5, sender-side sentences unmoved. Leading with the offer, it restated the offer in fresh words, and the fresh words carried the selection claim again, in one letter as "tickets set aside for your club", which the original had not said.

The registry-born faults passed through both arms untouched, by lexical count over 25 letters: "not on sale / not advertised" 20 original, 21 office, 19 bare; "picked / a short list / yours is one" 17, 17, 17; "the code" or "the link" unintroduced 24, 23, 20. The reader who holds only the letter cannot tell a fact from a leak, and the instruction to keep every fact the reader needs was read as keep every fact.

So a fresh reader-writer reorganises but does not cut, because to it the sender-side sentences are information. Cutting them needs the inputs in view, which is the challenger's fact-check step with a different question: does this sentence exist because an input said so, or because the reader would ask. What the writer who holds the inputs does with a second pass is round 4's question.

The reader's consistency across rounds is checkable here: the same 25 originals scored 3.72 on unresolved references in this pass against a weighted 3.8 in round 2's, under a rubric written afresh.

### Round 4 — 23 September, the writer's own second pass, two designs

Flower's remedy is the writer transforming its own draft with everything it knows. Two designs of that, both set by the Director, with the same instruction shape and no cue word named:

- **Design A, one call.** The author's ordinary drafting brief, with an appended instruction to write a first draft, then read it as the recipient would and write the final message to what they would ask. The pair is the first draft against the final, inside one call. Eight contacts from the round-1 rerun, whose briefs survive with live file paths; one is phone-only and has no letter, so seven pairs.
- **Design B, second prompt.** The session that wrote a finished round-2 letter is resumed and given one prompt: write the letter again for its reader, who has seen none of what you read in order to write it. The pair is the sent letter against the second writing. The 22 Opus round-2 letters; 19 completed before the profile holding those sessions reached its weekly limit.

In both the writer holds the plan block, the registry, the profile, the fact sources and, in B, every challenger round. Both ran on Opus 5, the model that wrote round 2, by its exact id. The letters were blinded together with their firsts, 55 in one folder, and scored by one Opus 5 reader in a bare context under the round-3 rubric ([round3-rewrite/key4.json](round3-rewrite/key4.json), [scores4.tsv](round3-rewrite/scores4.tsv), [scorer4-report.md](round3-rewrite/scorer4-report.md)). By accident the same 55 were scored a second time by a second run of the same reader ([scores4-second.tsv](round3-rewrite/scores4-second.tsv)); the two readings correlate at 0.95 on sender-side sentences, 0.99 on words, and between 0.64 and 0.77 on the other counts, with the second counting higher throughout. Both readings give the same direction on every measure below; the first is quoted.

| paired, n | unresolved references | surprising 4-5 | false | unsupported | sender-side | words |
|---|---|---|---|---|---|---|
| A, first draft, 7 | 2.86 | 0.29 | 1.00 | 0.86 | 1.14 | 186 |
| A, final, 7 | 3.14 | 0.43 | 1.14 | 0.43 | 1.43 | 213 |
| B, sent letter, 19 | 3.11 | 0.63 | 1.16 | 1.11 | 2.21 | 253 |
| B, second writing, 19 | 3.05 | 0.68 | 1.21 | 1.11 | 2.74 | 290 |

Paired per letter, better / same / worse: A on sender-side sentences 0 / 5 / 2, on unresolved references 1 / 2 / 4, on words 0 / 0 / 7 longer; B on sender-side sentences 1 / 10 / 8, on unresolved references 7 / 7 / 5, on false claims 2 / 15 / 2, on words 1 / 1 / 17 longer. The one movement in the right direction is A's unsupported claims, down in two pairs of seven.

The registry-born claims pass through the writer's own second pass as they passed through the fresh reader's, by phrase over the paired letters: B, "not on sale / not advertised" 17 of 19 before and 17 after, the selection claim 15 and 15; A, 4 of 7 and 4, 3 and 3. The writer holds the registry as the offer's own statement and, asked to write for the reader, writes its claims again, at greater length. A's finals add what the first draft had not needed: a show's running time, a street address, a second channel. B's second writings add reader-facing lines ("What I need from you is a rough number", "There is nothing to pay and nothing to buy") and keep everything else.

**The same two designs on Opus 5.5, five pairs each.** The Opus 5.5 material from the first run of each design, the five contacts common to both, scored in a separate pass by the same reader ([key5.json](round3-rewrite/key5.json), [scores5.tsv](round3-rewrite/scores5.tsv)). A on 5.5, both drafts by 5.5, moves as on Opus 5: 41 words longer, unresolved references 1 / 2 / 2, false claims 0 / 3 / 2. B on 5.5 moves the other way: unresolved references 3 / 1 / 1, surprising sentences 4 / 1 / 0, false claims 4 / 1 / 0, sender-side 2 / 2 / 1, words +7. B's first writings are Opus 5's, so that pair changes model as well as pass, and A, where both passes are 5.5, did not gain; the reading that fits both is that 5.5 writes a tighter letter from the same brief, not that the second pass does. A B pair with a 5.5 first writing needs the harness run on 5.5.

So the second pass by the writer, with or without its brief, reaches the letter's order and address and not the selection of what is in it. The cut needs a question the writer is not asking of its own sentences: is this here because an input said so, or because the reader would ask. That question needs the inputs in view, and it is the challenger's fact-check step with its question changed, not another pass by the author.

## What survived every arm

| Fault | Letters carrying it, of 25 |
|---|---|
| An unintroduced booking link, code or details | 24 |
| "The seats are not on sale to the public" | 17 |
| "You were picked / chosen / held in your name" | 20 |

The first comes from the campaign's own drafting instruction, which reads "the code and the Eventbrite link go in the reply" — the definite article is in the instruction. Every author followed it faithfully.

The second and third come from one entry in the campaign's USP registry, `chosen-not-advertised`, and they fail in two different ways worth separating.

Its `claim` field is qualified and, as written, true: the free opening-week seats are not advertised and are not offered to the public at any price, *the same shows selling at full price on the venue's own page and on the operator's ticketing*. Its `label` drops the qualifier: "These seats are not on sale anywhere". Standing alone the label is false, and it is the short quotable line at the top of the entry, which is the form a drafting agent reaches for. The letters carry the label's compression, "the seats are not on sale at any price", rather than the claim's careful version. So the mechanism is not that an unsourced claim was believed. The entry is sourced. The registry holds the same statement at two levels of qualification and nothing checks the short one against the long one.

The selection claim fails differently. "The recipient's organisation was chosen by name from the venue's own list" sits in the `claim` field itself, and its own `rests_on` supports only that each recipient is a profiled roster entry on a per-segment allowlist. That is not choosing by name. The entry is contradicted by its own provenance, which a check comparing claim against `rests_on` would catch.

`spar-campaign-yaml.md` states that a USP's claim is taken as written in the registry, because the campaign was verified once when defined, and that the challenger opens a fact source only where a `rests_on` names one. So neither failure has anywhere to surface. Both were known and left in place as a constant across arms.

One more thing the letters show about the selection claim. Counted by keyword, picked or chosen or selected, it appears in 9 of 25. Counted by meaning it is 20. The difference is carried as implicature: "a handful of local organisations and yours is one", "a short list", "offering them to a few publications". Five letters say it outright. A guard that matched words would clear two thirds of the letters that make the claim.

A guard around the writing cannot catch a fault that was not made during the writing. That is the finding.

Both registry entries were still live in the campaign file when this was written. They stay until the campaign's owner rules on them; correcting them mid-experiment would have moved the constant every arm was measured against.

## What did work, and it was not a guard

The date. Adding today's date to both the author and challenger prompts changed the persona from approving a two-day-away offer to rejecting it on operational grounds. That is a fix to an input, not a guard on the output. It landed in the method mid-experiment (commits 82d9ddb, 881215b, 41714cd on the aesop branch) along with the phone-only fix and a three-bin sorting in the revise step; verified from this experiment's own run logs, where "Today is Tuesday 22 September 2026" appears in 11 challenger and 15 author prompts of one arm, the phone-first contact's final round holds one phone message and no email, and every file of that arm carries the sorting in `revision_note`.

## Where to look next

The faults live upstream of the drafting loop, in the campaign's model messages and its USP registry. Three places worth a guard, none tested here:

1. **The model message.** A campaign's `first_ask` is prose written by whoever set the campaign up, and it goes into every draft. Nothing reads it for writer-based prose or for definite articles pointing at nothing.
2. **The USP registry.** It is the one document the fact-check treats as verified, and nothing verifies it. Two checks would have caught this campaign's faults and neither exists: the label read against the claim beneath it, since a label is a compression and a compression can drop the qualifier that made the claim true; and the claim read against its own `rests_on`, since an entry can assert more than its stated grounds support. A check asking only whether an entry is sourced passes both faults.

   Whatever does the checking has to work on meaning rather than words. The selection claim appears in 9 of 25 letters by keyword and 20 by meaning, the difference carried by phrases like "a handful of local organisations and yours is one".
3. **The persona's information state.** The date fix shows the shape: the role-play is stripped of our framing, correctly, and of the recipient's own situation, incorrectly. What a real recipient knows and the isolation removes is worth enumerating.

## A measurement lesson

Round 1 was first scored by a different agent per arm. Their rubrics drifted: one counted the sender's name and role as an unsupported claim, contributing 8 of that arm's 16, and the others did not. Arm-level numbers were not comparable until one reader re-scored every set under one written rubric. Any repeat should score all arms in one pass, or the instrument varies more than the treatment.

## Operational notes

- **Fable is quota-limited.** All five Fable arms failed at the author call with "You've reached your Fable limit"; three produced nothing at all. The model axis is unmeasured, not negative.
- **The harness has no author-model setting.** `vendor/coachman-1.13.tm` hardcodes `--model sonnet` for any call that passes none, and the A-phase author calls pass none (`harness-1.0.tm:212, :283`), so `ANTHROPIC_MODEL` is overridden. Round 2 used a copied tree with that one line reading `SPAR_AUTHOR_MODEL`. The office belief that "A runs on Opus" was not true of any run before this.
- **Refusals track the session's injected context, not the letter.** In round 3 the same 25 rewrite prompts ran twice: under the office configuration, whose plugin injects its methodology at session start, Opus 5's safeguards refused 6 of 25 on the first call, 5 of those again on retry and 1 on a second retry; under a credentials-only config directory, 0 of 25. Round 2's authors ran under the office configuration too, so its three refusals are more plausibly the same effect than a response to the method text.
- **The office context also writes working notes into the output.** Five of the 25 office-arm rewrites carried the methodology's ceremony before the subject line, one of them 382 words of it; the bare arm carried none. A headless author under this configuration is not a bare model, and a repeat that wants one uses a config directory without the plugin.
- **A headless session can spin a core for minutes.** With two versions of the office plugin's git shim on PATH, which happens to a session started before a plugin update, each shim resolves the other as the real git and execs it in a loop. Any `git` from the session, or from a headless claude it spawns, spins at 100 % of a core until killed. Verified 22 September: 11.7 s of CPU in a 15 s timeout with both on PATH, 0.1 s with one. Round 3 stripped the duplicate from PATH for every call.
- **A scorer over 75 letters overran the 64 000-token output limit** by writing its per-sentence rows into the report. The prompt now keeps them in the working; the run was recovered by resuming the same session for the table alone.
- **A wording of the design-A instruction was refused outright.** Asked to write the message "as it comes" under a working marker before the final, Opus refused all eight calls as reasoning extraction. Probes: the same brief without the instruction passed; the instruction under a bare configuration was refused; Sonnet accepted it. Reworded as a first draft and a final, all eight passed.
- **The `opus` alias moved under the experiment.** By 23 September it resolved to Opus 5.5 while the round-2 letters were Opus 5's. A first run of both designs changed model as well as pass; both were rerun by exact id. The Opus 5.5 material is kept under `drafts-a-*` and `rewrites-author-clean/`.
- **Resume appends.** Prompting a session a second time leaves the first rewrite in its context, so a rerun on the same session is a third writing. `fork-sessions.py` copies each transcript under a fresh id, cut before the first rewrite prompt; the CLI finds a session file only in the compact serialisation.
- **Weekly limit.** The profile holding the author sessions reached its weekly usage limit during design B, leaving three of 22 unwritten until 24 September, 7pm.
- **Three of 25 Opus drafting calls were refused** by a safety classifier, with the message that Opus 5's safeguards flagged the prompt. Verified from each arm's run log: the three refusals are the three missing cells and nothing else dropped a letter. The two arms with no method text, none and placebo, had no refusal, and all three refusals fell on method arms. Three cases cannot tell a coincidence from a classifier responding to the method text itself, and a refusal that is not independent of the draft would bias exactly the arms under test. A repeat should record the refusal rate per arm as a measure rather than as an operational note. The cells: the men's shed in method 1, the magazine in the composed arm, both refused again on retry, and the retirement village in method 2, whose retry succeeded after the blind extraction had already run, so its letter exists in `round2-drafts/` but not in the scored set.
- **Two approach files of the reused Sonnet baseline would not parse**, so that row rests on three messages of five. Both carried an unquoted colon inside a value, as did four other round-1 drafts and the campaign file itself. The Tcl loader tolerates it and a strict parser does not, so `validate_approach` passes a file that later tooling cannot read. An approach file that will not parse is a letter lost with no error raised at the time, which is worth its own issue against the harness rather than a line here.
- **Cost:** about $186 for round 2, of which about $64 went on the blocked Fable arms.
- **Worktrees are safe** for parallel arms: nothing in the libraries hardcodes a repo path, the workdir is per-process, the logs directory slugs the campaign path, and `--control-port=0` avoids the one port. They need `--force` to remove, since the harness patches roster TSVs in place.

## Files

- [prompts.md](prompts.md) — every appendix text used in both rounds, verbatim, and the sub-agent prompts for the scoring readers and the recipient role-play test.
- [setarm-round1.py](setarm-round1.py), [setarm-round2.py](setarm-round2.py) — swap a campaign YAML's appendices to one arm, keeping the constant block byte-identical.
- [blind.py](blind.py) — extract each approach file's final message to a plain-text file under a random name, key written beside it.
- [scores-round2.tsv](scores-round2.tsv), [key-round2.json](key-round2.json) — the blind scores and the arm key.
- [round3-rewrite/](round3-rewrite/) — rounds 3 and 4: `run-a.py`, `prompt-a.txt` and `split-a.py` for design A; `fork-sessions.py`, `rewrite-author.py` and `prompt-author.txt` for design B; `page-data.py` and `ab-evaluation.html` for the published evaluation; and, from round 3, `rewrite.py` and `prompt.txt` make the rewrites, `blind50.py` shuffles originals and arms together, `scorer-prompt.txt` is the reader's brief, `analyze.py` the paired comparison; `rewrites*/` hold both arms as returned and with preambles removed, `blind/` the 75 letters as scored, `key50.json`, `scores.tsv` and `scorer-report.md` the result.

- `round1-drafts/`, `round2-drafts/` — every approach file both rounds produced, one folder per arm.
- `round2-blind/` — the 25 letters exactly as the scoring reader saw them, subject and body, random names.

Round 1's per-message scores are gone. They were reported by five separate agents under drifting rubrics and were never written to a file, which is why the round-1 table should be read as a record that a run happened rather than as a result. Its drafts survive in `round1-drafts/`, so it can be rescored under one rubric if anyone wants a comparable number. The harness run logs are under `/var/local/log/spar/` in folders naming the arm and timestamp, and are not copied here.
