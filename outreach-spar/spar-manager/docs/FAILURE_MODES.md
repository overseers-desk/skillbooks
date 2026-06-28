# spar-manager failure modes

A catalog of harness/dispatch failure modes observed in real runs, each with a
trace path (session IDs) so a later session diagnoses from the record instead of
re-deriving it. Open modes carry an issue number; fixed modes carry the commit
that closed them; operational caveats record conditions outside the tooling's
control. Add to it; do not let the same mode be rediscovered from scratch.

## How to trace a run

Three artifact layers, in increasing detail:

1. **Orchestration stream** (`[START]`/`[DONE]`/`[FAIL]`/`Validation failed`/`[phase]`
   lines). The transition CLI persists the dispatch-level part (`spar::transitions`
   and `spar::dispatch`) to `<logs_root>/orchestration-<stem>-<datestamp>.log` for any
   real (non-dry) run, and also writes it to stderr. Per-row worker (`spar::harness`)
   lines run in separate tpool interps and are not in that file; they live in the
   per-row artifacts below. Other entry points (GUI, a manual run) capture the stream
   only if launched with redirection (`… > run.log 2>&1`, or `| tee`).
2. **Per-row harness artifacts**: `<logs_root>/<run-slug>/<stem>-profile.log.json`
   (the claude stream-json transcript), `<stem>-profile.log.stderr`, `<stem>-cost.jsonl`,
   `<stem>-fixN.log`. `<run-slug>` is the campaign path slug + `-p-<YYYYMMDD-HHMMSS>`
   (launch second). Written regardless of who launches the run. `<logs_root>` is
   `/var/local/log/spar` when present, else `~/logs/spar` (see `spar::logs_root`).
3. **Per-row claude transcript** (richest): `~/.claude/projects/<campaign-cwd-slug>/<session-id>.jsonl`.
   One JSONL per worker session, every tool call and message. Written regardless of
   `--output-format`. This is where killed-before-result work is still visible.

`<session-id>` is the claude session UUID. The harness captures it from the first
stream-json event (the init event), so it is available even for a killed row; to find
a transcript directly, match by mtime within the run window and confirm by content.

## Reference run

2026-06-14, T1 (profiling), `--jobs=10`, launched 16:16:59 (log-dir suffix
`-p-20260614-161659`). 113 tasks; stopped mid-run. Five worker sessions failed in two
distinct ways; their UUIDs key the entries below.

| session-id | stem | failure mode |
|---|---|---|
| ed9357e7-6a04-429b-83e5-5a2da5201971 | nicole-my-forever-weddings | FM-AGENT-1 (loop) + FM-HARNESS-2 (discard) + FM-HARNESS-3 (1800s kill) |
| 30656bff-00f3-4f75-be07-0f1b6c40ed08 | lara-galanthia | FM-HARNESS-4 (early SIGKILL) + FM-HARNESS-1 (mislabel) |
| 2d6fe635-a486-4de5-9cee-03ef603d12fb | jolanda-tarifa-events | FM-HARNESS-4 + FM-HARNESS-1 |
| b688ebf0-00e0-4eec-a4c0-872a3e25649b | juan-medinas | FM-HARNESS-4 + FM-HARNESS-1 |
| 73268a63-6f32-48d7-8db4-a32d83e45d86 | maria-jose-que-se-besen | FM-HARNESS-4 + FM-HARNESS-1 |

---

## Fixed

### FM-HARNESS-0 — `missing_profile` gate rejected legitimate exclusions · `bab6ca7`

`validate_profile_errors` returned `missing_profile` for any row ending without a profile
file, with no exception for an excluded contact. SPAR-P §5.4 requires an excluded contact to
have *no* profile, so the spec-correct terminal state (date_excluded set, no profile) was
exactly what the gate rejected; an excluded row oscillated and failed after three retries.
The gate now reads the roster row first and treats an absent file next to a `date_excluded`
row as the correct outcome. Seen on `ana-c-anaceventos` and `anna-ambrosiewicz-ambrosia-wedding`
in the 2026-06-14 14:07 run.

### FM-HARNESS-1 — `timeout after 1800s` mislabel · `111f548`

`_invoke` branded any wrapped exit code in {124,125,137} as the configured timeout regardless
of elapsed time (uutils `timeout` emits 125 for its own failures and 137 for a SIGKILL), so a
non-timeout death was reported as a timeout and the real exit code — the actual diagnostic —
was lost. `_invoke` now records real elapsed and the true exit code. (The wrapped-timeout path
this entry fixed was later removed entirely — `78b6e2d` — leaving the per-worker cost cap as the
sole budget bound.)

### FM-HARNESS-2 — completed deliverable discarded when killed before the result · `111f548`

