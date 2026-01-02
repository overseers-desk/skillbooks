# Travel Management Master SOP

## Purpose

This is the master orchestrator for travel planning. It defines interfaces between sub-SOPs and coordinates their execution to produce complete travel documentation.

## Sub-SOP Registry

| SOP | Purpose | Input | Output |
|-----|---------|-------|--------|
| `sop-booking-extraction.md` | Parse PDFs from Fares/Accommodations/Passes | Journey folder path | `build/extraction/*.yaml` |
| `sop-cluster-research.md` | Research geographic cluster, attractions, suitability | City name, dates, traveller composition | `build/research/{city}-cluster.md` |
| `sop-twinyo.md` | Date-specific constraint analysis and opportunity discovery | Journey folder + cluster research | `build/research/{journey}-twinyo.md` |
| `sop-itinerary-management.md` | Assemble research into a destination-level itinerary | All build/ artifacts | `[Itinerary-File].md` |
| `sop-mental-journey-simulation.md` | Test itinerary via narrative walkthrough | `[Itinerary-File].md`, segment | `build/test/{N}.{Segment}.md` |

## Build Directory Structure

All generated intermediate files reside in `build/` within the journey folder:

```
[Journey Folder]/
├── Fares/                           # Source: transport booking PDFs
├── Accommodations/                  # Source: hotel booking PDFs
├── Passes/                          # Source: event tickets, passes
│
├── build/
│   ├── extraction/                  # From sop-booking-extraction
│   │   ├── transport-segments.yaml  # All inter-city transport
│   │   ├── traveller-composition.yaml
│   │   ├── 1.Edinburgh.yaml         # Per-city booking details
│   │   ├── 2.Berlin.yaml
│   │   └── ...
│   │
│   ├── research/                    # From sop-cluster-research and sop-twinyo
│   │   ├── edinburgh-cluster.md     # Cluster research for Edinburgh segment
│   │   ├── berlin-cluster.md
│   │   ├── 2025-12-23-edinburgh-twinyo.md  # TWINYO analysis for complex scenarios
│   │   └── ...
│   │
│   └── test/                        # From sop-mental-journey-simulation
│       ├── 1.Edinburgh.md           # Simulation for segment 1
│       ├── 2.Berlin.md              # Simulation for segment 2
│       └── ...
│
└── [Start Date] - [End Date] [Destination]_Itinerary.md  # Final deliverable
```

### Itinerary Naming Convention

The Master SOP identifies segments or "clusters" within a journey (e.g., a 2-week trip might have 3 destination clusters). Each cluster receives its own itinerary file named:
`[YYYY-MM-DD] - [YYYY-MM-DD] [Cluster-Name]_Itinerary.md`

This prevents a single massive document for complex multi-country journeys and allows focused planning for each segment.

### Sequence Numbering Convention

City files are prefixed with sequence numbers reflecting travel order:
- `1.Edinburgh` = first destination
- `2.Berlin` = second destination
- etc.

This ensures `ls` output matches journey chronology.

---

## Interface Definitions

### Interface: Booking Extraction Output

**File**: `build/extraction/{N}.{City}.yaml`

```yaml
city: "Berlin"
sequence: 2
dates:
  arrival: "2025-12-26"
  departure: "2025-12-29"
  nights: ["2025-12-26", "2025-12-27", "2025-12-28"]

inbound_transport:
  type: "flight"
  from: "Edinburgh"
  departure_time: "08:15"
  arrival_time: "11:05"
  carrier: "Ryanair"
  flight_number: "FR1234"
  booking_ref: "ABC123"
  passengers: ["Weiwu", "Liansu", "Alice", "Zoe"]

outbound_transport:
  type: "train"
  to: "Munich"
  departure_time: "09:30"
  arrival_time: "13:45"
  carrier: "DB"
  booking_ref: "XYZ789"
  passengers: ["Weiwu", "Liansu", "Alice", "Zoe"]

accommodation:
  hotel_name: "Hotel Indigo Berlin - Alexanderplatz"
  address: "Bernhard-Weiss-Straße 5, 10178 Berlin"
  check_in: "2025-12-26"
  check_out: "2025-12-29"
  booking_ref: "IHG123456"
  room_type: "Family Suite"

events:
  - name: "Reichstag Dome Visit"
    date: "2025-12-27"
    time: "14:00"
    booking_ref: "DOME789"
```

