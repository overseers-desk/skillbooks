# Revival: server/shared/auth.js (A low)

**Instrument check first.** A=3 is what a static import-graph index sees, and I found the same 3 by grep: `access.js` (`import { enforced }`), `chat.js` (`import * as auth`), and `migration/grants-normalisation/probe.mjs` (`import { grantsFor }`). But `server/app.js` — the file with the heaviest real usage in the data (17 sites: `principalFor` ×12, `machineBearer` ×2, `handleAuthApi`, `sessionEmail`, `upsertUser`) — reaches auth.js only through `import('./shared/auth.js')` inside a single `Promise.all` boot bundle that dynamically loads the *entire* `server/shared/` tier (db.js, ready.js, contract.js, auth.js, party.js, chat.js, tenancy.js, … all in that one call). A static index cannot see it. So A=3 is not the truth about consumers; it is the index's blind spot on app.js, which is `principalFor`'s "one resolver every gate reads" — every request touches auth.js's behaviour through app.js's dispatch seam, not through import.

Separately, the 28 `startMs` sites across connector `sync.js` files are a false trail: each is an unrelated local variable, not a reference to `auth.js`'s internal `settleFloor(startMs)`.

Same app.js dynamic-bundle blind spot explains the whole family (access.js, contract.js, http-json.js, ready.js) — one mechanism, one cause.

**Verdict: artefact.**
