# spar-manager

Tcl libraries and GUI for managing SPAR outreach campaigns. Provides a state machine that classifies contacts, computes progress, detects duplicates, and enumerates transition tasks. The same libraries power both the CLI tools and the Tk GUI.

## Architecture

A campaign is anchored on `campaign.yaml`. `spar-state.tcl` classifies each roster row against the transition registry and exposes the eligibility ladder used by the progress table and the dispatcher. The registry is built at load time from per-class files under `transitions/` (`profile.tcl`, `approach.tcl`, `send_email.tcl`, `check_replies.tcl`, `linkedin_followup.tcl`, `manual_followup.tcl`); each class binds itself to a TID (`T1`, `T2`, `T6`, `T7`, and so on).

Dispatch comes in two forms over the same registry. CLI dispatch lives in `spar-dispatch.tcl` (the phase runners `spar::p::run` and `spar::a::run`, plus per-T runners), used by `spar-transition.tcl`. GUI dispatch lives in `spar-dispatcher.tcl` (the `spar::Dispatcher` class, a tcllib `tpool`-backed mixed-type job pool), used by `spar-ui.tcl` via `ui/dispatch-controller.tcl`. The state machine, validation, harnesses (`spar-harness.tcl`, `spar-p-harness.tcl`, `spar-a-harness.tcl`), email helpers, and shared library (`spar-lib.tcl`) are common to both paths.

For deeper internals: `state-machine.md` covers the TIDs, validation gates, warnings catalogue, and pre/post Design-by-Contract markers. `docs/concurrency.md` covers the Dispatcher message protocol and tpool model. `ui-design.md` covers the GUI zone layout. `spar-transition.tcl --help` prints the live transition catalogue with each transition's wiring status (`available`, `not-implemented`, `manual`, `blocked`, `n/a`).

## Dependencies

### Tcl/Tk

- `tclsh9.0` (CLI tools, tests) — scripts use `#!/usr/bin/env tclsh9.0` shebang
- `wish9.0` (GUI)
- tcllib packages: `yaml`, `json`, `json::write` — typically installed via `apt install tcllib` or equivalent
- TclTLS: `tls` package for STARTTLS (email sending) — `apt install tcl-tls` on Ubuntu, `brew install tcl-tls` on macOS

### External CLI tools

| Tool | Used by | Purpose |
|------|---------|---------|
| `claude` | `spar-harness.tcl` (harness) | Claude Code CLI for profile/approach generation |
| `mailroom` | `spar-email.tcl` | Query email account for reply checking |
| `flock` | `spar-a-harness.tcl` | File locking for concurrent roster TSV writes |
| `md5sum` | `spar-a-harness.tcl` | Lock file path derivation |
| `mktemp` | `spar-a-harness.tcl`, `transitions/send_email.tcl` | Temporary file creation |

Email sending (`transitions/smtp_send.tcl`) connects directly to the SES SMTP endpoint. The system is written assuming SES: SES rewrites the RFC 822 `Message-ID` header on every send, and the SES-assigned tracking id is captured from the `250 Ok <id>` SMTP response rather than from an API reply.

SMTP host and port are non-secret and belong in the campaign YAML under `sender.smtp_host` and `sender.smtp_port` (default 587). SMTP username and password are stored in the OS secret store under the entry name `spar-smtp` and read at send time — no plaintext credentials file is kept on clerk machines.

Admin setup (one-time per machine, credentials in hand):

```sh
# macOS
security add-generic-password -s spar-smtp -a SMTP_USER -w SMTP_PASS -U

# Ubuntu / Linux
secret-tool store --label="SPAR SMTP user" service spar-smtp key user <<< "SMTP_USER"
secret-tool store --label="SPAR SMTP pass" service spar-smtp key pass <<< "SMTP_PASS"
```

```powershell
# Windows
[void][Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime]
$vault = New-Object Windows.Security.Credentials.PasswordVault
$vault.Add([Windows.Security.Credentials.PasswordCredential]::new("spar-smtp", "SMTP_USER", "SMTP_PASS"))
```

On macOS, Keychain presents a one-time "Allow / Always Allow / Deny" dialog the first time spar-manager reads the entry. After "Always Allow" the reads are silent.

### Optional

- `mailroom` is only needed for reply checking. The GUI and CLI progress tools work without it.
- `claude` is only needed for dispatch (running profile/approach generation). Progress reporting and state classification do not require it.

## Usage

`spar-transition.tcl --help` is the live reference for transition grammar and prints the wired-transition catalogue. Examples below are starting points.

