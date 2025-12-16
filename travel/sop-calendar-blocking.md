# Travel Calendar Blocking Standard Operating Procedure

## Purpose Statement

This Standard Operating Procedure establishes the methodology for calculating calendar blocks for travel periods when the traveler is unavailable for meetings or work commitments. The SOP accounts for flight times, airport transfers, hotel check-in procedures, and layover availability rules to generate accurate time blocks that reflect real-world travel constraints.

## Scope

This SOP applies to calendar blocking calculations for air travel documented in journey folders within the Dropbox "Travel Admin" structure.

**Important Boundaries:**

- For journey planning and itinerary creation, see Travel Itinerary Management SOP
- For file organization and email synchronization, see Travel Admin Folder Management SOP

## Prerequisites

- Journey folder exists with properly organized Fares subfolder
- Flight booking PDFs present in Fares subfolder
- PDF text extraction capability (`pdftotext`)
- Current date awareness to filter past travel
- Web search access for airport distance calculations

## Layover Availability Rule

**Threshold: 5 hours**

- **Layover ≥ 5 hours**: Traveler available for lounge work. Split calendar block into two segments with gap representing availability.
- **Layover < 5 hours**: Traveler unavailable. Create continuous block covering entire journey.

**Rationale**: Layovers under 5 hours involve too much movement (deplaning, finding lounge, security dynamics, boarding) to sustain productive work.

## Procedure: Generate Calendar Blocks for Remaining Travel

### Input

Journey folder path (absolute or relative to `~/Dropbox/0. Travel Admin/`)

### Output

Structured calendar block specifications:
- Start/end datetimes (timezone-aware)
- Purpose and flight segments
- Layover handling notes

### Steps

1. **Locate All Flight Bookings**
   - Navigate to Fares subfolder
   - List all PDFs excluding "(Cancelled)" prefix
   - **Do NOT filter by filename date** - return tickets have outbound date in filename but contain future return flights

2. **Extract Flight Details and Filter by Actual Flight Dates**
   - Use `pdftotext` on each PDF
   - Parse ALL flight segments in each booking:
     - Flight numbers, airport codes, departure/arrival times **with full dates**, durations
     - **Return/round-trip bookings**: Extract BOTH outbound AND return segments - these are in the same PDF
   - **Filter by actual flight date**: For each flight segment, check if segment date < current date
     - Skip past segments
     - Keep future segments (even if from a booking file with past outbound date)
   - Identify multi-segment journeys (connecting flights within same direction of travel)

3. **Determine Airport-to-City Distances**
   - **Only for origin and final destination airports** - NOT for connection airports where traveler stays airside
   - For each relevant airport code: web search `[code] airport to city center distance`
   - Extract distance in kilometers
   - If ambiguous: use 25km conservative estimate
   - **Skip distance lookup for connection airports** when layover < 5h (traveler remains in airport)

4. **Calculate Travel Buffers**

   **Pre-departure:**
   - Domestic: 2h before departure
   - International: 3h before departure
   - Add 30min if distance > 40km, 1h if > 60km

   **Post-arrival:**
   - Immigration/baggage: 45min (international), 30min (domestic)
   - Airport-to-city travel: `distance / 40 km/h` (min 20min)
   - Hotel check-in: 30min
   - Sum all components

5. **Apply Layover Rule**

   For multi-segment journeys:

   **If layover ≥ 5h:**
   - Segment 1: (Departure - pre-buffer) → (First arrival + immigration only)
   - GAP: Lounge availability
   - Segment 2: (Second departure - 1h) → (Final arrival + full post-buffer)

   **If layover < 5h:**
   - Single block: (Departure - pre-buffer) → (Final arrival + full post-buffer)

6. **Calculate Block Timestamps**
   - Start: `Departure time - Pre-departure buffer` (in departure timezone)
   - End: `Arrival time + Post-arrival buffer` (in arrival timezone)
   - Express with IANA timezone identifiers

7. **Format Block Specifications**

   ```
   **BLOCK [N]: [Origin] → [Destination]**
   - **Start:** [Day], [Date] at [HH:MM] ([TZ], UTC±X)
   - **End:** [Day], [Date] at [HH:MM] ([TZ], UTC±X)
   - **Flight segments:**
     - [Flight]: Depart [HH:MM], Arrive [HH:MM] ([Origin]-[Dest])
     - Layover: [Duration] ([< or ≥] 5h)
     - [Flight]: Depart [HH:MM], Arrive [HH:MM] ([Origin]-[Dest])
   - **Total unavailable:** [Duration]
   - **Notes:** [Layover handling, terminal changes]
   ```

8. **Generate Summary**
   - List blocks chronologically
   - Sum total blocked time
   - Note timezone transitions
   - Highlight split blocks (layover ≥ 5h)

### Checkpoint

- Future bookings identified (past travel excluded)
- Flight details extracted with times, airports, durations
- Airport distances determined for all locations
- Buffers calculated based on distance and flight type
- Layover rule applied at 5h threshold
- Blocks formatted with timezone-aware timestamps
- Summary generated

## Helper Procedure A: Airport Distance Lookup

**Input**: IATA code

**Output**: Distance in km

