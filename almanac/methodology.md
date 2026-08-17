# Almanac Methodology

The almanac answers the question: given that time is finite and geography is constraining, where should one be, and when?

A conference in one city, an investor meetup in another, and a family obligation on the far side of the world may all fall within the same month. One cannot attend all. The almanac exists to make that trade-off explicit rather than leaving it to whichever invitation arrives last.

The methodology has three stages. The first, discovery, is implemented. The second and third are not yet built.

## Where the data lives

This repository holds the method. The event data lives in the user's own repository, in a folder handed to the sweep at run time, holding:

- `profile.yaml` — bases, interests, pull events (opportunities important enough to override the default location plan), frequent destinations, and seasonal presence constraints.
- `keywords.yaml` — a living ledger of search terms that have surfaced relevant events here.
- `<year>.yaml` — the rated list: a star, a shortlist flag, a participation status and the reasoning behind each.
- `cache/` — one file per event holding what was observed about it, and a record of every search run, including those that found nothing.

The split is by profile dependence. A fact about an event is the same for everyone and caches. A star depends on whose year is being planned and does not.

## Stage 1: Discovery

**Goal:** maintain a complete, current list of events and opportunities worth considering.

The process is `sweep.md`. A sweep agent runs periodically, reads the cache before searching, verifies what has gone stale, discovers what is missing, and writes facts to the cache and judgments to the rated list. It maintains `keywords.yaml` as it goes, adding productive queries and retiring unproductive ones.

The output is a rated list with a star reflecting how well each event matches the user's interests and how reachable it is from the bases, alongside an estimate of how much of the relevant audience is in the building and by what mechanism the user could reach them. `bin/render-almanac` builds an HTML view for human review.

What discovery does not do: decide which events to attend. It presents the field of possibilities.

## Stage 2: Evaluation

**Goal:** given the discovered events and the user's constraints, determine which combinations of events and locations yield the most value across a planning window, typically one to three months.

This is the hard problem. A single event is easy to evaluate. What is difficult is the interaction between events, because attending one often precludes attending others, not through a clash on the same day but through the geographic commitment that surrounds it.

### The clustering problem

Events are not independent. Three conferences in one city across a month amount to a single "be in that region" commitment. If the user is committed elsewhere that month, all three are lost as a group. Conversely, a single five-star event might not justify a long-haul trip alone, but two three-star events in the same week nearby make the cluster compelling.

Evaluation therefore works with clusters rather than individual events. A cluster is a set of events attendable from a single geographic position within a contiguous window.

### Weighing presence against absence

For each planning window, the evaluator weighs:

**Value of being in location A:**
- Event value in reachable clusters: stars, pull-event matches, speaking slots secured
- Non-event obligations from `seasonal_presence`: family commitments, school terms, visa or residency requirements
- Ongoing work that benefits from a specific timezone or locale

**Cost of not being in location B:**
- Events in B's reachable clusters that are foregone
- Deadlines or relationships that decay without physical presence
- Whether the event recurs: a conference missed this year may exist next year

The output is a set of **presence decisions**, each naming a base or region and a date range, with an explicit accounting of what is gained and what is foregone. The user reviews and adjusts before they pass to Stage 3.

### What evaluation does not do

It does not book flights. It does not produce an itinerary. It produces a commitment to be in a region during a window, and the events within that window worth attending.

## Stage 3: Agenda and travel optimisation

**Goal:** given the presence decisions from Stage 2, produce a concrete travel plan: flights, accommodation, and a day-by-day agenda.

This stage connects to the `travel/` SOPs, which handle trip-level logistics. The almanac's job ends where the trip begins:

- Presence decisions become journey folders in `travel/`.
- Each is processed by `travel/sop-travel-master.md`, which coordinates booking extraction, cluster research, itinerary assembly and mental journey simulation.
- The almanac may influence routing. Where presence decisions produce an out-and-back sequence through the same region twice, the optimiser should consider whether the legs combine into a single loop.

### Interface between almanac and travel

The almanac produces, per planning window:

1. Confirmed events with dates and locations.
2. A presence schedule: which base or region, which dates.
3. Constraints: must-attend events, family travel segments, visa limits.

Travel consumes these and produces journeys. The boundary is clean: the almanac decides *where and when*; travel decides *how*.

## Current state

| Stage | Status |
|---|---|
| Discovery | Implemented: `sweep.md`, `bin/render-almanac`, and the data folder's rated list, cache and keyword ledger |
| Evaluation | Not yet built; design decisions and open questions in `evaluation-design.md` |
| Agenda and travel optimisation | Partially exists in `travel/`; interface from the almanac not yet defined |
