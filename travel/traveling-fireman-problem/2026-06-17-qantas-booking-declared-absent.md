---
date: 2026-06-17
pwd: /home/weiwu/code/aesop/travel
session_id: be4b5fa2-3d12-4e22-b40e-e7863dea698d
transcript: ~/.claude/projects/-home-weiwu-code-aesop-travel/be4b5fa2-3d12-4e22-b40e-e7863dea698d.jsonl
---

# Qantas booking declared absent from all mailboxes, on a head-truncated search of the wrong sender domain

The task was to find every invoice for a June 2026 multi-leg family trip (Spain → London → Asia → Brisbane → Gold Coast) and file them for reconciliation against the CPL company card. Five IMAP mailboxes are configured in `mailroom`.

## Pre-fireman sequence

1. `mailroom -A search 'qantas' search 'gold coast' search 'OOL'`, output piped through `head -80`. The raw JSON is verbose, so `head -80` showed only two or three messages, all marketing (a DBS travel promo, an "Experience Gold Coast" newsletter, a "perks before you travel" bank mail). Conclusion: noise.

2. `mailroom -A search 'from:qantas.com' search 'from:qantas' search 'subject:itinerary'`, formatted one line per message, piped through `head -60`. `from:qantas.com` returned five messages, all `upgradeoffers@qantas.com` (2024–2025 bid-for-upgrade marketing). `from:qantas` returned a long block, of which the visible 60 lines were entirely work-mailbox results dated 2017–2023. Conclusion, written verbatim: "No Qantas booking or e-ticket for 2026 exists in any of the five mailboxes — every Qantas confirmation is 2017–2023."

3. Acted on that absence for the next three turns: built a forensic puzzle around the on-file boarding pass's e-ticket prefix (`781` = China Eastern stock vs Qantas `081`), concluded the SIN→BNE invoice "needs the Qantas portal / serialised browsing," then "is in-app only, no PDF." Every downstream claim rested on the unverified absence, and each new claim was stated with more confidence than the last.

The nudge that broke it was the user quoting an email subject back: "you didn't see the email 'Prepare for your flight QF52 to Brisbane on 15 June 2026'?"

## The false assumption

The Qantas booking did not exist in any mailbox — because `from:qantas.com` returned only marketing and the visible top of `from:qantas` was all old — so the invoice was declared missing-from-mail and routed to a portal-login plan.

## The actual cause

The Qantas e-ticket (booking F784YM, subject "Confirmation and E-Ticket Flight Itinerary … Singapore Changi to Brisbane on 15Jun26") and two "Prepare for your flight QF52" reminders were in the personal mailbox the whole time. Two independent defects, each alone sufficient to fake the absence:

- **Wrong sender domain.** Qantas transactional mail comes from `@yourbooking.qantas.com.au`. `from:qantas.com` matches only the literal domain `qantas.com` and does not match the `.com.au` subdomain, so it could never have returned the booking — the wrong question, not an empty answer. For an Australian carrier the transactional domain is `qantas.com.au`; `qantas.com` reaches only the US/marketing stream.

- **`head` deciding an absence.** The search that *did* contain the booking — `from:qantas`, matching the display name "Qantas Customer Services" — returned 50 results in the personal mailbox. The output was grouped by account, and roughly fifty stale 2017–2023 hits in the work mailbox printed first, filling the `head -60` window before the personal mailbox's block was reached. `head -N`, with N picked for terminal readability, was allowed to ground a claim of non-existence. The result count (50 in the personal box, of which 0 had been seen) was knowable and never checked.

Two facts already on screen falsified the claim at the moment it was made. Earlier searches in the same session had shown that this same personal mailbox held every other booking for the trip (the Ryanair invoice, the BudgetAir and Flightnetwork receipts) — yet Qantas was assumed absent from it. And `from:qantas.com` returning *only* `upgradeoffers@qantas.com` should have raised "is `qantas.com` even the transactional domain?" rather than "there is no booking."

Once the assuming stopped, it took **one** search to find: `mailroom -A search 'QF52' …` surfaced both reminders and, in the same run, the F784YM e-ticket with its PDF attachment — the document that had been declared not to exist anywhere.

## Marker for a hook

The detectable tell is an **absolute absence claim** ("absent from all five mailboxes", "NO … in any of the five mailboxes") emitted directly after a tool call of shape `<search> | head -N`, with no intervening check of the total result count and no acknowledgement that the output was truncated or grouped by account. The negative existence claim and the truncating pipe in adjacent turns are the signature. A weaker secondary tell: a sender filter (`from:qantas.com`) that returns only one homogeneous class (marketing) being read as "the entity sent nothing" instead of "this filter is wrong."
