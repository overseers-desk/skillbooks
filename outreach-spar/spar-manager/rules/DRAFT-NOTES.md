# rules/ DRAFT-NOTES — for the wiring round

Drafts land: `approach.rules`, `profile.rules`, `sender.rules`, `version.rules`.
Nothing is loaded or tested this round (the yamlmuster module does not exist
yet). This file records what the wiring round must register, where the DSL
could not reach the legacy behaviour, per-file fidelity doubts, and every
place the two specs contradict the legacy code that `spar-validate.tcl`
actually runs. Where a spec and the legacy code disagree, the drafts follow
the legacy code (per the shift order) and the disagreement is logged in (d).

Legacy = `outreach-spar/spar-manager/spar-validate.tcl` unless noted.

---

## (a) Host predicates to register

Register these on the singleton BEFORE any `load`. Contract:
`{*}$cmdprefix $node $meta`, `meta = {path level context extra}`, returns a
list of partial issue dicts (`{}` = pass); the engine fills
severity/code/path/level from the rule and the predicate may override
severity/code/message per issue.

| predicate name | attach (rule) | wraps legacy | responsibility |
|---|---|---|---|
| `first_line_is_profile_hash` | approach root, `-code profile_hash_misplaced -needs approach_path` | 392-395 emit + 416-423 read | Guard `dict exists $node profile_hash` (384) and `context.approach_path ne ""`. Open the file, read line 1 (utf-8), regexp `^profile_hash:\s*sha256:[0-9a-fA-F]+\s*$`. Emit profile_hash_misplaced when it does not match. |
| `profile_hash_actual` | approach root, `-code profile_hash_mismatch -needs approach_path` | 384-405 | Guard profile_hash present + path non-empty. Parse stored hash: strip `sha256:` via `^sha256:([0-9a-fA-F]+)$`, else use verbatim; lowercase (385-391). Sibling profile path = `[file join [file dirname [file dirname $ap]] profiles <stem>.md]` (396-398). If that file exists, `::sha2::sha256 -hex -file` it, lowercase, compare; on mismatch emit `Approach profile_hash 'sha256:<stored>' does not match profile file (current sha256:<actual>) — re-approach required`. |
| `is_null` | (none — see doubt) | spar-lib.tcl:633-636 | YAML-null test (`"" ~ None null`). See (d)#11: no drafted rule references it; the other predicates call `spar::is_null` directly as a Tcl proc. Listed in design-migration Wave 2a; register if the module wants it available, but it is not load-bearing for any rule here. |
| `linkedin_guard` | approach round, `-when {type final} -code linkedin_note_too_long` | 285-308 | For the final round node, iterate `messages`. For each with `channel eq linkedin` and `spar::is_null [dict getdef $m actioned_date ""]`: li_text = `string trim text` else `string trim body`; li_len = `string length`; li_mode = `dict getdef mode ""`. If li_mode in {invite ""} and li_len > 300 emit linkedin_note_too_long = `LinkedIn invite note is <li_len> chars, limit 300; shorten it, or declare mode: dm if a direct message to a 1st-degree connection is intended`. If `char_count` present, trimmed, non-null, and (`!string is integer -strict` or `!= li_len`) emit (code override) char_count_mismatch = `LinkedIn message char_count recorded <cc>, measured <li_len>`. |
| `placeholder_to` | approach root, `-code placeholder_to` (no -needs) | 320-363 | Run `spar::analyse_final_round $node`; for each addr in `to_addresses` (already final-round + email + non-null; trim, skip empty): if `![regexp {^[^@\s]+@[^@\s]+\.[^@\s]+$} $addr]` emit placeholder_to `Approach file has non-email to: address '<addr>'` and continue; split on first `@`, lowercase; if domain in the reserved-domain list or local in the stub-local list (322-333) emit placeholder_to `Approach to: '<addr>' looks like a placeholder (reserved domain or stub local-part)` and continue; if `context.roster_email` non-empty and contains `@` and `tolower(addr) != tolower(roster_email)` emit (severity+code override) email_desync warning `Approach to: '<addr>' differs from roster email '<roster_email>'`. |
| `engagement_leak` | profile root, `-code engagement_leak -needs raw` | 604-624 | Read `context.raw`. Three case-sensitive `string first pat raw >= 0` patterns (608-617): `## Prior correspondence` / `## Angles` / `Warmth:` with descs `prior-correspondence or warmth section` / `pitch or angles section` / `warmth line`, message `Profile carries a <desc> ('<pat>'). Engagement and pitch content is campaign-bound and must not live in a reusable profile (INVARIANTS.md I1).`. Then three phrases over `string tolower raw` (618-624): `no prior contact` / `no prior correspondence` / `no prior connection`, message `Profile states '<phrase>'. Prior-contact state is campaign-bound and stale on reuse (INVARIANTS.md I1).`. Emit in that order, all code engagement_leak. |
| `version_unstamped` | version root, `-severity warning -needs {declared label} -code version_unstamped` | 766-770 | If `context.declared eq ""` emit `<label> has no version: field — treating as pre-<CURRENT> (unstamped). Stamp it with version: "<CURRENT>".` where CURRENT = `spar::CURRENT_SPEC_VERSION`. |
| `version_unsupported` | version root, `-severity error -needs {declared label} -code version_unsupported` | 771-775 | If `context.declared ne "" && ne CURRENT` emit `<label> declares spec version '<declared>' but this tool supports <CURRENT>.` (guards `ne ""` so it is mutually exclusive with version_unstamped). |

