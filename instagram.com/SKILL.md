---
name: instagram
description: "Instagram: search accounts, read profiles (display name, follower/following/post counts, recent caption snippet); find by name or handle."
argument-hint: <name, handle, or search terms>
---

## Execution model

Spawn a **Sonnet subagent** to run the workflow. Profile DOM dumps are 1–2 MB; search responses are a few KB. Tell the subagent to use the scripts in `$HOME/.claude/skills/instagram.com/` — do not paste scripts inline.

## Prerequisites

A logged-in Instagram session in the browser profile that `$HOME/.claude/skills/bin/not-google-chrome` targets.

Note: `--lang` flags do not override Instagram's locale; it is a server-side account setting. The parsers are locale-agnostic, so this does not matter.

If a request redirects to `/accounts/login/` or returns empty JSON, the session has expired or been rate-limited. Stop and let the user log in interactively; continuing usually makes it worse.

## Skill-specific Chrome-compatible flag

The wrapper handles standard flags (headless, window size, user agent, profile, flock, timeout). This skill appends `--virtual-time-budget=N` (4000 for search, 6000 for profile) to give Instagram's JSON endpoint time to hydrate. Save stdout and stderr separately: a common pitfall is `2>/dev/null > out.html` producing a zero-byte file; `> out.html 2> out.err` is reliable.

## 1. Search via the topsearch JSON endpoint

Instagram's rendered search page (`/explore/search/keyword/?q=...`) is GraphQL-hydrated and stays empty in a headless dump within a reasonable time budget. The internal endpoint `/web/search/topsearch/?query=...`, authenticated, returns clean JSON directly. Use that:

```bash
$HOME/.claude/skills/bin/not-google-chrome -t 30 \
  "https://www.instagram.com/web/search/topsearch/?query=SEARCH_TERMS" \
  --virtual-time-budget=4000 \
  > /tmp/instagram-search.html 2> /tmp/instagram-search.err
```

URL-encode search terms (spaces become `%20`).

The response contains `users[]`, `hashtags[]`, and `places[]`. Each user includes `username`, `full_name`, `is_verified`, `is_private`, and (where applicable) `social_context` listing mutual followers — useful signal for disambiguation.

## 2. Parse search results

```bash
python3 $HOME/.claude/skills/instagram.com/parse-search.py /tmp/instagram-search.html
```

Prints a ranked list of candidate handles with display name, verified/private flags, profile URL, and mutual-followers context.

## 3. Fetch a profile

```bash
$HOME/.claude/skills/bin/not-google-chrome -t 45 \
  "https://www.instagram.com/HANDLE/" \
  --virtual-time-budget=6000 \
  > /tmp/instagram-profile.html 2> /tmp/instagram-profile.err
```

Instagram has no separate "about" page on the web.

## 4. Parse profile

```bash
python3 $HOME/.claude/skills/instagram.com/parse-profile.py /tmp/instagram-profile.html
```

Reliably extracts (from `<meta>` tags, which are server-rendered):
- Handle and canonical URL (from `og:url`)
- Display name (from `og:title`)
- Follower / following / post counts — parsed positionally so locale-agnostic
- Avatar URL (from `og:image`)
- A snippet of the most recent post's caption (from `meta name=description`)

When available (typically only for the logged-in user's own profile or profiles the viewer already follows closely), the parser also pulls JSON-hydrated fields: `biography`, `external_url`, `category_name`, `is_verified`, `is_private`, and exact counts. For most third-party profiles these JSON fields are absent — the og:description counts are the source of truth.

## 5. DM inbox metadata (noninvasive)

This script reads inbox metadata only. It must not be modified to read individual thread content. If you need message content from a specific thread, that is a separate, invasive operation. Write a different script with a different name.

```bash
python3 $HOME/.claude/skills/instagram.com/inbox-noninvasive.py list
```

Emits JSON with one entry per thread: `username`, `full_name`, `thread_id`, `last_activity_iso`, `last_snippet` (up to 120 chars of the last message text or a type label), `unseen` (boolean), `is_group`.

To verify the script does not mutate read state:

```bash
python3 $HOME/.claude/skills/instagram.com/inbox-noninvasive.py verify-noninvasive
```

Runs `list` twice with a 45-second sleep, diffs the `unseen` field per thread, exits 0 if stable and exits 2 if any thread flipped from unseen to seen.

Requires a logged-in session. Does not navigate to `/direct/inbox/` to avoid triggering a "user is viewing inbox" presence beacon. Any outgoing request matching seen-mutation URL patterns (`*/seen/*`, `*/mark_seen*`, `*item_seen*`, `*direct_thread*` POST) is blocked at the Fetch domain level and logged to stderr.

## 6. Recent posts for a handle

```bash
python3 $HOME/.claude/skills/instagram.com/fetch-recent-posts.py posts HANDLE
python3 $HOME/.claude/skills/instagram.com/fetch-recent-posts.py posts HANDLE --limit 50
```

Default limit is 12. Pagination via the feed API's `next_max_id` cursor happens automatically when `--limit` exceeds 12. The script navigates to the profile page once to resolve the user_id (from inline JSON or the `web_profile_info` API), then calls `/api/v1/feed/user/<user_id>/` directly in a loop until the limit is reached or `more_available` is false.

Each post entry includes:

- `post_id`, `shortcode`, `url`, `post_type` (image/video/carousel/reel), `taken_at_iso`
- `like_count`, `comment_count`
- `caption`, `hashtags` (regex-extracted from caption), `mentions` (regex-extracted from caption)
- `tagged_users` (the "tag people" feature on the post; aggregated across carousel slides)
- `coauthors` (the dual-author collab-post feature)
- `sponsors` (branded-content sponsor tags)
- `is_paid_partnership`, `location`

The five handle-bearing fields above (`mentions`, `tagged_users`, `coauthors`, `sponsors`, plus paid-partnership context) are what the collab-expansion script in §7 walks to find candidates.

## 7. Collab partner expansion (multi-handle spider)

```bash
python3 $HOME/.claude/skills/instagram.com/collab-expand.py expand handle1,handle2,handle3
python3 $HOME/.claude/skills/instagram.com/collab-expand.py expand --from /tmp/seeds.txt --posts-per-handle 36
```

Walks a list of input handles, fetches recent posts for each (paginated via §6's helpers), and accumulates the union of `tagged_users`, `coauthors`, `sponsors`, and caption `mentions` across all posts. Outputs candidate handles NOT already in the input set, ranked by explicit-collab signal first (tagged + coauthor + sponsor counts) and then by caption-mention count and breadth of source handles.

Each candidate row carries the four per-signal counts, a `total`, and a sorted `sources` list of input handles whose posts surfaced the candidate. Multi-source candidates (handles surfaced by several different input accounts) rank higher than single-source ones at equal signal strength.

This is single-level expansion. For "spider" behaviour (recursively expanding), feed the top N candidates as input to a second run.

Default `--posts-per-handle` is 24 (about two pages). Pacing: roughly one feed page every 2 seconds, plus a 2-second gap between input handles. A run over 5 input handles at 24 posts each takes about a minute.

## What this skill does NOT do (by design)

- It does not scrape individual post captions, comments, or likes. The profile page does not render post bodies in a headless dump — those come from separate GraphQL calls. If that is needed, add a step that fetches individual post permalinks (`/p/SHORTCODE/`), which do server-render caption and alt text, and parse them separately.
- It does not handle hashtag or place pages, only people search and profiles. The topsearch endpoint already returns hashtags and places for discovery; dedicated pages would be a separate addition.
- It does not attempt to defeat rate limits or checkpoints. Pace requests — a few per minute, not a burst.
