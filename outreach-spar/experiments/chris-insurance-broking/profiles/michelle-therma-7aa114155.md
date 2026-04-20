---
profile_date: 2026-04-18
star_rating: 0
richness: limited
richness_count: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Michelle Therma
  organisation: Ethos360 Recruitment
  role: Recruitment Consultant
  date_excluded: 2026-04-18
---

# Profile: Michelle Therma

## Prior correspondence (IMAP)

Not searched — this campaign's sender inbox (chris@nationalrisksolutions.com.au) is not among locally indexed accounts available to this agent, and the contact is structurally excluded (see §4.0 below), so IMAP lookup is moot. Warmth defaults to cold.

## Current role

Recruitment Consultant, **Ethos360 Recruitment** (Melbourne, Victoria). LinkedIn headline reads "Recruitment Consultant at Ethos360 Recruitment." Ethos360 is a Melbourne-based recruitment/staffing firm — not a manufacturer, transport/logistics operator, sport, tourism, hospitality, retail, or wholesale employer. Michelle is not a C-suite executive at a target company; she is a recruiter who sources into those roles.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | Recruitment Consultant | Ethos360 Recruitment | Melbourne, Victoria |
| prior | — | — | LinkedIn Experience section not rendered under headless capture; pre-current roles not recovered |

## Certifications and education

- Monash University (degree details not rendered under headless capture)

## Volunteer and mentorship

None surfaced.

## What they have said publicly

No substantive public statements surfaced on any campaign-relevant theme.

**Absent themes:** insurance, risk, broker, renewal, claims, D&O, cyber, business interruption, policy wording — none present on her profile. The two faint keyword hits in the captured DOM ("insurance", "risk") appear in sidebar recommendation cards for other companies (one of which is National Risk Solutions itself), not in Michelle's own content.

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| — | — | No campaign-relevant named connections surfaced; 80+ shared connections with the session account reported as a count only |

## Relevance assessment

**What they have NOT said:** anything on insurance, risk, or C-suite program control.

**What IS relevant:** nothing structural. Michelle does not satisfy segment discovery rule 2 (current title must contain CEO / CFO / CIO / Owner / Founder / Managing Director — hers is "Recruitment Consultant") nor rule 3 (employer must be in manufacturing, transport/logistics, sports, tourism, hospitality, retail, or wholesale — Ethos360 is a recruitment firm). She is adjacent to the campaign's target population in that she sources C-suite finance roles into manufacturers, which is almost certainly why the v2-matrix query `CFO manufacturing+geo:AU` surfaced her, but adjacency to the mechanism is not the mechanism (SPAR-P §4.0).

## Angles (ordered by fit)

None. The contact is excluded at §4.0 (structural fit) — no angles apply.

## Verification corrections

- `organisation` — was `(unknown)`. Backfilled to `Ethos360 Recruitment` from LinkedIn headline.
- `role` — was `CFO`. Corrected to `Recruitment Consultant` from LinkedIn headline. The "CFO" value was a sweep miscategorisation: v2-matrix surfaced her against query `CFO manufacturing+geo:AU start:0` because her recruiting activity matches those keywords, and the s_note "parse-search: name confirmed from window" attests only that the person exists, not that the role was verified.
- `date_excluded` — set to `2026-04-18`. Reason in `p_note`: fails segment rules 2 (title) and 3 (industry).
- `star_rating` — set to `0` in roster TSV and in this profile's front matter. Noted that SPAR-P §5.1 states 0 should not appear in front matter and §5.4 states excluded contacts have no profile document; this file exists at explicit user direction overriding §5.4 for the purpose of capturing the exclusion reasoning in the profile corpus rather than only the roster `p_note`.
- `linkedin_url` — confirmed live, resolves to the correct individual (unique surname "Therma" + matching URL slug; no namesake collision).
- `email`, `facebook_url`, `phone` — not researched; research halted at §4.0.
- No replacement search — the roster row is not a "person left the role" case; it is a "sweep misread the role" case. There is no "real CFO at Ethos360 Recruitment" to substitute because Ethos360 itself is out of scope (rule 3).

## Findability probe

- findability_score: 0
- query_used: `"Ethos360 Recruitment" Melbourne "Recruitment Consultant"` (initial); refined `"Michelle Therma" Ethos360` (not run — contact already excluded, probe run with inferred keys only per experiment spec)
- note: not materially informative for this row — the contact is excluded at §4.0, so findability-to-warmth correlation is moot; recording a probe score only for bookkeeping consistency with the campaign's experimental sweep.