### GUI

```
wish9.0 spar-ui.tcl                         # welcome screen
wish9.0 spar-ui.tcl /path/to/campaign-dir   # file picker rooted at dir
wish9.0 spar-ui.tcl /path/to/campaign.yaml  # mount campaign directly
```

### Transition report and dispatch

`spar-transition.tcl` decides between report and dispatch by argv. A bare campaign yaml prints the eligibility ladder. One or more `Tn` tokens dispatch those transitions live. `--auto` drives auto-safe transitions (those with no external side effects) to convergence and refuses positional `Tn`. `--dry-run` disables writes and combines with any mode. `Tn` tokens accept `Tn:<segment>` or `Tn:<segment>/<stem>` for narrower scope, are repeatable, and may mix TIDs.

```
tclsh9.0 spar-transition.tcl /path/to/campaign.yaml             # eligibility report
tclsh9.0 spar-transition.tcl /path/to/campaign.yaml --ready     # ready rows only
tclsh9.0 spar-transition.tcl /path/to/campaign.yaml T1          # dispatch one TID live
tclsh9.0 spar-transition.tcl /path/to/campaign.yaml T1 --dry-run
tclsh9.0 spar-transition.tcl /path/to/campaign.yaml T6:vic/jane-doe   # one contact
tclsh9.0 spar-transition.tcl /path/to/campaign.yaml --auto      # converge auto-safe
tclsh9.0 spar-transition.tcl /path/to/campaign.yaml T6 --yes    # cron, skip [y/N]
```

Common flags: `--pending`/`--ready` (report filters), `--jobs=N` (parallelism, default 4; `--jobs=0` steps one row at a time with a `[y/N]` gate), `--delay=N` (seconds between sends for SES-type transitions, default 2), `--yes` (skip the upfront confirmation for transitions that require it, e.g. `T6` SES sends), `-v`/`--verbose` (list each contact in report mode rather than counts).

### Progress table

```
tclsh9.0 spar-progress.tcl <campaign-dir-or-yaml>
tclsh9.0 spar-progress.tcl <campaign-dir-or-yaml> --json
tclsh9.0 spar-progress.tcl <campaign-dir-or-yaml> --no-reply-check
```

Positional argument is either a campaign directory or the yaml inside it. `--json` emits machine-readable output; `--no-reply-check` omits the T7 reply-check row; `--legend` is accepted (no-op kept for compatibility).

### Harness (usually dispatched, runnable standalone for debugging)

```
tclsh9.0 spar-p-harness.tcl <prompt-dir> <log-dir>
tclsh9.0 spar-a-harness.tcl <prompt-dir> <log-dir>
```

Dispatch supplies both arguments, with `<log-dir>` resolved by `spar::resolve_logs_dir` (see Logs). Running by hand against an existing prompt directory reproduces a single profile or approach run.

### Tests

```
tclsh9.0 test/run.tcl   # parallel; honours SPAR_TEST_JOBS
```

## Logs

`spar::resolve_logs_dir` (`spar-lib.tcl:518`) creates `/var/local/log/spar/<folder>` if `/var/local/log/spar` exists, otherwise `$HOME/logs/spar/<folder>`. `<folder>` is `<dir_slug>-<stem>-<phase>-<datestamp>`, where `dir_slug` is the campaign yaml's normalised parent path with `/` replaced by `-`, `stem` is the yaml filename without extension, `phase` is `p` or `a`, and `datestamp` is Tcl `%Y%m%d-%H%M%S`. The dispatch API's `logs_dir` opt (`spar-dispatch.tcl:234`) overrides path derivation; the supplied directory must already exist or `resolve_logs_dir` raises an error.

Created by dispatch runs only. `spar-transition.tcl` (CLI) and `spar-ui.tcl` (GUI) resolve identical paths for the same campaign and phase. `spar-progress.tcl`, state classification, and validation write nothing here.

Per-stem files inside the run folder, written by `spar::Harness` (`spar-harness.tcl:38`), with `<slug>` set to the file tail of `prompt_dir`:

- `<slug>-cost.jsonl`: one JSON record per `claude` invocation, summed by `spar::Harness cost_total`
- `<slug>-profile.log` plus `<slug>-profile.log.json` (Claude session JSON, used for `--resume`): P-phase
- `<slug>-author-draft.log`, `<slug>-challenger-pass<N>.log`, `<slug>-author-rev<N>.log`, `<slug>-author-assembly.log`: A-phase stages
- `<slug>-fix<N>.log`: A-phase post-assembly retries
