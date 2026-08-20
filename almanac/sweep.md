# Almanac Sweep

Run daily or weekly to keep the event list current.

## Where the data lives

This document is the method. The data is a separate folder, given to you when the sweep is invoked, and every path below is relative to it:

```
profile.yaml          bases, interests, pull_events, frequent destinations
keywords.yaml         queries that have worked here before
<year>.yaml           ratings and participation decisions
cache/SCHEMA.md       the shape of a cache file
cache/events/         one file per event: dates, access, audience, prices
cache/searches/       what has been looked for, including what came back empty
```

The split matters when you write. A fact about an event goes in `cache/events/`. A judgment about whether it suits this user goes in `<year>.yaml`. The same fact belongs in one file, never two.

## Goal

Keep the list complete, accurate and actionable. The user should not be surprised by a missed deadline or by an event they would have wanted to attend.

## 1. Read the cache before searching

The cache is the record of every sweep before this one, and re-establishing what it already holds is the largest avoidable cost in this procedure. Read it first, then verify on a schedule rather than on principle:

| Condition | Action |
|---|---|
| Event inside 30 days | re-check dates, deadlines, whether it still runs |
| Deadline inside 21 days | re-check it |
| Event beyond 90 days, `checked` within this year | trust the cache |
| Prices | only when a decision needs them |
| A search past its `revisit_after` | run it again |

`cache/searches/` records what has already been looked for and found empty. An absence recorded there is a finding, not a gap: establishing that a city is empty in a given month costs as much as finding an event in it, and the record exists so nobody pays twice.

## 2. Update existing entries

For every event whose `participation.status` is not `closed`, bring it up to date, writing facts to its cache file and judgments to the ratings file:

- Confirm dates where they are unset.
- Find and record application deadlines, speaking and otherwise.
- Note early-bird pricing, sell-out risk or discount codes.
- For events within 60 days, check for programme changes that affect relevance: a new investor side event, a relevant keynote.
- Re-rate from the three inputs below. Where an event is cancelled or registration has closed, mark it so.

Lowering a star needs the user's word. Raising one does not.

## 3. Discover new events

Find events the user would want and the list does not hold. Read `profile.yaml` for interests, pull events, bases and frequent destinations. Read `keywords.yaml` for queries that have worked here, and go beyond them: adjacent terms, leads from event pages, sponsor and partner lists of events already known.

Add what you find to both files: a cache file for what it is, an entry in the ratings file for what it is worth.

After the sweep, update `keywords.yaml`: add queries that worked, mark ones that did not, adjust the productivity ratings. That file is yours to maintain.

## Rating an event

Three inputs, weighed together.

**Pull-event match.** The `pull_events` in `profile.yaml` carry `weight: override`. An event offering one directly (a room of angels, an open speaking slot, an organiser-run investor programme) outranks a larger or nearer event that does not.

**Interest match.** Read the interest's `scope`, including what it excludes. An exclusion is written against a category, so check the event belongs to that category before applying it. An event whose investor or startup programme is its point is not excluded by a line aimed at enterprise trade shows.

**Proximity.** Measure it. Each base declares an `event_radius_km`; compute great-circle distance from the base's `home_city` and compare. `frequent_destinations` names places worth going to whatever the distance, so it adds proximity and does not withhold it: a city absent from that list but inside the radius is near.

Rate from these three every time you touch an entry, rather than carrying a rating forward because it is already written. Say why in the entry's reasoning, in terms a reader can argue with. An adjective alone ("generic", "academic", "massive") is not a reason, and travels between entries and between sweeps doing damage.

A star is a treatment, not a mood. 5: act now, and plan the season around it. 4: act when its named condition lands, an invitation secured, regional outreach done, a trip committed. 3: join when already in the region, never fly for it. 2: tracked for one stated narrow reason. 1: recorded so the search does not repeat. Rate by picking the level whose treatment fits, and name the treatment in the reasoning.

Where the data folder carries a `rubric.md`, that is the user's own weighing of these inputs and it binds: read it before rating, and argue each entry's reasoning from it. A star lowered on its authority holds against later sweeps the way a user-worded lowering does.

`shortlisted: true` marks an event the user has chosen to pursue. It is the user's to set. Leave the key absent otherwise; absent reads as not shortlisted.

## Opportunity estimates

A star says how well an event fits. It says nothing about how much of the thing the user came for is in the building. That is `audience` in the cache file, and it is estimated rather than looked up.

