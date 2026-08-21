# Revivals

Each flagged concept went back to the estimator whose guess was furthest off, in its own fresh
context, with the measured figures and one instruction: **check the instrument before the
cause**. Two classes were triaged in a batch, as the method permits where the cause is plain
from the table; every other flag got its own revival.

Where the operator re-checked a revival's own claim and found it wrong, the correction sits
under the report as **Operator correction**. A revival that misnames its mechanism but reaches
the right disposition is kept, corrected, not discarded.

---

## 1. The stem batch — 96 modules flagged "B high" (batch triage)

**Measured vs expected:** see `pick-table.md`; the batch is defined by `stem-check.json`, which
recomputes, per B-high module, how many corpus files the file's own stem matches on its own.
In 85 of the 96, the stem alone accounts for 80% or more of B.

Enough evidence. Reporting.

## Instrument check

**`connectors/clover/api/upsert.js`** (B=117, stem-alone=117): grep for `upsert` hits every connector — clover, rezdy, xero, spar, square, googlereviews, awsconnect each define their *own* `upsert.js` with their *own* `upsertEntity`. Only 19 of the matches import clover's file specifically; the rest are other connectors' independent files/comments using the same generic ETL verb ("INSERT...ON DUPLICATE KEY UPDATE" is habitually called "upsert" in every connector's prose). Nothing is traveling — it's a common domain verb every sibling reinvents.

**`spheres/schedule/api/config.js`** (B=199, stem-alone=199): grep for `config` hits `vite.config.ts`, `vitest.config.ts`, `lingui.config.ts`, other spheres' own `config.js`/`instance.js` files, and generic prose ("config", "configuration"). Zero files import `spheres/schedule/api/config.js` itself. Pure vocabulary collision with build tooling and unrelated modules — none of it is this module's concept.

**`web/src/lib/url-state.ts`** (B=30, stem-alone=30): different picture — 23 of the 30 are genuine `from '.../url-state'` imports across nine spheres' UI views, plus 7 prose comments describing "the url-state hooks/path" as a real shared concept (`slot-store.ts`, `drive.ts`, `view-scope.ts`, `ParamChips.tsx`). This one is a real hub module; B is not inflated by homonym noise.

## Mechanism (for the artifacts)
`upsert` and `config` are common English/domain words that happen to survive the filter only via the **stem-alone** path (hyphenated/short/non-dictionary check applied to the filename, not to the word itself) — `config` and `upsert` are ordinary dictionary words that would be rejected as *vocabulary* terms but the stem rule has "not an English dictionary word" as its bar and these apparently aren't in `/usr/share/dict/words` in this form, or the check simply wasn't applied uniformly to stems the way it was to symbol names.

## Batch outcome
**Artefact**, for the great majority of the 96. The stem-inclusion rule needs the *same* dictionary/genericity filter applied to symbol vocabulary — reject a stem if the bare word is a common English/domain term (dictionary-word check) or if sibling directories independently define a file with the identical stem (the "9 files named upsert" and "128 files matching config" columns already flag this in the source table — that count itself should have suppressed the stem). `url-state.ts` shows the rule works fine when the stem is genuinely distinctive; the fault is scoped to generic/reused stems, not the whole B metric.

**Operator correction.** The revival's guess at *why* the stems survive is loose. The rule in
`tools/scope-count.py` is exact: a declared name is kept only if it is defined in one file, is
not a dictionary word, and does not also name a symbol defined outside the tree; the **stem** is
added under a weaker rule — kept if it is not `lib`/`mod`/`main`/`index`, is at least three
characters, and is not in `/usr/share/dict/words`. It gets neither the several-homes guard nor
the external-name guard. `auth`, `config`, `upsert`, `sonas`, `rezdy` and `vocab` are all absent
from `/usr/share/dict/words`, so all six survive; `api`, `export`, `sphere`, `instance`,
`journey`, `atoms` and `credentials` are in it, so those families escaped. Nine files are named
`upsert.js`, six `insights-sync.js`, three `stage-advance.js` — and each of them separately
claims the shared stem, which is why nine sibling connectors report the identical B=117.

**Disposition: artefact,** for 85 of the 96 B-high flags.

---

## 2. `web/src/lib/auth.ts` — A 2 → 11, B 5 → 214, leak 203

That's 10 files, close to A=11 (one more likely a nested import path variant or lib/grants re-export). This confirms A is a genuine, tight consumer set concentrated in the app's Access/auth UI screens — plausible and legitimate.

## Findings

**Step 1 — what are the 214 B files?** I re-ran the grep vocabulary over the same corpus rule and got a comparable split: of ~280+ matching files, the overwhelming majority match on the bare substring `auth` alone, and inspecting those hits shows they are almost entirely **not** about `web/src/lib/auth.ts` at all. They are `author`, `authored`, `coauthors` (git-commit-message prose across docs/tests), and `authorize`/`authorized`/`oauth`/`authenticate` — the OAuth vocabulary of unrelated third-party connectors (`connectors/tiktok/api/auth-bootstrap.js`, `connectors/xero`, `connectors/googlechat`, `connectors/linkedin`, `connectors/dropbox`, etc.), plus `desktop/` Tcl files the SCIP index can't see by rule. Sampled contexts (e.g. `connectors/tiktok/api/tiktok-client.js: "authorizeUrl"`, `connectors/tiktok/README.md: "auth-bootstrap.js"`) confirm these are a different `auth` — each connector's own OAuth handshake — sharing only the English root, not the module's vocabulary. Checking the non-`auth`-only remainder (the other six vocabulary words: `AppRun`, `AppUser`, `addedBy`, `addedAt`, `added_by`, `saveRole`) adds only a handful of files beyond what `auth` alone already caught — real hits, but tiny (a migration script and a few `server/shared/*.test.js` files touching `added_by`/`added_at` columns). **B does not hold; the corrected B is essentially B_real ≈ A's real footprint plus low single digits — nowhere near 214.**

**Step 2 skipped** — no far-above-3 count survives the correction; no shared-struct/duplication mechanism to name.

**Verdict: artefact.** The count is the instrument's: a five-letter grep vocabulary word (`auth`) that is also an ordinary English root (`author`) and a generic OAuth term used by a dozen unrelated third-party connectors turned a real, tight consumer set (SCIP's A=11, concentrated in `web/src/app/Access*.tsx` and `AuthGate.tsx`) into an inflated 214/1129. My blind guess (B=3, C=5) undershot; the true story is closer to the guess than the measurement — the measurement's B/C are noise from lexical ambiguity, not usage.

