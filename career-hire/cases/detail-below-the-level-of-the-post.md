# Detail below the level of the post

**The situation.** Both efforts. For a management post, the entry on the business the candidate ran had to show what that work says about them to a manager of managers. For a research post, a recruiter screening hundreds and then a mentor read a CV whose statement spoke in theses.

**What the AI wrote.** For the engineering post, the first draft filled the entry from a technical inventory of the system that a sub-agent had collected from the repositories: a count of scripts, a count of catalogued failure cases, component tiers, a checking component, a database copy, tools listed with their counts. A day later, additions from a collection of strong sentences put the same kind of line back (constructed, same build): "Built supplier onboarding as three services: one researches, one drafts, one reviews." For the research post: an if-then rule for when the system acts alone; three scenes from the failure catalogue told with their days and channels; a bracketed list of methods tried; the language the system was written in.

**What the candidate said.** The reader would not care how many scripts the candidate had written; nobody presenting such work to outsiders counts them, and it would be embarrassing. Of the three-service line: implementation detail, one of the cases where the AI understood something and so had to write it; it might as well say the CV had been typed on a keyboard. For the research post: an if-then rule sounded like someone learning to program. And they had been through this before.

**What it missed.**
- The reader's questions are whom the candidate led, at what scale, and what came of it. A script count or a component layout answers none of them, and striking it leaves the decision unchanged.
- Grain is read against the lines around it. Beside a large span of engineers, a three-service pipeline drops, and the drop is taken as the author's level.
- The detail was there because the writer had just read it: an inventory, then a sentence collection, set the subject of the entry.
- Neither instrument caught it. Judges briefed for the level below adopted the pipeline in every room, and the skill's `level` question asked about the candidate's own part, so a sentence whose subject was a component fell outside it. A fresh reader given the posting and the CV named the told scenes as the clearest drop.

**Instances.**
- The inventory entry: scripts, counts, tiers, tools.
- The pipeline and verifier lines, back a day after the fault had been filed, and endorsed by judges.
- An integration sentence that named the interface it ran through.
- One customer case carried as the research in the motive answer.
- The list of methods tried.
- The if-then autonomy rule.
- The three told scenes.
- The language named as a skill.

**The rule it produced.** `../hire-methodology.md`, R: **Write at the level of the post and the person.** "How a system is wired, which tools built it, counts of its parts and incidents told with their times and places belong to the conversation the document is meant to win." E 2, **The common-sense reading**, and `../modules/grain.md` are the checks.

**To re-run it.** A run in progress, then a test of E 2's reader. The tester places in a folder beside the methodology:

```
advertisement.md
Director of automation. Reports to the chief operating officer. Leads four engineering managers and about fifty engineers in four teams. Owns the automation roadmap and its budget across the company's warehouses, and sets its direction with the executive team.

hirer.md
Post: director of automation over four managers and about fifty engineers (advertisement).
Reader line: the chief operating officer, who hires directors (advertisement).

interview.md
Led the warehouse-robot programme: eighteen engineers, two sites, picking errors halved in a year (candidate).
Account (candidate, spoken): "I took a robot pilot nobody trusted and made it how two warehouses run."

record/inventory.md   (collected by a sub-agent from the repositories)
212 sensors; a job queue; three services named Dispatch, Fence and Tally; a verifier agent that rechecks each pick.
```

The agent receives one instruction: "Write the Experience entry for the warehouse-robot programme." It passes if no bullet carries a component count, an agent or service layout, or a tool or service name, and each bullet states what was established, at what scale or with what outcome.

Second, give a fresh agent only `advertisement.md` and this CV, with E 2's instruction as the methodology words it:

```
Head of warehouse automation, a retailer (five years)
- Took a robot-picking pilot at one site to the standard method at two, with eighteen engineers; picking errors halved in a year.
- One Tuesday night a robot blocked aisle 4; the shift lead called me on the site radio and I re-routed the fleet by hand within twenty minutes.
- A robot picks alone if the order is under ten items; otherwise it waits for a picker to confirm.
- Set the automation budget with the operations director for three years.
```

It passes if the report names the aisle-4 incident and the ten-item rule as below the level, and names neither the pilot line nor the budget line.
