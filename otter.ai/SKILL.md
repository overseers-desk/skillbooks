---
name: otter.ai
description: List, rename, and export Otter.ai recordings. Use when the user asks about Otter.ai recordings, transcripts, or wants to manage their Otter.ai content.
argument-hint: <list | rename | export-dropbox | fetch-via-dropbox | dropbox-status>
allowed-tools: Bash, Read
---

## Execution model

Spawn a **subagent** to run the CDP script, as each invocation launches a headless browser session (~15s overhead). Tell the subagent to use the script at `$HOME/code/aesop/otter.ai/otter-cdp.py`.

## Prerequisites

- A Chrome-compatible browser with an active Otter.ai session (user must be logged in via the browser UI)
- Python 3 with `websocket-client` installed
- For Dropbox export: Dropbox must be connected in Otter.ai settings
- Export path configured in `~/.claude/skills/config.yaml` under `otter.ai.dropbox_export_path`

If the script returns `{"error": "Not logged in..."}`, the user needs to log in to otter.ai in their browser first. If `skill-config.yaml` is absent, pause and let the user know: "Create `~/.claude/skills/config.yaml` with an `otter.ai.dropbox_export_path` entry. This file is not part of the shared aesop repository - create it locally."

## Capabilities

### 1. List recordings

```bash
python3 $HOME/code/aesop/otter.ai/otter-cdp.py list [--page-size N] [--last-load-ts TS]
```

Returns JSON with `speeches` array. Each entry has: `otid`, `title`, `created_at` (epoch), `duration` (seconds), `summary`, `link` (full URL).

Default page size is 50. To paginate, pass `--last-load-ts` from the previous response's `last_load_ts`.

### 2. Rename a recording

```bash
python3 $HOME/code/aesop/otter.ai/otter-cdp.py rename <otid> "<new title>"
```

Returns `{"status": "OK", "modified_time": ...}` on success.

The `otid` is the recording identifier from the list command or from an otter.ai URL (`https://otter.ai/u/<otid>`).

### 3. Export to Dropbox

```bash
python3 $HOME/code/aesop/otter.ai/otter-cdp.py export-dropbox <otid> [--format txt|pdf|docx|srt]
```

Exports the recording to the user's connected Dropbox. Default format is `txt`.

Returns `{"status": "OK", "failed_speeches": []}` on success.

### 4. Fetch a recording via Dropbox round-trip

```bash
python3 $HOME/code/aesop/otter.ai/otter-cdp.py fetch-via-dropbox <otid> [--timeout 60] [--extended-timeout 120]
```

One-shot helper that triggers a txt export to Dropbox, polls `Dropbox:Apps/Otter` via `rclone` until a new file appears, reads its contents, deletes it from Dropbox, and returns the text. Format is hardcoded to `txt`. Path `Dropbox:Apps/Otter` is hardcoded.

Polling: `rclone lsf` every 5 seconds. `--timeout` (default 60s) is the initial deadline; on expiry a stderr notice is logged and polling continues until `--extended-timeout` (default 120s).

Returns `{"otid", "dropbox_filename", "content"}` on success. Errors include `Timeout waiting for Dropbox export`, `Multiple new files in Dropbox:Apps/Otter` (if a concurrent unrelated upload races), and any error propagated from `export-dropbox`.

Requires `rclone` configured with a `Dropbox:` remote.

### 5. Check Dropbox connection

```bash
python3 $HOME/code/aesop/otter.ai/otter-cdp.py dropbox-status
```

Returns connection status, `dropbox_account_id`, auto-export/import settings, and default export format.

## How it works

The script uses Chrome DevTools Protocol (CDP) to:
1. Launch a headless browser with the user's logged-in profile
2. Navigate to otter.ai to establish session context
3. Execute JavaScript `fetch()` calls against Otter.ai's internal API (`/forward/api/v1/...`)
4. Return JSON results

No Selenium needed. The browser is terminated after each invocation.

## API endpoints used

| Operation | Method | Path | Auth |
|---|---|---|---|
| List speeches | GET | `/forward/api/v1/speeches` | session cookie + x-csrftoken |
| Rename | POST | `/forward/api/v1/set_speech_title` | session cookie + x-csrftoken |
| Export TXT to Dropbox | POST | `/forward/api/v1/dropbox_speech_txt` | session cookie + x-csrftoken |
| Export PDF to Dropbox | POST | `/forward/api/v1/dropbox_speech_pdf` | session cookie + x-csrftoken |
| Export DOCX to Dropbox | POST | `/forward/api/v1/dropbox_speech_word` | session cookie + x-csrftoken |
| Export SRT to Dropbox | POST | `/forward/api/v1/dropbox_speech_srt` | session cookie + x-csrftoken |
| User info | GET | `/forward/api/v1/user` | session cookie + x-csrftoken |

The CSRF token is read from `document.cookie` (the `csrftoken` cookie is not httponly). The session cookie (`sessionid`) is httponly and sent automatically by the browser.