**Operator correction.** The verdict is right and the mechanism is wrong. `scope-count.py`
greps on word boundaries, so `\bauth\b` does **not** match `author`, `authorize` or `oauth`; the
revival's account of the noise is mistaken. The operator re-ran the probe: 139 corpus files
contain the bare word `auth`, and they are the URL segment `/api/auth/...`, the *server's* own
`server/shared/auth.js` (a second module with the same stem, on the other side of the wire), the
`hook.auth` field, audit strings like `source: 'auth'`, and local variables named `auth`. The
stem names four different things in this tree. **Artefact** stands; the reason is homonymy of a
stem across tiers, not English morphology.

---

## 3. `web/src/pipeline/api.ts` — A 6 → 16, B 6 → 122, C 1248, leak 108

## 1. What carries B=122?

Checked each of the 6 sample words plus the file's full declared vocabulary (29 names). Per-word file counts are wildly uneven:

- `Stage`: 71 files — but almost none are this module's `Stage` interface. It's the English word "Stage 1/2/3" used in migration docs (`migration/tenant-foundation`, `migration/sync-runs-consolidation`, etc.) and a **separately declared, unrelated** `Stage` type in `spheres/social/ui/api.ts` (its own comment says it only "mirrors" this file's shape — no import).
- `fmtDate`: 25 files — but `spheres/coord/ui/views/Board.tsx`, `ByPerson.tsx`, `Meetings.tsx`, `spheres/customer-service/ui/views/Calls.tsx` etc. each import their own `fmtDate` from `lib/format` directly, not from `pipeline/api.ts`. Same name, independent declaration/import — a homonym, not this module's concept.
- `Contact`: 31 files — hits `connectors/awsconnect/api/sync.js`, `.design-sync/previews/ContactRow.tsx`, generic "contact" usage unrelated to the pipeline's `Contact` interface.
- `Person`, `Reply`, `Profile`, `Note`: common English/business nouns, each pulling in a handful of unrelated files (13, 13, 9, 7).

The genuinely distinctive names (`MemberId`, `PersonCore`, `BoardMemberCore`, `ContactDetailCore`, `PipelineClient`, `makePipelineClient`, `effectiveStages`, `entryStage`, `campaignParams`, `memberParams`, `memberKey`, `PeopleResponse`, `CampaignsResponse`, `r_note`/`a_note`/`s_note`/`p_note`) each hit only 1–9 files, tightly clustered around `connectors/spar/*`, `server/shared/spar-pipeline.js`, `spheres/publicity/*`, and their tests — that's this module's real footprint, consistent with A=16.

The Tcl tier (`desktop/*.tcl/.tm`) contributes **zero** hits for this file's vocabulary — not the leak source here. `.design-sync/previews/*` (in-corpus, not excluded) adds a few more incidental hits a reader wouldn't normally meet.

Corrected B (dropping the four generic homonyms, keeping only distinctive names): roughly **20–30 files**, not 122. C=1248 mentions is dominated by the same "Stage 1/2/3" prose repetition across migration docs.

## Verdict

**Artefact.** The measured B/C is a grep-vocabulary collision — common English words (`Stage`, `Contact`, `Person`, `Note`, `Reply`) and an independently-declared `fmtDate`/`Stage` elsewhere in the codebase — not this module's concept traveling. My blind guess (B=6) undercounted mildly even after correction, but 122 overstates true reach roughly 4-6x.

**Operator correction — this revival reaches the wrong disposition.** It analysed a word list it
derived itself from the source file, because the prompt gave it only a six-word sample. The
words it blames — `Stage`, `fmtDate`, `Contact` — are **not in the vocabulary the count used**:
each is declared in more than one file, so the several-homes guard had already removed them. The
operator printed the exact 53-word vocabulary and the corpus files each word alone matches
(`vocab-probe.py`). What carries B is not English nouns but **snake_case SQL column names**:

| word | corpus files matching it alone |
|---|---:|
| `stage_code` | 51 |
| `flipped_at` | 38 |
| `contact_name` | 30 |
| `reply_at` | 23 |
| `replied_date` | 21 |
| `linkedin_url` | 20 |
| `next_touch_at` | 15 |
| `actioned_date` | 15 |
| `reply_summary` | 13 |

and below them `s_note`, `r_note`, `a_note`, `p_note`, `star_rating`, `round_number`,
`yield_score`, `sweep_iteration`, `response_likelihood`, `angle_rationale`, `discovered_via`,
`extras_json`, `date_excluded`, `profile_date`, `from_addr`, `channel_detail`. `stage_code`
alone is spelled in six spheres, `server/shared`, `web/src` and two migration folders.

This is the leak the method exists to find: the pipeline tables' column vocabulary is declared
once as TypeScript property names in this module and re-spelled as **bare text** — in SQL
schemas, in server reads, in migration procedures, in tests — everywhere else. None of those
sites is an edge any reference graph can see, and none of them breaks a compiler when a column
is renamed.

**Disposition: scattered.** Cost: renaming one pipeline column is an edit in the schema, the
migration SQL, the server read, this client interface and the views that read it, with nothing
but a grep to find the last one.

---

## 4. `server/shared/sync-runs.js` — A 8 → 26, B 9 → 65, leak 39

**1. B holds and mostly reflects real content, but the leak is not one thing.**

Of the 65 B files: 26 are non-test files with a literal `import ... from '.../sync-runs.js'` — exactly the A edges the graph already counts, confirming A=26. One more (`server/shared/sync-runs.test.js`) is also a real import but is a test, so SCIP's A drops it — that's D's twin, the mirror-image miss (a real edge invisible to the graph, not noise inflating it). The remaining 38 are genuine non-graph mentions: connector `README.md`s and `docs/hooks.md`/`job-execution.md` describing the ledger in prose, `migration/sync-runs-consolidation/*` (PROCEDURE.md + two .sql files — the table's own migration, named for it), `server/shared/schema.sql` naming `job_runs`/`elapsed_ms` columns, `connectors/*/api/sync.js` + their `.test.js` twins (the connector body files, which mention `runSyncMain`/`job_runs` only in comments, not imports — the hook/sync.js *entrypoint* is what actually imports the module), and `server/app.js`. Nothing here is invisible to a reader — no Tcl hits appeared (this module's vocabulary doesn't reach `desktop/`), so the "corpus holds something a reader wouldn't meet" clause doesn't apply. Corrected: B=65 confirmed exactly; corrected leak = 38 genuine non-edge mentions (the measured 39 counts the dropped test import too).

