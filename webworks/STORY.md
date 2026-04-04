# How this method came to be

In April 2026, an Opus session was asked to programmatically fetch a page from ihg.com. The page loaded fine in a normal browser. curl got 403. Headless Chrome got "Access Denied."

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
