# exp-writer-based-prose

Can a guard placed around the drafting loop stop a letter carrying the writer's private reasoning to the reader? Ten arms across two rounds, 22 September 2026. None worked. The faults that survived were all written before drafting began, in the campaign's own inputs, where no guard around the loop can reach them.

## Problem

Writer-based prose, in Linda Flower's sense, is prose organised by the writer's own path through a problem rather than by what the reader needs. A drafting agent produces it in a recognisable form: it names a thing with a definite article that the reader has never met, and it answers questions the reader never asked.

The letters under test invited local organisations to a circus season at a venue. Three specimens, from a campaign whose messages had already been through the mandatory A2 spar:

- "Reply and I will send you **the** booking link and **the** code" — no code and no link have been mentioned.
- "Following **our call**" — a template written before the call it follows. The phone-only pattern produces it by design: SPAR-A §4.2 asked for an email "for once an address is obtained on the call", so the follow-up is drafted in the past tense about an event that has not happened.
- "The opening-week seats aren't on sale to groups" and "an excursion in two days isn't realistic" — both answer a question the recipient never asked. The second caveats an offer the letter has not yet made.

The existing guard is SPAR-A §4.6 Step 1: a context-isolated agent plays the recipient and reacts before any fact-check. It passed all three. Its own words on the first, recorded in the approach file: *"nothing about the email itself smells like spam — it's specific, personalised, and low-pressure"*, with `REPLY_PCT: 55`.

## Why the existing guard misses it

Two reasons, both structural rather than a failure of the agent.

**The persona construes.** A model told to react in character makes sense of whatever it is given. Faced with "an excursion in two days isn't realistic" it infers an excursion was offered and carries on. A real recipient with a room full of children does the same, faster. So the reader who would notice the gap is exactly the reader the role-play is not.

**The persona does not know what day it is.** §4.6 Step 1 gives C2 the profile and the draft and nothing else, so our framing cannot contaminate the reaction. That isolation also removes the fact that decides whether a time-bound offer is actionable. In the draft for Songbirds Early Learning at Pimpama, a vacation-care service, the persona read a show two days away as advance notice: *"this is talking about September, so it's not solving my immediate problem, but a heads-up for later is fine"*, and *"I'd probably reply within a day or two if it fits our calendar"* — a reply time that lands after the show. Controlled comparison: the same persona, same draft, one line added ("Today is Tuesday 22 September 2026") opened with *"first thing I notice: that's two days away"* and rejected the ask on permission forms, bus booking and ratios.

## Attempts

Ten arms across two rounds, five per round, all delivered through `prompt_appendices`; no method document or prompt was edited. Every appendix text is in [prompts.md](prompts.md).

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
- **Three of 25 Opus drafting calls were refused** by a safety classifier, with the message that Opus 5's safeguards flagged the prompt. Verified from each arm's run log: the three refusals are the three missing cells and nothing else dropped a letter. The two arms with no method text, none and placebo, had no refusal, and all three refusals fell on method arms. Three cases cannot tell a coincidence from a classifier responding to the method text itself, and a refusal that is not independent of the draft would bias exactly the arms under test. A repeat should record the refusal rate per arm as a measure rather than as an operational note. The cells: the men's shed in method 1, the magazine in the composed arm, both refused again on retry, and the retirement village in method 2, whose retry succeeded after the blind extraction had already run, so its letter exists in `round2-drafts/` but not in the scored set.
- **Two approach files of the reused Sonnet baseline would not parse**, so that row rests on three messages of five. Both carried an unquoted colon inside a value, as did four other round-1 drafts and the campaign file itself. The Tcl loader tolerates it and a strict parser does not, so `validate_approach` passes a file that later tooling cannot read. An approach file that will not parse is a letter lost with no error raised at the time, which is worth its own issue against the harness rather than a line here.
- **Cost:** about $186 for round 2, of which about $64 went on the blocked Fable arms.
- **Worktrees are safe** for parallel arms: nothing in the libraries hardcodes a repo path, the workdir is per-process, the logs directory slugs the campaign path, and `--control-port=0` avoids the one port. They need `--force` to remove, since the harness patches roster TSVs in place.

## Files

- [prompts.md](prompts.md) — every appendix text used in both rounds, verbatim, and the sub-agent prompts for the scoring readers and the recipient role-play test.
- [setarm-round1.py](setarm-round1.py), [setarm-round2.py](setarm-round2.py) — swap a campaign YAML's appendices to one arm, keeping the constant block byte-identical.
- [blind.py](blind.py) — extract each approach file's final message to a plain-text file under a random name, key written beside it.
- [scores-round2.tsv](scores-round2.tsv), [key-round2.json](key-round2.json) — the blind scores and the arm key.

- `round1-drafts/`, `round2-drafts/` — every approach file both rounds produced, one folder per arm.
- `round2-blind/` — the 25 letters exactly as the scoring reader saw them, subject and body, random names.

Round 1's per-message scores are gone. They were reported by five separate agents under drifting rubrics and were never written to a file, which is why the round-1 table should be read as a record that a run happened rather than as a result. Its drafts survive in `round1-drafts/`, so it can be rescored under one rubric if anyone wants a comparable number. The harness run logs are under `/var/local/log/spar/` in folders naming the arm and timestamp, and are not copied here.
