---
name: instagram
description: Search Instagram accounts and read profiles (display name, follower/following/post counts, recent caption snippet). Trigger when the user asks to look up someone on Instagram, check an Instagram profile, or find an account by name or handle.
argument-hint: <name, handle, or search terms>
---

## Execution model

Spawn a **Sonnet subagent** to run the workflow. Profile DOM dumps are 1–2 MB; search responses are a few KB. Tell the subagent to use the scripts in `$HOME/code/aesop/instagram.com/` — do not paste scripts inline.

## Prerequisites

A Chrome-compatible headless browser with a logged-in Instagram session. The browser binary, profile path, user-agent override, and `flock` lock are machine-specific. Refer to `BROWSER.md` for local configuration. These instructions use `BROWSER` and `PROFILE_DIR` as placeholders.

Note: `--lang` flags do not override Instagram's locale — it is a server-side account setting. The parsers are locale-agnostic, so this does not matter.

If a request redirects to `/accounts/login/` or returns empty JSON, the session has expired or been rate-limited. Stop and let the user log in interactively; continuing usually makes it worse.

## Browser flags used below

| Flag | Purpose |
|------|---------|
| `--virtual-time-budget=4000` (search) / `6000` (profile) | Enough for the endpoint to respond. Do not raise past ~15000 — the real timeout will kill the process before the dump completes. |
| `--window-size=3840,2160` | Tall viewport for lazy content on the profile DOM. |
| `--user-data-dir=PROFILE_DIR` | Active session cookies. |

Also: save stdout and stderr to separate files. A common pitfall on this setup is `2>/dev/null > out.html` producing a zero-byte file; `> out.html 2> out.err` is reliable.

## 1. Search — use the topsearch JSON endpoint

Instagram's rendered search page (`/explore/search/keyword/?q=...`) is GraphQL-hydrated and stays empty in a headless dump within a reasonable time budget. The internal endpoint `/web/search/topsearch/?query=...`, authenticated, returns clean JSON directly. Use that:

```bash
flock /tmp/browser.lock timeout 30 BROWSER --headless --dump-dom \
  --virtual-time-budget=4000 \
  --window-size=3840,2160 \
  --user-data-dir=PROFILE_DIR \
  "https://www.instagram.com/web/search/topsearch/?query=SEARCH_TERMS" \
  > /tmp/instagram-search.html 2> /tmp/instagram-search.err
```

URL-encode search terms (spaces become `%20`).

The response contains `users[]`, `hashtags[]`, and `places[]`. Each user includes `username`, `full_name`, `is_verified`, `is_private`, and (where applicable) `social_context` listing mutual followers — useful signal for disambiguation.

## 2. Parse search results

```bash
python3 $HOME/code/aesop/instagram.com/parse-search.py /tmp/instagram-search.html
```

Prints a ranked list of candidate handles with display name, verified/private flags, profile URL, and mutual-followers context.

## 3. Fetch a profile

```bash
flock /tmp/browser.lock timeout 45 BROWSER --headless --dump-dom \
  --virtual-time-budget=6000 \
  --window-size=3840,2160 \
  --user-data-dir=PROFILE_DIR \
  "https://www.instagram.com/HANDLE/" \
  > /tmp/instagram-profile.html 2> /tmp/instagram-profile.err
```

Instagram has no separate "about" page on the web.

## 4. Parse profile

```bash
python3 $HOME/code/aesop/instagram.com/parse-profile.py /tmp/instagram-profile.html
```

Reliably extracts (from `<meta>` tags, which are server-rendered):
- Handle and canonical URL (from `og:url`)
- Display name (from `og:title`)
- Follower / following / post counts — parsed positionally so locale-agnostic
- Avatar URL (from `og:image`)
- A snippet of the most recent post's caption (from `meta name=description`)

When available (typically only for the logged-in user's own profile or profiles the viewer already follows closely), the parser also pulls JSON-hydrated fields: `biography`, `external_url`, `category_name`, `is_verified`, `is_private`, and exact counts. For most third-party profiles these JSON fields are absent — the og:description counts are the source of truth.

## What this skill does NOT do (by design)

- It does not scrape individual post captions, comments, or likes. The profile page does not render post bodies in a headless dump — those come from separate GraphQL calls. If that is needed, add a step that fetches individual post permalinks (`/p/SHORTCODE/`), which do server-render caption and alt text, and parse them separately.
- It does not handle hashtag or place pages, only people search and profiles. The topsearch endpoint already returns hashtags and places for discovery; dedicated pages would be a separate addition.
- It does not attempt to defeat rate limits or checkpoints. Pace requests — a few per minute, not a burst.
