---
name: edit-email
description: Polish an email draft via a fresh-context subeditor spawned with the Agent tool. The caller passes the draft inline (no file). Counters the predictable failure modes of AI-drafted email: project-shaped to-do lists, session-anchored timestamps, defending arguments the reader has not raised, inferred facts smuggled in as paraphrase, missing identity-first lead. The subeditor returns a reading log (what landed and how, where the reader paused or had to infer) alongside POLISHED and QUERIES, so confident wrong-readings surface even when no rule fires. The `--director` flag adds director-to-staff register checks (decisions stay decisions, no soft closes, don't decide in the recipient's domain, no deliberation-narrative defence).
argument-hint: [--director]
---

# edit-email

## Problem this skill exists to solve

AI-drafted email reads to its sender like an email and to its recipient like a project. The drafting agent has the brief in conversation; when it composes, it paraphrases liberally, defends inferences the reader has never drawn, anchors timestamps to its own session, and turns asks into numbered lists. The recipient sees something that will take effort to handle and defers it.

A general newspaper maxim in CLAUDE.md is not enough on its own: the drafting agent cannot see the scaffolding it has carried in from its brief. The fix is a cold reader who has only the email, applies the rulebook, and returns a polished draft plus queries.

The rules the drafting agent and the subeditor both work to are in `email-rulebook.md` alongside this file.

## Procedure

1. Assemble the draft as a text block with the YAML-style header preamble (`to:`, `cc:`, `from:`, `subject:`) and the body below.
1a. If the draft relies on prior correspondence (a reply, or a fresh message that picks up an unresolved ask from earlier mail), assemble a THREAD block of the relevant prior messages. One issue often spans several threads: include every thread the draft draws on, not only the one the headers say it replies to. Each message in the block carries its own from/date/subject and body. The subeditor cannot fetch mail; whatever the cold reader needs to judge whether the draft omits a fact the recipient is waiting on must be in this block. If the draft stands on its own, the THREAD value is `(none)`.
2. Spawn a fresh-context general-purpose agent. Use the prompt template at `$HOME/.claude/skills/edit-email/editor-prompt.md`; substitute `$RULEBOOK_PATH` with the rulebook path, `$EMAIL` with the draft text, `$THREAD` with the THREAD block (or `(none)`), and `$REGISTER` with the register tag (`general` by default; `director-to-staff` when the caller invokes with `--director`). Pass the result as the agent prompt.
3. The agent returns READING (a paragraph-by-paragraph log of what landed, where the reader paused, what meaning they took when a word was ambiguous, what step they supplied to bridge a chain of reasoning), POLISHED (body with mechanical fixes applied), and QUERIES (questions for the caller).
4. Read READING first. Compare each interpretation against what the draft meant. Where the reader took a meaning the author did not intend, or had to supply a link the draft elided, that is a defect even though no rule fired; fix the draft. Then resolve each query from your conversation, asking the user if the brief does not answer. Do not invent.
5. Show the user the polished body inline; revise as requested by re-running the skill.
6. Send via mailroom once approved. The skill does not send.

## Files

`$HOME/.claude/skills/edit-email/`:

- `email-rulebook.md` — the rules
- `editor-prompt.md` — the subeditor prompt template

## Why a fresh-context subeditor

The drafting role belongs to the caller, which holds the brief and the user's surface phrasing. A subagent in the same context inherits the same blindness about which sentences are scaffolding and which are the email. A brand-new agent reading only the rulebook and the draft is the cleanest cold reader available.

## Anti-cheating discipline

Rulebook examples must come from outside any test fixture, otherwise the subeditor matches lexically rather than applying the rule. If a rule example appears in a draft to be tested, the example is contamination and must be rewritten before the test result is meaningful.
