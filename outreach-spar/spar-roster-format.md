# SPAR Roster Format

**Applies to:** all SPAR campaigns. Campaign-specific columns are appended after the core set and documented in the campaign plan, not here.

## File format

One TSV file per segment. TSV, not CSV — roster fields contain quoted speech, URLs, and free-text that cause quoting problems with commas.

Every row must have a `contact_name`. A row without a named person is not a contact. Each S&P iteration updates the same file via the `sweep_iteration` column; do not create separate files per iteration. The file is `segments/{segment}.tsv`, the dotted stem sibling of the segment folder (e.g. `segments/wedding-planner.tsv`; see `spar-campaign-directory.md`).

**Delimiter and line-break conventions:** Tab (`\t`) separates fields; newline (`\n`) separates rows. Neither may appear inside a field value. When a field needs to represent a line break within its content (e.g. a multi-sentence note), use carriage return (`\r`) instead of newline. Standard tools (LibreOffice, Python `csv` with `delimiter='\t'`, pandas) read `\r` inside a field without treating it as a row boundary.

**Programmatic access (interactive sessions):** Edit roster files with `mlr --tsvlite`. The `--tsvlite` flag is the one that matters: plain `--tsv` applies IANA TSV escaping and rewrites an in-field carriage return to the two characters `\r`, which breaks the line-break convention above. `mlr --tsvlite` reads and writes the file literally, so a round trip is byte-identical, and it agrees with the harness's own reader (`spar::load_roster`, which splits on tab and handles no quoting). Install with `brew install miller` on macOS, `apt install miller` on Ubuntu.

Read:

```bash
mlr --tsvlite filter '$email == ""' roster.tsv
```

Update one row in place:

```bash
mlr -I --tsvlite put 'if ($stem == "jane-doe-acme") { $email = "jane@acme.com" }' roster.tsv
```

`-I` edits the file in place and leaves it untouched when the run errors. Every column survives without being named, so there is no column list to forget. A name holding an apostrophe needs no escaping. There is no heredoc and no temp file to get wrong.

Three faults to guard:

- **A tab or newline assigned into a value splits the row.** mlr writes both out literally and a TSV record is one line, so flatten a multi-line value to spaces before assigning it. (First hit: 21 records rejoined from 26 physical lines.)
- **`-I` empties a roster carrying a header and no data rows**, at exit 0, because mlr writes no header when it has no records. Such a file has nothing to update; the guard is to not run an update against one.
- **A ragged row aborts the run**, at exit 1, file untouched. Fix the row, or pass `--allow-ragged-csv-input` when the short row is intended.

For concurrent access (worker scripts), wrap the mlr call with `flock -x <lockfile>`; when a dispatcher provides the canonical lockfile path in the prompt, use that path verbatim rather than inventing a new filename.

**Where mlr is absent,** `sqlite3` in `.mode tabs` is the backup. It is a backup rather than the tool because its `.import` applies CSV quoting rules: a field whose value begins with a double quote swallows the following record, so the row count silently drops. It warns on stderr and exits 0. A ragged row is filled with NULL, also at exit 0. Check both before trusting a result.

Read:

```bash
sqlite3 :memory: <<'EOF'
.mode tabs
.import roster.tsv tbl
SELECT contact_name, email FROM tbl WHERE email = '';
EOF
```

Write:

```bash
sqlite3 :memory: <<'EOF'
.mode tabs
.import roster.tsv tbl
UPDATE tbl SET email='new@example.com' WHERE contact_name='Name';
.headers on
.output /tmp/out.tsv
SELECT * FROM tbl;
EOF
mv /tmp/out.tsv roster.tsv
```

Write `SELECT *` rather than a column list, which silently drops any column the author forgets, and double an apostrophe inside a WHERE clause (`WHERE contact_name='O''Neil'`).

**Harnessed writes are mediated.** A worker running under the spar-manager harness does not write the roster: it declares changes in its own deliverable (the profile front matter's `roster_patch` block and `star_rating`, or the approach file's root `roster_patch`), and the harness validates and applies them (`spar::apply_roster_patch` / `spar::apply_approach_patch`), stamping `roster_patch_applied` back into the deliverable so a replay is inert and a later human roster edit stands. `star_rating`'s authoritative home is the profile front matter; the roster column is a cache the harness syncs. The discipline above is the interactive regime: S sweeps, maintenance sessions, and anything else with no harness to mediate. (A worker defect once wrote one facility's contacts across 249 rows in a single unguarded UPDATE; mediation bounds that class to one row.)

