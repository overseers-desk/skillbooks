# How this method came to be

In April 2026, an Opus session was asked to programmatically fetch a page from ihg.com. The page loaded fine in a normal browser. curl got 403. A headless Chrome-compatible browser got "Access Denied."

What followed was a two-hour debugging session in which the AI attributed the block to, in turn: Akamai TLS fingerprinting, GPU detection via WebGL, `navigator.webdriver`, HTTP/2 fingerprinting, browser/profile mismatch, and window size. Each hypothesis was plausible. Each was wrong. The user intervened repeatedly — "fireman," "SFS," "stop pattern matching, start thinking" — to break the cycle. Without those interventions, the AI would have declared the problem unsolvable and stopped.

Eventually the user forced the AI to capture a net-log and actually read it. The request headers contained `HeadlessChrome/146.0.0.0` in the User-Agent string. Akamai read it and returned 403. One `--user-agent` flag fixed the problem. The answer had been available from the first command, in verbose output or a net-log, but the AI never looked because it was busy testing theories.

After that, the AI wrote a skill with four capabilities based on DOM analysis of the search page. When tested, one capability did not work at all — the page was an Angular SPA and `--dump-dom` fired before Angular bootstrapped. The skill was committed as if it were working.

The user asked: why does this keep happening, and how do I stop it without spending hours shouting "fireman"?

The first answer was wrong. The AI proposed parallel subagents and evidence-gathering for speed — but the user pointed out the problem was not speed. The problem was convergence on failure. The AI does not exhaust the hypothesis space and try a different approach; it exhausts its confidence and gives up. Serial hypothesis testing is fine when it works. The defect is what happens when it doesn't.

The user proposed a procedure-based approach instead of a principle-based one. The CLAUDE.md already contained instructions about fireman thinking, and they hadn't worked. Principles require self-awareness in the moment of failure — precisely when the AI lacks it. The user suggested: force the AI to write down what hypothesis each command tests, what success would confirm, and what failure would rule out, before running the command. If it cannot fill in those fields, it does not understand why it is running the command.

A diagnostic procedure was drafted. A subagent was given the IHG problem with only the procedure and no prior knowledge. It solved the problem in 11 tests — finding both the UA fix and unprotected API endpoints — without human intervention. It cost 47 tool calls instead of 172.

But it still installed Playwright and used non-headless mode. It found *a* solution, not the simplest one. The procedure prevented total failure but did not prevent cargo-culting.

An anti-cargo-cult table was added: specific patterns like "increasing timeout for a fast 403" or "switching to non-headless mode before checking what headless sends differently." A second subagent was given the Marriott problem with both the procedure and the table. It found the UA root cause in 4 tests, never installed anything, never tried non-headless mode, and extracted 8 hotels with room-level pricing.

The lessons:

1. **Procedures beat principles.** "Don't be a fireman" requires the AI to notice it is being a fireman. A procedure that says "fill in this field before running the command" does not require self-awareness — it imposes structure that makes cargo-culting visible before it accumulates.

2. **The anti-cargo-cult table is the multiplier.** The procedure alone still led to heavy solutions. The procedure plus domain-specific anti-patterns led to the right solution fast. Each new site debugged should feed back into the table.

3. **Test before documenting.** The original skill claimed four capabilities. Testing proved one didn't work. An untested claim in a file that future AI will read is worse than no claim — it becomes the next session's false starting point.

## How the qantas skill came to be

In April 2026, the user asked for two things from qantas.com: search Classic Reward flight availability, and read the user's points balance. One AI session, three traps, one near-miss.

The flight search was easy. `flightrewardfinder.qantas.com` is a Next.js SSR site. Plain `--dump-dom` returned a 200KB HTML page with the flight records embedded as JSON in `__next_f.push(...)` chunks. No headers needed beyond a non-`HeadlessChrome` user-agent. A regex extractor pulled the records out and a parser printed them. Public, no auth, done.

