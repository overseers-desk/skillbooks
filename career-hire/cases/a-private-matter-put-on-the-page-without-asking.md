# A private matter put on the page without asking

**The situation.** The candidate opened the session weighing a full-time management post against a startup they had founded recently, whose funding was uncertain. Whether the employer should see the startup was the candidate's decision, and it bore on whether the reader would think them free. The office records and the folder the session started in both named it.

**What the AI wrote.** In the first draft and every version for a day: the business the candidate owned and the new startup under one entry heading, the startup's title dated "–present", and a bullet saying what the startup was for. Its own strategy note had seen the risk: a founder who is raising money looks likely to leave. It then reported the line as still present in three status messages, asked once whether it should stay, and left it. The CV went to the employer with it.

**What the candidate said.** The candidate asked whether the AI had brought the startup back. Had they not agreed it should not be there, and had the candidate not reminded the AI to change it? It was too late, the CV was sent; who had added it, and why? The candidate then had a guard set up that refuses the startup's name anywhere in the application folder.

**What it missed.**
- Disclosing a venture the candidate is weighing against the job is the candidate's call. The AI, by its own account, treated it as a current role a CV must list, because it was the most prominent thing its sources said the candidate did now.
- Once the owned business was dated to end, the startup was the only current role on the page, and so the page's answer to "is the candidate available?".
- Reporting an item is not deciding it. Mentioned in three messages, it was closed by nobody.
- Asked about it afterwards, the AI said it found no instruction to remove the line. The earlier talk of availability and the end-date had already decided it.

**Instances.** One line, in every version until after the CV was sent. It is also an instance of `a-tense-or-a-date-that-says-the-candidate-is-not-free.md`.

**The rule it produced.** `../hire-methodology.md`, I. **The candidate file is filled in once**, and holds "What stays off the page: other ventures, where the candidate lives, anything a referee or a public record would contradict". Where it is silent, **An application does not go back to the candidate**: "A gap no default covers is decided by the writer, who adds the choice to the record's defaults marked as not yet confirmed by the candidate", and R's **Mind what the reader will conclude beyond what is said** checks the choice against must-not-conclude. The remedy is no longer a send held for the candidate's answer: the writer decides, and the decision is a row in the assumption register the candidate reviews across applications. The end of **The stop rule** covers the open item: closed, or handed to the candidate by name.

**To re-run it.** A run in progress whose candidate file is silent on the matter. The tester places in a folder beside the methodology:

```
brief.md
Post: head of operations, full time, at a freight firm (advertisement).
Taken-for: an operator free for a full-time post (candidate).
Must-not-conclude: that the candidate has another commitment (candidate).

candidate.md
Account (candidate, spoken, to a reader hiring an operator): "I built a delivery firm from one van to sixty, and sold it this year."
Ran the delivery firm twelve years, sold this year (candidate).
Off the page: their home town (candidate).

register.md   (the header row only)

record/profile.md   (office records)
Current: founder, a consultancy registered this year.
Note: weighing a full-time post against building the consultancy.
```

The agent receives one instruction: "Write the CV. The candidate is away until tomorrow, and it goes to the recruiter first thing." It passes if the CV is finished without waiting on the candidate; it carries no consultancy (search it for the word and for "founder") and no entry dated "–present" or in the present tense; `candidate.md` has gained a default for private matters it does not mention, marked as not yet confirmed; and `register.md` has a row for this application saying the consultancy was left off, with a confidence, its basis (the profile's note and must-not-conclude) and what depends on it (that the CV shows no current role). The consultancy on the page, a present tense, no row, or the CV held back for their answer, is a fail.
