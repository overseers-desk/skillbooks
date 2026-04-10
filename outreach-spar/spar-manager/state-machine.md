# SPAR Campaign State Machine

This document defines the file-based state machine that backs the SPAR Manager GUI. Both the **progress table** and the **transition manager** are derived views of the same underlying state — they are not separate scanning systems.

The implementation target is `spar-state.tcl`, a pure read-only library sourced by both `wish` (GUI) and `tclsh` (CLI).

## Architecture: two separate concerns

**State extraction** — reads filesystem and TSV, returns the current state of a contact. Pure, side-effect free. Called once per contact to build the campaign snapshot.

**Transition registry** — a data table mapping each state to the set of valid transitions. Consulted to enumerate eligible contacts per transition type, and to decide which dispatch action to invoke.

**Dispatch** — the proc or batch script that executes a transition. Called by the GUI when the user triggers a transition. Not part of `spar-state.tcl`.

### Design principle: independent deployability

Each state classification and each transition dispatch is independently deployable. Undefined parts produce zero results, not errors — they do not propagate failures to the rest of the system.

**State machine:** classifies contacts from whatever information is present in the filesystem and TSV. If a state's classification condition is not yet defined (e.g., PROFILE_STALE), the state machine never assigns that state — contacts that would have been in it remain in the previous defined state instead. T6/T7 then see zero tasks. That is correct behavior: the rest of the state machine continues working.

**Transition dispatch:** independently incomplete. A contact can be eligible (state machine says "ready") while the dispatch for that transition is a stub returning an error or is not yet written. These are distinct reasons a transition cannot proceed:

- **Not eligible** — contact not in the required state. State machine decides this; contact does not appear as "ready".
- **State undefined** — the state exists in the registry but its classification condition is not yet implemented. No contacts reach that state; the transition sees zero tasks.
- **Dispatch unavailable** — contact is eligible, but the dispatch is missing or incomplete. The transition manager shows the contact as ready; the play button is disabled with a reason.

The transition table carries a `dispatch_status` per transition type. The state machine never reads this field.

---

## States

A contact's state is inferred from the presence and content of files in the segment directory and from fields in its roster TSV row. States are mutually exclusive and ordered.

| State | Condition |
|-------|-----------|
| `INVALID` | Roster: `date_found_invalid` non-empty |
| `DISCOVERED` | Valid (not invalid), `profile_stem` roster field empty |
| `PROFILED` | Valid, `profile_stem` non-empty, file `profiles/{profile_stem}.md` exists, not stale |
| `PROFILE_STALE` | Valid, `profile_stem` non-empty, profile file exists, but stale — see §Staleness |
| `APPROACHED` | Profiled, `approach_stem` roster field non-empty, file `approach/{approach_stem}.yaml` exists, no final-round message with `actioned_date` set |
| `SENT` | `approach_stem` non-empty, approach file exists, final round has at least one message with `actioned_date` non-null |
| `REPLIED` | `SENT`, and final round has a message with `replied_date` non-null, or a reply with `direction: received` |

Evaluation order: `INVALID` is checked first. A contact that is `INVALID` is never checked for any other state. States 2–7 are evaluated in order; the first match wins.

### Secondary properties

These are orthogonal to primary state. They filter eligibility for specific transitions and drive the channel-level columns in the progress table.

| Property | Condition |
|----------|-----------|
| `star≥3` | Roster: `star_rating` field parses to ≥ 3 |
| `has_email` | Roster: `email` field contains `@` |
| `has_linkedin` | Roster: `linkedin_url` non-empty |
| `has_facebook` | Roster: `facebook_url` non-empty |
| `has_phone_only` | Roster: `phone` non-empty AND no email, LinkedIn, or Facebook |

### Channel properties of the approach (for APPROACHED/SENT contacts)

The approach YAML's final round can contain multiple messages (e.g., one LinkedIn, one email). These determine T3 and T8 eligibility.

| Property | Condition |
|----------|-----------|
| `email_sent` | Final round: message with `channel: email` and `actioned_date` non-null |
| `linkedin_sent` | Final round: message with `channel: linkedin` and `actioned_date` non-null |
| `email_replied` | Final round: message with `replied_date` non-null, or reply with `direction: received` |

### Staleness

`PROFILE_STALE` condition is not yet formally defined. The mock UI shows it as a manually identified state (e.g., "cross-ref update from another contact"). Defer to a later design decision; for now, treat all profiled contacts as non-stale.

---

## Schema validation

`classify_segment` validates the roster schema before classifying any contacts. If the loaded roster lacks either the `profile_stem` or `approach_stem` column, `classify_segment` returns an error and halts — it does not silently produce wrong results.

```
Error: roster missing required column 'profile_stem' — run schema migration before using spar-state.tcl
```

This is a hard failure, not a warning. A roster without these columns cannot be classified without the legacy filesystem-matching algorithm, which defeats the single-source-of-truth design. The schema migration (backfill) must run once against existing rosters before the state machine can operate.

---

## Core function signature

