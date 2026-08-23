# Aesop — notes for AI sessions

This repo holds the **AESOP methodologies** (SPAR/SIFT/TEND/SAGE/SCOPE/PLACE) and their working data, in
the top-level dirs (almanac, articles, contact-graph, correspondence-tend, events,
listing-sift, market-place, outreach-spar, scatter-scope, travel, tests, webworks). These are SOPs written for AI
agents to execute.

The almanac is the exception: it is method only. Its data (the user's profile, the rated
event list, the event cache) lives in the user's own repository and is handed to the sweep
as a data root at run time. Nothing naming the user's cities, interests or decisions
belongs under `almanac/`.

Each methodology carries its hard rules in its own `INVARIANTS.md`, imported by that directory's `CLAUDE.md` so they arrive in context when you work there. The procedures and validators cite them by number.

## Authoring AESOPs

Before creating or revising an AESOP, read `authoring/`: it holds the prompt that runs the author-test-fix loop (cases in `tests/NN/`) and a worked headless example. The rules for how AESOPs are written are in `sop-authoring-rules.md`; they override authoring instincts.

