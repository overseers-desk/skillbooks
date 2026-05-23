---
name: sorry-im-late
description: A draft written mid-conversation carries references only someone who sat in the conversation can resolve. Run before sending or publishing one, this skill role play a fresh colleague who has the project but not this chat reads it cold.
---

# sorry-im-late

A colleague walks into a working session already under way and says "sorry I'm late, I see you have started." He knows the project, but not what this conversation has covered. Everything you write from here has to land for him.

## Problem this skill exists to solve

A draft written in the middle of a conversation reads, to whoever reads it next, like the tail of that conversation. The agent holds the whole exchange in context, so it writes "Option C", "the approach we agreed", "the current behaviour" as if shared. A colleague who has the project but did not sit in this conversation cannot resolve any of them.

The reader-simulation maxim (PDS) in CLAUDE.md is not enough on its own, because the author cannot see the scaffolding it carried in from the conversation. A separate reader who never had the conversation can.

The boundary is what separates this from edit-economistly. That skill's reader is a generalist outside the project who needs entities glossed and acronyms expanded. This skill's reader is inside the project and needs none of that. The single thing withheld from him is this conversation. So the test is narrow: does a reference trace to the repository or common knowledge (leave it), or only to the conversation he missed (query it)?

The rules both the author and the colleague work to are in `$HOME/.claude/skills/sorry-im-late/rulebook.md`.

## Procedure

1. Assemble the draft as a text block: title or subject on the first line, body below.
2. Spawn a fresh-context general-purpose agent, leaving its repo-reading tools available (the colleague reads the project). The prompt template is at `$HOME/.claude/skills/sorry-im-late/editor-prompt.md`; substitute `$RULEBOOK_PATH` with `$HOME/.claude/skills/sorry-im-late/rulebook.md` and `$DRAFT` with the draft text. Pass the result as the agent prompt.
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
