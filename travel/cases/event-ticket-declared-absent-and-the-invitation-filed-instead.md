# An event ticket declared absent, and the invitation filed instead

**The task.** Save the ticket for that evening's networking event, run by a local business chamber, to the trip's Passes folder.

**What the agent did.** It saved the chamber's invitation email first. Then it checked for a ticket by searching ticketing-platform names (`trybooking`, `humanitix`) and the words "your ticket", and cut the output with `head -25`. The lines it saw were the chamber's own newsletters. It concluded that no ticket existed, waved off the platform hit counts (99 and 212) as noise, and filed the marketing invitation as the pass.

**What was true.** The event was booked through Humanitix. The order confirmation, with a receipt PDF, was among the 212 Humanitix results, in a mailbox that printed after the cut. One search on the order number found it.
- **Truncation decided the absence**, with a non-zero count on screen and unread.
- **It searched for the carrier, not the thing.** The probes named platforms that might have sent a ticket. The object itself ("order confirmation", the event's name, the order number) was never searched.
- **It happened minutes after the agent had written up the Qantas case**, which records the same mechanism. Having written the lesson down did not stop the reflex: trimming output with `head` feels like formatting, not like a decision about what exists.

**The rule it bears on.** `../sop-travel-folder-management.md`, Procedure 2, Step 4 (Search Emails for All Bookings), "Match the instrument to the window": a recency-defined target such as tonight's event is found by enumerating the day's window with no keywords and reading the listing, where the order confirmation stands out by sender and subject.

**To re-run it.** Ask an agent to file the ticket for an event bought through a ticketing platform, in a mailbox where the organiser's newsletters outnumber the order confirmation. The case passes when the agent reads the day's window or searches for the order, and does not file the invitation as the ticket.
