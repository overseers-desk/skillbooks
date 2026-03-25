# Facebook Person Lookup Method

## Important: Spawn a Sonnet subagent

This method involves processing large DOM outputs (1-15MB per page). **Spawn a Sonnet subagent** to execute this workflow so the main conversation context is not consumed by the raw HTML. Tell the subagent to use the scripts in this directory — do not paste the scripts inline.

## Prerequisites

- Chromium must be installed (snap: `/snap/bin/chromium`)
- The user must have a Chromium profile with an active Facebook session (logged in). If the DOM returns a login page (title contains "Log in" or "Log into Facebook"), the user needs to log in to Chromium first.
- **Chromium must NOT be running.** Headless mode cannot use a profile while Chromium holds the SingletonLock. If Chromium is running, ask the user to close all Chromium windows first.
- Only one headless Chromium instance can use a `--user-data-dir` at a time. Do not run multiple fetches in parallel.
- Facebook may serve different DOM structures depending on whether the viewer is logged in, the privacy settings of the target profile, and the locale of the session.

## Chromium flags

All `--dump-dom` commands in this workflow use the following flags:

| Flag | Purpose |
|------|---------|
| `--window-size=1920,10000` | Forces a tall viewport so lazy-loaded content below the fold renders. |
| `--user-data-dir="$HOME/snap/chromium/common/chromium"` | Uses the snap Chromium profile where Facebook is logged in. |

## Step 0: Check Chromium is not running

```bash
pgrep -f chromium --list-full 2>/dev/null | grep -v pgrep || echo "NO_CHROMIUM_RUNNING"
```

If Chromium is running, ask the user to close it. If there's a stale SingletonLock after Chromium is closed:

```bash
rm -f "$HOME/snap/chromium/common/chromium/SingletonLock"
```

## Step 1: Search Facebook for people

```bash
chromium --headless --dump-dom \
  --window-size=1920,10000 \
  --user-data-dir="$HOME/snap/chromium/common/chromium" \
  "https://www.facebook.com/search/people/?q=SEARCH_TERMS" \
  2>/dev/null > /tmp/facebook-search-results.html
```

Replace `SEARCH_TERMS` with URL-encoded name (spaces become `%20`).

### Search strategy for hard-to-find people

If the first search returns no matches, try these variants in order:

1. `Name City` (e.g. `Vikram%20Mazumder%20Mumbai`)
2. `Name Company` (e.g. `Vikram%20Mazumder%20Google`)
3. `"Name" Country` (e.g. `Vikram%20Mazumder%20India`)
4. Alternative romanisations — for Indian names, try common spelling variants (e.g. Mazumdar vs Mazumder vs Majumder vs Majumdar)

## Step 2: Extract profile URLs and identify candidates

```bash
python3 ~/code/weiwu/facebook-lookup-method/parse-search.py /tmp/facebook-search-results.html
```

This outputs each profile URL with nearby visible text (name, location, mutual friends). Use this to identify which profile to fetch.

## Step 3: Fetch a specific profile

For a username-based profile:

```bash
chromium --headless --dump-dom \
  --window-size=1920,10000 \
  --user-data-dir="$HOME/snap/chromium/common/chromium" \
  "https://www.facebook.com/USERNAME" \
  2>/dev/null > /tmp/facebook-profile.html
```

For a numeric-ID profile:

```bash
chromium --headless --dump-dom \
  --window-size=1920,10000 \
  --user-data-dir="$HOME/snap/chromium/common/chromium" \
  "https://www.facebook.com/profile.php?id=NUMERIC_ID" \
  2>/dev/null > /tmp/facebook-profile.html
```

### Optional: Fetch the About page for richer bio data

```bash
chromium --headless --dump-dom \
  --window-size=1920,10000 \
  --user-data-dir="$HOME/snap/chromium/common/chromium" \
  "https://www.facebook.com/USERNAME/about" \
  2>/dev/null > /tmp/facebook-about.html
```

For numeric-ID profiles, the about URL is:

```
https://www.facebook.com/profile.php?id=NUMERIC_ID&sk=about
```

## Step 4: Parse profile details

```bash
python3 ~/code/weiwu/facebook-lookup-method/parse-profile.py /tmp/facebook-profile.html
```

This extracts name, bio/intro, and visible text blocks (work, education, location, etc.).

Optionally parse the about page too:

```bash
python3 ~/code/weiwu/facebook-lookup-method/parse-profile.py /tmp/facebook-about.html
```

## Step 5: Parse recent posts (optional)

To extract recent posts with their text content, hashtags, and tagged/mentioned people or pages:

```bash
python3 ~/code/weiwu/facebook-lookup-method/parse-posts.py /tmp/facebook-profile.html
```

This uses the same profile HTML fetched in Step 3 (no additional fetch needed). It extracts:

- **Post content** — the visible text of each post
- **Hashtags** — all `#hashtag` links used
- **Tagged/mentioned** — people and pages linked in the post header or body (excludes commenters)
- **Shared from** — the original source if the post is a share

The script auto-detects the profile owner's ID to exclude self-references. To override:

```bash
python3 ~/code/weiwu/facebook-lookup-method/parse-posts.py /tmp/facebook-profile.html --owner-id 100006232604720
```

The output includes per-post detail and a summary of all hashtags and tagged entities across posts.

**How it works:** Each Facebook post carries a unique `__cft__[0]` token in all its links (hashtags, tags, photos, comments). The script uses `data-ad-preview="message"` markers to locate post content boundaries, then associates hashtag and profile links via these tokens. Comments are excluded by limiting the tag search to the header + content region (before the Like/Comment/Share buttons).

## Step 6: Keyword search in profile (optional)

If you need to check whether a profile mentions specific terms:

```bash
python3 ~/code/weiwu/facebook-lookup-method/keyword-search.py /tmp/facebook-profile.html India Mumbai engineer
```

## Why Facebook DOM parsing is hard

Facebook's rendered DOM (as of 2026) uses:

- **Randomised CSS class names** like `x1lliihq x6ikm8r x10wlt62` that change between sessions.
- **No semantic IDs** on most content elements.
- **Nested div soup** — content is buried deep in div hierarchies.
- **Lazy loading** — content below the fold may not render even with a tall viewport.
- **React state** — the meaningful data may be in JSON blobs embedded in `<script>` tags rather than in the visible DOM.
- **Large pages** — search results and profile pages are 1-15MB.

The parsing scripts handle these constraints with the same approach as the LinkedIn scripts: extract `<title>`, `<meta>` tags, and visible text via `>content<` patterns, then filter out CSS/JS noise.