design-migration Wave 2a lists only `first_line_is_profile_hash,
profile_hash_actual, is_null`. That list is incomplete: the drafting needs
`linkedin_guard` and `placeholder_to` (approach), `engagement_leak`
(profile), and `version_unstamped` / `version_unsupported` (version) as
well. See (d)#7.

---

## (b) Where the DSL could not express a legacy check, and the choice made

1. **missing_rounds — two messages + early return.** Legacy (193-203)
   emits `Approach file missing required 'rounds' key` when absent and
   `Approach file has empty 'rounds' array` when the list is empty, then
   `return $issues` (196, 202) in BOTH cases, suppressing every later
   check. A single `require rounds -nonempty` carries one message and
   cannot early-return. **Chose:** `require root rounds -nonempty` with the
   absent-case message. Lost: the empty-array wording, and the suppression
   (see (d)#3). Alternative if fidelity is required: a host predicate that
   emits the right message and the wiring gates downstream rules — not
   drafted because it re-imperative-ises what the plan wanted declarative.

2. **placeholder_to + email_desync — one predicate, not the muster split.**
   design-muster puts the email-shape test under `regexp` and the stub
   lists + desync under `predicate`. Not viable: (i) `to_addresses` comes
   from `analyse_final_round` (final rounds, channel email, non-null `to`),
   which a message-level `regexp message to <re>` cannot scope (it would
   fire on draft rounds, sent messages, and non-email channels, and round
   `type` is a parent-level field a message rule cannot read); (ii) the
   three checks are mutually exclusive via `continue` (341-362), so split
   rules double-emit; (iii) email_desync interpolates the `roster_email`
   context value. **Chose:** one root predicate `placeholder_to`. See (d)#4.

3. **linkedin length + char_count — round-level predicate.** The 300-char
   check reads `text` falling back to `body`, gates on mode in {invite ""},
   and only for final-round unsent linkedin messages; char_count compares a
   recorded count to the measured length. Cross-level (round type + message
   fields) and fallback-tangled. **Chose:** one predicate at round level
   emitting both codes via per-issue override, per design-muster.

4. **profile_hash_misplaced / profile_hash_mismatch — predicates.** File
   reads (line-1 test, sibling-profile sha256) and a two-hash message are
   outside the DSL. **Chose:** two root predicates, `-needs approach_path`.

5. **engagement_leak — predicate over `raw`.** Substring scans of the whole
   profile text (not a front-matter field) with messages interpolating the
   matched pattern/phrase. **Chose:** root predicate reading `context.raw`.

6. **version_unstamped / version_unsupported — predicates.** Messages
   interpolate the per-call `$label` and `$CURRENT_SPEC_VERSION`, neither a
   node field nor a template token. Per the task rule this forces a
   predicate. **Chose:** two root predicates reading `context {declared
   label}`. See (d)#5.

7. **vocab messages + `unknown_key_<level>` code — engine + wrapper, not
   the rules file.** The `vocab` kind emits built-in `unknown_key` /
   `wrong_level`. Two fidelity dependencies the rules file cannot carry:
   (i) the engine's built-in messages must be exactly
   `unknown key '<k>' at <level> — not in canonical vocabulary` and
   `'<k>' at <level> belongs at <found_at>; move it there` (legacy 82-83,
   79-80); (ii) the host wrapper must rename `unknown_key` to
   `unknown_key_<level>` from the issue's `level` field (design-migration
   section 7). The wrong_level `found_at` must be the FIRST-declared owning
   level (legacy `break` over canonical dict order, 74-77); the levels are
   declared in canonical order to preserve this — the engine must resolve
   KeyOwners to the first declaration. See (d)#10.

