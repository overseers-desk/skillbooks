---
profile_date: 2026-04-18
star_rating: 0
richness: thin
richness_count: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Ed Madon
  organisation: Baybridge Lawyers
  role: CFO
  date_excluded: 2026-04-18
---

# Profile: Ed Madon

**Excluded contact.** Written at user request despite §5.4. Exclusion reason in "Relevance assessment" below; roster carries authoritative `date_excluded`.

## Prior correspondence (IMAP)

Not searched — contact excluded at §4.0 validation before IMAP step.

## Current role

CFO at Baybridge Lawyers, Sydney. LinkedIn headline: "CFO | Financial Leadership | Director". Pronouns He/Him. Sydney and surrounds. 500+ connections. CPA Canada credential shown on profile intro card.

## Career history

Full chronology not retrievable — LinkedIn lazy-loads Experience/Education blocks after initial render, and `--dump-dom` snapshots before hydration. Only the intro card and a prior-role fragment ("Group Head of Finance: FP&A and ...", truncated, captured by the sweep into the roster `contact_name` slot in error) are visible.

| Period | Role | Organisation | Notes |
|---|---|---|---|
| current | CFO | Baybridge Lawyers (Sydney) | Primary employer per header card |
| prior | Group Head of Finance, FP&A (truncated) | unknown | Captured by sweep; company not resolved in this fetch |

## Certifications and education

- CPA (Chartered Professional Accountants of Canada)
- Further education entries not retrievable from lazy-loaded DOM

## Volunteer and mentorship

None surfaced.

## What they have said publicly

No public statements retrievable from the profile shell. No blog, press, or conference material pursued — contact excluded before §4.5 web search.

**Absent themes:** insurance, risk, renewal, claim, D&O, cyber, business interruption, broker — none of the campaign's rule-4 keywords appear in Ed's own rendered profile content. The "Corporate insurance specialist..." phrase present in the DOM belongs to a *Chris Graham* sidebar card ("Más perfiles para ti"), not to Ed's About.

## Who they know (connections relevant to campaign)

| Person | Relationship | Relevance to campaign |
|---|---|---|
| Chris Graham (NRS) | Ed has LinkedIn admin rights on the NRS company page (ID 109900221) | Internal to the campaign's own organisation — see exclusion below |

## Relevance assessment

**What they have NOT said:** no public engagement on insurance, risk, or broking topics retrievable.

**What IS relevant:** nothing for the target population. Two hard-exclusion signals:

1. **Rule 5 (law-firm employer).** `segment.yaml` discovery_criteria rule 5 excludes contacts whose current employer is in the legal industry. Baybridge Lawyers is a Sydney law firm (confirmed via LinkedIn sidebar cards for colleagues: "Partner – Litigation and Intellectual Property - Baybridge Lawyers | Trade Marks Attorney | Sydney"; "Special Counsel, Baybridge"). CFO of a law firm is in an excluded industry, regardless of C-suite title.
2. **Inside the campaign's own org.** Ed has admin access to the National Risk Solutions LinkedIn company page (company ID 109900221, visible as `Empresa: National Risk Solutions` in the page-admin dropdown of Ed's session). This places him inside Chris Graham's own organisation — a colleague/partner, not a prospect. Contacts internal to NRS are not in the S&P₁ target population.

Either signal alone is sufficient for exclusion. The combination is decisive.

## Angles (ordered by fit)

None. Contact excluded.

## Verification corrections

- `contact_name`: `Anterior: Group Head of Finance: FP&A and` (malformed sweep capture of a Spanish-UI "Previous role" fragment) → `Ed Madon`
- `organisation`: `(unknown)` → `Baybridge Lawyers`
- `role`: empty → `CFO`
- `industry`: `unknown` → `law`
- `date_excluded`: empty → `2026-04-18` (rule-5 exclusion; see assessment above)
- `star_rating`: empty → `0`
- `s_note`: expanded to record the headline-resolution outcome
- `p_note`: recorded exclusion reason with detail

Email / Facebook URL not sought — contact excluded before §4.4a.

## Findability probe

Skipped — procedure runs only at end of normal P profile work; excluded contacts do not receive probe scores.