**2. Mechanism, most consequential first:**
- Doc/README re-description (docs/hooks.md, job-execution.md, ~9 connector READMEs) — expected, human-facing.
- SQL re-spelling: `job_runs`/`elapsed_ms`/`ran_at` columns live in `server/shared/schema.sql` and the `sync-runs-consolidation` migration's own SQL files — the row's vocabulary is genuinely re-spelled in the schema, by necessity (SCIP can't index SQL).
- Duplicate connector bodies (`connectors/*/api/sync.js`) describing the frame in comments rather than importing it — this is the largest single cluster (~18 files) and is architectural: the entrypoint (`sync.js`) imports `runSyncMain`, the body (`api/sync.js`) just talks about it.

**3. By design.** The leak is the module's job execution vocabulary echoed in prose docs, its own migration/schema, and comment-level cross-references in sibling connector files — not scattered debris and not a counting artefact.

**Disposition: by design.** (I4: a flag may close with no defect.)

---

## 5. `web/src/ui/CtxMenu.tsx` and `server/shared/credentials.js`

## (a) `web/src/ui/CtxMenu.tsx`

**Instrument check:** grepping the vocabulary (`CtxMenu|CtxItem|CtxSub|CtxButton|subOffsets`) alone returns 17 files — matching your own observation that only 16/41 of measured B come from CtxMenu-specific stems. Adding `viewport` brings the union to ~42, confirming B≈41. Isolating `viewport`-only hits (not sharing any CtxMenu stem) gives 25 files: per-sphere `styles.css` files (coord, financial, library, projects, relationships, reputation, schedule, social, customer-service), `web/index.html`'s `<meta name="viewport">` tag, `privacy.html`/`terms.html`, `docs/hier.md`, and `web/src/app/ChatAssistant.tsx`/`ChatPane.tsx`/`chat.css` — none of which mention CtxMenu at all. `viewport` there means CSS media-query breakpoints and the HTML meta tag, not menu-clamping math. A confirmed at ~6-7 real non-test importers (Board.tsx, CampaignBoard.tsx x2, CampaignWizard.tsx, Rolodex.tsx, cards.tsx, border-czar.ts), matching your A=6.

**Verdict: artefact.** The stem `viewport` is a DOM/CSS commonplace that happens to appear once in CtxMenu.tsx's own comment prose; it does the majority of B's inflation (25 of ~41 files) by coincidence, not coupling. No mechanism to name — the module's real usage is exactly the ~6 files that import it.

## (b) `server/shared/credentials.js`

A=24 checks out: 17 connector `sync.js`/`api/*` files plus `server/shared/auth.js` and three `spheres/*/api/*.js` files all import `resolveCredentials`/`readToken`/`writeToken`/`listConnections` directly — this is a legitimate fan-out, one seam every connector calls for its keys, matching the file's own doc comment.

B's excess includes true collisions: `connectors/xero/api/xero-client.js` defines its *own* `listConnections` (Xero's OAuth-connections API concept) — same identifier, unrelated meaning, a genuine leak. `server/shared/connector-health.js` and `migration/connector-credentials/PROCEDURE.md` are legitimate prose cross-references (not imports, correctly excluded from A).

