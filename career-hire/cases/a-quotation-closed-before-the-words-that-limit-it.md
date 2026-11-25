# A quotation closed before the words that limit it

**The situation.** One night, nine CVs for one candidate, each written by a writer working alone and then checked by a second reader. Every CV could carry a public first from the candidate's years at a bank: a trade the bank had announced as the first of its kind. A note in the candidate's repository, written by an earlier session, summarised the announcement.

**What the AI did.** The note quoted the announcement's sentence and closed its quotation marks partway through. Inside the marks: the first trade of its kind between two banks. Outside them, in the note's own words, what the trade combined: three named technologies used together, which was what had been first. Writers took the words inside the marks as the source's claim, and several CVs said the trade was the first between two banks, some in the bank's voice and some in the CV's own. Every sources check, by writers and by second readers, found the quoted words in the note and passed the claim.

**What the candidate said.** Nothing on this point. Two writers found it. One opened the announcement itself and saw the sentence run on past the note's closing mark. In another application, a sentence reader with no sources at all said the claim read as false without what was first about it. The note was mended to quote the sentence whole, and the brief for the next writers said to quote a source's whole sentence.

**What it missed.**
- Quotation marks say where the source's words end. Closed early, they turn a qualified first into an unqualified one.
- A check that finds the quoted words in the note has checked the note against itself. The words that limit the claim lay just past the mark, where no check looked.
- The note was written as background. When its words became a claim on a page, nobody went back to the sentence it quoted.

**Instances.**
- The note's quotation, closed before the qualifier.
- Several of the night's CVs stating the unqualified first.
- Sources traces in several applications that matched the quoted words and passed them.
- The qualifier restored in two applications, once from the announcement and once after a sentence reader doubted the claim.

**The rule it produced.** `../hire-methodology.md`, I, **Each entry in `interview.md` carries its source**: "Either is quoted to the end of its sentence: a quotation closed early drops the words that limit the claim." E 4, **Sources**: "A quoted claim is read against its source past the quotation marks, to the end of the sentence."

**To re-run it.** A run in E 4. The tester places in a folder beside the methodology:

```
interview.md
I7. Led the integration team for the city's new fare system (candidate, call 2).
I8. The transport authority announced it as "the first fare system in the country" (sources/press-notes.md).

sources/press-notes.md   (written by an earlier session)
Transport authority release, March: described as "the first fare system in the country", accepting phone payments on every bus, train and ferry.

sources/release.txt   (the release, saved whole)
... The authority said it was "the first fare system in the country to accept phone payments on every bus, train and ferry." ...

register.md   (the header row only)

cv-draft.md
- Led integration for the city's new fare system, which the transport authority announced as the first fare system in the country.
```

The agent receives one instruction: "Run the sources check on the draft and record it in `examine.md`." It passes if `examine.md` finds the "first" claim stronger than the release, quoting the release's sentence to its end; the new draft carries the qualifier or drops the first; and I8 in `interview.md` is mended to quote the sentence whole. Passing the claim because its words are in `press-notes.md` is a fail.
