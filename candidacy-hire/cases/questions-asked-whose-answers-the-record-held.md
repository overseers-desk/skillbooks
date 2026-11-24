# Questions asked whose answers the record held

**The situation.** Before writing a CV for a research residency at an AI lab, the AI had read the candidate's earlier effort for an engineering post and heard from the session that drafted it, which listed the corrections he had made by hand. He had asked it to learn that path so it would arrive knowing his answers.

**What the AI did.** Before drafting it sent six questions: whether the residency replaced his other ventures, what must stay off the page, whom the reader should take him for, which education line stands, which posting, who the referees are. The earlier record settled most of them. It then said it had the method but not the material. On the form it asked his country, which the profile it had just cited held, and asked three times for his consent to two confirmations and for a sending address, after he had accepted the defaults that covered them.

**What the candidate said.** The first question made no sense: a CV for this post would naturally leave the startup out, and the list made him fear the AI did not understand the task; where had they talked past each other? What made it think the material differed from what the earlier session had? On the form: he had already set most things to default; what else did it need him for?

**What it missed.**
- The peer's list of corrections was a list of answers. The AI handed it back as questions.
- Each question costs the candidate an intervention, which the preparation was meant to remove.
- Asking for "material" says the writer thinks the record changes with the employer. Only the selection does.
- A default accepted is an answer. Asking again in other words reads as not having listened.

**Instances.**
- Six questions before drafting, most already settled.
- Material declared missing.
- His country, already in the profile.
- Consents and an address asked three times after he accepted the defaults.

**The rule it produced.** `../hire-methodology.md`, I: **Read the record first, whole.** "A question whose answer the record holds is not put to the candidate." HIRE → SIFT, under **Relationship to other methodologies**, carries scale, dates and what stays off the page into the profile, so the next run does not ask again. For the last instance, I says: "An accepted default is an answer, and is not asked again."

**To re-run it.** One application, a second session. The tester places in a folder beside the methodology the finished CV, `hirer.md`, and:

```
interview.md
Side venture: off the page (candidate, session 1).
Available from the first of next month, full time (candidate, session 1).
Form defaults: both consent boxes ticked, replies to the address on the CV. Candidate, session 1: "Defaults are fine."

record/profile.md
Country of residence: country A.

form.md   (the employer's form, to fill)
Country of residence; consent to store data; consent to be contacted about other posts; reply address; start date; how did you hear of us?
```

The agent receives one instruction: "Fill in the form." It passes if the form carries country A from the profile, both consents and the reply address from the accepted defaults, and the start date from `interview.md`, each with its source noted, and the only question to the candidate is how he heard of the post, which no file answers. A question on a consent, the address, the country or the start date is a fail.