**File**: `build/extraction/transport-segments.yaml`

```yaml
segments:
  - sequence: 1
    from_city: "Edinburgh"
    to_city: "Berlin"
    date: "2025-12-26"
    departure_time: "08:15"
    arrival_time: "11:05"
    type: "flight"
    carrier: "Ryanair"
    booking_ref: "ABC123"

  - sequence: 2
    from_city: "Berlin"
    to_city: "Munich"
    date: "2025-12-29"
    departure_time: "09:30"
    arrival_time: "13:45"
    type: "train"
    carrier: "DB"
    booking_ref: "XYZ789"
```

**File**: `build/extraction/traveller-composition.yaml`

```yaml
travellers:
  adults:
    - name: "Weiwu"
      notes: "IHG Platinum member"
    - name: "Liansu"
  children:
    - name: "Alice"
      age_approx: 8
    - name: "Zoe"
      age_approx: 5

segments:
  - cities: ["Edinburgh", "Berlin", "Munich"]
    travellers: ["Weiwu", "Liansu", "Alice", "Zoe"]
  - cities: ["Vienna", "Warsaw"]
    travellers: ["Weiwu", "Liansu"]
    notes: "Children return home after Munich"
```

---

### Interface: Cluster Research Output

**File**: `build/research/{city}-cluster.md`

Each cluster research file contains ALL research for that city segment in a single document:

```markdown
# {City} Research - {dates}

## Seasonal Context

- **Travel dates**: December 26-29, 2025
- **Season**: Winter
- **Sunrise/Sunset**: 08:15 / 15:52
- **Weather**: Cold, potential snow, -2°C to 5°C typical
- **Daylight constraint**: Outdoor activities must finish by 15:30

## Events and Festivals

### Christmas Markets
- **Alexanderplatz market**: Nov 24 - Dec 30, open daily 10:00-22:00
- **Gendarmenmarkt market**: CLOSED (ends Dec 23)

### Holiday Closures
- **December 26 (Boxing Day)**: Most museums OPEN (public holiday but attractions operate)
- **Weekly closures**: Most museums closed Mondays - N/A for Dec 26-29 (Thu-Sun)

## Transport Strategy

**Car rental decision**: Not recommended

**Reasoning**: Berlin has excellent public transport (U-Bahn, S-Bahn, buses).
Parking expensive (€20-30/day), city centre pedestrian zones extensive.
All planned activity clusters accessible within 20 minutes by metro.

**Airport-to-hotel transport**:
- FEX train: €3.80/adult, children under 6 free. Family total: €7.60
- Taxi: €45-55 flat rate
- **Recommendation**: FEX train. Hotel is 3-min walk from Alexanderplatz station.

## Activity Clusters

### Cluster 1: Alexanderplatz Area (near hotel)
- TV Tower (Fernsehturm): €24.50 adult, €14.50 child 4-16
- Alexanderplatz Christmas Market
- Walking distance from hotel

### Cluster 2: Museum Island
- Pergamon Museum: PARTIALLY CLOSED for renovation
- Neues Museum: €14 adult, free under 18
- 10-min S-Bahn from Alexanderplatz

### Cluster 3: West Berlin
- Zoo Berlin: €18 adult, €9 child 4-15
- KaDeWe department store
- 20-min U-Bahn from hotel

## Accommodation Strategy

**Recommended**: Hotel Indigo Berlin - Alexanderplatz (IHG)
- 3-min walk to Alexanderplatz S-Bahn/U-Bahn
- IHG property: Platinum upgrade potential
- Near Christmas market and TV Tower

**Alternative**: InterContinental Berlin
- More upscale, further from Alexanderplatz (15-min walk)
- Higher upgrade potential but less convenient location

## Day-by-Day Recommendations

### December 26 (Thursday) - Arrival Day
- Flight arrives 11:05
- Afternoon arrival at hotel (~12:30)
- **Afternoon options**: Alexanderplatz market, TV Tower (if pre-booked)
- Light first day after travel

### December 27 (Friday) - Full Day
- **Morning**: Museum Island cluster
- **Afternoon**: Return to hotel for rest, then Alexanderplatz area
- Sunset 15:52 - indoor afternoon preferred

### December 28 (Saturday) - Full Day
- **Morning**: Zoo Berlin (if children interested) OR LEGOLAND Discovery
- **Afternoon**: Flexible - market revisit or hotel rest

### December 29 (Sunday) - Departure Day
- Train departs 09:30
- Minimal morning activities
- Checkout and proceed to Hauptbahnhof

## Booking Requirements

| Activity | Booking Required | URL | Lead Time |
|----------|------------------|-----|-----------|
| Reichstag Dome | Yes | bundestag.de | 2-4 weeks |
| TV Tower | Recommended | tv-turm.de | 1-2 days |
| Zoo Berlin | No | Walk-up OK | - |

## Cost Summary

**Transport**:
- Day ticket (AB zone): €9.50/adult, children 6-14 €3.50, under 6 free
- Family of 4 daily: ~€22

**Attractions**:
- TV Tower family: ~€78
- Zoo family: ~€54
- Museums: Free for children under 18

**Estimated 3-day total**: €300-450 (transport + attractions, excl. food)
```

