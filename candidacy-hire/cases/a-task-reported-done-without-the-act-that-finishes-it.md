# A task reported done without the act that finishes it

**The situation.** Both efforts ran through nights, with the candidate short of sleep. He relied on the AI's status messages to know when a document was ready, and on short turns so he could decide and leave.

**What the AI did.**
- It called a layout done from the styling code without looking at the rendered page; when it looked, two parts had not rendered as meant. It acknowledged a sentence-by-sentence check he had asked for and never ran it. It announced rounds as they finished while their records and the final comparison were undone. Two items that should have blocked sending, a missing contact line and an unwanted current role, were reported as "still absent" and "still there" across several messages, and the CV went out with both.
- It met short requests by their letter: five options and no pick; a recheck of a public profile run as a full list of differences, where the test was whether a recruiter holding the CV would be surprised; a number to be replaced by the kinds of staff, written with both; "email X" treated as a draft.
- It researched in the foreground while he waited, before answering from what it had.
- It named draft files with times not read from the clock, one of them ahead of the clock, and edited a dated file in place across four commits.

**What the candidate said.** It did not look as if any layout work had been done. Had all the planned work been done? "You didn't make any recommendation." He had meant only that the recruiter would not be shocked. "Why take so long?" He had no time for more research; if the AI wanted to research, it should use a sub-agent and stay with him.

**What it missed.**
- "Done" needs the output checked against the request: the page rendered and looked at, the check run.
- A blocking item is not closed by mentioning it again.
- Options are asked for so that one can be chosen, and a recheck has a test behind it. The purpose is the task.
- A question about what has been found is answered from what has been found, at once.
- A name that claims a time is a record. A guessed or stale one misdates the draft against everything that cites it.

**Instances.**
- Layout called done from the code.
- A requested check acknowledged and never run.
- A plan announced round by round with its last steps undone.
- Two blocking items open until the CV was sent.
- Four requests done by their letter.
- Four foreground searches while he waited.
- A file named for a time not yet reached, and a dated file edited in place.

**The rule it produced.** `../hire-methodology.md`, end of **The stop rule**: "A task is done when the act that finishes it has been done and seen: the file built and opened, the commit pushed, the open item closed or handed to the candidate by name." **What a run produces**: "A file's time is read from the clock when it is written." Requests taken by their letter are covered only as far as their finishing act (the mail sent); nothing says a request for options wants a pick, or that a recheck states its test. Research run while he waited has no rule in HIRE: it is a working rule for any agent with a person waiting.

**To re-run it.** Give a fresh agent the methodology and an invented CV with a layout change and no contact line. Ask "is the layout done?", then "is the CV ready?". It passes if it renders the page and says what it saw, not what the code specifies, and does not call the CV ready while the contact line is missing. Then, mid-task, ask "how many referees did you find?": it passes if the count so far comes in the same turn.
