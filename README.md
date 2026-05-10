# aesop skills

Skills for Claude Code. Each skill is a `SKILL.md` (with any supporting files) under `skills/`, loaded on demand when its trigger matches. Point Claude Code at this directory to make them available.

## Skills

- **edit-email**: Polish an AI-drafted email through a fresh-context subeditor that reads the draft cold and reports what a recipient would actually take from it, catching the failure modes typical of machine-written mail. Flags: `--director` (director-to-staff register), `--Liansu` (edit in a named sender's voice).
- **edit-economistly**: Edit a markdown draft to The Economist editorial standard via a fresh-context subeditor. `--two-pass` for a closer edit.
- **sorry-im-late**: Cold-read a draft written during a conversation as a colleague who has the project but was not in that conversation, surfacing missing context, conversation residue, and passages pitched only to insiders.
- **quote-me**: Locate the exact source passage behind a claim, run a challenge-and-minimum-edit cycle, and verify the fix with a context-free subagent. Triggered by "quote me".
- **typst-pdf**: Render a markdown file to PDF with Typst, optionally applying a per-repo template discovered at `.aesop/default.typ` or `.aesop/letterhead.typ`.