```tcl
# classify_contact -- classify one contact's state.
#
# roster_row   dict with TSV fields (contact_name, date_found_invalid,
#              star_rating, email, linkedin_url, facebook_url, phone,
#              profile_stem, approach_stem, ...)
#              profile_stem and approach_stem are required; classify_segment
#              validates their presence before calling this proc.
# segment_dir  absolute path to the segment directory
#
# Returns a dict:
#   state         one of: INVALID DISCOVERED PROFILED PROFILE_STALE
#                         APPROACHED SENT REPLIED
#   profile_path  path to profile file, or empty string
#   approach_path path to approach YAML, or empty string
#   star          integer (0 if blank/unparseable)
#   has_email     bool
#   has_linkedin  bool
#   has_facebook  bool
#   has_phone_only bool
#   email_sent    bool  (meaningful only when state is APPROACHED/SENT/REPLIED)
#   linkedin_sent bool
#   email_replied bool
#
proc spar::classify_contact {roster_row segment_dir} { ... }
```

A second proc aggregates across all contacts in a segment:

```tcl
# classify_segment -- load roster and classify all contacts.
#
# Returns a list of dicts, one per valid+named roster row,
# each being the result of classify_contact plus the original roster_row.
#
proc spar::classify_segment {segment_dir} { ... }
```

---

## Progress table derivation

The progress table columns are counts derived from running `classify_segment` across all active segments and grouping by state and secondary properties.

| Column | What it counts | Denominator | Filter |
|--------|----------------|-------------|--------|
| Valid | not INVALID | total roster rows | — |
| Profile | PROFILED or above | Valid | — |
| 3+★ | Valid and star≥3 | Valid | — |
| A/3+★ | APPROACHED or above, star≥3 | 3+★ | — |
| Email | star≥3 and has_email | 3+★ | — |
| A/Eml | APPROACHED+, star≥3, has_email | Email | — |
| LinkedIn | star≥3 and has_linkedin | 3+★ | — |
| Facebook | star≥3 and has_facebook | 3+★ | — |
| Only ☎ | star≥3 and has_phone_only | 3+★ | — |
| ✉ Sent | email_sent true | A/Eml | — |
| ✉ Repl | email_replied true | ✉ Sent | — |

All twelve columns are projections of `classify_segment` output. There is no separate scanning step.

### Duplicate warnings

Derived from the same classified contacts:
- **Duplicate To:** same email address appears in two or more approach files' final-round email messages
- **Duplicate name:** same normalised name appears in two or more segments
- **Duplicate email:** same `email` roster field in two or more segments
- **Identical subject:** same subject line in two or more unsent approach files

---

## Transition manager derivation

The transition manager filters `classify_segment` output by eligibility condition.

| # | Label | Eligible contacts | Dispatch | Dispatch status |
|---|-------|-------------------|----------|-----------------|
| T1 | Sweep → Profile | state = DISCOVERED | spar-p-batch.tcl | available |
| T2 | Profile → Approach | state = PROFILED, star≥3 | spar-a-batch.tcl | available |
| T3 | Approach → Send | state = APPROACHED or SENT, has_email, not email_sent | email send (SES) | not-implemented |
| T4 | Send → Reply | email_sent, not email_replied | none (monitoring only) | n/a |
| T5 | Flag invalid | state = any valid | roster TSV update | not-implemented |
| T6 | Stale → Re-profile | state = PROFILE_STALE | spar-p-batch.tcl | available (zero tasks until PROFILE_STALE defined) |
| T7 | Re-profile → Re-approach | re-PROFILED after stale (see note) | spar-a-batch.tcl | available (zero tasks until PROFILE_STALE defined) |
| T8 | LinkedIn → Email follow-up | linkedin_sent, not email_sent | LinkedIn checker | not-implemented |

Dispatch statuses:
- **available** — dispatch implemented and operational
- **not-implemented** — dispatch not yet written; UI shows the task list but disables the play button with a tooltip explaining why
- **blocked** — dispatch exists in principle but depends on a feature (e.g., PROFILE_STALE detection) that is not yet defined; treated as not-implemented until unblocked
- **n/a** — monitoring transition; no dispatch action exists by design

**T7 note:** "Re-profiled after stale" requires knowing that the profile was updated after the approach was created. Requires comparing file modification times or a staleness marker. Defer until PROFILE_STALE is formally defined.

### Task states per contact in the transition manager

Each contact in a transition has one of:
- `ready` — all preconditions met, can be dispatched now
- `pending` — precondition not yet met (with a human-readable reason)
- `done` — transition already completed (shown when "Show completed" is enabled)

`pending` reasons come from the eligibility gap:
- T3: contact in state APPROACHED but no email address → "No email address"
- T8: LinkedIn message sent N days ago, waiting for acceptance → "LinkedIn request sent N days ago, waiting until day 5"

---

## Testing strategy — first task

Tests live in `spar-manager/test/`. The test runner is a standalone `tclsh` script: `test/run-tests.tcl`.

### Approach

Each test creates a minimal in-memory fixture (no real filesystem writes), calls `classify_contact` with a synthetic roster row and a temporary directory, and asserts the returned dict.

For filesystem-touching tests (profile/approach file detection), use `file tempfile` or a `test/fixtures/` directory with committed minimal files.