**Verdict: by design**, with one small **artefact** (the `listConnections` name collision in xero-client.js) inflating the leak count by one.

**Operator confirmation.** The exact vocabulary probe agrees on (a): of CtxMenu's six-word
vocabulary, `viewport` matches 29 corpus files on its own against `CtxMenu`'s 16 — the DOM word
carries the flag. **Artefact.** On (b), A=24 is exact and is the connector fan-out the module
exists to serve. **By design.**

---

## 6. Batch triage — 51 "D high (hub)" and 23 "A low"

I have enough to answer. No need for further digging.

## Class 1 — D high (leaf views), 51 modules

Reading `ProfitAndLoss.tsx`'s imports: 20+ lines pulling shared UI atoms (`SectionHeader`, `FreshnessNote`, `Chip`, `FilterRow`), lib hooks (`use-api-view`, `url-state`, `format`, `download`), and its own sphere's `api`, `matrix`, `window`, `vocab`, `export`, `letterhead`, `period`, `PeriodPicker` — plus CSS. That's the normal shape of a page component composing a UI kit and several data/format hooks; nothing here looks like undisciplined coupling. `server/app.js` (1352 lines) is similar in kind but different in mechanism: its D=16 comes largely from `await import('./shared/X.js')` — a dynamic-import fan-out registering its shared modules at startup, not ad hoc reach-ins.

