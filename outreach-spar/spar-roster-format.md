# SPAR Roster Format

**Applies to:** all SPAR campaigns. Campaign-specific columns are appended after the core set and documented in the campaign plan, not here.

## File format

One TSV file per segment. TSV, not CSV — roster fields contain quoted speech, URLs, and free-text that cause quoting problems with commas.

Every row must have a `contact_name`. A row without a named person is not a contact. Each S&P iteration updates the same file via the `sweep_iteration` column; do not create separate files per iteration. The file is named `roster.tsv` and lives inside the segment's own directory (e.g. `wedding-planner/roster.tsv`). Do not embed the segment name in the filename — the directory already carries that context.

**Delimiter and line-break conventions:** Tab (`\t`) separates fields; newline (`\n`) separates rows. Neither may appear inside a field value. When a field needs to represent a line break within its content (e.g. a multi-sentence note), use carriage return (`\r`) instead of newline. Standard tools (LibreOffice, Python `csv` with `delimiter='\t'`, pandas) read `\r` inside a field without treating it as a row boundary.

**Programmatic access:** Use `trdsql` (not `q`) for SQL operations on roster files. Both tools run SQL against flat files, but they differ on `\r` handling, which matters because roster fields use `\r` for in-field line breaks:

- `trdsql` treats bare `\r` as in-field data and preserves it on round-trip. `q` treats `\r` as a record separator (splitting one row into two) and converts `\r` to `\n` on output.
- `trdsql` correctly quotes fields containing `\r` on output and reads both quoted and bare forms. `q` does not quote such fields on output and then cannot parse its own output (row count increases).
- Double round-trip through `trdsql` is byte-identical; `q` corrupts on the first pass.

Standard invocation for reading: `trdsql -id "\t" -ih "SELECT ... FROM roster.tsv"`. For writing back: `trdsql -id "\t" -ih -od "\t" -oh "SELECT ... FROM roster.tsv" > roster-new.tsv`. For cell-level updates, use `CASE WHEN` expressions in the SELECT. For inserting `\r` in SQL strings, use `char(13)`. Tested 2026-03-26 on the Singapore activation `outreach-ready.tsv`.

## Core columns

Columns are ordered left-to-right by pipeline stage: identity, contact channels, discovery provenance, validation, then phase handover (S, P, A, R). A human scanning a row reads the contact's identity first, then progressively later-stage information.

### Identity

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 1 | contact_name | text (mandatory) | S | P, A, R | Identity anchor — no row without this |
| 2 | organisation | text | S; P corrects | P, A | Org at discovery time; P updates if stale |
| 3 | role | text | S; P corrects | P, A | Title at discovery time; P updates if stale |

### Contact channels

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 4 | phone | text | S; P updates | A | |
| 5 | email | text | S; P updates | A | |
| 6 | linkedin_url | URL | S | P (fetches it) | Contact channel and profiling source |
| 7 | facebook_url | URL | S | P (fetches it) | Contact channel and profiling source |

Every row must have at least one of email, linkedin_url, or facebook_url populated. Phone alone is insufficient for campaigns that begin with a written introduction.

### Discovery provenance

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 8 | sweep_iteration | integer | S | Human review | Which sweep iteration added this row |
| 9 | discovered_via | text | S; P for new names found during profiling | Human review, future S | Referral chain traceable to the original seed source |
| 10 | discovery_source | text | S | Human review | Specific mechanism: "LinkedIn comment", "Facebook group co-admin", "WebSearch: [query]" |

### Validation

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 11 | verified | yes/no | S initial; P confirms or corrects | A, quality check | Role confirmed via independent source |
| 12 | date_found_invalid | ISO date (YYYY-MM-DD) | S, P, or A | S (skips row), A (skips row), human review | Marks stale contacts without deleting them. The date rather than a flag allows periodic re-checking. Set when the person has left the relevant role entirely (retired, changed industry), or when profiling or approach drafting determines the contact is not a campaign target (e.g. operates a competing venue with no cooperation incentive, or the profile concludes there is no viable approach angle). |

### Phase handover

