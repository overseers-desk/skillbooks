# MOVE — where to be, given a date range

**Phases:** Map, Offer, Value, Elect

## What MOVE is

The almanac rates events one at a time, for a year or a season, and says of each what treatment it deserves. MOVE answers the question the almanac leaves open: given a date range, which sequence of places to be in, and which events to attend from each. It runs on the almanac's data root and produces an election: one presence plan, chosen by the owner from lettered offers, with the reasons, what was foregone, and a hand-off the travel procedures can start a journey from.

Events interact through geography, and that is why the almanac's ratings do not add up to a plan on their own. Three events in one region a fortnight apart are one commitment to be there, and a base elsewhere loses all three as a group. One strong event may not justify a long-haul trip that two nearby middling events make worthwhile. So MOVE works in clusters and plans. Map turns the range into clusters of events reachable from one position; Offer assembles plans from them; Value compares the plans on several dimensions at once; Elect records the owner's choice.

- **Map** reads the almanac for the range, checks that the range was swept, gathers the events in it, marks what is fixed before any choice is made, and groups the rest into clusters by region and time.
- **Offer** assembles two to four presence plans that span the range, each feasible in gross terms, each anchored on a different cluster, one of them the plan of not moving at all.
- **Value** scores each offer on a vector of dimensions, with the owner's rubric binding, and recommends one with the trade it makes stated.
- **Elect** is the owner's. The choice is recorded in the move file with the events foregone and the presence schedule that travel takes over.

**Direction:** inward and windowed. The field is already assembled and rated; MOVE reads it over one range, decides between plans rather than between events, and hands the decision on. It runs as prompts, like the sweep, because the decisions in it are judgment (whether a cluster holds together, what a foregone event costs) rather than routing.

## Two ranges

An almanac is built for a year or a season. The sweep records at the top of each year file the date it ran and the window it covered. An election is for a range the owner names, shorter than the almanac's and rarely aligned with it: a fortnight, a quarter, the gap between two fixed commitments. The two are not the same thing and the method keeps them apart.

The rule that follows: an election range sits inside a swept window. Map checks this first. A range that runs past what the sweep covered has no field to elect from, and MOVE stops there and names the sweep that is needed, rather than electing from a field that was never assembled. A range crossing a year boundary reads both year files and checks both windows.

## Why the method exists

AI planning a season fails in repeatable ways, each countered by a mechanism:

- **Event-by-event thinking.** The best-rated event is attended and the cluster around a lesser one is lost. Countered by Map, which clusters before anything is compared, and by Offer, which builds plans rather than picking events.
- **The ledger as the plan.** The almanac's year file is a mostly add-only record maintained by sweeps. A plan written into it goes stale on the next sweep, and stale the other way when a fare or a family date moves. Countered by the move file: one artefact per range, rewritten on each re-election, with the ledger untouched (`INVARIANTS.md`).
- **Electing over an unswept range.** A confident plan for dates the almanac never covered. Countered by the coverage check in Map.
- **Silent election.** The AI picks, when what is being decided is where the owner will be. Countered by the split between `recommended` and `elected`: an unattended run ends at the recommendation.
- **The composite score.** One number hides the trade between two plans that differ in kind, one cheaper and one better attended. Countered by Value's vector: the dimensions stay separate and the recommendation names the trade.
- **Ratings carried as reasons.** A star is a treatment, not an argument, and a plan justified by adding stars up cannot be argued with. Countered by the rule the sweep already holds: reasoning in terms a reader can dispute.

## Runs and the data root

A run is one range, elected once and re-elected as often as the triggers below fire. Everything MOVE reads lives in the almanac's data root: the profile, the rubric, the year files, the cache, the rates. Everything it writes lives under `moves/` in that root, one file per range, named by the range. The method holds nothing about any owner; the data root holds everything about one.

The dividing test for any fact: would the next sweep change it? Then it is the sweep's and lives in the year file or the cache. Would a different range change it? Then it is the move file's. A fare is neither an event fact nor a rating, so it goes in the move file with the date it was checked.

## The phases

Each phase has its own document; this file says what each is for and what crosses its boundary.

**M — Map** (`move-M-map.md`). Consumes the range and the data root. Produces the coverage record, the field of events in range, the fixed points, the deadlines that fall inside the range, and the clusters. Sonnet-tier.

**O — Offer** (`move-O-offer.md`). Consumes the map. Produces two to four lettered offers, each an ordered sequence of stays with the events attended from each and the moves between them. Sonnet-tier.