8. **Absent / blank value handling for value-reading kinds.** Legacy always
   guards value checks with `dict exists` (range/regexp), and smtp_port
   additionally with `ne ""`. The drafts assume `range` (and any
   value-reading kind) SKIPS an absent keypath (existence is `require`'s
   job) and that `smtp_port` needs blank-skipping too. If the engine fires
   these on absent/blank values, invalid_yield / invalid_star_rating /
   smtp_port_non_numeric will over-emit. Engine-contract dependency, stated
   in (d)#9.

---

## (c) Per-file: legacy code → rule kind → message-fidelity doubt

### approach.rules

| legacy code | rule kind | message fidelity |
|---|---|---|
| unknown_key_<level> | vocab (built-in) | Engine built-in text + wrapper rename must match legacy (b#7). |
| wrong_level | vocab (built-in) | Built-in text + first-declared owning level (b#7, d#10). |
| missing_decisions | require | exact (static). |
| missing_rounds | require -nonempty | **DOUBT:** empty-array message lost; absent-case kept (b#1). |
| no_final_round | any | exact (static). **DOUBT:** fires as an extra when rounds absent/empty (d#3). |
| draft_missing_number | require -when {type draft} warning | exact. |
| review_missing_number | require -when {type review} warning | exact. |
| email_missing_content (reply) | require body -when {channel email mode reply} warning | exact. |
| reply_missing_parent_message_id | require {parent message_id} -nonblank | exact. Depends on engine treating a missing intermediate key as blank. |
| email_missing_content (non-reply) | require {subject body} -anyof -when {channel email} -unless {mode reply} warning | exact. Depends on `-anyof` reading the list as alternatives (not a keypath). |
| linkedin_note_too_long | predicate (linkedin_guard) | Built by predicate; interpolates li_len. |
| char_count_mismatch | predicate (linkedin_guard, code override) | Built by predicate; interpolates recorded + measured. |
| too_many_final_emails | atmost | `%n` = measured count; exact. |
| placeholder_to (×2) | predicate (placeholder_to) | Built by predicate; interpolates addr. |
| email_desync | predicate (placeholder_to, severity+code override) | Built by predicate; interpolates addr + roster_email. |
| profile_hash_misplaced | predicate (first_line_is_profile_hash) | Static; exact. |
| profile_hash_mismatch | predicate (profile_hash_actual) | Built by predicate; interpolates two hashes. |

### profile.rules

| legacy code | rule kind | message fidelity |
|---|---|---|
| unknown_key_<level> / wrong_level | vocab (built-in) | as approach (b#7). |
| missing_profile_date/star_rating/yield/dependent_data | require ×4 | `%k` = required key; exact. |
| invalid_yield | range -min 0 -integer | `%v` = value; exact. Assumes skip-on-absent (b#8). |
| engagement_leak (×6) | predicate | Built by predicate. |
| invalid_star_rating | range -min 1 -max 5 -integer | `%v` = value; exact. Assumes skip-on-absent. |

Staying imperative in `validate_profile` (NOT in this file): invalid_front_matter
(×3, 545-576), profile_unreachable_without_exclusion (640-651), stale_*
(653-678). Appended after the yamlmuster issues.

### sender.rules

| legacy code | rule kind | message fidelity |
|---|---|---|
| sender_missing | require | exact. Absence prunes descent = legacy early return. |
| smtp_host_missing | require -nonblank | exact (absent or blank). |
| smtp_user_missing | require -nonblank | exact. |
| smtp_port_non_numeric | range -integer warning | `%v` = value. **DOUBT:** legacy skips empty port via `ne ""`; range must skip blank (b#8, d#9). |

### version.rules

| legacy code | rule kind | message fidelity |
|---|---|---|
| version_unstamped | predicate | Built by predicate; interpolates label + CURRENT. |
| version_unsupported | predicate | Built by predicate; interpolates label + declared + CURRENT. |

---

## (d) Spec-vs-legacy contradictions (legacy wins in the drafts)

1. **One singleton loading all four files vs level-redeclaration errors.**
   design-migration (line 25): "the lazy singleton `spar::_yamlmuster`: ...
   and `load` of every `rules/*.rules` (fixed order list) all happen on
   first `validate_*` call". design-muster (level command): "Redeclaring a
   level errors." and "The level named exactly `root` is the traversal
   entry ... a load that declares rules but no root level fails at compile."
   All four drafts declare `level root` (each with different `-keys`).
   Loading them into ONE instance re-declares `root` and errors. design-
   muster itself assumes multiple instances: "Sender-block and version
   gates are a second instance over the campaign dict"; "Two instances
   coexisting with different rulesets". **Resolution for wiring:** the
   singleton must hold one instance PER document kind (approach / profile /
   sender / version), each loading its own file, not one instance loading
   all four. The `.rules` drafts are correct either way; only the Wave 1
   bootstrap changes. Likely a LEDGER item.

2. **"Rules ordered to mirror legacy emission" vs the fused single walk.**
   design-migration risk 2 (line 110): "Yamlmuster guarantees
   declaration-order evaluation and document-order walk emission; rules
   files are ordered to mirror legacy emission." But legacy emits in TWO
   passes: a full vocab walk over every level (139-182) THEN a structural
   pass (184-406). yamlmuster fires all of a node's rules before descending
   (design-muster walk: "for id in ByLevel(level) ... for {key {mode
   child}} in Levels(level).children"). Declaration order only controls
   order WITHIN a level; it cannot make deep vocab emit before root
   structural. Concrete divergences on the full-issue list:
   - Root structural rules (missing_decisions/rounds, no_final_round,
     placeholder_to, profile_hash_*) emit BEFORE deep vocab issues
     (decisions/round/message/...). Legacy emits them after all vocab.
   - placeholder_to and profile_hash_* (root) emit BEFORE per-round errors
     (linkedin, char_count, reply_missing_parent_message_id, too_many_final,
     which live at round/message level). Legacy emits the per-round errors
     first (219-318) and the email guard rails + hash last (320-406).
   - linkedin_guard and too_many_final (round level) emit BEFORE the
     message-level email rails, because round rules precede message descent.
     Legacy interleaves them per message and computes too_many_final after
     the message loop.
   Impact: the gate (`-severities error -limit 1`) can return a DIFFERENT
   first error than legacy for a document carrying both a deep error and a
   root-level aggregate error (e.g. a message-level unknown_key with
   `decisions` absent → legacy first error = the unknown_key; yamlmuster =
   missing_decisions). Same for a doc with an over-long linkedin note AND a
   placeholder `to` (legacy → linkedin_note_too_long; yamlmuster →
   placeholder_to). This is irreducible in the DSL: the escaping rules are
   root/round aggregates that must fire before descent. The drafts order
   each level's rules to match legacy within the level; the cross-depth
   reordering cannot be closed. **The per-wave old-vs-new diff must treat
   the issue LIST as a multiset (compare by content, not position), and the
   gate's first-error parity should be spot-checked on mixed fixtures.**

3. **missing_rounds early return not reproduced.** Legacy `return $issues`
   at 196 and 202 stops all downstream checks when rounds is absent/empty.
   The DSL has no per-rule stop (only global `-limit`). So on a full run
   with rounds missing/empty, yamlmuster additionally emits no_final_round
   (the `any` fails) and, if profile_hash is set, profile_hash_misplaced /
   _mismatch — issues legacy suppresses. Gate path is unaffected (`-limit 1`
   returns missing_rounds first and unwinds). Add a rounds-absent and a
   rounds-empty fixture to the diff corpus and expect these extras.

4. **regexp assignment for placeholder_to.** design-muster kinds table:
   "`regexp` | `<keypath> <re>` | `placeholder_to`'s email-shape test on
   `to`". Contradicted by legacy: the shape test runs over
   `analyse_final_round`'s `to_addresses` (final-round email only, 334-337)
   inside a `continue` chain, not over every message's `to`. Drafted as
   part of the `placeholder_to` predicate (b#2). If nothing else uses
   `regexp`, that kind has no consumer in this migration.

5. **oneof/require assignment for the version gate.** design-muster:
   "`oneof` | ... | `version_unsupported` (declared version must be in
   {1.0}); paired with `require version -severity warning` for
   `version_unstamped`". Contradicted by the legacy messages, which
   interpolate the per-call `$label` (763-775) that no `-message` template
   token can carry; and design-migration itself passes the facts via
   `-context {declared ... label ...}` (line 70), not as a node dict.
   Drafted as predicates (b#6). Consequence: `version_unsupported` was
   `oneof`'s only named user and `version_unstamped` one of `require`'s;
   with version as predicates, **`oneof` has no surviving consumer in this
   migration** — worth raising against design-muster's "no speculative
   kinds" claim.

6. **Context key name: `raw` vs `raw_text`.** design-muster predicate row:
   "engagement_leak (`-needs raw_text`)". design-migration Wave 2b: the
   call is "`-context {raw $raw}`" and "engagement_leak rules match patterns
   against context `raw`". The drafts use `raw` (the actual call site wins).

7. **Incomplete predicate registration list.** design-migration Wave 2a:
   "Host predicates registered: `first_line_is_profile_hash`,
   `profile_hash_actual`, `is_null`." Its own rules-file inventory (line 40)
   and design-muster both require more (linkedin, placeholder_to,
   engagement_leak, version_*). Full list in (a).

8. **Issue-dict shape differences (affects the diff corpus).** yamlmuster
   issues always carry `path`, `level`, and (for keyed kinds) `key`, which
   legacy `_issue` dicts (39-46) never have. Conversely legacy sender and
   version issues carry `contact_name ""` from the `_issue` signature;
   yamlmuster only adds it if passed via `-extra`. Consumers (`build_warnings`,
   the gates) read severity/code/message/contact_name/segment via `getdef`,
   so behaviour is unaffected, but the "full-issue-dict diff" (risk 1) must
   project both sides to `{severity code message contact_name segment}`
   before comparing, and the sender/version wrappers should stamp
   `contact_name ""` in `-extra` if byte-parity is wanted.

9. **Value-reading kinds vs absent/blank guards (engine contract).** Not a
   spec statement, but the specs never pin it and the drafts depend on it:
   `range` (invalid_yield, invalid_star_rating, smtp_port_non_numeric) must
   skip an absent keypath, and smtp_port must additionally skip a blank
   value, or the drafts over-emit versus legacy's `dict exists` / `ne ""`
   guards (596, 625, 729). Confirm the engine's kind semantics at wiring;
   if a kind fires on absent/blank, move that check to a predicate.

10. **wrong_level first-owner resolution (engine contract).** Legacy picks
    the first owning level in canonical dict order (`break`, 74-77). The
    engine's KeyOwners map must name the FIRST-declared owning level for the
    hint. The levels are declared in canonical order in every file to
    preserve this; confirm the engine honours declaration order (keys like
    `subject`/`to` own both message and parent; `claim`/`source` own both
    fact_provenance_item and fact_check_item).

11. **`is_null` as a registered predicate.** design-migration lists it
    (Wave 2a) but no drafted rule references it — the linkedin/placeholder
    predicates call `spar::is_null` directly as a Tcl proc. Registering it
    as a yamlmuster predicate is redundant for these rules; keep it only if
    the module intends a null-check kind later. Flag, don't rely on it.