## Core columns

Columns are ordered left-to-right by pipeline stage: identity, contact channels, discovery provenance, validation, then phase handover (S, P). A human scanning a row reads the contact's identity first, then progressively later-stage information. The roster ends at the P phase: it is the segment's campaign-independent population record, so the campaign-bound A and R outputs do not live here (see "Phase handover" below).

### Identity

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 1 | stem | filename stem (mandatory) | S | P, A, state machine | Unique contact ID, set at discovery. Slug form: `firstname-lastname-organisation`. Derives file paths: profile at `segments/{segment}/{stem}.md`, approach at `campaigns/{campaign}/{stem}.yaml`. Must be unique within the segment. Renaming is high-impact (see design note): the stem keys the filesystem artefacts the state machine reads, so a rename has to move the profile and every campaign's approach file to the new path in the same change. |
| 2 | contact_name | text (mandatory) | S | P, A, R | Identity anchor — no row without this |
| 3 | organisation | text | S; P corrects | P, A | Org at discovery time; P updates if stale |
| 4 | role | text | S; P corrects | P, A | Title at discovery time; P updates if stale |

**Design note:** `stem` is set at sweep time (not at profile creation) so that it is a stable primary key throughout the pipeline. Because `stem` exists from the moment a contact enters the roster, SPAR-P and SPAR-A do not write back to the roster to record their artefact names; they create their files at the paths derived from the pre-existing `stem` (`segments/{segment}/{stem}.md` and `campaigns/{campaign}/{stem}.yaml` respectively). Contact state is determined by file existence on disk, not by TSV field values. A rename is therefore a coordinated change across the TSV row, both file paths, and any cross-referencing notes; do it when the alternative is worse (a stem collision is the clearest case), and move all three in the same commit so the state machine sees no break.

### Contact channels

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 5 | phone | text | S; P updates | A | |
| 6 | email | text | S; P updates; A backfills on discovery | A | A may write a verified email found at send time (see `spar-A-approach.md` §4.8) |
| 7–8 | {platform}_url | URL | S; A corrects on discovery | P (fetches it) | Platform profile URL columns, one per platform module (`platforms/{platform}.md` documents its own column, or its absence). A new URL column is a change to this table, not implied by a new module. |

Every row must have at least one of email or a platform URL column populated. Phone alone is insufficient for campaigns that begin with a written introduction.

### Discovery provenance

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 9 | sweep_iteration | integer | S | Human review | Which sweep iteration added this row |
| 10 | discovered_via | text | S; P for new names found during profiling | Human review, future S, discovery-yield count | Referral chain traceable to the original seed source. A row profiling surfaced leads with `profile:{stem}` of the profile that found it (SPAR-P §4.15); that prefix is what tells a P-found row from a swept one |

### Validation

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 11 | date_excluded | ISO date (YYYY-MM-DD) | S, P, or A | S (skips row), A (skips row), human review | Marks contacts that should not be advanced further, without deleting them. The date rather than a flag allows periodic re-checking. Set when the person has left the relevant role entirely (retired, changed industry), when profiling determines the contact is not a campaign target (wrong mechanism, no individual identifiable after exhaustive search, or low relevance), or when approach drafting concludes no viable angle exists. The roster carries the date; the reason lives in the writing agent's note — `s_note` for S-authored exclusions (stale contacts discovered during sweep), `p_note` for P-authored exclusions, and the approach YAML's `a_note` root key for A-authored exclusions. By SSOT, the note records only the cause (the circumstance the exclusion was derived from, e.g. "the platform is email-gated and no email is on file"); the fact that the contact is excluded is asserted once, by `date_excluded` being set. The note must not restate that fact (no "excluded", "unreachable", "no viable channel", nor the exclusion date), since that content already has its home in this column. See §Artefact retention below. |

### Phase handover

