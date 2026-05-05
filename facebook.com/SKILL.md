---
name: facebook
description: Search Facebook people, read profiles, extract posts with hashtags and tagged people, and check keywords. Trigger when user asks to look up someone on Facebook, check a Facebook profile, or find someone's posts/activity.
argument-hint: <name, URL, or search terms>
---

## Execution model

This workflow produces large DOM outputs (1-15MB per page). Spawn a **Sonnet subagent** to execute it so the main conversation context is not consumed. Tell the subagent to use the scripts in `$HOME/.claude/skills/facebook.com/` — do not paste scripts inline.

## Prerequisites

A logged-in Facebook session in the browser profile that `$HOME/.claude/skills/bin/not-google-chrome` targets.

If the dumped DOM title contains "Log in", "Log into Facebook", or "Iniciar sesión", the session has expired and the user needs to log in interactively.

Facebook may serve different DOM structures depending on whether the viewer is logged in, the target profile's privacy settings, and the session locale.

## Skill-specific Chrome-compatible flag

The wrapper handles standard flags (headless, window size, user agent, profile, flock, timeout). This skill appends `--virtual-time-budget=3000` to allow Facebook's JS to render. Increase to 45000 on slow connections.

## 1. Search for people

```bash
$HOME/.claude/skills/bin/not-google-chrome \
  "https://www.facebook.com/search/people/?q=SEARCH_TERMS" \
  --virtual-time-budget=3000 \
  > /tmp/facebook-search-results.html 2>/dev/null
```

URL-encode search terms (spaces become `%20`).

### Search variants for hard-to-find people

Try in order if no results:

1. `Name City` — `Vikram%20Mazumder%20Mumbai`
2. `Name Company` — `Vikram%20Mazumder%20Google`
3. `"Name" Country` — `Vikram%20Mazumder%20India`
4. Alternative romanisations — for Indian names try Mazumdar/Mazumder/Majumder/Majumdar; for Chinese names try Lin/Lim/Lam etc.

## 2. Parse search results

```bash
python3 $HOME/.claude/skills/facebook.com/parse-search.py /tmp/facebook-search-results.html
```

Outputs profile URLs (both vanity `/username` and numeric `/profile.php?id=`) with nearby visible text.

## 3. Fetch a profile

For username-based profiles:

```bash
$HOME/.claude/skills/bin/not-google-chrome \
  "https://www.facebook.com/USERNAME" \
  --virtual-time-budget=3000 \
  > /tmp/facebook-profile.html 2>/dev/null
```

For numeric-ID profiles:

```bash
$HOME/.claude/skills/bin/not-google-chrome \
  "https://www.facebook.com/profile.php?id=NUMERIC_ID" \
  --virtual-time-budget=3000 \
  > /tmp/facebook-profile.html 2>/dev/null
```

### Optional: Fetch the About page for richer bio data

```bash
$HOME/.claude/skills/bin/not-google-chrome \
  "https://www.facebook.com/USERNAME/about" \
  --virtual-time-budget=3000 \
  > /tmp/facebook-about.html 2>/dev/null
```

For numeric-ID profiles, the about URL is `https://www.facebook.com/profile.php?id=NUMERIC_ID&sk=about`.

## 4. Parse profile

```bash
python3 $HOME/.claude/skills/facebook.com/parse-profile.py /tmp/facebook-profile.html
```

Extracts name, meta descriptions, JSON-LD Person data (if present), bio/intro lines, role/work mentions, location mentions, and visible text blocks.

Optionally parse the about page too:

```bash
python3 $HOME/.claude/skills/facebook.com/parse-profile.py /tmp/facebook-about.html
```

## 5. Parse recent posts (optional)

Uses the same profile HTML from step 3 (no additional fetch):

```bash
python3 $HOME/.claude/skills/facebook.com/parse-posts.py /tmp/facebook-profile.html
```

Extracts per post: text content, hashtags, tagged/mentioned people and pages (with profile URLs), and shared-from source. Produces a summary of all hashtags and tagged entities across posts.

The script auto-detects the profile owner's ID to exclude self-references. To override:

```bash
python3 $HOME/.claude/skills/facebook.com/parse-posts.py /tmp/facebook-profile.html --owner-id 100006232604720
```

How it works: each Facebook post carries a unique `__cft__[0]` token in all its links. The script uses `data-ad-preview="message"` markers to locate post boundaries, then associates hashtag and profile links via these tokens. Comments are excluded by limiting tag search to the header + content region.

## 6. Keyword search (optional)

```bash
python3 $HOME/.claude/skills/facebook.com/keyword-search.py /tmp/facebook-profile.html keyword1 keyword2 ...
```

Checks whether a profile mentions specific terms and shows surrounding context.

## DOM parsing notes

Facebook (as of 2026) uses randomised CSS class names (e.g. `x1lliihq x6ikm8r`), no semantic IDs, deeply nested div hierarchies, lazy loading, and pages of 1-15MB. The scripts extract `<title>`, `<meta>` tags, JSON-LD, and visible text via `>content<` pattern matching. Do not select by CSS class name — they change between sessions.
