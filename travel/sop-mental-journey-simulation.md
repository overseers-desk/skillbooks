# Mental Journey Simulation Standard Operating Procedure

## Purpose

Validate travel itineraries by walking through them as if you are the traveller. The simulation produces a narrative that reveals gaps, timing issues, and logistical problems that static itinerary documents miss.

The output is a **story-like narrative** written from the traveller's perspective, highlighting smooth segments and problematic moments.

## Input

- **Required:** Path to an Itinerary.md file OR a journey folder containing booking documents
- **Optional:** Traveller composition (defaults to "family with 2 young children" if not stated)

## Output

1. **Journey Narrative** - Story-format walkthrough of the entire trip
2. **Issues Discovered** - Categorized list of problems found
3. **Recommendations** - Suggested fixes for each issue

**Output Location**:
- When run as part of master orchestration: `build/validation/journey-simulation.md`
- When run standalone for testing: caller specifies output path (e.g., `travel/test/`)
- The output is a single markdown file containing all sections below

---

## Simulation Process

### Step 1: Extract Journey Parameters

From the itinerary, extract:
- Traveller composition (adults, children, special needs)
- Journey dates (day-by-day breakdown)
- Locations (cities, hotels, airports, stations)
- Transport segments (flights, trains with times)
- Activities (attractions, events)
- Accommodation (hotels with check-in/out times)

For journey folders, use `pdftotext` on booking PDFs:
```bash
pdftotext "/path/to/Fares/booking.pdf" -
```

### Step 2: Walk Through Each Segment

Write a brief narrative paragraph for each segment. Focus on:
- What the family is doing
- Logistics they need to manage
- What could go wrong

**Use present tense. Write concisely like a user story.**

---

## Narrative Style

### Good (User-Story Style):

> 6:15 AM Boxing Day. Family rushing through Edinburgh Airport. Alice half-asleep in stroller, Zoe asking "are we there yet." Security cleared with 45 min to spare—good.
>
> **Problem:** No breakfast planned. Children haven't eaten since last night. Land Berlin 11:05 local time—kids will be hungry and cranky.

### Bad (Novel Style):

> The cold December air bit at their faces as they rushed through the gleaming corridors of Edinburgh Airport, the children's breath forming small clouds in the early morning chill...

Keep it functional. The story reveals logistics, not literary prose.

---

## Checkpoint Questions

At each checkpoint, answer briefly in narrative form:

### Airport/Station
- Time pressure: buffer to departure?
- Children's state: hungry? tired? bathroom?
- Food situation: when last ate, when next?

### Transport (Flight/Train)
- Duration and comfort
- What happens during journey
- Arrival state

### Hotel Check-In
- Arrival vs check-in time (usually 15:00)
- Early arrival plan? Late arrival 24hr reception?
- Luggage storage if room not ready?

### Activities
- Energy levels after rest?
- Fits within daylight/opening hours?
- Transport to/from?
- Food timing?

### Inter-City Transitions
- Checkout + transport logistics with luggage and kids
- Connection buffer adequate?

---

## Issue Markers

Flag issues inline as you write:

**[CRITICAL]** Journey may fail
- Missing transport/accommodation booking
- Impossible connection

**[SIGNIFICANT]** Major discomfort/risk
- 4+ hours without food for kids
- Midnight hotel arrival with children
- Activity during closure hours

**[MINOR]** Inconvenience
- Early hotel arrival before check-in
- Tight but achievable connection

**[VERIFY]** Confirmation needed
- Operating hours not confirmed
- Booking status unclear

---

## Output Template

```markdown
# Journey Simulation: [Journey Name]

**Travellers:** [Names/composition]
**Dates:** [Start - End]

---

## Day 1: [Date] - [Title]

### Morning/Departure
[Brief narrative - what happens, logistics, problems]

### Transit
[Journey experience]

### Arrival
[Landing, transfer, hotel]

### Afternoon/Evening
[Activities if any, dinner, settling]

---

## Day 2: [Date] - [Title]
[Continue pattern...]

---

## Day N: [Date] - Departure
[Checkout, final activities, departure logistics]

---

# Issues Summary

## Critical
1. [Issue] - Day X
   **Fix:** [Recommendation]

## Significant
1. ...

## Minor
1. ...

## Verify
1. ...

---

# Verdict

**Assessment:** [GREEN/YELLOW/RED]
- GREEN: Well-planned, minor optimizations only
- YELLOW: Significant issues but fundamentally sound
- RED: Critical issues that could cause failure

**Top Concerns:**
1. ...
2. ...

**Works Well:**
1. ...
2. ...
```

---

## Special Considerations

### Winter Travel
- Track sunset (can be 15:45 in northern Europe December)
- Holiday closures (Dec 24-26, Jan 1)

### Young Children
- Cannot go 4+ hours without food
- Need 30-60 min rest between activities
- Everything takes longer

### Multi-City
- Transition days = minimal activities
- Fatigue accumulates across days

---

## Example Narrative (Concise Style)

> **Dec 27 Morning**
>
> Alarm 7:30, Berlin still dark (sunrise 8:15). Breakfast at hotel takes until 9:15. Head to Neues Museum—U5 one stop to Museumsinsel, 3 min. Arrive 9:45, museum opens 10:00.
>
> **[MINOR]** 15-min wait outside in 3°C with kids—time arrival better.
>
> Inside 90 minutes. Alice loves mummies, Zoe restless. 11:30 "I'm hungry" on schedule.
>
> **[VERIFY]** Lunch options near Museum Island at 11:30? Many German restaurants open 12:00.
>
> Find café on Karl-Liebknecht-Strasse. Fed by 12:30. Kids energized, decide to continue to Brandenburg Gate instead of hotel rest.
>
> U5 to Brandenburger Tor, 8 min. Photos at gate. Kids happy.
>
> **[SIGNIFICANT]** Itinerary says Reichstag Dome but no booking confirmed. Requires 2-4 week advance reservation at bundestag.de. Without it, cannot enter.
>
> By 14:00 kids flagging. "Can we go back?" Good call planning afternoon rest. Back at hotel 14:30, both asleep in 10 min.
>
> **Evening**
>
> Kids wake 16:30. Sun already set (15:52). Walk to Alexanderplatz Christmas Market 5 min. Bratwurst, carousel, glühwein. Back 19:00. Bed 20:30. Tomorrow is LEGOLAND—Alice hasn't stopped talking about it.

---

**End of SOP**