The S and P phases each have one note column in the roster. Only that phase writes to it; subsequent phases read it as context before doing their work. Notes are roster-level summaries, not replacements for full artefacts (profile documents, approach files). The A and R phases do not write their campaign-bound output to the roster: `response_likelihood`, `a_note`, and `r_note` are campaign-bound, and a segment's roster is shared across campaigns, so that output lives in the per-contact approach YAML instead (see `spar-methodology.md`, "Campaigns and segments", and `spar-A-approach.md`). The one exception is population-tier contact details: when A discovers a verified email, or a corrected platform URL, at send time, it backfills the roster, the same as P (see `spar-A-approach.md` §4.8). Such a detail is campaign-independent, so the roster is its home, not the approach file.

| # | Field | Type | Written by | Read by | Purpose |
|---|-------|------|------------|---------|---------|
| 12 | s_note | short text | S; P on a row it declares through `rows_new` (SPAR-P §4.15); frozen after discovery | P, A | Why the discovering phase included this person — the source statement, event, or signal that justified the entry. P reads this before profiling to check whether the person matches the rationale. |
| 13 | p_note | short text | P only | A, human review | What P found: the evidence of interest, the recommended angle, any cautions for A. Broader than evidence of interest alone — includes corrections, routing advice, and warnings. |
| 14 | star_rating | 0–5 | P; A may set to 0 | A (band ordering), human review | General value of this contact to us in this segment, today — a property of the contact, not of any one campaign (the campaign-dependent counterpart is `response_likelihood`, on the approach). Question and procedure defined in `spar-methodology.md` (P section) and `spar-P-profile.md` §4.13 — segment file's `rating_rubric` governs where present, otherwise judge general value to us directly, without importing the current campaign's ask. A value of 0 means "excluded — not a campaign target." When star_rating is set to 0, date_excluded must also be set. The date_excluded field records when the determination was made; p_note (or, for an A-authored exclusion, the approach YAML's a_note) records the reason. A star_rating of 0 is distinct from 1: a 1-star contact is low-priority but targetable; a 0-star contact is excluded from the pipeline entirely. |

Columns 13–14 are empty during S and populated by P. Empty columns are expected; not every contact reaches every phase. The campaign-bound A and R outputs are documented with the approach YAML schema in `spar-A-approach.md`, not here.

## Phase notes vs full artefacts

| Phase | Full artefact | One-line note |
|---|---|---|
| S | Roster row (this is S's primary output) | roster `s_note`: why this person was included |
| P | Profile document (`segments/{segment}/{stem}.md` with YAML front matter) | roster `p_note`: one-line relevance summary and routing for A |
| A | Approach file (`{stem}.yaml`) | approach YAML `a_note` root key: angle and outcome summary for R |
| R | Campaign YAML updates (plan-block angle priorities, `prompt_appendices` guidance) | approach YAML `r_note` root key: per-contact observation from the human reviewer |

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
4. Every row has at least one of email or a platform URL.
5. Every row has a `sweep_iteration` value.
6. Every row with `star_rating = 0` has a non-empty `date_excluded`.
7. Every row has a non-empty `stem`.
8. No two rows share the same `stem` (it is the primary key of the segment roster).
9. The roster file must contain a `stem` column header. A roster lacking it is rejected by the state machine (`spar::state`) at load time with a schema error. This is a hard failure, not a warning.

## Relationship to other documents

This document defines the roster schema. The operational procedures for populating it are:

- **SPAR-S** (`spar-S-sweep.md`) — populates columns 1–12 (including `stem` at discovery)
- **SPAR-P** (`spar-P-profile.md`) — populates columns 13–14, corrects columns 3–8 and 11, and appends whole rows (columns 1–12) for members it discovers, declared as `rows_new` and applied by the harness (§4.15); creates `segments/{segment}/{stem}.md` using the pre-existing `stem`
- **SPAR-A** (`spar-A-approach.md`) — creates `campaigns/{campaign}/{stem}.yaml` using the pre-existing `stem`, writing `response_likelihood`, `a_note`, and the messages into it; writes to the roster only to backfill a population-tier contact detail discovered at send time (a verified email, a corrected platform URL; see §4.8)
- **R** (human, no procedure document) — writes the `r_note` root key into the campaign's approach file; does not write to the roster
- **spar::state** — reads `stem` from the roster and checks for the presence of the profile and the campaign's approach file on disk to classify contact state; never writes to the roster
