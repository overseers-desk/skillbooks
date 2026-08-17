# Almanac Sweep

Run daily or weekly to keep `events/2026.yaml` current.

## Goal

Ensure the event list is complete, accurate, and actionable. The user should never be surprised by a missed deadline or an event they would have wanted to attend.

## 1. Update existing entries

For every event where `participation.status` is not `closed`, bring it up to date:

- Confirm dates if still TBC.
- Find and record speaker application deadlines. Mark `speaker.too_late: true` when the window has closed.
- Note early-bird pricing, sell-out risk, or discount codes in `participation.note`.
- For events within 60 days, check for programme changes that affect relevance (e.g. a new angel-investor side event, a relevant keynote addition).
- Do not downgrade `stars` without user confirmation. If an event is cancelled or registration has closed, mark it accordingly.

## 2. Discover new events

Find events the user would want to attend but that are not yet in the YAML. Read `almanac.yaml` for the user's interests, pull_events, bases, and frequent destinations. Read `keywords.yaml` for search inspiration — it contains queries that have worked before, but you are not limited to them. Invent better queries, try adjacent terms, follow leads from event pages, and explore sponsor/partner lists of known events.

When you find something worth tracking, add it to the events YAML with a star rating (see below).

After each sweep, update `keywords.yaml`: add queries that worked, note ones that didn't, adjust productivity ratings. The keyword file is yours to maintain.

## Rating an event

Three inputs, weighed together.

**Pull-event match.** The `pull_events` in `almanac.yaml` carry `weight: override`. An event that offers one of them directly (a room of angels, an open speaking slot, an organiser-run investor programme) outranks a larger or nearer event that does not.

**Interest match.** Read the interest's `scope` field, including what it excludes. The exclusions are written against a category, so check that the event belongs to the category being excluded before applying one. An event whose investor or startup programme is its point is not excluded by a line aimed at enterprise trade shows.

**Proximity.** Measure it. Each base declares an `event_radius_km`; compute great-circle distance from the base's `home_city` and compare. `frequent_destinations` names places worth going to regardless of distance, so it adds proximity and never withholds it: a city absent from that list but inside the radius is near.

Rate from these three every time you touch an entry, rather than carrying a rating forward because it is already written. Where you change a rating, say why in `notes`, in terms a reader can argue with. An adjective on its own ("generic", "academic", "massive") is not a reason and should not be carried between entries or between sweeps.

## Opportunity estimates

Star ratings say how well an event fits. They say nothing about how much of the thing you came for is in the building. That is what `estimates` carries, and it is estimated rather than looked up.

```yaml
estimates:
  attendees: [60000, 80000]
  investors: [1500, 4000]
  basis: >
    No published investor count. An investor pass is a sold ticket class and the
    startup programme runs matched meetings, so investors are a defined cohort.
    A comparable-scale event in this file states 3,600. Range set wide.
access:
  mechanism: matched_1to1   # curated_intro | pitch_stage | open_floor
  gate: application         # membership | ticket | none
```

Organisers rarely publish a segment breakdown, and an unpublished figure is not a null. Spend one search on it, then estimate from what is observable: which ticket classes are sold, whether the programme names the cohort, the organiser's figures for adjacent segments, and comparable events already in this file. Record a range and widen it rather than omitting the estimate. Put the reasoning in `basis` in a sentence or two. Reserve `none` for a segment that genuinely does not attend.

Segment keys come from the `interests` and `pull_events` ids in `almanac.yaml`, so the same segment is named the same way across entries.

`access` is observed rather than estimated, and it is what makes the population count for anything: a matched programme turns a large crowd into meetings, an open floor does not. Record the two separately and leave them separate; combining them into a single score requires weights nobody has measured.

## 3. Alert on deadlines

After updating, surface anything that needs the user's attention:

- Speaker deadlines approaching (within 14 days).
- Events within 30 days where no participation decision has been made.
- Events whose dates are still TBC but expected soon.

Write all changes directly into `events/2026.yaml` — new events appended under the appropriate star tier, updated fields edited in place. The user will review the diff after the sweep.

## 4. After sweep

- Update the `# Last sweep:` comment at the top of the events YAML.
- Commit with a message summarising what changed.
