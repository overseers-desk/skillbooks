---
profile_date: 2026-04-18
star_rating: 0
richness: thin
richness_count: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Chief Financial Officer - Waipa Networks
  organisation: (unknown)
  role: ""
  date_excluded: 2026-04-18
---

# Profile: William Parker (roster mismatch — excluded)

## Exclusion summary

The roster row `william-parker` carries `linkedin_url=https://www.linkedin.com/in/william-parker-97b31645/` with the label "Chief Financial Officer - Waipa Networks" and `industry=food`. The LinkedIn URL resolves to a different person and employer, and both candidate interpretations fail the segment's structural check (§4.0).

**Interpretation A — take the LinkedIn URL as authoritative:**
The profile at that URL is William Parker, **Managing Director, Hurford Parker Insurance Brokers** (New Zealand). Hurford Parker is an insurance broking firm. Insurance brokers are a hard exclude under segment rule 5 ("current employer is in the insurance … industries … brokers, underwriters, insurer staff"). Role title "Managing Director" would otherwise satisfy rule 2, but rule 5 supersedes.

**Interpretation B — take the "CFO Waipa Networks" label as authoritative:**
Waipa Networks Ltd is an electricity distribution (lines) company serving the Waipa District, New Zealand. Electricity utilities are not in the seven in-scope industries (manufacturing, transportation/logistics, sports, tourism, hospitality/leisure, retail, wholesale). Fails rule 3. The `industry=food` tag on the roster row appears to be a sweep-time misclassification; nothing in either candidate points to food.

Either reading fails the segment. No further research performed per §4.0.

## Prior correspondence (IMAP)

Not checked — contact excluded at §4.0 before §4.4.

## Current role

Per LinkedIn (headline): Managing Director, Hurford Parker Insurance Brokers, New Zealand.

## Career history

Not extracted — public/limited DOM view only exposed headline, current company, school, country. No dated experience entries returned by the parser.

## Certifications and education

- University of Otago (degree and dates not surfaced in the limited DOM view)

## Volunteer and mentorship

Not researched (excluded at §4.0).

## What they have said publicly

Not researched (excluded at §4.0).

**Absent themes:** N/A — no topical research performed.

## Who they know (connections relevant to campaign)

Not researched (excluded at §4.0).

## Relevance assessment

**What they have NOT said:** N/A.

**What IS relevant:** Nothing. Both interpretations of the roster row fail the segment's structural gate:

1. As the LinkedIn profile's actual owner (William Parker, MD Hurford Parker Insurance Brokers) — insurance broker, excluded by rule 5.
2. As the labelled "CFO Waipa Networks" — electricity lines company, outside the seven in-scope industries, excluded by rule 3.

## Angles (ordered by fit)

None. Contact excluded.

## Verification corrections

- `star_rating` set to 0 on roster row `william-parker`.
- `date_excluded` set to 2026-04-18 on roster row.
- `p_note` records the mismatch between LinkedIn URL (William Parker, insurance broker) and the roster label (CFO Waipa Networks), and the exclusion rationale for each interpretation.
- `organisation`, `role`, `email`, `facebook_url` left unchanged — no reliable value to backfill for a row that is being excluded; the displaced "CFO Waipa Networks" lead is not carried forward as a replacement entry because utilities are out of scope for this campaign.

## Findability probe

Not applicable — contact excluded, no profile-derived keys to test.
