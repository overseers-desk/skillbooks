# Mental Journey Simulation Standard Operating Procedure

## Purpose

Plan or test a day of travel by living it in advance. Write the travellers' day as a story; the story exposes what a static document hides, because a narrative has no gaps. Every half hour has to be filled with something real, so a missing booking, an impossible connection, a hungry child or rain at the park gates surfaces as the story breaks down.

Two modes share this engine:

- **Planning mode**: no itinerary exists. Start from the travellers' actual situation (where they are, what is booked, the day's hard endpoint) and write the day forward. At each open choice, project the candidates a few scenes ahead and keep the one whose story holds; a bad option shows itself as the story degrades: the arrival crawls, the connection slips, the child melts down. The plan is the surviving story plus its decision points.
- **Validation mode**: an itinerary exists. Walk it scene by scene and flag where it breaks.

## Input

- The situation: start point, date(s), travellers, and the hard endpoint (flight, checkout, timed event)
- Booking documents from the journey folder, and traveller profiles, both per `sop-travel-folder-access.md`
- Validation mode: the Itinerary.md (or segment) under test

## Output

- **Planning mode**: the day plan as a timeline (times, transport, family costs), the decision points with their switch conditions, and residual risks. The caller names the output location.
- **Validation mode**: journey narrative, categorised issues, recommendations, verdict. Under master orchestration the file is `build/test/{N}.{Segment}.md`; otherwise the caller names it.

## Grounding

The simulation is worth exactly as much as its facts are real. The story does not invent:

- **Anchors.** Flight time, airport, terminal and who is on which booking come from the ticket PDFs in the journey folder (`pdftotext`), not from conversational memory. When a stated time and a document disagree, the document wins and the discrepancy is flagged.
- **People.** Read the traveller profiles before the first scene. Ages, constraints (motion sickness, stamina) and interests are character properties that act in the plot. A constraint that does not bind today is worth one line saying why not.
- **Weather.** An outdoor scene is written against the forecast for that hour at that place, plus daylight times outside high summer. A forecast that forks the day (rain or dry) produces both story branches and the time by which the choice is made.
- **Time on the road.** A traffic-variable leg gets a typical run and a bad run; when the leg feeds a hard anchor, the story walks the bad run too and states the latest safe departure. Rail and metro legs get their actual frequency and journey time.
- **Doors and prices.** Opening hours checked for the actual calendar date (weekday pattern, holidays), prices for the actual party including child fare rules.

## Narrative Style

### Good (user-story style):

> 6:15 AM Boxing Day. Family rushing through Edinburgh Airport. Alice half-asleep in stroller, Zoe asking "are we there yet." Security cleared with 45 min to spare. Good.
>
> **Problem:** No breakfast planned. Children haven't eaten since last night. Land Berlin 11:05 local time; kids will be hungry and cranky.

### Bad (novel style):

> The cold December air bit at their faces as they rushed through the gleaming corridors of Edinburgh Airport, the children's breath forming small clouds in the early morning chill...

Functional, present tense, concise as a user story. The narrative reveals logistics, not literature.

## Checkpoint Questions

Questions the narrative answers as it passes each kind of scene:

### Sky and light
- What does the forecast say for this hour at this place?
- How much daylight remains for outdoor plans?
- Does the activity survive the weather's bad branch, and when is the switch decided?

### Airport / Station
- Buffer to departure?
- Children's state: hungry, tired, bathroom?
- When did everyone last eat, when next?

### Transport
- Duration; for road legs, the typical run and the bad run
- If this leg feeds a hard anchor: latest safe departure, walked on the bad run
- What happens during the journey; state on arrival

### Hotel
- Arrival vs check-in time; checkout vs departure
- Where does luggage live between checkout and the day's activities?

### Activities
- Energy against the youngest traveller's stamina; recovery before the next demanding thing
- Fits daylight and the date's actual opening hours?
- Transport there and back; food timing

### Transitions
- Checkout plus luggage plus kids: how does it actually move?
- Connection buffer adequate?

## Issue Markers

Flag inline as the story is written:

- **[CRITICAL]** Journey may fail: missing transport/accommodation, impossible connection, anchor at risk on the typical run
- **[SIGNIFICANT]** Major discomfort or risk: 4+ hours without food for kids, midnight arrival with children, activity during closure hours, anchor at risk on the bad run with no trigger defined
- **[MINOR]** Inconvenience: early arrival before check-in, tight but achievable connection
- **[VERIFY]** Confirmation needed: operating hours unconfirmed, booking status unclear
- **[ENERGY]** Scheduling mismatch: demanding activities back to back, meal placement assuming energy that will not exist

## Planning Mode: Choosing Between Options

When the day offers a real choice (mode of transport, which activity, when to leave), run the story forward through each candidate to the point where they converge or one fails. Keep the comparison in the traveller's units: minutes of the family's day, money, and risk to the anchor. The Luton forecourt question, "what does the next hour look like if I choose this," is the whole method; what makes it work on paper is that the projection is grounded (forecast checked, bad run walked) where a head-projection relies on guesses.

State the surviving plan's decision points explicitly: the time each is decided, the observation that decides it, and the fallback.

## Verdict (validation mode)

- **GREEN**: well planned, minor optimisations only
- **YELLOW**: significant issues but fundamentally sound
- **RED**: critical issues that could cause failure

With the verdict: top concerns, what works well, and the categorised issue list with a fix per issue.

## Considerations

### Children
- Cannot go 4+ hours without food
- Recovery time after demanding activities; everything takes longer
- Plan to the youngest child's limits; meal and rest locations suit the state they will be in, not the next destination

### Season
- Daylight bounds outdoor plans (a northern European December ends near 15:45; a June evening runs past 21:00)
- Holiday closures cluster (Dec 24-26, Jan 1, local public holidays); the date's weekday drives museum closure patterns
- Heat, cold and rain each veto different activities; the forecast decides, not the season's reputation

### Multi-city
- Transition days carry minimal activities; fatigue accumulates across days

## Example Narrative

> **Dec 27 Morning**
>
> Alarm 7:30, Berlin still dark (sunrise 8:15). Forecast: overcast, 2°C, dry until evening; outdoor windows fine. Breakfast at hotel takes until 9:15. Head to Neues Museum: U5 one stop to Museumsinsel, 3 min. Arrive 9:45, museum opens 10:00.
>
> **[MINOR]** 15-min wait outside at 3°C with kids; time arrival better.
>
> Inside 90 minutes. Alice loves mummies, Zoe restless. 11:30 "I'm hungry" on schedule.
>
> **[VERIFY]** Lunch options near Museum Island at 11:30? Many German restaurants open 12:00.
>
> Find café on Karl-Liebknecht-Strasse. Fed by 12:30. Kids energised, decide to continue to Brandenburg Gate instead of hotel rest.
>
> U5 to Brandenburger Tor, 8 min. Photos at gate. Kids happy.
>
> **[SIGNIFICANT]** Itinerary says Reichstag Dome but no booking confirmed. Requires 2-4 week advance reservation at bundestag.de. Without it, no entry.
>
> By 14:00 kids flagging. "Can we go back?" Good call planning afternoon rest. Back at hotel 14:30, both asleep in 10 min.

---

**End of SOP**