Each SPAR phase has one note column. Only that phase writes to it. Subsequent phases read it as context before doing their work. Notes are roster-level summaries, not replacements for full artefacts (profile documents, comms files, strategy revision notes).

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 13 | s_note | short text | S only; frozen after discovery | P, A | Why S included this person — the source statement, event, or signal that justified the entry. P reads this before profiling to check whether the person matches the rationale. |
| 14 | p_note | short text | P only | A, human review | What P found: the verified evidence of interest, the recommended angle, any cautions for A. Broader than evidence of interest alone — includes corrections, routing advice, and warnings. |
| 15 | star_rating | 0–5 | P; A may set to 0 | A (band ordering), human review | Strategic value: how interesting this contact is to the campaign. Scale defined in SPAR-P. A value of 0 means "invalid — not a campaign target." When star_rating is set to 0, date_found_invalid must also be set. The date_found_invalid field records when the determination was made; p_note or a_note records the reason. A star_rating of 0 is distinct from 1: a 1-star contact is low-priority but targetable; a 0-star contact is excluded from the pipeline entirely. |
| 16 | response_likelihood | percentage | P | A (band ordering) | Estimated probability the contact responds to outreach. |
| 17 | a_note | short text | A only | R (human review), subsequent A bands | Angle used, key hook referenced, outcome. Lets R scan a band's results from the roster without opening every comms file. |
| 18 | r_note | short text | R (human) only | Subsequent A bands, S&P₄+ | Per-contact observation from response review: what worked, what did not, new leads mentioned, channel adjustment. |

Columns 15–18 are empty during S and populated progressively as the contact moves through P, A, and R. Empty columns are expected; not every contact reaches every phase.

## Phase notes vs full artefacts

| Phase | Full artefact | Note column |
|---|---|---|
| S | Roster row (this is S's primary output) | s_note: why this person was included |
| P | Profile document (`profile-name-org.md`) | p_note: one-line relevance summary and routing for A |
| A | Communication log (`ID-name-org-comms.md`) and comms index entry | a_note: angle and outcome summary for R |
| R | Strategy revision notes (`strategy-revision-[band].md`) | r_note: per-contact observation from the human reviewer |

A phase note should answer: "what does the next phase need to know about this contact from my phase, in one line?" If the observation requires more than a short sentence, it belongs in the full artefact, not in the note column.

## Campaign-specific columns

Campaigns may append columns after column 18. The campaign plan defines them. Common additions include:

- **segment** — when the campaign has multiple segments in a single roster or needs to tag cross-leads
- **postcode** or **location** — for geographic filtering
- **type** — contact category within a segment (e.g. "strategic", "corporate", "community")
- **source_url** — the specific page that justified inclusion

Campaign-specific columns must not duplicate core columns under different names. If a campaign needs a field that serves the same purpose as a core column, use the core column.

## Quality checklist

These assertions apply to the core columns. Campaign-specific checks are defined by the campaign plan.

1. Every row has a non-empty `contact_name` that is not a placeholder.
2. Every row has the expected number of tab-separated fields.
3. No two rows share the same (`contact_name`, `organisation`) pair (case-insensitive).
4. Every row has at least one of email, `linkedin_url`, or `facebook_url`.
5. Every row has a `sweep_iteration` value.
6. No contact marked `verified=yes` has a `p_note` or `date_found_invalid` indicating they left the role.
7. Every row with a `star_rating` also has a `response_likelihood` (both are P outputs; one should not exist without the other).
8. Every row with `star_rating = 0` has a non-empty `date_found_invalid`.

## Relationship to other documents

This document defines the roster schema. The operational procedures for populating it are:

- **SPAR-S** (`spar-S-search.md`) — populates columns 1–13
- **SPAR-P** (`spar-P-profile.md`) — populates columns 14–16, corrects columns 2–7 and 11–12
- **SPAR-A** (`spar-A-approach.md`) — populates column 17
- **R** (human, no procedure document) — populates column 18

SPAR-S §4 currently contains a roster format definition that predates this document. When SPAR-S is next revised, §4 should reference this document rather than defining the format inline.
