# SIFT Registry Format

**Applies to:** all SIFT campaigns. Campaign-specific columns are appended after the core set and documented in the campaign configuration, not here.

## File format

One TSV file per campaign. TSV, not CSV — registry fields contain URLs, free-text notes, and comma-separated tags that cause quoting problems with commas.

Every row must have an `id` and a `url`. A row without these is not a listing. The file is named `registry.tsv` and lives in the campaign root directory. Do not embed the campaign name in the filename — the directory already carries that context.

**Delimiter and line-break conventions:** Tab (`\t`) separates fields; newline (`\n`) separates rows. Neither may appear inside a field value. When a field needs to represent a line break within its content (e.g. a multi-sentence note), use carriage return (`\r`) instead of newline. Standard tools (LibreOffice, Python `csv` with `delimiter='\t'`, pandas) read `\r` inside a field without treating it as a row boundary.

**Programmatic access:** Use `trdsql` (not `q`) for SQL operations on registry files. Both tools run SQL against flat files, but they differ on `\r` handling, which matters because registry fields use `\r` for in-field line breaks:

- `trdsql` treats bare `\r` as in-field data and preserves it on round-trip. `q` treats `\r` as a record separator and converts `\r` to `\n` on output.
- Double round-trip through `trdsql` is byte-identical; `q` corrupts on the first pass.

Standard invocation for reading: `trdsql -id "\t" -ih "SELECT ... FROM registry.tsv"`. For writing back: `trdsql -id "\t" -ih -od "\t" -oh "SELECT ... FROM registry.tsv" > registry-new.tsv`.

## Core columns

Columns are ordered left-to-right by pipeline phase: discovery, scoring, then disposition. A human scanning a row reads the listing's identity first, then progressively later-stage information.

### Discovery (Sweep)

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 1 | id | string (mandatory) | Sweep | All phases | Row identifier. Format defined per campaign (e.g. `J001` for jobs, `G001` for grants). |
| 2 | date_found | ISO date | Sweep | Human review | Date the listing was discovered |
| 3 | date_posted | ISO date | Sweep | Fit, human review | Date the listing was originally published. Extracted from structured data where available. Empty if not determinable. |
| 4 | source_name | text | Sweep | Investigate, Fit | Who published the listing (employer, funder, conference, procuring authority) |
| 5 | title | text | Sweep | Fit, Target | Listing title as published |
| 6 | location | text | Sweep | Fit | City, country, or "Remote" |
| 7 | url | URL (mandatory) | Sweep | Investigate (fetches it) | Primary URL. Publisher's own site preferred over aggregator mirrors. |
| 8 | source | text | Sweep | Human review | How the listing was found (e.g. web search, job board, mailing list, referral) |
| 9 | alive | enum: yes/no/unverified | Sweep; Investigate updates | Fit (skips dead), human review | Whether the listing is confirmed live |
| 10 | notes_sweep | text | Sweep | Investigate, Fit | Free-text observations from discovery |

### Scoring (Fit)

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 11 | stars | decimal 1.0–5.0 | Fit | Target, human review | Composite value-to-us score from campaign-defined dimensions |
| 12 | pct | integer 0–100 | Fit | Target, human review | Likelihood-of-success after amplification, capped at 95 |
| 13 | pct_base | integer 0–100 | Fit | Human review (audit) | Raw fit before amplification |
| 14 | hard_gates | text | Fit | Target, human review | Credential or requirement gates that block candidacy. Comma-separated. Empty if none. |
| 15 | notes_fit | text | Fit | Target, human review | Free-text rationale for star and pct scores |

### Disposition (Target)

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 16 | decision | enum: respond/skip/watch/network-approach | Target | Human review | Final disposition |
| 17 | date_responded | ISO date | Target (post-submission) | Human review | Date response was submitted. Empty until responded. |
| 18 | status | enum: not-started/responded/screening/advanced/final/accepted/closed/withdrawn | Target (updated over time) | Human review | Current progress through the selection process |
| 19 | notes_target | text | Target | Human review | Free-text notes on response preparation and progress |

Columns 11–19 are empty during Sweep and populated progressively as the listing moves through Fit and Target. Empty columns are expected; not every listing reaches every phase.

## Campaign-specific columns

Campaigns append columns after column 19. The campaign configuration defines them. The specific columns depend on the domain. Examples:

**Job-seeking campaigns** might add: `company`, `seniority`, `comp_estimate`, `work_mode`, `role_family`, plus star-dimension breakdown columns (`influence_knowledge`, `comp_modifier`, `stepping_stone`, `labour_fit`), plus response columns (`cv_lane`, `cv_emphasis`, `cv_deemphasis`, `approach_channel`, `contact_notes`).

**Grant campaigns** might add: `funder`, `programme`, `funding_amount`, `deadline`, `eligibility_region`, plus star-dimension columns, plus proposal columns.

**CFP campaigns** might add: `conference`, `track`, `deadline`, `acceptance_rate`, `audience_size`, plus star-dimension columns.

Campaign-specific columns must not duplicate core columns under different names. If a campaign needs a field that serves the same purpose as a core column, use the core column.

## Phase notes vs full artefacts

| Phase | Full artefact | Registry column |
|---|---|---|
| Sweep | Registry row (Sweep's primary output) | notes_sweep: why this listing was included |
| Investigate | Dossier file (`dossiers/{id}.md`) | (no note column — the dossier is the artefact) |
| Fit | Dossier Fit section (scores with rationale) | notes_fit: summary rationale for star and pct scores |
| Target | Response materials (campaign-specific) | notes_target: disposition reasoning and progress |

## Quality checklist

These assertions apply to the core columns. Campaign-specific checks are defined by the campaign configuration.

1. Every row has a non-empty `id` that is unique within the registry.
2. Every row has a non-empty `url`.
3. Every row has the expected number of tab-separated fields.
4. No two rows share the same `url`.
5. Every row with a `stars` value also has a `pct` value (both are Fit outputs; one should not exist without the other).
6. Every row with `decision` = `respond` has a non-empty `stars` and `pct` (cannot disposition without scoring).
7. Every row with `alive` = `no` has either `decision` = `skip` or empty Target columns (dead listings should not be pursued).

## Relationship to other documents

This document defines the registry schema. The methodology for populating it is defined in `sift-methodology.md`:

- **SOP 1: Sweep** — populates columns 1–10
- **SOP 2: Investigate** — updates column 9 (`alive`); creates dossier files (not registry columns)
- **SOP 3: Fit** — populates columns 11–15
- **SOP 4: Target** — populates columns 16–19
