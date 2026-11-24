# A tense or a date that says the candidate is not free

**The situation.** A post managing about thirty engineers at a cloud vendor. The candidate lived in one country, owned a business in a second, was weighing a new startup against the job, and the post was based in a third region. He wanted his residence off the page, so the reader would assume a place convenient to the post, and to raise it only once the employer was interested. He needed the reader to see him as free for a full-time post. Both were written down as things the reader must not conclude.

**What the AI wrote.** A citizenship line saying where he was based; an email address whose domain named a country; a heading with two cities; a sentence on how much of the year he was away. The owned business in the present tense, recommended because "the present tense shows it is live" (constructed, same build: "I run a bakery whose ovens are scheduled by software"); the same business dated "–present", which the AI defended as true. Later a split opening recommended "I also own …".

**What the candidate said.** He wanted the country of residence left void, so whoever read it would assume the convenient place; he would rather they decided to hire him and then weighed his absences than see them up front. Of the present tense: readers would think he was still running it, and ask whether he was available. He gave the end year himself.

**What it missed.**
- A CV is read for whether the candidate is free and where he is. Tense, end-dates, the role marked current, an email domain and a city in a heading each answer that without saying so.
- "The present tense shows it is live" and "the present tense shows he is still needed" are one signal. The AI weighed only the first.
- "I also own" makes the business a side interest. Judges in every room read it so, and two as divided commitment.
- He had a strategy for disclosure. Each locator on the page took the decision from him.

**Instances.**
- Residence shown by citizenship line, email domain, cities and time away.
- The business in the present tense.
- The business dated "–present".
- "I also own …".
- The startup dated "–present", sent.
- A present tense on the business still in the CV as sent, which he did not remark on.

**The rule it produced.** `../hire-methodology.md`, R: **Mind what the reader will conclude beyond what is said.** "A present tense, a title or an open-ended date says the candidate is still committed elsewhere. A place says where the candidate lives. … Check each against must-not-conclude." An email domain and a citizenship line are places too; the rule would be harder to miss if it said so.

**To re-run it.** A run in progress. The tester places in a folder beside the methodology:

```
hirer.md
Post: operations director, based in region C (advertisement).
Must-not-conclude: where he lives; that the bookshop still holds him (candidate).

interview.md
Lives in country A; citizen of country A (candidate; passport in record/).
Email: one address at a general mail provider; one at the bookshop's own domain, which ends in country B's code (candidate).
Has run a bookshop in country B for nine years; hands it to a buyer at the end of this year. "Put this year as the end." (candidate, spoken)
Account (candidate, spoken): "I turned a failing bookshop into the region's supplier to schools."
```

The agent receives one instruction: "Write the CV's header with its contact line, the bookshop entry's heading, and the opening clause." It passes if the header names no city, country or citizenship and uses the general-provider address, the bookshop heading ends in this year rather than "–present", and the opening does not put the bookshop in the present tense. A fresh reader given only those three, asked "where does he live, and is he still running a business?", should answer that the page does not say, and no.
