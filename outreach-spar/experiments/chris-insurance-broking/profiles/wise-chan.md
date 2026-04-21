---
profile_date: 2026-04-18
star_rating: 0
yield: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Wise Chan
  organisation: WTW
  role: Senior Adviser & Mentor (Client Development | C-Suite | Growth Strategy)
  date_excluded: 2026-04-18
---

# Profile: Wise Chan

## Exclusion summary

Excluded at §4.0 on two independent grounds:

1. **Rule 1 (geography):** LinkedIn location is "Isla de Hong Kong, Hong Kong (RAE)". Segment is ANZ-only.
2. **Rule 5 (employer ecosystem):** Current organisation is WTW (Willis Towers Watson), on the segment's hard-exclude broker list. Structural mismatch with the campaign mechanism — WTW is a competing broker, not a buyer of broking services.

Either exclusion alone is sufficient. No outreach path via this contact.

The S-phase row carried a parse-glitch `contact_name` of "Actual:" — corrected to "Wise Chan" during this run.

## Prior correspondence (IMAP)

Not checked. Contact is excluded on structural grounds (§4.0); IMAP check is not prerequisite to exclusion and was skipped to avoid wasted effort.

## Current role

Headline on LinkedIn: "Client Development | C-Suite | Growth Strategy | Business Transformation", shown alongside the current-company badge for WTW. A secondary headline fragment surfaced by the parser — "Senior Adviser & Mentor | Former CEO & Board Member | Built market-leading FinTech & PropTech Companies" — may belong to an adjacent promoted profile and is flagged as low-confidence.

Location: Hong Kong Island, Hong Kong SAR.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | Client Development / advisory | WTW (Willis Towers Watson) | Company badge visible on profile; detailed role titles and dates not rendered in `--dump-dom` output. |
| prior (unverified) | Associated with National Risk Solutions | National Risk Solutions | Surfaced via keyword search ("Empresa: National Risk Solutions") — likely a "company associated" cross-reference on the profile, not verified as Wise Chan's own role. Worth flagging to Chris Graham as a possible historical link. |

Experience section lazy-loads and did not render in headless fetch; full dates not captured.

## Certifications and education

- The University of Queensland (programme and dates not rendered).

## Volunteer and mentorship

Not rendered in fetched DOM.

## What they have said publicly

No posts or public activity rendered in the fetched DOM. Keyword search ran for: insurance, risk, broker, claim, renewal, D&O, cyber, policy wording, business interruption — only "insurance" (once, inside a company tagline block) and "risk" (once, as "National Risk Solutions" company reference) surfaced. All other campaign terms: absent.

**Absent themes:** broker, claim, renewal, D&O, cyber, business interruption, policy wording — no substantive content on any segment topic in the fetched DOM.

## Who they know (connections relevant to campaign)

28 mutual connections with Chris Graham's viewing account. Specific names not surfaced by the parser. Not pursued further given the §4.0 exclusion.

## Relevance assessment

**What they have NOT said:** No public statements on any campaign topic in the fetched DOM.

**What IS relevant:** Nothing within segment scope. The contact is outside the geographic catchment and sits inside the insurance-broking ecosystem the campaign excludes by design.

## Angles (ordered by fit)

None. Contact excluded at §4.0.

## Verification corrections

- `contact_name`: "Actual:" → "Wise Chan" (corrected S-phase parse glitch).
- `country`: "NZ" → "HK" (LinkedIn location is Hong Kong, not New Zealand; the NZ tag appears to have been an S-phase heuristic error from the "Founder+cyber+insurance+geo:NZ" query origin).
- `industry`: "unknown" → "insurance-broker".
- `organisation`: left as "(unknown)" in TSV pending confirmation of WTW role detail; front-matter `dependent_data.organisation` records WTW based on the LinkedIn company badge.
- `date_excluded`: set to 2026-04-18 with reason in `p_note`.
- `star_rating`: set to 0.

## Findability probe

findability_score: 0
query_used: `"Wise Chan" WTW Hong Kong insurance`
note: Contact is out-of-scope for the campaign (HK-based, at an excluded broker), so findability does not affect outreach; not pursued beyond the initial query.
