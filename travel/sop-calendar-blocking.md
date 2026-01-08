# Travel Calendar Standard Operating Procedure

## Purpose Statement

This Standard Operating Procedure establishes the methodology for creating calendar entries for travel events. It supports two modes: **detail mode** (default) shows flight numbers, times, and routes; **blocking mode** creates privacy-preserving "Blocked Time" entries.

## Calendar Mode

**Default: Detail mode**

- **Detail mode**: Calendar entries include specific information (flight numbers, routes, event names). Use when the calendar is private or sharing specifics is acceptable.
- **Blocking mode**: Calendar entries show only "Blocked Time" with no location or travel details. Use when privacy is required.

If the user doesn't specify, use detail mode.

## What Gets Calendar Entries

Create calendar entries for:

- Flights (each segment or journey block)
- Online check-in appointments (per flight segment where available)
- Train journeys
- Car rental pickup and return appointments
- Event tickets (museums, shows, concerts, attractions)

Do NOT create calendar entries for:

- Hotel bookings (arrival/departure handled by flight entries already)

## Scope

This SOP applies to calendar entries for travel documented in journey folders. See `sop-travel-folder-access.md` for how to access travel folders.

**Boundaries:**

- For journey planning and itinerary creation, see Travel Itinerary Management SOP
- For file organization and email synchronization, see Travel Admin Folder Management SOP

## Prerequisites

- Journey folder exists with properly organized Fares subfolder
- Flight booking PDFs present in Fares subfolder
- PDF text extraction capability (`pdftotext`)
- Current date awareness to filter past travel
- Web search access for airport distance calculations

## Layover Availability Rule

**Applies to blocking mode only.** In detail mode, create separate entries for each flight segment regardless of layover duration.

**Blocking mode threshold: 5 hours**

- **Layover ≥ 5 hours**: Split into separate blocked time entries with gap for lounge availability
- **Layover < 5 hours**: Single blocked time entry covering entire journey

**Rationale**: Layovers under 5 hours involve too much movement (deplaning, finding lounge, security dynamics, boarding) to sustain productive work.

## Procedure: Generate Calendar Blocks for Remaining Travel

### Input

Journey folder path (use access method from `sop-travel-folder-access.md` to locate the folder)

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
     - **PNR/booking reference** (for check-in events)
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

5. **Determine Calendar Entry Structure**

   **Detail mode**: Create separate calendar entries for each flight segment, regardless of layover duration. Each segment includes terminal information and specific flight details.

   **Blocking mode**: Apply layover rule for multi-segment journeys:
   - **If layover ≥ 5h**: Segment 1 → GAP → Segment 2
   - **If layover < 5h**: Single continuous block

6. **Calculate Entry Timestamps**

   **Detail mode** (per flight segment):
   - First segment: Start = Departure - pre-departure buffer; End = Arrival + immigration only
   - Middle segments: Start = Departure - 1h; End = Arrival + immigration only
   - Final segment: Start = Departure - 1h; End = Arrival + full post-arrival buffer
   
   **Blocking mode**:
   - Start: `Departure time - Pre-departure buffer` (in departure timezone)
   - End: `Arrival time + Post-arrival buffer` (in arrival timezone)
   
   Express with IANA timezone identifiers

7. **Format Specifications for Planning Output**

   Document the travel structure (this informs calendar entry creation):

   ```
   **Flight [N]: [Flight#] [Origin] → [Destination]**
   - **Departure:** [Day], [Date] at [HH:MM] ([TZ], UTC±X)
   - **Arrival:** [Day], [Date] at [HH:MM] ([TZ], UTC±X)
   - **Terminal:** [Terminal info]
   - **Calendar entry:** [Start time] → [End time] (with buffers)
   ```

8. **Generate Summary**
   - List blocks chronologically
   - Sum total blocked time
   - Note timezone transitions
   - Highlight split blocks (layover ≥ 5h)

### Checkpoint

- Future bookings identified (past travel excluded)
- Flight details extracted with times, airports, durations
- Airport distances determined for origin and final destination
- Buffers calculated based on distance and flight type
- Entry structure determined (separate segments for detail mode; layover rule for blocking mode)
- Specifications formatted with timezone-aware timestamps
- Planning output generated

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

