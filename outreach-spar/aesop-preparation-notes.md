# AESOP Preparation Notes — SPAR Procedures

This is a temporary working document. It collects procedural details that must be addressed when writing the individual AESOPs for each SPAR phase. These details were identified during the methodology design discussion but are too execution-specific for the methodology document itself. Each item names the AESOP it belongs to, the requirement, and the source where the technique was first observed or defined.

When an AESOP is written and the relevant items are incorporated, remove them from this list.

## For the P (Profile) AESOP

### Profile richness classification
The A phase scales its A2 (sparring) rounds based on profile richness. P must therefore classify each profile into one of three tiers as part of its output:

- **Rich** (6+ substantive data points): public statements with quotes, known positions on relevant topics, project affiliations, stated concerns, named connections, recent activity
- **Medium** (3–5 data points): enough for a directional assessment but not enough for iterative simulation
- **Thin** (<3 data points): bare LinkedIn, no public writing, no known connections

The classification is recorded in the profile document so that A can read it without re-evaluating richness.

**Source:** methodology discussion, derived from the A2 round-scaling design.

### Verification corrections during profiling
P will frequently find that seed data is wrong: a CRM lists a tour guide as the owner, a conference speaker list has an outdated title, a LinkedIn profile shows someone has left the company. The AESOP must specify: (1) correct the roster entry with the verified data, (2) record what changed and why in the profile document, (3) if the person has left the relevant role entirely, trigger the stale contact handling procedure defined in the methodology.

**Source:** rivermill iteration results. Examples: The Vino Bus CRM contact "Kaz" was a tour guide, not the owner (actual founder: Natasha Bennett). Zoe Fall left River City Labs, now at DT Infrastructure. Natalie Arnold left wedding planning entirely.

## For the A (Approach) AESOP

### Comm index maintenance
The AESOP must specify the exact format of the `comms-index.md` file. Each entry should contain at minimum: target ID, name, organisation, segment, angle used, key relationship hooks established, date of approach, response status (pending/replied/no-response). The index must be append-only during a band and must not be edited by the A agent except to add new entries.

**Source:** methodology discussion. The index exists to prevent A from reading all prior comm logs in full, which would exceed context limits at scale.

### Comm log file structure
The `ID-person-name-org-comms.md` file must contain sections in a fixed order so that both humans and subsequent A runs can parse them predictably: (1) profile summary (copied or referenced from P output), (2) angle chosen and rationale, (3) A1/A2 iteration history (all drafts and C2 responses, in order), (4) final message, (5) contact method, (6) response log (initially empty, updated as responses arrive).

**Source:** methodology discussion.

### Cluster definition for segment-level context
When A processes a contact, it reads full comm logs for contacts "in the same segment or cluster." The AESOP must define what constitutes a cluster. Options: (a) same segment tier (all strategic, all corporate, etc.), (b) same angle (all contacts approached with the CRA compliance angle), (c) same geography, (d) explicitly defined by the campaign plan. The choice affects context window usage — a broad cluster definition means more logs to read.

Recommendation: cluster by angle, since the comm logs are most useful when A can see how different people responded to the same framing. The campaign plan may override this.

**Source:** methodology discussion.

## For the R (Revise) phase — human checklist

R is not an AESOP (it is a human review process), but the following items should be formalised as a checklist for the human reviewer:

### Quality checklist for S&P output
Before AR begins, verify per roster:

1. Every row has a named contact (no organisation-only rows)
2. No duplicate contacts within the roster
3. No duplicate contacts across rosters (if multi-segment campaign)
4. Every contact has at least one reachable channel (email, LinkedIn, or Facebook open for messages)
5. Star ratings are plausible (geographic proximity alone does not establish fit; a referral path must be plausible)
6. Response likelihood estimates are consistent with profile richness (a thin profile cannot support a 90% estimate)
7. Stale contacts are marked and replacements attempted
8. Profile richness classification (rich/medium/thin) is recorded
9. Cross-leads are tagged with correct destination segment
10. `discovered_via` chains are traceable to a seed source

**Source:** rivermill iteration results, quality checklist (25 March 2026). Adapted to be campaign-agnostic.

### Band review checklist
After each AR band completes and responses are collected:

1. Compare actual response rate against P's response-likelihood estimates for the band
2. Categorise responses by which angle generated engagement
3. Note angles that generated no engagement or negative responses
4. Record unexpected themes or concerns raised by respondents
5. List any new names surfaced (for S&P₄+)
6. List any warm leads offered (introductions, referrals) — these bypass the pipeline
7. Draft revised connection strategy for the next band, specifying which angles to emphasise, which to drop, and any new hooks from the comm log to reference
8. Record the revision in `strategy-revision-[band].md`

**Source:** methodology discussion, R phase definition.
