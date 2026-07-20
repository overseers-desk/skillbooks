# Invariants — outreach-spar

Hard rules the rest of the methodology must not contradict. When a procedure, template, prompt, field placement, or example here disagrees with an invariant, the invariant wins and the other is the bug to fix. These are stated once, here, because they have been re-violated by operational artifacts that drifted from the principle stated elsewhere.

## I1. A profile is campaign-independent and time-stable

A contact's profile is a property of the contact, shared by every campaign that ever targets them. It must read the same whether built today for one campaign or in a month for a different one.

The test (the same question as `spar-methodology.md`, "Campaigns and segments"): would re-profiling this contact for a different campaign, or simply at a different time, change this line? If yes, the line is not profile content.

Three kinds of content fail the test and therefore never enter the profile:

- **Our pitch** — the angle, the ask, the argument for why they should say yes. It turns on the campaign's goal, so it changes every campaign. Home: the approach phase (campaign × segment plan, and the approach YAML).
- **Our engagement state with them** — prior correspondence, warmth, whether we are connected on LinkedIn, "no prior contact". The second campaign finds a different answer, and the first message we send falsifies it. The profile would be stale the moment the approach button is pressed. Home: the engagement tier (approach YAML), determined fresh per campaign at approach time.
- **Our own facts / USP** — our metrics, our track record, our value proposition. They stay out for two reasons, not one. Reuse: they drift over time and are framed differently per campaign. Approach-neutrality: naming a USP in a contact's profile pre-empts a choice that belongs to the approach phase — which USP to lead with for *this* contact — and smuggles into a campaign-independent record an implication of what this campaign is about. So a USP mention stays out **even when the fact behind it is stable**. This is the line between a USP and a plain stable comparison: "their guest archetype matches our subject's" pre-empts no pitch and survives every campaign, so it may stay; "our value proposition fits them" pre-decides the pitch, so it goes. Home of the USP: the campaign's `usp_document`, read by the approach phase.

What the profile *does* hold: facts about the contact (role, history, audience, what they cover, who they know) and our campaign-independent judgement of their general value to us — `star_rating` and `match_rationale`, expressed as the contact's own attributes weighed against the segment's standing needs (`rating_rubric`, `discovery_criteria`), never against one campaign's ask or USP.

## Enforcement (why prose alone is not enough)

This invariant has been stated in `spar-methodology.md` since the three-tier spec, and was still violated in every profile of a real campaign, because the profiler follows the concrete template in front of it, not a principle in another file. So I1 is enforced in three coordinated places:

1. **Conformance** — the profile template (`spar-P-profile.md` §5), the procedure steps, and the worker prompt (`spar-manager/prompts/spar-p.txt`) carry no pitch, engagement, or USP section. There is nothing for the profiler to fill with campaign-bound content.
2. **Mechanical backstop** — `spar-validate` fails a profile whose body carries engagement markers (a prior-correspondence or warmth line, a "no prior contact" statement, an angles/pitch section). A leak is a build failure, not a style note.
3. **This file** — the single statement the prompt references and the validator cites.

## I2. A campaign folder's file list is closed

`spar-campaign-directory.md` enumerates the names, and that enumeration is complete: a file whose name is not in it does not belong in the folder, whatever produced it. Profiles and approaches run to one file per target, so the volume is open while the list is not.

What makes the list closable is that each name is the sole home of what it holds: the roster owns who we know and how to reach them, the sweep file owns coverage, a profile owns one target's assessment, an approach owns one target's messages. A further name duplicates one of them and goes stale against it, so analysis, working notes, worklogs, issue write-ups and segment summaries live outside the campaign folder.

A second TSV created to be merged into the first one later is the recurring form of the breach, and the merge is the step that does not happen: context runs out, the user leaves, the machine reboots, the agent is stopped mid-run, and the file stays holding data nobody can account for. An agent talks itself past this whenever the roster looks inconvenient: another writer holds it (a running P or A batch, a second sweep, another session), several agents are fanning out over one segment, the findings are unvalidated and want staging, bulk merging at the end looks cheaper, a crash once ate work so an in-repo copy feels safer, a subagent should not touch shared state, the pass is only scratch, or no column fits what was found. The answer to each is the same: wait for the roster or write to it now, unproven rows marked unproven and anything homeless in `s_note` prose until the owner names a column, because scratch in a tracked directory is not scratch.

### Enforcement

I2 was violated the same day it was written into the S procedure, by the session that wrote it, under the first reason on that list. Prose alone did not hold, so it rests on:

1. **Conformance** — `spar-campaign-directory.md` shows the layout with no optional extras, so a planner copying the template creates nothing else.
2. **Procedure** — `spar-S-search.md` §8 gives a sweep one output, the roster, and one writer at a time per segment.
3. **This file** — the statement a procedure or template is measured against when they disagree.
