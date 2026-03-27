# SPAR-A A2 design: problems, options, and decisions (2026-03-27)

## Problems found

Reviewing the first batch of 78 approach files revealed four distinct failures:

**P1 — Wrong sender identity.** The prompt hardcoded "Weiwu Wu" at `weiwu@rivermill.au`. Correct: Weiwu Zhang, `director@rivermill.au`.

**P2 — A2 was not context-isolated.** The role-playing agent had read all Rivermill project files before simulating the recipient. The spar was therefore an informed insider critiquing the draft, not a cold stranger receiving it. Output read as a structured rubric ("What works / What could be improved") — helpful-assistant mode, not recipient mode.

**P3 — "Presuppose don't narrate" was misread.** The rule says: don't narrate the recipient's situation back to them. The batch agent read it as: minimise all narration, including self-introduction. Cold contacts received emails that presupposed they knew who Historic Rivermill was.

**P4 — A2 could not fact-check.** The context-isolated agent had no source files. Factual errors (wrong river name, unverifiable routing claims) passed through undetected. A separate fact-checker restricted to a named file list was equally fragile — claims documented in unlisted files were flagged as unverifiable.

## Options considered and decisions

**P2 — A2 isolation:**

| Option | Verdict |
|---|---|
| Prompt the agent to "forget" prior context | Unreliable; context cannot be genuinely erased |
| Two separate `claude -p` calls (one A1, one A2) | Feasible but doubles external calls and complicates orchestration |
| A1 spawns a subagent (C2) that receives only profile + draft | Adopted |

C2 receives no Rivermill files, no method files. It reacts in character as the recipient who has never heard of the venue. No rubric, no structured format. Sonnet-class model preferred over Opus for persona fidelity under role-play instruction.

**P4 — Fact-checking:**

| Option | Verdict |
|---|---|
| Separate C3 agent with full repo access (third agent per contact) | Adds complexity; C3 is unnecessary if C2 can do it sequentially |
| C2 does role-play first, then breaks character and fact-checks | Adopted |
| Restrict fact-checker to a named file list | Fragile; claims outside the list are incorrectly flagged unverifiable |

The two-step approach works because the role-play is already recorded before C2 gains file access. Source-file knowledge cannot contaminate the persona simulation if the reaction precedes the read. One agent, two sequential steps: react in character → search full repo and append "P.S. I noticed:" for errors.

## Quality after fixes

The Zoe Abrahams file (tour-operator-inbound, 5★) was regenerated with the corrected template and serves as the reference example of correct output.

**Before:** Structured "What works / What could be improved" A2; routing claim ("on the route to Tamborine Mountain") passed unchallenged; wrong sender address.

**After:**
- C2 reacted naturally: "I've never heard of Rivermill. What does 'heritage tourism venue' actually mean for a coachload of international visitors?"
- C2 fact-check caught the unverifiable routing claim and a distance discrepancy (40 vs 45 minutes from some source files). The draft was revised to drop the routing claim.
- Correct sender identity throughout.
- Every factual claim in the final draft cites a specific project file and field.

The 77 remaining first-batch files still carry P1–P3. They require a re-run before review.
