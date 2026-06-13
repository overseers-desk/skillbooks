# SPAR Roster Format

**Applies to:** all SPAR campaigns. Campaign-specific columns are appended after the core set and documented in the campaign plan, not here.

## File format

One TSV file per segment. TSV, not CSV — roster fields contain quoted speech, URLs, and free-text that cause quoting problems with commas.

Every row must have a `contact_name`. A row without a named person is not a contact. Each S&P iteration updates the same file via the `sweep_iteration` column; do not create separate files per iteration. The file is named `roster.tsv` and lives inside the segment's own directory (e.g. `wedding-planner/roster.tsv`). Do not embed the segment name in the filename — the directory already carries that context.

**Delimiter and line-break conventions:** Tab (`\t`) separates fields; newline (`\n`) separates rows. Neither may appear inside a field value. When a field needs to represent a line break within its content (e.g. a multi-sentence note), use carriage return (`\r`) instead of newline. Standard tools (LibreOffice, Python `csv` with `delimiter='\t'`, pandas) read `\r` inside a field without treating it as a row boundary.

**Programmatic access:** Use `sqlite3` for SQL operations on roster files. Do not use `trdsql`, `q`, `csvq`, or Python's `csv` module — they apply CSV quoting rules to TSV output, corrupting fields that contain double quotes.

## Core columns

Columns are ordered left-to-right by pipeline stage: identity, contact channels, discovery provenance, validation, then phase handover (S, P). A human scanning a row reads the contact's identity first, then progressively later-stage information. The roster ends at the P phase: it is the segment's campaign-independent population record, so the campaign-bound A and R outputs do not live here (see "Phase handover" below).

### Identity

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 1 | stem | filename stem (mandatory) | S | P, A, state machine | Unique contact ID, set at discovery. Slug form: `firstname-lastname-organisation`. Derives file paths: profile at `profiles/{stem}.md`, approach at `approach/{stem}.yaml`. Must be unique within the segment. Renaming is high-impact (see design note): the stem keys the filesystem artefacts the state machine reads, so a rename has to move `profiles/{stem}.md` and `approach/{stem}.yaml` to the new path in the same change. |
| 2 | contact_name | text (mandatory) | S | P, A, R | Identity anchor — no row without this |
| 3 | organisation | text | S; P corrects | P, A | Org at discovery time; P updates if stale |
| 4 | role | text | S; P corrects | P, A | Title at discovery time; P updates if stale |

**Design note:** `stem` is set at sweep time (not at profile creation) so that it is a stable primary key throughout the pipeline. Because `stem` exists from the moment a contact enters the roster, SPAR-P and SPAR-A do not write back to the roster to record their artefact names; they create their files at the paths derived from the pre-existing `stem` (`profiles/{stem}.md` and `approach/{stem}.yaml` respectively). Contact state is determined by file existence on disk, not by TSV field values. A rename is therefore a coordinated change across the TSV row, both file paths, and any cross-referencing notes; do it when the alternative is worse (a stem collision is the clearest case), and move all three in the same commit so the state machine sees no break.

### Contact channels

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 5 | phone | text | S; P updates | A | |
| 6 | email | text | S; P updates | A | |
| 7 | linkedin_url | URL | S | P (fetches it) | Contact channel and profiling source |
| 8 | facebook_url | URL | S | P (fetches it) | Contact channel and profiling source |

Every row must have at least one of email, linkedin_url, or facebook_url populated. Phone alone is insufficient for campaigns that begin with a written introduction.

### Discovery provenance

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 9 | sweep_iteration | integer | S | Human review | Which sweep iteration added this row |
| 10 | discovered_via | text | S; P for new names found during profiling | Human review, future S | Referral chain traceable to the original seed source |

### Validation

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 11 | date_excluded | ISO date (YYYY-MM-DD) | S, P, or A | S (skips row), A (skips row), human review | Marks contacts that should not be advanced further, without deleting them. The date rather than a flag allows periodic re-checking. Set when the person has left the relevant role entirely (retired, changed industry), when profiling determines the contact is not a campaign target (wrong mechanism, no individual identifiable after exhaustive search, or low relevance), or when approach drafting concludes no viable angle exists. The roster carries the date; the reason lives in the writing agent's note — `s_note` for S-authored exclusions (stale contacts discovered during sweep), `p_note` for P-authored exclusions, and the approach YAML's `a_note` root key for A-authored exclusions. See §Artefact retention below. |

### Phase handover

