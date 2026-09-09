---
name: other-side
description: "Work out what an adversary, counterparty, or assessor will do, say, or conclude, from what they hold rather than from what we hold. A fresh agent answers from a ledger of the party's information, gated by a checker that knows nothing of our side. Triggers: other-side, what will they say, think from their perspective, what does the other side know, put yourself in their shoes, what would a rival bidder make of this, red-team our position."
argument-hint: "<who the other party is> <the question, in one sentence>"
---

# other-side

## Problem this skill exists to solve

Asked what the other party will do, an agent answers from everything in its context: the files it has read, the conversation, the inferences it has drawn. Much of that the other party does not hold. The answer then describes an opponent who knows our internal notes, our headcount, our unsent drafts, and it is confidently wrong in a direction that flatters our fears. Psychology calls this the curse of knowledge: once a fact is known it cannot be un-known for the purpose of modelling someone who lacks it. No instruction to "forget" removes a fact from an agent's computation, and no agent that has read our files can play a party who has not.

The failure is compounded from the other direction. The party holds things we do not: what they were told in person, what they saw, complaints they made that never reached a file. An agent given a filtered slice of our documents has none of that and returns a confident under-estimate.

The remedy is a partition of information, not of instruction. The party's view is computed by an agent that receives only the party's information, and that information is assembled as a ledger in which every item says how the party came to hold it.

## Procedure

1. **Name the party and the grade.** The grade is the state of the party's knowledge at the moment the question concerns. A rival bidder at tender close holds less than the same rival after the contract award is published; a plaintiff framing a claim holds less than their counsel after discovery. Where the owner's question spans grades, run each grade as its own impersonation. The default is one grade, the moment named in the question.

2. **Draft the ledger** to a scratchpad file, following `${CLAUDE_PLUGIN_ROOT}/skills/other-side/ledger-template.md`. Each item the party holds carries a provenance mark: the channel by which they came to hold it and the date. An item you cannot mark is a candidate, not an entry. The second section, what the party knows and we do not, is authored from the owner's knowledge, and the template says it is incomplete so the impersonator treats it as such. The question goes in last, phrased as the party would meet it.

3. **Confirm provenance, from the record first.** Sending, signing, attending are facts about the world that files often do not record; a draft in our tree may never have left it. For every unmarked candidate and every mark you inferred, look first for the owner's own statement of it: the conversation so far, a peer session's transcript, a sent-mail log, a signed copy. A statement by the owner is a confirmation wherever it sits, and the owner is not asked what the record already answers. What the record leaves unsettled goes to the owner as one batched message, each line the item and the mark you propose, and the turn stops there. When no owner is in the loop (a subagent, an unattended run), return that batch as the result and go no further: a mark set by inference is the leak this skill exists to prevent. Unconfirmed candidates are dropped, not assumed.

4. **Anti-cheat block on the question.** Before spawning anything, write in a labelled block: the question as it will be sent; each fact the wording presupposes; whether each has a ledger entry. Reword until every presupposition is either in the ledger or gone.

5. **Checker.** Spawn a fresh general-purpose agent with `model: "sonnet"` using `${CLAUDE_PLUGIN_ROOT}/skills/other-side/checker-prompt.md`, substituting `$LEDGER_PATH`. It receives the ledger path and nothing else. It knows nothing of our side, which is why it can see what the wording carries in: it returns PRESUPPOSED (facts the question assumes with no ledger entry), IMPLAUSIBLE (items whose mark does not fit how such a party comes by such a thing), and CLEAN. Repair the ledger or the question and rerun until CLEAN. The checker does not read our files, and its report never contains the repair, which is yours.

6. **Impersonator.** Spawn a fresh general-purpose agent using `${CLAUDE_PLUGIN_ROOT}/skills/other-side/impersonator-prompt.md`, substituting `$LEDGER_PATH`, one per grade. Pick the model for the stakes: a claim or a contract at risk earns the strongest model; a rehearsal earns Sonnet. The prompt forbids tool use beyond reading the ledger file; the agent must not reach our tree. It returns ANALYSIS (the party's answer, in the party's frame), ASSUMED (what it filled in, as the party would), and WOULD SEEK (what the party would try to find out next).

7. **Reconcile.** Read ANALYSIS against your own view. Every fact you want to argue back with that has no ledger entry is a fact the party does not hold; list those, since they are where our side's picture and theirs diverge. WOULD SEEK names what the party's next grade would contain. Deliver the impersonation, the divergence list, and WOULD SEEK to the owner. The skill decides nothing about our response; that is the owner's.

## Files

`${CLAUDE_PLUGIN_ROOT}/skills/other-side/`:

- `ledger-template.md`: the shape of the party's information set, with provenance marks
- `checker-prompt.md`: the ignorant checker's prompt
- `impersonator-prompt.md`: the party's agent's prompt

## Why the impersonator has no tools

Every leak in the case that produced this skill entered by the agent's own reading of the repository, not by the prompt. Withholding at prompt level does nothing when the agent can open the tree. The impersonator reads one file, the ledger, and reasons from it and from what any member of the public knows.

## Why the checker knows nothing of our side

A checker that has read our files carries the same curse as the caller and passes the same leaks. Ignorance is the checker's instrument: a presupposition in the question is visible to it exactly because it cannot supply the missing fact itself. The one leak it cannot catch is a wrongly marked provenance, which only the owner can catch, and which step 3 is for.

## Anti-cheating discipline

Examples in the template and prompts come from domains other than any case this skill is run on, so an agent applies the rule rather than recognises a remembered phrase. The checker and impersonator prompts carry the ledger path and no hint of what the caller hopes they will find.
