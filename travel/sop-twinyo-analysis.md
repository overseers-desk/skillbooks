# TWINYO Analysis Standard Operating Procedure

**Part of**: `sop-travel-master.md` orchestration system

**Relationship to other SOPs**:
- **File access**: Follow `sop-travel-folder-access.md` to read from and write to the journey folder (Dropbox via MCP)
- Runs after: `sop-cluster-research.md` (consumes cluster research output)
- Consumed by: `sop-itinerary-management.md` (provides constraint analysis and recommended strategy)
- Input: Journey folder + `build/research/[destination]-cluster.md`
- Output: `build/research/[journey-start-date]-[destination]-twinyo.md` (saved to Dropbox journey folder)

## Purpose Statement

This SOP performs date-specific constraint analysis and opportunity discovery for a journey. While cluster research (`sop-cluster-research.md`) documents WHAT EXISTS at destinations (stable information that can be researched months ahead), TWINYO verifies WHAT'S AVAILABLE for THIS specific journey (dynamic information requiring near-term dates).

**What this SOP produces:**
1. Date-mapped operating schedules (not "closed Mondays", but "Dec 29 = Monday = CLOSED")
2. Actual availability verification (hotel search results with numbers)
3. Opportunity inventory (specific events ON travel dates)
4. Feasibility matrix comparing options
5. Recommended strategy for the itinerary SOP to adopt

**What the itinerary SOP does with this:**
- Adopts the TWINYO recommendation
- Builds day-by-day schedule around discovered opportunities
- Provides booking guidance and logistics
- Produces the final traveller-facing document

---

## Input

- **Journey folder path**: Contains Fares/, Accommodations/, Passes/ subfolders
- **Cluster research document**: `build/research/[destination]-cluster.md` (from `sop-cluster-research.md`)
- **Travel dates**: Extracted from transport bookings in Fares folder
- **Traveller composition**: Extracted from journey folder name (adults, children, special needs)

## Output

**File location**: `[journey-folder]/build/research/[journey-start-date]-[destination]-twinyo.md`

Save the output to the journey folder in Dropbox using `sop-travel-folder-access.md`. Use `DROPBOX_CREATE_PAPER` via Rube MCP tools with `import_format: "markdown"`. The file path must end with `.paper` extension.

**Example**: For journey folder `2025-12-23 Edinburgh, Berlin, Munich, Vienna, Warsaw - Liansu, Weiwu, A-Z`, save Vienna TWINYO to:
`/0. Travel Admin/2025-12-23 Edinburgh.../build/research/2025-12-31-vienna-twinyo.paper`

**Contents**:
1. Date-mapped operating schedules for attractions
2. Availability verification results (accommodation search)
3. Opportunity inventory (events, concerts, festivals on travel dates)
4. Feasibility matrix with constraint synthesis
5. Recommended strategy with reasoning

---

## When to Run TWINYO

