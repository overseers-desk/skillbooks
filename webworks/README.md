# Webworks: Programmatic Website Access

**Scope:** Direct programmatic access to a site's own API or DOM, or controlled access through headless browsers.

This document was created mainly due to the excessive premature commitment behaviour (firemaning) demonstrated by AI when doing this type of work.

AI would commit to 3 causes if something doesn't work, and circle between them:

1. Something is wrong with what the user has. User profile must be bad or corrupted (correct about two times a year). User wasn't logged in (sometimes yes, but AI will always suspect this). User had a Chromium browser running (sometimes true, but AI will report it without verifying that a desktop Chromium session exists).
2. The website detected a browser fingerprint. e.g. the website learned the browser is bot controlled by Browser String, by headless behaviour, by TLS handshake.
3. The website has banned, blocked, or throttled us. AI attributes every sign of error to this first. We have accessed it too frequently (sometimes true, but AI would name this even if the access rate is far slower than a real human, e.g. one click per 10 seconds or even one click per minute).

The big 3 share a shape: all three blame an anonymous external agent (a bad profile, a fingerprinting site, a throttling site), while mixing up Profile with User Data Dir. It is the equivalent of a police officer saying the murderer is almost certainly a drifter: the explanation closes the case without examining the scene, and it cannot be argued with because the culprit has no name and left no address. A "drifter" cause should not be filed until a test singles it out from the local, resident explanations (our own code, our own click, this specific target). If the proposed cause is an unnamed outsider and nothing rules out the residents, it is a drifter, and the residents have not been checked.

Being committed to the big 3 makes AI not enumerate plausible reasons and sometimes omit the obvious clue (e.g. that the code used to work, and by comparing the changes the cause may be discovered).

Method for finding and maintaining programmatic access to websites. It covers both first-time access and repairing skills that have broken, and is thus documented here to unstick AI.

Remember to spawn a subagent when suitable — it involves many tool calls and large outputs. Include the diagnostic procedure in the subagent prompt.

## How to write a skill as a modular skill, not as a prompt to the AI that overshadows other skills

A skill covers only what the target site's own API or DOM can do. Rules:

- Do not list capabilities that belong to other skills, even as a fallback or suggestion.
- Do not mention what the AI should do when this skill cannot fulfil the request.
- Do not assume or name the tools, browsers, or environment the user has — those are defined in `CLAUDE.md`.
- Do not list a missing capability as a capability. If the site cannot provide it, say nothing.

The Known access patterns section below is for hints when building access to a new site — not instructions for accessing any specific site. Entries are examples; they must not grow into full access guides.

## Driving a page: prefer the constant action, and match by name not visible text

Two ways a click-and-submit skill breaks on a machine other than the one it was written on, both avoidable while the skill is being written:

- **A button's shape is presentation; the action behind it is the constant.** A site moves a control, buries it in a menu, or drops it for a keyboard affordance. It does this per redesign and per A/B rollout, so two sessions logged into the same site at the same moment can differ. Where the action has a stable trigger, reach for that first. A message composer sends on Enter, a form submits on Enter, and a trusted keypress in the focused field survives a layout the button-shape match does not. Match a button only when no such trigger exists.

- **A visible text label is localized; a name is not.** A control reading "Send" reads "Enviar" for a Spanish session and "Senden" for a German one, so a match on the rendered words works on your machine and fails on the next. Prefer a stable handle over the text: a class, an aria role, a data attribute, or a form-level `type=submit`. When the visible label is the only option left, cover the locales you actually run rather than assuming English.

## How to get access to a website without the early false conclusion such as thinking a 403 response means TLS-level blocking

A response code is an observation, not a diagnosis. A 403 means the server rejected the request. It does not reveal why — the cause could be a User-Agent string, a missing header, a TLS fingerprint, an unsolved JS challenge, an IP block, or something else entirely. Each cause requires a different fix, and they must be distinguished by evidence, not by inference.

Do not write a causal explanation into a skill or access pattern unless you have verified it with a test that would have produced a different result if the cause were different. An unverified explanation written into a file becomes a false premise for every future session that reads it.

## When a fetch hangs or returns empty (not the same as blocked)

