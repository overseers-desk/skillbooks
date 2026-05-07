# Browser strategy for skills

## Editorial rule

The word **Chrome** appears in this repository under three permitted forms only:

1. As part of the unsuitability argument that follows in this file — explaining why Chrome the product is not used.
2. As part of the phrase **Chrome-compatible**, used to describe a class of browsers, a User-Agent shape, or a binary surface.
3. As part of a technology name defined by Chrome — for example **Chrome DevTools Protocol** (CDP) — where the word is the proper name of the technology, not a reference to the product.

It must not appear as a product reference outside form 1. New code or documentation that names Chrome as the product to use, install, or launch is to be rewritten in terms of Chromium. This is because Chrome has an outsized representation in LLM training data, any mention of Chrome once in documents or code, AI starts to launch Chrome when this document detailed why we chose to use Chromium for the skills.

The word **Chromium** in this repository should be changed to Chrome-compatible when it refers to generic idea of Chrome-like browsers such as Chromium.

## Problem

Skills that reach the web face a tangle of related problems.

1. Some target sites refuse to log in inside Cursor's MCP browser, inside headless Chrome with a separate profile, or inside any session that registers as "obviously automated." The user has been denied at login this way and the exact triggering signal was never isolated.
2. Chrome 136 and later (released April 2025) refuse `--remote-debugging-port` and `--remote-debugging-pipe` whenever `--user-data-dir` resolves to the user's default profile. Browser skills that need the cookies in that profile cannot use Chrome at all.
3. Chrome on macOS hangs after `--dump-dom` finishes rendering. Even where the profile restriction would not bite, the dom-dump skills cannot exit cleanly.
4. Each browser-using skill independently encounters the same questions: which binary, which profile, what to do when the user is not logged in, how to ask the user to log in. Without a shared answer, every new skill rediscovers the constraints and each prompts the user with different wording when cookies are missing.
5. The bot-detection question itself is open-ended. Datadome, Akamai Bot Manager, PerimeterX, Cloudflare, and hCaptcha each run their own probes (CDP runtime side-effects, headless markers, fresh-profile signals, mouse-entropy scoring), and the probes change without notice. Walking into that space costs days and yields a fix that may break on the vendor's next deploy.

## Decisions

The following decisions resolve the problems above.

**D1. Use Chromium, not Chrome.** Resolves problems 2 and 3. The currently installed Chromium build (from the snap channel on Linux, the Homebrew cask on macOS) does not enforce the upstream user-data-dir restriction that Chrome 136+ ships, and Chromium exits cleanly after `--dump-dom` on macOS. Recorded in commit `5d1dc6f`.

**D2. Use the user's real, logged-in profile, not a fresh user-data-dir.** Resolves problem 1 in the most direct way available: a session indistinguishable from the user's own activity is hard to flag, because it is the user's own activity. Fresh-profile sessions fail both fingerprinting probes and account-level "new device" heuristics; the operational cost of using the live profile (see D5) is accepted in exchange.

**D3. Decline to diagnose why Cursor's MCP browser was denied on specific sites.** Resolves problem 5 by not entering it. Whether the cause was CDP runtime side-effects, headless markers (software WebGL, screen-size leaks, Sec-CH-UA mismatches), or fresh-profile signals, the design chosen under D2 sidesteps all three categories at once. A diagnosis tuned to one probe is bypassed when the vendor adds another.

**D4. Browser skills use uniform wording when cookies are missing.** The convention is "please open Chromium, log in to X, then tell me to proceed." Resolves problem 4 on the human-facing side. Implementation lives inside each skill; the prompt wording is the cross-skill contract.

**D5. Sessions are short-lived and exclusive on the profile.** Chromium locks `--user-data-dir` for the duration of the process. Two browser skills cannot run in parallel against the same profile, and the user's everyday Chromium has to be closed while a skill runs. The design accepts this rather than holding a long-running browser process.

## Resulting state

Skills split into two groups by whether the decisions above apply.

**Browser skills** ride D1-D5. Examples: otter.ai, ihg.com, qantas.com, linkedin.com, facebook.com, instagram.com, supplier.getyourguide.com, atdw-online.com.au, australia.skal.org, interlinetravel.com.au, deviantart.com, marriott.com. Each launches Chromium against the user's profile, dumps DOM or attaches CDP, runs the task, exits, releases the lock.

**API / non-browser skills** are not affected by D1-D5 because they do not touch a browser. Examples: serpapi, renfe.com, claude-api, send-email, mailroom. Credentials live in environment variables or `~/.claude/skills/config.ini`.

Profile paths per platform: `~/snap/chromium/common/chromium` on Linux snap, `~/.config/chromium` on Linux non-snap, `~/Library/Application Support/Chromium` on macOS (Chromium installed via the Homebrew cask, default profile). The snap-vs-non-snap probe and the canonical launch flags live in `bin/not-google-chrome`, the wrapper that all skills call.

When a skill written for the future runs into a login denial on a target site, the first action is not to harden the fingerprint. The first action is to verify the user is actually logged in inside the same Chromium profile, run the page in a non-headless Chromium to confirm the account itself works, and only then ask whether D3 needs revisiting for that specific site.

## Caveats worth tracking

- D1 rests on a snap/distro version observation, not an architectural guarantee. Upstream Chromium has the user-data-dir restriction patch. If the snap channel ever ships a build that adopts it, every browser skill breaks at the CDP launch step and there is no fallback wired in. A periodic check of `chromium --version` against the upstream announcement is the only early warning.
- D2 does not eliminate fingerprint detection. The software WebGL renderer that comes with `--disable-gpu` is detectable, and some sites may still deny on that signal even with a real profile. Treated as a residual failure mode handled per-skill if it becomes recurring, not by reopening the global strategy.
- The snap and non-snap Chromium variants read different profile directories and are not interchangeable. The user logs in once in whichever variant is installed; skills follow the same variant.
