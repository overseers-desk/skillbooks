---
profile_date: 2026-04-18
star_rating: 0
yield: 2
warmth_finding: existing
applicable_angles: []
dependent_data:
  contact_name: Damian Mathews
  organisation: National Risk Solutions
  role: CFO / COO
  date_excluded: 2026-04-18
---

# Profile: Damian Mathews

## Exclusion summary

Damian Mathews is CFO / COO at **National Risk Solutions** — the campaign's own sending organisation (Chris Graham's firm; see `nrs-overview.md`). He is internal staff, not a prospect. Excluded per SPAR-P §4.0 (structural fit against segment: cannot be a customer of NRS) and §4.9 (star_rating = 0). The profile file exists only because it was explicitly requested; per §5.4, excluded contacts normally have no profile document.

## Prior correspondence (IMAP)

Not searched — the contact is an internal colleague of the sender, so IMAP history against director@ / admin@ is not diagnostic of warmth for outreach purposes. Warmth classification: existing relationship (co-worker).

## Current role

CFO / COO, National Risk Solutions (New Zealand). LinkedIn headline: "Corporate insurance specialist providing multi-sector program advisory, complex program structuring and global insurer placement, delivered through a director-led model." This headline mirrors Chris Graham's own NRS positioning verbatim, confirming joint firm identity rather than a parallel role at another company.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| Current | CFO / COO | National Risk Solutions | NZ-based; internal to the sending organisation |

LinkedIn parse did not surface the full experience list (JSON-embedded, not reached by the visible-text extractor). Further career history was not pursued because the §4.0 exclusion made deeper profiling moot.

## Certifications and education

- University of Bristol (degree unspecified — surfaced as a keyword hint only)

## Volunteer and mentorship

- Not researched (exclusion precedes this step).

## What they have said publicly

**Absent themes:** Not applicable — exclusion precedes public-activity research. LinkedIn headline is the only first-person statement captured.

## Who they know (connections relevant to campaign)

Not researched. As an NRS co-principal, his network is co-extensive with the sending organisation's network and does not function as an external bridge for outreach targeting.

## Relevance assessment

**What they have NOT said:** Not applicable (exclusion).

**What IS relevant:** The discovery is itself diagnostic — the S-phase LinkedIn keyword query (CFO + risk management + NZ) surfaced the sender's own colleague. Consider adding an exclusion rule to `segment.yaml` listing "National Risk Solutions" as a self-exclude employer, analogous to rules 5–6 for broker brand names, so the next sweep does not re-surface NRS staff.

## Angles (ordered by fit)

None. Target is internal staff; no angle applies.

## Verification corrections

Roster entry updated 2026-04-18:
- `contact_name`: "Strategic CFO" → "Damian Mathews" (prior value was a role phrase, not a name)
- `organisation`: "(unknown)" → "National Risk Solutions"
- `industry`: "unknown" → "insurance"
- `star_rating`: "" → 0
- `date_excluded`: "" → "2026-04-18"
- `p_note`: "CFO/COO at National Risk Solutions — the sending organisation. Internal staff, not a campaign target. Excluded per SPAR-P §4.0."
- `s_note`: refreshed to "resolved: Damian Mathews, NRS CFO/COO (NZ)"

No email, Facebook URL, or phone was written — contact channels for internal staff are out of scope for roster completeness.

## Findability probe

- findability_score: 2
- query_used: `"Damian Mathews" "National Risk Solutions"` (and the more generic `CFO "National Risk Solutions" New Zealand` also surfaces him via the NRS LinkedIn company page)
- note: Trivially findable because his role, company, and country are unambiguous and the company name is distinctive; but since he is internal staff this high score carries no approach-warmth signal.
