---
profile_date: 2026-04-18
star_rating: 0
richness: thin
richness_count: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Derek Jorgensen
  organisation: Claim Partners Pty Ltd / WorldClaim Partners Australia
  role: Managing Director
  date_excluded: 2026-04-18
---

# Profile: Derek Jorgensen

**Segment exclusion — not a campaign target.** Derek Jorgensen runs Claim Partners Pty Ltd and WorldClaim Partners Australia, public loss adjusting / claims preparation firms that advocate for policyholders after a loss. This is squarely inside the insurance ecosystem excluded by `segment.yaml` rule 5 ("loss adjusters, claims managers… competing risk consultants"). No profile assessment is performed beyond confirming the exclusion basis. File retained per user override of SPAR-P §5.4.

## Prior correspondence (IMAP)

Not checked — segment-excluded before IMAP step. Warmth marked `cold` by default.

## Current role

Managing Director, Claim Partners Pty Ltd (Sydney / Berry NSW) and principal of WorldClaim Partners Australia (worldclaimpartners.com.au), the Australian arm of US-founded global public adjuster WorldClaim (Fusco family, 1983; 10 offices across 5 continents; >$4B claims handled). Policyholder-side claim advocacy: preparation, quantification, settlement negotiation across Australia, NZ, and the South Pacific.

## Career history

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | Managing Director | Claim Partners Pty Ltd | Policyholder-side loss adjusting / claims prep |
| current | Principal (AU arm) | WorldClaim Partners Australia | Rebrand/extension of Claim Partners into global network |
| prior | Loss adjuster | LMI Group | Claims / risk consulting |
| prior | Loss adjuster | Crawford & Company | Global loss adjusting |
| prior | Loss adjuster | Wyatt Gallagher Bassett | Loss adjusting |

Exact dates not captured — LinkedIn Experience section was auth-gated on the fetched view.

## Certifications and education

- Royal Society of Loss Adjusters credentials (per industry sources)
- Griffith University (degree/field not surfaced in fetched DOM)

## Volunteer and mentorship

Not surfaced.

## What they have said publicly

No substantive public statements captured. LinkedIn About (extracted from JSON payload): "Corporate insurance specialist providing multi-sector program advisory, complex program structuring and global insurer placement, delivered through a director-led model." (Note: this phrasing is unusually close to National Risk Solutions' own positioning; treat as low-confidence until verified against a logged-in DOM — it may be bleed-through from the viewer's context rather than Derek's own About copy.)

**Absent themes:** no captured public statements on insurance policy wordings, D&O, cyber, business interruption from a corporate-buyer perspective, broker-channel commentary, or any of the seven target verticals' risk programs.

## Who they know (connections relevant to campaign)

Not researched — segment-excluded before §4.7.

## Relevance assessment

**What they have NOT said:** n/a — segment-excluded at structural check.

**What IS relevant:** nothing at the campaign level. Derek is a competent insurance-claims professional but on the wrong side of the ecosystem boundary `segment.yaml` draws. The campaign targets corporate *buyers* of insurance (C-suite at manufacturing, transport, sports, tourism, hospitality, retail, wholesale). Claim Partners' own clients may be valid targets, but Derek himself is not.

## Angles (ordered by fit)

None. Contact fails `segment.yaml` rule 5 (insurance ecosystem exclusion: loss adjusters / claims managers). Set aside; do not progress to A-phase.

## Verification corrections

- `contact_name`: was corrupted as "Vivek Bhatia" (shared with multiple unrelated rows in the roster); corrected to "Derek Jorgensen" based on the LinkedIn URL `derek-jorgensen-49488265`.
- `organisation`: was "(unknown)"; backfilled to "Claim Partners Pty Ltd / WorldClaim Partners Australia".
- `role`: was empty; backfilled to "Managing Director".
- `industry`: was "unknown"; set to "insurance (public loss adjusting)".
- `star_rating`: set to 0 (segment-excluded); written to both this profile and the roster TSV.
- `date_excluded`: set to 2026-04-18 with reason recorded in `p_note`.
- `email`, `facebook_url`, `phone`: not researched (segment-excluded before §4.4a / §4.11 backfill).

Related data-quality observation: other roster rows also carry the placeholder `contact_name='Vivek Bhatia'` with unrelated LinkedIn URLs (e.g. `marc-chiarella`, `dr-rexine`, `phillip-bailey`). Flagged to operator; not corrected here.

## Findability probe

- findability_score: 0
- query_used: `"Managing Director" "Claim Partners" Sydney loss adjuster`
- note: Surfaces Claim Partners the firm and Derek's name on the company site, but the campaign's inferred keys (C-suite + one of the seven target industries + insurance-program keywords) do not apply — he is not a campaign target, so findability in the campaign's search vocabulary is structurally 0 rather than a measure of visibility.
