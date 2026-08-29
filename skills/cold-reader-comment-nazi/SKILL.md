---
name: cold-reader-comment-nazi
description: Cold-read a code diff before commit or push and edit its comments in place, cutting what repeats the code or names a mechanism outside the comment's own scope. Triggers: comment nazi, trim comments, comment fan-out, cold-read a diff.
argument-hint: <path> | --staged | --since <ref> [--report] [--plan-agent]
---

# cold-reader-comment-nazi

A colleague walks into a working session already under way, says "sorry I'm late, I see you have started", reads the diff as the maintainer who inherits it, and then does what a maintainer does with comments that will cost him later: cuts them. This skill is the editing member of the cold-reader category. sorry-im-late is the reading member: the same colleague, the same rulebook, no edits. Where a caller holds prose (a plan, an issue, a document), sorry-im-late is the pass; where it holds a code diff, this one is.

## Problem this skill exists to solve

A mechanism's name sits in the code, then in its own comment, then in a caller's comment, then in a module doc. When the mechanism changes, every one of those places changes, and a rename becomes shotgun surgery with comments as most of the wounds. Measured on one 34k-line Rust tree over 246 commits: a rename or signature change touched a median 114 lines across 3 files and 13 hunks; 69% of the comment-only hunks in those commits existed only because a comment had spelled the name, about 300 avoidable hunks over the history. Of the comment lines naming a mechanism, 36% were plain repetition. The other 64% were pointers whose value is the reference itself: the test that guards an invariant, the authoritative copy across a crate boundary, third-party source, a module index. One of those pointers was already stale, naming a file that had moved. The cure is not fewer names; it is that a comment outside a mechanism's definition either points in a form the toolchain checks or speaks in roles, and a role never needs updating.

The second problem is growth. An AI editing code adds a comment wherever it touches logic and removes none, so the comment share climbs with every pass over the same lines, and the comments it adds restate the operation beside them. The reader already has the code; explaining it to him is what the mum check in the rulebook refuses.

The author cannot make these cuts. It wrote the comment for the reader it imagined, and reads its own sentence as carrying weight. A fresh reader who holds the project, reads the diff as its next maintainer, and never saw the conversation, can tell a pointer from decoration and a reason from a restatement. This skill gives that reader edit tools.

The rules the colleague works to are in `${CLAUDE_PLUGIN_ROOT}/skills/cold-reader-comment-nazi/rulebook.md`: the cold-reading rules (short of context, conversation residue, insider pitch, the mum check), then the Comments section that edits.

## Procedure

1. The draft is a file on disk. With `--staged`, run the diff that shows what the commit will commit (`git diff --cached` for a staged commit; `git diff HEAD -- <paths>` for a pathspec or `--only` commit; `git diff HEAD` for `-a`) and write its full output to a temp file outside the repo (a scratchpad path). With `--since <ref>`, write `git diff <ref>..HEAD` the same way and name `<ref>` as the base in the agent prompt. With a path, the file itself is the draft. The diff goes in whole; a condensed or excerpted draft blinds the colleague to what you cut, and the prompt carries only the path.
2. Spawn a fresh-context general-purpose agent with `model: "sonnet"`, leaving its read and edit tools available: it reads the project and edits the working tree. The prompt template is at `${CLAUDE_PLUGIN_ROOT}/skills/cold-reader-comment-nazi/editor-prompt.md`; substitute `$RULEBOOK_PATH` with `${CLAUDE_PLUGIN_ROOT}/skills/cold-reader-comment-nazi/rulebook.md` and `$DRAFT_PATH` with the absolute path to the draft file. With `--report`, append one line: `The caller invoked --report.` The colleague then lists the edits it would make and touches nothing; use it for a first run on a tree whose house style you have not seen. Add nothing else that telegraphs what you hope it will catch.
3. The agent returns four sections: READING (the colleague's interpretive write-back), EDITS (each comment edit it applied, or would apply under `--report`, as path:line, before, after, rule), QUERIES (gaps only the conversation can close, and comments it left alone because their value may sit in domain knowledge it lacks), and METRICS (comment lines, fan-out lines split pointer/repetition, and comment/code ratio, before and after).
4. **Planner pass (opt-in via `--plan-agent`).** Only when the caller invoked it, and only for a plannable draft (a bug report or feature request): spawn a second fresh-context agent with `model: "sonnet"` using `${CLAUDE_PLUGIN_ROOT}/skills/cold-reader-comment-nazi/planner-prompt.md`, substituting `$DRAFT_PATH`. It returns ERRORS (steps that cannot be executed as written) and MISSING (inputs the draft omits that the project holds). If a finding names a component or boundary it could not reach, re-run it pointed at those materials, and bring the cross-boundary gaps that remain back to the caller. Skip it for a diff.
5. Read READING first and compare each interpretation against what you meant; a confident wrong reading is a defect even when no edit or query fired. Then review EDITS against `git diff`: the colleague edits by rule and you hold the domain, so revert any edit that cut a reason it took for restatement, and say why in the commit. A C6 finding (a comment stating an invariant a test or assert could hold) is reported, not applied; promoting it is your call. Resolve QUERIES from the conversation, folding a settled answer into the code in project terms and marking an open one open.
6. Show the user the edits and the metrics. Committing and pushing are the caller's acts. When a push gate sent you here, commit the edits before rerunning the push: the gate measures the push range, and edits left in the working tree are not in it.

## Files

`${CLAUDE_PLUGIN_ROOT}/skills/cold-reader-comment-nazi/`:

- `rulebook.md`, the colleague's knowledge boundary, the reading rules, and the Comments rules that edit
- `editor-prompt.md`, the editing cold-reader subagent prompt template
- `planner-prompt.md`, the planner-evaluator subagent prompt template

## Why a fresh-context subagent

The authoring role belongs to the caller, which holds the conversation and wrote the comments. A subagent forked inside the same context inherits the same blindness about which comments carry weight and which carry only the name. A brand-new agent that can read the project but never saw the conversation is the maintainer the diff is for, and the one who can cut without mercy and without loss.

## Anti-cheating discipline

Rulebook examples come from no test fixture and no tree the skill has been measured on, so the subagent applies the rule rather than recognising a remembered line. The prompt carries the rulebook path and the draft's path; no hint about the particular diff is leaked in, and the colleague reads the diff in full from its file.