**Execute this SOP when:**
- Travel dates are within 4-6 weeks (availability can be meaningfully verified)
- Peak travel periods (New Year's, Christmas, summer holidays, major festivals)
- Multiple destination options need evaluation
- Travel includes constraints (children, elderly, accessibility needs)
- Significant closures or special events are likely during travel dates

**Skip this SOP when:**
- Simple round-trip travel with abundant availability
- Flexible low-season dates with no special events
- Single destination with straightforward planning
- Cluster research alone provides sufficient information

---

## Philosophy

The world is not your oyster during peak travel periods, school holidays, major festivals, or when travelling with specific needs. Planning must start with **what's actually possible AND what's actually available**, not with **what would be ideal**.

This methodology forces systematic examination of reality constraints **AND active discovery of opportunities** before proposing strategies, preventing two common failure modes:

**Failure Mode 1: Wishful Planning** - recommending beautiful plans that collapse upon contact with:
- Sold-out hotels on New Year's Eve
- Museums closed on the Monday you're visiting
- Sunset at 16:00 making evening outdoor activities impossible
- No family rooms available in the "perfect" hotel
- Children exhausted after 2 hours when you planned 6 hours of activities

**Failure Mode 2: Minimalist Planning** - producing sparse plans that avoid constraints by avoiding activities:
- Missing the New Year's Eve street festival because it "might be crowded"
- Skipping concerts and performances because schedules weren't researched
- Ignoring seasonal events that define the destination experience
- Creating generic sightseeing plans that could apply to any time of year

**Core Principle**: Document constraints AND discover opportunities. Strategies exploit what's uniquely available during the travel window, working within real-world limits.

---

## Anti-Patterns This Methodology Prevents

### ❌ Premature Optimization
Recommending "Füssen first, then Innsbruck" before checking:
- Which attractions are actually open January 1?
- Are there any hotels with family rooms available January 1?
- What time does it get dark in winter?

### ❌ Generic Information
"Museum closed Mondays" without mapping to actual travel dates.

**Problem**: Your travel dates might not include a Monday, or the museum might have special holiday closures more relevant than the Monday pattern.

### ❌ Wishful Availability
"Book accommodation in Munich" without checking availability.

**Problem**: New Year's Night in capital cities often means 90%+ sold out, remaining hotels 3-5x normal price, no family rooms.

### ❌ Idealized Timing
Planning 8-hour activity days with children ages 6 and 11.

**Problem**: Real-world effective activity time is ~4 hours/day when accounting for morning routine (3 hours), meals, transport, rest periods, evening settling.

### ❌ Distance Blindness
"Visit X and Y in one day" because they look close on a map.

**Problem**: 50km might be 2+ hours with traffic, mountain roads, or poor public transport connections.

### ❌ Minimalist Avoidance (NEW - Critical)
Creating sparse plans that avoid constraints by avoiding activities entirely.

**Problem**: "September 21 afternoon - relax at hotel" when Munich Oktoberfest (the world's largest beer festival with 6 million visitors) is in full swing 2km away. The plan avoids dealing with crowds/reservations by avoiding the defining experience of visiting Munich during Oktoberfest.

**Correct approach**: Research what IS happening, then decide whether to attend with full knowledge of logistics (crowds, child-friendliness, timing, transport back to hotel).

### ❌ Opportunity Blindness
Failing to research what unique events, performances, or seasonal attractions are available during travel dates.

**Problem**: Planning "visit Neuschwanstein Castle" without checking if the Bavarian State Opera has a special performance, if there's an Oktoberfest-related event, or if autumn foliage is at peak. Generic sightseeing that ignores what makes THIS visit different from visiting any other week.

---

## RUN Workflow

Execute the following stages in order, documenting findings as you go.

### CHECKPOINT 1: Input Verification

Before beginning analysis, verify:
- [ ] Journey folder path exists and contains Fares/ with transport bookings
- [ ] Travel dates extracted from Fares (start date, end date)
- [ ] Traveller composition extracted from folder name
- [ ] Cluster research document exists: `build/research/[destination]-cluster.md`
- [ ] If cluster research doesn't exist, run `sop-cluster-research.md` first

### CHECKPOINT 2: After Stages 1-2 (Constraint Mapping)

Verify before proceeding:
- [ ] Each travel date mapped to day-of-week
- [ ] Public holidays identified for each date
- [ ] Sunrise/sunset times documented
- [ ] Attractions from cluster research mapped to date-specific availability
- [ ] Critical closures identified (attractions closed on specific travel dates)

### CHECKPOINT 3: After Stage 3 (Opportunity Discovery)

Verify before proceeding:
- [ ] Event search performed for each travel date
- [ ] Concerts/performances checked at major venues
- [ ] Seasonal attractions verified (still running on travel dates?)
- [ ] At least one specific event found OR explicitly noted "no events found after searching [sources]"

### CHECKPOINT 4: After Stages 4-7 (Constraint Analysis)

Verify before proceeding:
- [ ] Accommodation availability verified with actual search results
- [ ] Physical constraints documented (traveller capabilities)
- [ ] Geographic routing evaluated
- [ ] Economic constraints noted if applicable

### CHECKPOINT 5: Final Output

Verify output document contains:
- [ ] Date-mapped operating schedule table
- [ ] Opportunity inventory (events on travel dates)
- [ ] Availability verification results
- [ ] Feasibility matrix comparing options
- [ ] RECOMMENDED STRATEGY with explicit reasoning

---

## The Eight Analysis Stages

**Stages 1-2**: Temporal and operational constraints (what's closed, when)
**Stage 3**: Opportunity discovery (what's ON - events, concerts, festivals)
**Stages 4-7**: Scarcity, physical, geographic, economic constraints
**Stage 8**: Synthesis with explicit recommendation

### Stage 1: Temporal Constraints Analysis

**Objective**: Map time-based limitations that cannot be negotiated

#### 1.1 Calendar Date Mapping
- What day of week is each travel date?
- Are any travel dates public holidays (national, religious, local)?
- What is the seasonal period (peak summer, winter holidays, shoulder season)?

**Output Format**:
```
Dec 31, 2025 = Wednesday (New Year's Eve)
Jan 1, 2026 = Thursday (New Year's Day - public holiday in most of Europe)
Jan 2, 2026 = Friday (regular day, but post-holiday recovery period)
```

#### 1.2 Seasonal Daylight Constraints
- Sunrise and sunset times for travel dates at destination
- Useful daylight hours (exclude twilight for outdoor activities)
- Weather patterns (rain probability, temperature range, snow season)

**Output Format**:
```
Munich, September 20-22:
- Sunrise: 06:58
- Sunset: 19:18
- Useful daylight: ~12 hours (07:30-19:00)
- Outdoor activities feasible throughout day
- Temperature: 12°C to 20°C, autumn weather, rain possible
```

#### 1.3 Effective Activity Hours
Account for traveller-specific constraints:

**With children (ages 0-12)**:
- Morning routine: 2-3 hours from wake to ready to depart
- Activity stamina: 1.5-2 hours before rest needed
- Rest periods: 30-60 minutes between activities
- Evening settling: 1.5-2 hours from dinner to sleep
- **Effective activity time**: ~4 hours per 12-hour day

**With elderly travellers**:
- Slower pace: 1.5x time for same activities
- More frequent rest: every 60-90 minutes
- Earlier dinner: limited evening activities

**Standard adult travel**:
- Morning routine: 1-1.5 hours
- Activity stamina: 3-4 hours before rest
- **Effective activity time**: ~8 hours per 14-hour day

#### 1.4 Weekly Closure Patterns
Many attractions close specific days weekly (Monday/Tuesday most common).

**Critical Rule**: Always map closure days to actual calendar dates.

**Output Format**:
```
Deutsches Museum Munich:
- Closure pattern: CLOSED some Mondays (check calendar)
- Sep 20, 2025 = Saturday → OPEN
- Sep 21, 2025 = Sunday → OPEN
- Sep 22, 2025 = Monday → Check holiday schedule
```

---

### Stage 2: Operating Schedule Verification

**Objective**: Document actual operating hours for specific travel dates, not generic hours

#### 2.1 Date-Specific Operating Hours
Research primary sources (official websites, not aggregator sites) for:
- Standard operating hours
- Holiday hours (often reduced)
- Seasonal variations (winter hours vs summer hours)
- Special closures (renovation, private events)

**Documentation Standard**:
```
❌ BAD: "Schönbrunn Palace: 8:30-17:00, closed Jan 1"
✅ GOOD:
Schönbrunn Palace (Dec 31, 2025 - Jan 2, 2026):
- Dec 31: 08:30-17:00 (standard hours)
- Jan 1: CLOSED (New Year's Day)
- Jan 2: 08:30-17:00 (reopens)
Source: schoenbrunn.at/en/plan-your-visit/opening-hours (verified Dec 29, 2025)
```

#### 2.2 Transport Operating Schedules
Public transport often operates on holiday schedules:
- Sunday/holiday schedules (reduced frequency)
- Last train/bus times (relevant for evening activities)
- Special New Year's Eve/Day schedules (extended or curtailed)

**Output Format**:
```
Munich U-Bahn, September 20-22, 2025:
- Operates on normal schedule (Sat-Mon)
- Frequency: Every 5-10 minutes
- Night services: Extended during Oktoberfest (U4/U5 to Theresienwiese)
- Note: Trains crowded 17:00-23:00 due to festival traffic
```

#### 2.3 Restaurant/Food Availability
Critical for travel with children or dietary needs:
- Many restaurants closed New Year's Day
- Advance reservations required for New Year's Eve
- Grocery stores closed on public holidays

**Output Format**:
```
Dining, Munich, Sep 20 (Oktoberfest Saturday):
- Most restaurants: OPEN but extremely busy
- Beer tents: Reservations essential (book months ahead)
- Non-tent restaurants: Walk-in possible but expect queues
- Grocery stores: OPEN normal hours
- Recommendation: Book tent reservation OR arrive before 10:00 for walk-in seats
```

---

### Stage 3: Opportunity Discovery (NEW - Critical Stage)

**Objective**: Actively research what unique events, performances, and seasonal attractions are available during travel dates

This stage prevents the "minimalist avoidance" anti-pattern by requiring explicit research into what's ON, not just what's closed.

#### 3.1 Seasonal Events and Festivals

Research what special events occur during travel dates:
- Christmas/New Year's markets and their specific operating dates
- New Year's Eve celebrations and street parties
- Winter festivals, light shows, seasonal attractions
- Special holiday programming at major venues

**Output Format**:
```
Munich, September 20-22:

CONFIRMED EVENTS:
- Oktoberfest: Sep 20 - Oct 5, daily 10:00-23:30 (tents close 22:30)
  - 14 large tents: Hofbräu, Augustiner, Paulaner, Hacker-Pschorr, etc.
  - Traditional music, rides, parades (Sep 21 Trachten parade)
  - FREE entry to grounds (drinks/food extra)
  - Family days: Tue reduced prices, children's areas at Oide Wiesn
  Source: oktoberfest.de (verified Aug 15, 2025)

- Munich Philharmonic Season Opener: Sep 21 19:30
  - Gasteig HP8, tickets €45-120 available
  - Program: Mahler Symphony No. 2

NO EVENTS FOUND:
- No Bayern Munich home match Sep 20-22 (checked bundesliga.com)
- Residenz concerts: None scheduled (season starts October)
```

#### 3.2 Concerts, Performances, and Shows

Actively search for performances during travel dates:
- Concert halls and their January schedules
- Opera houses, ballet companies, theatres
- Special New Year's performances
- Child-friendly shows and performances

**Research Method**:
1. Search "[City] concerts [Month Year]"
2. Check official websites of major concert halls
3. Search "[City] ballet [Month Year]", "[City] opera [Month Year]"
4. Search "[City] what's on [specific dates]"

**Output Format**:
```
Salzburg Region, September 20-22, 2025:

SALZBURG FESTIVAL (salzburgerfestspiele.at):
- Schedule checked: Festival ended Aug 31
- Next edition: July-August 2026

MOZARTEUM (mozarteum.at):
- Season opener: Sep 25 (not during travel dates)
- No concerts Sep 20-22

MIRABELL PALACE CONCERTS:
- Daily chamber music at 20:00, €35-45
- Available Sep 20-22

Conclusion: Only Mirabell concerts available; major festivals ended
```

#### 3.3 Route-Based Opportunity Scan

For journeys involving driving routes, research what's available ALONG the route:
- Cities and towns on or near the driving route
- Attractions that can be visited as stopovers
- Events or performances in route cities

**Output Format**:
```
Munich → Neuschwanstein → Innsbruck Route (Sep 20-22):

ON ROUTE:
- Füssen (2 hr from Munich): Neuschwanstein Castle, no special events
- Garmisch-Partenkirchen (1.5 hr from Munich): Alpine town, cable cars operating
- Oberammergau (detour): Wood carving shops, Passion Play museum

DESTINATION (Innsbruck):
- Old Town walkable (Golden Roof, Hofkirche)
- Tyrolean State Theatre: Schedule check required
- Nordkette cable car: Open daily
- Swarovski Crystal Worlds: Open daily

OPPORTUNITIES IDENTIFIED:
1. Oktoberfest on Sep 20-21 (Munich)
2. Neuschwanstein Castle (Sep 21 morning)
3. Innsbruck Old Town + Nordkette (Sep 22)
```

#### 3.4 Opportunity Integration Requirement

**Critical Rule**: The Opportunity Discovery stage must produce either:
1. A list of specific events/performances to consider attending, OR
2. Explicit documentation that no relevant opportunities exist

Never produce an empty opportunity section. If research finds nothing, document what was searched and the negative result.

---

### Stage 4: Competitive Scarcity Assessment

**Objective**: Quantify availability, don't assume it

#### 3.1 Accommodation Availability Scan

**Method**: Search booking platforms with exact guest configuration
- Dates: Exact check-in and check-out
- Guests: Exact number of adults and children with ages
- Room type: Must accommodate all guests (NOT multiple rooms unless acceptable)

**Output Format**:
```
Munich, Sep 20-22, 2025, 2 adults + 2 children (ages 11, 6):

Search performed: booking.com, Aug 15, 2025
Results: 18 properties found
Price range: €380 (Ibis Styles München Ost) to €650 (Hilton Munich City)
Family room availability: 12 of 18 properties
Free cancellation: 6 of 18 properties

Availability status: SCARCE (normal period: 350+ properties)
Scarcity level: 95% sold out
```

#### 3.2 Peak Season Booking Timeline

Different destinations have different "book by" timelines:
- New Year's: 3-6 months advance (book by July-October)
- Easter: 2-3 months advance
- Summer school holidays: 3-4 months advance
- Random weekdays: 1-7 days advance acceptable

**Output Format**:
```
Current booking deadline status (Dec 29 for Jan 1 stay):
- New Year's typical booking deadline: 3 months ago (October 1)
- We are: 3 days before check-in
- Implication: Booking extremely late, expect 80-95% sold out
```

#### 3.3 Attraction Advance Booking Requirements

Post-pandemic, many attractions require timed-entry booking:
- Some attractions: Book 1-2 weeks minimum
- Popular attractions: Book 4-6 weeks
- Sold-out attractions: No walk-up possible

**Output Format**:
```
Reichstag Dome, Berlin:
- Booking required: Yes (timed entry)
- Booking opens: 2-4 weeks advance
- Walk-up available: No
- Jan 15 visit, booking Dec 29: Likely available
- Booking URL: bundestag.de/en/visittheBundestag
```

---

### Stage 5: Physical & Logistical Boundaries

**Objective**: Document non-negotiable physical limits

#### 4.1 Realistic Journey Times

**Never use map estimates alone**. Account for:
- Peak hour traffic (2x normal time)
- Border crossings (even Schengen can have delays)
- Parking time (15-30 min in cities)
- Mountain roads (half of map speed)
- Rest stops (every 2 hours with children)

**Output Format**:
```
Munich to Füssen:
- Map distance: 130 km
- Map time: 1hr 45min (A96/B17, no traffic)
- Real-world time: 2-2.5 hours
  - Normal traffic: 1hr 50min
  - Rest stop (children): +15 min
  - Füssen parking: +10 min
  - Total: 2hr 15min
- Must depart by: 07:00 for 09:15 Neuschwanstein ticket
```

#### 4.2 Transport Availability at Actual Times

Transport options vary dramatically by time:
- Late night (after 23:00): No public transport, taxi only
- Early morning (before 06:00): Limited public transport
- Public holidays: Sunday schedules
- Remote areas: Infrequent buses (every 2-4 hours)

**Output Format**:
```
Airport to city centre, 23:30 arrival:
- S-Bahn: Last train 23:10 → NO LONGER RUNNING
- Bus: Night bus every 30 min → Available but 60 min journey
- Taxi: Always available → €40-50, 25 min
- Recommendation: Taxi only realistic option
```

#### 4.3 Accommodation Capacity Constraints

**Family Room Reality**: Many hotels have 1-2 family rooms maximum
- Standard rooms: King bed or 2 singles (max 2-3 guests)
- Family rooms: Rare, book early
- Connecting rooms: More common but 2x price

**Output Format**:
```
Sofitel Munich Bayerpost:
- Total rooms: 396
- Family rooms: 15 (4% of inventory)
- Standard rooms: Max 3 guests (2 adults + 1 child up to age 12)
- For 2 adults + 2 children (ages 6, 11): Need family room OR connecting rooms
- Family room availability Sep 20: Check required
```

#### 4.4 Traveller Stamina Limitations

**Children Activity Limits** (observed patterns):
- Age 0-3: 45-60 min activity, 2-3 hour naps
- Age 4-7: 1-1.5 hour activity, 1 hour rest
- Age 8-12: 1.5-2 hour activity, 30-60 min rest
- Walking: 2-3 km max before fatigue

**Output Format**:
```
Alice (11) and Zoe (6) stamina profile:
- Maximum activity duration: 1.5-2 hours
- Rest required between activities: 30-60 minutes
- Daily outings: 2 outings realistic, 3 pushing limits
- Walking distance: 2 km before complaints begin
- Museum saturation: 60-90 minutes before engagement drops
- Outdoor activity: Requires toilet access every 2-3 hours
```

---

### Stage 6: Geographic Constraint Mapping

**Objective**: Understand actual spatial relationships and accessibility

#### 5.1 Cluster Identification

**Method**: Research regional travel patterns
- What destinations are typically visited together?
- Are they actually accessible from each other?
- Is there shared transport infrastructure?

**Output Format**:
```
Munich Regional Cluster:
- Munich (hub)
- Augsburg (70 km, 45 min drive, 30 min ICE)
- Füssen/Neuschwanstein (130 km, 2 hr drive, 2hr train+bus)
- Starnberg (30 km, 40 min S-Bahn)
- Garmisch-Partenkirchen (90 km, 1.5 hr drive, 1hr 20min train)

Cluster characteristics:
- All connected by A96/A95 motorways
- S-Bahn covers nearby destinations
- Bavaria only (no border crossings)
```

#### 5.2 Transport Mode Feasibility

**Car vs Train vs Bus Reality Check**:

For each cluster connection, assess:
- Does public transport exist?
- How frequent?
- Does it operate on your travel dates/times?
- Cost for family vs car rental
- Luggage handling practicality

**Output Format**:
```
Munich to Füssen:

Car:
- Distance: 130 km
- Time: 2 hr
- Cost: Fuel €15 (no vignette needed, domestic)
- Luggage: No limit
- Schedule: Depart anytime
- Feasibility: ✅ FULLY FEASIBLE

Train:
- Connection: Munich Hbf → Buchloe → Füssen
- Time: 2 hours
- Frequency: Hourly
- Luggage: Manageable with one transfer
- Feasibility: ✅ FULLY FEASIBLE

Bus:
- Connection: Flixbus available
- Feasibility: ⚠️ MARGINAL (infrequent, 2.5 hours)
```

#### 5.3 Cross-Cluster Travel Costs

**Time, Money, and Energy**:

Quantify the cost of moving between clusters:
- Travel time (reduces activity time)
- Financial cost
- Energy/fatigue (especially with children)

**Output Format**:
```
Cost Analysis: Staying in Munich Centre vs Starnberg

If staying Munich Centre:
- Sep 22 departure: Walk to Theresienwiese for morning at Wiesn
- Children in transport: None (walking distance)
- Morning activity window: 09:00-12:00 (3 hours at Wiesn)
- Hotel checkout: 11:00 rush checkout during festival chaos

If staying Starnberg (30 km from Munich):
- Sep 22 departure: 40min S-Bahn to Munich
- Children in transport: 40min = acceptable
- Morning activity window: 08:00-11:00 (3 hours at lake + travel)
- Hotel checkout: 11:00 relaxed, lakeside breakfast option

Trade-off: Starnberg offers calm mornings but adds 80min round-trip commute
```

---

### Stage 7: Economic Reality Check

**Objective**: Document actual costs, not estimates or wishes

#### 6.1 Peak Pricing Multipliers

Accommodation prices vary dramatically by:
- Season (summer +50-100%, winter -20-30%, shoulder normal)
- Day of week (Friday/Saturday +30-50%)
- Special events (New Year's +200-400%, conferences +50-150%)

**Output Format**:
```
Munich hotel pricing:

Normal period (random Tuesday in November):
- Budget: €80-100
- Mid-range: €100-150
- Upscale: €150-250

Oktoberfest (Sep 20, 2025):
- Budget: €280-350 (+250%)
- Mid-range: €350-500 (+250%)
- Upscale: €500-800 (+220%)

Peak pricing multiplier: 3-5x normal rates
```

#### 6.2 Family Cost Calculations

**Always calculate family totals**, not per-person costs:

Many travel resources quote per-person:
- "Train ticket €15" → Family of 4 = €60 (or less with children's discounts)
- "Museum €12" → Check if children free or reduced

**Output Format**:
```
Deutsches Museum Munich:
- Adult: €15
- Children 6-17: €8
- Family of 4 (2 adults + 2 children): €46 total

Neuschwanstein Castle:
- Adult: €15
- Children under 18: FREE
- Family of 4: €30 total (2 adult tickets only)
```

#### 6.3 Hidden Costs

Don't forget:
- Parking: €20-40/day in city centres
- Vignettes: Austria €10, Hungary €15, Switzerland €40
- Tourist taxes: €2-5/person/night
- Resort fees: €10-30/night (some hotels)
- Checked baggage: €15-50/bag/flight

**Output Format**:
```
Car rental Munich-Füssen road trip:

Visible cost:
- Car rental: €85 (2 days)
- Fuel: €35 (300 km)
- Subtotal: €120

Hidden costs:
- No vignette needed (domestic)
- Füssen parking: €10/day
- Neuschwanstein shuttle: €3/person
- Subtotal hidden: €22

Total real cost: €142 (not €120)
```

---

### Stage 8: Synthesis - Feasibility Matrix and Opportunity Integration

**Objective**: Organize constraint findings AND discovered opportunities to inform strategy recommendations

**Critical Clarification**: This stage produces INPUTS for itinerary creation, not a final document. The itinerary SOP (`sop-itinerary-management.md`) requires definitive recommendations with reasoning—TWINYO provides the evidence base for those recommendations.

#### 8.1 Feasibility Matrix Template

For each option being considered, document pass/fail for each constraint category:

| Option | Temporal | Operating | Available | Physical | Geographic | Economic | Opportunities | Overall Status |
|--------|----------|-----------|-----------|----------|------------|----------|---------------|----------------|
| | ✅/⚠️/❌ | ✅/⚠️/❌ | ✅/⚠️/❌ | ✅/⚠️/❌ | ✅/⚠️/❌ | ✅/⚠️/❌ | 🎭/🎪/❌ | FEASIBLE / MARGINAL / BLOCKED |

Legend:
- ✅ = Passes constraint cleanly
- ⚠️ = Marginal (possible but with significant drawbacks)
- ❌ = Fails constraint (blocker)
- 🎭 = Unique opportunity available (concert, festival, special event)
- 🎪 = Seasonal attraction available (market, fair, seasonal venue)

#### 8.2 Constraint and Opportunity Summary Document

Before the itinerary SOP can make recommendations, TWINYO produces this summary:

```markdown
## TWINYO Analysis: [Journey Name]

### Temporal Constraints
- Travel dates: [dates with day-of-week]
- Season: [season], sunset [time]
- Holiday period: [Yes/No + which holiday]
- Effective activity hours: [X hours/day for this traveller composition]

### Operating Schedule (Date-Specific)
[List key attractions/transport with actual operating status on travel dates]

### OPPORTUNITIES DISCOVERED (Critical Section)
[List events, performances, and seasonal attractions found in Stage 3]

**Events and Festivals:**
- [Event name]: [Date/time], [Location], [Relevance to travel group]
  Example: "Oktoberfest: Sep 20 - Oct 5, Theresienwiese Munich, FREE entry, family days Tuesdays with reduced prices"

**Concerts and Performances:**
- [Performance]: [Date/time], [Venue], [Availability/Cost]
  Example: "Slovak Philharmonic New Year Concert: Jan 1 16:00, Reduta, €25-45, tickets available"

**Seasonal Attractions:**
- [Attraction]: [Operating dates], [Relevance]
  Example: "Christmas Market at Riesenradplatz: Until Jan 6, open on Jan 1"

**No Opportunities Found** (if applicable):
- [What was searched and why nothing was found]
  Example: "Győr Ballet: No performances Jan 1-2 (checked gyoribalett.hu)"

### Competitive Scarcity (Verified)
[Actual search results with numbers: X properties, €Y-Z range, availability %]

### Physical Constraints
- Longest journey: [distance, time, who travels]
- Traveller limitations: [specific needs]
- Fixed commitments: [meetings, flights, events with times]

### Geographic Reality
- Cluster map: [what's near what]
- Transport modes: [what exists vs what we wish existed]
- Cross-cluster costs: [time/money/energy to move]

### Economic Reality
- Peak pricing: [multiplier for this period]
- Family costs: [actual totals for family size]
- Hidden costs: [itemized]

### BLOCKERS IDENTIFIED
1. [Specific constraint that eliminates an option entirely]
   Example: "Munich Sep 20: Only 18 hotels available for family of 4 (vs 350+ normal), cheapest €380"

### MARGINAL FEASIBILITY
1. [Options technically possible but with significant drawbacks]
   Example: "Stay in Füssen: Return drive 130km requires 14:00 departure Sep 22, leaving only 4 hours morning activity time"

### CLEAR FEASIBILITY
1. [Options that pass all constraint checks]
   Example: "Stay in Starnberg: €95-130 hotels available, 40min to Munich = 5 hours morning activity time Sep 22"

### RECOMMENDED STRATEGY (for Itinerary SOP)
Based on the above analysis, the recommended approach is:
[Explicit recommendation with reasoning that references constraints AND opportunities]

Example: "Stay in Füssen Sep 21 night. Reasoning: (1) Opportunity: Oktoberfest Sep 20 evening before early departure; (2) Constraint: Munich hotels 3x price during festival; (3) Opportunity: Neuschwanstein Castle sunrise visit Sep 21 before crowds."
```

#### 8.3 Feasibility Matrix Example (Updated with Opportunities)

**Munich Oktoberfest Trip Alternative Plans (Sep 20-22, 2025)**

| Option | Temporal | Operating | Available | Physical | Geographic | Economic | Overall |
|--------|----------|-----------|-----------|----------|------------|----------|---------|
| **Stay Munich Centre** | ✅ Sep 20-22 works | ✅ All attractions open | ❌ 95% sold out, €380+ | ✅ Walking distance to Wiesn | ✅ Central | ❌ 4-5x normal price | **BLOCKED** |
| **Stay Augsburg** | ✅ Sep 20-22 works | ✅ All open | ✅ Good availability €89-120 | ⚠️ 70km = 1hr train each way | ✅ On route | ✅ Normal pricing | **FEASIBLE** |
| **Stay Füssen** | ✅ Sep 20-22 works | ✅ Castle open | ✅ Excellent availability €75-95 | ⚠️ 130km = 2hr drive | ✅ Near Neuschwanstein | ✅ Normal pricing | **FEASIBLE** |
| **Stay Starnberg** | ✅ Sep 20-22 works | ✅ Lake activities | ✅ Good availability €95-130 | ✅ 30km = 40min S-Bahn | ✅ Lake district | ✅ Slight premium | **FEASIBLE** |

**Constraint Details**:

**Munich Centre - BLOCKED**:
- Temporal ✅: Dates work
- Operating ✅: Oktoberfest in full swing, all attractions open
- Available ❌: **95% sold out, only luxury hotels €380+ remain**
- Physical ✅: Walking distance to Theresienwiese
- Geographic ✅: Central location
- Economic ❌: €380-600 hotels (4-5x normal €80-120)
- **Primary Blocker**: Availability (95% sold out)
- **Secondary Blocker**: Economic (extreme pricing)

**Augsburg - FEASIBLE**:
- Temporal ✅: Dates work
- Operating ✅: Historic old town, Fuggerei, all open
- Available ✅: **Good availability, Hotel am Rathaus €89, Steigenberger €120**
- Physical ⚠️: 70km = 1hr train to Munich, last train 23:30
- Geographic ✅: On Munich-Stuttgart rail corridor
- Economic ✅: €89-120 = normal pricing
- **Passes all constraints, minor physical consideration (train commute)**

**Füssen - FEASIBLE**:
- Temporal ✅: Dates work
- Operating ✅: Neuschwanstein open daily 9:00-18:00
- Available ✅: **Excellent availability, Hotel Hirsch €75, Luitpoldpark €95**
- Physical ⚠️: 130km = 2hr drive, requires car rental
- Geographic ✅: Gateway to Neuschwanstein Castle
- Economic ✅: €75-95 = normal pricing
- **Passes all constraints, enables castle day trip**

**Starnberg - FEASIBLE**:
- Temporal ✅: Dates work
- Operating ✅: Lake cruises running, Berg chapel open
- Available ✅: Good availability, Seehotel Leoni €95, Marina €130
- Physical ✅: 30km = 40min S-Bahn S6, frequent service
- Geographic ✅: Lake Starnberg district, scenic
- Economic ✅: €95-130 = slight premium but reasonable
- **Passes all constraints cleanly, best balance of proximity and pricing**

---

## Output Document Structure

The TWINYO analysis output follows this structure. Save to Dropbox using `DROPBOX_CREATE_PAPER` at `[journey-folder]/build/research/[journey-start-date]-[destination]-twinyo.paper`.

```markdown
# [Destination] TWINYO Analysis

**Journey**: [Start Date] - [End Date]
**Travellers**: [Composition - e.g., 2 adults, 2 children (6, 11)]
**Cluster Research**: [Link to build/research/[destination]-cluster.md]
**Analysis Date**: [When this TWINYO was performed]

---

## Stage 1-2: Temporal and Operating Constraints

### Date-Mapped Operating Schedule

**Table Format Requirements**:

- Column headers MUST be actual travel dates, not days of week
- Format: `Dec 31 (Wed)` — date first, day-of-week in parentheses as annotation
- Include ONLY columns for actual travel dates (no irrelevant days — if no travel date falls on Tuesday, no Tuesday column)
- This table is the transformed output of day-of-week patterns mapped to specific dates
- Place this table AFTER the "Travel Dates Mapped" list, so the date-to-day mapping is established before the table uses it

| Attraction | Dec 31 (Wed) | Jan 1 (Thu) | Jan 2 (Fri) | Jan 3 (Sat) | Source |
|------------|--------------|-------------|-------------|-------------|--------|
| Natural History Museum | 10:00-18:00 | CLOSED | 10:00-18:00 | 10:00-18:00 | nhm-wien.ac.at verified Dec 29 |
| Schönbrunn Palace | 08:30-17:00 | CLOSED | 08:30-17:00 | 08:30-17:00 | schoenbrunn.at verified Dec 29 |

### Daylight Constraints

- Sunrise: [time]
- Sunset: [time]
- Civil twilight ends: [time]
- Useful outdoor hours: [range]

---

## Stage 3: Opportunities Discovered

### Events ON Travel Dates

**[Event Name]**
- Date/Time: [Specific date and time]
- Location: [Where]
- Cost: [Price or FREE]
- Child-friendly: [Yes/No/Notes]
- Source: [URL, verified date]

### Concerts/Performances

[List each with venue, date, time, ticket availability]
OR "None found - searched [list venues and event calendars checked]"

### Seasonal Attractions

[Christmas markets, winter wonderlands, special exhibitions still running]
OR "None found - [what was checked]"

---

## Stage 4: Availability Verification

### Accommodation Search Results

**[City], [Date] (family of 4)**
- Search performed: [Platform], [Date of search]
- Total results: [N] properties found
- Price range: €[X] - €[Y]
- Availability status: [SCARCE/MODERATE/GOOD]
- IHG options: [List or "None available"]
- Marriott options: [List or "None available"]
- Recommended: [Hotel] - [Reasoning]

---

## Stages 5-7: Physical, Geographic, Economic Constraints

### Physical Constraints

[Traveller capabilities affecting planning]

### Geographic/Routing Constraints

[Key distances, travel times, route considerations]

### Economic Constraints

[Budget limits, price anomalies noted]

---

## Stage 8: Synthesis

### Feasibility Matrix

| Option | Constraints Summary | Opportunities | Availability | Overall |
|--------|---------------------|---------------|--------------|---------|
| [A]    | [brief summary]     | [events/shows]| [status]     | FEASIBLE/MARGINAL/BLOCKED |

### Recommended Strategy

**Recommendation**: [Clear statement of what the itinerary SOP should adopt]

**Reasoning**:
1. [Constraint-based reason - what this avoids]
2. [Opportunity-based reason - what this enables]
3. [Practical reason - logistics, cost, comfort]

**For Itinerary SOP**: Build day-by-day plan around these anchors:
- [Key anchor 1 - e.g., "Oktoberfest Sep 20 evening, Augustiner tent reservation 18:00"]
- [Key anchor 2 - e.g., "Neuschwanstein Castle Sep 21 morning, 09:00 ticket"]
- [Key anchor 3 - e.g., "Return to Munich airport by 16:00 Sep 22"]
```

---

## Integration with Itinerary Planning

### Relationship to `sop-itinerary-management.md`

TWINYO is a **pre-planning methodology** referenced by the itinerary management SOP. The relationship is:

1. **TWINYO produces**: Constraint analysis, opportunity inventory, feasibility matrix, and recommended strategy
2. **Itinerary SOP consumes**: TWINYO outputs to make definitive recommendations with full reasoning
3. **Final output**: The itinerary SOP produces the actionable travel document

**Critical**: TWINYO does NOT replace the itinerary SOP's requirement for explicit recommendations. TWINYO provides the EVIDENCE; the itinerary provides the RECOMMENDATIONS.

### When to Use TWINYO

Execute TWINYO methodology **before** itinerary creation in these scenarios:
- Peak travel periods (holidays, summer, festivals)
- Travel with constraints (children, elderly, accessibility needs)
- Limited time windows (weekend trips, day trips)
- Multiple destination evaluation (which city to visit?)
- Complex logistics (multiple transport modes, hotel changes)
- **New Year's, Christmas, or other periods with significant closures and special events**

### When TWINYO Is Overkill

Skip or simplify for:
- Simple round-trip travel (origin → destination → origin)
- Flexible dates in low season
- No special needs or constraints
- Single destination with abundant accommodation
- Standard adult travel with no time pressures

### Output Usage

The TWINYO analysis provides the itinerary SOP with:
1. **Verified constraints** - what's actually closed, sold out, or impractical
2. **Discovered opportunities** - what events, concerts, and seasonal attractions are available
3. **Feasibility assessment** - which options pass constraint checks
4. **Recommended strategy** - explicit recommendation with reasoning for the itinerary to adopt

The itinerary SOP then:
1. Adopts the TWINYO recommendation (or documents why an alternative was chosen)
2. Builds detailed day-by-day plans incorporating discovered opportunities
3. Provides booking guidance, transport details, and practical logistics
4. Produces the final traveller-facing document

**The constraint AND opportunity summary provides the evidence base for itinerary recommendations. Strategies should exploit discovered opportunities while respecting documented constraints.**

---

## Documentation Standards

### Date Specificity
❌ "Museum closed Mondays"  
✅ "Dec 29 (Monday) - Museum CLOSED"

### Availability Facts
❌ "Hotels available"  
✅ "23 properties found for family of 4, €285-556, 11 with free cancellation"

### Real-World Times
❌ "2 hour drive"  
✅ "243km, 2hr 38min map time → 3hr 15min real (traffic + parking + rest stop with children)"

### Constraint Language
❌ "Might be difficult"  
✅ "BLOCKED: Only 2 hotels have family rooms, both sold out"

### Cost Transparency
❌ "€100 per day"  
✅ "€100 visible + €35 hidden (parking €25, tourist tax €10) = €135 total"

---

## Success Criteria

TWINYO methodology has succeeded when:

1. ✅ **Constraints AND opportunities examined** - both what's blocked AND what's uniquely available
2. ✅ **Specific blockers documented** - "X is not feasible because [specific constraint]"
3. ✅ **Opportunities actively discovered** - events, concerts, festivals researched with specific findings
4. ✅ **Assumptions verified** - opening hours checked, availability searched, distances measured
5. ✅ **Date-specific information** - "Jan 1 (Thursday) Museum CLOSED" not "closed holidays"
6. ✅ **Real-world numbers** - "23 hotels found, €285-556" not "accommodation available"
7. ✅ **Family-total costs** - "€36 family" not "€18 per person"
8. ✅ **Explicit strategy recommendation** - clear recommendation with reasoning for itinerary SOP to adopt
9. ✅ **No minimalist avoidance** - plan exploits opportunities rather than avoiding constraints by avoiding activities

**TWINYO has FAILED if:**
- ❌ The output is a sparse plan that avoids constraints by doing nothing
- ❌ Major events/festivals during travel dates are not mentioned
- ❌ The analysis lists only closures without researching what IS open/available
- ❌ No explicit recommendation is provided for the itinerary SOP

---

## Example Application

See: `travel/examples/twinyo-munich-example.md` for worked example applying this methodology to Munich Oktoberfest Sep 20-22 alternative plans.

---

*Methodology created in response to repeated travel planning failures caused by:*
1. *Ignoring real-world constraints (v1.0)*
2. *Producing minimalist plans that avoid constraints by avoiding activities (v2.0 - addresses this)*




