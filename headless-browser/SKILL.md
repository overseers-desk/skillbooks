---
name: headless-browser
description: "Provides the not-google-chrome wrapper (at $HOME/.claude/skills/headless-browser/not-google-chrome) for fetching a page through the user's logged-in Chromium when WebFetch is blocked by bot detection or a login wall. Other skills call it by bare name; the path and usage live here."
allowed-tools: Bash, Read
argument-hint: <URL>
---

Canonical home of the `not-google-chrome` wrapper. Site-specific skills (e.g. linkedin, facebook, ihg.com) call it by bare name; resolve that name to the path below. When a site-specific skill covers the target, use it instead; this is the fallback for everything else.

## Fetch a page

```bash
$HOME/.claude/skills/headless-browser/not-google-chrome [-t SECONDS] [--pdf PATH] URL > /tmp/dump.html
```

Redirect to a file: dumps run several MB and flood context if returned inline. Parse the file selectively, or hand it to a Haiku/Sonnet subagent — keep raw DOM out of the main session.

The wrapper's comment header is the reference for flags, exit codes, and the abuse list of URLs it refuses (sites that answer plain HTTP; use WebFetch or curl for those). `../BROWSER.md` records why Chromium and the live user-data-dir.

## Prerequisites

- `[browser] user_agent` set in `$HOME/.claude/skills/config.ini` (see `../config.ini.example`). The wrapper sends it as the UA so the fetch fingerprint matches the logged-in session; it exits 78 if the key is missing.
- A logged-in Chromium session for any site needing one. If a dump comes back as a sign-in page, the user-data-dir is wrong or another Chromium holds the lock — investigate the plumbing rather than asking the user to log in again; they are usually already logged in.
