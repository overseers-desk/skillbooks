---
name: airbnb.com
description: List Airbnb hosting quick replies. Use when the user asks about their Airbnb quick replies, saved message templates, or hosting message settings.
argument-hint: <list [--product STAYS|EXPERIENCES]>
allowed-tools: Bash, Read
---

## Execution model

Spawn a **subagent** to run the CDP script, as each invocation launches a headless browser session (~15s overhead). Tell the subagent to use the script at `$HOME/.claude/skills/airbnb.com/airbnb-cdp.py`.

## Prerequisites

- A Chrome-compatible browser with an active Airbnb hosting session. The user must be logged in to `airbnb.com/hosting` via their browser. See `BROWSER.md` for which browser `bin/browser` targets on each platform — this skill uses CDP, not `--dump-dom`, because Airbnb is a React SPA and the URL does not change on in-page navigation.
- **Close the browser before running.** The headless instance and GUI browser share the same profile; if the GUI holds the profile lock, cookies will not be readable by the headless instance.

If the script returns `{"error": "Not logged in..."}`, the user needs to log in to Airbnb in their browser first, then close it.

## Capabilities

### 1. List quick replies

```bash
python3 $HOME/.claude/skills/airbnb.com/airbnb-cdp.py list [--product STAYS|EXPERIENCES]
```

Navigates to the quick replies settings page, intercepts the API response the page makes, and returns the quick replies as JSON. Default product is `STAYS`.

On success returns a list of objects, each with the quick reply data as Airbnb returns it (typically `id`, `title`, `body`/`message`, and category fields). On API discovery failure, returns the intercepted responses with `url`, `status`, and `data` so the endpoint can be identified and hardcoded.

## How it works

The script uses Chrome DevTools Protocol (CDP) to:
1. Launch a headless browser with the user's logged-in profile
2. Enable `Network.enable` before navigating, so all API responses are captured
3. Navigate to `airbnb.com/hosting/messages/settings/quick-replies?product=STAYS`
4. Drain network events for 10 seconds, buffering responses whose URL contains `quick` and `airbnb.com/api`
5. Fetch response bodies via `Network.getResponseBody` while still in the same CDP session
6. If no matching network traffic is captured, falls back to JS `fetch()` against known v2 endpoints using the page's `X-Airbnb-API-Key` and CSRF tokens

The CDP approach is necessary because the page is a React SPA — the URL does not change when browsing between quick replies, so `--dump-dom` would only capture the pre-hydration shell.

## API endpoints (discovered via network interception)

Not yet confirmed — the script captures whatever endpoint Airbnb's hosting dashboard calls. Once confirmed, this section should be updated with the verified endpoint, method, and auth headers.
