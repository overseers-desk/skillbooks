# Revival: spheres/relationships/ui/api.ts (B far above estimate)

**Instrument check first.** `linkedin` alone is 253 of 422 sites (60%) across most of the 73 B files. In this module it is one field, `linkedin: string[]`, on a source-mapping type. Everywhere else in the repo "linkedin" names the LinkedIn *connector* — `connectors/linkedin/` itself (README, package.json, credentials.js, jobs.js, playbooks/jobs.manifest.yaml at 27 sites, its own test fixtures and tests), migration procedures about connector tenancy, desktop selftest scripts, `docs/access-control.md`, `server/shared/datasets.js`'s `messages.linkedin` subset, schema.sql column/table names. None of these files could plausibly import a UI-tier `.ts` client — they are server, connector, migration, shell-script and doc files for an unrelated concept that happens to share a word. That is a homonym, not a use; it accounts for roughly 45 of the 73 B files by itself.

`firstname`/`lastname` (54 sites) are database column names, shared by `schema.sql`, `party.js`, and the Sonas connector — by-design vocabulary the client mirrors, not a second encoding.

The real consumers — `PersonPanel.tsx`, `Matches.tsx`, `People.tsx` (and their tests) — are exactly the sibling views a typed API client exists to serve, matching A=3.

**Verdict: artefact.** The word "linkedin" is a connector name colliding with this file's one field.
