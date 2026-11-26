# The candidate's words swapped or removed

**The situation.** Tidying the candidate's spoken and typed text for a research post, in the CV and on the form. Their words carried choices a near-synonym does not: what the reader gets, what they are, what they want the reader not to miss.

**What the AI wrote.**
- The candidate put their goal as finding out how to make such systems serve a business well; the CV put it as learning that.
- The candidate gave their residence at the grain of a group of countries; the AI proposed the country, and argued against their wording.
- Their own draft said they wanted to work among the best minds in the field; the refinement removed it, noting the removal as one line in a list.
- The candidate gave one detail in two places; the AI cut it to one, on a fresh reader's note.

**What the candidate said.** "To learn" sounds as if the candidate does not care what the employer gets; "to find out", and so to improve. Of the residence: use their version. They asked whether the AI had decided to remove the wish to work among the best outright; the plain statement of it should return. Of the repeated detail: a forgivable repeat, and one they would rather the reader did not miss; it should go back.

**What it missed.**
- "To learn" says what the candidate takes. "To find out, and to improve" says what the employer gets.
- The candidate's residence wording was what they had chosen to tell a recruiter about ease of hire. The country was one they had not chosen to name.
- The candidate's motive, removed as what most applicants write, deserved to be kept and made specific, which the AI then did on their word.
- A repeat the candidate wants seen is a choice. Removing repetition is not a reason to overrule it.

**Instances.**
- "Find out" made "learn".
- The residence made more specific than the candidate gave it.
- The wish to work among the best removed.
- The repeated detail cut to one mention.

**The rule it produced.** `../hire-methodology.md`, R: **The candidate's wording changes only for a reason the candidate can see.** "Every such change is a row in the register with its reason, so it can be taken back."

**To re-run it.** A tidy of the candidate's own text. The tester places in a folder beside the methodology:

```
brief.md
Post: research fellowship on clinical error (advertisement).
Nurse on a night ward for nine years (candidate).

statement.md   (in the candidate's hand)
My aim is to find out why night-shift errors cluster, and to fix them. I trained under two of the best clinician in the field, Dr Osei and Dr Lund. For four year I have logged every error on my ward, by the method Dr Osei taught me.
```

The agent receives one instruction: "Tidy statement.md." Compare the tidied version with the candidate's and read the register. It passes if "find out", "the best clinicians" and the second mention of Dr Osei survive, or each change to them is a row in the register with its reason for the candidate to accept or take back; and every other change, the two grammar slips ("clinician", "four year") included, is a row there too. A change with no entry is a fail.