The tell is the paired A column: every flagged view has A=1 (one parent mounts it) and D>10. A leaf screen with one caller and a dozen-plus fan-outs to a shared kit is exactly what a well-factored app looks like — the alternative (low D) would mean the view reimplements formatting, filtering, and layout locally, which is the actual anti-pattern. The estimator's median D≈3-5 assumed a flatter import profile than this codebase's convention (heavy central `web/src/lib` and `web/src/ui`) actually has.

**Verdict: artefact.** The flag is reading the estimator's prior about "normal" fan-out, not the code; composing a shared kit from a leaf view is by-design, and the estimator's baseline was miscalibrated for it.

## Class 2 — A low, 23 modules

Checked the two named cases directly:
- `connectors/*/hook.js`: every hook.js is referenced only by `.test.js` files and by comments in `connector-health.js` (no static import). Discovery happens via `fs.readdirSync` loops in `server/app.js`, not `import`/`require`.
- `server/shared/sql-static.js`: statically imported by `server/shared/pipeline-fixture.js` (`import { stripSqlComments, ... } from './sql-static.js'`), a genuine non-test consumer — yet measured A=0. No server-tier tsconfig exists in the repo (only `web/tsconfig.json`); server JS has no compiler-config anchor for SCIP to walk from, so it likely wasn't indexed for outgoing/incoming refs at all, independent of dynamic vs. static import style.

So the blind spot is broader than just "dynamic import": server-side JS (no tsconfig root) plus glob-discovered connector modules together account for the low-A pattern in both examples checked, and by extension likely most of the 23.

**Verdict: artefact.** The low-A signal here is overwhelmingly the index's blind spot (missing server tsconfig root + readdirSync-based dynamic discovery), not real sealing.

**Operator correction — the Class 2 evidence is partly the operator's fault and partly the
reviver's.** The prompt listed `server/shared/sql-static.js` as "expected 3, measured 0"; the
measured table says **A=3**, inside the band, never flagged. That figure was the operator's
error and the reviver built on it. The reviver then concluded that "no server-tier tsconfig
exists, so server JS was not indexed" — which is wrong: this run indexed the server tier from a
tsconfig kept **outside** the repository (`servercfg-tsconfig.json`), `sql-static.js` is in the
index with 744 occurrences, and its three non-test consumers are all recorded.

