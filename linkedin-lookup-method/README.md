# LinkedIn Person Lookup Method

## Important: Spawn a Sonnet subagent

This method involves processing large DOM outputs (1-20MB per page). **Spawn a Sonnet subagent** to execute this workflow so the main conversation context is not consumed by the raw HTML. Tell the subagent to use the scripts in this directory — do not paste the scripts inline.

## Prerequisites

- A headless browser with a logged-in LinkedIn session. LinkedIn requires authentication to view full profiles; without a logged-in session the server returns an auth wall. If the DOM returns a login page (title contains "Sign In", "Log In", or "Iniciar sesión"), the user needs to log in interactively first.
- Browser command, profile path, and concurrency handling (e.g. `flock`) are machine-specific — refer to `~/.claude/CLAUDE.md` for the local configuration.

## Browser flags

All `--dump-dom` commands in this workflow use the following flags:

| Flag | Purpose |
|------|---------|
| `--virtual-time-budget=3000` | Gives the page 3 seconds of virtual time to execute JavaScript before dumping the DOM. Without this, `--dump-dom` fires on the `load` event, which on LinkedIn is before content has rendered. On slow connections, increase to 45000 or 60000. |
| `--window-size=1920,10000` | Forces a tall viewport so lazy-loaded content below the fold renders. |
| `--user-data-dir=PROFILE_DIR` | Points to a browser profile that has an active LinkedIn session (cookies). Required — without it, the browser starts anonymous and LinkedIn returns the auth wall. |

## Step 1: Search LinkedIn

Use **people search** (`/search/results/people/`), not "all" search — it returns fewer results but they are cleaner profile cards. Skip profile selection — there is only one profile (Default).

```bash
BROWSER --headless --dump-dom \
  --virtual-time-budget=3000 \
  --window-size=1920,10000 \
  --user-data-dir=PROFILE_DIR \
  "https://www.linkedin.com/search/results/people/?keywords=SEARCH_TERMS&origin=GLOBAL_SEARCH_HEADER" \
  2>/dev/null > /tmp/linkedin-search-results.html
```

Substitute `BROWSER` and `PROFILE_DIR` from the local configuration in `~/.claude/CLAUDE.md`.

Replace `SEARCH_TERMS` with URL-encoded name (spaces become `%20`).

### Search strategy for hard-to-find people

If the first search returns no matches, try these variants in order. A search returning zero results does not mean the person has no LinkedIn — try all variants before declaring "not found".

1. `Name City` (e.g. `Sidney%20Lin%20Singapore`)
2. `Name Company` (e.g. `Sidney%20Lin%20A%20Firm%20Foundation`)
3. `Name Role City` (e.g. `Sidney%20Lin%20property%20Singapore`)
4. Alternative romanisations — in Singapore, the same Chinese surname can be Lin (Mandarin), Lim (Hokkien), or Lam (Cantonese). Try all variants.
5. `"Company Name" City` — search by company to find employees, then match the person
6. `Role Organisation City` (e.g. `Chairman%20Distinction%20ASME%20Singapore`) — search by role

## Step 2: Extract profile URLs and identify candidates

```bash
python3 parse-search.py /tmp/linkedin-search-results.html
```

This outputs each profile URL with its headline. Use this to identify which profiles to fetch.

## Step 3: Fetch a specific profile

```bash
BROWSER --headless --dump-dom \
  --virtual-time-budget=3000 \
  --window-size=1920,10000 \
  --user-data-dir=PROFILE_DIR \
  "https://www.linkedin.com/in/USERNAME/" \
  2>/dev/null > /tmp/linkedin-profile.html
```

## Step 4: Parse profile details

```bash
python3 parse-profile.py /tmp/linkedin-profile.html
```

This extracts name, headline, location, and visible text blocks (experience, about, education). See the script for details on how it handles LinkedIn's obfuscated DOM.

## Step 5: Keyword search in profile (optional)

If you need to check whether a profile mentions specific terms:

```bash
python3 keyword-search.py /tmp/linkedin-profile.html ASME property Australia tourism
```

## Why LinkedIn DOM parsing is hard

LinkedIn's rendered DOM (as of 2026) uses:

- **Randomised CSS class names** like `_38cb7509 d1e9ae31 d72b15a7` that change between sessions. You cannot select elements by class name.
- **No semantic IDs** on most content elements.
- **Lazy loading** — content below the fold may not render even with a tall viewport.
- **JSON state blobs** — large `<code>` blocks with serialised JSON state in an opaque, frequently changing format.
- **Large pages** — search results are 1-20MB; profile pages are 1-7MB.

The parsing scripts handle these constraints by extracting `<title>` tags, `<meta>` description tags, raw visible text via `>content<` patterns, and keyword matching. This approach is brittle but works as of March 2026.
