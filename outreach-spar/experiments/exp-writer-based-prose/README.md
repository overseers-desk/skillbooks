# exp-writer-based-prose

Can a guard placed around the drafting loop stop a letter carrying the writer's private reasoning to the reader? Nine attempts across two rounds, 22 September 2026. None worked. The faults that survived were all written before drafting began, in the campaign's own inputs, where no guard around the loop can reach them.

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

**The persona does not know what day it is.** §4.6 Step 1 gives C2 the profile and the draft and nothing else, so our framing cannot contaminate the reaction. That isolation also removes the fact that decides whether a time-bound offer is actionable. In the Songbirds draft the persona read a show two days away as advance notice: *"this is talking about September, so it's not solving my immediate problem, but a heads-up for later is fine"*, and *"I'd probably reply within a day or two if it fits our calendar"* — a reply time that lands after the show. Controlled comparison: the same persona, same draft, one line added ("Today is Tuesday 22 September 2026") opened with *"first thing I notice: that's two days away"* and rejected the ask on permission forms, bus booking and ratios.

## Attempts

Nine arms across two rounds, all delivered through `prompt_appendices`; no method document or prompt was edited. Every appendix text is in [prompts.md](prompts.md).

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

The Director rejected three strategies of the agent's own and supplied two: a reader's reference map with a separate resolvability score, and per-sentence scores for confusing / surprising / interesting with the author naming the question behind any surprising sentence. A placebo arm (an unrelated analytical pre-task of matched length) tests whether any pre-task alone sharpens the challenger.

Scored blind: one reader, 25 letters as plain subject and body under random names, no arm labels, key held apart ([blind.py](blind.py), [key-round2.json](key-round2.json), [scores-round2.tsv](scores-round2.tsv)).

| Arm | n | Nowhere | Surprise | Surprising 4-5 | False | Words |
|---|---|---|---|---|---|---|
| none | 5 | 4.2 | 1.17 | 0.8 | 1.2 | 269 |
| placebo | 5 | 4.2 | 1.18 | 1.2 | 2.0 | 268 |
| method 1, reference map | 4 | 3.0 | 1.21 | 0.75 | 1.75 | 227 |
| method 2, sentence scores | 4 | 3.25 | 1.49 | 1.5 | 2.25 | 230 |
| method 1+2 | 4 | 5.0 | 1.21 | 1.0 | 1.5 | 247 |
| earlier Sonnet run | 3 | 2.67 | 2.00 | 2.0 | 2.33 | 181 |

Paired on the two contacts present in all five arms, nowhere counts: seniors club 6 / 3 / 3 / 2 / 7; playgroup 5 / 4 / 3 / 4 / 4 (none / placebo / m1 / m2 / m12).

Method 1 is lowest or equal-lowest on both paired contacts and beats the placebo, so its effect is not mere priming. Four or five messages per arm separates nothing statistically and the direction is all this supports.

### Why the composed arm is not a test of the composition

In m1+m12 the challenger returned DONE at pass 1 on four of four drafts. No revision ran, so the author never saw a single score. Its numbers describe a first draft under a guard whose author-side half never fired. Method 2 alone went to revision on four of five, so its author step did fire.

## What survived every arm

| Fault | Letters carrying it, of 25 |
|---|---|
| An unintroduced booking link, code or details | 24 |
| "The seats are not on sale to the public" | 17 |
| "You were picked / chosen / held in your name" | 20 |

The first comes from the campaign's own drafting instruction, which reads "the code and the Eventbrite link go in the reply" — the definite article is in the instruction. Every author followed it faithfully.

The second and third come from the campaign's USP registry. `spar-campaign-yaml.md` states that a USP's claim is taken as written there, because the campaign was verified once when defined. So a false registry entry is approved by the fact-check in every letter it touches, by design. Both entries were known to be false and left in place deliberately as a constant across arms.

A guard around the writing cannot catch a fault that was not made during the writing. That is the finding.

## What did work, and it was not a guard

The date. Adding today's date to both the author and challenger prompts changed the persona from approving a two-day-away offer to rejecting it on operational grounds. That is a fix to an input, not a guard on the output. It landed in the method mid-experiment (commits 82d9ddb, 881215b, 41714cd on the aesop branch) along with the phone-only fix and a three-bin sorting in the revise step; verified from this experiment's own run logs, where "Today is Tuesday 22 September 2026" appears in 11 challenger and 15 author prompts of one arm, the phone-first contact's final round holds one phone message and no email, and every file of that arm carries the sorting in `revision_note`.

## Where to look next

The faults live upstream of the drafting loop, in the campaign's model messages and its USP registry. Three places worth a guard, none tested here:

1. **The model message.** A campaign's `first_ask` is prose written by whoever set the campaign up, and it goes into every draft. Nothing reads it for writer-based prose or for definite articles pointing at nothing.
2. **The USP registry.** It is the one document the fact-check treats as verified, and nothing verifies it. A registry entry asserting a fact about the world, as against a claim about the offer, has no check at all.
3. **The persona's information state.** The date fix shows the shape: the role-play is stripped of our framing, correctly, and of the recipient's own situation, incorrectly. What a real recipient knows and the isolation removes is worth enumerating.

## A measurement lesson

Round 1 was first scored by a different agent per arm. Their rubrics drifted: one counted the sender's name and role as an unsupported claim, contributing 8 of that arm's 16, and the others did not. Arm-level numbers were not comparable until one reader re-scored every set under one written rubric. Any repeat should score all arms in one pass, or the instrument varies more than the treatment.

## Operational notes

- **Fable is quota-limited.** All five Fable arms failed at the author call with "You've reached your Fable limit"; three produced nothing at all. The model axis is unmeasured, not negative.
- **The harness has no author-model setting.** `vendor/coachman-1.13.tm` hardcodes `--model sonnet` for any call that passes none, and the A-phase author calls pass none (`harness-1.0.tm:212, :283`), so `ANTHROPIC_MODEL` is overridden. Round 2 used a copied tree with that one line reading `SPAR_AUTHOR_MODEL`. The office belief that "A runs on Opus" was not true of any run before this.
- **Three of 25 Opus drafting calls were refused** by a safety classifier, twice on retry for two of them. Same contacts, different arms.
- **Cost:** about $186 for round 2, of which about $64 went on the blocked Fable arms.
- **Worktrees are safe** for parallel arms: nothing in the libraries hardcodes a repo path, the workdir is per-process, the logs directory slugs the campaign path, and `--control-port=0` avoids the one port. They need `--force` to remove, since the harness patches roster TSVs in place.

## Files

- [prompts.md](prompts.md) — every appendix text used in both rounds, verbatim, and the sub-agent prompts for the scoring readers and the recipient role-play test.
- [setarm-round1.py](setarm-round1.py), [setarm-round2.py](setarm-round2.py) — swap a campaign YAML's appendices to one arm, keeping the constant block byte-identical.
- [blind.py](blind.py) — extract each approach file's final message to a plain-text file under a random name, key written beside it.
- [scores-round2.tsv](scores-round2.tsv), [key-round2.json](key-round2.json) — the blind scores and the arm key.

The drafts themselves are not in this repo. Round 2's 25 letters and their approach files sat in the session scratchpad and the run logs are under `/var/local/log/spar/` in folders naming the arm and timestamp; both are ephemeral. A repeat should copy the approach files into the experiment folder as it goes.
