# An opening that indexes the career

**The situation.** The opening of a CV for a research residency at an AI lab. Its reader has many applicants with research careers who state a direction and results. This candidate held no research post, but had run a business on software agents for a year and catalogued how they failed.

**What the AI wrote.** Four facts in career order, each, in its own words, "sanded until no reader could doubt it": the system he built, one finding about it, his span of command and a protocol at a startup he co-founded, an earlier post at a bank. A restructure later left a second opening of the same kind, leading with his titles. In the motive answer and the CV, the failure best supported by the record stood in for the whole subject (constructed, same build: "an agent rebooked a supplier because the supplier's email sounded urgent"), and the CV gave all the failures a single cause.

**What the candidate said.** That a research role wants a technical leader with a crusade, a direction or findings, and asked whether that had been in the AI's matrix. Then: "It reads bone dry", and what does this reader expect from someone with no research post? Of the example: it was "scope collapse"; examples may be needed, but the text had carried one as the whole of what he works on, and he expected it to recur in the next draft unless named.

**What it missed.**
- A settled finding and a list of posts say who he was. They leave a mentor nothing to work on with him, and nothing of what he brings that the lab's researchers lack.
- It placed him beside nothing in the reader's world. His own spoken opening did, by setting where his evidence came from against where most researchers' comes from.
- The example easiest to support is often one the reader has met in the news. Readers asked what he works on named the example's kind, not his subject.
- No instrument heard it. No sentence reader scored it dry, and judges preferred it in every room to the earlier CV.

**Instances.**
- The first opening: posts and a finding, in career order.
- The titles-first opening left after a restructure.
- The motive answer narrowed to one kind of failure.
- The CV's failures given a single cause, in two versions.

**The rule it produced.** `../hire-methodology.md`, R, **Choose the approach before writing sentences**: three approaches that differ in kind, one of them the candidate's own account. H, **What these readers have plenty of, and what they lack**, sets the argument. For the example, R's **Write at the level of the post and the person**: a category is shown by naming a few of its members. E 1 warns that sentence readers cannot tell whether the document speaks to anyone; E 2, **The common-sense reading**, has its reader say "in one sentence what the applicant works on and what it would ask them about; a reader who cannot has been given an index of a career."

**To re-run it.** A run in progress, at the choice of approach. The tester places in a folder beside the methodology:

```
advertisement.md
Research fellowship in robot reliability. Fellows join a lab group for two years.

hirer.md
Readers have plenty of: researchers with lab results (inference; question for the candidate).
Readers lack: failure evidence from robots in daily use (candidate).

interview.md
Account (candidate, spoken): "People who study robot failure mostly see it in a lab. I see it on a loading dock every day, and I've logged three hundred failures in a year, the odd ones, not the famous ones. I want to know which of them no lab would ever produce."
Ran a fleet of twelve delivery robots for a year; before that, engineer at a parts maker (candidate).
Logged failure: a robot followed a person into a lift (record/log.md).
```

The agent receives one instruction: "Set out the approaches, and write the CV's opening on the one you recommend; he will confirm." It passes if `approaches/` holds three or more that differ in kind, one of them his account tidied, and a fresh reader given only `advertisement.md` and the opening, asked "in one sentence, what does this applicant work on, and what would you ask them to work on with you?", names the general subject (failures of robots in daily use that a lab does not produce) and a question. A reader who names the lift, or the posts in career order, is a fail.
