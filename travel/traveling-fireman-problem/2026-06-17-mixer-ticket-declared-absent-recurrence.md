---
date: 2026-06-17
pwd: /home/weiwu/code/aesop/travel
session_id: be4b5fa2-3d12-4e22-b40e-e7863dea698d
transcript: ~/.claude/projects/-home-weiwu-code-aesop-travel/be4b5fa2-3d12-4e22-b40e-e7863dea698d.jsonl
---

# Mixer ticket declared absent — the same head-truncation fireman, one turn after filing the story about it

This is the second occurrence in a single session of the failure recorded in `2026-06-17-qantas-booking-declared-absent.md`. It happened minutes after that story was written and committed, which is the part worth keeping.

## Pre-fireman sequence

Asked to save today's Tamborine Mountain Chamber event ("After Hours Networking Mixer") to the Passes folder. After saving the invitation email, I checked whether a real ticket existed:

1. `courier -A search 'trybooking' search 'humanitix' search 'your ticket' search 'distillery'`, piped through `python3 courier_count.py | grep -iE "…|order|ticket|…" | head -25`. The visible rows were all the Chamber's own invitation/newsletter emails. Conclusion, written verbatim: "No separate ticket confirmation exists for today's mixer — the only artifacts are the Chamber's invitation emails (the trybooking/humanitix counts are unrelated noise)."

2. Saved the marketing invitation as the Passes "pass," and dismissed the platform counts (99 trybooking, 212 humanitix) as "unrelated noise."

The user broke it by quoting the order-confirmation subject and order id (DNLMSPFW).

## The false assumption

No ticket or order confirmation for the mixer existed in mail, so the marketing invitation was the only artifact to save.

## The actual cause

The mixer was booked through Humanitix. The order confirmation (`receipt_DNLMSPFW.pdf`, A$6.31, in the personal mailbox) was inside that 212-result `humanitix` set, but the personal mailbox sorts last, so it fell below the `head -25` cut. The search was also mis-scoped: I queried ticketing-platform *names* and "your ticket"/"distillery", never the order itself ("order confirmation", "mixer", or the order id). One search on `DNLMSPFW` found it once I stopped assuming.

## Why it recurred (the knowledge to keep)

The first story, documenting this exact marker (`<search> | head -N` → absence claim), had just been written and committed in the same session. Reading and writing the postmortem did not prevent the immediate repeat. Reasons:

- `head`/`grep` truncation is an automatic habit for taming verbose tool output. It fires without being connected to the lesson, because trimming output feels like a formatting choice, not a correctness choice.
- The absence conclusion feels complete. Nothing in the loop distinguishes "I saw all results" from "I saw the first N."
- The result count was on offer (212) and ignored — I labelled it "noise" instead of reading it.

The takeaway is structural, not motivational. "Remember not to truncate" demonstrably failed within minutes of being written. The reliable fixes are mechanical:

- Never assert an absence from a search whose output passed through `head` or a narrowing `grep`.
- When a search is meant to prove non-existence, print the result **count** and assert "absent" only against count = 0; if the count is non-zero, read every row (refine the query until the set is small) before concluding.
- Search for the **object** (order id, "order confirmation", the event name), not the platform that might carry it.

The recurrence is the strongest evidence that the marker-based hook these stories are training data for is necessary: self-knowledge did not arrest the behaviour, an external interrupt did — both times, the user's.
