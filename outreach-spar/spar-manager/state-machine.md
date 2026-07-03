# SPAR Campaign State Machine

This document defines the file-based state machine that backs the SPAR Manager GUI. Both the **progress table** and the **transition manager** are derived views of the same underlying state — they are not separate scanning systems.

The implementation target is `spar-state.tcl`, a pure read-only library sourced by both `wish` (GUI) and `tclsh` (CLI).

## Architecture: two separate concerns

**State extraction** — reads filesystem and TSV, returns the current state of a contact. Pure, side-effect free. Called once per contact to build the campaign snapshot.

**Transition registry** — a data table mapping each state to the set of valid transitions. Consulted to enumerate eligible contacts per transition type, and to decide which dispatch action to invoke.

**Dispatch** — the proc or batch script that executes a transition. Called by the GUI when the user triggers a transition. Not part of `spar-state.tcl`.

### Design principle: independent deployability

Each state classification and each transition dispatch is independently deployable. Undefined parts produce zero results, not errors — they do not propagate failures to the rest of the system.

**State machine:** classifies contacts from whatever information is present in the filesystem and TSV. If a state's classification condition is not yet defined (e.g., PROFILE_STALE), the state machine never assigns that state — contacts that would have been in it remain in the previous defined state instead. T3/T4 then see zero tasks. That is correct behavior: the rest of the state machine continues working.

**Transition dispatch:** independently incomplete. A contact can be eligible (state machine says "dispatchable") while the dispatch for that transition is a stub returning an error or is not yet written. These are distinct reasons a transition cannot proceed:

- **Not eligible** — contact not in the required state. State machine decides this; contact does not appear as "dispatchable".
- **State undefined** — the state exists in the registry but its classification condition is not yet implemented. No contacts reach that state; the transition sees zero tasks.
- **Dispatch unavailable** — contact is eligible, but the dispatch is missing or incomplete. The transition manager shows the contact as dispatchable; the play button is disabled with a reason.

The transition table carries a `dispatch_status` per transition type. The state machine never reads this field.

---

## Design by Contract: pre/post validation around AI calls

Every AI invocation is wrapped in a **pre/post validation pair**, like a car-rental damage check: document the state before handing the keys over, document the state on return, attribute any new damage to the renter.

### The principle

Before dispatch launches a Claude session that mutates project state (roster TSV, profile files, approach files), the orchestration code runs the relevant validation. If validation fails, the AI call does not happen — the inputs were already broken, so no agent can be blamed and none should be charged tokens to work on bad data.

After the AI session returns, the *same* validation runs again. Any new failure is the agent's fault. The orchestrator can then resume the agent (`claude --resume`) with a specific message: "you broke X, fix it" — the agent cannot deny responsibility because the pre-check passed.

This is a pre/post-condition contract in the Design by Contract sense (Meyer, Eiffel). The contract holds an invariant: project state remains valid across each AI invocation. The orchestration layer enforces the contract; the validation library (`spar-state.tcl`) defines what "valid" means.

### Coding standard: `DbC-Pre` / `DbC-Post` markers

Every AI invocation site in the orchestration code carries a paired comment marker:

```tcl
# DbC-Pre: validate roster integrity before P-phase dispatch
set issues [spar::validate_roster $contacts]
if {[llength $issues] > 0} { ... refuse to dispatch ... }

# ... build prompt, launch claude session ...

# DbC-Post: re-validate after agent returns; agent-introduced issues blame the agent
set issues [spar::validate_roster [spar::classify_segment $segment_dir]]
if {[llength $issues] > 0} { ... resume agent with the diff ... }
```

**Rules:**

