# Aesop — notes for AI sessions

This repo holds the **AESOP methodologies** (SPAR/SIFT/TEND) and their working data, in
the top-level dirs (almanac, articles, contact-graph, correspondence-tend, events,
listing-sift, outreach-spar, travel, tests, webworks). These are SOPs written for AI
agents to execute.

Each methodology states its hard rules in its own `INVARIANTS.md`, which the procedures and validators cite.

## Authoring AESOPs

Before creating or revising an AESOP, read `authoring/`: it holds the prompt that runs the author-test-fix loop (cases in `tests/NN/`) and a worked headless example. The rules for how AESOPs are written are in `sop-authoring-rules.md`; they override authoring instincts.

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
