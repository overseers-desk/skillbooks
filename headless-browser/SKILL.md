---
name: headless-browser
description: "When WebFetch/WebSearch are blocked by bot detection or a login wall, or WebFetch returns 'unable to fetch' for a domain, this skill provides the not-google-chrome wrapper for fetching a page through the user's logged-in Chromium. Other skills call it by bare name; the path and usage live here."
allowed-tools: Bash, Read
argument-hint: <URL>
---

Canonical home of the `not-google-chrome` wrapper. Site-specific skills call it by bare name; resolve that name to the path below. When a site-specific skill covers the target, use it instead; this is the fallback for everything else.

For months this wrapper has left chromium (not chrome!) processes running after a fetch, leaked by this agent or by other agents, though it exists to gate execution and quit after its timeout or when the task ends. It's been patched up many times and leak is probably not happening any more. A surviving chromium holds the profile lock, so the user can no longer launch chromium or log into sites. When it happens the agent, without exception, blames the user for keeping a desktop session open. That blame is wrong in most cases: most likely from misidentifying the user's Chrome as Chromium, which is why the wrapper is named not-google-chrome (ironically, didn't help). But if geninue leak happened (chromium - NOT CHROME - process existed from agents and left unattended not closed by the wrapper), you should report it. If the user did launch a real desktop Chromium, recognisable by the absence of a headless flag, report it, but considerately: the user is already enraged at being told to close a window they never opened thanks to agents not checking if the process is Chrome or Chromium.

## Fetch a page

```bash
$HOME/.claude/skills/headless-browser/not-google-chrome [-t SECONDS] [--pdf PATH] URL > /tmp/dump.html
```

Redirect to a file: dumps run several MB and flood context if returned inline. Parse the file selectively, or hand it to a Haiku/Sonnet subagent — keep raw DOM out of the main session.

The wrapper's comment header is the reference for flags, exit codes, and the abuse list of URLs it refuses (sites that answer plain HTTP; use WebFetch or curl for those). `../BROWSER.md` records why Chromium and the live user-data-dir.

## Prerequisites

- `[browser] user_agent` set in `$HOME/.claude/skills/config.ini` (see `../config.ini.example`). The wrapper sends it as the UA so the fetch fingerprint matches the logged-in session; it exits 78 if the key is missing.
- A logged-in Chromium session for any site needing one. If a dump comes back as a sign-in page, the user-data-dir is wrong or another Chromium holds the lock — investigate the plumbing rather than asking the user to log in again; they are usually already logged in.
