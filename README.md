# skillbooks

A Claude Code plugin of editorial and writing skills. Each skill is a `SKILL.md` (with any supporting files) under `skills/`, loaded on demand when its trigger matches. Claude runs a skill automatically when a request fits its description, or you invoke it directly as `/skillbooks:<skill>`.

## Skills

- **edit-email**: Polish or compose an email so it reads as a person wrote it, not a project: fixes the tells of machine-written mail (to-do lists, session dates, smuggled inferences, a buried lead) and applies a standing like-human-do pass. `--register` picks how the mail is pitched to its recipient; `--voice` picks whose hand it is written in.
- **edit-economistly**: Edit a markdown draft to The Economist editorial standard through a fresh-context subeditor. `--two-pass` for a closer edit.
- **sorry-im-late**: Cold-read something written during a conversation, a draft or a staged code diff, as a colleague who has the project but was not in that conversation, surfacing missing context and insider residue before you send, publish, or commit.
- **tell-tale**: Label each line of a draft for AI tells (vocabulary clusters, negative parallelisms, rule-of-three padding, em-dash overuse, promotional tone), rewrite only the flagged lines, then smooth the seams. Optional project profile and dialect target.
- **quote-me**: Locate the exact source passage behind a claim, run a challenge-and-minimum-edit cycle, and verify the fix with a context-free subagent. Triggered by "quote me".
- **worklog**: Write a durable WORKLOG in the repository so a session's knowledge survives when its JSONL is gone or you continue the work on another machine or in a fresh session.
- **nswp-scout**: Scout a codebase for redundant solutions, most sharply one problem solved twice in two vocabularies where neither arm earns its place, and other solutions that answer no live problem.
- **typst-pdf**: Render a markdown file to PDF with Typst, optionally applying a per-repo template.

## Install

```sh
claude plugin marketplace add overseers-desk/overseers-desk
claude plugin install skillbooks@overseers-desk
```

For development, load it from disk without installing (reads the working tree live):

```sh
claude --plugin-dir /path/to/skillbooks
```

## Prerequisites

The editorial skills are self-contained and drive fresh-context subagents; they need no credentials and no browser. Only **typst-pdf** has an external dependency: [Typst](https://typst.app) on `PATH`.
