# S-phase on local inference: Qwen3-30B-A3B via ollama

Does a model on the owner's own hardware sweep as well as hosted Claude? This folder holds the local arm. The hosted arm's sweep of the same subject, horse supply for the estate, sits on the campaign repository's `main` branch as the control.

Read **FINDINGS.md** first. It is the answer, and it carries its own corrections where a claim was withdrawn.

## What each file is for

**FINDINGS.md** — what the run established, in the order it was learned, including the several places an earlier conclusion here was wrong and what replaced it. The short version: the model was never the constraint, most of a worker's prompt was the operator's own injected context, and a chain of timeout defaults assumed a request finishes in minutes.

**BRIDGE.md** — the configuration that works, preserved because it lives outside version control in a wrapper under a home directory. Read this before rebuilding anything.

**METHOD.md** — how the two arms are to be scored, written and committed before any result existed so the scoring could not be shaped to fit. It adapts the July blind-judging study and adds the ground-truth half that study omitted.

**control-arm-baseline.md** — a sample of the hosted arm's rows checked for whether the businesses exist and sit in catchment. It also records that the catchment half of the test discriminates poorly, which is a finding about the test rather than the rows.

**harvest_timings.py** and the dated CSVs — per-request prefill, generation and queue waits, harvested from the model server's own log. Re-runnable while a job is in flight. The summary is in `2026-09-21-timing-summary.md`.

**compare-rosters.py** — counts and overlap between two arms' rosters, matching on business and locality rather than on stem, with a guard for rows whose organisation field holds a category label instead of a name.

## What is not here

Roster rows from the local arm, and therefore the comparison the experiment exists to make.

The reason is a ceiling rather than slowness. Three limits sat in a row, each hidden by the one in front of it, and the last of them kills any worker whose turn needs more than 600 seconds of prefill. On this hardware that is a prompt of about 13,000 tokens, which a sweep's conversation passes after a handful of turns, so every source is attempted, killed, retried and killed again. All three are now cleared for the running arm and none had been when the earlier attempts were made.

## What the arm has established about the model

One finding, and it is about judgement rather than output. Twice, on two segments, the worker stated in its own reasoning that its first step was to read the segment definition, then made no read call at all and went to the data. On the first segment that mattered: it spent two hours enumerating a population its own sweep record says cannot be enumerated, which is work the hosted arm had considered and declined. A model that skips the framing and goes to the data looks productive and does the wrong thing.

## The scope caveat, stated plainly

This arm was handed the groundwork: the segment definitions, the family sweeper, the market-size estimates and the list of where to look. The hosted arm derived all of it itself. So a comparison drawn from this folder speaks to finding and recording members of a defined segment, and not to whether a local model can frame a sweep. That second question needs an arm that starts where the hosted one did.
