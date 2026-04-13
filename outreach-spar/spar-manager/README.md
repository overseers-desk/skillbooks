# spar-manager

Tcl libraries and GUI for managing SPAR outreach campaigns. Provides a state machine that classifies contacts, computes progress, detects duplicates, and enumerates transition tasks. The same libraries power both the CLI tools and the Tk GUI.

## Dependencies

### Tcl/Tk

- `tclsh9.0` (CLI tools, tests) — scripts use `#!/usr/bin/env tclsh9.0` shebang
- `wish9.0` (GUI)
- tcllib packages: `yaml`, `json`, `json::write` — typically installed via `apt install tcllib` or equivalent

### External CLI tools

| Tool | Used by | Purpose |
|------|---------|---------|
| `claude` | `spar-claude.tcl` (harness) | Claude Code CLI for profile/approach generation |
| `aws` | `spar-email.tcl` | `aws ses send-email` for sending outreach emails |
| `mailroom` | `spar-email.tcl` | Query email account for reply checking |
| `flock` | `spar-a-harness.tcl` | File locking for concurrent roster TSV writes |
| `md5sum` | `spar-a-harness.tcl` | Lock file path derivation |
| `mktemp` | `spar-a-harness.tcl` | Temporary file creation during roster update |

### Optional

- `mailroom` and `aws` are only needed for email operations (Phase 5). The GUI and CLI progress tools work without them.
- `claude` is only needed for dispatch (running profile/approach generation). Progress reporting and state classification do not require it.

## Usage

```
# GUI
wish9.0 spar-ui.tcl /path/to/campaign-dir

# CLI progress table
tclsh9.0 spar-progress.tcl /path/to/campaign-dir

# Profile generation (dry run)
tclsh9.0 spar-transitions.tcl /path/to/campaign.yaml --tid=T1 --execute --dry-run

# Approach generation (dry run)
tclsh9.0 spar-a-batch.tcl /path/to/campaign.yaml --dry-run

# Tests
tclsh9.0 test/run-tests.tcl
tclsh9.0 test/test-email.tcl
```