The S and P phases each have one note column in the roster. Only that phase writes to it; subsequent phases read it as context before doing their work. Notes are roster-level summaries, not replacements for full artefacts (profile documents, approach files, strategy revision notes). The A and R phases do not write to the roster: their per-contact output (`response_likelihood`, `a_note`, `r_note`) is campaign-bound, and a segment's roster is shared across campaigns, so that output lives in the per-contact approach YAML instead (see `spar-methodology.md`, "Campaigns and segments", and `spar-A-approach.md`).

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 12 | s_note | short text | S only; frozen after discovery | P, A | Why S included this person — the source statement, event, or signal that justified the entry. P reads this before profiling to check whether the person matches the rationale. |
| 13 | p_note | short text | P only | A, human review | What P found: the evidence of interest, the recommended angle, any cautions for A. Broader than evidence of interest alone — includes corrections, routing advice, and warnings. |
| 14 | star_rating | 0–5 | P; A may set to 0 | A (band ordering), human review | Usefulness of this contact to us in this segment, today — a property of the contact, not of any one campaign. Question and procedure defined in `spar-methodology.md` (P section) and `spar-P-profile.md` §4.13 — segment file's `rating_rubric` governs where present, otherwise role-play as the campaign's management. A value of 0 means "excluded — not a campaign target." When star_rating is set to 0, date_excluded must also be set. The date_excluded field records when the determination was made; p_note (or, for an A-authored exclusion, the approach YAML's a_note) records the reason. A star_rating of 0 is distinct from 1: a 1-star contact is low-priority but targetable; a 0-star contact is excluded from the pipeline entirely. |

Columns 13–14 are empty during S and populated by P. Empty columns are expected; not every contact reaches every phase. The campaign-bound A and R outputs are documented with the approach YAML schema in `spar-A-approach.md`, not here.

## Phase notes vs full artefacts

| Phase | Full artefact | One-line note |
|---|---|---|
| S | Roster row (this is S's primary output) | roster `s_note`: why this person was included |
| P | Profile document (`profiles/{stem}.md` with YAML front matter) | roster `p_note`: one-line relevance summary and routing for A |
| A | Approach file (`{stem}.yaml`) | approach YAML `a_note` root key: angle and outcome summary for R |
| R | Strategy revision notes (`strategy-revision-[band].md`) | approach YAML `r_note` root key: per-contact observation from the human reviewer |

A phase note should answer: "what does the next phase need to know about this contact from my phase, in one line?" If the observation requires more than a short sentence, it belongs in the full artefact, not in the note. The S and P notes live in the roster; the A and R notes live in the approach YAML, beside the messages they summarise.

## Artefact retention

The profile document is the only record of *why* a contact was excluded or replaced: why they are not a campaign target, or why a different person now holds the role. The roster's `date_excluded` carries *when* the determination was made; the *why* lives only in the profile. Preserving the profile preserves that reasoning for a future sweep that rediscovers the same name, which would otherwise repeat the evaluation. Any preservation that keeps the reasoning reachable from the contact's name serves this purpose.

The same applies when a contact is replaced (e.g. a new person takes over the role): the old contact's profile should be kept. It documents who held the role before, what was found during profiling, and why outreach did not proceed. The replacement contact's profile is a separate file.

Old-slug duplicates — where the same content exists under two filenames due to a rename or slug normalisation — may be deleted. The test is whether the content is reachable from any current roster row's `stem` field. If it is, the other copy is redundant. If neither copy is reachable, the content is an orphan and should be linked to a roster row or investigated, not deleted.

## Campaign-specific columns

Campaigns may append columns after column 14. The campaign plan defines them. Common additions include:

- **postcode** or **location** — for geographic filtering
- **type** — contact category within a segment (e.g. "strategic", "corporate", "community")
- **source_url** — the specific page that justified inclusion

Each roster fact has one canonical column. If a campaign needs a field that serves the same purpose as a core column, use the core column rather than add a parallel one under a different name.

## Quality checklist

These assertions apply to the core columns. Campaign-specific checks are defined by the campaign plan.

1. Every row has a non-empty `contact_name` that is not a placeholder, or has a blank `contact_name` that P §4.1 will resolve (organisation identified, person not yet found).
2. Every row has the expected number of tab-separated fields.
3. No two rows share the same (`contact_name`, `organisation`) pair (case-insensitive).
4. Every row has at least one of email, `linkedin_url`, or `facebook_url`.
5. Every row has a `sweep_iteration` value.
6. Every row with `star_rating = 0` has a non-empty `date_excluded`.
7. Every row has a non-empty `stem`.
8. No two rows share the same `stem` (it is the primary key of the segment roster).
9. The roster file must contain a `stem` column header. A roster lacking it is rejected by the state machine (`spar-state.tcl`) at load time with a schema error. This is a hard failure, not a warning.

## Relationship to other documents

This document defines the roster schema. The operational procedures for populating it are:

- **SPAR-S** (`spar-S-search.md`) — populates columns 1–12 (including `stem` at discovery)
- **SPAR-P** (`spar-P-profile.md`) — populates columns 13–14, corrects columns 3–8 and 11; creates `profiles/{stem}.md` using the pre-existing `stem`
- **SPAR-A** (`spar-A-approach.md`) — creates `approach/{stem}.yaml` using the pre-existing `stem`, writing `response_likelihood`, `a_note`, and the messages into it; does not write to the roster
- **R** (human, no procedure document) — writes the `r_note` root key into `approach/{stem}.yaml`; does not write to the roster
- **spar-state.tcl** — reads `stem` from the roster and checks for the presence of `profiles/{stem}.md` and `approach/{stem}.yaml` on disk to classify contact state; never writes to the roster

SPAR-S §4 currently contains a roster format definition that predates this document. When SPAR-S is next revised, §4 should reference this document rather than defining the format inline.