---

### Interface: Test Output

**File**: `build/test/{N}.{Segment}.md`

Each segment gets its own simulation file, matching the research convention. See `sop-mental-journey-simulation.md` for full specification. Summary:

```markdown
# Journey Simulation: [Segment] - [dates]

**Travellers**: [composition]
**Dates**: [segment dates]
**Verdict**: GREEN / YELLOW / RED

## Day-by-Day Narrative
[Story-format walkthrough with [CRITICAL], [SIGNIFICANT], [MINOR], [VERIFY], [ENERGY] markers]

## Issues Summary

### Critical
1. [Issue] - [Day] - **Fix**: [recommendation]

### Significant
...

### Minor
...

### Verify
...

### Energy
...
```

---

## Orchestration: RUN Workflow

### Prerequisites

1. Journey folder exists with organized Fares/Accommodations/Passes
2. Folder management SOP has been run (files properly named)

### Incremental Execution Strategy

Sub-SOPs should only re-run when source data has changed.

#### Extraction Phase Caching

Before running `sop-booking-extraction.md`, check if extraction is current:

```bash
# Get newest source file modification time
NEWEST_SOURCE=$(find Fares/ Accommodations/ Passes/ -type f -name "*.pdf" -printf '%T@\n' 2>/dev/null | sort -n | tail -1)

# Get oldest extraction output modification time
OLDEST_EXTRACTION=$(find build/extraction/ -type f -printf '%T@\n' 2>/dev/null | sort -n | head -1)

# If no extraction exists, or source is newer than extraction, re-run
if [ -z "$OLDEST_EXTRACTION" ] || [ "$NEWEST_SOURCE" -gt "$OLDEST_EXTRACTION" ]; then
    # Run extraction
fi
```

**Decision logic**:
- If `build/extraction/` does not exist → run extraction
- If any PDF in Fares/Accommodations/Passes is newer than oldest file in `build/extraction/` → re-run extraction
- Otherwise → skip extraction, use cached results

#### Research Phase Caching

Research files depend on:
1. Corresponding extraction file
2. Travel dates (for seasonal research)

