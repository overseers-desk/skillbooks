---
name: this-guy-aint
description: Run on anything written under an assumed identity (human, aussie, developer, artist, manager, or any phrase) before handing it over: a fresh-context reader who is one judges whether he believes the author is what the author claims to be, and reports the giveaways. Detection only; the judge edits nothing. Comma-separate identities for one verdict each. --speak-like hands the findings to the speak-like skill for repair and re-judges once. `this-guy-aint human` is the light gate for short pieces and code with comments where speak-like's line pipeline is too heavy. `this-guy-aint Gradgrind` is the gate for a brief written to another agent: the judge sits at the addressee's desk and lists every line that closes ground with the authority it names, for the caller to answer.
argument-hint: <identity>[, <identity>...] [--speak-like <identity> [manner flags]] [<draft-path> | --staged]
---

# this-guy-aint

A reader picks up a text whose author is supposed to be a developer, an Aussie, a manager, a person. Three lines in he thinks: this guy ain't. He usually cannot cite a rule; belief just broke. This skill puts that reader in front of the text before the real one gets it. It is the detection skill: the judge returns a verdict and the giveaways, and edits nothing. Its counterpart is `speak-like`, the writing skill; the two compose through the judge's findings file, and `--speak-like` runs that composition in one command.

## Problem this skill exists to solve

Writing produced under an instruction to be some identity often fails as that identity, and the author cannot see the failure because it knows the instruction was followed. The failure is not usually a false fact; it is a false voice. The vocabulary is about the trade rather than of it, the text explains what any member already knows, the confidence sits on the wrong claims, the identity arrives as costume. A real member reading it feels the wrongness immediately, even when the content is fine. Four categories are the exception to feeling: restate, secretary, gradgrind, and officialese name registers that read as thorough, competent, decisive, and courteous and so trip no felt read, least of all the judge's own, so the judge checks the draft against those four deliberately after its felt read (issue #170 is the reference case for the register pair; restate earned its place from a 115-document workplace-corpus audit where closing summaries and re-announced rules were the strongest single marker of non-member authorship).

The goal of the writing is never the impersonation; it is the work, done in that identity, without leaking that a non-member did it. So the skill detects leaks only, and demands no performance: plain, unopinionated, workmanlike text is fully believable, because members write that way all the time. Overplaying the identity still gets caught, not as bad acting but as a leak in its own right — a costume worn at the reader is itself something no member would produce. The verdict is a reader's, not a coach's.

The check must run in fresh context. The author wrote under the instruction and cannot un-know the effort it made to comply; a fork of the author would grade the intention. The judge knows only the claim and the text, which is exactly what the real reader will know.

The most common invocation is `this-guy-aint human`: does this read as written by a person at all? That is a lighter instrument than speak-like, suited to things speak-like's line-by-line pipeline is too heavy for — a code file with comments, a commit message, a short reply, a bio line. The boundary: speak-like writes, with sidecars and thresholds; this-guy-aint reads once, believes or does not, and hands back why. A long prose draft that fails `this-guy-aint human` is a candidate for `speak-like human` — or run both at once with `--speak-like`.

One identity is a figure the author must not be rather than one it claims: `Gradgrind`, after the schoolmaster in Hard Times who forbids Sissy Jupe to fancy flowers on a carpet. It is for a brief written to other agents, the case where an author with the standing to recommend closes ground in its own voice, and grants the leftover. The judge for that word sits in the addressee's seat, the agent the brief is written to, and reads only the brief. Its report is a listing rather than a felt verdict: every line that closes something, with the authority the line names or `none named`. The caller, who holds the project, answers each line as ruled by someone dated and named, or as the recommended answer the reader may depart from with a citation, and rewrites the line to say which. A reading judge samples under a block header that attributes every line beneath it, and a run of this skill over a brief that hid five defaults among eight rulings under "these are ruled" passed it; so the prompt asks for each line under such a header on its own, and the caller's answering pass is the check, with the listing as its worksheet. What the judge cannot see, a parameter the brief leaves off its competed list altogether, is outside this seat; where the project enumerates its parameters, walking that enumeration against the brief is the caller's own pass.

## Invocation

```
/this-guy-aint human path/to/reply.md
/this-guy-aint aussie developer path/to/notes.md
/this-guy-aint developer --staged
/this-guy-aint human, director --speak-like director --warmly path/to/update.md
/this-guy-aint Gradgrind briefs/game-arm.md
```

