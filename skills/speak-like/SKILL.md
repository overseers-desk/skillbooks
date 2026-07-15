---
name: speak-like
description: Rewrite a draft so it speaks as an identity (human, director, aussie developer, any phrase), tuned by manner adverbs (--warmly, --tersely). Labels each line for AI tells and editorial violations, rewrites only the flagged lines, then smooths the seams. `speak-like human` is the pass for prose that must not read as AI-written. Accepts a judge's findings via --findings; optional project profile and dialect target.
argument-hint: <identity> [manner flags] [--profile <path>] [--dialect <varieties>] [--findings <path>] [--two-pass] <draft-path>
---

# speak-like

The writing skill. It rewrites a draft so the text speaks as the given identity — a human, a director, an aussie developer — touching only the lines that need it and leaving the rest alone. It is the counterpart of `this-guy-aint`, which is the detection skill: that one judges and edits nothing; this one writes and judges nothing. The two compose through a findings file, described below.

`speak-like human` is the most common invocation and is the old tell-tale: remove the signs of AI writing from prose, line by line. It works on any prose a model emits: documentation, posts, release notes, messages, briefs.

## Invocation

```
/speak-like human release-notes.md
/speak-like director --warmly board-update.md
/speak-like aussie developer --tersely --profile docs/style.md notes.md
```

The identity is every word before the first flag or path, compound as spoken (`aussie developer`). With no identity given, assume `human`.

Any flag that is not reserved (`--profile`, `--dialect`, `--findings`, `--two-pass`) is a **manner adverb**: `--warmly`, `--tersely`, `--formally`. Manner calibrates the writing within the identity — warmth from a director, not warmth plus costume. Manner never licenses performing the identity.

## Problem this skill exists to solve

A model writing prose leaves fingerprints: vocabulary that surged after late 2022, "not just X but Y" parallelisms, padded triads, clauses chained past the period, a press-release lilt. A reader who senses these stops trusting the text. And prose written under an assumed identity leaks in subtler ways: tourist vocabulary, overglossing, confidence in the wrong places. The job is to remove what the identity's real member would not have produced, without flattening the writing into something a model would equally have made — and without adding identity markers, because a costume worn at the reader is itself a leak.

A single sweeping rewrite cannot do that, because it cannot tell a clean sentence from a tainted one and ends up rewriting both. The discipline here is to separate the acts: first decide which lines need hands on them, then rewrite only those, then repair the joins. The label pass is **aiming, not a verdict** — it decides where the writer puts its hands, not whether the text passes as its author. Verdicts belong to `this-guy-aint`.

The codes come in two registers. Lowercase codes (`anti-pattern.md`) are AI tells, drawn from Wikipedia's "Signs of AI writing". Uppercase codes are editorial rules: the shipped base (`editorial-base.md`, Orwell's `W01`–`W06` and the `D01` dialect check) plus whatever a project adds through `--profile`. The two registers drive the edit threshold differently, below.

## Procedure

The draft must already be a file on disk; the passes read it by path, never from pasted text, so a shortened copy cannot blind them. Each pass runs as a fresh-context subagent (the reasons are below).

1. **Pass 1, label.** Spawn a subagent with the prompt at `${CLAUDE_PLUGIN_ROOT}/skills/speak-like/label-prompt.md`. Substitute `$ANTIPATTERN_PATH` with `${CLAUDE_PLUGIN_ROOT}/skills/speak-like/anti-pattern.md`, `$EDITORIAL_BASE_PATH` with `${CLAUDE_PLUGIN_ROOT}/skills/speak-like/editorial-base.md`, `$PROFILE_PATH` with the `--profile` path or `(none)`, `$DIALECT_TARGETS` with the `--dialect` value or `(none)`, and `$FILE` with the draft's absolute path. The subagent writes a `.sc` sidecar beside the draft (`report.md` to `report.sc`), one line per draft line, codes in brackets or empty. It aims only; it does not edit.
2. **Pass 2, edit.** Spawn a subagent with the prompt at `${CLAUDE_PLUGIN_ROOT}/skills/speak-like/edit-prompt.md`, the same substitutions plus `$SC_PATH` for the sidecar, `$IDENTITY` for the identity phrase, `$MANNER` for the manner adverbs or `(none)`, and `$FINDINGS_PATH` for the `--findings` path or `(none)`. The subagent rewrites every line over the threshold, repairs any judge-reported giveaways, then makes a minimum-touch smoothing pass over the whole file, writes the draft back, and updates the `.sc` (clearing fixed codes, suffixing unresolved ones with `?`).
3. **Review gate.** Present the summary report below to the user. Nothing is committed and no `.sc` is deleted until the user accepts.
4. With `--two-pass`, run a second label-then-edit cycle on the now-revised draft, to catch tells the first edit surfaced. Otherwise stop after one cycle.