**Decision logic**:
- If `build/research/{city}-cluster.md` does not exist → run research
- If `build/extraction/{N}.{City}.yaml` is newer than research file → re-run research
- Otherwise → skip research, use cached results

#### Test Phase

Re-run for a segment after its portion of Itinerary.md changes.

---

### RUN Execution Steps

```
RUN: Travel Management

1. **Access Data: Examine Online Travel Folder**
   - Parse journey name from user request.
   - Follow `sop-travel-folder-access.md` for access instructions.
   - Verify journey folder exists within `0. Travel Admin/` in the "online" storage.

2. CHECK extraction freshness
   - Compare source PDF timestamps vs build/extraction/ timestamps
   - If stale or missing:
     → Run: sop-booking-extraction.md
     → Creates: build/extraction/*.yaml
   - Else: Skip, use existing extraction

3. IDENTIFY city sequence
   - Read build/extraction/transport-segments.yaml
   - Determine ordered list of cities: [Edinburgh, Berlin, Munich, ...]

4. FOR EACH city (can run in parallel):
   - Check if build/research/{city}-cluster.md exists and is fresh
   - If stale or missing:
     → Run: sop-cluster-research.md for {City}
     → Input: extraction data, dates, traveller composition
     → Creates: build/research/{city}-cluster.md

5. TWINYO ANALYSIS (when required)
   - Check if complex scenario (peak travel, constraints, multiple options)
   - If TWINYO required:
     → Run: sop-twinyo.md
     → Input: journey folder + build/research/{city}-cluster.md
     → Creates: build/research/{journey-start-date}-{city}-twinyo.md
   - Skip for simple journeys with abundant availability

6. ASSEMBLE itinerary
   → Run: sop-itinerary-management.md
   → Input: all build/extraction/*.yaml + build/research/*.md (including TWINYO if exists)
   → Creates/Updates: `[YYYY-MM-DD] - [YYYY-MM-DD] [Cluster-Name]_Itinerary.md`

7. TEST (can run in parallel per segment)
   → Run: sop-mental-journey-simulation.md for each segment
   → Input: Cluster itinerary file, segment
   → Creates: build/test/{N}.{Segment}.md

8. IF test verdict is RED:
   - Review critical issues
   - Update the cluster itinerary to address issues
   - Re-run test (step 7) for affected segments
   - Repeat until GREEN or YELLOW with acceptable issues

9. QUALITY CONTROL
   - Run 10-item QC checklist from sop-itinerary-management.md
   - Iterate until all items PASS
```

---

### Invocation Examples

**Full RUN**:
```bash
claude -p "Follow travel/sop-travel-master.md for journey '2025-12-23 Edinburgh, Berlin, Munich, Vienna, Warsaw - Liansu, Weiwu, A-Z'"
```

**Research only for one city**:
```bash
claude -p "Follow travel/sop-cluster-research.md for Berlin, Dec 26-29 2025, family with 2 children. Save to build/research/berlin-cluster.md" \
  --allowedTools "WebSearch,WebFetch,Read,Write"
```

**Extraction only**:
```bash
claude -p "Follow travel/sop-booking-extraction.md for journey folder '2025-12-23 Edinburgh...'" \
  --allowedTools "Bash,Read,Write,Glob"
```

---

## Appendix: Journey Folder Location

See `sop-travel-folder-access.md` for how to access travel folders. That SOP defines:

- Access methods (MCP preferred, filesystem mount fallback)
- Folder location within cloud storage
- Error handling when access fails

Journey folder naming convention: `YYYY-MM-DD [Destination(s)] - [Travellers]`

Examples:

- `2025-12-23 Edinburgh, Berlin, Munich, Vienna, Warsaw - Liansu, Weiwu, A-Z`
- `2025-11-29 Venice - Liansu, Weiwu, A-Z`

---

**End of Master SOP**