The verdict hinged on the claude envelope, not the deliverable: `--output-format json` emits
one object only at turn end, so a kill before it left an empty/truncated file that `_invoke`
treated as failure, and `ProfileHarness::run` short-circuited before validating the disk
product. A complete, valid profile was reported FAIL and would have been lost had the kill
landed during the write (ed9357e7: profile written 16:44, killed 16:48:33, logged FAIL).
`_invoke` now requests `--output-format stream-json` and returns 2 (incomplete) when no result
object closed the turn; `ProfileHarness::run` validates the on-disk product on 2, so a
completed-but-killed profile lands DONE. Shared `_invoke` covers both CLI and GUI.

### FM-HARNESS-3 — blanket wall-clock cap kills long sessions · mitigated by `111f548`, cap removed by `78b6e2d`

The 1800s cap had no awareness of whether the deliverable was done; SPAR-P §6's sequential
social fetches (~15 min) put a thorough profile near the cap. The product-based verdict
(FM-HARNESS-2) first defanged it — a cap-kill of a completed profile lands DONE and a partial
one resumes the captured session — and `78b6e2d` then removed the wall-clock cap altogether,
leaving the per-worker cost cap as the sole budget bound. The loop that inflated the tail is
tracked under FM-AGENT-1 (#135).

### FM-HARNESS-5 — no metadata recovery path on a killed session · `111f548`

`session_id` and `cost` were read only from the final JSON envelope, so a kill lost both even
though the transcript existed. With `--output-format stream-json`, `_extract_session_id` reads
`session_id` from the first (init) event, so it survives a kill and the fix loop can resume the
session. `cost` is in the final result line and is still unrecorded on a kill (the transcript
retains per-turn usage if needed).

### FM-LOG-1 — orchestration log not persisted · `73dcfae`

The `spar::transitions` / `spar::dispatch` services emitted only to stderr, so a run launched
without shell redirection left no on-disk record of its outcomes. `spar::install_orchestration_log`
tees those services to `<logs_root>/orchestration-<stem>-<datestamp>.log`, installed by the
transition CLI for real (non-dry) dispatch. Per-row worker lines are not captured there (see
"How to trace").

### FM-AGENT-1 — profiling agent had no stop test · `3a0c802`

The §4 procedure ran §4.1–§4.15 with no terminal condition, so after the deliverable (profile
file + matched roster row) was on disk the agent treated the next tool result as a new prompt
and kept working — git archaeology in the observed case (ed9357e7) — until the wall-clock cap
killed it. Its own reconstruction: *"I treat the last tool result as the prompt, not the task
spec as the boundary… there was no problem — I manufactured one."* New SPAR-P §4.16 binds done
to the deliverable, adds the test "would the next action change the profile or roster? if not,
it is outside this task", and bars touching version control (the trigger that fed the loop and
linked it to FM-REPO-1). The existing imperatives were left untouched as correctness invariants.
Self-diagnosis caveat: the mechanism is the model reconstructing itself, not an independent
witness; the fix stands on the missing-boundary fact regardless. Behavioural confirmation (the
agent actually stopping) awaits a live run.

---

## Operational caveats (not code defects)

### FM-REPO-1 — concurrent git operations on the campaign repo during a run

spar-manager performs no git operations: there is no commit/reset/add anywhere in the tooling,
and the SPAR-P methodology and prompts do not instruct the agent to commit (verified by grep).
So any commit or reset on the campaign repo during a run comes from outside spar-manager — a
parallel session, a manual command, or an automation on the same checkout.

Nothing in spar-manager code can prevent this, but it carries a real risk: a concurrent
`git reset --hard` discards uncommitted working-tree edits, which is exactly what a run is
producing (roster.tsv, profile files). Do not commit or reset the campaign repo while a run is
active. Observed in the 2026-06-14 run as HEAD moving forward then back; it also fed the agent
loop in FM-AGENT-1 (the worker saw a confusing git state and chased it). Filed then closed as
not-a-code-bug: #137.

### FM-HARNESS-4 — first-wave workers SIGKILLed ~75s in (external, unidentified)

In a jobs=10 run, four of the first-launched workers were SIGKILLed 67-83s in, mid-turn, with no
error envelope; replacements launched immediately and survived. spar-manager has no code path
that kills a running worker (verified by reading the dispatch/pool machinery): `idletime=60`
evicts only idle workers, `cancel` is a cooperative sentinel, the `timeout` wrap (the one in
place during this run, since removed — `78b6e2d`) fired only at 1800s, and the chromium
`flock`/`timeout` runs inside the agent's bash. So the kill came from
outside the tooling — same class as FM-REPO-1.

Ruled out: the 1800s cap (deaths too early), kernel OOM (`journalctl -k` clean), userspace OOM
(`systemd-oomd` zero kills), CPU/memory contention (load 3.99/8 cores, 13Gi free). Cause
unidentified; the honest exit code is now logged (FM-HARNESS-1 fixed), so a recurrence records
the real signal. Sessions: 30656bff, 2d6fe635, b688ebf0, 73268a63 (2026-06-14 run). Filed then
closed as not-a-code-bug: #136.
