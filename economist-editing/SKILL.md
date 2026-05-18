---
name: economist-editing
description: Edit a draft markdown file to The Economist editorial standard via a fresh-context Sonnet subeditor spawned with the Agent tool. The subeditor edits in place; queries the editor cannot answer alone come back in its response message for the caller to address. The skill mandates two passes (editor → author revision → editor verification) and never commits. Use when the caller asks to apply Economist-style editing to a markdown document, or invokes /economist-editing.
argument-hint: <path-to-draft.md>
---

# economist-editing

## Problem this skill exists to solve

Reports written by an AI agent tend to read like the agent's internal monologue. The agent has the source material, the chain of investigation and the prior conclusions in its conversation, and its prose carries scaffolding the reader cannot decode. Named entities arrive unglossed, dates carry no significance, claims arrive without source, sections begin with throat-clearing about what the report "will show". Subjects sit far from their verbs because the writer is loading qualifiers from inside its own thinking. A reader who was not in the authoring conversation cannot follow it.

A general maxim in CLAUDE.md asking the author to write for a cold reader is not enough on its own. The author cannot see its own scaffolding. The fix is a separate cold reader: a fresh-context subeditor who reads the draft the way a Singaporean lawyer or Kenyan economist would, applies the mechanical fixes itself, and asks the author about the substantive gaps and sentence-architecture problems it cannot resolve alone.

## What you (the author) should bear in mind

Before revising in response to the subeditor's queries, hold one principle in mind: **the pair of words you are connecting should sit as close together as the sentence allows.** This is dependency grammar's reading of "easy to read". When a query points at a sentence whose subject and verb are nine words apart, the rewrite is not to find better words; it is to bring those two words closer, usually by splitting the sentence or demoting a parenthetical. Cut meta-prose about the document's structure ("this document covers …", "those are not restated here"). Compound modifiers stacked three deep are a warning sign that you are still writing from inside your filing system.

## What this skill is

You (the caller) are the report-writing session. This skill polishes one of your own drafts to *The Economist* standard by spawning a fresh-context subeditor twice — once to edit and diagnose, once to verify your revisions. You own the spar: the subeditor edits and asks; you revise; the subeditor verifies; you decide when to commit.

## Procedure (mandatory two passes; the skill never commits)

### Round 1

1. **Commit the draft first.** Any uncommitted changes get folded into what the editor's diff shows. Clean working tree before invoking.
2. **Spawn a fresh-context subeditor with the Agent tool.** Use a fresh general-purpose agent. The prompt template is at `$HOME/.claude/skills/economist-editing/editor-prompt.md`; substitute the two placeholder paths and pass it as the agent prompt. The agent will read the stylebook (including R13 on dependency grammar) and the draft, apply class-A fixes in place via its Edit tool, and return a list of author queries as its single response message.
3. **Read the agent's response.** The response is the list of queries. The actual edits are on disk; inspect with `git diff HEAD -- <draft>` or `git diff --word-diff HEAD -- <draft>`.
4. **Revise but do not commit.** Address each query using sources you have in conversation, or leave it and note the unresolved item in a `## Unresolved` block at the foot of the draft. Do not invent. Keep dependency grammar in mind: when you rewrite a sentence the editor flagged for R13, bring the dependent words closer; do not just swap synonyms.

### Round 2

5. **Re-invoke the skill on the same draft.** The draft is still uncommitted at this point; that is intended. The round-2 subeditor reads the draft as it now stands (including your revisions) and verifies that round-1 queries are addressed, flagging anything that remains or any new issue your revisions surfaced.
6. **Revise again** (still without committing) if round 2 has substantive queries. If round 2's queries are trivial or empty, the polish is settled.

### Done

7. **You commit on your own decision.** The skill does not commit. Between rounds the draft stays uncommitted and the user can read `git diff HEAD -- <draft>` to see all changes from rounds 1 and 2 in one diff. You may also invoke for additional rounds if the round-2 queries warrant it.

If you want to recover token budget after committing, the user can manually roll back the conversation to before the polish step. The committed draft survives; the spar chatter does not need to.

## Skill files

`$HOME/.claude/skills/economist-editing/` holds:

- `economist-stylebook.md`: the editorial standard (twelve Style-Guide rules plus R13 on dependency grammar)
- `editor-prompt.md`: the subeditor prompt template
- `source/style_guide_12.pdf`: published Style Guide, citation source for R1–R12

## Why one fresh-context subeditor per round, and why no auto-commit

The subeditor stays fresh-context because that is the cold reader's eye the author lost when it wrote the report. The author role belongs to the caller, which has the source material in its own conversation context; a fork of the caller as an internal author subagent would not work because Claude Code subagents do not inherit caller conversation history, and that conversation is where the research actually lives.

The skill never commits because git is the user's control surface. The user inspects `git diff HEAD` after both rounds and commits when satisfied, or discards via `git checkout`. An earlier version of this skill led callers to commit between rounds; that turned out to confuse the user, who only ever asked for the *baseline* to be committed before invocation, not the result.

## Anti-cheating discipline

The skill takes no per-invocation hint flags ("--check-for-X") by design. The subeditor receives only the stylebook and the draft; no fixture-specific guidance is ever leaked into the prompt. The stylebook articulates general editorial principles only; rule examples must come from outside any test fixture so the subeditor cannot recognise the expected answer.