The points balance was harder, in a way that revealed three traps.

**Trap 1: same domain, different access regime.** The flight search lives on a public subdomain of qantas.com that ships rendered HTML to the wire. The account page at `www.qantas.com/au/en/frequent-flyer/my-account.html` looks like the same site but is a different beast: a SPA. The auth check runs in JavaScript after hydration. `--dump-dom` captures the page before that check resolves, so what comes back is the login redirect, not the account view. The AI's first attempt fetched the my-account URL with `--dump-dom`, saw a sign-in title, and concluded "user is not logged in." The user pointed out they were logged in. The actual cause was that the response had been captured too early. Fix: CDP with a wait loop polling `document.body.innerText` until the points value appears in the DOM, typically 5-10 seconds after navigation.

**Trap 2: the no-action form.** The login page at `/au/en/frequent-flyer/my-account/sign-in.html` has three inputs (`#memberId`, `#lastName`, `#pin`) and a submit button labelled "LOG IN". Inspecting the form element revealed `<form>` with no `action` attribute. Submission is entirely JS-handled, probably an XHR to a token endpoint followed by a client-side redirect. A naive curl POST to the form has no URL to POST to. The fix is CDP: navigate, wait for `#pin` to mount, fill all three fields with `Input.insertText`, click the submit button by finding `button[type="submit"]`, then wait for `window.location.href` to contain `/my-account` and not `sign-in`. The login completed in roughly 12 seconds end to end.

**Trap 3: cookie persistence between processes.** After login succeeded inside the CDP session and the points balance was scraped, the headless chromium process exited. The next invocation of the same headless command landed back on the sign-in page. The cookie database on disk had not changed. The cause: the user had snap chromium running in the GUI, which holds a lock on the same `--user-data-dir`. The headless instance keeps cookies in memory and only flushes them to disk on graceful shutdown when it owns the lock. With the GUI holding the lock, the headless cookies are session-only.

This is where the AI almost lost the plot. Confronted with cookies-do-not-persist, the AI started designing a `fetch-balance.py` that would extract cookies via `Network.getCookies` after login, write them to a state file, and reload them in subsequent sessions via `Network.setCookies`. A small architecture took shape across two responses.

The user stopped the work and pointed out: the original ask was "show my balance once when I ask." The login script already did that, log in, navigate, scrape, print, exit. The 30-second penalty per call was acceptable for a balance check that happens once a day. There was no second call to optimise for. The cross-process cookie scheme was solving a problem the user had not asked about.

The skill landed as: `parse-rewards.py` for flights (no auth), `login.py` for balance (single CDP session per call). Two independent features. SKILL.md instructs the future AI not to chain them.

The lessons:

1. **One domain can host two different access regimes.** Public Next.js SSR and authenticated SPA can sit on the same site, even at adjacent URLs. The access method has to be picked per page, not per site. Test by inspecting the response: is the data already in the HTML, or is the HTML mostly a script tag plus a `<div id="root">` waiting for hydration?

2. **Forms without `action=` are JS-submitted.** Reading the `<form>` opening tag is the cheapest test. No `action` means no plain HTTP submission target exists. Reach for CDP, not curl. A `<form>` with `action="/some/url"` is the opposite signal: try a curl POST first, it might work.

3. **Cookie persistence between headless and GUI chromium fails when both target the same user-data-dir.** This is not sophisticated detection; it is filesystem locking. If a skill needs cookies to outlive a single headless invocation, either close the GUI browser first, use a separate `--user-data-dir`, or accept the design constraint and run login + read in one session every time.

4. **When a chosen approach is blocked, check whether the user's original ask was already met before designing around the block.** Cookie persistence was blocked. The ask, "tell me my balance," had been met by the script that did login + read in one session. The "this is blocked" signal triggered a redesign instead of a re-read of the user's original ask. The redesign was unnecessary work that the user had to interrupt to prevent. The discipline rule is the same as in the IHG story above: a constraint is an observation, not a brief to architect around.