### Edit threshold

A line is edited if its label holds **any uppercase code**, or **two or more lowercase codes**. A single lone lowercase code is tolerated: one AI-ism in an otherwise sound sentence is acceptable, a cluster is not. The threshold never inspects which letter an uppercase code carries, so base codes (`W`, `D`) and profile codes are treated alike.

### The `--findings` input

`--findings <path>` feeds the edit pass a cold reader's report — the VERDICT / GIVEAWAYS / PASSES sections a `this-guy-aint` judge produces. Each GIVEAWAY carries a quoted passage and what a real member would have done in its place; the editor repairs those passages by the judge's own direction, usually by saying it differently, often by saying less, sometimes by deleting. PASSES is a do-not-flatten list: a passage quoted there already carries the identity and is never rewritten. Findings flow one way, judge to writer; this skill never primes a judge.

### The `.sc` sidecar

The `.sc` is the diagnostic; the `.md` is the patient. Each `.sc` line corresponds to the same line number in the draft. The files are ephemeral working artifacts between Pass 1 and the user's accept or reject: they are not committed. A consuming repository should gitignore `*.sc`.

### Summary report

```
## Revision summary

### Counts
- Lines labelled:       <n>
- Lines edited:         <n>
- Lines tolerated:      <n>  (single lowercase code, not edited)
- Lines needing human:  <n>  (marked [code?])
- Giveaways repaired:   <n>  (only with --findings)

### By code (most frequent first)
  c01  ██████████  14
  c04  ████████    11
  W02  ████         5
  ...

### Sample edits (a few of the most changed lines)
  line 23  [c01][c04]  BEFORE: ...   AFTER: ...

### Lines needing human review
  line 67  [c05?]  Vague attribution, source unclear
```

Then ask: accept these edits? On accept, delete the `.sc` files and let the caller commit the edited draft. On reject, leave the `.sc` files in place as an audit trail and commit nothing; the user reviews with `git diff` and adjusts by hand.

## Composing with this-guy-aint

Two flows, one interface (the findings file):

- **Repair (detect → write).** Driven from the detector: `this-guy-aint <identity> --speak-like <identity> [manner] <draft>` judges first, hands its findings here, and re-judges once. See that skill.
- **Compose then gate (write → detect).** After speak-like rewrites under a non-trivial identity, the standing convention is to run `this-guy-aint <identity>` on the result before handover. The judge is always fresh context and is never told a rewrite happened.

## The profile and dialect seam

Without `--profile` and `--dialect`, the skill catches the lowercase AI tells and applies the Orwell base; `D01` stays inert. A project adds its own house rules by passing an editorial guide of uppercase-coded rules through `--profile`, and its target language variety through `--dialect` (or declared inside the profile). The profile's codes join the base under the same threshold. A profile must avoid the reserved prefixes `W` and `D`, which belong to the base.

## Model selection

Pass 1 is classification and runs well on the session's default tier. Pass 2 on a draft with only lowercase codes is mechanical and runs there too; a draft carrying uppercase codes or a findings file asks for editorial judgement, so escalating Pass 2 to a stronger model is worthwhile. This is guidance, not a hard pin.

## Files

`${CLAUDE_PLUGIN_ROOT}/skills/speak-like/`:

- `anti-pattern.md` — the lowercase AI-tell taxonomy, the living canonical home
- `editorial-base.md` — the shipped uppercase codes (`W01`–`W06`, `D01`)
- `label-prompt.md` — the Pass 1 subagent prompt
- `edit-prompt.md` — the Pass 2 subagent prompt

## Why fresh-context subagents

The labeller must judge the draft on the text alone, not on the intent the calling context remembers. A pass forked inside the caller's context would label what the author meant rather than what the page says. A brand-new agent reads only what a future reader will read. Keeping label and edit in separate subagents also stops the editor from trusting its own labelling instead of re-reading the line.
