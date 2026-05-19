---
name: edit-email
description: Polish an email draft via a fresh-context subeditor spawned with the Agent tool. Counters the predictable failure modes of AI-drafted email: project-shaped to-do lists, session-anchored timestamps, defending arguments the reader has not raised, inferred facts smuggled in as paraphrase, missing identity-first lead.
argument-hint: <path-to-draft.md>
---

# edit-email

## Problem this skill exists to solve

AI-drafted email reads to its sender like an email and to its recipient like a project. The drafting agent has the brief in conversation: who the recipient is, how the user reached them, what the user has done, what the user wants. When it composes, it paraphrases the brief liberally, defends inferences the reader has never drawn, anchors timestamps to its own session ("today I wrote..."), and turns asks into numbered lists. The recipient sees something that will take effort to handle and defers it behind the next email-shaped message.

A general "newspaper" maxim in CLAUDE.md is not enough on its own. The drafting agent cannot see the scaffolding it has carried in from its brief. The fix is a cold reader who has only the email, not the brief, and applies the rulebook to the draft before send.

## What the drafting agent should bear in mind

The full rulebook with examples is at `email-rulebook.md` alongside this file. Before drafting, hold these in mind; the rulebook spells each out:

- Lead with identity. The first two sentences must let the recipient place the sender on their list.
- One ask, as prose. Numbered or bulleted lists of requests turn email into project.
- Don't write the recipient's worklist. Situation + ask, not recipe.
- Defend nothing the reader has not raised. Pre-empting an interpretation invents the reader's doubt.
- Faithful surface for borrowed facts. "A Westpac account" is not "my Westpac account"; paraphrase that adds detail is inference.
- Volunteer only what advances the ask. Each extra fact widens the project surface.
- Match the sender address. Send from whichever address the recipient has indexed against the user's file.

Knowing these at draft time means fewer subeditor round trips. The subeditor catches what slipped.

## Invocation

```
/edit-email path/to/draft.md
```

The draft is a markdown file (typically `/tmp/email-draft.md`) with a YAML preamble for headers and the body below:

```
---
to: recipient@example.com
cc: cc-party@example.com
from: alice@example.org
subject: Subject line
---

Dear Recipient,

[body...]
```

The subeditor edits the body in place. Headers are read for the R9 (sender-identity-match) check and flagged as a query if they do not fit the body, but not edited. Header choices are operational decisions for the caller.

## Procedure

The skill **never sends** and **never commits**. The file is left edited; the caller decides what to do with it.

1. **Draft the email to a markdown file.** Include the YAML preamble.
2. **Spawn a fresh-context subeditor with the Agent tool.** Use a general-purpose agent. The prompt template is at `$HOME/.claude/skills/edit-email/editor-prompt.md`; substitute the two placeholder paths and pass it as the agent prompt. The agent reads the rulebook, reads the draft, applies Class A fixes in place via its Edit tool, and returns Class B queries as its single response message.
3. **Read the agent's response** (the list of queries). The actual edits are on disk; read the draft file again to see them, or `git diff` if the draft is tracked.
4. **Resolve each query** using the brief in your conversation. Do not invent. If a query has no answer from the brief, ask the user.
5. **Show the user the polished body inline.** The user approves or asks for further revision; on revision, re-run the skill.
6. **Send via mailroom** once the user approves. The skill does not send.

## Skill files

`$HOME/.claude/skills/edit-email/` holds:

- `email-rulebook.md`: the email-drafting rules with examples
- `editor-prompt.md`: the subeditor prompt template

## Why a fresh-context subeditor

The subeditor stays fresh-context because that is the cold reader's eye the drafting agent loses when it carries the brief in conversation. The drafting role belongs to the caller, whose conversation holds the brief, the user's surface phrasing, and the prior corrections. A subagent in the same context would inherit the same blindness. A fork of the caller with the brief stripped out would still leak via residual prompt material; a brand-new agent reading only the rulebook and the draft is the cleanest cold reader available.

## Anti-cheating discipline

The subeditor receives only the rulebook and the draft. No brief-specific guidance is leaked into the prompt. The rulebook articulates general email rules; examples in the rulebook are illustrative, not test answers, and any future test fixture must come from outside the rulebook so the subeditor cannot recognise the expected answer.
