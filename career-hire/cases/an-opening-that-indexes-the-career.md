# An opening that indexes the career

**The situation.** The opening of a CV for a research post. Its reader has many applicants with research careers who state a direction and results. This candidate held no research post, but had run a business on a system they built and catalogued how it failed.

**What the AI wrote.** Four facts in career order, each, in its own words, "sanded until no reader could doubt it": the system the candidate built, one finding about it, their span of command and a protocol at another venture, an earlier post. A restructure later left a second opening of the same kind, leading with their titles. In the motive answer and the CV, the failure best supported by the record stood in for the whole subject (constructed, same build: "the system rebooked a supplier because the supplier's email sounded urgent"), and the CV gave all the failures a single cause.

**What the candidate said.** That a research role wants someone with a direction or findings, and asked whether the AI had weighed that. Then: that the text read as entirely dry, and what does this reader expect from someone with no research post? Of the example: the subject had collapsed into it; examples may be needed, but the text had carried one as the whole of what the candidate works on, and they expected it to recur in the next draft unless named.

**What it missed.**
- A settled finding and a list of posts say who the candidate was. They leave a mentor nothing to work on with them, and nothing of what the candidate brings that the employer's researchers lack.
- It placed the candidate beside nothing in the reader's world. Their own spoken opening did, by setting where the candidate's evidence came from against where most researchers' comes from.
- The example easiest to support is often one the reader has met in the news. Readers asked what the candidate works on named the example's kind, not the candidate's subject.
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

brief.md
Readers have plenty of: researchers with lab results (assumption; register, medium confidence).
Readers lack: failure evidence from robots in daily use (candidate).
Account (candidate, spoken): "People who study robot failure mostly see it in a lab. I see it on a loading dock every day, and I've logged three hundred failures in a year, the odd ones, not the famous ones. I want to know which of them no lab would ever produce."
Ran a fleet of twelve delivery robots for a year; before that, engineer at a parts maker (candidate).
Logged failure: a robot followed a person into a lift (record/log.md).
register.md   (that row only)

```

The agent receives one instruction: "Set out the approaches, choose one, and write the CV's opening on it." It passes if `approaches/` holds three or more that differ in kind, one of them the candidate's account tidied; `register.md` has a row for the choice, with its confidence and basis; and a fresh reader given only `advertisement.md` and the opening, asked "in one sentence, what does this applicant work on, and what would you ask them to work on with you?", names the general subject (failures of robots in daily use that a lab does not produce) and a question. A reader who names the lift, or the posts in career order, is a fail.
