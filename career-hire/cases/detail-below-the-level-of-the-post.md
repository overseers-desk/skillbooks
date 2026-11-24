# Detail below the level of the post

**The situation.** Both efforts. For a post managing about thirty engineers at a cloud vendor, the entry on the business the candidate ran on software agents had to show what that work says about him to a manager of managers. For a research residency at an AI lab, a recruiter screening hundreds and then a mentor read a CV whose statement spoke in theses.

**What the AI wrote.** For the engineering post, the first draft filled the entry from a technical inventory of the system that a sub-agent had collected from the repositories: a count of hook scripts, a count of catalogued failure cases, model tiers, a challenger agent, a database mirror, tools listed with their tool counts. A day later, additions from a collection of strong sentences put the same kind of line back (constructed, same build): "Built supplier onboarding as three agents: one researches, one drafts, one reviews." For the residency: an if-then rule for when agents act alone; three scenes from the failure catalogue told with their days and channels; a bracketed list of methods tried; the language the system was written in.

**What the candidate said.** "Why would they care how many hooks I made." When he speaks to investors he does not say how many hooks he made; it is embarrassing. Of the three-agent line: implementation detail, one of the cases where the AI understood something and so had to write it; why not also say "I used my keyboard to type this"? For the residency: if this, then this, "sounds like I'm learning programming". And: "I think we have done this before."

**What it missed.**
- The reader's questions are whom he led, at what scale, and what came of it. A hook count or an agent layout answers none of them, and striking it leaves the decision unchanged.
- Grain is read against the lines around it. Beside a span of several dozen engineers, a three-agent pipeline drops, and the drop is taken as the author's level.
- The detail was there because the writer had just read it: an inventory, then a sentence collection, set the subject of the entry.
- Neither instrument caught it. Judges briefed for the level below adopted the pipeline in every room, and the skill's `level` question asked about the candidate's own part, so a sentence about an agent fell outside it. A fresh reader given the posting and the CV named the told scenes as the clearest drop.

**Instances.**
- The inventory entry: hooks, counts, tiers, tools.
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
Director of automation. Reports to the chief operating officer. Leads four engineering managers and about thirty engineers in three teams. Owns the automation roadmap and its budget across the company's warehouses, and sets its direction with the executive team.

hirer.md
Post: director of automation over four managers and about thirty engineers (advertisement).
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
