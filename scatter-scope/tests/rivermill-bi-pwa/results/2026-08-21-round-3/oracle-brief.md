# Blind estimation brief

You are estimating, from a program's description alone, how widely each of its modules is used and spoken about. You have no access to the code and no tools. Answer with numbers.

## 1. The program's own description

# bibi

A business platform that gathers a business's back-office work into one installable, mobile-first web app: social-media marketing, operational performance, and financial reconciliation, with booking to follow. One install serves many businesses: each is a tenant, and the platform's commitment is that staff who work across several see all of their work on one screen (`docs/scalability.md` §The multi-tenant view; the union view's UI is #112's work).

`bibi` is the product's working name until marketing returns one (gitlab #119). New prose and new identifiers use it; the `bi-`, `BI_` and `/bi` prefixes name the category rather than the product and stay as they are.

## What it covers

- **Social marketing**: posting and reply tracking across Facebook Groups and Instagram, a campaign-level overview, and the replies that need a human answer.
- **Reputation**: the business's Google reviews, and the ones still waiting for an answer.
- **Outreach**: partnership and publicity campaigns, each a roster of contacts and where every conversation stands.
- **Relationships**: everyone the business knows, resolved across every source into one list.
- **Coordination**: who was asked to do what, reconstructed from the team's chat, plus captured meetings.
- **Schedule**: bookings, weddings, and the business's own entries merged onto one calendar, with the changes waiting to land.
- **Projects**: one-off endeavours tracked to an outcome, a portfolio board and a per-project milestone Gantt.
- **Performance**: revenue, labour cost, and daily profit and loss.
- **Financial**: expense reconciliation, corrections, and cash flow.
- **Booking**: planned.

An assistant sits beside every domain without owning one: a chat panel on every screen, answering from the business's own data, good enough that staff need not paste it into a separate AI chat.

Staff reach all of it from one mobile-first web app, on a phone or a desktop.

(Installation and build detail cut.)

## 2. Size facts

Source files and lines by top-level area:

| area | source files | lines |
|---|---:|---:|
| spheres | 258 | 47853 |
| connectors | 147 | 21271 |
| web | 129 | 19322 |
| server | 91 | 17458 |
| desktop | 46 | 16445 |
| scripts | 8 | 2623 |
| agent | 13 | 2290 |
| migration | 4 | 177 |

Documentation files (105), by name:

- `.design-sync/NOTES.md`
- `.design-sync/conventions.md`
- `CLAUDE.md`
- `README.md`
- `Requirements.md`
- `agent/README.md`
- `connectors/clover/README.md`
- `connectors/deputy/README.md`
- `connectors/dropbox/README.md`
- `connectors/facebook/README.md`
- `connectors/github/README.md`
- `connectors/googlechat/README.md`
- `connectors/googlereviews/README.md`
- `connectors/instagram/README.md`
- `connectors/linkedin/README.md`
- `connectors/onedrive/README.md`
- `connectors/otter/README.md`
- `connectors/rezdy/README.md`
- `connectors/sonas/README.md`
- `connectors/spar/README.md`
- `connectors/square/README.md`
- `connectors/tiktok/README.md`
- `connectors/xero/README.md`
- `desktop/LOGGING-CHECKLIST.md`
- `desktop/README.md`
- `desktop/themes/design/_ds/historic-rivermill-design-system-019dd5af-8e9c-78ba-93a6-ffd5dee56845/README.md`
- `docs/2026-06-10-inbox-sweep-flow.md`
- `docs/2026-07-08-overnight-worklog.md`
- `docs/INVARIANTS.md`
- `docs/access-control.md`
- `docs/architecture.md`
- `docs/border-czar-alignment.md`
- `docs/border-czar-ledger.md`
- `docs/building-a-sphere.md`
- `docs/growth-decision-map.md`
- `docs/hier.md`
- `docs/hooks.md`
- `docs/i18n.md`
- `docs/interaction-seam.md`
- `docs/job-execution.md`
- `docs/overseer-protocol.md`
- `docs/overseer.md`
- `docs/party.md`
- `docs/playbook.md`
- `docs/runbook.md`
- `docs/scalability.md`
- `docs/spar-pipeline.md`
- `docs/status.md`
- `docs/vision.md`
- `migration/REHEARSAL.md`
- `migration/connector-credentials/PROCEDURE.md`
- `migration/connector-tenant-2/PROCEDURE.md`
- `migration/connector-tenant/PROCEDURE.md`
- `migration/fin-vocab-l10n/PROCEDURE.md`
- `migration/grants-normalisation/PROCEDURE.md`
- `migration/one-ledger/PROCEDURE.md`
- `migration/owner-axis-inboxes/PROCEDURE.md`
- `migration/people-core/PROCEDURE.md`
- `migration/pipeline-consolidation/PROCEDURE.md`
- `migration/pipeline-social/PROCEDURE.md`
- `migration/rekey-longkey/PROCEDURE.md`
- `migration/rekey-seek-indexes/PROCEDURE.md`
- `migration/roles/PROCEDURE.md`
- `migration/shell-auth/PROCEDURE.md`
- `migration/sync-runs-consolidation/PROCEDURE.md`
- `migration/tenant-defaults-drop/PROCEDURE.md`
- `migration/tenant-foundation/PROCEDURE.md`
- `migration/tenant-mirrors-1/PROCEDURE.md`
- `migration/tenant-mirrors-2/PROCEDURE.md`
- `migration/tenant-mirrors-3/PROCEDURE.md`
- `migration/tenant-social/PROCEDURE.md`
- `migration/tenant-spheres/PROCEDURE.md`
- `migration/user-language/PROCEDURE.md`
- `migration/walls/PROCEDURE.md`
- `policing/playbook-audit.aesop.md`
- `spheres/coord/docs/reads.md`
- `spheres/coord/docs/task-home.md`
- `spheres/coord/runbooks/ao01-derive-meeting.md`
- `spheres/customer-service/docs/reads.md`
- `spheres/financial/docs/2026-07-04-pl-process-knowledge.md`
- `spheres/financial/docs/export.md`
- `spheres/financial/docs/reads.md`
- `spheres/library/docs/library.md`
- `spheres/library/docs/reads.md`
- `spheres/partnership/docs/reads.md`
- `spheres/projects/docs/milestone-authoring-draft.md`
- `spheres/projects/docs/reads.md`
- `spheres/projects/docs/verdict-bootstrap.md`
- `spheres/publicity/docs/reads.md`
- `spheres/publicity/runbooks/at00-advance-pipeline-stage.md`
- `spheres/relationships/docs/reads.md`
- `spheres/reputation/docs/reads.md`
- `spheres/schedule/docs/reads.md`
- `spheres/social/README.md`
- `spheres/social/docs/architecture.md`
- `spheres/social/docs/crm-open-threads.md`
- `spheres/social/docs/ig-crm-state-machine.md`
- `spheres/social/docs/reads.md`
- `spheres/social/runbooks/ai00-shortlist-marketing-threads.md`
- `spheres/social/runbooks/ai01-read-marketing-thread.md`
- `spheres/social/runbooks/ai02-grade-marketing-contact.md`
- `spheres/social/runbooks/ai03-advance-funnel-stage.md`
- `web/README.md`
- `web/docs/guides/border-czar-foundations.md`
- `web/docs/guides/border-czar-patterns.md`

