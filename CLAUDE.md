# Aesop skills — notes for AI sessions

`~/.claude/skills` is a symlink to this repo. All skill paths in SKILL.md files use `$HOME/.claude/skills/<skill>/script` — do not use `$HOME/code/aesop/`.

## Headless browser access

Skills that need to fetch a URL call the `not-google-chrome` wrapper, provided by the headless-browser skill:

```bash
not-google-chrome [-t SECONDS] URL > /tmp/output.html
```

The wrapper handles platform detection, flock, timeout, UA override, and user-data-dir resolution. The headless-browser skill is the home of its path and usage; the wrapper's comment header is the reference for the underlying invocation, and `BROWSER.md` covers the strategy and rationale. Never write the raw `flock ... chromium ...` invocation inline in a skill: use the wrapper.

## CDP scripts (authenticated SPAs)

Sites that require login and use JavaScript-rendered content need Chrome DevTools Protocol instead of `--dump-dom`. The `not-google-chrome --cdp -- <client command>` wrapper owns the browser lifecycle: it launches the headless browser, exports `CDP_WS_URL` (a page-target websocket) and `CDP_PORT` into the client's environment, and tears the browser down on every exit path (flock, deadman, snap-robust kill). A CDP script is a pure client: it reads `CDP_WS_URL`, connects over the local WebSocket, and executes JS `fetch()` calls or intercepts network responses from within the page. It holds no browser PID and never launches a browser itself. Run one as `not-google-chrome --cdp -- python3 <skill>/<script>.py ...`; a script invoked without `CDP_WS_URL` in its environment exits with a usage line.

CDP runs `ws://` on localhost (no TLS, no extensions, no compression), so the CDP client scripts hand-roll a small set of `_ws_*` helpers over stdlib `socket`, `struct`, `base64`, `os`, copy-pasted so each runs self-contained. The copy-paste now spans every CDP client (linkedin, facebook, airbnb, otter, qantas, and the instagram family), so pulling the helpers into a shared module is worth revisiting.

**User-data-dir lock.** The CDP browser uses the same user-data-dir as the GUI browser. The user must close their browser before running a CDP script, otherwise the headless instance cannot read cookies and will land on a login page.

## Credentials

Site credentials live in `$HOME/.claude/skills/config.ini`. The file is outside this repo, do not commit it. Each skill's SKILL.md documents the required keys under a `Prerequisites` section.

## Testing skills

Use `claude -p --dangerously-skip-permissions "<natural language request>"` to invoke a skill end-to-end. Calling the script directly with `python3` only tests the script, not the skill trigger. Do not report a skill as working until `claude -p` returns real data.
