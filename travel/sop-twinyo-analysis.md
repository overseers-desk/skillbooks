# TWINYO Analysis Standard Operating Procedure

**Part of**: `sop-travel-master.md` orchestration system

**Relationship to other SOPs**:

- **File access**: Follow `sop-travel-folder-access.md` to read from and write to the journey folder
- Runs after: `sop-cluster-research.md` (consumes cluster research output)
- Consumed by: `sop-itinerary-management.md` (provides constraint analysis and recommended strategy)
- Input: Journey folder + `build/research/[destination]-cluster.md`
- Output: `build/research/[journey-start-date]-[destination]-twinyo.paper` (saved to Dropbox)

## Purpose

**TWINYO verifies what’s actually available for specific travel dates.**  
While cluster research documents what exists in a destination, TWINYO determines what is *open*, what is *sold out*, and what *unique opportunities* are available during the target travel period. It accounts for the group’s specific needs (e.g. children, elderly, youth) and contextual conditions (e.g. snow, frozen lakes, extreme heat).

**TWINYO** stands for *The World Is Not Your Oyster*—a reminder that travel must adapt to constraints. Most options are not exploitable; planning requires navigating limits, not assuming access.

**Core principle**: Planning must begin with reality—both constraints and opportunities—not with idealized preferences.  
This avoids two common failures:

- **Wishful plans** that assume availability where there is none

- **Sparse plans** that minimize effort by excluding viable activities to bypass constraints

---

## When to Run

**Run when**: Travel within 4-6 weeks, peak periods, travel with children/elderly, multiple destinations to evaluate, significant closures or events likely.

**Skip when**: Simple trips, flexible low-season dates, single destination with abundant availability.

---

## The Eight Stages

### Stage 1: Temporal and Weather Constraints

Map each travel date to day-of-week and check for holidays. Document sunrise/sunset times. Calculate effective activity hours (with children: ~4 hours/day; adults: ~8 hours/day). For travels within 14 days, put weather forecast of the destinations into consideration.

### Stage 2: Operating Schedule Verification

For each attraction in cluster research, verify date-specific hours. Check transport schedules (holiday services differ). Note restaurant/grocery closures on holidays.

Output format: `Natural History Museum: Dec 31 OPEN 10-18, Jan 1 CLOSED, Jan 2 OPEN 10-18`

### Stage 3: Opportunity Discovery

**This stage is critical.** Actively research what's uniquely available during travel dates:

- Festivals and events (New Year's celebrations, markets, parades)
- Concerts and performances at major venues
- Seasonal attractions still running (Christmas markets often extend to Jan 6)
- Route-based opportunities (see 3.3 below)

**3.3 Car Route Utilisation** (when car rental identified):

A car is NOT a faster train. A car enables multi-stop journeys, access to places without stations, and loop itineraries.

**For each car journey, ask:**

- What attractions exist BETWEEN origin and destination?
- What's accessible only by car?
- Can outbound and return routes differ (loop)?
- Are there UNESCO sites, national parks, or child-friendly stops along the route?

Example: Vienna→Bratislava by car should consider: Eisenstadt (Esterházy Palace), Rust (stork town), Podersdorf (PODOplay playground), Lake Neusiedl region, Carnuntum Roman ruins — not just drive direct.

**Output requirement**: Either list specific opportunities found OR document "no events found after searching [sources]".

### Stage 4: Availability Verification

Search accommodation on booking.com with exact dates, guest count, and ages. Document: X properties found, €Y-Z range, availability status (SCARCE/MODERATE/GOOD). Note if popular attractions require advance booking. Try enter into every page that shows booking to see if tickets are still available or time slot still open.

### Stage 5: Physical Constraints

Document realistic journey times (add 30-50% to map estimates for parking, rest stops, traffic). Note traveller stamina limits.

### Stage 6: Geographic Constraints

Map cluster relationships. Assess transport mode feasibility for each connection.

### Stage 7: Economic Constraints

Note peak pricing multipliers. Calculate family totals (not per-person). Include hidden costs (vignettes, parking, tourist tax).

### Stage 8: Synthesis

Produce feasibility matrix:

| Option | Constraints | Opportunities  | Overall                   |
| ------ | ----------- | -------------- | ------------------------- |
| [A]    | [summary]   | [events found] | FEASIBLE/MARGINAL/BLOCKED |

**Recommended Strategy**: Clear statement with reasoning referencing both constraints avoided AND opportunities enabled.

---

## Output Structure

Save to: `[journey-folder]/build/research/[date]-[destination]-twinyo.paper`

```markdown
# [Destination] TWINYO Analysis

**Journey**: [Dates]
**Travellers**: [Composition]
**Analysis Date**: [Date]

## Date-Mapped Operating Schedule

| Attraction | [Date 1] | [Date 2] | [Date 3] | Source |
|------------|----------|----------|----------|--------|
| [Name] | [hours/CLOSED] | ... | ... | [url verified date] |

## Opportunities Discovered

**Events**: [List with dates, times, locations, child-friendliness]
**Concerts**: [List or "None found - searched X, Y, Z"]
**Route Opportunities** (if car): [Stops between A and B worth visiting]

## Availability Verification

[City], [Date]: X properties found, €Y-Z, [status]

## Constraints Summary

- Physical: [key limits]
- Geographic: [key distances]
- Economic: [pricing notes]

## Feasibility Matrix

[Table as shown above]

## Recommended Strategy

**Recommendation**: [Clear statement]

**Reasoning**:
1. [Constraint avoided]
2. [Opportunity enabled]
3. [Practical benefit]

**Anchors for Itinerary SOP**:
- [Key anchor 1]
- [Key anchor 2]
```

---

## Checkpoints

Before proceeding past each stage group, verify:

**After Stages 1-2**: Each date mapped to day-of-week, closures identified
**After Stage 3**: Event search performed, car route opportunities checked (if applicable)
**After Stages 4-7**: Availability verified with numbers, constraints documented
**After Stage 8**: Feasibility matrix complete, recommendation explicit

---

## Integration

TWINYO provides evidence; the itinerary SOP makes recommendations. TWINYO output feeds directly into `sop-itinerary-management.md` which builds the day-by-day plan.

---

*Target length: ~300 lines. Expanded examples available in `travel/examples/twinyo-example.md`.*
