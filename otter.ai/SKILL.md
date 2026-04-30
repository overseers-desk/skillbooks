---
name: otter.ai
description: List, rename, and export Otter.ai recordings. Use when the user asks about Otter.ai recordings, transcripts, or wants to manage their Otter.ai content.
argument-hint: <list | rename | export-dropbox | dropbox-status>
allowed-tools: Bash, Read
---

## Execution model

Spawn a **subagent** to run the CDP script, as each invocation launches a headless browser session (~15s overhead). Tell the subagent to use the script at `$HOME/code/aesop/otter.ai/otter-cdp.py`.

## Prerequisites

- A Chrome-compatible browser with an active Otter.ai session (user must be logged in via the browser UI)
- Python 3 with `websocket-client` installed
- For Dropbox export: Dropbox must be connected in Otter.ai settings
- Export path configured in `~/.claude/config/skill-config.yaml` under `otter.ai.dropbox_export_path`

If the script returns `{"error": "Not logged in..."}`, the user needs to log in to otter.ai in their browser first. If `skill-config.yaml` is absent, pause and let the user know: "Create `~/.claude/config/skill-config.yaml` with an `otter.ai.dropbox_export_path` entry. This file is not part of the shared aesop repository - create it locally."

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

### 4. Check Dropbox connection

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