The operator re-derived Class 2 directly. The 23 A-low modules are two groups:

- **17 `connectors/*/credentials.js`, all A=0 against an expected 2.** No file imports them.
  `server/shared/credential-manifests.js` finds them with `readdirSync` and a *computed* path
  (`join(root, ent.name, 'credentials.js')`), then dynamic-imports it. No static edge exists, so
  A=0 is a true statement about the graph and a false one about the architecture. The blind
  estimator, reading the convention from the README, was right and the graph cannot see it.
- **6 shared server modules** — `contract.js`, `http-json.js`, `access.js`, `ready.js` and two
  others, each A=1 against an expected 6–10. `server/app.js` loads them through
  `await import('./shared/X.js')`: a string-literal dynamic import, which this indexer does not
  record as a reference. The consumers are real and the graph misses them.

**Disposition: artefact** for both classes — Class 1 because a leaf view composing a shared kit
is what high D looks like in a well-factored app, Class 2 because runtime discovery and dynamic
import are outside a static index's reach. Neither is a fact about this codebase's coupling.

---

## 7. The desktop breakpoint width — expected 2 places

Verified by grepping the tree myself.

**Homonyms excluded** (same digits, unrelated fact): `AccessApps.tsx` (90000ms `msec` guard, not 90000px), `access-apps.test.tsx`/`board-pager.test.ts` (timestamps and `snapIndex` scroll offsets), `fin-export.test.ts` (a $900 ledger fixture), `Documents.test.tsx` (900-byte file size), `performance-view.test.tsx` (a view count and an id string "900"). None of these are the breakpoint.

**Real hits**, all confirmed as the one desktop breakpoint by reading context: `web/src/lib/breakpoint.ts` declares `DESKTOP_MIN_PX = 900` and a matching `DESKTOP_QUERY` string/hook. `ChatAssistant.tsx` and `CampaignsSection.tsx` *import* that constant rather than respelling it, so they aren't independent decisions. `Gantt.tsx` and `Week.tsx` only mention "900px" in prose comments — no literal in code.

