---
profile_date: 2026-04-18
star_rating: 0
richness: thin
richness_count: 2
warmth_finding: cold
applicable_angles: []
dependent_data:
  contact_name: Rudy Sheriff
  organisation: National Risk Solutions
  role: Managing Director
  date_excluded: 2026-04-18
---

# Profile: Rudy Sheriff

**Excluded contact.** Per SPAR-P §5.4 excluded contacts normally have no profile document; this file exists at explicit user request and records the exclusion reasoning so the decision is reviewable from git history alone.

## Prior correspondence (IMAP)

Not searched. Exclusion was determined at §4.0 (structural fit against segment file) before email research was warranted.

## Current role

Managing Director, National Risk Solutions. LinkedIn headline (verbatim): "Corporate insurance specialist providing multi-sector program advisory, complex program structuring and global insurer placement, delivered through a director-led model." Location signals: Australia (NSW indicators in DOM, no city resolved).

National Risk Solutions Pty Ltd is the campaign sponsor's own firm — Chris Graham is its director (see `/home/weiwu/code/aesop/nrs-overview.md`). The headline phrasing is the NRS spoken brief verbatim.

## Career history

Not enumerated. Career-history extraction would not change the exclusion outcome.

## Certifications and education

Not extracted. See above.

## Volunteer and mentorship

Not extracted.

## What they have said publicly

Not researched beyond the LinkedIn headline.

**Absent themes:** n/a — public-statement collection was not run.

## Who they know (connections relevant to campaign)

Not researched.

## Relevance assessment

**What they have NOT said:** n/a (not researched).

**What IS relevant:** the contact's institutional position is the campaign's own sponsor firm. Outreach from National Risk Solutions to a National Risk Solutions colleague is not the campaign mechanism.

## Angles (ordered by fit)

None. The contact is excluded at §4.0.

## Exclusion reasoning

Two independent grounds:

1. **Segment rule 5 (insurance broker employer).** `segment.yaml` discovery_criteria rule 5 hard-excludes employers in the insurance industry, including brokers. National Risk Solutions operates as a corporate authorised representative under Insurance Advisernet Australia (AFSL 240549) — broker.
2. **Self.** National Risk Solutions is the campaign's own firm. The campaign sends outreach *from* NRS *to* C-suite at qualifying client industries; NRS staff are not the target population.

Either ground alone is sufficient. `star_rating: 0` per §4.9. `date_excluded: 2026-04-18` per §4.0 / §4.11.

## Verification corrections

Roster updates written this run (sqlite3 against `roster.tsv`):

- `contact_name`: `CFO` → `Rudy Sheriff` (the prior value was a placeholder seeded by the LinkedIn keyword sweep, not a name)
- `organisation`: `(unknown)` → `National Risk Solutions`
- `role`: blank → `Managing Director`
- `industry`: `unknown` → `insurance`
- `verified`: `no` → `yes`
- `star_rating`: blank → `0`
- `date_excluded`: blank → `2026-04-18`
- `p_note`: appended exclusion reasoning and a flag against the conflicting `francine-hackett` row.

**Flag for separate cleanup (not this row's responsibility):** the `francine-hackett` roster row carries the same `linkedin_url` (`/in/rudy-sheriff-b30a0a34/`) but identifies the URL's owner as Francine Hackett, CFO Buildkite. The current DOM dump of that URL is unambiguously Rudy Sheriff at NRS. The francine-hackett identification appears to be a prior P-run error and should be re-checked; the URL collision suggests the LinkedIn-keyword-search source row was attached to two different identities by two different runs.

## Findability probe

- `findability_score: 0`
- `query_used: "National Risk Solutions" "Managing Director" Australia insurance`
- `note: Initial generic query returned only Chris Graham (NRS director, the campaign principal); Rudy Sheriff did not appear in the first 20 results. Probe rules disallow refining with the contact's name, so no second non-name refinement was tried that surfaced him. Low public visibility under inferred keys; the principal's namesake-collision-like dominance of NRS+role+geo results would defeat any A-phase cue building from non-name keys even if the contact were a valid target.`
