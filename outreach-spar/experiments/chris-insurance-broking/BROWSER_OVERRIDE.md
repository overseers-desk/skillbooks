# Browser override — this campaign only

**Scope:** applies to any LinkedIn fetch subagent working in `/home/weiwu/code/aesop/chris-insurance-broking/`. Does NOT modify the user-level `~/.claude/CLAUDE.md`.

**Rationale:** the default headless command in `~/.claude/CLAUDE.md` targets `chromium` (snap-installed) against its snap profile `$HOME/snap/chromium/common/chromium`, which is logged in as **Chris Graham**. For a second discovery pass from Weiwu Zhang's 1st-degree network, use Weiwu's `google-chrome` profile instead.

## Exact invocation for this campaign when fetching LinkedIn as Weiwu

```bash
flock /tmp/google-chrome.lock timeout 30 google-chrome \
  --headless=new \
  --dump-dom \
  --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36" \
  --user-data-dir="$HOME/.config/google-chrome" \
  --window-size=1280,800 \
  "URL" > out.html
```

## Rules

- Binary: `google-chrome` (not `chromium`). `which google-chrome` → `/usr/bin/google-chrome`, NOT a snap symlink.
- Profile: `$HOME/.config/google-chrome`, NOT the snap path.
- Lock: `/tmp/google-chrome.lock`. Different from the chromium lock so both can run in parallel if needed (they are different binaries with different profiles, no actual collision risk).
- Flags are otherwise identical to the CLAUDE.md chromium pattern: `--headless=new`, no `--virtual-time-budget`, UA override to defeat `HeadlessChrome` detection.
- Verification: the first fetch should produce a DOM whose `<title>` contains `Feed | LinkedIn` (not "Sign In") and whose JSON payload contains `"firstName":"Weiwu"` / `"lastName":"Zhang"`. If instead the title contains "Sign In" or the firstName is different, stop — do not proceed with a broken profile.

## When to use chromium vs google-chrome in this campaign

- `chromium` + `$HOME/snap/chromium/common/chromium` → Chris's LinkedIn identity (all 1A/1B/2B searches earlier in the campaign used this).
- `google-chrome` + `$HOME/.config/google-chrome` → Weiwu's LinkedIn identity (this second discovery pass; tag rows with `discovered_via=weiwu-1st-degree` or `weiwu-2nd-degree`).

Do not mix profiles in a single subagent run — each subagent should use one profile and tag its rows accordingly.
