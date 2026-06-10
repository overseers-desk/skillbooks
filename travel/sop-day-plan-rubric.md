# Day Plan Rubric Standard Operating Procedure

## Purpose

Plan a single day of travel by decomposition: fix the anchors first, enumerate the option set, run a standard set of checks as unconditional line items, and turn every two-way uncertainty into an explicit fork whose branches are separately costed. The plan is judged against the whole decision tree, not against the single expected path; an option that is "usually fine" is not fine when its bad branch misses a flight.

This SOP suits the mid-journey case: the travellers are somewhere concrete (a hotel, a city) and the day has a hard endpoint (a flight, a checkout, a timed event).

## Input

- The situation: where the travellers are, the date, the day's hard endpoint
- Booking documents from the journey folder, and traveller profiles, both per `sop-travel-folder-access.md`

## Output

- Day timeline with times, per-leg transport, and family-total costs
- Decision table: every fork, both branches costed, with in-day triggers
- The backward chain from each anchor with its latest-safe times

The caller names the output location.

## Procedure

### 1. Anchors

Extract the day's fixed points from documents, not from conversational memory: flights from the ticket PDFs (`pdftotext`: airport, departure time, terminal, who is on which booking reference), hotel checkout time, any timed tickets. When a remembered time and a document disagree, the document wins and the discrepancy is flagged.

Documents state entitlements and schedules, not the state of the world. A baggage allowance is a ceiling, not a manifest; the actual load is evidenced by what the travellers carried on the inbound leg. A fact about the ground takes ground evidence.

Convert each anchor into a backward chain with the buffers stated as numbers:

```
16:00 departure → 13:55 bag drop closes → 13:30 at terminal →
13:00 latest train from X → 12:40 leave hotel area
```

The chain's weakest link is the leg with the widest time band (step 3, check 4).

### 2. Option set

Enumerate before evaluating. Candidates drawn from memory are the famous and the walkable, with nothing between; the gap sits at exactly the radius a short ride covers.

- Enumerate what exists around the travellers' position by radius and category (museums, parks, attractions, events), out to the distance the day's slack allows. A maps or local-search skill, if available, beats text queries here: it searches by distance, not by words.
- Place-name queries clip at administrative boundaries; the next district, ten minutes away, is invisible to a query carrying this district's name. Enumerate by distance, or repeat the query with neighbouring district names.
- Adequacy test: a candidate set holding only doorstep options and city landmarks is the signature of memory-driven generation; regenerate before proceeding.
- Generate before framing the day. A day framed first ("just a transition, keep it low") sets the stopping rule before the search starts; what exists nearby is allowed to change the frame.

### 3. Standard checks

Run every line, every time; judgment decides what the findings mean, not whether to look. A check that comes back empty is recorded as checked-empty, not skipped.

| # | Check | What to record |
|---|-------|----------------|
| 1 | Weather | Hour-by-hour forecast for the day at each location; mark the outdoor-hostile hours |
| 2 | Traveller profiles | Ages, constraints, interests; which constraints bind today, which do not, and why |
| 3 | Opening hours | Each candidate activity against the actual calendar date (weekday pattern, holidays) |
| 4 | Transport per leg | Options with two time bands, typical and bad; family fare with child fare rules |
| 5 | Meals | Where each meal lands; what happens to it if the schedule slips an hour |
| 6 | Energy | Demanding activities against the youngest traveller's stamina; recovery gaps |

For check 4: rail and metro legs carry timetable frequency and run on the clock; road legs carry a range, and the range is the honest number. Time is costed in the same units as money; a leg that is £20 cheaper and an hour longer on the typical run is not the cheaper leg.

### 4. Forks

List every uncertainty that splits the day in two: rain or dry, jam or clear, open or closed, sold out or available, room ready or not. For each fork, cost both branches:

| Fork | Branch | Time | Money | Anchor risk |
|------|--------|------|-------|-------------|
| Rain at 10:00 | dry | park morning as planned | £0 | none |
| | wet | museum swap, 20 min repositioning | £24 family | none |
| M23 incident | clear | 45 min to terminal | £80 car | none |
| | jam | 90-150 min | £80+ | misses bag drop |

Three rules of reading the table:

- A fork whose bad branch threatens an anchor gets a **trigger**: the time by which the state is observable, and the switch action. If no trigger exists (the bad branch is discovered only when it is too late), that branch's option is out.
- Branches are compared at the tree level. An option that wins its good branch and loses the day on its bad branch loses to an option that is slightly worse on the good branch and indifferent on the bad one.
- Branches are costed against the traveller constraints as well as the clock. A bad branch whose duration crosses a profile threshold (motion sickness, stamina) fails even when it still makes the anchor; a constraint cleared on the typical run is re-checked on the bad one.

### 5. Compose the day

Assemble the timeline from activities that survive their forks, ordered so that the anchor chain is protected: the closer to the anchor, the more fixed-schedule the leg. Activities are picked with the profile findings in hand (check 2): a candidate that matches the travellers' interests beats a generic one at equal logistics.

### 6. Deliver

The three outputs above, plus one line per standard check confirming it ran and what it found (including checked-empty). The decision table is part of the plan, not working notes: the traveller carries the triggers into the day ("if not on the 12:48, drop X; if raining at 9:30, museum branch").

---

**End of SOP**