Organisers rarely publish a segment breakdown, and an unpublished figure is not a null. Spend one search, then estimate from what is observable: which ticket classes are sold, whether the programme names the cohort, the organiser's figures for adjacent segments, and comparable events already cached. Record a range and widen it rather than omitting the estimate. Put the reasoning in `basis`. Reserve `none` for a segment that genuinely does not attend.

Name segments in plain language: `investors`, `buyers`, `speakers`, `exhibitors`. A cache file knows nothing about whose year is being planned, so the profile's own vocabulary has no place in it. Use the same name for the same segment across every entry, and let the renderer map the profile's pull events onto those names.

`access` is observed rather than estimated, and it is what makes the population count for anything: a matched programme turns a large crowd into meetings, an open floor does not. Keep the two separate. Combining them into one score would need weights nobody has measured.

## Money without a purchase

Where an event puts capital in front of a founder, record what it costs. A prize that buys nothing and an accelerator's cheque that buys eight per cent both read as money on a listing, and they are opposite: one leaves the cap table untouched, the other prices the company as a condition of entry. `capital` holds this, and `dilutive` is the field that decides it.

Then go one step further, because eligibility is not addressability.

**An open door is not an invitation.** Entry criteria are what an organiser publishes, and a wide funnel costs them nothing and makes the competition look larger. Who they award to is never published as a policy and is demonstrated every year. Before recording a competition as an opportunity, read last year's winners, or the criteria that actually bind: the jury's own portfolio, the problem statements a sponsor has set, the sectors the past three cohorts came from. The same check reads a speaker call: last year's roster shows who gets the stage, as the winner list shows who gets the money.

Money given away goes to a niche far more often than to the field. A crypto conference's competition admits any sector and has awarded only crypto, because its jury is three crypto funds selecting deal flow. A fintech programme's entrants answer problem statements set by banks, so what the banks asked for decides who can compete, whatever the entry form says.

Record the finding against the event, not the rating, because it is equally true for anyone reading it. An entry that carries open criteria and an equity-free prize, and nothing about who wins, reads as an opportunity to a company that has no precedent for winning one.

**Note the exceptions, because they are the valuable half.** A competition that is genuinely wide is worth more than several narrow ones, and the only way to know is the same check. Where the winner history crosses sectors and the criteria bind on stage and size rather than subject, say so plainly in the record, so a later sweep does not discount it by the general rule.

## Searching well

Lessons this procedure has paid for.

**Budget the built-in search.** A session carries a limited number of web searches, and subagents draw on the same pool, so a handful of parallel researchers can exhaust it in minutes. Spend search on discovering that an event exists, then fetch the organiser's own domain for dates, prices and deadlines.

**Fetch the domain rather than searching the name.** Event names collide constantly, and two unrelated conferences a year apart will share one. Resolve on the domain.

**Believe the system that runs the thing.** Where a marketing page and the ticketing or speaker platform disagree, the platform is right. A call for speakers can be closed on the platform while the event's own site still invites applications.

**Search the registration window, not the event date.** Trade events close their floor months ahead. Find the registration deadline first and treat the event date as secondary.

**Check the domain still belongs to the event.** Lapsed domains get resold, sometimes to something unrelated. A confident answer built on a lapsed domain is worse than no answer.

**Watch for renames and relocations.** Events rename, merge, move city and move month between editions. Searching last year's name or slot finds nothing, or worse, finds a stale listing.

**Discard conference mills.** Several operations generate plausible "International Conference on X" listings for any city and month, and sell presentation slots. They are not events worth tracking.

**Treat a round number without a year as prior-year.** Organisers reuse last edition's attendance in the present tense. Widen the estimate range accordingly.

**A target is not a confession.** An organiser publishing target numbers may still have run before; read a prior edition's actuals before treating targets as evidence of no history.

**Give the range, not the archaeology.** Two sources with two figures make one range in the reasoning; which source carried which number stays in the cache.

## 4. Alert on deadlines

After updating, surface what needs the user's attention:

- Application deadlines inside 14 days.
- Events inside 30 days with no participation decision.
- Events whose dates are still unset but expected soon.

## 5. After the sweep

- Update the `# Last sweep:` comment at the top of the ratings file.
- Rebuild the page: `<method-repo>/almanac/bin/render-almanac <data-root> out/<year>.html`.
- Commit the data folder with a message summarising what changed. The generated page is not committed.
