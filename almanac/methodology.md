# Almanac Methodology

The almanac answers the question: given that time is finite and geography is constraining, where should one be, and when?

A conference in one city, an investor meetup in another, and a family obligation on the far side of the world may all fall within the same month. One cannot attend all. The almanac exists to make that trade-off explicit rather than leaving it to whichever invitation arrives last.

Two methods share the work. Discovery, in this folder, keeps a rated list of events current. Election, in `../presence-move/`, chooses over a date range which plan of places and events to run. They work on different ranges: a sweep covers a year or a season, an election covers the range the owner names, and the election checks that its range lies inside a swept one.

## Where the data lives

This repository holds the method. The event data lives in the user's own repository, in a folder handed to the sweep at run time, holding:

- `profile.yaml` — bases, interests, pull events (opportunities important enough to override the default location plan), frequent destinations, and seasonal presence constraints.
- `keywords.yaml` — a living ledger of search terms that have surfaced relevant events here.
- `<year>.yaml` — the rated list: a star, a shortlist flag, a participation status and the reasoning behind each. A mostly add-only ledger, updated by each sweep.
- `cache/` — one file per event holding what was observed about it, and a record of every search run, including those that found nothing.
- `moves/` — one election per date range, written by the election method and never by the sweep.

The split is by profile dependence and by rate of change. A fact about an event is the same for everyone and caches. A star depends on whose year is being planned and does not. An election depends on the range and on travel factors that move faster than either, so it has a file of its own.

## Discovery

**Goal:** maintain a complete, current list of events and opportunities worth considering.

The process is `sweep.md`. A sweep agent runs periodically, reads the cache before searching, verifies what has gone stale, discovers what is missing, and writes facts to the cache and judgments to the rated list. It maintains `keywords.yaml` as it goes, adding productive queries and retiring unproductive ones.

The output is a rated list with a star reflecting how well each event matches the user's interests and how reachable it is from the bases, alongside an estimate of how much of the relevant audience is in the building and by what mechanism the user could reach them. `bin/render-almanac` builds an HTML view for human review.

What discovery does not do: decide which events to attend. It presents the field of possibilities.

## Election

`../presence-move/move-methodology.md`. Given a date range, MOVE maps the rated events in it into clusters, offers two to four presence plans, values them on a vector of dimensions with the owner's rubric binding, and records the owner's election with what was foregone. Its output is a presence schedule and the constraints around it, which is what the travel procedures start a journey from: the almanac decides where and when, travel decides how.

## Where each stage lives

| Stage | Where |
|---|---|
| Discovery | `sweep.md`, `bin/render-almanac`, and the data folder's rated list, cache and keyword ledger |
| Election | `../presence-move/` |
| Agenda and travel | `../travel/`, from a move file's hand-off |
