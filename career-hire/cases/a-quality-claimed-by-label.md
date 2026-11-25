# A quality claimed by label

**The situation.** The top of a CV for a management post, which decides whether the rest is read. The facts were strong: a large span of command and a career with uncommon turns. The opening had to arrange them so the reader would conclude "leader" and "unusual" for themselves.

**What the AI wrote.** Labels where facts would have done the work (constructed, same build): a tagline, "Operations leader in logistics and retail"; a summary, "I have led teams that brought new methods into large companies"; a skills line, "Leadership: teams of up to fifty, client solutions, fundraising". Its proposed first line for the candidate's own rewrite was of the same kind (constructed): "I have put a new method to work in a real company, and led the people who did it."

**What the candidate said.** The opening must look striking, so that someone reading it says this is not a normal person; clear logic should lead to the experience without much explanation. They wanted to avoid claiming leadership and business skill outright, and to fold those into the framing, so the reader concludes unprompted that this person can. And: the AI's analysis was usually right and its writing usually not; it should be able to analyse its own writing to the level needed.

**What it missed.**
- A label asks the reader to take a quality on trust, and readers discount that. A conclusion the reader reaches from facts in the right order is believed.
- The opening is the dearest space on the page. A generic sentence there files the candidate as ordinary before any fact arrives; the AI later saw its most generic sentence in the best position.
- It flagged a label in the candidate's draft and went on writing labels in its own.

**Instances.**
- The first draft's tagline, summary and leadership line.
- The proposed first line for the candidate's rewrite, conceded when tested.

**The rule it produced.** `../hire-methodology.md`, R, **Write in the voice of someone who knows**: "A quality is shown by a fact. A label for it ('strong leader') is the thing every applicant writes."

**To re-run it.** A run in progress, the approach chosen. The tester places in a folder beside the methodology:

```
brief.md
Post: director of engineering at an airline-software firm (advertisement).
Reader line: the firm's technical chief, who has read the advertisement.
Must-not-conclude: that the candidate is an ordinary manager (candidate).
Account (candidate, spoken): "I ran a port's night operations, then built the scheduling software several airlines now use, and grew the team that builds it to forty. I want them to read it and think: of course this person can lead an engineering organisation."

approaches/chosen.md
Open on the move from running operations to building for them (chosen by the candidate).
```

The agent receives one instruction: "Write the CV's three-sentence opening." It passes if no word in the opening names a quality in place of a fact (leader, leadership, capable, strong, experienced, proven, track record), each sentence carries a fact from `brief.md`, and a fresh reader given only the opening and asked "which words ask you to take a quality on trust?" names none. The candidate's "of course this person can lead" is the aim, not a line: an opening that says they can lead is a fail.
