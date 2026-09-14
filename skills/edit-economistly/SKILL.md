---
name: edit-economistly
description: Edit a draft markdown file to The Economist editorial standard via a fresh-context Sonnet subeditor spawned with the Agent tool. `--two-pass` gets better result.
argument-hint: <path-to-draft.md> [--two-pass]
---

# edit-economistly

## Problem this skill exists to solve

Reports written by an AI agent tend to read like the agent's internal monologue. The agent has the source material, the chain of investigation and the prior conclusions in its conversation, and its prose carries scaffolding the reader cannot decode. Named entities arrive unglossed, dates carry no significance, claims arrive without source, sections begin with throat-clearing about what the report "will show". Subjects sit far from their verbs because the writer is loading qualifiers from inside its own thinking. A reader who was not in the authoring conversation cannot follow it.

A general maxim in CLAUDE.md asking the author to write for a cold reader is not enough on its own. The author cannot see its own scaffolding. The fix is a separate cold reader: a fresh-context subeditor who reads the draft the way a Singaporean lawyer or Kenyan economist would, applies the mechanical fixes itself, and asks the author about the substantive gaps and sentence-architecture problems it cannot resolve alone.

## What you (the author) should bear in mind

Before revising in response to the subeditor's queries, hold one principle in mind: **the pair of words you are connecting should sit as close together as the sentence allows.** This is dependency grammar's reading of "easy to read". When a query points at a sentence whose subject and verb are nine words apart, the rewrite is not to find better words; it is to bring those two words closer, usually by splitting the sentence or demoting a parenthetical. Cut meta-prose about the document's structure ("this document covers …", "those are not restated here"). Compound modifiers stacked three deep are a warning sign that you are still writing from inside your filing system.

## Invocation

```
/edit-economistly path/to/draft.md            # one pass (default)
/edit-economistly path/to/draft.md --two-pass # two passes with verification
```

If the second positional argument is `--two-pass`, the skill runs the editor a second time after the caller's revisions, to verify that round-1 queries are addressed and flag anything the revisions surfaced. Without `--two-pass`, the skill runs only round 1; the caller still revises and the polish stops there.

Default is one pass because the spar in two-pass mode roughly doubles the API cost and adds ~10 minutes of wall time; one pass is the right shape for most drafts, two passes for drafts that need to read at *Economist* standard rather than just better than they started.

## Procedure

The skill **never commits**. Whatever mode you run in, the draft is left edited and uncommitted; you decide whether to commit. The skill expects the draft to be committed *before* invocation so the editor's changes can be inspected via `git diff HEAD -- <draft>`.

### Round 1 (always runs)

1. **Confirm the draft is committed** (clean working tree for that file). Commit any uncommitted changes first, or discard them.
2. **Spawn a fresh-context subeditor with the Agent tool.** Use a fresh general-purpose agent. The prompt template is at `${CLAUDE_PLUGIN_ROOT}/skills/edit-economistly/editor-prompt.md`; substitute the two placeholder paths, leave `$CARRIED_QUERIES` empty, and pass it as the agent prompt. The agent will read the stylebook (including R13 on dependency grammar) and the draft, apply class-A fixes in place via its Edit tool, and return a list of author queries as its single response message.
3. **Read the agent's response.** It opens with a line `Queries: N`, then N queries each headed by the rule it fails. A reply whose first line is anything else, or whose count does not match the queries beneath it, is a malformed reply: read it anyway, but the number is not to be trusted. The actual edits are on disk; inspect with `git diff HEAD -- <draft>` or `git diff --word-diff HEAD -- <draft>`.
4. **Revise but do not commit.** Address each query using sources you have in conversation, or leave it and note the unresolved item in a `## Unresolved` block at the foot of the draft. Do not invent. Keep dependency grammar in mind: when you rewrite a sentence the editor flagged for R13, bring the dependent words closer; do not just swap synonyms.

   **Tag each query as you go**, one word: `addressed` if your revision answers it, `kept-by-author` if you considered it and decided the draft stands, `unresolved` if it is waiting on something you do not have. Keep the query text beside the tag. Round 2 needs this list, and it cannot be reconstructed afterwards from the diff, which shows what changed but not what you weighed and rejected.

If you invoked without `--two-pass`: stop here. The draft is edited and uncommitted; commit when satisfied.

### Round 2 (only if `--two-pass` was passed)

5. **Spawn a fresh-context subeditor a second time** on the now-revised but still-uncommitted draft, substituting your tagged round-1 list into `$CARRIED_QUERIES`. Pass the query text and the tag, nothing else: not the source that settled a query, not why you kept what you kept. The round-2 subeditor reads the draft as it now stands (including your revisions) and verifies that round-1 queries are addressed, flagging anything that remains or any new issue your revisions surfaced. It will not re-raise anything you tagged `kept-by-author`.
6. **Revise again** (still without committing) if round 2 has substantive queries. If round 2's queries are trivial or empty, the polish is settled.

### Done (both modes)

7. **You commit on your own decision.** The skill does not commit. The user can read `git diff HEAD -- <draft>` to see all changes from this polish in one diff. You may also invoke the skill again on the now-committed draft for an additional cycle.

If you want to recover token budget after committing, the user can manually roll back the conversation to before the polish step. The committed draft survives; the spar chatter does not need to.

## Skill files

`${CLAUDE_PLUGIN_ROOT}/skills/edit-economistly/` holds:

- `economist-stylebook.md`: the editorial standard (twelve Style-Guide rules plus R13 on dependency grammar)
- `editor-prompt.md`: the subeditor prompt template
- `source/style_guide_12.pdf`: published Style Guide, citation source for R1–R12

## Why one fresh-context subeditor per round, and why no auto-commit

The subeditor stays fresh-context because that is the cold reader's eye the author lost when it wrote the report. The author role belongs to the caller, which has the source material in its own conversation context; a fork of the caller as an internal author subagent would not work because Claude Code subagents do not inherit caller conversation history, and that conversation is where the research actually lives.

The skill never commits because git is the user's control surface. The user inspects `git diff HEAD` after the polish settles and commits when satisfied, or discards via `git checkout`. A skill that creates new edited content has no expectation that it should also commit on the user's behalf.

## Anti-cheating discipline

The `--two-pass` flag is a workflow knob, not a content hint. The skill takes no per-invocation hint flags ("--check-for-X") by design. The subeditor receives the stylebook, the draft, and on a second pass the round-1 queries with their tags; no fixture-specific guidance is ever leaked into the prompt. The stylebook articulates general editorial principles only; rule examples must come from outside any test fixture so the subeditor cannot recognise the expected answer.

The round-2 carry-forward stays inside that discipline because of what it withholds. A query plus `kept-by-author` tells the second subeditor that a question was asked and closed. It does not tell it what the answer was, which source settled it, or what the author thought. So the second pass still arrives at the prose cold, with no view of where the author already looked, and reads it for what it says rather than for what it has been through. Passing the reasoning, or the revision diff, would hand over both.