## Appendix B: Mode Comparison

**Detail mode**: Each flight segment becomes a separate calendar entry with flight number, route, and terminal information. Apply buffers per Step 6.

**Blocking mode**: Multi-segment journeys are combined based on layover duration (5h threshold). All entries show "Blocked Time" without specifics.

---

## Procedure: Update Google Calendar

### Prerequisites

- Google Calendar MCP server configured and accessible
- Travel data extracted (flight segments, train bookings, car rentals, event tickets)
- Access to target calendar (typically primary calendar)

### Input

- Calendar mode (detail or blocking; default: detail)
- Structured travel data with start/end datetimes (ISO 8601 with timezone)

### Steps

1. **Get Current Time**
   - Use `mcp__google-calendar-mcp__get-current-time` to confirm timezone context

2. **List Existing Events**
   - Use `mcp__google-calendar-mcp__list-events` for the travel date range
   - Check for existing entries that might duplicate

3. **Create Calendar Entries**

   For each travel item, use `mcp__google-calendar-mcp__create-event` with:
   - `calendarId`: "primary" (or specific calendar ID)
   - `start`: ISO datetime string (with buffers per Step 6)
   - `end`: ISO datetime string (with buffers per Step 6)
   - `timeZone`: IANA timezone of departure/event location
   - `transparency`: "opaque" for flights/trains/events; "transparent" for online check-in
   - `summary`: see table below
   - `location`: see table below (web search for terminal if not in booking)

   **Detail mode (default):**

   Create separate calendar entries for each flight segment with terminal details.

   | Item Type | Summary | Location |
   |-----------|---------|----------|
   | Flight segment | `✈ [Flight#] [Origin]-[Dest]` | `[Airport Name] Terminal [X]` |
   | Online check-in | `📱 Check-in PNR: [PNR] ([Flight1]+[Flight2]+...)` | (omit) |
   | Train | `🚄 [Operator] [Origin]-[Dest]` | `[Station Name]` |
   | Car rental pickup | `🚗 Pickup: [Company] [Location]` | `[Airport/City] [Company] [Branch]` |
   | Car rental return | `🚗 Return: [Company] [Location]` | `[Airport/City] [Company] [Branch]` |
   | Event/ticket | `🎫 [Event name]` | `[Venue Name]` |

   **Blocking mode:**

   Apply 5h layover rule. Create one or more "Blocked Time" entries depending on layover duration.

   | Item Type | Summary | Location |
   |-----------|---------|----------|
   | All items | `Blocked Time` | (omit) |

4. **Create Online Check-in Events**

   In detail mode only, create one check-in event per booking (not per flight segment):

   a. **Group flights by booking**: Flights on the same booking/PNR check in together. Extract the PNR and all flight numbers from each booking PDF.

   b. **For each booking's first flight**:
      - Research airline check-in policy: Web search `[airline] online check-in window hours`
      - Check country availability: Web search `[airline] online check-in [origin country]` to verify availability (some China and India flights don't offer it)
   
   c. **Create event if available**: One event per booking spanning the check-in window:
      - Summary: `📱 Check-in PNR: [PNR] ([Flight1]+[Flight2]+...)`
      - Start: When check-in opens (per airline policy)
      - End: When check-in closes (per airline policy, for the first flight)
      - `transparency`: "transparent"
      - Use first flight's departure timezone

   Skip this step in blocking mode.

5. **Report Conflicts**
   - List any existing meetings that fall within travel entry times
   - Recommend declining or rescheduling conflicting events

### Output Format

```
CALENDAR UPDATE SUMMARY
=======================

Created Entries:
- [Summary]: [Start datetime] → [End datetime] ([transparency]) (Event ID: xxx)

Conflicts Detected:
- [Meeting name] at [time] - recommend: [decline/reschedule]
```

### Checkpoint

- All future travel items have calendar entries
- Online check-in events created per booking where airline policy allows (detail mode only, marked as transparent)
- Entry titles follow mode-appropriate format
- Travel events marked as "busy" (opaque); check-in events marked as "free" (transparent)
- Conflicting meetings identified and reported

---

**End of Standard Operating Procedure**