**V — Value** (`move-V-value.md`). Consumes the offers, the rubric, the cache and the rates. Produces the value table, a narrative per offer, and the recommendation with its trade stated. Opus-tier.

**E — Elect** (`move-E-elect.md`). The owner's phase. Consumes the recommendation and the owner's word. Produces the election, the foregone list with reasons, and the hand-off for travel.

## The move file

One YAML per range at `moves/<start>_<end>.yaml`, dates in ISO form. Its sections are the phases' outputs in order, so a reader can see where each judgment came from. Values below are placeholders; a real file carries the data root's own identifiers.

```yaml
range: {start: 2027-03-01, end: 2027-04-15}
almanac_as_of:
  2027: {last_sweep: 2027-01-20, window: [2027-01-20, 2027-06-30]}
  commit: 0f3a9c1        # the data root's commit when read, where the root is a repository
fixed:
  - {kind: presence, base: <base id>, from: 2027-03-01, to: 2027-03-10, why: seasonal_presence, certainty high}
  - {kind: event, slug: <slug>, why: participation.status speaker}
deadlines:
  - {slug: <slug>, kind: early_bird, date: 2027-03-05}
clusters:
  - id: <region>-mar
    region: <region>
    span: [2027-03-12, 2027-03-20]
    events: [<slug>, <slug>, <slug>]
    anchor: <slug>
    holds_because: >-
      one city and a second within a day by rail, the three events inside nine days
offers:
  - letter: A
    name: stay at base
    stays:
      - {where: <base id>, from: 2027-03-01, to: 2027-04-15, attend: [<slug>]}
  - letter: B
    name: anchor on <region>-mar
    stays:
      - {where: <base id>, from: 2027-03-01, to: 2027-03-10, attend: []}
      - {where: <region>, from: 2027-03-11, to: 2027-03-21, attend: [<slug>, <slug>], via: <hub>}
      - {where: <base id>, from: 2027-03-22, to: 2027-04-15, attend: [<slug>]}
values:
  dimensions: [event_value, presence, cost_of_absence, travel_burden, money, risk]
  table:
    A: {event_value: ..., presence: ..., cost_of_absence: ..., travel_burden: ..., money: ..., risk: ...}
    B: {event_value: ..., presence: ..., cost_of_absence: ..., travel_burden: ..., money: ..., risk: ...}
  narrative:
    A: >-
      ...
    B: >-
      ...
recommended:
  offer: B
  trade: >-
    B buys the <region> cluster for two long-haul legs and about <amount> <currency>;
    A keeps the base and forgoes it, and the anchor recurs next year
elected: null
```

After the owner's word, the election and the hand-off fill in:

```yaml
elected:
  offer: B
  on: 2027-02-02
  reason: >-
    the anchor's speaking slot was confirmed the day before
foregone:
  - {slug: <slug>, in: A, why: recurs annually, the cluster does not}
handoff:
  presence:
    - {where: <region>, from: 2027-03-11, to: 2027-03-21}
  constraints:
    must_attend: [<slug>]
    companions: <as the profile states for this presence>
    visa: <the rule the profile names for the region>
```

## Re-election

The elected set changes more often than the almanac, and the method expects it. Three triggers re-run the file, each from Value unless the field itself changed:

- **The almanac moved inside the range.** The sweep, on adding an event at four or five stars, moving a date, or marking a cancellation or a status change, names the move file whose range holds it (`../almanac/sweep.md`, alerts). Map and Offer re-run only when events entered or left the field; a date shift within a cluster re-runs Value.
- **A travel factor moved.** A fare, a companion's availability, a visa condition, a family date. Owner-invoked; Value re-runs with the new figure recorded.
- **The owner changed their mind.** Elect re-runs; the reason goes in the file.

Each re-election rewrites the same file. Git holds the history; the file holds the current election and the reason it replaced the last.

## Interface to travel

The election's `handoff` is what the travel procedures take at the start of a journey: a presence schedule (region, dates) and the constraints around it (events that must be attended, who travels, visa limits). Travel decides how; MOVE decided where and when. A journey folder opens from one presence entry, or from several when they chain through a region without a return to base.

## What MOVE is not

Not the sweep: it discovers nothing and rates nothing, and an event it cannot find in the almanac does not exist for it. Not travel: it books nothing and plans no day. Not a scorer: it never sums its dimensions into one number. Not the owner: it recommends.
