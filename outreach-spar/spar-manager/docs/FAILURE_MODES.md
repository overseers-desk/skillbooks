# spar-manager failure modes

A catalog of harness/dispatch failure modes observed in real runs, each with a
trace path (session IDs) so a later session diagnoses from the record instead of
re-deriving it. Open modes carry an issue number; fixed modes carry the commit
that closed them. Add to it; do not let the same mode be rediscovered from scratch.

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

## Open

### FM-HARNESS-4 — early external SIGKILL of first-wave workers (cause unidentified) · issue #136

**Symptom.** Several of the first concurrently-launched workers are SIGKILLed ~70-83s in,
mid-turn, with no error envelope; replacement workers launch immediately and survive.

**Cause.** Unknown. Held open deliberately rather than guessed.

**Ruled out (with evidence):**
- The 1800s timeout — deaths at 67-83s, far short of the cap.
- Kernel OOM — `journalctl -k` over the window shows no OOM/killed-process lines.
- Userspace OOM — `systemd-oomd` is active but logged zero kills that day.
- CPU/memory contention — load average 3.99 on 8 cores (~50%); 13Gi RAM free.

**Evidence.** Four sessions (30656bff, 2d6fe635, b688ebf0, 73268a63) all end in a 7-second
window (06:18:25-32 UTC), last event a tool_result with no following turn, no result
object, no `stop_reason`. Launch was staggered: 4 workers started ~16:17:08-18, the
remaining started ~16:18:33+ — and it was exactly the first-started 4 that died.

**Hypotheses not yet tested:** a one-time ramp-up resource transient at first 10-wide
cold-start; a concurrent-session limit; a dispatcher/tpool teardown step. Distinguishing
them needs the real exit code, which the harness now logs (FM-HARNESS-1 is fixed), so the
next occurrence records the actual signal.

### FM-AGENT-1 — no stop test; last tool result treated as the next prompt · issue #135

**Symptom.** After the deliverable is written, the agent keeps acting — here, four minutes
of `git diff`/`git log` archaeology — until an external kill stops it. The run-tail looks
like a hang but is a self-sustaining loop.

**Cause (agent self-reconstruction, ed9357e7).** The agent finished the profile + roster,
ran `git add`, saw `roster.tsv` show no diff (because a concurrent process owns commits —
see FM-REPO-1), and that surprise "spawned a fake question" which it then chased. Its own
words: *"I treat the last tool result as the prompt, not the task spec as the boundary.
After the Write succeeds, there's no internal 'halt' fired"* and *"there was no problem — I
manufactured one"* (NSWP). The deliverable contract (file + roster on disk) was met but
never bound to "done", so a proxy ("is it committed?") substituted for the terminator.

**Proposed terminator (from the same transcript):** after on-disk verification, apply one
test — *does the next observation change any action I would take?* Once no, stop. This
belongs in SPAR-P (the methodology and the profile prompt), not the harness.

**Caveat.** This is the same model reconstructing its behaviour after the fact, not an
independent witness; treat the mechanism as a strong hypothesis, not a logged fact.

**Note.** The harness now judges by the on-disk product (FM-HARNESS-2 fixed), so the loop
no longer loses the deliverable; the wasted wall-clock and cost remain.

### FM-REPO-1 — concurrent git HEAD movement during a run (observed) · issue #137

**Symptom.** During the run, the campaign repo's HEAD moved forward and then back (a commit
appeared, then HEAD returned to its prior position) without the worker committing — visible
to a worker's `git` calls and a source of confusion (it fed FM-AGENT-1).

**Cause.** Not confirmed. Some process commits (and possibly resets) the campaign repo while
workers run; roster writes are guarded by `.roster.lock`, but git operations are not. Whether
it is an intended dispatcher auto-commit or workers racing each other is unverified.

**Next step.** Identify what commits/resets the repo during a run before relying on git state
mid-run; a reset could discard a worker's working-tree edits.

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
was lost. `_invoke` now records real elapsed and the true exit code, and reserves the timeout
wording for an elapsed wall-clock that reached the cap.

### FM-HARNESS-2 — completed deliverable discarded when killed before the result · `111f548`

The verdict hinged on the claude envelope, not the deliverable: `--output-format json` emits
one object only at turn end, so a kill before it left an empty/truncated file that `_invoke`
treated as failure, and `ProfileHarness::run` short-circuited before validating the disk
product. A complete, valid profile was reported FAIL and would have been lost had the kill
landed during the write (ed9357e7: profile written 16:44, killed 16:48:33, logged FAIL).
`_invoke` now requests `--output-format stream-json` and returns 2 (incomplete) when no result
object closed the turn; `ProfileHarness::run` validates the on-disk product on 2, so a
completed-but-killed profile lands DONE. Shared `_invoke` covers both CLI and GUI.

### FM-HARNESS-3 — blanket wall-clock cap kills long sessions · mitigated by `111f548`

The 1800s cap had no awareness of whether the deliverable was done; SPAR-P §6's sequential
social fetches (~15 min) put a thorough profile near the cap. With the product-based verdict
(FM-HARNESS-2), a cap-kill of a completed profile now lands DONE and a partial one resumes the
captured session, so the cap no longer destroys work. Residual — the cap value, and the loop
that inflated the tail — is tracked under FM-AGENT-1 (#135). Not separately filed.

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
