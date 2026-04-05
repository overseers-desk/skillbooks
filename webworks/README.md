# Webworks: Programmatic Website Access

Method for finding and maintaining programmatic access to websites. Covers both first-time access and repairing skills that have broken.

Spawn a subagent for this work — it involves many tool calls and large outputs. Include the diagnostic procedure in the subagent prompt.

## Prerequisites

- A headless browser (see `~/.claude/CLAUDE.md` for the local command, profile, and concurrency)
- curl

## When repairing a broken skill

Before diagnosing, test every capability the skill claims. Produce a works/broken table. Then apply the diagnostic procedure below only to broken capabilities. WAF rules are per-path — one broken endpoint does not mean the site blocks everything.

## Diagnostic procedure

Include this verbatim in the subagent prompt:

---

You are finding a way to programmatically access a website. You are an experimenter-programmer.

Every test you run gets an entry BEFORE you run it:

```
## Test N: (one-line summary)
- Hypothesis tested:
- If succeeds, confirms/rules out:
- If fails, rules out:
- Command:
- Result: (fill after)
- Conclusion: (fill after)
```

Rules:

1. Fill in all fields before running the command. If you cannot state the hypothesis and both outcomes, you do not understand why you are running it.

2. "If fails" must name something specific. If failure rules out nothing, the test is worthless.

3. Fill Result and Conclusion immediately after.

4. Three consecutive entries on the same hypothesis means you are looping. List untested hypotheses and pick the most different one.

5. Before declaring a root cause, state one test that would disprove it. Run that test.

6. Never declare unsolvable while standard diagnostics remain unused (verbose output, net-log, control-site comparison).

7. Diff the evidence between a working case and a broken case. The difference IS the cause until proven otherwise.

---

## Anti-cargo-cult checklist

Check before running any test. Left column = cargo cult sign, right column = what to do instead.

| Sign | Do instead |
|---|---|
| Increasing timeout for a response that arrives instantly | A 403 in <1s is a server-side rejection. Timeouts only matter for incomplete page loads (skeleton/spinner). |
| `DISPLAY=:0` without checking display server | `echo $XDG_SESSION_TYPE`. Wayland machines need `WAYLAND_DISPLAY` or confirmed XWayland. |
| Switching to non-headless ("headed") mode | Find the specific detection signal first. Capture request headers with `--log-net-log` and diff against a headed browser. Usually one or two headers differ. |
| Trying a different browser binary | Chromium and Chrome use the same headless implementation. Swap variables one at a time: UA, then headers, then profile. |
| Adding anti-detection JS when the server returned 403 before serving any JS | No `<script>` tags in the response = no JS-level detection. The block is in passive request inspection. |
| Installing Playwright/Selenium for what `--dump-dom` can do | Only reach for automation if you need interaction (clicks, form fills, XHR waits). |
| Assuming "sophisticated bot detection" | Most detection is simple: UA string, TLS fingerprint, missing headers. Capture `curl -v` or `--log-net-log` and read it. |
| Guessing API parameter formats | If the API returns 400 (bad format) vs 422 (unknown field), the format is in the client JS bundle. Read it instead of guessing. |

## Key diagnostic tool

`--log-net-log=/tmp/netlog.json --net-log-capture-mode=Everything` on headless Chrome captures actual request/response headers. Parse for `HTTP_TRANSACTION_SEND_REQUEST_HEADERS` and `HTTP_TRANSACTION_READ_RESPONSE_HEADERS` events.

## Known access patterns

### IHG (ihg.com)

- **Block mechanism:** Akamai reads the User-Agent. Headless Chrome sends `HeadlessChrome/...`. Override with `--user-agent`.
- **Open API endpoints:** `apis.ihg.com/availability/v3/hotels/offers` and `apis.ihg.com/locations/v1/destinations` work via curl. GraphQL is WAF-protected.
- **API key:** Static client-side key `se9ym5iAzaW8pxfBjkmgbuGjJcr3Pj6Y`.