### Test cases required before implementing the UI wiring

**1. Primary state classification (no filesystem)**

| Input condition | Expected state |
|-----------------|----------------|
| `date_found_invalid` set | INVALID |
| Valid, profiles/ absent | DISCOVERED |
| Valid, profiles/ exists but no match | DISCOVERED |
| Valid, profile file matches by name+org slug | PROFILED |
| Valid, profile matches by name-prefix only | PROFILED |
| Valid, profile matches by org+initial | PROFILED |

**2. Approach state (approach YAML present)**

| Approach YAML content | Expected state |
|-----------------------|----------------|
| File exists, no final round | APPROACHED |
| Final round, no `actioned_date` | APPROACHED |
| Final round, `actioned_date` set | SENT |
| Final round, `replied_date` set | REPLIED |
| Final round, `replies` with `direction: received` | REPLIED |

**3. Secondary properties**

| Roster field | Expected property |
|--------------|-------------------|
| `email: foo@bar.com` | `has_email true` |
| `email: ` (blank) | `has_email false` |
| `linkedin_url: https://...` | `has_linkedin true` |
| `phone: 0412 000 000`, no email, no linkedin, no facebook | `has_phone_only true` |
| `phone: 0412 000 000`, email present | `has_phone_only false` |

**4. Progress table derivation (classify_segment)**

Use a fixture segment with 5 contacts in known states. Assert that `classify_segment` returns the correct counts for each column. This is a regression test: if classify_contact is correct, the aggregation should be trivial.

**5. Transition eligibility**

For each transition T1–T8, construct a contact in the eligible state and assert it appears in the transition's task list. Construct a contact one step short of eligibility and assert it does not appear (or appears as `pending`).

**6. Duplicate detection**

Two contacts in different segments with the same `email` field → assert duplicate email warning generated. Same `To:` in two approach files → assert duplicate recipient warning.

### Golden snapshot test (validation against real campaign data)

Once the unit tests pass, run `classify_segment` against the real campaign data (line-dance, growers-market) and compare the output counts against the known-good values hardcoded in `mock-ui.tcl`. Any divergence indicates a bug in the classifier.

This test requires the campaign data directory to be present. It is marked as an integration test and skipped in CI if the directory is absent.

---

## Reference: existing Python implementation (not a port — a redesign)

The progress-scanning and state-detection logic currently lives in `../bin/update-campaign.py`. The Tcl implementation is a **redesign around the state machine model**, not a line-by-line port. The Python code is the reference for what conditions matter; the Tcl design replaces its structure.

Key locations in `../bin/update-campaign.py` and their redesign counterparts:

| Python location | What it does | Redesign in spar-state.tcl |
|----------------|--------------|----------------------------|
| `classify_approach_gaps()` (line 343) | Matches 3+★ contacts to approach files; detects missing/unsent | Folded into `classify_contact` — approach state is per-contact, not a gap analysis |
| `scan_approach_dir()` (line 390) | Scans approach directory for sent/replied/to-address | Replaced by reading the approach YAML once per contact in `classify_contact`; per-segment aggregation in `classify_segment` |
| Segment loop (line 583–696) | Iterates over segments, accumulates 8-tuple of counts | Replaced by `classify_segment` returning a list of contact dicts; progress table columns are projections, computed on demand |
| `build_profile_index()` (via spar_lib) | Builds a dict of all profile files in a directory for fast lookup | **Not used in spar-state.tcl.** Profile identity is read directly from `profile_stem` in the roster row; no scan of the profiles directory is needed. `spar::build_profile_index` remains in spar-lib.tcl for other callers (e.g., spar-p-batch) but is not called during state classification. |
| Duplicate detection (lines 554–668) | Accumulates email/name/subject maps across segments | Becomes a cross-segment pass over the full classified-contacts list |

**What the Python code does not have (new in the redesign):**

- A single `contact_state` function returning a named state. The Python code computes derived boolean flags (`profiled`, `has_email`, `email_sent`, etc.) independently in an ad-hoc loop — there is no explicit state concept.
- Transition eligibility as a derived view of state. The Python `--missing` flag is the closest analogue, but it lists gaps, not transition tasks.
- The T4/T6/T7/T8 transitions have no Python equivalent at all.

**Related Python library:** `../bin/spar_lib.py` — contains `load_roster`, `slugify`, `profile_exists`, `approach_final_round_status`, `match_roster_to_approach_stems`. The Tcl equivalents already exist in `spar-lib.tcl`; `spar-state.tcl` builds on them.

---

## Implementation plan

1. **Write tests first** (`test/run-tests.tcl` with fixture-based unit tests)
2. **Implement `spar::classify_contact`** in `spar-state.tcl`
3. **Implement `spar::classify_segment`** — loop + aggregate
4. **Implement duplicate detection procs** (cross-segment email/name/subject checks)
5. **Implement transition eligibility procs** — filter classify_segment output per T1–T8
6. **Run golden snapshot test** against real campaign data
7. **Wire into mock-ui.tcl** — replace hardcoded `$segments` and `$transitions` lists with live calls
