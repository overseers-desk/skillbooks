# A true detail kept because it was known

**The situation.** A CV for a post managing about thirty engineers at a cloud vendor. Every line on two pages leaves an impression on a reader deciding whether the candidate can run an organisation. Many lines were true, and were kept because the writer had them.

**What the AI wrote.** Details of these kinds (constructed, same build): "Built in [some] months by a very small team"; a headcount of staff at the business he ran; a link to his public code repository; "a few hundred instructions a day" from the system; the earlier name of a company, in brackets.

**What the candidate said.** That leaving out the number of employees might work better: with it, the business turns out small, which nothing else had said. That the AI "feels everything it knows must be said". That the build time read as boasting of something plain and, unexplained, as a very slow project. That the repository had few stars and might give off negative information. That hundreds of instructions a day may sound good, but AI is also very good at producing rubbish.

**What it missed.**
- The reader acts on what a detail implies, not on whether it is true: a very small team says he leads few; a headcount, a small business; months, slow; few stars, unused; hundreds a day, noise.
- The test of a line is what it does for the decision to interview. No line was put to it before it went in.
- The writer had its own reason for each (few people building much; a timeline that makes the claim believable). The reader sees only the inference.
- The case is not "cut every number". Judges kept the headcount as checkable and the earlier name as linking two facts. The fault is that nobody asked what each line implied, so the candidate had to ask each time.

**Instances.**
- "A very small team", in two versions.
- The staff headcount, settled with the kinds of staff beside it.
- The repository link, removed.
- The build time, gone in a rewrite.
- Hundreds of instructions a day, left out.
- The earlier company name, kept on the judges' reading.

**The rule it produced.** `../hire-methodology.md`, R: **For each fact, name the question of this reader that it answers**: "A fact that answers no question of this reader stays out, however true and however hard-won." The rule is weak here. A headcount does answer a question (how big?); the fault lies in the inference beyond the fact. **Mind what the reader will conclude beyond what is said** reaches that kind of inference, but only for availability and residence.

**To re-run it.** Give a fresh agent the methodology and an invented CV for a post leading forty engineers that contains "built by two of us over three years", "the shop has six staff", a link to a repository with four stars, and "the bot sends about nine hundred messages a day". Ask it to go line by line. It passes if it writes down what each detail implies beyond its fact, and recasts, tests or cuts each one whose inference counts against the candidate. A line kept because it is true is a fail.
