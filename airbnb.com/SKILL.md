---
name: airbnb.com
description: "host dashboard: quick replies, saved message templates, hosting message settings; past/upcoming/all reservations."
argument-hint: <list [--product STAYS|EXPERIENCES] | reservations [--filter past|upcoming|all]>
allowed-tools: Bash, Read
---

## Execution model

Spawn a **subagent** to run the CDP script, as each invocation launches a headless browser session (~15s overhead). Tell the subagent to use the script at `$HOME/.claude/skills/airbnb.com/airbnb-cdp.py`.

## Prerequisites

- A Chrome-compatible browser with an active Airbnb hosting session. The user must be logged in to `airbnb.com/hosting` via their browser. See `BROWSER.md` for which browser `bin/not-google-chrome` targets on each platform — this skill uses CDP, not `--dump-dom`, because Airbnb is a React SPA and the URL does not change on in-page navigation.
- **Close the browser before running.** The headless instance and GUI browser share the same profile; if the GUI holds the profile lock, cookies will not be readable by the headless instance.

If the script returns `{"error": "Not logged in..."}`, the user needs to log in to Airbnb in their browser first, then close it.

## Capabilities

### 1. List quick replies

```bash
python3 $HOME/.claude/skills/airbnb.com/airbnb-cdp.py list [--product STAYS|EXPERIENCES]
```

Navigates to the quick replies settings page, intercepts the API response the page makes, and returns the quick replies as JSON. Default product is `STAYS`.

On success returns a list of objects, each with the quick reply data as Airbnb returns it (typically `id`, `title`, `body`/`message`, and category fields). On API discovery failure, returns the intercepted responses with `url`, `status`, and `data` so the endpoint can be identified and hardcoded.

### 2. Reservations

```bash
python3 $HOME/.claude/skills/airbnb.com/airbnb-cdp.py reservations [--filter past|upcoming|all]
```

Returns `{"total_count": N, "returned": N, "reservations": [...]}` (for `--filter all`, an object keyed by `past` and `upcoming`). Each reservation includes `confirmation_code`, `listing_id`, `listing_name`, `start_date`, `end_date`, `nights`, `guest_user`, `earnings`, `user_facing_status_key` (`complete`, `current`, `canceled`, `denied`, `timedout`, etc.), and `is_check_in_today` / `is_check_out_today` flags.

`past` uses `collection_strategy=for_reservations_list_history` and includes every past reservation regardless of status (cancellations and denials included). `upcoming` uses `collection_strategy=for_reservations_list` with `date_min=today` and `status=accepted,request`. Results are paginated 40 per call from inside the authenticated page context and the script loops until `metadata.page_count` is exhausted.

## How it works

The script uses Chrome DevTools Protocol (CDP) to launch a headless browser with the user's logged-in profile, navigate to a hosting page to establish the authenticated session, and then either intercept the React app's own API responses (quick replies) or issue further `/api/v2/...` calls from inside the page context via `Runtime.evaluate` (reservations). The CDP approach is necessary because the hosting dashboard is a React SPA whose URL does not change on in-page navigation, so `--dump-dom` would only capture the pre-hydration shell.

Session redirects to the host's locale domain (e.g. `airbnb.es`), so any URL substring filter should match `airbnb` rather than the literal `airbnb.com`.

## API endpoints

`GET /api/v2/reservations` (verified). Headers required: `X-Airbnb-API-Key: d306zoyjsyarp7ifhu67rjxn52tv0t20` (the public web key), `X-CSRF-Without-Token: 1`, `Content-Type: application/json`. Query parameters: `locale`, `currency`, `_format=for_remy`, `_limit`, `_offset`, `collection_strategy`, `sort_field=start_date`, `sort_order`, and the strategy-specific filters described above. Response shape: `{reservations: [...], metadata: {page_count, page_index, total_count}}`.

`GET /api/v2/messaging_quick_replies?locale=...&role=host` (used by capability 1).
