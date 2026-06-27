# Invariants — outreach-spar

Hard rules the rest of the methodology must not contradict. When a procedure, template, prompt, field placement, or example here disagrees with an invariant, the invariant wins and the other is the bug to fix. These are stated once, here, because they have been re-violated by operational artifacts that drifted from the principle stated elsewhere.

## I1. A profile is campaign-independent and time-stable

A contact's profile is a property of the contact, shared by every campaign that ever targets them. It must read the same whether built today for one campaign or in a month for a different one.

The test (the same question as `spar-methodology.md`, "Campaigns and segments"): would re-profiling this contact for a different campaign, or simply at a different time, change this line? If yes, the line is not profile content.

Three kinds of content fail the test and therefore never enter the profile:

- **Our pitch** — the angle, the ask, the argument for why they should say yes. It turns on the campaign's goal, so it changes every campaign. Home: the approach phase (campaign × segment plan, and the approach YAML).
- **Our engagement state with them** — prior correspondence, warmth, whether we are connected on LinkedIn, "no prior contact". The second campaign finds a different answer, and the first message we send falsifies it. The profile would be stale the moment the approach button is pressed. Home: the engagement tier (approach YAML), determined fresh per campaign at approach time.
- **Our own facts / USP** — our metrics, our track record, our value proposition. They drift over time and are framed differently per campaign. Home: the campaign's `usp_document`, read by the approach phase.

What the profile *does* hold: facts about the contact (role, history, audience, what they cover, who they know) and our campaign-independent judgement of their general value to us — `star_rating` and `match_rationale`, expressed as the contact's own attributes weighed against the segment's standing needs (`rating_rubric`, `discovery_criteria`), never against one campaign's ask or USP.

## Enforcement (why prose alone is not enough)

This invariant has been stated in `spar-methodology.md` since the three-tier spec, and was still violated in every profile of a real campaign, because the profiler follows the concrete template in front of it, not a principle in another file. So I1 is enforced in three coordinated places:

1. **Conformance** — the profile template (`spar-P-profile.md` §5), the procedure steps, and the worker prompt (`spar-manager/prompts/spar-p.txt`) carry no pitch, engagement, or USP section. There is nothing for the profiler to fill with campaign-bound content.
2. **Mechanical backstop** — `spar-validate` fails a profile whose body carries engagement markers (a prior-correspondence or warmth line, a "no prior contact" statement, an angles/pitch section). A leak is a build failure, not a style note.
3. **This file** — the single statement the prompt references and the validator cites.
