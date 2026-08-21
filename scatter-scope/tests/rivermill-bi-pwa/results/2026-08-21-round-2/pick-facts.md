# Pick — the decided-once facts

Expected places is the median of the three blind estimators, taken over the facts at least two
of them named. The measured side is split, as the method asks, into **decided in** (where the
fact is declared) and **obeyed in** (independent sites that assume it), because an estimator
answers the first and a grep answers the second. Homonyms excluded are named per probe.
Gap is log₃(obeyed ÷ expected); beyond ±1 flags.

| fact | expected | decided in | obeyed in (non-test) | gap | flag | disposition |
|---|---:|---:|---:|---:|---|---|
| the mobile-first desktop breakpoint width | 2 | 1 (`web/src/lib/breakpoint.ts`, `DESKTOP_MIN_PX = 900`) | 17 files, 17 `@media (min-width: 900px)` | +1.95 | **flag** | revived — see revivals.md |
| sphere self-registration (`spheres/*/ui/sphere.tsx` glob) | 13 | 1 (`web/src/app/spheres.ts`, one `import.meta.glob`) | 12 sphere entry files | −0.07 | — | by design (the convention's N homes are its interface) |
| connector self-registration (`hook.js` / `jobs.js` discovery) | 15 | 3 (`server/app.js`, `contract-helpers.js`, `sql-static.js`) | 9 `hook.js` + 16 job entrypoints = 25 | +0.46 | — | by design |
| grant-token grammar and cover logic | 3 | 2 (`server/shared/grants.js`; `web/src/lib/grants.ts` mirrors the cover half only) | 6 | +0.63 | — | by design; the server module's own header documents the mirror and pins it with a shared vector table |
| error-code vocabulary mirrored client/server | 2 | 3 (`server/shared/error-codes.js`, `web/src/lib/error-codes.ts`, `agent/error-codes.js`) | 35 | — | — | by design on the definition (+0.37); the third home, the agent tier's own list, is the one a reader would not have guessed |
| one HTTP transport bottom | 1 | 1 (`server/shared/http-raw.js`) | 20 clients | 0.00 | — | by design |
| the product's working name | 4 | 1 (`README.md`) | 2 files, 3 sites | −0.63 | — | by design; the README's own note that `bi-`/`BI_`/`/bi` stay as they are is what keeps this small |
| credential-manifest shape | 4 | 1 (`server/shared/credential-manifests.js`) | 17 `connectors/*/credentials.js` | +1.32 | flag | by design — a sibling-family interface, the convention table's shape, not scatter |
| venue-local date handling | 3 | 1 (`server/shared/venue-date.js`) | 8 | +0.89 | — | by design |
| pipeline stage vocabulary | 5 | 2 (`server/shared/stage-vocabulary.js`, `stage-advance.js`) | 20 non-test source files across 6 spheres | +1.26 | flag | by design — the module's own header states the composition rule and names the four readers and six call sites; the count is the intended fan-out |
| tenant scoping | 4 | 2 (`server/shared/tenancy.js`, `connector-tenant.js`) | 58 | +2.44 | **flag** | by design — the README's first paragraph makes multi-tenancy the platform's commitment; a fact obeyed everywhere by design is not a finding (INVARIANTS I4) |
| `job_claims` row-claiming protocol | 6.5 | 1 (`server/shared/job-claims.js`) | 5 source + 10 migration procedures | −0.24 | — | by design |
| the union view across tenants | 4 | — | — | — | — | **not measured**: named by one estimator only, and its only handle is common words; the method says record it as not measured rather than give it a number |
| MySQL access centralised in one module | 1 | 1 (`server/shared/db.js`) | 44 (= its A) | — | — | by design; A is exact and needs no probe |

## Probes and their exclusions

- **breakpoint**: `\b900px\b|DESKTOP_MIN_PX|DESKTOP_QUERY`. Documentation files (3) excluded from the obeyed count; the revival was asked to exclude any `900px` that is not the desktop breakpoint (a container max-width, a grid track, a `min-height`).
- **sphere registration**: `import\.meta\.glob\(.*sphere\.tsx|ui/sphere\.tsx`. Excludes `web/src/app/sphere.ts`, the *type* module, whose stem collides.
- **connector registration**: `import\.meta\.glob\(.*connectors|readdir.*connectors|connectors/\*`. Excludes `package.json` and the lockfile (workspace globs, not discovery).
- **grants**: `parseGrants|coversDataset|grantsCover|DATA_TOKEN`. Excludes the bare word `grant`, which the migration folder uses for the SQL sense.
- **error codes**: `\bErrorCode\b|ERROR_CODES|errorText\(`. Excludes `error` alone.
- **tenancy**: `connector-tenant|tenantOf|withTenant|tenancy`, tests and docs removed. Excludes `tenant_id` as a bare SQL column (8 files), which is the schema's spelling of the same fact and would double-count.
- **stage vocabulary**: `pipeline_stages|stage-vocabulary|stageVocab|pipeline_stage_subsets`, tests and docs and migration procedures removed from the source figure.
