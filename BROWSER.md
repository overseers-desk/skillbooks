# Browser invocation

**Linux (snap Chromium):** `flock /tmp/chromium.lock timeout 10 chromium --user-data-dir="$HOME/snap/chromium/common/chromium" --headless=new --dump-dom --window-size=3840,2160 --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36" URL` (non-snap: `--user-data-dir="$HOME/.config/chromium"`; detect snap via `readlink -f $(which chromium)` resolving to `/usr/bin/snap`).

**macOS (Chrome):** `/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --user-data-dir="$HOME/Library/Application Support/Google/Chrome" --profile-directory="Profile 5" --headless=new --dump-dom --window-size=3840,2160 --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36" URL`

Use `--headless=new`, not legacy `--headless`. Do not set `--virtual-time-budget`. Keep the UA override; it defeats sites that block on the literal string `HeadlessChrome`. Always redirect `--dump-dom` output to a file (`> /tmp/page.html`); DOM dumps are commonly several MB and passing them directly to the caller floods the context.

Prefer `WebFetch` when the site allows it: the tool routes the response through a Haiku summarization step, keeping the main context small. Fall back to the browser approach when bot detection blocks `WebFetch`. Background and decisions: `BROWSER_WHY.md`.
