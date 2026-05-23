---
name: sorry-im-late
description: Run before sending or publishing a draft written during a conversation, so it reads for someone who has the project but was not in that conversation. A fresh-context colleague reads the draft cold and flags three faults: context the conclusions rest on but the draft leaves out, conversation residue (abandoned ideas, dropped alternatives) kept only because it was discussed, and text pitched at someone who was in the conversation instead of the newcomer reading it.
---

# sorry-im-late

A colleague walks into a working session already under way and says "sorry I'm late, I see you have started." He knows the project, the document produced by it, but not what this conversation has covered leading to the document. Everything you write from here has to land for him. This skill is in the family of edit-email and edit-economistly.

## Problem this skill exists to solve

This is a document tool, in the same family as edit-email and edit-economistly: it makes a finished text read for its reader. The reader here is an outsider who has the project but was not in the conversation that produced the text. The product is the document, not the conversation; the skill does not summarise the talk, it makes the text stand on its own. If most of the conversation is irrelevant to the document, none of it belongs in the document.

A draft written in the middle of a conversation carries that conversation into the text three ways, and all read badly to the imaginary person who arrived late:

- **Short of context.** The author holds the whole exchange, so the draft leans on it: "Option C", "the approach we agreed", "the current behaviour", a conclusion whose reason was spoken and not written, a change that never says what becomes of what it replaces. The reader cannot reconstruct any of it.
- **Conversation residue.** The draft also carries the conversation's leftovers: an idea raised and abandoned, an alternative weighed and dropped, deliberation replayed, kept only because it happened. A reader who wants the result, not the transcript, has to wade through it. That a thing was discussed is not a reason to include it.
- **Pitched at an insider.** The draft can hold every fact yet tell it from the seat of someone who walked the conversation: a present framed as a change from a before only an insider knew, a defence of an objection the reader never raised. To the newcomer it reads as the middle of a talk he never joined.

The reader-simulation maxim in CLAUDE.md is not enough on its own, because the author cannot see the scaffolding it carried in. A separate reader who never had the conversation can. This is the boundary from edit-economistly, whose reader is a generalist outside the project who needs entities glossed and acronyms expanded; here the reader is inside the project and needs none of that. The one thing withheld from him is this conversation.

The rules both the author and the colleague work to are in `$HOME/.claude/skills/sorry-im-late/rulebook.md`.

## Procedure

1. Assemble the draft as a text block: title or subject on the first line, body below.
2. Spawn a fresh-context general-purpose agent, leaving its tools to read the project's materials available (the colleague reads the project, whatever form it takes: a codebase, a document set, a shared body of work). The prompt template is at `$HOME/.claude/skills/sorry-im-late/editor-prompt.md`; substitute `$RULEBOOK_PATH` with `$HOME/.claude/skills/sorry-im-late/rulebook.md` and `$DRAFT` with the draft text. Pass the result as the agent prompt.
3. The agent returns POLISHED (light fixes applied) and QUERIES (gaps only this conversation can close).
4. Resolve each query from your conversation. Fold the answer into the draft in project terms; where the alternatives behind a label bear on the choice, name them in a clause; where they do not, drop the label and state the thing directly. Do not invent.
5. Show the user the revised draft. Sending or publishing is the caller's act; this skill does neither.

## Files

`$HOME/.claude/skills/sorry-im-late/`:

- `rulebook.md` — the colleague's knowledge boundary and the gaps to query
- `editor-prompt.md` — the subagent prompt template

## Why a fresh-context subagent

The authoring role belongs to the caller, which holds the conversation. A subagent forked inside the same context inherits the same blindness about which sentences are conversation and which are draft. A brand-new agent that can read the project but never saw the conversation is the colleague the draft is actually for.

## Anti-cheating discipline

Rulebook examples come from outside any test fixture, so the subagent applies the rule rather than recognising a remembered phrase. The prompt carries only the rulebook and the draft; no hint about the particular draft is leaked in.
