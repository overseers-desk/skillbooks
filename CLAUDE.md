# Aesop skills — notes for AI sessions

`~/.claude/skills` is a symlink to this repo. All skill paths in SKILL.md files use `$HOME/.claude/skills/<skill>/script` — do not use `$HOME/code/aesop/`.

## Headless browser access

Skills that need to fetch a URL use the wrapper at `$HOME/.claude/skills/bin/not-google-chrome`:

```bash
$HOME/.claude/skills/bin/not-google-chrome [-t SECONDS] URL > /tmp/output.html
```

The wrapper handles platform detection, flock, timeout, UA override, and profile selection. Its comment header is the canonical reference for the underlying invocation; `BROWSER.md` covers the strategy and rationale. Never write the raw `flock ... chromium ...` invocation inline in a skill: use the wrapper.

## CDP scripts (authenticated SPAs)

Sites that require login and use JavaScript-rendered content need Chrome DevTools Protocol instead of `--dump-dom`. CDP scripts launch a headless browser via `subprocess`, connect to its debug port over a local WebSocket, and execute JS `fetch()` calls or intercept network responses from within the browser.

**No external dependencies.** CDP scripts in this repo use a `_WebSocket` class implemented in stdlib (`socket`, `struct`, `base64`, `os`). Do not install `websocket-client`, `websockets`, or Playwright. Do not suggest `pip install` for anything — on macOS with Homebrew, pip installs into a different Python environment than the one `python3` resolves to, so packages installed that way are silently invisible at runtime.

The `_WebSocket` class is replicated verbatim in each CDP script rather than extracted to a shared lib. This keeps scripts self-contained when called by absolute path. If there are ever 5+ CDP scripts it is worth revisiting, but for now copy-paste is correct.

Current CDP scripts: `otter.ai/otter-cdp.py`, `airbnb.com/airbnb-cdp.py`.

**Profile lock.** CDP scripts use the same browser profile as the GUI browser. The user must close their browser before running a CDP script, otherwise the headless instance cannot read cookies and will land on a login page.

## Credentials

Site credentials live in `$HOME/.claude/skills/config.yaml` (the file is outside this repo — do not commit it). Each skill's SKILL.md documents the required keys under a `Prerequisites` section.

## Testing skills

Use `claude -p --dangerously-skip-permissions "<natural language request>"` to invoke a skill end-to-end. Calling the script directly with `python3` only tests the script, not the skill trigger. Do not report a skill as working until `claude -p` returns real data.
