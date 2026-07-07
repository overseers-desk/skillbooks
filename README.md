# skillbooks

[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE) [![Claude Code plugin](https://img.shields.io/badge/Claude_Code-plugin-d97757)](https://claude.com/claude-code)

Put an editor between your AI and the send button.

skillbooks is a Claude Code plugin of editorial skills. Each one reads a draft the way its real reader will: cold, without the conversation that produced it, and with no patience for machine habits. Claude runs a skill automatically when a request fits its description, or you invoke one directly as `/skillbooks:<skill>`.

## The moments it exists for

- An AI-drafted email is competent and reads machine-made: bullet points where a person would write sentences, the session's date presented as "today", a closing offer to answer questions nobody asked.
- A document written across a long conversation goes to a colleague who was not in it, and paragraph two leans on "the approach we discussed".
- A report states a figure with confidence, and you can no longer say which source it came from, or whether the source agrees.
- The work continues tomorrow on another machine, and everything this session learned lives in a transcript that will expire.

## Before and after

One pass of `edit-email` over an AI draft (illustrative):

> Hi Alice, I hope this email finds you well! I wanted to reach out regarding the March workshop. Here are the key details: the workshop will take place on Saturday March 14th at 10am. Please don't hesitate to reach out if you have any questions.

becomes

> Hi Alice, the March workshop is confirmed: Saturday the 14th, 10am. If anything is unclear, ask.

## Skills

- **edit-email**: Polish or compose an email so it reads as a person wrote it, not a project: fixes the tells of machine-written mail (to-do lists, session dates, smuggled inferences, a buried lead) and applies a standing like-human-do pass. `--register` picks how the mail is pitched to its recipient; `--voice` picks whose hand it is written in.
- **edit-economistly**: Edit a markdown draft to The Economist editorial standard through a fresh-context subeditor. `--two-pass` for a closer edit.
- **sorry-im-late**: Cold-read something written during a conversation, a draft or a staged code diff, as a colleague who has the project but was not in that conversation, so missing context and insider residue show up before you send, publish, or commit.
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

The editorial skills are self-contained: they run their own fresh-context subagents and need no credentials and no browser. Only **typst-pdf** has an external dependency: [Typst](https://typst.app) on `PATH`.

## License

[MIT](LICENSE).
