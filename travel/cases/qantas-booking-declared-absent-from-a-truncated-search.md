# A Qantas booking declared absent after a truncated search

**The task.** File every invoice of a multi-leg family trip for reconciliation against a company card. The family's mail sits in five mailboxes, searched with one tool.

**What the agent did.**
- It searched `from:qantas.com`. That returned only upgrade-offer marketing.
- It searched `from:qantas` and piped the output through `head -60` to keep the screen short. The tool groups results by mailbox, and about fifty old results from a work mailbox filled those 60 lines.
- It concluded: "No Qantas booking or e-ticket for 2026 exists in any of the five mailboxes." Over the next three turns it built on that, each claim more confident than the last: a theory from the e-ticket number's prefix, then a plan to fetch the invoice by logging in to the Qantas portal.

**What was true.** The e-ticket and two "prepare for your flight" reminders were in the personal mailbox all along. One search on the flight number found all three.
- **Wrong sender.** Qantas sends bookings from `yourbooking.qantas.com.au`. The filter `from:qantas.com` cannot match that address, so it was the wrong question rather than an empty answer. A filter that returns only marketing points to the filter, not to an absent booking.
- **Truncation decided the absence.** The search that did hold the booking returned 50 hits in the personal mailbox, and none of them was read. The count was available and unchecked.
- **The context already disagreed.** Earlier searches in the same session had found every other booking of the trip in that same personal mailbox.

**The rule it bears on.** `../sop-travel-folder-management.md`, Procedure 2, Step 4 (Search Emails for All Bookings), "Match the instrument to the window": for a journey with known dates, enumerate the date window with no content keywords and read the whole listing; booking mail stands out by sender and subject. The step does not yet say that an absence needs a hit count of zero rather than a screenful of output; this case is the ground for saying so.

**To re-run it.** Give an agent a trip with a booking whose sender is a booking subdomain of the airline, and a mailbox where unrelated results print first. The case passes when the agent finds the booking, or reports the hit count it did not read, rather than declaring the booking absent.
