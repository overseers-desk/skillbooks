# spar-manager

Tcl libraries and GUI for managing SPAR outreach campaigns. Provides a state machine that classifies contacts, computes progress, detects duplicates, and enumerates transition tasks. The same libraries power both the CLI tools and the Tk GUI.

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

```
# GUI
wish9.0 spar-ui.tcl /path/to/campaign-dir

# CLI progress table
tclsh9.0 spar-progress.tcl /path/to/campaign-dir

# Profile generation (dry run)
tclsh9.0 spar-transition.tcl /path/to/campaign.yaml T1 --dry-run

# Approach generation (dry run)
tclsh9.0 spar-transition.tcl /path/to/campaign.yaml T2 --dry-run

# Tests (parallel; honours SPAR_TEST_JOBS)
tclsh9.0 test/run.tcl
```
