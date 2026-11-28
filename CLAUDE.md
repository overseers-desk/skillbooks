# Aesop — notes for AI sessions

This repo holds the **AESOP methodologies** (SPAR/SIFT/TEND/SAGE/SCOPE/PLACE/LAMP/MIND/MOVE/CART/HIRE) and their working data, in
the top-level dirs (almanac, brandreview-mind, contact-graph, correspondence-tend, events,
listing-sift, market-place, matter-cart, outreach-spar, pmf-sage, presence-move, sales-hire, scatter-scope, seo-lamp, travel, tests, webworks). These are SOPs written for AI
agents to execute.

The almanac is the exception: it is method only. Its data (the user's profile, the rated
event list, the event cache) lives in the user's own repository and is handed to the sweep
as a data root at run time. Nothing naming the user's cities, interests or decisions
belongs under `almanac/`.

Repository-wide invariants are in `INVARIANTS.md` beside this file, imported below. Each methodology's own `INVARIANTS.md` is imported by that directory's `CLAUDE.md`, so it arrives in context when you work there.

@INVARIANTS.md

`labs/` holds versions of a methodology that are being compared with each other. Nothing in it is a methodology to follow.

## Authoring AESOPs

Before creating or revising an AESOP, read `authoring/`: it holds the prompt that runs the author-test-fix loop (cases in `tests/NN/`) and a worked example. The rules for how AESOPs are written are in `sop-authoring-rules.md`; they override authoring instincts.

A remark from the owner on something a methodology produced shows a problem; it is not a line to file. The pull is to give each remark a home of its own, a rule in the procedure, a case, an invariant or an entry in an instance's data, so that seven remarks become seven lines (the office's cue for this is Borges, the map drawn at the scale of the empire). Read the remark for the problem it shows, then look for what solves that problem: a rule the methodology already has at a more general level, a step that already settles the matter case by case, a repair to the one output, or nothing. A new line is the answer only where it holds for every instance and every occasion; a rule whose right answer changes with the occasion is not one. First case: HIRE, where seven of the owner's remarks on drafts were being written into the method as seven cases and rule edits, and none of the seven needed one.

