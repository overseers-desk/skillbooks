# A CV built by editing one written for another post

**The situation.** Days after a CV for a management post, the candidate applied to a research post. They asked the AI to learn how the first CV's material had been collected and to build the new one for the new reader. The first CV answered a reader hiring a manager: span of control, how a deployment was governed, how data was integrated, how the build was run. The research post's reader wants to know what the candidate's work lets them observe.

**What the AI did.** It copied the first CV's file and edited its lines. Its plan said the material was the same, "selected again for this reader", and its working orders made the first CV win wherever sources conflicted. Lines of the earlier reader's kinds came across, of these builds (constructed): "I designed the system and built it with [a tool], to a standard I set"; "Staff act alone only on small orders; above that a manager signs"; "Led a team of sixty in four groups"; a count of client companies served. One of them survived more than twenty versions, until minutes before the deadline.

**What the candidate said.** They quoted the build line: it came from the engineering CV, and for a research role the bridge should be different. Had they asked for the method of collecting material, or for the old CV modified? And of the carried lines: they were all framing problems, and none should simply be deleted.

**What it missed.**
- The material is the record. The earlier CV is one selection from it, made for another reader, and each of its sentences carries that reader's question unseen.
- A line kept by default is never asked what it is for, so no check raised it.
- Every fact was good. Recast, a span of management becomes the scale of a proof (constructed: "brought the system from first specification to a live service, with a team of sixty"), and an integration feat becomes a control in an experiment.
- Recasting can overshoot: one rule recast as an abstraction was called by a fresh reader too general to hold.

**Instances.**
- The CV begun as an edit of the earlier file, with a rule that the earlier CV wins conflicts.
- Seven lines of the earlier reader's kinds (build, governance, integration, where effort went, span, delivery, a programme of experiments) kept to the final morning.
- Four first-draft lines written for the earlier reader, cut later.
- An opening that, after a restructure, read as the engineering CV again.

**The rule it produced.** `../hire-methodology.md`, R: **Start from an empty page.** "An earlier document for another post lends no sentences". For the recasting, **For each fact, name the question of this reader that it answers**: "a team's size is span of control to one and the scale of a proof to another", and "Before leaving a fact out, look for the question it could answer for this reader and recast it to that; most facts written for another reader have one." `selection.md` records each decision.

**To re-run it.** A run in progress, where R begins. The tester places in a folder beside the methodology:

```
brief.md
Post: two-year research fellowship on how field robots fail (advertisement).
Reader line: a panel of roboticists who run trials in the lab (advertisement).
Readers lack: failure evidence from machines in daily use (candidate).
Taken-for: someone whose work yields evidence a lab cannot get (candidate).
Must-not-conclude: none given (candidate).
Account (candidate, spoken): "My robots break in ways no lab sees, and I have logged every break for three years."
Ran a depot of forty pickers and twelve robots for five years (old-cv.md; candidate confirmed).

approaches/chosen.md
Open on the fault log as evidence the lab lacks (chosen by the candidate).

old-cv.md   (written for an operations-manager post)
- Led a team of forty pickers in three shifts.
- Pickers override a robot only on orders under ten items; above that a supervisor signs.
- Integrated the robots with the stock system, cutting mis-picks by a third.
- Ran a weekly review of every robot fault with the vendor.
```

The agent receives one instruction: "Write the CV for the fellowship." Look in `selection.md` and the new CV. It passes if `selection.md` lists each of the four lines of `old-cv.md` with a question the fellowship's reader has and a decision, and three are recast to a question of that reader, not left out: the team to the scale of the trial behind the log (forty people working beside twelve robots), the override rule to a condition under which the faults arose (when a robot acts without a person), and the integration to a measure or a control (mis-picks as the count the log is checked against). The fault review may be kept or recast as how the log was kept. A fact left out names in `selection.md` the questions tried for it. No sentence of `old-cv.md` appears word for word in the new CV. A CV made from a copy of `old-cv.md`, any of the first three facts dropped, or no `selection.md` is a fail.
