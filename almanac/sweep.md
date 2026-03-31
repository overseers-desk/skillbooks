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

When you find something worth tracking, add it to the events YAML with a star rating derived from the same logic used for existing entries (pull_event match, interest match, proximity to bases and frequent destinations).

After each sweep, update `keywords.yaml`: add queries that worked, note ones that didn't, adjust productivity ratings. The keyword file is yours to maintain.

## 3. Alert on deadlines

After updating, surface anything that needs the user's attention:

- Speaker deadlines approaching (within 14 days).
- Events within 30 days where no participation decision has been made.
- Events whose dates are still TBC but expected soon.

Write all changes directly into `events/2026.yaml` — new events appended under the appropriate star tier, updated fields edited in place. The user will review the diff after the sweep.

## 4. After sweep

- Update the `# Last sweep:` comment at the top of the events YAML.
- Commit with a message summarising what changed.
