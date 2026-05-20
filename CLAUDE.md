# Aesop skills — notes for AI sessions

`~/.claude/skills` is a symlink to this repo. All skill paths in SKILL.md files use `$HOME/.claude/skills/<skill>/script` — do not use `$HOME/code/aesop/`.

## Headless browser access

Skills that need to fetch a URL call the `not-google-chrome` wrapper, provided by the headless-browser skill:

```bash
not-google-chrome [-t SECONDS] URL > /tmp/output.html
```

The wrapper handles platform detection, flock, timeout, UA override, and user-data-dir resolution. The headless-browser skill is the home of its path and usage; the wrapper's comment header is the reference for the underlying invocation, and `BROWSER.md` covers the strategy and rationale. Never write the raw `flock ... chromium ...` invocation inline in a skill: use the wrapper.

## CDP scripts (authenticated SPAs)

Sites that require login and use JavaScript-rendered content need Chrome DevTools Protocol instead of `--dump-dom`. CDP scripts launch a headless browser via `subprocess`, connect to its debug port over a local WebSocket, and execute JS `fetch()` calls or intercept network responses from within the browser.

CDP runs `ws://` on localhost (no TLS, no extensions, no compression), so the four CDP scripts in this repo (`airbnb.com/airbnb-cdp.py`, `otter.ai/otter-cdp.py`, `qantas.com/login.py`, `linkedin.com/send-invite.py`) hand-roll a small set of `_ws_*` helpers over stdlib `socket`, `struct`, `base64`, `os`. The helpers are copy-pasted across the four files so each runs self-contained when called by absolute path. If a fifth or sixth script lands and the copy-paste starts to drift, pulling them into a shared module is worth revisiting.

**User-data-dir lock.** CDP scripts use the same user-data-dir as the GUI browser. The user must close their browser before running a CDP script, otherwise the headless instance cannot read cookies and will land on a login page.

## Credentials

Site credentials live in `$HOME/.claude/skills/config.ini`. The file is outside this repo, do not commit it. Each skill's SKILL.md documents the required keys under a `Prerequisites` section.

## Testing skills

Use `claude -p --dangerously-skip-permissions "<natural language request>"` to invoke a skill end-to-end. Calling the script directly with `python3` only tests the script, not the skill trigger. Do not report a skill as working until `claude -p` returns real data.
