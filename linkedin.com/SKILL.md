---
name: linkedin
description: "search people, read profiles, check keywords, verify connect eligibility, find role/company. Send connection invites or direct messages to connections."
argument-hint: <name, URL, or search terms>
---

## Execution model

This workflow produces large DOM outputs (1-20MB per page). Spawn a **Sonnet subagent** to execute it so the main conversation context is not consumed. Tell the subagent to use the scripts in `$HOME/.claude/skills/linkedin.com/` — do not paste scripts inline.

## Prerequisites

A logged-in LinkedIn session in the browser profile that `not-google-chrome` targets. This skill constructs LinkedIn URLs, calls the wrapper to fetch them, and parses the result.

If the dumped DOM title contains "Sign In", "Log In", "Iniciar sesión", or "Registrarse", the wrapper did not deliver a logged-in session: the profile path is wrong, or another chromium instance holds the same profile. Investigate the plumbing; do not ask the user to log in again. The user is almost always already logged in.

## 1. Search for people

Use **people search**, not "all" search. Fetch this URL with the wrapper, save to `/tmp/linkedin-search-results.html`:

```bash
not-google-chrome "https://www.linkedin.com/search/results/people/?keywords=SEARCH_TERMS&origin=GLOBAL_SEARCH_HEADER" > /tmp/linkedin-search-results.html
```

URL-encode search terms (spaces become `%20`).

### Search variants for hard-to-find people

Try in order if no results:

1. `Name City` — `Sidney%20Lin%20Singapore`
2. `Name Company` — `Sidney%20Lin%20A%20Firm%20Foundation`
3. `Name Role City` — `Sidney%20Lin%20property%20Singapore`
4. Alternative romanisations — Lin (Mandarin), Lim (Hokkien), Lam (Cantonese) are the same surname
5. `"Company" City` — search by company to find employees, then match
6. `Role Organisation City` — `Chairman%20Distinction%20ASME%20Singapore`

A search returning zero results does not mean the person has no LinkedIn. Try all variants before declaring "not found".

## 2. Parse search results

```bash
python3 $HOME/.claude/skills/linkedin.com/parse-search.py /tmp/linkedin-search-results.html
```

Outputs each profile URL with nearby visible text (name, headline).

## 3. Fetch a profile

Fetch this URL with the wrapper, save to `/tmp/linkedin-profile.html`:

```bash
not-google-chrome "https://www.linkedin.com/in/USERNAME/" > /tmp/linkedin-profile.html
```

## 4. Parse profile

```bash
python3 $HOME/.claude/skills/linkedin.com/parse-profile.py /tmp/linkedin-profile.html
```

Extracts name, headline, location, meta descriptions, and visible text blocks (experience, about, education).

## 5. Keyword search (optional)

```bash
python3 $HOME/.claude/skills/linkedin.com/keyword-search.py /tmp/linkedin-profile.html keyword1 keyword2 ...
```

Checks whether a profile mentions specific terms and shows surrounding context.

## 6. Verify connect eligibility

The connection invite page is at a constructable URL:

```
https://www.linkedin.com/preload/custom-invite/?vanityName=USERNAME
```

Fetch this URL with the wrapper, save to `/tmp/linkedin-connect.html`, then check the modal that renders:

```bash
not-google-chrome "https://www.linkedin.com/preload/custom-invite/?vanityName=USERNAME" > /tmp/linkedin-connect.html
```

Parse the result:

- **Connectable** — modal header is "Add a note to your invitation?" with two buttons: "Add a note" and "Send without a note". Body text says "Personalize your invitation to [Name] by adding a note."
- **Email required** — same modal but with an extra `<input type="email">` and text asking to "enter their email to connect" (happens for some high-profile accounts).
- **Already connected** — different page state (no invite modal).
- **Not found / error** — no modal rendered.

If the modal shows "Add a note" and "Send without a note", the person is connectable. Proceed to step 7 to send.

## 7. Send connection invite with note

```bash
python3 $HOME/.claude/skills/linkedin.com/send-invite.py VANITY_NAME "Your note (≤300 chars)"
```

`VANITY_NAME` is the slug from the profile URL: `/in/john-smith-123/` → `john-smith-123`.

The script uses CDP (Chrome DevTools Protocol) against the snap Chromium profile. It:
1. Navigates to `/preload/custom-invite/?vanityName=VANITY_NAME`
2. Clicks "Add a note", waits for the textarea (`#custom-message`)
3. Types the note via `Input.insertText` (triggers Ember reactivity)
4. Clicks the send button (label varies; matched by "send" excluding "without")
5. Waits for server round-trip and captures confirmation

**Prerequisite:** snap Chromium must not be open (it shares the profile directory). If it is running, the script warns but may still succeed; if the profile is locked, close the browser and retry.

**Confirmation output** — the script prints and returns a JSON result:
- `toast` — text of LinkedIn's toast notification if present (e.g. "Invitation sent")
- `modal_closed` — whether the modal disappeared after send (strong success signal)
- `api_responses` — HTTP status codes from LinkedIn's invitation API calls
- `status` — `"sent"` | `"uncertain"` | `"dry_run"`

`status: "sent"` requires at least one of: toast present, modal closed, or API 200/201/204. If none triggered, the script exits with code 1 and prints `UNCERTAIN`.

**Dry-run mode** (types but does not click Send):
```bash
python3 $HOME/.claude/skills/linkedin.com/send-invite.py VANITY_NAME "note" --dry-run
```

**Prerequisites check:** if `websockets` is missing, install it: `pip3 install websockets`.

**Note character limit:** LinkedIn enforces 300 chars client-side (no `maxlength` HTML attribute). The script enforces this before launching the browser.

## 8. Send a direct message to a connection

```bash
python3 $HOME/.claude/skills/linkedin.com/send-message.py VANITY_NAME "Message text"
```

The person must be a first-degree connection. The script:
1. Navigates to the profile page `/in/VANITY_NAME/`
2. Clicks the "Message" button
3. Types the message via `Input.insertText` into the compose area
4. Clicks the Send button
5. Confirms via compose-area clearing and/or API response

**Dry-run mode:**
```bash
python3 $HOME/.claude/skills/linkedin.com/send-message.py VANITY_NAME "text" --dry-run
```

**Confirmation output:**
- `toast` — LinkedIn toast text if present
- `compose_cleared` — whether the compose area emptied after send (primary success signal)
- `api_responses` — HTTP status codes from LinkedIn's messaging API
- `status` — `"sent"` | `"uncertain"` | `"dry_run"`

## DOM parsing notes

LinkedIn (as of 2026) uses randomised CSS class names, no semantic IDs, lazy loading, and pages of 1-20MB. The scripts extract `<title>`, `<meta>` tags, and visible text via `>content<` pattern matching. Do not select by CSS class name — they change between sessions.
