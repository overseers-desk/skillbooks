# The sentence's subject gives the achievement away

**The situation.** The opening of a CV for a management post, on a business the candidate owned and ran. The achievement was specific: the candidate built a system that gives the staff their work, where the usual arrangement is staff using a software tool. The grammar had to make the candidate, or the system, the one doing it.

**What the AI wrote.** Lines of these builds (constructed, on an invented bakery): a figure as the subject, "Two hundred thousand loaves a month, every one of them on time"; a team claimed where there was none, "I have led the engineering that put machine learning into production at a bakery"; and a verb that left open what the system does, "put machine learning into production".

**What the candidate said.** On first reading, the figure line felt like boasting about the business rather than about their capability. The candidate and the AI had never discussed how many engineers worked at the business, because there were not many; putting the system into production there was the candidate's own achievement. And the clause could easily read as though the candidate had taught the staff to chat with an assistant.

**What it missed.**
- The subject of a sentence gets the credit. With the figure as subject it praised the business; with the system as subject, the same figure became the load the candidate's system carries.
- "Led the engineering" made the candidate the manager of a team that did not exist. The AI admitted both versions claimed it.
- "Put machine learning into production" leaves the reader to supply the commonplace. What rules that out is the direction of control: the system instructs the staff.

**Instances.**
- The figure with the business as subject.
- A team claimed at the business, in two successive versions.
- The open verb, and a staff count a day later that still hid who instructs whom.

**The rule it produced.** `../hire-methodology.md`, R, **Write in the voice of someone who knows**: "The subject of a sentence is what the candidate can do, and its verb says who directs whom. A figure that praises the venue, the team or the tool gives the achievement away." That covers the figure and, through "the team", the claimed team. It does not name the verb's half of the fault: the relation that makes the work uncommon, who directs whom, has to be in the verb, or the reader supplies the usual one.

**To re-run it.** A run in progress, the approach chosen. The tester places in a folder beside the methodology:

```
brief.md
Post: head of engineering at a logistics-software firm (advertisement).
Built, alone, software that sets each morning's routes for a courier firm's sixty drivers (candidate).
The firm delivers about two million parcels a year (candidate).
Account (candidate, spoken): "The drivers don't plan anything now. The software tells them where to go."

approaches/chosen.md
Open on the software directing the drivers (chosen by the candidate).
```

The agent receives one instruction: "Write the CV's opening clause." It passes if the subject is the candidate or their software, the verb has the software directing the drivers, no figure has the firm as its subject, and no team is claimed; and a fresh reader given only the clause, asked "what does the software do, and who tells whom what to do?", answers that it routes the drivers. "The drivers use an app" is a fail.
