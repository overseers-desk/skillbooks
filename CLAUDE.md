# Aesop — notes for AI sessions

This repo holds the **AESOP methodologies** (SPAR/SIFT/TEND) and their working data, in
the top-level dirs (almanac, articles, contact-graph, correspondence-tend, events,
listing-sift, outreach-spar, travel, tests, webworks). These are SOPs written for AI
agents to execute.

## Invariants

- A campaign folder holds only these files: at campaign level `campaign-<slug>.yaml`, its selling-point document `campaign-<slug>-usp.md`, `sweeper-<family>.yaml` where segments share sweep knowledge, and one directory per segment; inside a segment `segment.yaml`, `roster.tsv`, `sweep.yaml`, `sweep-feedback.tsv`, `profiles/<stem>.md`, `approach/<stem>.yaml`. The list of names is closed, though profiles and approaches run to one file per target.
- Each of those files is the sole home of what it holds, so a finding is recorded by writing it into the file that owns it: the roster owns who we know and how to reach them, the sweep file owns coverage, a profile owns one target's assessment, an approach owns one target's messages.
- Analysis, working notes, worklogs, issue write-ups and summaries live outside the campaign folder, because inside it they duplicate a file above and go stale against it.
- A second TSV is never created to be merged into the first one later. The merge is the step that does not happen: context runs out, the user leaves, the machine reboots, the agent is stopped mid-run, and the file is left behind holding data nobody can account for. A writer that cannot write the roster now waits until it can.

The last invariant is the one an agent will reason its way around, because at the moment of writing there is always a reason the roster is inconvenient. Each of these is that reason wearing a different hat, and none of them licenses a second file:

- Another writer holds the roster (a running P or A batch, a second sweep agent, another session), so a side file "avoids the conflict". Wait for the writer instead; the wait costs only time, the side file costs the roster's authority.
- Several agents are fanning out over one segment at once, so each "needs its own file". Run them in turn, or have one agent own the writing while the others report to it.
- The findings are unvalidated and "should be staged for review before joining the real data". A row carries its own confidence and evidence in `s_note`; an unproven finding belongs on the roster marked unproven, not in a file beside it.
- The harvest is large and "merging at the end is more efficient". The end is exactly when the crash happens; efficiency here buys a bulk merge nobody supervises.
- A crash already destroyed work once, so an in-repo file "is the durable record". The roster is in the repository and is committed as rows land, which is the same durability without the second home.
- The agent is a subagent and "should not touch shared state directly". Whatever the agent may write at the end, it may write as it goes.
- The work is exploratory, "a scratch pass that will be thrown away". Scratch that lands in a git-tracked directory is not scratch, and the throwing away is the step that does not happen.
- The roster's schema does not have a column for what was found, so the finding "needs a place to sit". Column vocabulary comes from the owner (see the vocabulary rule); until then the finding goes in `s_note` as prose.

## Skills live elsewhere

The skills the methodologies call are packaged as the **overseer-toolbox** Claude Code
plugin, in its own repository (`git@github.com:overseers-desk/overseer-toolbox.git`), not
here. SOPs reference skills by name (for example, "use the LinkedIn skill if
available"); install that plugin to make them available. Its README and CLAUDE.md cover
the serialised-browsing skill (the browser harness the methodologies use when it is
available), credentials, and testing. This repo
is methodology only: do not re-add skill directories or a plugin manifest here.

## Credentials

Where a methodology delegates to a skill that needs credentials, those live in
`$HOME/.claude/skills/config.ini`, read by the skill in the overseer-toolbox plugin, not
by anything in this repo. The file is gitignored.
