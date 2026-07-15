# skillbooks

[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE) [![Claude Code plugin](https://img.shields.io/badge/Claude_Code-plugin-d97757)](https://claude.com/claude-code)

Every book read is a stat permanently raised.

skillbooks is a Claude Code plugin of crafts your agent keeps. Each one reads the work cold, the way its next reader will: the editor who never saw the chat, the reviewer who takes no refactor at its word, the colleague who brings you only the questions that are really yours. That cold read is the one thing you cannot do to your own work, because you were in the room. Claude runs a skill automatically when a request fits its description, or you invoke one directly as `/skillbooks:<skill>`.

## The moments it exists for

- An AI-drafted email is competent and reads machine-made: bullet points where a person would write sentences, the session's date presented as "today", a closing offer to answer questions nobody asked.
- A document written across a long conversation goes to a colleague who was not in it, and paragraph two leans on "the approach we discussed".
- A report states a figure with confidence, and you can no longer say which source it came from, or whether the source agrees.
- A rename landed weeks ago, and a test fixture, a CI file, and a doc still describe the world as it was.
- Your agent hits a decision mid-run and stops the whole plan to ask you, when it could have settled safely and kept walking.
- The work continues tomorrow on another machine, and everything this session learned lives in a transcript that will expire.

## Before and after

One pass of `edit-email` over an AI draft (illustrative):

> Hi Alice, I hope this email finds you well! I wanted to reach out regarding the March workshop. Here are the key details: the workshop will take place on Saturday March 14th at 10am. Please don't hesitate to reach out if you have any questions.

becomes

> Hi Alice, the March workshop is confirmed: Saturday the 14th, 10am. If anything is unclear, ask.

## Skills

| Skill | What it does | Category |
|---|---|---|
| **edit-email** | Polish or compose an email so it reads as a person wrote it, not a project: fixes the tells of machine-written mail (to-do lists, session dates, smuggled inferences, a buried lead) and applies a standing like-human-do pass. `--register` picks how the mail is pitched to its recipient; `--voice` picks whose hand it is written in. | Writing |
| **edit-economistly** | Edit a markdown draft to The Economist editorial standard through a fresh-context subeditor. `--two-pass` for a closer edit. | Writing |
| **densify** | Shrink a verbose text so every specific (dates, numbers, names, commands, caveats) survives, verified by a mapping rather than by feel. | Writing |
| **speak-like** | Rewrite a draft so it speaks as an identity (`human`, `director`, any phrase), tuned by manner adverbs (`--warmly`): labels each line for AI tells and editorial violations, rewrites only the flagged lines, then smooths the seams. `speak-like human` is the pass for prose that must not read as AI-written. Accepts a judge's findings via `--findings`; optional project profile and dialect target. | Writing |
| **sorry-im-late** | Cold-read something written during a conversation, a draft or a staged code diff, as a colleague who has the project but was not in that conversation, so missing context and insider residue show up before you send, publish, or commit. | Review |
| **this-guy-aint** | Cold-read work written under an assumed identity (`human`, `aussie`, `developer`, `manager`, any phrase) as a fresh reader who is one: believed or not, with the giveaways that leak a non-member. The judge edits nothing; `--speak-like` hands its findings to speak-like for repair and re-judges once. `this-guy-aint human` is the light gate for code comments and short pieces. | Review |
| **quote-me** | Locate the exact source passage behind a claim, run a challenge-and-minimum-edit cycle, and verify the fix with a context-free subagent. Triggered by "quote me". | Verification |
| **nswp-scout** | Scout a codebase for redundant solutions, most sharply one problem solved twice in two vocabularies where neither arm earns its place, and other solutions that answer no live problem. | Codebase audit |
| **drift-scout** | Find the stale debris a refactor, rename, or move left in a codebase's edges: extract each change's retired vocabulary, sweep the periphery, confirm by running, and report only what provably breaks or misleads. | Codebase audit |
| **halfway-house** | Tell a decision your agent can safely settle from one that blocks the path: settle it, land the change, file the road not taken, and bring only the true forks to you. | Agent workflow |
| **worklog** | Write a durable WORKLOG in the repository so a session's knowledge survives when its JSONL is gone or you continue the work on another machine or in a fresh session. | Handoff |
| **typst-pdf** | Render a markdown file to PDF with Typst, optionally applying a per-repo template. | Rendering |

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

The skills are self-contained: they run their own fresh-context subagents and need no credentials and no browser. Only **typst-pdf** has an external dependency: [Typst](https://typst.app) on `PATH`.

## License

[MIT](LICENSE).
