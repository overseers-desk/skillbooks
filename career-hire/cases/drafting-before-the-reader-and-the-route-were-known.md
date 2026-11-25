# Drafting before the reader and the route were known

**The situation.** A management post. The candidate held an advertisement marked for reference only, which described a first-line manager of a small squad, and a contact's word that the post sat above it. Who would read the CV first, how it would reach them, in what language they worked, and what the page must not show were all open.

**What the AI did.** It wrote a strategy when asked, then drafted from the sources it could reach. It pitched the first page at a headhunter, whose existence was the candidate's early guess, and briefed its judges as headhunters. It wrote to the advertisement: the summary closed on hands-on work, of this build (constructed): "I still do the analysis myself, mostly in spreadsheets", and a skills list named languages and hosting. The facts that decided the document came one at a time after drafting began, several after the CV had gone: the reporting line; the route (the employer's own recruiter, through a friend, with no headhunter); the reader's first language, which was not the CV's; and a contact line, which the sent version lacked.

**What the candidate said.** That they had asked for a strategy first precisely to stop the AI acting as a document clerk, and it had happened anyway. Refusing a draft message to the future manager: the AI was in too much of a hurry. And that the advertisement might be only a signal, since the post sat above it.

**What it missed.**
- Each fact about the reader changes the document: what it leads with, what may appear, which language comes first, which judge brief is right. Learnt after drafting, each forced a rewrite, and one version went out with the gaps.
- An advertisement for the level below describes the team under the post, not what its own reader hires for. Hands-on skill offered as a qualification placed the candidate in the team, not over it. The AI had said so before drafting, and drafted to the squad anyway.
- A strategy binds nothing unless the draft is checked against it.

**Instances.**
- The route assumed through a headhunter, then found to run through the employer's recruiter and a friend.
- The level, above the advertisement's, confirmed after sending.
- The reader's language, learnt after sending.
- No contact line on the version sent.
- Entries in the junior form (headcount, duties, a percentage) until the candidate proposed the senior form, twice.

**The rule it produced.** `../hire-methodology.md`, H — Hirer: "A document is not begun until `brief.md` exists for it", with **The post behind the advertisement** and **The route**, which asks "in what language each reads". What H cannot source "is an assumption, and goes into the register with a confidence score: what this hirer wants, who reads first, what level the post is." The CV no longer waits for the reader to be confirmed, but is written to one stated and scored before the first sentence. The contact details are not among the things H settles; E 4, **Sources**, checks that the document carries them, which is after drafting.

**To re-run it.** This one starts from nothing, since the fault is a draft begun too early. Give a fresh agent the methodology and:

```
advertisement.md
Team lead, data platform. Leads a team of five engineers, hands-on in the pipeline code. Reports to the engineering manager.

note.md   (from the candidate)
A friend forwarded this. The post I'm going for sits two levels above the team lead it describes. Write my CV.

standing-record.md
Account (candidate, spoken, to a reader hiring a leader): "I took a data team from four people to forty, and the platform with it."
Head of data at a payments firm, six years (candidate).
Fears a reader will conclude: that they are still a hands-on engineer (candidate).

register.md   (the header row only)
```

Look in the folder. It passes if `brief.md` predates the CV; `brief.md` sets out who reads first, the route, the level (two above the advertisement's team lead, sourced to the note), the reporting line, each reader's language, and must-not-conclude from the standing record, each line with its source; each line the folder does not source is a row in `register.md` with a confidence, its basis and what in the CV depends on it; and the CV offers no hands-on pipeline work as a qualification. A CV begun before `brief.md`, an inferred line with no row, a CV written to the advertisement's team lead, or no CV while the agent waits on answers, is a fail.