A 403 is the site rejecting you. A hang or an empty result is almost always local: the browser, the profile, or the launch, not the site. Same discipline (an observation is not a diagnosis), different bisection:

1. **Fresh temp `--user-data-dir` versus the real profile.** If a copy of the same data works elsewhere and the real profile does not, the fault is the profile or its location, not the site or the binary.
2. **CDP versus `--dump-dom`.** `--dump-dom` waits for the browser to report the page loaded; CDP navigates and reads `outerHTML` on a fixed timer. If CDP works and dump-dom hangs, the page never reports "done", so use CDP for that site.
3. **Count the renderer processes.** N renderers for a one-tab fetch means session restore reopened N tabs; then check the profile's `restore_on_startup`. (The serialised-browsing skill, if available, refuses a one-shot render when that is set to "Continue where you left off"; see its BROWSER.md.)
4. **`/proc/PID/wchan`** separates a true hang from mere slowness.

Red herrings observed once, worth skipping: the snap browser's process name is `chrome`, not `chromium`; the "zygote" errors are a symptom (`--single-process` removed them and the hang remained); `--timeout` cannot force a capture when no page renders; `--no-sandbox` and `--headless=old` changed nothing.

## Prerequisites

- A headless browser (use the serialised-browsing skill if available; see its BROWSER.md for context)
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
| Trying a different browser binary | All Chrome-compatible browsers share the same headless implementation. Swap variables one at a time: UA, then headers, then profile. |
| Adding anti-detection JS when the server returned 403 before serving any JS | No `<script>` tags in the response = no JS-level detection. The block is in passive request inspection. |
| Installing Playwright/Selenium for what `--dump-dom` can do | Only reach for automation if you need interaction (clicks, form fills, XHR waits). |
| Assuming "sophisticated bot detection" | Most detection is simple: UA string, TLS fingerprint, missing headers. Capture `curl -v` or `--log-net-log` and read it. |
| Guessing API parameter formats | If the API returns 400 (bad format) vs 422 (unknown field), the format is in the client JS bundle. Read it instead of guessing. |

## Key diagnostic tool

`--log-net-log=/tmp/netlog.json --net-log-capture-mode=Everything` on a headless Chrome-compatible browser captures actual request/response headers. Parse for `HTTP_TRANSACTION_SEND_REQUEST_HEADERS` and `HTTP_TRANSACTION_READ_RESPONSE_HEADERS` events.

## Known access patterns

### IHG (ihg.com)

- **Block mechanism:** Akamai reads the User-Agent. Headless Chrome-compatible browsers send `HeadlessChrome/...`. Override with `--user-agent`.
- **Open API endpoints:** `apis.ihg.com/availability/v3/hotels/offers` and `apis.ihg.com/locations/v1/destinations` work via curl. GraphQL is WAF-protected.
- **API key:** Static client-side key `se9ym5iAzaW8pxfBjkmgbuGjJcr3Pj6Y`.

### Marriott (marriott.com)

- **Open API endpoints:** Apollo GraphQL with operation safelisting — only pre-registered (name + query text + signature hash) tuples execute. Homepage-client signatures are accessible; search-page signatures (needed for pricing) are not.
- **Blocked paths:** `/search/` and hotel-detail pages return 403 for both curl and direct HTTP requests. Cause undiagnosed.

### Qantas (qantas.com)

- **Public Next.js SSR (no auth):** `flightrewardfinder.qantas.com` returns server-rendered HTML with flight data in `__next_f.push(...)` chunks. Plain `--dump-dom` works.
- **Authenticated SPA:** `www.qantas.com/au/en/frequent-flyer/my-account.html` is JS-rendered. The auth check fires after hydration, so `--dump-dom` captures the pre-hydration login redirect instead of the account view. Need CDP with a wait loop until the points value appears.
- **Login form:** at `/au/en/frequent-flyer/my-account/sign-in.html`. The `<form>` has no `action` attribute - submission is JS-handled. Inputs are `#memberId`, `#lastName`, `#pin`. CDP `Input.insertText` + button click works; curl POST does not.
- **Cookie persistence:** when the user has snap chromium running in the GUI, the headless instance does not flush cookies to disk on exit. Treat each authenticated read as one CDP session: log in, fetch, exit. Do not design around cross-process cookie reuse.
