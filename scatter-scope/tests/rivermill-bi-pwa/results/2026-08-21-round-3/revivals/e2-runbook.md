# Revival: server/shared/runbook.js — B miss

**Instrument check first.** Vocabulary is 5 names; `runbook` alone carries 260/311 sites
(84%) — one word is doing the work. Walking its 60 carriers: a handful are real JS callers
of `loadRunbook`/`resolveRunbook` (ready.js, anthropic.js, ollama.js, deepseek.js,
model-api.js, stage-advance.js in social/publicity) — legitimate use, feeding A, not B
noise. The rest split into: (a) docs describing the runbook system and the actual
`spheres/*/runbooks/*.md` files themselves (docs/runbook.md, job-execution.md,
overseer-protocol.md, per-sphere docs/reads.md, runbook markdown files) — prose about, and
instances of, the concept; (b) `jobs.manifest.yaml` and `schema.sql` files declaring a
runbook field/column — config and schema, not code; (c) a full sibling **Tcl** desktop
client (`runbook-loader.tcl`, `runbook-runner.tcl`, `job_board.tcl`, `server-client.tcl`,
`ollama-runner.tcl`, `config.tcl`, its selftest) that independently loads and runs
runbooks in a different runtime that cannot import this JS module.

None of the 60 restate the module's state in fields of their own at this layer — they are
prose, manifest/schema declarations, or a sibling-tier reimplementation, exactly the
excluded categories. `runbook` is the product's own domain word for what this file loads;
it is read widely because that is its job.

**Verdict: by design.**
