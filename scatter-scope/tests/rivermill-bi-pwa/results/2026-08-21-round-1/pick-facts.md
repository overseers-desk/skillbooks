# Pick table — decided-once facts

Expected places are the estimators' blind guesses (`-` where an estimator did not name the fact); the expectation is their median. Measured is the grep given in the last column, over the same corpus as Count. Gap is log3(measured files / expected).

| fact | e1 | e2 | e3 | expected (median) | measured files | sites | gap | flag | probe |
|---|--:|--:|--:|--:|--:|--:|--:|---|---|
| Multi-tenant scoping: the tenant dimension and its enforcement | 40 | 8 | 4 | 8 | 306 | 5560 | +3.32 | scattered | `\btenant\b` over the corpus (the registry's own tables — tenant_member/tenant_group/.tenancy — are 31 files, 222 sites) |
| Dataset / grant vocabulary a route or token may name | 15 | 6 | 3 | 6 | 104 | 745 | +2.60 | scattered | `datasets?\.(js|json)|DATASETS|datasetOf|\bdataset\b`; `parseGrants|grantsOf|\bgrants\b` alone is 98 files / 753 sites |
| Mirror-table upsert convention (first_seen_at / last_seen_at) | - | 10 | 6 | 8 | 46 | 380 | +1.59 | scattered | `first_seen_at|last_seen_at` |
| Connector mirror-table name prefix (connector_*) | 20 | - | - | 20 | 89 | 194 | +1.36 | scattered | `connector_[a-z]` |
| Route-declaration contract every sphere/connector publishes (handleApi) | 10 | 5 | 3 | 5 | 55 | 407 | +2.18 | scattered | `handleApi` |
| Machine error-code vocabulary and its wire shape | 2 | 4 | 3 | 3 | 34 | 94 | +2.21 | scattered | `error-codes|ERROR_CODES|errorCode` |
| URL-as-state convention for filters and windows | 15 | - | 8 | 11.5 | 24 | 100 | +0.67 |  | `useUrlParam|useStringParam|writeParam|readRaw` |
| Doorbell / SSE "poll now" event shape | - | 4 | - | 4 | 32 | 117 | +1.89 | scattered | `doorbell|Doorbell` |
| Wall (secrecy circle) enforcement semantics | - | - | 3 | 3 | 20 | 95 | +1.73 | scattered | `\bwalls?\b` in a circle/secrecy sense, `wallId`, `wall_id` |
| Pipeline stage vocabulary | - | 6 | - | 6 | 13 | 17 | +0.70 |  | `stage-vocabulary|stageVocab|STAGES\b|stage_key` |
| Venue-local timezone and calendar arithmetic | 5 | 5 | 2 | 5 | 4 | 5 | -0.20 |  | `Australia/Sydney` |
| Passwordless email sign-in mechanism | 3 | 3 | 2 | 3 | 64 | 145 | +2.79 | scattered | `sign-?in|signIn|login_code|sendMail` |
| Connector HTTP transport: plain node:https, no vendor SDK | - | 14 | 12 | 13 | 3 | 3 | -1.33 | hidden | `require('node:https')|from 'node:https'|require('https')` |
| Product working name "bibi" pending the marketing rename | 30 | - | - | 30 | 2 | 3 | -2.46 | hidden | `\bbibi\b` |