**Method**:
- Web search: `[IATA] airport to city center distance`
- Verify correct airport (some cities have multiples)
- Extract typical distance; if range, use midpoint
- No result: 25km default

## Appendix A: Common Timezones

- **Asia/Tokyo** (NRT, HND): UTC+9
- **Asia/Singapore** (SIN): UTC+8
- **Asia/Shanghai** (PVG, PEK): UTC+8
- **Asia/Dubai** (DXB): UTC+4
- **Europe/Paris** (CDG): UTC+1/+2
- **Europe/London** (LHR, LGW): UTC+0/+1
- **America/New_York** (JFK, EWR): UTC-5/-4
- **America/Los_Angeles** (LAX): UTC-8/-7
- **Australia/Sydney** (SYD): UTC+10/+11
- **Australia/Melbourne** (MEL): UTC+10/+11

## Appendix B: Validation Examples

### Example 1: Short Layover - Continuous Block

**Journey**: Singapore → Tokyo → Los Angeles (hypothetical Dec 10-11)
- SIN-NRT: 08:00 - 16:15 (7h 15m)
- Layover: 3h 45m (< 5h)
- NRT-LAX: 20:00 - 14:30 (9h 30m)

**Result**: Single block
- Start: Dec 10, 05:00 SGT (3h before international departure, NRT is ~60km from Tokyo)
- End: Dec 11, 16:30 PST (45min immigration + 60min travel for LAX ~45km + 30min check-in)
- Duration: Approximately 27h 30m unavailable

### Example 2: Long Layover - Split Block

**Journey**: London → Dubai → Sydney (hypothetical Mar 15-16)
- LHR-DXB: 22:00 (Mar 15) - 08:30 (Mar 16) (6h 30m)
- Layover: 6h 15m (≥ 5h)
- DXB-SYD: 14:45 (Mar 16) - 10:30 (Mar 17) (13h 45m)

**Result**: Two blocks with gap

**Block 1**: London → Dubai
- Start: Mar 15, 19:00 GMT (3h before departure)
- End: Mar 16, 09:15 GST (45min immigration only, staying in airport)
- Duration: Approximately 10h 15m unavailable

**GAP**: Mar 16, 09:15 - 13:45 GST (~4h 30min lounge availability)

**Block 2**: Dubai → Sydney
- Start: Mar 16, 13:45 GST (1h before departure, already in airport)
- End: Mar 17, 12:15 AEDT (45min immigration + 60min travel for SYD ~20km + 30min check-in)
- Duration: Approximately 16h 30m unavailable

---

## Procedure: Update Google Calendar with Travel Blocks

### Prerequisites

- Google Calendar MCP server configured and accessible
- Calendar block specifications generated (from main procedure above)
- Access to target calendar (typically primary calendar)

### Privacy Requirements

**CRITICAL**: Calendar event summaries must NOT contain location information for privacy reasons.

- **Allowed titles**: "Blocked Time"
- **NOT allowed**: "Flight to Paris", "NYC Trip", "London → Dubai", city names, airport codes

### Input

Structured calendar block data with:
- Start datetime (ISO 8601 with timezone)
- End datetime (ISO 8601 with timezone)
- Block number/identifier

### Steps

1. **Get Current Time**
   - Use `mcp__google-calendar-mcp__get-current-time` to confirm timezone context

2. **List Existing Events**
   - Use `mcp__google-calendar-mcp__list-events` for the travel date range
   - Search for existing travel blocks using `mcp__google-calendar-mcp__search-events` with query "Blocked Time"

3. **Identify Conflicts and Existing Blocks**
   - Check if travel blocks already exist for these times
   - Note any meetings that conflict with travel times
   - **Conflicts do NOT prevent block creation** - create blocks regardless of conflicts, then report them

4. **Create or Update Calendar Blocks**

   For each block specification:

   **Always create new blocks** (even if conflicts exist):
   - Use `mcp__google-calendar-mcp__create-event` with:
     - `calendarId`: "primary" (or specific calendar ID)
     - `summary`: "Blocked Time" (NO location details)
     - `start`: ISO datetime string
     - `end`: ISO datetime string
     - `timeZone`: IANA timezone of departure location
     - `transparency`: "opaque" (shows as busy)
     - `visibility`: "private"
     - `allowDuplicates`: true (to bypass duplicate detection if needed)

   **If existing travel block needs time adjustment:**
   - Use `mcp__google-calendar-mcp__update-event` with:
     - `calendarId`: calendar ID
     - `eventId`: existing event ID
     - Updated `start` and/or `end` times

5. **Report Conflicts**
   - List any meetings that fall within travel block times
   - Recommend declining or rescheduling conflicting events

### Output Format

```
CALENDAR UPDATE SUMMARY
=======================

Created Blocks:
- [Block N]: [Start datetime] → [End datetime] (Event ID: xxx)

Updated Blocks:
- [Block N]: [Previous times] → [New times] (Event ID: xxx)

Conflicts Detected:
- [Meeting name] at [time] - recommend: [decline/reschedule]

No Action Needed:
- [Block N]: Already correctly blocked
```

### Checkpoint

- All future travel blocks created/updated in calendar
- Event titles contain NO location information
- Events marked as "busy" (opaque)
- Conflicting meetings identified and reported

---

**End of Standard Operating Procedure**
