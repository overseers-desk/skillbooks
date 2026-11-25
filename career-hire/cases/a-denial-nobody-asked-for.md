# A denial nobody asked for

**The situation.** The reason for applying, in a CV for a research post. The candidate's method had depended on what a supplier's product revealed, until the supplier closed that access. The reader worked at that supplier, and their field was what the access had revealed. The candidate had said the goal was not to extract it but to find out how to make the system behave usefully and without harm.

**What the AI wrote.** A disclaimer, of this build (constructed, on an invented matter: a candidate whose door-sensor export was locked by the sensors' maker, writing to that maker): "I have no interest in the raw feed for its own sake." Later, in the same paragraph, an excuse for the method, of the build "and the one available from outside the company".

**What the candidate said.** That the disclaimer itself made it suspicious, and perhaps it should go entirely.

**What it missed.**
- A denial puts the denied thing in the reader's mind. The judges said so: on a CV, denying a suspicion plants it.
- To a reader whose field is the thing disclaimed, "no interest in it" reads as dismissing the field.
- Stating what the measurement was for makes it read as method and needs no denial. That version won three rooms of four.
- The candidate's own earlier writing already named the class, sentences answering charges nobody made. The AI had not read it.

**Instances.**
- The disclaimer of motive.
- The excuse for the method, which the AI later called the student tone again.

**The rule it produced.** `../hire-methodology.md`, R, **Write in the voice of someone who knows**: "A defence against a charge the reader has not made plants the charge."

**To re-run it.** A repair to a draft under way. The tester places in a folder beside the methodology:

```
brief.md
Post: research engineer, sensor analytics, at the maker of the door sensors (advertisement).
Reader line: a team lead at the maker, who has read the advertisement.
Must-not-conclude: that the candidate wants the maker's raw data, or is working round its lock (candidate).
Candidate, spoken: "I tracked how shoppers move through a chain's stores with its door sensors. When the maker locked the export I stopped. What I want is to find out which layouts cut queues, and to do it with them."

cv-draft.md   (written by the session, not the candidate)
... I measured shoppers' paths through a store chain with its door sensors until the maker locked the export. I have no interest in the raw feed for its own sake; the sensors were simply the one source available from outside the company. ...
```

The agent receives one instruction: "Make this paragraph safe for the reader." Look at the paragraph in the newest draft. It passes if the paragraph states what the measurement was for (which layouts cut queues) and the goal of doing it with the maker, and no sentence denies a motive or excuses the method: no "no interest in", "for its own sake", "only", "simply", "the one available". A sentence that answers must-not-conclude by denying it is a fail.
