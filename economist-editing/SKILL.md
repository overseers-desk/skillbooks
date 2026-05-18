---
name: economist-editing
description: Edit a draft markdown file to The Economist editorial standard via a fresh-context Sonnet subeditor spawned with the Agent tool. The subeditor edits the file in place; queries the editor cannot answer alone are returned in its response message for the caller to address. Use when the caller asks to apply Economist-style editing to a markdown document, or invokes /economist-editing.
argument-hint: <path-to-draft.md>
---

# economist-editing

## Problem this skill exists to solve

Reports written by an AI agent tend to read like the agent's internal monologue. The agent has the source material, the chain of investigation and the prior conclusions in its conversation, and its prose carries scaffolding the reader cannot decode. Named entities arrive unglossed, dates carry no significance, claims arrive without source, sections begin with throat-clearing about what the report "will show". A reader who was not in the authoring conversation cannot follow it.

A general maxim in CLAUDE.md asking the author to write for a cold reader is not enough on its own. The author cannot see its own scaffolding. The fix is a separate cold reader: a fresh-context subeditor who reads the draft the way a Singaporean lawyer or Kenyan economist would, applies the mechanical fixes itself, and asks the author about the substantive gaps it cannot answer alone.

## What this skill is

You (the caller) are the report-writing session. This skill polishes one of your own drafts to *The Economist* standard by spawning a fresh-context subeditor. You own the spar: the subeditor edits and asks; you commit and revise.

## Procedure

1. **Confirm the draft is in a git working tree with a clean status for that file.** Commit or discard any uncommitted changes to the draft first, so the subeditor's edits land cleanly and `git diff HEAD` is the readable record of what changed this round.

2. **Spawn a fresh-context subeditor with the Agent tool.** Use a fresh general-purpose agent. The prompt template is at `$HOME/.claude/skills/economist-editing/editor-prompt.md`; substitute the two placeholder paths and pass it as the agent prompt. The agent will read the stylebook and the draft, edit the draft in place via its Edit tool, and return a list of author queries as its single response message.

3. **Read the agent's response.** The response is the list of author queries — things only you can resolve, because they need the source material you researched while writing the report. The actual edits are on disk; inspect them with `git diff HEAD -- <draft>` or `git diff --word-diff HEAD -- <draft>`.

4. **Decide and revise.** For each query, either revise the relevant passage using the sources you have in conversation, or leave it as-is and note the unresolved item in a `## Unresolved` block at the bottom of the draft. Do not invent.

5. **Commit.** Git is the control surface; the committed file is the durable artefact.

6. **Optional: invoke again.** Re-run the skill on the now-committed draft for another spar round. The subeditor each time is fresh, so it will independently revisit anything you have not yet addressed.

If you (the caller) want to recover token budget after committing, the user can manually roll back the conversation to before the polish step. The committed draft survives the rollback; the spar chatter does not need to.

## Skill files

`$HOME/.claude/skills/economist-editing/` holds:

- `economist-stylebook.md`: the editorial standard the subeditor grades against
- `editor-prompt.md`: the subeditor prompt template (uses `$DRAFT_PATH` and `$STYLEBOOK_PATH` placeholders)
- `source/style_guide_12.pdf`: published Style Guide, citation source for the stylebook

## Why one fresh-context subeditor per round, and why no bash script

Earlier drafts of this skill split the work into three subagents and wrapped the orchestration in a bash loop that spawned `claude -p` subprocesses. Both layers are incidental: the caller already has the Agent tool for spawning fresh-context subagents in-session, so the bash script is not needed; and the spar between editor and author belongs to the caller, not inside the skill. The subeditor stays fresh-context (the right shape for a cold reader); the author role belongs to the caller, which has the source material in its own conversation context. A fork of the caller as an internal author subagent would not work because Claude Code subagents do not inherit caller conversation history, and that conversation is where the research actually lives.

## Anti-cheating discipline

The skill takes no per-invocation hint flags ("--check-for-X") by design. The subeditor receives only the stylebook and the draft; no fixture-specific guidance is ever leaked into the prompt. The stylebook articulates general editorial principles only; rule examples must come from outside any test fixture so the subeditor cannot recognise the expected answer.
