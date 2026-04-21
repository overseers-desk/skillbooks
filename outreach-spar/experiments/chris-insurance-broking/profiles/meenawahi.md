---
profile_date: 2026-04-18
star_rating: 0
yield: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Meena Wahi
  organisation: Monash Business School (Insurance Advisor; cyber/tech/health insurance specialist)
  role: Insurance Advisor
  date_excluded: 2026-04-18
---

# Profile: Meena Wahi

**Exclusion note.** The roster row `meenawahi` was carried into P with `contact_name="Graeme Berwick OAM"` — a sweep-side data error that duplicated Berwick's name across three unrelated LinkedIn URLs. The LinkedIn URL `/in/meenawahi/` belongs to **Meena Wahi**, a Melbourne-based cyber-risk / insurance advisor. Her identity was verified by fetching the profile directly. She is structurally excluded from this campaign (segment rule 5 — insurance industry); per SPAR-P §5.4 excluded contacts do not normally receive a profile document, but one is written here at explicit request to preserve the audit trail of the contact-name correction and exclusion reasoning.

## Prior correspondence (IMAP)

Not searched. Structural exclusion under §4.0 short-circuits the IMAP step — there is no A-phase downstream that would consume warmth. `warmth_finding: cold` recorded as a default, not as an IMAP finding.

## Current role

**Insurance Advisor**, affiliated with Monash Business School (advisory capacity). LinkedIn headline: "Digital Cyber Risk Advisor | Board Member | Health, IP & Tech - Insurance Specialist." Location: Melbourne, Victoria, Australia. Public positioning is that of an independent insurance specialist operating across cyber, health, IP, and tech lines, with a broker-adjacent advisory model. Self-described as providing "multi-sector program advisory, complex program structuring" — language that mirrors corporate-broker positioning. LinkedIn groups her in the "cyber-data-risk-managers-insurance-brokers" browsemap cluster.

## Career history

Full experience list could not be extracted from the headless DOM snapshot (only the current-position block rendered). Career-history enrichment was not pursued because the structural exclusion under §4.0 removes the need — the decision does not turn on any additional role detail.

| Period | Role | Organisation | Notes |
|---|---|---|---|
| Current | Insurance Advisor / Digital Cyber Risk Advisor | Monash Business School (advisory) + independent | Cyber, health, IP, tech insurance lines; board-advisory bent |

## Certifications and education

- MBA (per profile suffix "Meena Wahi, MBA"). Institution and date not extracted.

## Volunteer and mentorship

- "Board Member" self-described in headline; specific boards not extracted.

## What they have said publicly

No post or article content was captured in the DOM snapshot (activity section did not render in the headless fetch). The only public signal captured is the headline positioning itself.

**On own practice (LinkedIn headline):** "Digital Cyber Risk Advisor | Board Member | Health, IP & Tech - Insurance Specialist."

**On own practice (LinkedIn About, paraphrase):** positions as an "insurance specialist providing multi-sector program advisory, complex program structuring" — corporate-broker register.

**Absent themes:** No captured statements on manufacturing, transport/logistics, sports, tourism, hospitality, retail, or wholesale sectors as a buyer-side operator. No captured statements positioning herself as a C-suite executive controlling her own company's insurance program.

## Who they know (connections relevant to campaign)

Not pursued. 11+ mutuals with Chris Graham surfaced incidentally in the DOM; given the structural exclusion this is a peer/competitor overlap in the insurance-advisory space, not a campaign-relevant connection graph to mine.

## Relevance assessment

**What they have NOT said:** Nothing positioning her as a C-suite buyer at a manufacturing / transport / sports / tourism / hospitality / retail / wholesale company — because she is not one.

**What IS relevant:** Nothing, under the current segment definition. Her visible identity sits inside the campaign's explicit hard-exclude category.

## Angles (ordered by fit)

No applicable angles. Contact is structurally excluded.

## Verification corrections

Applied to `roster.tsv` at `stem=meenawahi`:

- `contact_name`: "Graeme Berwick OAM" → "Meena Wahi" (roster-side sweep error; `/in/meenawahi/` is and was Meena Wahi's URL).
- `organisation`: "(unknown)" → "Monash Business School (Insurance Advisor; cyber/tech/health insurance specialist)".
- `role`: empty → "Insurance Advisor".
- `industry`: "unknown" → "insurance".
- `country`: unchanged (AU — confirmed Melbourne VIC).
- `date_excluded`: empty → "2026-04-18".
- `star_rating`: empty → "0".
- `p_note`: populated with exclusion reasoning.

The same contact-name error affects `stem=melissa-crozier` (also carries `contact_name="Graeme Berwick OAM"` against a different LinkedIn URL). Out of scope for this P run; flagged here so the next P run on that stem catches it.

## Findability probe

Not applicable. Contact is structurally excluded under segment rule 5; the probe is a signal for valid contacts' approach-phase cue availability, and no approach will be drafted.

- findability_score: n/a
- query_used: n/a
- note: excluded contact — probe skipped per experiment scope (valid contacts only).
