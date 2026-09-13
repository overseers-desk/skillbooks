---
name: floor-and-fork
description: "A review or diagnosis has ended in a pile of findings that is about to reach the user. Read this before presenting the pile or acting on it. Triggers: floor-and-fork, f&f, floor and file."
argument-hint: "[optional: the findings or scope to work, when not already on the table]"
---

# Floor and Fork

A long review or diagnosis ends with a pile of findings, and the pile is the wrong shape for both parties. It holds clear fixes hostage to a discussion they do not need, and it hands the user a seventeen-entry questionnaire when the true number of decisions is three or four. This command reshapes the pile in two cuts — floor from forks, then masters from dependents — and gets the floor moving while the user's attention goes only where nothing can substitute for it.

Read the halfway-house skill before the first cut: it tells a decision an agent can settle into from one that is the path itself, and that distinction is what the sort below applies to each treatment. The floor/fork test is the one the standing Floor & File rule sets (office methodology; coding and debugging work is its scope), applied here to treatments rather than findings. A finding names a problem, and a problem admits treatments of different size and cost; a finding that reads as a tradeoff is usually a small certain fix wearing a large uncertain one. A treatment is floor when it is reversible at its own cost, sits inside authority already granted, and its worst case is no effect: a second competent engineer would make it the same way. A fork is a treatment that cannot be taken without the user's answer: design intent, his circumstance, a tradeoff with no dominant arm. A better treatment existing for the same problem disqualifies neither, and neither does the floor treatment being partial. A single treatment sitting on the line is a fork: floor mistaken for fork costs one question, a fork mistaken for floor spends the user's veto.

## 1. Cut one: floor from forks

Decompose each finding on the table (or the scope given as argument) into the distinct treatments it admits, cheapest first, and sort each treatment on its own. The treatments are the ones the finding names or that fall out of it without design work; a guard or scaffold invented so that the pile has a floor item is a solution without a problem, the mirror of a fork raised for the sake of having forks. Where a problem has a floor treatment and a larger one that needs a decision, the floor treatment joins the floor and the larger one joins the forks as the question of whether to go further, naming what the floor already buys; the user chooses whether to go further, not whether to start. A treatment the sort leaves out of both piles states its predicted effect and its price, since an unpriced refusal hides a decision rather than filing it, and a finding whose smallest treatment was never priced has not been sorted. Per the standing rule, a treatment earns the bug label only after confirming code could perform it; what nothing in code can fix is an operational caveat and belongs in neither pile.

## 2. Cut two: masters from dependents

A seventeen-fork list overstates the decision load, because forks are rarely independent: many hang on a few. Fork B hangs on fork A when A's answer settles B outright, turns B into floor, or shrinks it to a question answerable in one breath. A fork with several dependents is a master decision, and the measure of a candidate is this: decided either way, how many entries beneath it change category or shrink? The count of masters, not the count of forks, is the true size of the discussion. Forks nothing hangs on stay standalone. This cut orders forks only: a treatment the first cut put on the floor stays there, and a fork that might later rewrite the same code does not turn a correction owed today into its dependent.

## 3. Present the floor and forks, ask once

In order:

- **Floor** — numbered, one line per item, the fix named concretely enough to veto on sight.
- **Master decisions** — one section per master: the decision itself, which dependents it settles, and beneath it each dependent annotated with its fate under the plausible answers ("with X this becomes floor; with Y it is a one-line question").
- **Standalone forks** — the remainder, each with its most sensible default named, and a filed larger treatment carrying what its floor already bought.

Close with a single question: ready to send the floor to a subagent? No edits land before that answer.

## 4. Floor in the background, decide in the foreground

On yes, hand a subagent the floor list — precise locations, the named fix per item — to apply with staged commits, one coherent step each. Stay in the conversation yourself and take the masters biggest-unlock first: the one that settles the most dependents opens the discussion.

After each master is decided, re-derive its dependents. Those that became floor join the next flooring wave, dispatched when the running subagent returns (one tree, one writer: while a wave runs, the foreground stays discussion-only). Those that became simple questions get asked now, while the master's context is warm — the point of the ordering is that the user answers them from the decision just made, not from fresh study.
