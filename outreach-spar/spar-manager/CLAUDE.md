# spar-manager

## Invariants

**One dispatch pipeline.** The CLI (`spar-transition.tcl`) and the Tk GUI (`spar-ui.tcl`) execute transitions through the same objects: `::spar::transitions::get $tid` → the class's `prepare_for_pool` → the shared `spar::Dispatcher` → the worker proc named in the rows (a row's opts may carry `worker_proc`, overriding the batch default). A send path reachable from only one front-end must not exist. External side-effects (SES SMTP, the overseer's `POST /run`) live in worker procs and their `*_one.tcl` helpers, never in front-end code. Changing the `prepare_for_pool`/row contract or a per-kind cap means changing both consumers in the same commit: `dispatch_ready` in `spar-transition.tcl` and `_enqueue_prepared` in `ui/dispatch-controller.tcl`, plus the cap installs beside each front-end's Dispatcher construction.

**LinkedIn sends go through the overseer.** The T6 linkedin leg (`transitions/linkedin_send_one.tcl`) talks to the overseer on `127.0.0.1:11402` (`POST /run`; contract in `docs/overseer-protocol.md` of the overseer's repository). spar never launches a browser for sends, never calls browser-serialiser directly for sends, and never implements its own LinkedIn pacing: cadence belongs to the overseer's per-host rate gate, and a client-side delay on top would double-pace. Probe `GET /health` first; an absent overseer fails the transition loudly, never a silent skip. spar is one overseer client among several (the overseer's own type-B jobs, agents running skills), so never assume exclusivity of the browser or impose a client-side global lock; the per-kind cap of 1 on `linkedin_send`/`ses_send` serialises spar's own rows and is the permitted exception.

## Running T6 LinkedIn sends (operator runbook)

1. Start an overseer on the machine whose Chromium profile is logged in to the sending LinkedIn account, pointing it at a skills checkout that carries `linkedin.com/send-invite` and `linkedin.com/send-message`:

   `BI_SKILLS_ROOT=<skills-checkout>/skills <overseer-repo>/desktop/overseer -cli -no-poll`

2. Confirm it answers: `curl http://127.0.0.1:11402/health` (expect `"ok":true`).

3. Dry run first: `tclsh9.0 spar-transition.tcl <campaign.yaml> T6 --dry-run` validates every row (message present, vanity extractable, note within the 300-char invite limit) without contacting the overseer.

4. Send stepped: `tclsh9.0 spar-transition.tcl <campaign.yaml> T6 --jobs=0` confirms each contact on stdin before its send. A plain `T6` sends the whole band serially; the overseer's linkedin.com gate spaces the sends (minutes-scale, jittered), so a band of N takes on the order of N × 2–4 minutes.

5. A successful send stamps `actioned_date` on the approach YAML's linkedin message; `uncertain` results are left unstamped and reported as failures for a human to check on LinkedIn before retrying.

The message's `mode` key (`invite` or `dm`) picks the primitive; absent, text within 300 chars sends as a connection invite, longer text as a direct message (which requires a 1st-degree connection and fails cleanly otherwise).
