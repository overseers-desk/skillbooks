# SPAR-A batch execution: iteration log (2026-03-27)

This document records the problems discovered during the first batch execution of SPAR-A approach files, the solutions considered, and the method adopted.

## Context

136 outreach contacts across 8 roster categories (wedding-planner, tour-operator-domestic, tour-operator-inbound, tourism-board, corporate-team-experience, yoga-wellness, community-group, mothers-group) needed email drafts generated via SPAR-A. A batch script (`spar-a-batch.sh`) was built to generate prompt files and feed them to `claude -p --dangerously-skip-permissions` via GNU parallel (8 concurrent jobs). A worker script (`spar-a-worker.sh`) runs each job and captures output.

The first batch produced 79 approach files before the session hit a rate limit. Reviewing a single output (`4-jamie-lee-delectable-tours.md`) revealed three problems. A fourth emerged during deeper analysis of the 79 files.

## Problem 1: Wrong sender identity

The prompt hardcoded the sender as "Weiwu Wu" at `weiwu@rivermill.au`. The correct identity is Weiwu Zhang, Director, at `director@rivermill.au`. The sender address is documented in the project's CLAUDE.md but was not read by the batch prompt template.

**Fix:** Changed the prompt template to state the correct sender explicitly. This is a simple data error, not a method problem.

## Problem 2: A2 spar was not context-isolated

The A2 step (recipient role-play) was performed within the same agent context that had read all Rivermill project files. The simulated recipient therefore "knew" facts about the venue that a real cold contact would not know, producing artificially positive evaluations. Structurally, the A2 output read like a helpful assistant grading the email ("What works: / What could be improved:") rather than a person who had received an unsolicited message.

**Solutions considered:**

1. **Prompt instructions to "forget" context.** Unreliable. An LLM that has read the venue files cannot genuinely simulate ignorance of them.
2. **Two separate `claude -p` calls per contact** (one for A1, one for A2). Feasible but doubles the number of external process calls and complicates the workflow.
3. **Single `claude -p` session spawns a context-free subagent for A2.** The `claude -p` session has access to the Agent tool. By spawning a subagent that receives only the recipient's profile and the draft email (no Rivermill files, no method files), the role-play operates in genuine isolation.

**Adopted:** Option 3. The A1 agent spawns a single Sonnet-class subagent (C2) that receives only the profile and the draft. C2 reacts in character with no structured rubric. This produces natural, often sceptical reactions. Sonnet was chosen over Opus for persona fidelity (research cited in the session indicated less capable models shift behaviour more authentically under persona instructions).

## Problem 3: Self-introduction was omitted

SPAR-A's writing rule "presuppose, don't narrate" was misinterpreted. The rule means: do not narrate the recipient's own situation back to them. It does not mean: omit introducing yourself. In early drafts, the AI skipped self-introduction entirely, producing emails that presupposed the recipient knew who Historic Rivermill was. A cold contact has never heard of the venue.

**Fix:** Clarified in SPAR-A section 4.5 that "presuppose, don't narrate" applies exclusively to the recipient's own situation. Self-introduction and USP presentation are required for all cold contacts. Added explicit instructions to select 1-3 USPs relevant to the recipient's segment and to include the Instagram link (`rivermill.au/ig`) for cold contacts.

## Problem 4: A2 did not catch factual errors

Even when A2 reactions were natural, they could not detect factual errors about the venue (e.g. "Nerang River" instead of "Coomera River") because the context-isolated agent had no access to source files. Separately, restricting the fact-checker to a short list of named files caused it to report verifiable claims as "unverifiable" when the evidence existed in files not on the list (e.g. "on the route to Tamborine Mountain" is documented in multiple profile files).

**Solutions considered:**

1. **Separate C3 fact-checker agent** with full repo access, spawned after C2. Adds a third agent to the workflow.
2. **Two-step single subagent.** C2 first role-plays (context-isolated: only profile + draft). After recording its in-character reaction, C2 then gains repo access and fact-checks every claim, appending "P.S. I noticed:" corrections. The role-play is already recorded, so subsequent file reads do not contaminate the persona simulation.
3. **Restrict fact-checker to named files.** Simpler but fragile: claims documented in files not on the list are reported as unverifiable.

**Adopted:** Option 2. One subagent, two sequential steps: role-play first, then fact-check with full `Grep`/`Read` access to `/home/weiwu/code/rivermill/`. No file list restriction.

## Problem 5: Tab parsing in Bash

A secondary technical issue. Bash `read` with `IFS=$'\t'` collapses consecutive tabs (empty fields) because tab is IFS whitespace under POSIX rules. Rosters have many empty fields. The fix converts tabs to SOH (`\x01`, a non-whitespace byte) before parsing, preserving empty fields. Some rosters also had Windows line endings (`\r\n`); the trailing `\r` on the last field caused non-empty comparisons to fail silently.

## Variant testing

Six prompt variants were tested in parallel on a single contact (Jamie Lee, Delectable Tours) to determine the best A2 strategy:

| Variant | Strategy | Key difference |
|---|---|---|
| v1 | Stripped minimal | Profile + email only, no instructions beyond "react naturally" |
| v2 | Anti-template | Explicitly forbids structured response format |
| v3 | Persona anchoring | Opens with "you are [name], you run [business]" preamble |
| v4 | Two-step (C2+C3) | Role-play first, then fact-check with repo access |
| v5 | Adversarial | Instructed to find reasons to delete the email |
| v6 | Baseline (old method) | Original structured rubric for comparison |

The two-step approach (v4) was adopted because it was the only variant that both produced authentic role-play reactions and caught factual errors.

## Quality of output after fixes

The post-fix Zoe Abrahams file (Southern Cross Tours, 5-star, inbound operator) demonstrates the improved output:

- **Sender identity:** Correct (director@rivermill.au, Weiwu Zhang).
- **Self-introduction:** Present. Opens with who the sender is, what the venue is, and where it is.
- **A2 role-play (C2):** Natural, sceptical voice. Raises operational questions ("What does 'heritage tourism venue' actually mean for a coachload of international visitors?"). No structured rubric.
- **A2 fact-check (C3):** Catches an unverifiable routing claim ("on the route to Tamborine Mountain"), a URL documentation gap (`rivermill.au/ig`), and a distance discrepancy (40 vs 45 minutes). Draft is revised to drop the unverifiable claim.
- **Fact provenance:** Every claim in the final email cites a specific project file and field.

The 79 files from the first batch still contain the old problems (wrong sender, non-isolated A2, missing self-introduction). They require regeneration with the corrected template before review.