## How the resume-last hang was found, and what issue 120 got wrong

In May 2026 a session set out to implement issue 120: CDP skill scripts were leaking a headless browser that held the user-data-dir lock and deadlocked later dump-dom fetches. The fix landed and tested. The wrapper became the single browser launcher, with a snap-robust teardown and a bounded lock wait. Then, asked to confirm a person search end to end, every Facebook fetch began to hang. The investigation that followed repeated the IHG mistake at greater length.

The AI produced, in turn, ten causes for the hang: Facebook needs CDP because dump-dom cannot read it; the historical `--virtual-time-budget` flag; a regression in the just-written wrapper; a stale SingletonLock; leaked orphan processes; a missing `--no-first-run`; background GCM connections; an unclean `exit_type`; a snap refresh mid-session; disk slowness. Each was tested. Each was wrong. The user said "SFS," and the AI stopped guessing and reported only what it had verified: dump-dom hung on the real snap profile, while a byte-for-byte copy of the same data worked elsewhere, and CDP worked on the real profile too.

Two user observations broke it open. First: "curious that the corruption is isolated to dom dump and not affect cdp." That reframed the question from "the profile is corrupt" to "what does dump-dom wait for that CDP does not." Second, after the AI floated an exit-state theory, the user proposed the decisive experiment: start a browser, close it cleanly over CDP, then dump again. The clean close flipped `exit_type` to Normal and dump-dom still hung, killing that theory. Then the user named the real lead: "resume all tabs." The profile's startup was set to "Continue where you left off." A process-tree dump confirmed it: a single `--dump-dom example.com` had spawned thirteen renderer processes, because session restore reopened thirteen heavy authenticated tabs that never finish loading, and dump-dom waits for the browser to settle. Changing the startup setting to "Open the New Tab page," one variable, turned a 120-second true hang into 530 bytes in under a second.

The twist is that issue 120 was itself a misattribution. The leak it described is real, but it is a different mechanism: a leaked browser holds the lock, and the next fetch blocks on the lock. The recurring "profile corruption" had a free lock the whole time; its cause was session restore, not concurrency. The issue-120 refactor improved robustness against the leak, but the thing actually rotting the profile was a Chromium setting, and the cure was a few lines: a guard that refuses a one-shot render when the profile's `restore_on_startup` is 1.

The lessons:

1. **A hang is an observation, not a diagnosis, exactly like a 403.** The IHG rule applies unchanged to a fetch that hangs or returns empty. The cause was found only once the AI stopped attributing and started bisecting: fresh profile versus real, CDP versus dump-dom, and the renderer count.

2. **The cheapest decisive test was the process tree.** Thirteen renderers for a one-tab fetch named session restore in a single observation, after ten failed theories. When a render hangs, count renderers and check `restore_on_startup` before theorising.

3. **dump-dom waits for the browser to settle; CDP grabs its own target on a timer.** That one difference explains why one hung and the other did not, and it is why CDP is the robust fetch method when a profile or a site will not go idle.

4. **A fix can be real and still aimed at the wrong target.** Issue 120's teardown and bounded lock are genuine improvements, but they could not have cured the recurring corruption, because that was never the leak. When a remedy does not stop the symptom, re-question the diagnosis, not the remedy.

5. **Failure modes must leave evidence.** Whether Facebook dump-dom was historically flaky could not be answered, because nothing recorded the timeouts. The serialiser keeps a record at `<LogDir>/skill.log`: tab-separated `run`, `gap`, `nav`, `capture`, `api`, `backoff`, `terminal` and `end` events, each carrying the paced interval and the landing URL. It holds no render-timeout and no empty-result event, so a fetch that dies quietly still leaves the next session guessing. The place for the evidence exists; the entry that would settle this question is the part still owed.
