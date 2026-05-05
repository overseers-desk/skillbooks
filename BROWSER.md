# Browser invocation

Skills use `$HOME/.claude/skills/bin/browser [-t SECONDS] URL [extra-flags...]` for headless DOM dumps. Output is on stdout; redirect to a file (dumps are commonly several MB and flood context if returned to the caller). Default timeout 15s. Pass extra Chrome-compatible flags after the URL when a specific skill needs them (e.g. `--virtual-time-budget=N`, `--log-net-log=PATH`).

macOS prerequisite: `brew install util-linux coreutils` for `flock` and `gtimeout`. Linux has both natively.

The wrapper detects platform and runs the canonical incantation:

**Linux (snap Chromium):** `flock /tmp/chromium.lock timeout 15 chromium --user-data-dir="$HOME/snap/chromium/common/chromium" --headless=new --dump-dom --window-size=3840,2160 --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36" URL` (non-snap: `--user-data-dir="$HOME/.config/chromium"`; detect snap via `readlink -f $(which chromium)` resolving to `/usr/bin/snap`).

**macOS:** `/opt/homebrew/opt/util-linux/bin/flock /tmp/chromium.lock gtimeout 15 "/Applications/Chromium.app/Contents/MacOS/Chromium" --user-data-dir="$HOME/Library/Application Support/Chromium" --headless=new --dump-dom --window-size=3840,2160 --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36" URL`

Use `--headless=new`, not legacy `--headless`. Do not set `--virtual-time-budget` for general use; a few skills (instagram, facebook) pass it explicitly because their JSON or JS-rendered endpoints need a budget. Keep the UA override; it defeats sites that block on the literal string `HeadlessChrome`.

Prefer `WebFetch` when the site allows it: it converts HTML to plain text before loading into context, which is far smaller than a raw DOM dump. Fall back to the wrapper when bot detection blocks `WebFetch`. Background why we chose chromium: `BROWSER_WHY.md`.
