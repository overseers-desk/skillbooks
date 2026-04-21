---
profile_date: 2026-04-17
star_rating: 0
yield: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Andrew Broughton
  organisation: Network Insurance House
  role: Chief Executive Officer
  date_excluded: 2026-04-17
---

# Profile: Andrew Broughton

## Prior correspondence (IMAP)

Not searched. Contact was excluded at §4.0 structural validation before IMAP lookup; cold assumed.

## Current role

Chief Executive Officer, Network Insurance House — Brisbane, Queensland, Australia. Network Insurance House is an Australian insurance broking firm (AFSL-licensed broker); ANZIIF affiliation visible on the profile card.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | Chief Executive Officer | Network Insurance House | CEO; only role surfaced in the static DOM |

Experience and Education sections did not render in the headless DOM; no further history extracted.

## Certifications and education

- Not visible in the dumped profile DOM.

## Volunteer and mentorship

- None recorded.

## What they have said publicly

**No public statements extracted.** The static DOM surfaced only the top card (name, headline, location, connection count).

**Absent themes:** no posts, articles, talks, or press quotes observed on insurance program buying, D&O, cyber, business interruption, renewal, or any campaign keyword — consistent with his position on the broker (sell-side) side rather than the corporate insurance buyer (buy-side) side.

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| — | 11 shared connections with Chris Graham (count only; names not enumerable from static DOM) | As a fellow broker/insurance-industry leader, overlap is expected; not campaign-relevant because the shared network is sell-side |

## Relevance assessment

**What they have NOT said:** nothing relevant surfaced; no indication of corporate buyer-side engagement with insurance programs.

**What IS relevant:** nothing — the relevance assessment is negative. He sits on the sell-side of the market the campaign is trying to reach; he is a peer/competitor of the sender, not a prospective client.

## Angles (ordered by fit)

None. Segment rule 5 hard-excludes broker employers ("brokers, underwriters, insurer staff, loss adjusters, claims managers, insurance lawyers, actuaries, reinsurers, and competing risk consultants"). Network Insurance House is an insurance broker; Andrew Broughton is its CEO. This is a §4.0 structural mismatch with the segment mechanism — the campaign targets C-suite who personally *control* (i.e. purchase) corporate insurance programs, not C-suite who *sell* them. No angle in the campaign's angle table applies.

## Verification corrections

- `contact_name`: roster held "Frank Lampert" (sweep parser glitch — same garbled name appears against multiple unrelated URLs in this roster). LinkedIn title, URL slug, and profile card all confirm the person is Andrew Broughton. Corrected in roster.
- `organisation`: roster blank → "Network Insurance House" (from LinkedIn headline).
- `role`: roster blank → "Chief Executive Officer" (from LinkedIn headline).
- `industry`: roster "unknown" → "insurance" (Network Insurance House is a broker).
- `star_rating`: set to 0 per §4.9 (cannot deliver campaign outcome through the segment's mechanism).
- `date_excluded`: set to 2026-04-17 with reason recorded in `p_note`.
- Email / LinkedIn URL / Facebook URL: no backfill. Email not searched (contact excluded before §4.4a); LinkedIn URL already present; no Facebook search run.

## Findability probe

- `findability_score: 2`
- `query_used: "Network Insurance House" CEO Brisbane`
- `note: Broughton is the named CEO of an identifiable Brisbane broking firm; he surfaces trivially via role+company+city, though this is sell-side visibility irrelevant to this campaign's buy-side targeting.`
