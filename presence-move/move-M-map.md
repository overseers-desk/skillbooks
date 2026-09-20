# MOVE Map — the range becomes a field, fixed points and clusters

Map reads the almanac over one range and lays out what an election has to work with. It decides nothing about where to be. It runs first, and again only when the field changes.

## Coverage before anything

Read the head of each year file the range touches. The sweep writes there the date it last ran and the window it covered. The range has to sit inside a covered window: an election over dates the almanac never swept would rank a field that was never assembled, and the confident plan that results is worse than none. Where the range runs past the window, stop and say which window a sweep has to cover before MOVE can run.

A year file whose header carries a date but no window predates the rule. The sweep's commit message or the owner says what it covered; absent both, treat the window as unknown and ask.

Record what was read as `almanac_as_of`: per year file, the sweep date and window, and the data root's commit where the root is a repository. A later re-election compares against this to know whether the field moved.

## The field

An event is in the field when its edition dates, read from the cache, intersect the range, and its star in the year file is three or more. A two-star entry joins when the narrow reason its entry gives is what this range or this profile puts in play; the entry says what the reason is, so read it rather than the number. One-star entries stay out; the sweep keeps them so a search does not repeat, not for attending.

Events whose dates are unset but expected inside the range go in the field as unplaced, with the month the cache expects. They cannot anchor a cluster and enter an offer only as a condition.

Dates, venues, access and prices come from the cache and are not restated. The field lists slugs, stars and the cluster each joins.

## Fixed points

Some things are decided before any offer is drafted, and a plan that breaks one is not an offer.

- **Presence the profile fixes.** A `seasonal_presence` entry with high certainty whose months touch the range fixes the base for those dates, with the companion model it names. Probable presence is the default, not a fix; Value weighs departures from it.
- **Committed events.** An entry with `participation.status` of `ticket` or `speaker` is attended; every offer includes it.
- **The owner's shortlist.** `shortlisted: true` is the owner's own pre-election word. It fixes nothing, and Value treats it as the strongest preference short of a commitment.
- **Pull events.** Where the field offers what a `pull_events` entry with `weight: override` names, mark the event; the rubric says how far it outranks the rest.

## Deadlines inside the range

From each in-field event's cache entry, list the deadlines that fall inside the range or before it starts and gate attendance: a registration close, an early-bird price, a call for speakers. An offer that includes the event has to be elected before that date, and Elect reads this list to say by when. The sweep's own alerts cover deadlines generally; this list is the subset a plan for this range turns on.

## Clusters

Two events cluster when one trip covers both: the same city, or cities a day's ground travel apart, inside a span short enough that staying costs less than returning to a base and coming back. Compute great-circle distances between cities the way the sweep computes proximity; judge the rest, since a day's travel differs by country and by whether the party is one person or a family. A cluster carries its events, its span, its anchor (the event the trip would be made for, by star and pull-event match), and one sentence on why it holds together.

A single event far from everything is a cluster of one, and the honest note is that a trip for it alone stands or falls on that event. A base is a cluster too, of whatever sits inside the base's own event radius, and it is the one every offer can fall back to.

Name clusters by region and month so an offer can cite them. Do not rank them; that is Value's, on whole plans.

## Output

The `almanac_as_of`, `field`, `fixed`, `deadlines` and `clusters` sections of the move file, in the shape `move-methodology.md` shows. Where a judgment was made (why a two-star entered, why two cities clustered), write the reason in terms a reader can argue with.