Every word before the path or flag is the identity phrase, so compound identities work as spoken: `aussie developer`, `first-time manager`, `working artist`. Comma-separated identities (`human, director`) each get their own fresh judge and their own verdict, because belief in "a human" and belief in "a director" break in different places. With no identity given, assume `human`.

Everything after `--speak-like` (an identity and any manner adverbs like `--warmly`) is forwarded verbatim to the `speak-like` skill, which repairs the draft from the judges' findings; the composed flow is step 6 below. `--speak-like` with `--staged` is rejected: the judged draft is a scratch copy of a diff, and there is nothing to write the repair back to.

## Procedure

1. The draft must be a file on disk; the judge reads it by path, in full, never from pasted or condensed text. Content composed in conversation and not yet anywhere gets written to a scratchpad file first. With `--staged`, the draft is the staged diff: write the full output of `git diff --cached` to a scratchpad file and use that as the draft.
2. Spawn one fresh-context general-purpose agent with `model: "sonnet"` per comma-separated identity. The prompt template is at `${CLAUDE_PLUGIN_ROOT}/skills/this-guy-aint/judge-prompt.md`, or `${CLAUDE_PLUGIN_ROOT}/skills/this-guy-aint/gradgrind-prompt.md` when the identity is `Gradgrind`; substitute `$IDENTITY` with that identity phrase, `$DRAFT_PATH` with the draft's absolute path, and `$GIVEAWAYS_PATH` with `${CLAUDE_PLUGIN_ROOT}/skills/this-guy-aint/giveaways.md`. Add nothing that telegraphs what you suspect the judge will catch, and do not say who or what wrote the draft.
3. Each judge returns VERDICT (believed or not, with the moment belief broke if it did), GIVEAWAYS (quote, category, what a real member would have done instead), and PASSES (what already carries the identity, so a fix does not flatten it). The Gradgrind judge returns VERDICT (GRADGRIND or AIN'T), CLOSINGS (quote, the authority the line names, what a colleague would have written), and PASSES (closings that carry their authority on the line). Write the judges' reports to a scratchpad findings file — one file, a `## <identity>` section per identity, each holding that judge's three sections verbatim. The findings file is the interface to `speak-like` and exists whether or not anything consumes it.
4. **As a gate**, which is the standing use: when you have written something under an assumed identity and are about to hand it to the user, run this skill first. If the verdict is not believed, fix the giveaways yourself — you hold the intent, and PASSES tells you what to leave alone — and re-run once. If the second verdict still fails, hand the work over anyway with the remaining giveaways attached; do not loop, and do not silently ship a failing draft. For `Gradgrind` the fix is an answer per CLOSINGS line, `mark only`, `header only` and `none named` lines included: attach the dated ruling, or rewrite the line as the recommended answer with its evidence and the reader's freedom to depart from it; a line you cannot attribute is a default, whatever verb it used.
5. **On request**, when the user points the skill at existing content: report the verdicts and giveaways and stop. Fixing is the user's call — unless `--speak-like` was given. `--speak-like` does not compose with `Gradgrind`: its findings are answered from the project, not rewritten from the page.
6. **With `--speak-like`**, run the composed repair flow: invoke the `speak-like` skill with the forwarded identity and manner adverbs, the draft path, and `--findings <scratchpad path>`. The writer runs even when every verdict is BELIEVED, because a manner request like `--warmly` is unconditional; the findings are just thinner. After speak-like's review gate, spawn one fresh re-judge per original identity — a brand-new judge, never told a repair happened, primed with nothing — and report before/after verdicts side by side, with any remaining giveaways attached. One round only: one repair, one re-judge, then hand over; do not loop.

## Files

`${CLAUDE_PLUGIN_ROOT}/skills/this-guy-aint/`:

- `giveaways.md` — the taxonomy of ways belief breaks
- `judge-prompt.md` — the judge subagent prompt template
- `gradgrind-prompt.md` — the prompt for the addressee's seat, used when the identity is `Gradgrind`

## Why a fresh-context subagent

The reader this skill simulates knows the claim and nothing else. The calling context knows the instruction, the persona effort, and the conversation, and would read all three into the text. Fresh context is not a convenience here; it is the mechanism. The judge is also never told the author is a model, because the question is impersonation-agnostic: a human faking a trade fails the same reading, and a judge told to hunt AI would hunt tells instead of reading.

## Anti-cheating discipline

The prompt carries the identity phrase, the taxonomy path, and the draft path; nothing about the draft's origin or the caller's suspicions leaks in. Taxonomy examples come from outside any test fixture, so the judge applies the category rather than recognising a remembered phrase. The judge reads the draft in full from its file, so the reading covers every line rather than the ones the caller happened to keep.
