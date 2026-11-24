# Questions asked whose answers the record held

**The situation.** Before writing a CV for a research post, the AI had read the candidate's earlier effort for an engineering post and heard from the session that drafted it, which listed the corrections the candidate had made by hand. They had asked it to learn that path so it would arrive knowing their answers.

**What the AI did.** Before drafting it sent six questions: whether the research post replaced the candidate's other ventures, what must stay off the page, whom the reader should take the candidate for, which education line stands, which posting, who the referees are. The earlier record settled most of them. It then said it had the method but not the material. On the form it asked the candidate's country, which the profile it had just cited held, and asked three times for their consent to two confirmations and for a sending address, after they had accepted the defaults that covered them.

**What the candidate said.** The first question made no sense: a CV for this post would naturally leave the startup out, and the list made the candidate fear the AI did not understand the task; where had they talked past each other? What made it think the material differed from what the earlier session had? On the form: they had already set most things to default; what else did it need them for?

**What it missed.**
- The peer's list of corrections was a list of answers. The AI handed it back as questions.
- Each question costs the candidate an intervention, which the preparation was meant to remove.
- Asking for "material" says the writer thinks the record changes with the employer. Only the selection does.
- A default accepted is an answer. Asking again in other words reads as not having listened.

**Instances.**
- Six questions before drafting, most already settled.
- Material declared missing.
- The candidate's country, already in the profile.
- Consents and an address asked three times after the candidate accepted the defaults.

**The rule it produced.** `../hire-methodology.md`, I: **Read the record first, whole.** "A question whose answer the record holds is not put to the candidate." **An application does not go back to the candidate**: a gap no default covers is decided by the writer and added to the record's defaults, and "the register carries it as an assumption at low confidence. The work does not stop for it." **What a run produces** says of the standing record, "Every application reads it", so a later application reads what an earlier one settled. For the last instance, I says: "A default the candidate has accepted in the register is an answer, and is not put again."

**To re-run it.** One application, at its form. The tester places in a folder beside the methodology `hirer.md` and:

```
cv.md   (the finished CV; its contact line)
Contact: address A.

standing-record.md
Side venture: off the page (candidate).
Available from the first of next month, full time (candidate).
Residence: may be given at the grain of a country (candidate).
Contact: address A. Told that an address can show where the candidate lives: "Address A is fine, let it show the country." (candidate)

register.md
Earlier application | Form defaults: both consent boxes ticked, replies to the address on the CV | high | the forms' own defaults | the form | agreed: "Defaults are fine."

record/profile.md
Country of residence: country A.

form.md   (the employer's form, to fill)
Country of residence; consent to store data; consent to be contacted about other posts; reply address; start date; how did you hear of us?
```

The agent receives one instruction: "Fill in the form." Look in the filled form, `register.md` and the agent's message. It passes if the form carries country A from the profile, both consents from the agreed row, address A from the CV, and the start date from the standing record, each with its source noted; how the candidate heard of the post, which no file answers, is filled by a stated default with a new row at low confidence giving its basis; and no question goes to the candidate. Any question to the candidate, that one included, is a fail.