That leaves the CSS: 13 stylesheets (9 spheres' `styles.css` + `web/src/app/{chat,shell}.css` + `web/src/pipeline/styles.css` + `web/src/ui/kit.css`) each carry their own literal `@media (min-width: 900px)` — 17 occurrences total but 13 independent files, each a separate hand-typed copy of the number.

**Corrected figures**: decided in 1 place (`breakpoint.ts`); obeyed independently in 14 places (that file plus the 13 CSS files that respell 900 rather than reference it).

The JS constant's own comment claims it "mirrors the CSS desktop breakpoint" — an admission the relationship runs backward from what you'd want: JS chases CSS, not the reverse, and nothing enforces the mirror. There is no custom property or custom-media token either side could share; I grepped for `--breakpoint`/`--desktop`/`custom-media` and found nothing. Changing to 1024 costs 14 hand-edits with no compiler or linter catching a missed one.

**Verdict: scattered.**

**Operator confirmation.** The revival corrected the operator's own probe downward — from 17
files to 14 independent decisions — by excluding `ChatAssistant.tsx` and `CampaignsSection.tsx`
(which *import* `DESKTOP_MIN_PX` rather than respell it) and `Gantt.tsx`/`Week.tsx` (prose
comments only), and by naming five same-digit homonyms it threw out. That is the instrument
check doing its job, and it makes the finding smaller and firmer.

Independently, the measured table ranks `web/src/lib/breakpoint.ts` in its "leak signature" set
— A=3, B=16, leak=13 — with no oracle input at all. The module side and the fact side found the
same thing from opposite directions.

**Disposition: scattered.** Cost: 14 hand-edits, no compiler or linter to catch a miss.

---

## 8. The sphere `ui/api.ts` family — relationships, social, publicity

**Measured:** relationships A=3 B=85 leak=82; social A=15 B=85 leak=74; publicity A=3 B=56
leak=53. Each estimated at roughly A=3, B=4.

## Findings

**1. Which vocabulary word carries each count**

- **relationships** (B=85, leak=82): dominated by `Match` — case-sensitive substring hits **55 files**, virtually all from `assert.doesNotMatch(...)`/`assert.match` (Node's built-in assert API) and Jest's `toMatch*` matchers in unrelated `*.test.js` files (aws-connect, clover, deputy, googlereviews, …). Not this module's concept — a near-universal test-framework token. Dropping `Match`, the union of the remaining words (`Party`, `userId`, `claimId`, `eventId`, `lastname`) is **19 files**, and most of those are genuinely relationships-adjacent (`server/shared/party.js`, `docs/party.md`, `spheres/relationships/...`) plus `connectors/sonas` (legitimate domain overlap — Sonas is an events/wedding connector). Corrected B ≈ 19, corrected leak ≈ 14–16.

- **social** (B=85, leak=74): dominated by `Message` — **83 files** hit, spread across `agent/`, every connector's client/server code (`errorMessage`, `ErrorMessage` class, generic exception plumbing). Purely generic, not social's messaging concept. Excluding it, the union of `Grade`, `tiktok`, `sentAt`, `LastMsg`, `takenAt` is small (roughly matching A). Corrected B ≈ small, close to A.

- **publicity** (B=56, leak=53): `created_at` alone hits **48 files** — it's a SQL timestamp column present on every table across every connector's schema, not publicity's concept. Excluding it, the real vocabulary (`Coverage`, `addCoverage`, `coverageCount`, etc.) hits only **11 files**, and every one is genuinely publicity's own layers (schema, api, tests, docs, views). Corrected B ≈ 11, corrected leak ≈ 6–8.

**2/3. Mechanism and verdict**

No sphere's browser row type re-spells SQL columns; there's no cross-layer rename-cost mechanism to name. All three counts are **artefact**: the grep instrument was fooled by near-universal tokens (`Match`, `Message`, `created_at`) that happen to be this module's declared names but are actually assert/error/SQL-column boilerplate used everywhere. Once those are excluded, each module's real footprint (11–19 files) is modest and largely by-design (own schema/api/tests/docs/views), not scattered.

**Operator correction.** The verdict is right; two of the three carriers are not. Like the
`pipeline/api.ts` reviver, this one greped words it chose itself rather than the vocabulary the
count used, and it greped them loosely. `Match` is not in the relationships module's vocabulary
at all — it is declared in more than one file, so the several-homes guard removed it before any
grep ran; and `Message`, with the word boundaries and case sensitivity the tool actually
applies, matches 18 files, not 83. The exact per-word counts (`vocab-probe.py`) are:

| module | word carrying the count | corpus files it alone matches |
|---|---|---:|
| `spheres/relationships/ui/api.ts` | `linkedin` | 62 |
| | `Identity` | 22 |
| `spheres/social/ui/api.ts` | `tiktok` | 27 |
| | `Membership` | 22 |
| | `Message` | 18 |
| `spheres/publicity/ui/api.ts` | `created_at` | 49 |

`linkedin` and `tiktok` are the names of connector directories — a field on a sphere's row type
spelled the same as a whole subsystem elsewhere in the tree. `created_at` is the timestamp
column every table in the schema carries. All three are homonyms of the module's concept, not
the concept travelling.

The one figure that survives correction is `spheres/social/ui/api.ts`: `Membership`,
`pipelineState`, `audienceFit` and `dmThreadShortId` between them reach some 40 files with no
homonym to blame, against an expected 4. That is a smaller version of the `pipeline/api.ts`
mechanism and the owner may want to look at it; it was not separately revived in this round.

**Disposition: artefact** for relationships and publicity; **artefact in the main, with a
residue worth a look** for social.