## 3. The module list

Each row is a module to estimate: its path, its length in lines, and the module's own one-line doc as the file carries it (blank where the file carries none).

| module | lines | its own doc line |
|---|---:|---|
| `agent/drive-tools.js` | 163 | The drive class: the assistant's write side of the interaction seam |
| `agent/error-codes.js` | 37 | The error codes this tier stamps beside its English prose, so a chat failure |
| `agent/server.js` | 561 | The agent runtime: a small HTTP server that runs the conversation loop. |
| `agent/system-prompt.js` | 37 | The assistant's system prompt. One function, one string: the |
| `agent/tools.js` | 202 | Manifest-driven tool derivation for the agent runtime. |
| `agent/transcribe.js` | 115 | One-shot call transcription for the BI server: fetch the short-lived audio |
| `connectors/awsconnect/api/aws-client.js` | 132 | The AWS read client over plain node:https, so it runs on the host's Node 16 |
| `connectors/awsconnect/api/presign.js` | 34 | S3 GET presigning (SigV4 query auth): a short-lived URL for one object, |
| `connectors/awsconnect/api/sigv4.js` | 76 | AWS Signature Version 4 over node:crypto, the signing half of the client: |
| `connectors/awsconnect/api/sync.js` | 384 | The awsconnect cursor sync: a server-side API pull (kind C) that mirrors |
| `connectors/awsconnect/api/upsert.js` | 238 | Row mapping and upserts for the awsconnect mirror: raw API records in, |
| `connectors/awsconnect/credentials.js` | 20 | The connector's declared credential shape: what it needs to reach the |
| `connectors/awsconnect/hook.js` | 42 | The connector's self-registered hook. The BI app discovers connectors/*/hook.js |
| `connectors/awsconnect/sync.js` | 89 | External-timer entrypoint for the awsconnect cursor sync. A host cron entry |
| `connectors/clover/api/clover-client.js` | 137 | The Clover REST read client (v3, default base https://api.clover.com) over |
| `connectors/clover/api/sync.js` | 214 | The Clover cursor sync: a server-side API pull (kind C — neither browser |
| `connectors/clover/api/upsert.js` | 214 | The entity registry and the generic upsert. ENTITIES is the single list of |
| `connectors/clover/credentials.js` | 17 | The connector's declared credential shape: what it needs to reach Clover, |
| `connectors/clover/hook.js` | 37 | The connector's self-registered hook. The BI app discovers |
| `connectors/clover/sync.js` | 88 | External-timer entrypoint for the Clover cursor sync. A host cron entry or |
| `connectors/deputy/api/deputy-client.js` | 135 | The Deputy Resource API read client over plain node:https, so it runs on the |
| `connectors/deputy/api/sync.js` | 240 | The Deputy cursor sync: a server-side API pull (kind C — neither browser nor |
| `connectors/deputy/api/upsert.js` | 134 | The entity registry and the generic upsert. ENTITIES is the single list of what |
| `connectors/deputy/credentials.js` | 16 | The connector's declared credential shape: what it needs to reach Deputy, named |
| `connectors/deputy/hook.js` | 36 | The connector's self-registered hook. The BI app discovers connectors/*/hook.js and |
| `connectors/deputy/sync.js` | 86 | External-timer entrypoint for the Deputy cursor sync. A host cron entry or the BI |
| `connectors/dropbox/api/consent.js` | 66 | One-time OAuth consent: mint the Dropbox refresh token for the account whose |
| `connectors/dropbox/api/dropbox-client.js` | 359 | The Dropbox live-read client: files/search_v2, metadata, thumbnails, sharing |
| `connectors/dropbox/api/probe.js` | 61 | A CLI probe over the live client: run one search the way the library sphere |
| `connectors/dropbox/credentials.js` | 24 | The connector's declared credential shape: what it needs to reach the office's |
| `connectors/facebook/api/graph-client.js` | 167 | The Facebook Page Graph API read client, plain REST over node:https so it runs |
| `connectors/facebook/api/insights-sync.js` | 311 | The Facebook Page cursor pass (CF01): a server-side Graph API pull that keeps |
| `connectors/facebook/credentials.js` | 28 | The connector's declared credential shape, rendered by the Access screen's Apps |
| `connectors/facebook/insights-sync.js` | 77 | External-timer entrypoint for the Facebook Page cursor pass (CF01). A host |
| `connectors/github/api/formats.js` | 16 | The well-formedness gates, one per `format` value a subscription may declare. |
| `connectors/github/api/github-client.js` | 156 | The GitHub Contents API read client (base https://api.github.com) over plain |
| `connectors/github/api/sync.js` | 131 | The GitHub file mirror pass: a server-side API pull (kind C, neither browser nor |
| `connectors/github/credentials.js` | 16 | The connector's declared credential shape: what it needs to reach GitHub, named |
| `connectors/github/hook.js` | 53 | The connector's self-registered hook. The BI app discovers connectors/*/hook.js and |
| `connectors/github/sync.js` | 82 | External-timer entrypoint for the GitHub file mirror. A host cron entry or the BI |
| `connectors/googlechat/api/chat-client.js` | 119 | The Google Chat read client, plain REST over node:https so it runs on the host's |
| `connectors/googlechat/api/sync.js` | 304 | The Google Chat cursor sync: a server-side API pull (neither browser nor model) |
| `connectors/googlechat/credentials.js` | 27 | The connector's declared credential shape: what it needs to reach Google Chat, |
| `connectors/googlechat/hook.js` | 42 | The connector's self-registered hooks. The BI app discovers connectors/*/hook.js |
| `connectors/googlechat/sync.js` | 98 | External-timer entrypoint for the Google Chat cursor sync. A host cron entry, a |
| `connectors/googlereviews/api/import-historical.js` | 105 | The one-shot historical import: read an Apify "Google-Maps-Reviews-Scraper" JSON |
| `connectors/googlereviews/api/serpapi-client.js` | 70 | The SerpApi read client for Google Maps reviews, plain REST over node:https (no |
| `connectors/googlereviews/api/sync.js` | 232 | The SerpApi review pump: a server-side API pull (neither browser nor model) that |
| `connectors/googlereviews/api/upsert.js` | 183 | The one home for the two-source reconciliation rule, shared by both importers |
| `connectors/googlereviews/credentials.js` | 13 | The connector's declared credential shape: what it needs to reach SerpApi for the |
| `connectors/googlereviews/hook.js` | 43 | The connector's self-registered hook. The BI app discovers connectors/*/hook.js |
| `connectors/googlereviews/import-historical.js` | 53 | One-shot import of an Apify "Google-Maps-Reviews-Scraper" dump into the |
| `connectors/googlereviews/sync.js` | 73 | External-timer entrypoint for the SerpApi review pump. A host cron, a systemd |
| `connectors/instagram/api/graph-client.js` | 174 | The Instagram Graph API read client, plain REST over node:https so it runs on the |
| `connectors/instagram/api/insights-sync.js` | 512 | The Instagram per-post insights cursor pass: a server-side Graph API pull (neither |
| `connectors/instagram/api/jobs.js` | 559 | Instagram connector: the raw-ingest jobs and the shared instagram_-only |
| `connectors/instagram/api/shortcode.js` | 45 | Instagram media-pk ↔ permalink-shortcode codec. Pure, no DB: the bridge between |
| `connectors/instagram/credentials.js` | 19 | The connector's declared credential shape: what it needs to reach Instagram, named |
| `connectors/instagram/insights-sync.js` | 81 | External-timer entrypoint for the Instagram Graph cursor pass (CI01). A host |
| `connectors/instagram/jobs.js` | 17 | The connector's self-registered job map. The BI app discovers connectors/*/jobs.js |
| `connectors/linkedin/api/jobs.js` | 579 | LinkedIn connector: the raw-ingest jobs and the shared linkedin_-only SQL. |
| `connectors/linkedin/api/memdb.js` | 185 | An in-process stand-in for a mysql2 connection, used by this connector's tests. |
| `connectors/linkedin/credentials.js` | 15 | The connector's declared credential shape, rendered by the Access screen's Apps |
| `connectors/linkedin/jobs.js` | 15 | The connector's self-registered job map (connectors/instagram/jobs.js documents |
| `connectors/onedrive/api/consent.js` | 78 | One-time OAuth consent for the OneDrive connector: mint the first refresh |
| `connectors/onedrive/api/graph-client.js` | 343 | The OneDrive client: live search and item reads over Microsoft Graph |
| `connectors/onedrive/api/probe.js` | 61 | The hand-run probe: one live search against the office's OneDrive through |
| `connectors/onedrive/credentials.js` | 36 | The connector's declared credential shape: what it needs to reach the office's |
| `connectors/otter/api/jobs.js` | 274 | Otter connector: the raw-ingest jobs and the shared otter_-only SQL. |
| `connectors/otter/api/memdb.js` | 187 | An in-process stand-in for a mysql2 connection, used by this connector's tests |
| `connectors/otter/credentials.js` | 15 | The connector's declared credential shape, rendered by the Access screen's Apps |
| `connectors/otter/jobs.js` | 12 | The connector's self-registered job map (connectors/instagram/jobs.js documents |
| `connectors/rezdy/api/rezdy-client.js` | 156 | The Rezdy Supplier API read client (base https://api.rezdy.com/v1) over plain |
| `connectors/rezdy/api/sync.js` | 204 | The Rezdy cursor sync: a server-side API pull (kind C — neither browser nor model) |
| `connectors/rezdy/api/upsert.js` | 356 | The entity registry and the generic upsert. ENTITIES is the single list of what |
| `connectors/rezdy/credentials.js` | 13 | The connector's declared credential shape: what it needs to reach Rezdy, named |
| `connectors/rezdy/hook.js` | 36 | The connector's self-registered hook. The BI app discovers connectors/*/hook.js and |
| `connectors/rezdy/sync.js` | 82 | External-timer entrypoint for the Rezdy cursor sync. A host cron entry or the BI |
| `connectors/sonas/api/sonas-client.js` | 376 | The Sonas DDP read client. Sonas (app.sonas.events) is a Meteor app with no REST |
| `connectors/sonas/api/sync.js` | 251 | The Sonas cursor sync: a server-side DDP pull (kind C — neither browser nor |
| `connectors/sonas/api/upsert.js` | 317 | The entity registry and the generic upsert. ENTITIES is the single list of what |
| `connectors/sonas/credentials.js` | 29 | The connector's declared credential shape: what it needs to sign in to Sonas, |
| `connectors/sonas/hook.js` | 61 | The connector's self-registered hook. The BI app discovers connectors/*/hook.js |
| `connectors/sonas/sync.js` | 102 | External-timer entrypoint for the Sonas cursor sync. A host cron entry or the |
| `connectors/spar/api/parse.js` | 315 | Pure parsers from SPAR checkout files to mirror-table rows. Each function |
| `connectors/spar/api/upsert.js` | 215 | The writers from parsed rows to the spar_* mirror. Every parent table follows |
| `connectors/spar/credentials.js` | 12 | The connector's declared credential shape, rendered by the Access screen's Apps |
| `connectors/spar/sync.js` | 175 | External-timer entrypoint for the SPAR filesystem mirror. A host cron entry or |
| `connectors/square/api/square-client.js` | 108 | The Square REST client (base https://connect.squareup.com) over plain |
| `connectors/square/api/upsert.js` | 137 | The entity registry and the generic upsert for the Square historical |
| `connectors/square/import.js` | 82 | The hand-run historical importer: walks the retired Square account's whole |
| `connectors/tiktok/api/auth-bootstrap.js` | 97 | One-time OAuth consent: mint the first TikTok user token and write |
| `connectors/tiktok/api/insights-sync.js` | 181 | The TikTok cursor pass (CK01): one bounded, single-flight pull of the |
| `connectors/tiktok/api/tiktok-client.js` | 134 | The TikTok Display API client, plain REST over node:https so it runs on the |
| `connectors/tiktok/credentials.js` | 24 | The connector's declared credential shape, rendered by the Access screen's Apps |
| `connectors/tiktok/insights-sync.js` | 84 | External-timer entrypoint for the TikTok cursor pass (CK01). A host cron |
| `connectors/xero/api/auth-bootstrap.js` | 113 | One-time OAuth consent: mint the first refresh token and resolve the tenant, then |
| `connectors/xero/api/sync.js` | 242 | The Xero cursor sync: a server-side API pull (kind C — neither browser nor model) |
| `connectors/xero/api/upsert.js` | 333 | The entity registry and the generic upsert. ENTITIES is the single list of what |
| `connectors/xero/api/xero-client.js` | 211 | The Xero read client: accounting (api.xro/2.0) and payroll AU (payroll.xro/1.0) |
| `connectors/xero/credentials.js` | 22 | The connector's declared credential shape: what it needs to reach Xero, named once |
| `connectors/xero/hook.js` | 42 | The connector's self-registered hook. The BI app discovers connectors/*/hook.js and |
| `connectors/xero/sync.js` | 98 | External-timer entrypoint for the Xero cursor sync. A host cron entry or the BI |
| `scripts/deploy-skills.mjs` | 93 | Stamp the distributed_versions ledger with the current commit of every |
| `scripts/import-env-credentials.mjs` | 103 | One-time seed of the connector_credential store from the host's own |
| `scripts/import-meta-exports.mjs` | 804 | Import Meta Business Suite CSV exports into the platform mirror tables. |
| `scripts/import-otter-corpus.mjs` | 755 | Import the historical Otter meeting corpus (the rivermill repo's |
| `scripts/refresh-meta-recent.mjs` | 235 | Post-import refresh: pull each own Instagram account's recent posts through the |
| `scripts/stage-flip-harness.mjs` | 142 | The stage-advance acceptance harness: work item 57's 17 real Instagram |
| `server/app.js` | 1352 | BI HTTP API for the cPanel/Passenger Node tier (host startup file |
| `server/shared/access.js` | 219 | The dataset access gate — the one home of the access decision. Both |
| `server/shared/anthropic.js` | 63 | A type-A runbook's model leg over the Anthropic messages API — the server- |
| `server/shared/auth.js` | 1679 | Shell sign-in: passwordless email codes for the PWA's read tier. |
| `server/shared/chat.js` | 85 | The chat mount ('chat' is the shell's name, like 'auth', 'click-log' and |
| `server/shared/click-log.js` | 11 | The single INSERT into click_log, the deep-link click telemetry behind the |
| `server/shared/closure.js` | 87 | Assemble a type-B job's file closure for distribution to an overseer. The |
| `server/shared/connector-health.js` | 119 | Connector health: the pass-ledger truth layer (one row per owner, the |
| `server/shared/connector-tenant.js` | 45 | The one read of the connector_tenant attribution row (schema.sql, the |
| `server/shared/contract-helpers.js` | 41 | The contract helpers every connector's persist leg shares: compile a JSON |
| `server/shared/contract.js` | 154 | The written owner-config contract, checked at boot. A sphere's instance.js |
| `server/shared/credential-manifests.js` | 77 | Discovery of the connector credential manifests: each connector that takes |
| `server/shared/credentials.js` | 278 | The Apps credential store's two faces over connector_credential |
| `server/shared/datasets.js` | 72 | The dataset vocabulary: the names a route declaration or a grant token may |
| `server/shared/db-errors.js` | 19 | The driver's error shapes, read once so every caller reads them the same |
| `server/shared/db.js` | 92 | MySQL access for the platform. For local dev (the tests and a locally-run server), |
| `server/shared/deepseek.js` | 52 | The DeepSeek leg of the API executor — same contract as anthropic.js |
| `server/shared/dispatch.js` | 234 | The one route dispatcher behind a sphere's handleApi (the /api/<sphere>/ |
| `server/shared/error-codes.js` | 98 | The server's error-code vocabulary: the stable machine code a refusal |
| `server/shared/events.js` | 57 | The doorbell — a contentless SSE stream at GET /events. Clients (overseers, |
| `server/shared/freshness.js` | 46 | The mirror-age read: each mirror's last successful pass from the pass-grain |
| `server/shared/grants.js` | 224 | The grant-token grammar and its cover logic — the pure core of the |
| `server/shared/hash.js` | 8 | The hex SHA-256 of a buffer. The import scripts key their import_runs ledger |
| `server/shared/http-json.js` | 50 | The BI shell's three request/response helpers, one home for the two files |
| `server/shared/http-raw.js` | 54 | The one HTTP transport bottom under every connector client and model |
| `server/shared/job-claims.js` | 108 | The job_claims protocol, one home: how a single row of work is handed to a |
| `server/shared/job-runs.js` | 74 |  |
| `server/shared/manifest.js` | 166 | The per-job closure manifest: load each sphere's or connector's jobs.manifest.yaml and check |
| `server/shared/model-api.js` | 14 | The API executor's provider chooser: the server accepts both keys, and a |
| `server/shared/model-retry.js` | 44 | The retry policy the hosted model executors share, one stratum above the |
| `server/shared/ollama.js` | 51 | A type-A runbook's model leg over a local Ollama server — the zero-cost, |
| `server/shared/party.js` | 424 | The people core's routes: cross-source person linkage and nothing else |
| `server/shared/pipeline-fixture.js` | 86 | Test fixture: the pipeline core tables as session-local TEMPORARY tables, |
| `server/shared/ready.js` | 329 | The single-source-of-truth read of the eligible ("ready") work set, shared by |
| `server/shared/runbook.js` | 68 | Load a type-A job's runbook: a Markdown file with a YAML front-matter header |
| `server/shared/secret-box.js` | 43 | Seal and open credential values for the connector_credential store |
| `server/shared/spar-pipeline.js` | 623 | The spar-pipeline sphere family's stage pipeline, run over contacts the |
| `server/shared/sql-static.js` | 408 | The static-SQL reading shared by the conformance tests (schema-conformance, |
| `server/shared/stage-advance.js` | 323 | The stage-advance machinery every pipeline process composes: the sweep |
| `server/shared/stage-vocabulary.js` | 118 | The stage vocabulary's composable half: the scoped read of a sphere's |
| `server/shared/sync-runs.js` | 199 | The one implementation of the C-job pass leg of the activity ledger |
| `server/shared/tenancy.js` | 124 | The request's tenant scope — the walls.js pattern applied to tenancy: one |
| `server/shared/testdb.js` | 25 | Integration-test harness. The DB user can only touch the one live database |
| `server/shared/trail.js` | 45 | The write trail (write_trail): one row per write decision or registry |
| `server/shared/venue-date.js` | 64 | One home for venue-local DATE handling. This is the neutral tier, so it imports |
| `server/shared/versions.js` | 31 | Pure logic over the distributed_versions ledger for ONE (repo, artifact_ref): |
| `server/shared/walls.js` | 159 | Everything below is wall enforcement's single home (docs/access-control.md |
| `spheres/coord/api/decode.js` | 153 | The Google Chat task decoder, kept isolated so it lifts to a shared domain layer |
| `spheres/coord/api/instance.js` | 58 | The coord instance config: what the BI server needs to mount the sphere. |
| `spheres/coord/api/jobs-a.js` | 399 | Coord sphere: the meeting jobs, AO01 (type-A derive) and BO03 (type-B |
| `spheres/coord/api/jobs.js` | 228 | The coord sphere's deterministic reconstruction pass: read the connector's |
| `spheres/coord/api/meetings.js` | 241 | The coord sphere's meeting queries: plain (conn, params) -> data functions, |
| `spheres/coord/api/read.js` | 282 | The coord sphere's API: the half the PWA's ui/ calls over /bi/api/coord/*. |
| `spheres/coord/capture.js` | 31 | The capture vocabulary: the words the meeting corpus and the Otter title |
| `spheres/coord/prelink.js` | 74 | Deterministic corpus↔recording pre-link, the step that runs before any |
| `spheres/coord/reconstruct.js` | 29 | Run the coord sphere's task reconstruction over the connector's mirror. |
| `spheres/coord/ui/api.ts` | 204 | Typed access to the coord component's API: the rendered reads ride the kit's |
| `spheres/coord/ui/sphere.tsx` | 42 | The shell discovers this file (web/src/app/spheres.ts globs */ui/sphere.tsx) |
| `spheres/coord/ui/views/Board.tsx` | 141 | The same tasks by state: a card's column is its status, and moving it writes |
| `spheres/coord/ui/views/ByPerson.tsx` | 196 | The section the sphere opens to: tasks by person, most-assigned first, each |
| `spheres/coord/ui/views/MeetingFollowUp.tsx` | 134 | Turning a meeting into a follow-up task. A meeting is a source, not a card, |
| `spheres/coord/ui/views/Meetings.tsx` | 299 | The meetings section: search across every captured meeting (FULLTEXT on the |
| `spheres/coord/ui/windows.tsx` | 40 | The window filter both sections share: rolling last-seven-days (the default), |
| `spheres/customer-service/api/calls.js` | 457 | The Calls read: how the venue's phone line is doing over a window, |
| `spheres/customer-service/api/instance.js` | 14 | The customer-service instance config: what the BI server needs to mount the |
| `spheres/customer-service/api/policy.js` | 36 | The sphere's policy: config/customer-service.config.json loaded once per |
| `spheres/customer-service/api/read.js` | 125 | The customer-service sphere's API: the half the PWA's ui/ calls over |
| `spheres/customer-service/api/transcripts.js` | 90 | The transcript pair behind the log's View-transcript control. The read |
| `spheres/customer-service/ui/api.ts` | 164 | Typed access to the customer-service sphere's API, over the kit's |
| `spheres/customer-service/ui/sphere.tsx` | 33 | The shell discovers this file (web/src/app/spheres.ts globs */ui/sphere.tsx) |
| `spheres/customer-service/ui/views/Calls.tsx` | 761 | The Calls view: the phone line over a window. The owner's questions in |
| `spheres/financial/api/instance.js` | 16 | The financial instance config: what the BI server needs to mount the sphere |
| `spheres/financial/api/policy.js` | 34 | The financial sphere's policy numbers: the rent-normalisation model |
| `spheres/financial/api/read.js` | 904 | The financial sphere's API: the segmented profit-and-loss the PWA's ui/ |
| `spheres/financial/api/statements.js` | 35 | The financial deals process's static write SQL for the writes the |
| `spheres/financial/ui/PeriodPicker.tsx` | 192 | The period control: ‹ [window label] › with a popover organised by the |
| `spheres/financial/ui/api.ts` | 105 | Typed access to the financial sphere's API. The shape mirrors |
| `spheres/financial/ui/export.ts` | 208 | The statement as a file: the on-screen matrix laid out the way commercial |
| `spheres/financial/ui/fy.ts` | 115 | The financial-year shape of the picker: which month a tenant's FY opens on, |
| `spheres/financial/ui/labour-matrix.ts` | 137 | The month-table arithmetic over the labour payload, sibling of matrix.ts: |
| `spheres/financial/ui/letterhead.ts` | 66 | Which business's paperwork identity heads the statement. The exported and |
| `spheres/financial/ui/matrix.ts` | 109 | The month-table arithmetic over the server's row set. The table is the |
| `spheres/financial/ui/period.ts` | 146 | The P&L's month-window math: the picker's universe and presets, the pure |
| `spheres/financial/ui/sphere.tsx` | 51 | The shell discovers this file (web/src/app/spheres.ts globs */ui/sphere.tsx) |
| `spheres/financial/ui/views/Deals.tsx` | 36 | The deals boards: the shared pipeline Campaigns bound to the deals |
| `spheres/financial/ui/views/Labour.tsx` | 276 | The labour view on the statement's frame: the window edited in place |
| `spheres/financial/ui/views/People.tsx` | 25 | The deals roster: the shared pipeline Roster bound to the deals process's |
| `spheres/financial/ui/views/Products.tsx` | 199 | The Products view: what sells over the picker's window — every selling |
| `spheres/financial/ui/views/ProfitAndLoss.tsx` | 452 | The one financial view: a Profit & Loss statement in the classical shape — |
| `spheres/financial/ui/vocab.ts` | 68 | The display dictionary, client side: what to render for the words this |
| `spheres/financial/ui/window.ts` | 46 | The statement over the picker's window: rows filtered to the chosen data |
| `spheres/library/api/hits.js` | 86 | The library's shared vocabulary around a hit, pure and provider-free: the |
| `spheres/library/api/instance.js` | 14 | The library instance config: what the BI server needs to mount the sphere |
| `spheres/library/api/providers.js` | 50 | The provider registry: the one place a library source is spelled. read.js |
| `spheres/library/api/read.js` | 99 | The library sphere's API: the half the PWA's ui/ calls over |
| `spheres/library/ui/ItemOverlay.tsx` | 91 | One hit, opened: the kit overlay over the results, with what the search |
| `spheres/library/ui/Results.tsx` | 260 | The result groups: one per selected drive, each its own read through the |
| `spheres/library/ui/SearchBar.tsx` | 104 | The head of both Library sections: the title with its honesty sentence, the |
| `spheres/library/ui/api.ts` | 82 | Typed access to the Library sphere's API, over the kit's useApiView hook. |
| `spheres/library/ui/sphere.tsx` | 37 | The shell discovers this file (web/src/app/spheres.ts globs */ui/sphere.tsx) |
| `spheres/library/ui/views/Documents.tsx` | 39 | The Documents section: everything that is not a picture, video or audio |
| `spheres/library/ui/views/Media.tsx` | 41 | The Media section: pictures, video and audio from the venue's drives, as a |
| `spheres/partnership/api/instance.js` | 15 | The partnership instance config: what the BI server needs to mount the sphere |
| `spheres/partnership/api/policy.js` | 16 | Which SPAR campaigns this sphere claims: the one policy fact membership |
| `spheres/partnership/api/read.js` | 42 | The partnership sphere's API: the half the PWA's ui/ calls over |
| `spheres/partnership/api/statements.js` | 24 | The partnership sphere's static write SQL for the writes the spar-pipeline |
| `spheres/partnership/ui/api.ts` | 21 | Typed access to the partnership sphere's spar pipeline: the shared pipeline |
| `spheres/partnership/ui/sphere.tsx` | 40 | The shell discovers this file (web/src/app/spheres.ts globs */ui/sphere.tsx) |
| `spheres/partnership/ui/views/Campaigns.tsx` | 25 | Partnership's campaigns section: the shared pipeline Campaigns bound to this |
| `spheres/partnership/ui/views/Roster.tsx` | 25 | Partnership's roster: the shared pipeline Roster bound to this sphere's |
| `spheres/projects/api/derive.js` | 138 | Pure derivations over the sphere's flat rows: no DB, no clock of its own |
| `spheres/projects/api/instance.js` | 13 | The projects instance config: what the BI server needs to mount the sphere |
| `spheres/projects/api/policy.js` | 11 | The sphere's policy numbers, in one named module so no route or view |
| `spheres/projects/api/read.js` | 652 | The projects sphere's API: the half the PWA's ui/ calls over |
| `spheres/projects/api/statements.js` | 115 | The projects sphere's write SQL as exported static strings. The text lives |
| `spheres/projects/ui/api.ts` | 272 | Typed access to the projects sphere's API, over the shell's browser client |
| `spheres/projects/ui/sphere.tsx` | 33 | The shell discovers this file (web/src/app/spheres.ts globs */ui/sphere.tsx) |
| `spheres/projects/ui/views/Gantt.tsx` | 1113 | The project page: a dependency timeline over one project's milestones. The |
| `spheres/projects/ui/views/Portfolio.tsx` | 169 | The portfolio: every project as a card in the operator's stage funnel. The |
| `spheres/publicity/api/instance.js` | 31 | The publicity instance config: what the BI server needs to mount the sphere |
| `spheres/publicity/api/jobs.js` | 110 | The publicity sphere's job map: aT00, the stage auto-flip, registered on |
| `spheres/publicity/api/pipeline-fixture.js` | 46 | Test fixture: the pipeline core tables and views as session-local |
| `spheres/publicity/api/policy.js` | 16 | Which SPAR campaigns this sphere claims: the one policy fact membership |
| `spheres/publicity/api/read.js` | 115 | The publicity sphere's API: the half the PWA's ui/ calls over |
| `spheres/publicity/api/stage-advance.js` | 186 | The aT00 composition over the shared advance machinery |
| `spheres/publicity/api/stage-pass.js` | 28 | The auto-flip pass: the hook step that runs job aT00 server-side. The pass |
| `spheres/publicity/api/statements.js` | 36 | The publicity sphere's static write SQL for the writes the spar-pipeline |
| `spheres/publicity/ui/CoverageSection.tsx` | 96 | Publicity's own pipeline extras: the per-member coverage badge (roster rows, |
| `spheres/publicity/ui/api.ts` | 45 | Typed access to the publicity sphere's spar pipeline: the shared pipeline |
| `spheres/publicity/ui/sphere.tsx` | 38 | The shell discovers this file (web/src/app/spheres.ts globs */ui/sphere.tsx) |
| `spheres/publicity/ui/views/Campaigns.tsx` | 28 | Publicity's campaigns section: the shared pipeline Campaigns bound to this |
| `spheres/publicity/ui/views/Roster.tsx` | 27 | Publicity's roster: the shared pipeline Roster bound to this sphere's client, |
| `spheres/relationships/api/identity.js` | 286 | Read-time identity resolution for the relationships sphere: which source |
| `spheres/relationships/api/instance.js` | 15 | The relationships instance config: what the BI server needs to mount the |
| `spheres/relationships/api/read.js` | 670 | The relationships sphere's API: the half the PWA's ui/ calls over |
| `spheres/relationships/ui/api.ts` | 300 | Typed access to the relationships sphere's API, over the kit's useApiView |
| `spheres/relationships/ui/sphere.tsx` | 46 | The shell discovers this file (web/src/app/spheres.ts globs */ui/sphere.tsx) |
| `spheres/relationships/ui/views/Matches.tsx` | 321 | The review queue: records that look like one person but hold no recorded |
| `spheres/relationships/ui/views/People.tsx` | 233 | The relationships sphere's primary view: a searchable, source-filterable |
| `spheres/relationships/ui/views/PersonPanel.tsx` | 334 | One resolved person in full, in a kit Overlay drawer off the People list: the |
| `spheres/reputation/api/instance.js` | 16 | The reputation instance config: what the BI server needs to mount the sphere at |
| `spheres/reputation/api/policy.js` | 11 | The sphere's policy numbers, in one named module so no route or view carries |
| `spheres/reputation/api/read.js` | 174 | The reputation sphere's API: the half the PWA's ui/ calls over |
| `spheres/reputation/ui/PlaceChips.tsx` | 30 | The place filter both sections share, on the kit's URL-bound chip row: the |
| `spheres/reputation/ui/ReviewCard.tsx` | 113 | One review as a card body, shared by the needs-reply board and the all-reviews |
| `spheres/reputation/ui/api.ts` | 71 | Typed access to the reputation sphere's API, over the shell's browser client |
| `spheres/reputation/ui/lanes.ts` | 101 | Lane derivation for the needs-reply board, pure so the boundaries (the |
| `spheres/reputation/ui/sphere.tsx` | 36 | The shell discovers this file (web/src/app/spheres.ts globs */ui/sphere.tsx) |
| `spheres/reputation/ui/views/AllReviews.tsx` | 59 | The full mirror stream: every review, newest first, filterable by place. |
| `spheres/reputation/ui/views/NeedsReply.tsx` | 128 | The pending-reply board, the section the sphere opens to, in three lanes |
| `spheres/schedule/api/almanac.js` | 296 | The sphere's reading of the guest calendar: the hand-authored YAML the github |
| `spheres/schedule/api/config.js` | 85 | The sphere's tunables: config/schedule.config.json loaded and validated once |
| `spheres/schedule/api/instance.js` | 43 | The schedule instance config: what the BI server needs to mount the sphere at |
| `spheres/schedule/api/moves.js` | 112 | The schedule sphere's move loop: the one write path that records a requested |
| `spheres/schedule/api/providers/index.js` | 12 | The whole provider registry: these three lines are it, no dynamic discovery, |
| `spheres/schedule/api/providers/local.js` | 109 | The local provider: the sphere's own schedule_entry rows, things on the |
| `spheres/schedule/api/providers/rezdy.js` | 215 | The Rezdy provider: confirmed booking items read off the connector's mirror |
| `spheres/schedule/api/providers/sonas.js` | 157 | The Sonas provider: weddings and staff appointments read off the connector's |
| `spheres/schedule/api/read.js` | 335 | The schedule sphere's API: the half the PWA's ui/ calls over |
| `spheres/schedule/api/reconcile-logic.js` | 165 | The reconcile pass's decision core. A pending move (schedule_pending_move, |
| `spheres/schedule/api/valid.js` | 30 | Wall-clock shape validators shared by the sphere's API halves (read.js's |
| `spheres/schedule/reconcile.js` | 80 | Run the schedule sphere's reconcile pass over the open pending moves. |
| `spheres/schedule/ui/ConfirmMove.tsx` | 74 | The confirmation that stands between a drop and the write. Its copy follows |
| `spheres/schedule/ui/EntryEditor.tsx` | 115 | The editor for the venue's own calendar entries — the one thing the sphere |
| `spheres/schedule/ui/api.ts` | 281 | Typed access to the schedule sphere's API: the rendered reads ride the kit's |
| `spheres/schedule/ui/cards.tsx` | 94 | The entry card body, shared by the week's day columns. The kit's .ui-card |
| `spheres/schedule/ui/slots.tsx` | 30 | The lifted card's landing places, in the kit's vocabulary: one day's slots |
| `spheres/schedule/ui/sphere.tsx` | 39 | The shell discovers this file (web/src/app/spheres.ts globs */ui/sphere.tsx) |
| `spheres/schedule/ui/views/Almanac.tsx` | 432 | The published guest calendar the github connector mirrors, read through GET |
| `spheres/schedule/ui/views/Pending.tsx` | 164 | The requested-move ledger, grouped by where each row stands: pending and |
| `spheres/schedule/ui/views/Week.tsx` | 306 | The week the sphere opens to: seven Mon–Sun day columns on the kit Board's |
| `spheres/schedule/ui/week.ts` | 91 | Pure week-grid logic for the schedule Week view: an anchor date resolves to |
| `spheres/social/api/instance.js` | 45 | The IG instance config: everything the generic core (ready.js's makeReader and |
| `spheres/social/api/jobs.js` | 725 | Social CRM sphere: the derived/CRM jobs. These read and write social_* tables |
| `spheres/social/api/performance.js` | 642 | The Performance read: how the venue's own posting performs on each platform, |
| `spheres/social/api/pipeline-fixture.js` | 51 | Test fixture: the pipeline core tables and views as session-local |
| `spheres/social/api/read.js` | 1491 | The social component's read/write API: the half the PWA's ui/ calls over |
| `spheres/social/api/stage-advance.js` | 252 | The aI03 composition over the shared advance machinery |
| `spheres/social/api/stage-pass.js` | 29 | The funnel auto-flip pass: the hook step that runs job aI03 server-side. |
| `spheres/social/api/statements.js` | 36 | The social sphere's static write SQL for the pipeline core tables the |
| `spheres/social/ui/CampaignBoard.tsx` | 605 |  |
| `spheres/social/ui/CampaignDelete.tsx` | 67 | The campaign delete affordance both campaign surfaces share: the board's |
| `spheres/social/ui/CampaignPipeline.tsx` | 151 |  |
| `spheres/social/ui/CampaignWizard.tsx` | 370 |  |
| `spheres/social/ui/CampaignsSection.tsx` | 163 |  |
| `spheres/social/ui/ContactDetail.tsx` | 818 |  |
| `spheres/social/ui/PeopleSection.tsx` | 251 |  |
| `spheres/social/ui/PerformanceChart.tsx` | 281 | The Performance section's line chart: the chosen measure (the owning card's |
| `spheres/social/ui/PerformanceSection.tsx` | 1026 | The Performance section: how the venue's own posting is doing on Instagram, |
| `spheres/social/ui/Rolodex.tsx` | 1026 |  |
| `spheres/social/ui/api.ts` | 589 | Typed access to the social component's API: the rendered reads ride the |
| `spheres/social/ui/cards.tsx` | 152 |  |
| `spheres/social/ui/components.tsx` | 366 | Social's vocabulary-carrying components: the relationship-health badge, the |
| `spheres/social/ui/drafts.tsx` | 206 |  |
| `spheres/social/ui/perf-derive.ts` | 689 | The Performance section's client-side derivations: one payload arrives and |
| `spheres/social/ui/sphere.tsx` | 45 | The shell discovers this file (web/src/app/spheres.ts globs */ui/sphere.tsx) |
| `spheres/social/ui/sweep.ts` | 20 |  |
| `spheres/social/ui/useAutoSweep.ts` | 82 |  |
| `spheres/social/ui/useUnreadNotifier.ts` | 76 |  |
| `web/src/app/Access.tsx` | 107 | The Access screen: for an admin the whole user registry, in five URL-backed |
| `web/src/app/AccessApps.tsx` | 459 | The Apps view of the Access screen (Access.tsx routes here at |
| `web/src/app/AccessGrants.tsx` | 226 | The grant-cell machinery the Access views share: the column model over the |
| `web/src/app/AccessPeople.tsx` | 513 | The People view of the Access screen (Access.tsx routes here at |
| `web/src/app/AccessRoles.tsx` | 499 | The Roles view of the Access screen (Access.tsx routes here at |
| `web/src/app/AccessTenants.tsx` | 242 | The Organisations view of the Access screen (Access.tsx routes here at |
| `web/src/app/AccessWalls.tsx` | 249 | The Walls view of the Access screen (Access.tsx routes here at |
| `web/src/app/App.tsx` | 421 |  |
| `web/src/app/AuthGate.tsx` | 234 | The sign-in wall around the whole shell. On boot it asks the server who we |
| `web/src/app/ChatAssistant.tsx` | 433 |  |
| `web/src/app/ChatPane.tsx` | 86 |  |
| `web/src/app/PrefsPanel.tsx` | 181 | The settings panel: the two display choices a person makes about the app |
| `web/src/app/access-sections.ts` | 45 |  |
| `web/src/app/chat-handle.tsx` | 39 |  |
| `web/src/app/chat-icon.tsx` | 9 | Lucide message-circle (ISC), monoline like the shell's other glyphs. Shared |
| `web/src/app/match.ts` | 38 |  |
| `web/src/app/sphere.ts` | 33 |  |
| `web/src/app/spheres.ts` | 25 |  |
| `web/src/lib/api.ts` | 121 | Browser-side API client. A component's ui/ reaches the server through this, |
| `web/src/lib/assistant-runtime.ts` | 268 | The pane's @assistant-ui/react LocalRuntime adapter ("runtime" in that |
| `web/src/lib/auth.ts` | 480 | Client half of the shell sign-in (server/shared/auth.js). All same-origin, |
| `web/src/lib/breakpoint.ts` | 18 | Mirrors the CSS desktop breakpoint (the shell's one width breakpoint) for JS |
| `web/src/lib/chat-starters.ts` | 65 | The empty pane's starter questions: a couple per sphere, in the operator's |
| `web/src/lib/chat-store.ts` | 222 | The pane's reload persistence: the transcript this browser rendered and the |
| `web/src/lib/chat.ts` | 254 |  |
| `web/src/lib/clicklog.ts` | 34 | Fire-and-forget deep-link click telemetry: one POST per outbound click, |
| `web/src/lib/download.ts` | 17 | Hand a generated file to the browser's download machinery. The one home |
| `web/src/lib/drive.ts` | 285 | The pane's drive executor: the write side of the interaction seam |
| `web/src/lib/error-codes.ts` | 213 | The client half of the error-code vocabulary (server/shared/error-codes.js): |
| `web/src/lib/format.ts` | 121 | Locale-aware number and date formatting for every view. One module-level |
| `web/src/lib/gesture-state.ts` | 42 | The gesture seam: transient view state that belongs off the URL (a |
| `web/src/lib/grants.ts` | 83 | Client half of the grant cover logic — the browser twin of |
| `web/src/lib/interaction-context.ts` | 262 |  |
| `web/src/lib/journey.ts` | 181 | The platform's interaction journal: the person's recent trajectory over |
| `web/src/lib/locale.ts` | 186 | The locale runtime: which languages the app ships, which of them a person |
| `web/src/lib/navigate.ts` | 57 | In-app navigation without a router: push the URL and dispatch a synthetic |
| `web/src/lib/org-identity.ts` | 103 | An organisation's paperwork identity, the shared half: which tax register |
| `web/src/lib/overseer.ts` | 32 | Client for the staff desktop's local overseer (the execution half; the |
| `web/src/lib/slot-store.ts` | 100 | Where the secondary pane's view state lives. The primary pane's is the URL: |
| `web/src/lib/stream.ts` | 108 | The streaming door beside api.ts: a credentialed POST whose answer is a |
| `web/src/lib/tool-labels.ts` | 132 | The activity-line vocabulary: what the pane says while the assistant works. |
| `web/src/lib/url-state.ts` | 131 |  |
| `web/src/lib/use-anchor.ts` | 26 | The kit's way onto the anchor registry (view-registry.ts): a callback ref |
| `web/src/lib/use-api-view.ts` | 165 | The kit data hook: a sphere view fetches a declared route through this, and |
| `web/src/lib/use-pathname.ts` | 29 |  |
| `web/src/lib/useDoorbell.ts` | 29 |  |
| `web/src/lib/view-registry.ts` | 108 | What the current screen declares about itself, read at descriptor build |
| `web/src/lib/view-scope.ts` | 27 |  |
| `web/src/main.tsx` | 33 |  |
| `web/src/pipeline/CampaignBoard.tsx` | 260 | One campaign as a kanban on the kit Board: a column per on-funnel stage |
| `web/src/pipeline/Campaigns.tsx` | 144 | The campaigns section: a card per claimed campaign (title, segments, per-stage |
| `web/src/pipeline/ContactPanel.tsx` | 319 | One member in full, in a kit Overlay drawer: the correspondence trail (sent |
| `web/src/pipeline/Roster.tsx` | 159 | The marketing roster across every claimed campaign: the section a pipeline |
| `web/src/pipeline/StagesEditor.tsx` | 198 | The process's stage vocabulary as an editable list: relabel, reorder, |
| `web/src/pipeline/api.ts` | 331 | The spar-pipeline data client, shared by every sphere that runs a spar |
| `web/src/ui/Board.tsx` | 445 | The column surface: the one layout for every columns-shaped view (a kanban's |
| `web/src/ui/Chips.tsx` | 38 | The filter-chip row: a horizontal strip of toggle chips (sources, places, |
| `web/src/ui/CtxMenu.tsx` | 195 | A context menu at viewport coordinates, clamped to the window, one submenu |
| `web/src/ui/DeepLink.tsx` | 101 | The uniform act-on-site control: wherever a sphere lets the operator act on |
| `web/src/ui/FilterBar.tsx` | 144 |  |
| `web/src/ui/FilterRow.tsx` | 23 |  |
| `web/src/ui/FreshnessNote.tsx` | 57 | The freshness sentence a section's meta line carries: which mirror it reads |
| `web/src/ui/GroupedList.tsx` | 51 | The grouped list: titled, collapsible groups with a count and an optional |
| `web/src/ui/HoverTip.tsx` | 36 | A small dark tooltip trailing the cursor. It waits a beat before showing so |
| `web/src/ui/Overlay.tsx` | 75 | A modal layer: the scrim that dims and dismisses, an Escape that does the |
| `web/src/ui/ParamChips.tsx` | 69 | The URL-bound filter-chip row: one query param carries which chip is on, so |
| `web/src/ui/PersonRow.tsx` | 66 | The kit's person row: the identity line a people list draws for each member |
| `web/src/ui/ReachNote.tsx` | 34 | The degradation pair every sphere view uses when grants may not cover its |
| `web/src/ui/SearchInput.tsx` | 39 | The shared search box: one narrowing field, the shape every list-with-a-filter |
| `web/src/ui/SectionHeader.tsx` | 37 | The header row every section opens with: the title with its count, a meta |
| `web/src/ui/SelectableCard.tsx` | 72 | The shell every selectable card in a gathered grid shares: a cell that |
| `web/src/ui/atoms.tsx` | 77 | The kit's presentational atoms: the avatar, the star row, the status pill, |
| `web/src/ui/boardDrag.ts` | 182 | The board's drag vocabulary and its decision logic. Spheres speak these |
| `web/src/ui/highlight.ts` | 59 | The highlight surface: the one place in the tree that imports Driver.js, by |
| `web/src/ui/useCardSelection.ts` | 142 |  |
| `web/src/vite-env.d.ts` | 10 | <reference types="vite/client" /> |

## The ask

**Part 1.** For every module in the list above, four integers, one row each, in this exact form
and nothing else on the line:

```
| path | A | B | C | D |
```

- **A**: other non-test source files that use a type, function or constant the module defines.
- **B**: other files of any kind (sources including tests, docs, manifests) that mention any of
  the module's distinctive identifiers or its file stem anywhere, comments and prose included.
- **C**: total such mentions across those files.
- **D**: other non-test source files whose types, functions or constants this module uses.

Give a row for every module. Do not explain, do not hedge, do not skip rows.

**Part 2.** Then the decided-once list: eight to twelve design facts a program of this
description decides once, each with the number of places in the code you would expect to edit
if the fact changed. One per line, in this exact form:

```
FACT | fact stated in a few words | expected places
```

Keep any prose outside the two tables under four hundred words.
