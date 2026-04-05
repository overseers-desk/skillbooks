# Webworks: Programmatic Website Access

This method covers two situations:

1. **First access** — a website blocks programmatic access and you need to find a working path.
2. **Broken skill** — an existing skill that used to work has stopped working and needs fixing.

## Important: Spawn a subagent

Website debugging involves many tool calls and large outputs. Spawn a subagent to execute this workflow. Include the relevant procedure text below in the subagent prompt, followed by the goal.

## Prerequisites

- A headless browser. Refer to `~/.claude/CLAUDE.md` for the local browser command, profile path, and concurrency handling.
- curl

## When an existing skill breaks

Before diagnosing anything, test every capability the skill claims to have. Produce a table:

| Capability | Status | Notes |
|---|---|---|
| (each capability from the skill) | WORKS / BROKEN | (error message or data returned) |

Only then diagnose the broken capabilities using the diagnostic procedure below. Do not re-investigate capabilities that still work. The delta between what works and what doesn't tells you what changed on the website's side — that is where the fix is needed.

A single broken endpoint does not mean the site "blocks everything now." WAF rules are per-path. An API endpoint can be newly protected while the headless browser approach still works, or vice versa. Test each path independently.

## The diagnostic procedure (first access and broken capabilities)

Include this text verbatim in the subagent prompt:

---

You are finding a way to programmatically access a website. You are an experimenter-programmer. Follow this procedure for every command you run.

### Diagnostic list

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

1. Write the entry BEFORE running the command. If you cannot fill in "Hypothesis tested" and both outcome fields, you do not understand why you are running the command. Stop and think.

2. "If fails" must name something specific that gets ruled out. If failure would rule out nothing, the test has no diagnostic value. Design a better test.

3. After the command, fill in Result and Conclusion immediately.

4. If three consecutive entries test the same hypothesis or same category of cause, you are in a loop. Stop. List every hypothesis you have NOT tested. Pick the most different one.

5. When you believe you have the root cause, state it clearly, then state one test that would DISPROVE it. Run that test. If it disproves your finding, return to the list.

6. Never declare a problem unsolvable while untested hypotheses remain or standard diagnostic tools have not been used (verbose output, network logs, control-site comparison, header inspection).

7. When comparing a working case to a broken case, diff the observable evidence (headers, logs, status codes) rather than theorising about invisible mechanisms. The difference in the evidence IS the cause until proven otherwise.

---

## Anti-cargo-cult checklist

Before running a test, check this table. If your planned action matches the left column, it is probably cargo cult — a ritual repeated from pattern-matching rather than reasoning. The right column explains why and what to do instead.

| Cargo cult sign | Why it's cargo cult | Do instead |
|---|---|---|
| Increasing timeout beyond 10s for a page that returns immediately | A 403 or "Access Denied" arrives in <1s. Waiting longer does not change a server-side rejection. Timeouts only matter when the page is loading but incomplete (skeleton/spinner states). | Check the response time. If the error arrives fast, the problem is not timing. |
| Setting `DISPLAY=:0` without checking the display server | `DISPLAY=:0` is X11. If the machine runs Wayland, this works only by accident (XWayland). Copying it from another script is not reasoning. | Run `echo $XDG_SESSION_TYPE` first. On Wayland, use `WAYLAND_DISPLAY` or verify XWayland is running. |
| Switching to non-headless mode ("headed") as the fix | Non-headless requires a display server, a visible window, and often Playwright/Selenium. It is the heaviest possible solution. If headless fails, there is usually a specific detectable signal causing the failure (UA string, WebDriver flag, missing headers). Find the signal first. | Capture the actual request headers with `--log-net-log` and compare them to what a headed browser sends. The difference is usually one or two headers. |
| Retrying the same command with a different browser binary | If Chromium headless fails and Chrome headless also fails, the problem is not the browser binary. Both use the same rendering engine and headless implementation. | Identify what specifically is detected. Swap one variable at a time: UA string, then headers, then profile. |
| Adding anti-detection JS (removing `navigator.webdriver`, spoofing plugins) | If the server returned 403 before serving any JavaScript, JS-level detection did not run. The block is in passive request inspection (headers, TLS, UA). | Check whether the response contains any `<script>` tags. If not, JS detection is not the cause. |
| Installing Playwright/Selenium/Puppeteer to "automate" what `--dump-dom` could do | `--dump-dom` with the right flags is sufficient for read-only scraping. Automation frameworks add dependencies, complexity, and their own detection surface. | Only reach for automation if you need to interact with the page (click, fill forms, wait for XHR). For static reads, `--dump-dom` is correct. |
| Trying the site's API without checking if it is protected separately | A site may protect its HTML pages but leave API endpoints open (or vice versa). These are independent WAF rules. | Test the API endpoint independently with curl. It may work even when the HTML pages are blocked. |
| Assuming the problem is "sophisticated bot detection" | Most bot detection is simple: UA string, missing headers, wrong TLS fingerprint. Sophisticated detection (canvas fingerprinting, behavioral analysis) exists but is rarer and only triggers after basic checks pass. | Start with the simplest explanations. Capture verbose output (`curl -v`, `--log-net-log`) and read it before theorising. |
| Guessing API parameter formats by trying variations | If an API recognises a field name but rejects the value (e.g. 400 "invalid format" vs 422 "unknown field"), the correct format is in the client-side JS that constructs the request. Guessing is unbounded; reading the source is definitive. | Fetch the site's JS bundles via headless browser, search for the field name, and read the code that builds the request object. |

## Key diagnostic tool

Chrome/Chromium's `--log-net-log=/tmp/netlog.json --net-log-capture-mode=Everything` captures the actual request and response headers the browser sent and received. This is sufficient to identify UA string issues, missing cookies, redirects, and response codes. Parse the JSON for `HTTP_TRANSACTION_SEND_REQUEST_HEADERS` and `HTTP_TRANSACTION_READ_RESPONSE_HEADERS` events.

## Known access patterns (discovered by testing)

### IHG (ihg.com)

- **Block mechanism:** Akamai WAF reads the User-Agent string. Headless Chrome sends `HeadlessChrome/...` instead of `Chrome/...`. Override with `--user-agent`.
- **Open API endpoints:** `apis.ihg.com/availability/v3/hotels/offers` and `apis.ihg.com/locations/v1/destinations` accept curl with no browser session. The GraphQL endpoint (`apis.ihg.com/graphql/v1/hotels`) is WAF-protected.
- **API key:** Embedded in the JS bundle, static: `se9ym5iAzaW8pxfBjkmgbuGjJcr3Pj6Y`. Works without cookies.