1. `DbC-Pre` and `DbC-Post` always appear in pairs. A `DbC-Pre` without a matching `DbC-Post` (or vice versa) is a defect — `grep -c DbC-Pre` and `grep -c DbC-Post` should return equal counts in the orchestration code.
2. The pair count equals the number of AI invocation sites, **not** the number of validation checks. A single `validate_campaign` call may run 10+ checks; that is one pre/post pair, not ten.
3. Markers live in **orchestration logic** (dispatch scripts, harness scripts), not in validation procs. The validation library does not know whether it is being called pre or post.
4. The two halves of a pair must call equivalent validation. Adding a check to the pre side without adding it to the post side breaks the contract — agent regressions slip through silently.
5. Failure handling differs: pre-failure refuses to start; post-failure resumes the agent with the diff for correction (see `spar::Harness` subclasses' `validate_and_correct` method, implemented by `spar::ApproachHarness` in `spar-a-harness.tcl` and `spar::ProfileHarness` in `spar-p-harness.tcl`).

### Where pairs live

| AI call | Orchestration site | Pre-check | Post-check |
|---|---|---|---|
| P-phase profile generation | `spar-p-harness.tcl` | roster row well-formed (dispatcher-enforced) | `sanitise_roster_email` + `ProfileHarness::validate_and_correct` (`validate_profile` + resume-to-fix) |
| A-phase author draft | `spar-a-harness.tcl` author section | meta.env + roster row complete | draft markers extractable |
| A-phase challenger spar | `spar-a-harness.tcl` spar loop | profile + draft accessible | verdict marker extractable |
| A-phase author revision | `spar-a-harness.tcl` rev loop | challenger feedback present | draft + rationale markers extractable |
| A-phase assembly | `spar-a-harness.tcl` assembly | all logs present | `ApproachHarness::validate_and_correct` (`validate_approach` + resume-to-fix) |

Missing or unpaired markers should be tracked as data-integrity issues under #4.

---

## States

A contact's state is inferred from the presence and content of files in the segment directory and from fields in its roster TSV row. States are mutually exclusive and ordered.

| State | Condition |
|-------|-----------|
| `EXCLUDED` | Roster: `date_excluded` non-empty |
| `DISCOVERED` | Valid (not excluded), neither `profiles/{stem}.md` nor `approach/{stem}.yaml` exists. Blank `contact_name` is permitted — P §4.1 resolves it before the rest of profiling |
| `PROFILED` | Valid, file `profiles/{stem}.md` exists, not stale |
| `PROFILE_STALE` | Valid, profile is missing-but-needed (an `approach/{stem}.yaml` references it) OR profile exists with snapshot diverging from the roster — see §Staleness |
| `APPROACHED` | Profiled (fresh), file `approach/{stem}.yaml` exists, no final-round message with `actioned_date` set, profile_hash either matches or is absent |
| `APPROACH_STALE` | Profiled (fresh), `approach/{stem}.yaml` exists with a `profile_hash` that diverges from the current profile bytes (#63). T4 re-runs A. Routed to APPROACHED-equivalent only — SENT/REPLIED supersede so engaged contacts are never re-approached on hash mismatch alone |
| `SENT` | `approach/{stem}.yaml` exists, final round has at least one message with `actioned_date` non-null |
| `REPLIED` | `SENT`, and final round has a message with `replied_date` non-null, or a reply with `direction: received` |

Evaluation order: `EXCLUDED` is checked first. A contact that is `EXCLUDED` is never checked for any other state. States 2–7 are evaluated in order; the first match wins.

### Reassignment is a file move

Because the filesystem is the sole state — no index, no database, no `segment` field inside any roster row, profile, or approach file — a contact is reassigned between segments by moving its files: the `roster.tsv` row, `profiles/{stem}.md`, and `approach/{stem}.yaml` relocated into the destination segment's directory. There is nothing else to rewrite. The contact's pipeline state is re-derived from which of those files the destination now holds, so a DISCOVERED contact moves one file (the roster row) and a SENT contact moves all three; only the files that exist need to move.

The one constraint: a stem is unique within a segment, not globally, so a move checks that the destination does not already hold that stem (`classify_segment`'s `roster_duplicate_stem` is the post-move guard).

### Secondary properties

These are orthogonal to primary state. They filter eligibility for specific transitions and drive the channel-level columns in the progress table.

| Property | Condition |
|----------|-----------|
| `star≥3` | Roster: `star_rating` field parses to ≥ 3 |
| `has_email` | Roster: `email` field contains `@` |
| `has_linkedin` | Roster: `linkedin_url` non-empty |
| `has_facebook` | Roster: `facebook_url` non-empty |
| `has_phone_only` | Roster: `phone` non-empty AND no email, LinkedIn, or Facebook |
| `in_scope` | Roster contains a non-empty field for at least one channel named in the campaign's `primary_channel` / `secondary_channel` / `tertiary_channel` slots |
| `secondary_ready` | Campaign has `secondary_channel`; the approach file's final round contains a sent message for `primary_channel` (`actioned_date` non-null) with `actioned_date` ≥ `secondary_channel.wait_days` days ago; the `wait_condition` holds (e.g. `no_reply` requires `replied_date` null); the final round contains a pending message for `secondary_channel.channel` (`actioned_date` null) |
| `tertiary_ready` | Same as `secondary_ready`, one slot further along — gated on the secondary message rather than the primary |

### Channel properties of the approach (for APPROACHED/SENT contacts)

The approach YAML's final round can contain multiple messages across channels (e.g., one LinkedIn, one email, one phone), but **at most one `channel: email` message** — enforced by `validate_approach` (`too_many_final_emails`). Sequential email follow-ups belong in subsequent rounds; additional recipients belong in `cc`/`bcc`. These messages determine T6 and T8 eligibility.

| Property | Condition |
|----------|-----------|
| `email_sent` | Final round: message with `channel: email` and `actioned_date` non-null |
| `linkedin_sent` | Final round: message with `channel: linkedin` and `actioned_date` non-null |
| `email_replied` | Final round: message with `replied_date` non-null, or reply with `direction: received` |

### Staleness

`PROFILE_STALE` is raised in two situations:

1. **Snapshot divergence.** The profile's front-matter `dependent_data` snapshot diverges from the current roster row. The profile document captures, at generation time, the roster fields whose subsequent change should invalidate P's assessment; comparing the snapshot against the live roster row is the staleness test.
2. **Approach references a missing profile.** An `approach/{stem}.yaml` exists but the corresponding `profiles/{stem}.md` has been deleted. This is the missing-profile half of #63: re-profile is required (T3) before the approach can be re-considered. After T3 writes a fresh profile, the approach's stored `profile_hash` will mismatch the new bytes and the contact lands in `APPROACH_STALE` for T4.

**Snapshotted fields and divergence rules** (full spec in `spar-P-profile.md` §5.3):

- `contact_name`, `organisation`, `role` — any difference is staleness.
- `date_excluded` — **asymmetric**. Stale iff snapshot holds a date and current value is empty (contact was re-validated after exclusion). The reverse (empty → date) is not staleness — EXCLUDED state supersedes.

A profile missing its front matter, or with unparseable front matter, is classified as `PROFILED` at the file-existence level but `validate_profile` emits an error; it is not marked `PROFILE_STALE`. Staleness is about roster-vs-snapshot divergence (or missing-profile-with-approach), not file integrity.

`APPROACH_STALE` is raised when the approach's stored `profile_hash` diverges from the current profile file's sha256 (#63). The hash is recorded by the A harness at generation time and verified by `classify_contact`. Approaches without `profile_hash` (legacy or manually authored) are classified `APPROACHED` and never raise `APPROACH_STALE` — without a stored hash, the state machine cannot prove staleness. Once such an approach is re-run through A, the new file carries a hash and re-enters the staleness loop.

---

## Schema validation

`classify_segment` validates the roster schema before classifying any contacts. If the loaded roster lacks a `stem` column, `classify_segment` returns an error and halts — it does not silently produce wrong results.

```
Error: roster missing required column 'stem' — run schema migration before using spar-state.tcl
```

This is a hard failure, not a warning. Contact state is determined by file presence on disk (`profiles/{stem}.md`, `approach/{stem}.yaml`); without `stem` those paths cannot be constructed.

---

## Core function signature

Classification lives on `spar::State`, a TclOO class whose lifetime matches a unit of work. Each top-level entry point (CampaignModel, the CLI scripts, the harnesses) constructs one and threads it through to consumers. Per-instance method calls (rather than free procs) host the per-instance approach-summary cache that issue #84 lands.

```tcl
# classify_contact -- classify one contact's state.
#
# roster_row   dict with TSV fields (stem, contact_name, date_excluded,
#              star_rating, email, linkedin_url, facebook_url, phone, ...)
#              stem is required; classify_segment validates its presence
#              before calling this method.
# segment_dir  absolute path to the segment directory
#
# Returns a dict:
#   state         one of: EXCLUDED DISCOVERED PROFILED PROFILE_STALE
#                         APPROACHED APPROACH_STALE SENT REPLIED
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
oo::define spar::State method classify_contact {roster_row segment_dir} { ... }
```

A second method aggregates across all contacts in a segment:

```tcl
# classify_segment -- load roster and classify all contacts.
#
# Returns a list of dicts, one per roster row, each being the result of
# classify_contact plus the original roster_row.
#
oo::define spar::State method classify_segment {segment_dir} { ... }
```

---

## Progress table derivation

The progress table columns are counts derived from running `classify_segment` across all active segments and grouping by state and secondary properties.

| Column | What it counts | Denominator | Filter |
|--------|----------------|-------------|--------|
| Valid | not EXCLUDED | total roster rows | — |
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

T1–T4 are the cheap (no-parse) transitions; T5 is reserved for a future cheap addition; T6–T8 require an approach-YAML parse to evaluate eligibility. The split is exploited by the GUI loader (#82) to surface cheap rows before the parse pass completes.

| # | Label | Eligible contacts | Dispatch | Dispatch status |
|---|-------|-------------------|----------|-----------------|
| T1 | Sweep → Profile | state = DISCOVERED | `spar-transition.tcl <campaign.yaml> T1` (runs §4.1 first if `contact_name` is blank, else §4.2+) | available |
| T2 | Profile → Approach | state = PROFILED, star≥3 | `spar-transition.tcl <campaign.yaml> T2` | available |
| T3 | Stale → Re-profile | state = PROFILE_STALE | `spar-transition.tcl <campaign.yaml> T3` | available |
| T4 | Re-profile → Re-approach | state = APPROACH_STALE (profile_hash mismatch, #63) | `spar-transition.tcl <campaign.yaml> T4` | available |
| T6 | Approach → Send | state = APPROACHED or SENT, primary_channel = email, has_email, not email_sent | `spar-transition.tcl <campaign.yaml> T6` (AWS SES, serial with --delay) | available |
| T7 | Send → Reply | email_sent, not email_replied | `spar-transition.tcl <campaign.yaml> T7` (mailroom reply-check, appends replies to approach YAML) | available |
| T8 | LinkedIn → Email follow-up | linkedin_sent, not email_sent | LinkedIn checker | not-implemented |
| T9 | Secondary follow-up | `secondary_ready` | render script + manual marker | manual |
| T10 | Tertiary follow-up | `tertiary_ready` | render script + manual marker | manual |

Dispatch statuses:
- **available** — dispatch implemented and operational
- **manual** — the dispatch is not automated by design. The UI renders the script or content and exposes a "mark actioned" button that writes `actioned_date` on the message. Distinct from `not-implemented` (which means "should be automated but isn't yet")
- **not-implemented** — dispatch not yet written; UI shows the task list but disables the play button with a tooltip explaining why
- **blocked** — dispatch exists in principle but depends on a feature (e.g., PROFILE_STALE detection) that is not yet defined; treated as not-implemented until unblocked
- **n/a** — monitoring transition; no dispatch action exists by design

**T4 note:** Resolved as of #63. The approach records `profile_hash: sha256:<hex>` at generation time; `classify_contact` re-hashes the profile file and assigns `APPROACH_STALE` on mismatch. T4 picks those up and re-runs A. SENT/REPLIED supersede `APPROACH_STALE` so already-engaged contacts are never re-approached on hash mismatch alone.

### Task states per contact in the transition manager

Each contact in a transition has one of:
- `dispatchable` — all preconditions met, can be dispatched now
- `awaiting` — a self-resolving external dependency is outstanding (a clock or a third party); becomes `dispatchable` on its own, with a human-readable reason
- `blocked` — a data defect stops the row; an operator must fix it before it can move, with a human-readable reason
- `done` — transition already completed (shown when "Show completed" is enabled)

`blocked` reasons name a defect the operator must repair:
- T6: contact in state APPROACHED but no email address → "No email address"
- any parse-TID: approach YAML fails structural validation → "invalid_approach_yaml: …"

`awaiting` reasons name the dependency that will clear itself:
- T8: LinkedIn message sent N days ago, waiting for acceptance → "LinkedIn request sent N days ago, waiting until day 5"

---

## State diagram

```
  DISCOVERED ──T1──▶ PROFILED ──T2──▶ APPROACHED ──T6──▶ SENT ──T7──▶ REPLIED
                         │                  │
                         ▼                  ▼
                   PROFILE_STALE       APPROACH_STALE ──T4──▶ APPROACHED (re-approached, #63)
                       │
                       ▼
                   T3 ──▶ PROFILED (re-written; downstream APPROACH_STALE follows
                                    via profile_hash mismatch on the next sweep)

  EXCLUDED — terminal; reached as an in-process outcome of S (sweep), P (profile),
             or A (approach) writing `date_excluded` on the roster row, per the rules
             in spar-S-search.md, spar-P-profile.md §§4.1/4.2/4.13/4.15, and
             spar-A-approach.md §4.0 step 2. There is no operator-initiated arrow.
             T7, T8, detect_duplicates skip EXCLUDED. T2 cannot reach EXCLUDED
             because its gate requires PROFILED.

  T8 — LinkedIn→Email cross-message transition within APPROACHED/SENT (same primary state).
  T9, T10 — secondary/tertiary follow-ups (documented but not wired in transition_eligible).
```

---

## Warnings catalog and cross-check with transition gates

The state machine has two classes of "something is wrong" signal: **transition gates** that block a T from firing until a precondition holds, and **warnings/errors** from validator procs that surface on every `spar-progress` run. The two classes should be aligned: anything severe enough to be a warning should either (a) correspond to a gate that prevents the trouble, or (b) be flagging a condition a gate cannot reach.

This section inventories both, and cross-checks them so misalignments surface.

### Transition gates (formal)

Each T has a state predicate plus zero or more secondary predicates that must all hold for `task_state: dispatchable`. Where the code takes a different branch (`task_state: awaiting` for a self-resolving dependency, `task_state: blocked` for a defect, each carrying a reason), that branch is noted. `A(path)` = `_approach_validation_error(path) == ""` (approach YAML validates).

| T   | State                | Secondary predicates (all, for dispatchable)            | Awaiting / blocked branch                                      | Source            |
|-----|----------------------|---------------------------------------------------------|----------------------------------------------------------------|-------------------|
| T1  | DISCOVERED           | —                                                       | —                                                              | spar-state.tcl:448 |
| T2  | PROFILED             | star ≥ 3                                                | —                                                              | spar-state.tcl:456 |
| T3  | PROFILE_STALE        | —                                                       | —                                                              | transitions/profile.tcl |
| T4  | APPROACH_STALE       | approach-dispatch gate (min_star, in_scope_channel, skip_excluded — SSOT with T2) | —                                  | transitions/approach.tcl |
| T6  | APPROACHED ∨ SENT    | primary_channel = email ∧ has_email ∧ ¬email_sent ∧ A(approach_path) [†] | ¬has_email: "No email address". ¬A: "invalid_approach_yaml". primary_channel ≠ email: row is omitted entirely | spar-state.tcl:464 |
| T7  | any ≠ EXCLUDED       | email_sent ∧ ¬email_replied ∧ A(approach_path)          | A invalid → "invalid_approach_yaml". Dispatchable rows dispatch through spar::r::run (mailroom reply-check) | spar-state.tcl:487 |
| T8  | any ≠ EXCLUDED       | linkedin_sent ∧ ¬email_sent ∧ A(approach_path)          | always awaiting: awaiting acceptance                           | spar-state.tcl:526 |
| T9  | APPROACHED ∨ SENT    | `secondary_ready` ∧ A(approach_path)                    | A invalid → "invalid_approach_yaml". Waiting → "waiting until day N (currently day M since preceding send)". Primary unsent / no secondary slot → row omitted | spar-state.tcl:T9 branch |
| T10 | APPROACHED ∨ SENT    | `tertiary_ready` ∧ A(approach_path)                     | same shape as T9, gated on secondary's actioned_date           | spar-state.tcl:T10 branch |

[†] T6's `primary_channel = email` gate is an interim measure (issue #49). The correct long-term rule routes each unsent final-round message to T6, T8, T9, or T10 based on its slot in the primary/secondary/tertiary structure — not on channel alone. Until per-message routing is implemented, T6 conservatively refuses campaigns whose primary channel is not email, even when they carry an unsent email for the secondary/tertiary slot.

**Conditions no T-gate checks** (relevant for the cross-check below):

- `has_email ∨ has_linkedin ∨ has_facebook` — unchecked from DISCOVERED through SENT. A PROFILED star≥3 contact with zero channels passes T2 and reaches A. A's spec §4.2 line 63 tells A to "flag for human resolution", but the state machine itself does not prevent A-dispatch.
- `contact_name` quality — T1 has no placeholder check. A DISCOVERED row with `contact_name="Unknown"` dispatches P.
- `validate_profile` passing — T2 asserts PROFILED by file existence, not by profile-YAML validity.

### Warnings catalog

Grouped by validator proc. All line numbers are in `spar-state.tcl`.

#### `validate_roster` (per-segment roster quality)

| Code                            | Sev     | Trigger                                               | Skipped states      | Line |
|---------------------------------|---------|-------------------------------------------------------|---------------------|------|
| roster_empty_stem               | error   | `stem == ""`                                          | —                   | 1569 |
| roster_duplicate_stem           | error   | stem repeats within segment                           | —                   | 1580 |
| roster_extra_fields             | warning | TSV row has extra columns                             | —                   | 1559 |
| roster_placeholder_name         | warning | contact_name empty or in {unknown,n/a,tbd,placeholder}| EXCLUDED            | 1604 |
| roster_duplicate_name_org       | error   | (name,org) pair repeats in segment (case_1, issue #5) | EXCLUDED            | 1614 |
| roster_shared_inbox_collision   | error   | same email at same org, different names (case_2)      | EXCLUDED            | —    |
| roster_personal_email_reused    | warning | same email, same name, different orgs (case_3)        | EXCLUDED            | —    |
| roster_no_channel               | warning | ¬has_email ∧ ¬has_linkedin ∧ ¬has_facebook ∧ phone="" | EXCLUDED            | 1626 |
| roster_no_sweep_iteration       | warning | sweep_iteration empty                                 | EXCLUDED            | 1636 |
| roster_zero_star_no_invalid     | warning | star=0 ∧ date_excluded empty                          | EXCLUDED            | 1658 |

#### `validate_campaign` (cross-file campaign checks)

| Code                    | Sev     | Trigger                                    | Skipped states      | Line |
|-------------------------|---------|--------------------------------------------|---------------------|------|
| merged_contact_name     | warning | contact_name contains ` & `                | EXCLUDED            | 1419 |
| masked_email            | error   | roster email contains `*`                  | EXCLUDED            | 1429 |
| orphan_profile          | warning | profile file stem not in roster            | —                   | 1488 |
| orphan_approach         | warning | approach file stem not in roster           | —                   | 1510 |

#### `validate_approach` (per approach YAML, only when file exists)

Codes: `invalid_yaml`, `unknown_key_<level>`, `wrong_level`, `missing_decisions`, `missing_rounds`, `no_final_round`, `draft_missing_number`, `review_missing_number`, `email_missing_content`, `placeholder_to`, `email_desync`, `profile_hash_mismatch`, `profile_hash_misplaced`. All errors except the `*_missing_number`, `email_missing_content`, `email_desync` warnings. `profile_hash_mismatch` (issue #63) fires when the approach's stored hash differs from the current profile file's sha256 — the profile was rebuilt or edited after the approach was drafted and the approach must be regenerated. `profile_hash_misplaced` fires when `profile_hash` is set but is not the first line of the file; the position discipline reserves a fast-classify path that can read just line 1 to detect staleness without parsing the YAML.

#### `validate_profile` (per profile file, only when file exists)

Codes: `invalid_front_matter`, `unknown_key_<level>`, `wrong_level`, `missing_<key>` (×4 required root keys), `invalid_yield`, `invalid_star_rating`, `engagement_leak` (warmth, prior-correspondence, or angle content in the profile — I1), `profile_unreachable_without_exclusion`, `stale_<field>` (×3 warnings), `stale_date_excluded` (warning).

#### `detect_duplicates` (cross-segment; skips EXCLUDED)

| Code              | Sev     | Trigger                                                          |
|-------------------|---------|------------------------------------------------------------------|
| duplicate_to      | warning | same to-address in ≥2 approach files                             |
| duplicate_name    | warning | same normalised name in ≥2 segments                              |
| duplicate_email   | warning | same roster email in ≥2 segments                                 |
| identical_subject | warning | same subject line in ≥2 unsent approach files                    |

### Cross-check: warnings vs downstream gates

Categories (applied in the rightmost column):

- **REAL** — catches a lifecycle violation no T-gate catches. Keep.
- **MISALIGNED** — fires in states where the condition is pending work, not trouble. Either narrow the skip list, or move the check into a downstream T-gate.
- **OBSOLETE** — superseded by later spec changes. Delete.
- **GAP** — condition is genuine but the check belongs in a T-gate, not a post-hoc warning. Move.
- **AUDIT / WORK-HYGIENE / SCHEMA-DRIFT** — operator-signal, not transition-trouble. Keep at warning severity.
- **TROUBLE** — would cause a bad outgoing action if ignored. Keep or turn into a T-gate block.
- **HARD** — error severity; halts.
- **REDUNDANT** — another gate catches the same condition. Safe to delete but harmless.

| Code                            | States where it currently fires         | Catching T-gate                 | Category         |
|---------------------------------|-----------------------------------------|---------------------------------|------------------|
| roster_empty_stem               | all                                     | schema pre-check (column-level) | HARD             |
| roster_duplicate_stem           | all                                     | —                               | HARD             |
| roster_extra_fields             | all                                     | —                               | SCHEMA-DRIFT     |
| roster_placeholder_name         | DISCOVERED → REPLIED                    | T1 does not gate on name        | GAP              |
| roster_duplicate_name_org       | DISCOVERED → REPLIED                    | P-harness validate_and_correct  | TROUBLE (case_1) |
| roster_shared_inbox_collision   | DISCOVERED → REPLIED                    | P-harness validate_and_correct  | TROUBLE (case_2) |
| roster_personal_email_reused    | DISCOVERED → REPLIED                    | —                               | AUDIT (case_3)   |
| roster_no_channel               | DISCOVERED → REPLIED                    | no T-gate; P §4.15 now excludes | MISALIGNED       |
| roster_no_sweep_iteration       | DISCOVERED → REPLIED                    | —                               | AUDIT            |
| roster_zero_star_no_invalid     | DISCOVERED → REPLIED                    | n/a                             | OBSOLETE         |
| merged_contact_name             | DISCOVERED → REPLIED                    | —                               | WORK-HYGIENE     |
| masked_email                    | DISCOVERED → REPLIED                    | T6: has_email excludes masked   | REDUNDANT        |
| orphan_profile                  | n/a (file-scan)                         | —                               | AUDIT            |
| orphan_approach                 | n/a (file-scan)                         | —                               | AUDIT            |
| duplicate_to                    | APPROACHED, SENT                        | —                               | TROUBLE          |
| duplicate_email / duplicate_name| all non-EXCLUDED                        | —                               | TROUBLE or AUDIT |
| identical_subject               | APPROACHED (unsent)                     | —                               | WORK-HYGIENE     |

### Known gaps surfaced by this cross-check

1. **`roster_no_channel` is a canary for P's §4.8 rule.** Condition now matches P's DbC-Post (`profile_unreachable_without_exclusion`): no email, LinkedIn, Facebook, or phone. Firing on a non-EXCLUDED row means P's §4.8 was bypassed (legacy profile pre-dating the guard, or guard regression) — profile should be redone or `date_excluded` set.
2. **T2 has no channel gate.** `state==PROFILED ∧ star≥3` is insufficient; a P bug letting a no-channel contact through would reach A. Either add `has_email ∨ has_linkedin ∨ has_facebook` to T2, or rely wholly on P's §4.15. Cleanest: both.
3. **T9, T10 wired in `transition_eligible` (issue #41).** Branches take the full campaign dict as an optional 4th arg and compute `secondary_ready` / `tertiary_ready` per contact using the per-message final-round list returned by `analyse_final_round`. Dispatch status remains `manual` — the UI still has to render a script and surface an "actioned" button; see `dispatch_status` in the transition table.
4. **`roster_zero_star_no_invalid` is obsolete.** spar-P-profile.md §5.4 states star_rating=0 should not appear on the roster (exclusion is carried by `date_excluded` alone). Candidate for deletion.
5. **T1 does not gate on name quality.** A DISCOVERED row with placeholder contact_name passes T1 and dispatches P on "Unknown". Either T1 should gate, or P's §4.1 should accept placeholders as input and resolve them (it does — so the current path works, but the warning is still a useful audit-signal).
6. **T2 does not gate on `validate_profile` passing.** A malformed profile YAML is classified PROFILED and star≥3 can be whatever's in the front matter; T2 would mark it ready even though the profile file is broken. Parallel to T6's A(approach_path) check — missing symmetric P(profile_path) check at T2.

---

## Testing strategy — first task

Tests live in `spar-manager/test/`, one file per module (`test-state.tcl`, `test-validate-approach.tcl`, …). `test/run.tcl` dispatches them in parallel via tpool; `SPAR_TEST_JOBS=1` forces serial.

### Approach

Each test creates a minimal in-memory fixture (no real filesystem writes), calls `classify_contact` with a synthetic roster row and a temporary directory, and asserts the returned dict.

For filesystem-touching tests (profile/approach file detection), use `file tempfile` or a `test/fixtures/` directory with committed minimal files.

### Test cases required before implementing the UI wiring

**1. Primary state classification (no filesystem)**

| Input condition | Expected state |
|-----------------|----------------|
| `date_excluded` set | EXCLUDED |
| Valid, profiles/ absent | DISCOVERED |
| `contact_name` empty, `date_excluded` empty, profiles/ absent | DISCOVERED |
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

For each transition T1–T8, construct a contact in the eligible state and assert it appears in the transition's task list. Construct a contact one step short of eligibility and assert it does not appear (or appears as `awaiting` or `blocked`).

**6. Duplicate detection**

Two contacts in different segments with the same `email` field → assert duplicate email warning generated. Same `To:` in two approach files → assert duplicate recipient warning.

### Golden snapshot test (validation against real campaign data)

Once the unit tests pass, run `classify_segment` against the real campaign data (line-dance, growers-market) and compare the output counts against the known-good values hardcoded in `mock-ui.tcl`. Any divergence indicates a bug in the classifier.

This test requires the campaign data directory to be present. It is marked as an integration test and skipped in CI if the directory is absent.

---

## Reference: existing Python implementation (not a port — a redesign)

**Note (2026-04):** The bin/ Python code referenced below has been removed (v0.1-pre-tcl-migration). This section is retained as design rationale for the Tcl reimplementation.

The progress-scanning and state-detection logic currently lives in `../bin/update-campaign.py`. The Tcl implementation is a **redesign around the state machine model**, not a line-by-line port. The Python code is the reference for what conditions matter; the Tcl design replaces its structure.

Key locations in `../bin/update-campaign.py` and their redesign counterparts:

| Python location | What it does | Redesign in spar-state.tcl |
|----------------|--------------|----------------------------|
| `classify_approach_gaps()` (line 343) | Matches 3+★ contacts to approach files; detects missing/unsent | Folded into `classify_contact` — approach state is per-contact, not a gap analysis |
| `scan_approach_dir()` (line 390) | Scans approach directory for sent/replied/to-address | Replaced by reading the approach YAML once per contact in `classify_contact`; per-segment aggregation in `classify_segment` |
| Segment loop (line 583–696) | Iterates over segments, accumulates 8-tuple of counts | Replaced by `classify_segment` returning a list of contact dicts; progress table columns are projections, computed on demand |
| `build_profile_index()` (via spar_lib) | Builds a dict of all profile files in a directory for fast lookup | **Not used in spar-state.tcl.** Profile presence is determined by checking `profiles/{stem}.md` directly using the `stem` from the roster row; no directory scan is needed. `spar::build_profile_index` remains in spar-lib.tcl as a utility. |
| Duplicate detection (lines 554–668) | Accumulates email/name/subject maps across segments | Becomes a cross-segment pass over the full classified-contacts list |

**What the Python code does not have (new in the redesign):**

- A single `contact_state` function returning a named state. The Python code computes derived boolean flags (`profiled`, `has_email`, `email_sent`, etc.) independently in an ad-hoc loop — there is no explicit state concept.
- Transition eligibility as a derived view of state. The Python `--missing` flag is the closest analogue, but it lists gaps, not transition tasks.
- The T3/T4/T7/T8 transitions have no Python equivalent at all.

**Related Python library:** `../bin/spar_lib.py` — contains `load_roster`, `slugify`, `profile_exists`, `approach_final_round_status`, `match_roster_to_stems`. The Tcl equivalents already exist in `spar-lib.tcl`; `spar-state.tcl` builds on them.

---

## Implementation plan

1. **Write tests first** (per-module `test/test-*.tcl` with fixture-based unit tests)
2. **Implement `spar::classify_contact`** in `spar-state.tcl`
3. **Implement `spar::classify_segment`** — loop + aggregate
4. **Implement duplicate detection procs** (cross-segment email/name/subject checks)
5. **Implement transition eligibility procs** — filter classify_segment output per T1–T8
6. **Run golden snapshot test** against real campaign data
7. **Wire into mock-ui.tcl** — replace hardcoded `$segments` and `$transitions` lists with live calls
