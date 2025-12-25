# Itinerary Management Standard Operating Procedure

**Part of**: `sop-travel-master.md` orchestration system

**Relationship to other SOPs**:
- Orchestrated by: `sop-travel-master.md`
- Depends on: `build/extraction/*.yaml` (from `sop-booking-extraction.md`)
- Depends on: `build/research/*.md` (from `sop-destination-research.md`)
- Validated by: `sop-mental-journey-simulation.md`

## Purpose Statement

This Standard Operating Procedure assembles extraction and research outputs into a comprehensive itinerary document. When run standalone (without pre-built extraction/research), it performs all phases internally. When run as part of the master orchestration, it consumes `build/` artifacts produced by upstream SOPs.

The SOP enables systematic assessment of journey readiness through sophisticated contextual reasoning—employing mental journey simulation to identify gaps, validate logical continuity, and assess planning quality whilst distinguishing genuine problems from acceptable gaps.

## Role Definition - Critical Understanding

**You are an itinerary creator, not an advisor.**

When following this SOP, you are creating a complete, actionable itinerary document for the traveller. You are NOT producing an advisory document that tells the user what they need to research or look up. Key implications:

- If you research hotel options and their locations, YOU determine if they're close to subway exits - don't tell the user to check
- If you research transport options and costs, YOU provide the recommendation with reasoning - don't just list options for the user to decide
- If you research whether a car is needed, YOU conclude whether to rent or not with reasoning - don't leave it as "consider car rental"

**When user research is acceptable:**
- Information genuinely not yet available (e.g., "Check museum website closer to travel date for updated hours" when planning 6 months ahead)
- Anti-bot blocking prevents access (e.g., "Hotel website blocked scraping - booking.com shows reviews indicate 400m from metro")
- Requires account/booking to access (e.g., "Specific room views require booking to confirm")

The goal: The itinerary you create should be usable by the traveller during their journey without requiring them to do additional research, except in genuinely exceptional cases where information is not yet knowable or accessible. Provide complete information, clear recommendations, and explicit reasoning.

The procedure synthesizes multiple information sources—booking confirmations, accommodation details, event tickets, and transport documents—into a coherent assessment of travel readiness, producing actionable itinerary documents that integrate gap analysis, booking recommendations, and day-by-day timelines into one cohesive resource for travellers.

**Critical Understanding: Purpose of Detailed Research**

The detailed research requirements in this SOP (checking sunset times, museum opening hours, seasonality, transport options, etc.) serve a specific purpose: **to compensate for the inherent randomness and hectic nature of travel, not to create perfect, rigid schedules**. Travel is unpredictable—delays occur, energy levels vary, weather changes, children's needs fluctuate. The comprehensive research provides a foundation of knowledge that enables flexible adaptation during the journey, not a minute-by-minute prescription that must be followed precisely.

**Output Style Guidance:**

The detailed research instructions should NOT result in pedantic, overly precise itineraries with rigid minute-by-minute schedules. Instead, the output should:
- Provide flexible time estimates and ranges rather than exact timestamps
- Focus on feasibility and options rather than precise sequencing
- Emphasise adaptability and backup plans rather than rigid adherence to a schedule
- Recognise that travel is dynamic and plans will inevitably change
- Present information that supports decision-making during the journey, not a strict script to follow

The itinerary document is an operational reference that may be read first by staff as well as by the traveller. Therefore, avoid second-person conversational phrasing ("you", "your", "if you"). Write in a role-neutral voice that refers to the traveller(s) by name (e.g., "Weiwu") or as "the traveller".

The person requesting this itinerary is not seeking perfection or orderliness—they are seeking comprehensive information that helps navigate the chaos of travel with children and multiple commitments.

## Scope

This SOP applies to the creation, planning, evaluation, and documentation of travel journeys within the "Travel Admin" folder (see `sop-travel-folder-access.md` for access methods). The procedure focuses on:

- Creating and planning travel itineraries with activity recommendations and accommodation selection
- Applying child-specific planning considerations when children are detected in the travel party
- Evaluating travel completeness through intelligent contextual reasoning
- Generating comprehensive itinerary documents with gap identification
- Providing booking recommendations for identified gaps
- Creating day-by-day timelines with timestamp estimation

**Important Boundaries:**

- This SOP is **NOT** for file organisation or naming. For folder structure verification, file naming conventions, and email synchronisation, see the Travel Admin Folder Management SOP (`travel-admin-folder-management.md`).
- This SOP **CAN** recommend bookings. When gaps are identified, the procedure suggests what needs to be booked and provides guidance on options, formatted as: "To book this, you need to do X. There are certain options: A, B, C..." with considerations for each option.
- This SOP is **NOT** for making bookings. It does not prescribe the actual booking process or actions.

**Prerequisites:**

Before executing this SOP, ensure folder management is complete:

1. All files are properly organised and named (see Travel Admin Folder Management SOP)
2. Email confirmations have been synchronised with folder contents
3. Reimbursement documents are properly categorised

The folder management SOP (`travel-admin-folder-management.md`) must be completed first, as itinerary management depends on well-organised, correctly named files.

## Journey Folders

A journey folder contains all documentation for a specific trip, including transport bookings, accommodation reservations, event tickets, and reimbursement documents. Journey folders are organised with a date-prefixed naming structure (e.g., "2025-11-15 Lisbon - Weiwu, Liansu, A-Z") and contain standardised subfolders: Fares, Accommodations, Passes, and optionally Reimbursement folders.

**Default Location**: See `sop-travel-folder-access.md` for how to access travel folders. That SOP defines the access methods (MCP preferred, filesystem mount fallback) and is the single source of truth for folder location.

## RUN: Itinerary Management Execution

A **RUN** is a complete itinerary management pass through a journey folder, executing itinerary creation and planning, mental journey simulation validation, and itinerary document generation to provide comprehensive travel documentation.

**CRITICAL PREREQUISITE - Folder Location:**

This SOP assumes the folder management SOP has already been executed and the journey folder exists with organized booking documents.

**Before executing any procedures:**

1. **Access travel folders** following `sop-travel-folder-access.md`:
   - Use MCP method (preferred) or filesystem mount (fallback) as defined in that SOP
   - The access SOP is the single source of truth for folder location and access methods

2. **Locate the journey folder**:
   - Extract journey name from user request (format: "YYYY-MM-DD [Destination] - [Travelers]")
   - Use the access method established in step 1 to find the journey folder within `0. Travel Admin/`
   - Example journey folder: `2025-11-29 Venice - Liansu, Weiwu, A-Z`

3. **Verify folder exists and contains booking documents:**
   - Using the established access method, list the journey folder contents
   - If folder exists: Proceed with RUN using this folder as the working directory
   - If folder not found: Stop and ask user to confirm folder location or run folder management SOP first

4. **Set working context for all procedures:**
   - All Read, Glob, Grep operations target: `[journey-folder]/Fares/`, `[journey-folder]/Accommodations/`, `[journey-folder]/Passes/`
   - Generated itinerary document saves to: `[journey-folder]/[Itinerary-File].md` (filename determined by master SOP)

**RUN Workflow:**

1. **Itinerary Creation and Planning** (Procedure 1): Create or update travel plans with activity recommendations, accommodation selection, and child-specific considerations when applicable
2. **Mental Journey Simulation and Completeness Evaluation** (Procedure 2): Execute mental journey simulation to validate plans, identify gaps, verify transport connections, assess accommodation continuity, and categorise issues by severity
3. **Itinerary Document Creation/Update** (Procedure 3): Generate or update the cluster-level itinerary with integrated completeness checklist, transportation table, and day-by-day timeline
4. **Quality Control and Iteration** (Procedure 4): Verify itinerary against 10-item QC checklist, iterate to fix any failures, ensure creator role (not advisor), confirm all key decisions documented

**Triggering:**

This RUN is typically triggered after folder management RUN completes, or separately when:

- New bookings have been added and organised
- Journey evaluation is needed before departure
- Itinerary updates are required due to booking changes
- User requests completeness assessment

**Re-runnability by Design:**

A RUN is designed to be executed multiple times as new bookings arrive or information changes. However, it MUST maintain document cohesiveness:

- Each edit of the itinerary should be made cohesively and holistically written, as if the author already considered all points of the document at the outset.
- Each fact, number, and point should be mentioned only once, in the most appropriate place.
- Do NOT use incremental patching or scattered updates throughout the document. Very often, "Critical", "Important" keywords indicate not criticality or important but a missing point that was later addressed in a patch or revision. If you see those, you know the rule is probably broken.
- **Revision History Restriction**: A "Revision History" or "Version Updates" section should not exist nor added during the planning phase. It consumes tokens and reduces clarity.
- Revision history is ONLY needed for updates that occur *after* the journey has started then changes were introduced.
- Resolved gaps are removed from the completeness checklist entirely, not marked as "fixed".
- Newly identified gaps are integrated into the existing structure.

**Relationship to Folder Management:**

This SOP is designed to work in tandem with the Travel Admin Folder Management SOP. The typical workflow is:

1. Execute folder management RUN (organise files, check emails)
2. Execute itinerary management RUN (evaluate completeness, generate itinerary)

The separation allows automated systems to run folder management without user interaction, whilst itinerary management may require user confirmation for booking decisions and can be invoked separately.

## Procedure 1: Itinerary Creation and Planning

### Purpose

Create or update travel itineraries by researching destinations, identifying suitable activities, clustering attractions geographically, and selecting appropriate accommodations. This procedure transforms existing bookings into a coherent travel plan, or creates new plans from scratch, with special considerations applied when children are detected in the travel party.

**Primary Mode**: This procedure operates primarily in update/optimisation mode (approximately 90% of usage), refining and enhancing existing itineraries as new bookings are made or circumstances change. New itinerary creation from scratch represents approximately 10% of usage.

### Input

- All travel documents from journey folder (Fares, Accommodations, Passes)
- Existing itinerary document (if present, for revision)
- Journey folder name (to extract traveller composition)

### Output

- Updated or newly created travel plan with activity recommendations
- Accommodation selection strategy with reasoning
- Child-specific planning notes (when applicable)
- Geographic activity clusters with accessibility considerations

### Phase 1: Traveller Composition and Booking Analysis

**Objective**: Determine traveller composition, identify existing commitments, and establish planning anchors

1. **Check Passenger Names in Fares Folder**
   - List all files in Fares folder
   - Extract passenger names from filenames (comma-separated list after booking reference)
   - Check for known child names: "Alice" and "Zoe" (or variations: "A-Z", "Alice,Zoe")
   - If found, flag journey as **"with children"**

2. **Check for Child Indicators in Tickets**
   - If passenger names don't reveal children, examine ticket PDFs
   - Look for child fare types, age indicators, or "CHD" designations
   - Check for family booking patterns (multiple passengers with age-based pricing)
   - If child indicators found, flag journey as **"with children"**

3. **Identify Traveller Split Patterns**
   - **Important**: Not all travellers travel together all the time
   - Check if different tickets have different passenger combinations
   - Note where travellers split or rejoin (e.g., one person departs earlier, others stay longer)
   - Identify which travellers are present for which segments of the journey
   - Plan activities appropriate for each traveller composition on each day

4. **Identify Existing Event Commitments (Planning Anchors)**
   
   **Objective**: Events and conferences establish fixed points around which other activities must be planned
   
   a. **Scan Passes Folder**
      - List all files in Passes folder
      - Extract event names, dates, locations from filenames
      - Note which travellers are included in each event (check ticket details)
   
   b. **Categorise Events as Planning Anchors**
      
      **Conference/Business Events:**
      - Multi-day conferences establish location and accommodation requirements
      - Hotels should be near conference venue if possible (prioritise this over other considerations)
      - Daily activities should be planned near conference location (attendees may have limited time)
      - Check conference schedule: full-day events leave minimal time for other activities
      - Note: Conference attendees vs non-attendees may have different activity plans
      
      **Timed Events/Attractions:**
      - Museum bookings, show tickets, restaurant reservations establish time anchors
      - These fix the traveller's location at specific date/time
      - Plan other activities around these fixed points
      - Consider travel time to reach timed events
      
      **Multi-Day Events:**
      - Events spanning multiple days establish multi-day location requirements
      - Accommodation should remain consistent near event venue (avoid hotel changes mid-event)
   
   c. **Use Events to Establish Geographic Clusters**
      - Events define "must be here" locations
      - Build activity clusters around event locations
      - If multiple events in different areas, create separate clusters for each

5. **Default to Adult-Only Planning**
   - If no children detected, proceed with standard planning (skip child-specific phases)
   - Child-specific considerations in subsequent phases are only activated when children are detected

### Phase 2: Existing Content Review

**Objective**: Read and understand current state to enable update/optimisation mode

1. **Read Existing Itinerary Document (if present)**
   - Extract existing activity plans and recommendations
   - Note current accommodation bookings and their locations
   - **Note suggested accommodations in to-do items** (these are recommendations, not yet booked)
   - Identify what activities are already planned
   - Understand existing geographic clusters or patterns

2. **Cross-Reference Suggestions with Actual Bookings**
   
   **Critical for Re-runnability**: Suggested accommodations in previous itinerary may now be booked
   
   a. **Read Accommodations Folder**
      - List all accommodation booking files
      - Extract hotel names, dates, locations from filenames
   
   b. **Compare Suggestions to Actual Bookings**
      - For each suggested accommodation in previous itinerary:
        - Check if that specific hotel now appears in Accommodations folder
        - Check if a different hotel is booked for those dates
        - Check if dates still have no accommodation booking
      
   c. **Categorise Accommodation Status**
      - **Suggestion matched**: Suggested hotel was booked → mark to-do as complete
      - **Different hotel booked**: Alternative hotel chosen → mark to-do as complete, update itinerary to reflect actual booking
      - **Still unbooked**: No accommodation found for those dates → keep as active to-do, review if suggestion still valid

3. **Assess What Needs Planning**
   - Identify days with no planned activities
   - Identify cities with accommodation but no activity plans
   - Note any explicitly requested changes or additions
   - Identify accommodation gaps (nights with no booking)
   - Determine scope: full creation vs partial updates

4. **Preserve Valid Existing Plans**
   - Do not regenerate what already works
   - Only propose changes where needed
   - Build incrementally on existing content
   - **Update to reflect actual bookings** where different from suggestions

### Phase 3: Arrival and Departure Timing Analysis

**Objective**: Determine first-day and last-day activity feasibility based on flight/transport arrival and departure times

**IMPORTANT**: Use `pdftotext` to extract booking details from PDF files in the Fares folder. Flight times, train times, and other transport details are reliably available in the booking confirmations. Do not guess or leave times as "TBC" when PDFs are available.

**Purpose of Timing Analysis:**

This phase establishes feasibility windows and general timing constraints, NOT precise minute-by-minute schedules. The goal is to understand what activities are realistically possible given arrival/departure times, not to create rigid timelines. Use this information to inform activity recommendations and accommodation strategies, but do not translate it into pedantic scheduling in the final itinerary output.

**Example usage**:
```bash
pdftotext "/path/to/Fares/2025-12-23 [Ryanair] Seville-Edinburgh FR1073 JQ3BFI.pdf" -
```

This will extract text including flight numbers, departure times, arrival times, and other booking details needed for accurate itinerary planning.

1. **Analyse First Day Arrival**

   Extract arrival information from first transport booking:
   - **Use pdftotext to read the PDF** and extract actual departure and arrival times
   - Arrival time at destination
   - Add processing time (immigration, baggage, customs)
   - Add transport time to accommodation
   - Calculate estimated arrival time at accommodation
   
   **Night Arrival Strategy** (arrival after 19:00):
   - Primary plan: Proceed directly to hotel after arrival
   - Minimal additional activities (perhaps nearby dinner if energy permits)
   - First full activity day is the following day
   
   **Afternoon Arrival Strategy** (arrival 14:00-19:00):
   - Check if arrival time aligns with typical 15:00 check-in
   - If before check-in: Light nearby activity possible, then return to check in
   - If after check-in: Check in first, then optional nearby evening activity
   
   **Morning/Early Arrival Strategy** (arrival before 14:00):
   - Hotel typically cannot provide room until 15:00 check-in
   - Plan: Arrive at hotel, drop luggage (hotels usually allow early luggage storage)
   - Go out for activities nearby (walking distance from hotel preferred)
   - Activities could include: sightseeing, breakfast/lunch, light exploration
   - Return to hotel around 15:00 to complete check-in and access room
   - Optional second outing after check-in if energy permits
   - **Critical**: Keep morning activities near hotel (luggage is there, need to return by 15:00)

2. **Analyse Last Day Departure**

   Extract departure information from last transport booking:
   - **Use pdftotext to read the PDF** and extract actual departure time
   - Check-out time from hotel (typically 11:00)
   - Required arrival time at airport/station (2 hours for international flights, less for trains)
   - Calculate latest useful activity time
   
   **Late Departure** (departure after 18:00):
   - Full morning activities possible
   - Check out from hotel, store luggage if activities continue after checkout
   - Afternoon activities possible before departure
   
   **Afternoon Departure** (departure 12:00-18:00):
   - Morning activities possible near hotel
   - Check out, proceed to airport/station with time buffer
   
   **Morning Departure** (departure before 12:00):
   - Minimal activity possible
   - Early checkout, proceed to departure point
   - Perhaps breakfast near hotel before departure

### Phase 4: Destination Research and Activity Identification

**Objective**: Research destinations and identify suitable activities based on traveller composition, existing anchors, and seasonal factors

**Scope Interpretation:**

When asked to create an itinerary for a city (e.g., "make Edinburgh itinerary"), interpret this broadly to include nearby accessible regions when appropriate:
- If children are present: nearby destinations within reasonable driving distance can be considered as day trips
- If purpose is leisure: regional exploration may be more suitable than staying within city limits
- If purpose is business/conference: focus remains on the named city

This broader interpretation allows evaluation of car-based regional travel vs city-based walking travel as strategic alternatives.

**Purpose of Detailed Research:**

The comprehensive research requirements in this phase (sunset times, museum opening hours, seasonal events, weekly closure patterns) are designed to **build a knowledge base that compensates for travel randomness**, not to create rigid schedules. This research enables flexible decision-making during the journey—knowing that a museum closes on Mondays helps avoid wasted trips, knowing sunset times helps plan outdoor activities appropriately, but this information should inform recommendations rather than dictate minute-by-minute plans. The output should present this information as context and options, not as a strict timetable to follow.

1. **Identify Destinations and Seasonal Context**
   - Extract cities from Fares and Accommodations folders
   - Note duration of stay in each city
   - **Identify travel dates and season**: Winter, Spring, Summer, Autumn
   - **Research sunrise and sunset times** for the travel dates in each destination
     - Winter: shorter days, sunset as early as 16:00-17:00 in some locations
     - Summer: longer days, sunset as late as 21:00-22:00 in some locations
     - Affects viable activity hours and types
   - Cross-reference with existing event commitments from Phase 1

2. **Research Airport Positioning and Regional Accessibility**

   For the arrival and departure airports, conduct web searches and document findings:

   a. **Geographic position**:
      - Search: "Where is [Airport Name] located [Country/Region]?" and "What cities are near [Airport Name]?"
      - Document the airport's geographic position with specific details (distance from main city, highway access, position between multiple cities)
      - Example finding: "Edinburgh Airport is located 5.8 miles west of Edinburgh city centre, at M8/M9 motorway junction, positioned between Edinburgh and Glasgow"

   b. **Nearby destinations within 60 minutes**:
      - Search: "cities within 60 minutes drive [Airport Name]" or "day trips from [City] driving distance"
      - List all cities/towns within 60-minute drive
      - Document approximate driving times (e.g., "Glasgow 45 min, Stirling 60 min, Linlithgow 30 min")

   c. **Regional travel patterns**:
      - Search: "is [Region/Country] good for road trips" or "do tourists explore [Region] by car"
      - Document whether car-based touring is common
      - Note any statistics or recommendations found (e.g., "69% of visitors use cars", "VisitScotland recommends car touring")

   d. **Seasonal accessibility in alternative cities** (especially if travel dates include holidays/closures):
      - For each nearby city identified, search: "what's open in [City] on [Holiday/Date]" or "[City] Christmas Day attractions open"
      - Research ungated attractions that remain accessible regardless of closure schedules: churches, cathedrals, rivers, parks, public squares, outdoor monuments, waterfront areas, scenic viewpoints
      - Note: Larger cities may have more venues that remain open even if they also have more venues closed. Research actual open attractions, not just closure counts.
      - Document what IS accessible in each city, not just what's closed

   e. **Evaluate whether alternative destination-level plans warrant presentation**:
      Document findings for potential alternatives (car-based regional vs city-based), then assess comparative value using these criteria:

      **Value Assessment Criteria:**
      - **Variety**: Access to different cities/regions has inherent value even if individual attractions are similar (e.g., outdoor walks in multiple cities > outdoor walks in one city)
      - **Seasonal closures context**: When primary city has limited options (holidays/closures), car access to MULTIPLE limited-option cities compounds options rather than diluting them
      - **Travel time**: Car travel is transport overhead (like flights), NOT lost activity time. Don't penalize car options for drive time when comparing activity value.
      - **Practical benefits**: Children resting in car during drives, avoiding hotel changes for early flights, luggage flexibility, weather protection
      - **Cost factors**: Airport hotels often significantly cheaper than city hotels; free parking vs city parking fees
      - **Traveler composition**: Families with children benefit more from car flexibility than solo travelers

      **Threshold Application:**
      - If alternative offers ~90%+ value of primary: Present both with trade-offs
      - If alternative could offer 150%+ value for travelers with specific interests: Present with that caveat (Example: Cotswolds from London - not in any "sane" standard plan as it's 2+ hours away, but could be 150%+ value for travelers specifically interested in English countryside villages)
      - If alternative offers only ~60% value: Note alternatives exist but don't detail ("Alternative regional touring considered but offers limited value given constraints")

      Per-day alternatives are helpful when day-level choices have comparable value.

   Document this analysis - Phase 6 will use these findings for accommodation strategies, and Phase 7 will generate detailed plans only for alternatives warranting presentation.

   f. **Document transport mode decision for final itinerary**:

   Based on the regional accessibility research above, conclude whether car rental is recommended and provide explicit reasoning. This conclusion must appear in the final itinerary to demonstrate the transport strategy was evaluated, not overlooked.

   Example conclusion formats:
   - "Car rental not recommended: Amsterdam's compact historic center is best explored on foot or by tram, with excellent public transport (metro, tram, buses) connecting all major museums and attractions. Parking is extremely limited and expensive (€50+/day), and most streets are narrow or pedestrian-only. All planned activities accessible via public transport within 15-20 minutes."
   - "Car rental recommended: Gold Coast attractions are spread along 50km of coastline with limited public transport between key destinations. Major attractions (theme parks, beaches, hinterland) require 20-40 min drives between them. Car provides flexibility for beach hopping and visiting multiple parks without tour group constraints. Airport pickup convenient, free parking at most attractions."

3. **Research Seasonal Events and Festivals**
   
   **Critical**: Limited-time seasonal events should be prioritised as they define unique opportunities
   
   a. **Check for Major Seasonal Events:**
   
   **Winter (December-February):**
   - Christmas markets (typically late November through December)
   - New Year's Eve celebrations and parties (31 December)
   - Winter festivals, ice skating rinks, holiday light displays
   - Winter sports opportunities (if destinations include mountain/ski areas)
   
   **Spring (March-May):**
   - Spring festivals, flower displays (tulips, cherry blossoms)
   - Easter events and markets
   - Local cultural festivals (research specific to destination)
   
   **Summer (June-August):**
   - Outdoor music festivals, food festivals
   - Beach and water activities
   - Extended opening hours for attractions (summer schedules)
   - Outdoor cinema, evening events (taking advantage of long daylight)
   
   **Autumn (September-November):**
   - Harvest festivals, wine festivals
   - Autumn foliage viewing (particularly in parks and gardens)
   - Cultural season begins (opera, theatre, concerts)
   
   b. **Research City-Specific "What's On" for Travel Dates:**
   - Search: "[City name] events [Month Year]"
   - Check city tourism websites, event calendars
   - Note any major festivals, parades, special exhibitions
   - **Flag limited-time events prominently** (these create planning anchors similar to booked events)
   - **If no significant events found**: Explicitly document this finding ("No major events or festivals scheduled during [dates]") to distinguish researched absence from overlooked research

4. **Research General Activities with Seasonal Appropriateness**
   - Research major attractions and points of interest
   - Consider cultural sites, museums, landmarks, restaurants
   - Note opening hours and booking requirements
   - **Check winter vs summer hours** (many attractions have different schedules)
   - **Prioritise activities near existing event anchors** (conferences, booked attractions)
   - **Consider seasonal appropriateness:**
     - Winter: indoor activities more prominent (museums, galleries, cafes, indoor markets)
     - Summer: outdoor activities (parks, walking tours, outdoor dining, river cruises)
     - Rainy season: backup indoor options needed

5. **Research Attraction Operating Schedules**
   
   **Critical for Multi-Day Stays:**
   
   a. **Identify Weekly Closure Patterns:**
   - Many museums close on Mondays (very common in Europe)
   - Some close on Tuesdays instead
   - Religious sites may have restricted hours on religious days
   - Markets typically operate on specific days (e.g., Sunday markets, Saturday markets)
   
   b. **Create Day-of-Week Activity Matrix** (for multi-day city stays):
   - List all desired attractions
   - Note which days each is open
   - Note which days each is closed
   - **Plan activities for days when they're actually open**
   - Example: "Museum A closed Monday, Museum B closed Tuesday, Market on Sunday only"
   
   c. **Flag Public Holidays and Special Closures:**
   - Check if travel dates coincide with local public holidays
   - Many attractions close on public holidays or have reduced hours
   - Some attractions have special extended hours on certain days

**For Journeys WITH Children:**

1. **Identify Destinations and Seasonal Context (Child-Specific Notes)**
   - Extract cities from Fares and Accommodations folders
   - Note which travellers (including which children) are present for each segment
   - Calculate available activity time per day: ~4 hours actual exploring time in typical 12-hour day
   - **Identify travel dates, season, and research sunrise/sunset times**
     - **Critical with children**: Winter sunset at 16:00-17:00 means afternoon activities must finish earlier
     - Adjust activity timing to account for available daylight; winter limits evening activities
   - Cross-reference with existing event commitments from Phase 1

2. **Research Airport Positioning and Regional Accessibility** - *Follow same methodology as adult-only planning above, with additional child-specific value criteria noted in section 2e*

3. **Research Seasonal Events and Festivals**

   **Critical**: Children often enjoy seasonal events more than standard attractions
   
   a. **Check for Family-Friendly Seasonal Events:**
   
   **Winter (December-February):**
   - **Christmas markets**: Usually very child-friendly (lights, treats, entertainment)
   - Ice skating rinks and winter playgrounds
   - Holiday light displays and decorations (children find these captivating)
   - Santa visits and holiday-themed attractions
   - New Year's celebrations (note: late-night events may not suit young children)
   
   **Spring (March-May):**
   - Spring festivals with outdoor activities
   - Easter egg hunts and Easter markets
   - Flower displays and gardens (children enjoy running in gardens)
   
   **Summer (June-August):**
   - Outdoor water features and splash pads (crucial for cooling down)
   - Beach activities and water parks
   - Outdoor playgrounds and parks (longer daylight = more playground time)
   - Outdoor festivals with family zones
   
   **Autumn (September-November):**
   - Harvest festivals (pumpkin patches, apple picking)
   - Halloween events (if appropriate for children's age)
   - Parks with autumn foliage (children enjoy leaf piles)
   
   b. **Research City-Specific "What's On" for Families:**
   - Search: "[City name] family events [Month Year]"
   - Check city tourism websites for family-specific calendars
   - **Flag limited-time events prominently** (these are prioritised over standard attractions)

4. **Research Child-Friendly Activities with Seasonal Appropriateness**

   **Prioritization Principle:**

   Prioritize unique local experiences over generic attractions. Zoos and science museums are common globally - unless world-class or EU top (e.g., London Natural History Museum, Vienna Schönbrunn Zoo), they serve as "filler material" for activity clusters. Unique sights specific to the city that can't be found elsewhere should be prioritized.

   Examples: Edinburgh Forth Bridges and Arthur's Seat (unique) vs Edinburgh Zoo (generic). Include zoos/science museums only when: world-class attraction, child specifically requests, unique attractions exhausted, or backup needed for closures.

   **Priority Categories (in order):**
   1. Unique local landmarks: Castles, fortifications, architectural marvels, UNESCO sites, natural wonders specific to the region
   2. Distinctive natural scenery: Parks, beaches, gardens, viewpoints unique to the region (not generic city parks)
   3. Interactive cultural sites: Hands-on museums with local/national focus, child-oriented exhibits about regional history/culture
   4. Seasonal-specific experiences: Christmas markets, ice skating, water parks - often unique to how the region celebrates
   5. World-class museums/attractions: Include only if genuinely world-class or EU top-tier
   6. Generic attractions as filler: Aquariums, science museums, zoos - use only when unique options exhausted or as backup

5. **Research Attraction Operating Schedules**

   **Critical for Multi-Day Stays with Children:**
   
   a. **Identify Weekly Closure Patterns:**
   - Many children's museums and aquariums have limited closures (often open 7 days)
   - Science museums may close on Mondays
   - Zoos typically open daily but check winter schedules
   - Outdoor attractions may close for winter season entirely
   
   b. **Create Day-of-Week Activity Matrix** (for multi-day city stays):
   - List all desired child-friendly attractions
   - Note which days each is open
   - Note which days each is closed
   - **Plan museum/indoor visits for days when they're open**
   - **Plan outdoor/playground days for days when primary attractions are closed**
   - Example: "Aquarium closed Monday → Monday is playground + park day; Aquarium Tuesday"
   
   c. **Check Seasonal Operating Schedules:**
   - Outdoor attractions may close in winter or have reduced hours
   - Indoor attractions may have extended summer hours
   - Some attractions have winter closures (November-March)
   - Flag if attraction is closed during entire travel period

6. **Practical Considerations for Each Activity**
   
   For each identified activity, research:
   
   **Availability:**
   - Opening hours on travel dates (check specific dates, not just general hours)
   - Days closed per week (Monday closures, weekly patterns)
   - **Seasonal schedule changes** (winter vs summer hours)
   - Seasonal closures or off-season periods
   
   **Booking Requirements:**
   - Pre-booking required or walk-up available
   - Ticket purchase process (online, on-site, timed entry)
   - Lead time needed for booking
   
   **Duration and Energy Requirements:**
   - On-foot activities: max 1.5 hours recommended before rest needed
   - Indoor activities: up to 2 hours possible with breaks
   - Outdoor activities: variable, weather-dependent
   - **Adjust for daylight available**: Winter activities must finish before early sunset
   
   **Accessibility:**
   - Stroller-friendly or walking-only
   - Stairs, elevators, accessibility facilities
   - Rest areas and amenities (toilets, food, seating)
   
   **Weather Considerations:**
   - Indoor backup options for rainy days
   - Outdoor activities suitable for cold weather (with appropriate clothing)
   - Summer heat considerations (shaded areas, water access)

### Phase 5: Geographic Clustering

**Objective**: Group activities into geographic clusters to minimise transport time and maximise time at destinations

1. **Map Activities Geographically**
   - Plot identified activities on mental map of each city
   - **Plot existing event anchors first** (conferences, booked attractions, seasonal festivals)
   - Note distances between activities
   - Identify natural groupings based on proximity
   - Consider whether activities span multiple nearby cities or regions that might be better connected by car than by changing hotels

2. **Create Activity Clusters**
   
   **Clustering Principles:**
   - **Start with event anchors**: If conference/major event/seasonal festival exists, build clusters around that location
   - Group activities that are reasonably close to each other
   - Consider transport time between activities within cluster
   - For children: clusters should allow return to hotel for rest between outings
   - Balance cluster size: not too many activities (overwhelming), not too few (inefficient)
   - **Group by operating days**: For multi-day stays, cluster activities that are open on same days
   
   **Event-Anchored Clustering:**
   - If multi-day conference exists: all activities during conference days should be near conference venue
   - If timed event exists (museum booking, show): cluster that day's activities near event location
   - **If seasonal festival exists** (Christmas market, summer festival): make this a cluster anchor for that day
   - If travellers split: create separate clusters for different traveller groups
   
   **Day-of-Week Clustering** (for multi-day city stays):
   - **Monday cluster**: Activities that are open on Monday (avoid Monday-closed museums)
   - **Tuesday cluster**: Activities that are open on Tuesday (including Monday-closed museums if they're open)
   - **Sunday cluster**: Markets and attractions open on Sunday (many shops closed)
   - Ensure high-priority attractions are scheduled for days when they're actually open

3. **Assess Transport Within and Between Clusters**

   **Objective**: Research actual available transport modes and compare costs, time efficiency, and suitability for traveler composition

   **A. Research Available Transport Modes**

   For movement between hotel and activity clusters, research what transport options actually exist in this destination:

   1. **Public Transport Research**
      - Search: "[City] public transport", "[City] getting around", "[City] metro/tram/bus map"
      - Identify available modes: metro, trams, buses, ferries, water buses, cable cars, etc.
      - Note: "Public transport" is not generic - Venice has vaporetti, Brisbane has river ferries, some cities have no metro
      - Document ticket pricing: single ticket, day pass, multi-day pass
      - Check if children travel free or reduced fare

   2. **Private Transport Research**
      - Search: "[City] taxi prices", "[City] water taxi" (if applicable), "[City] rideshare availability"
      - Identify available modes: taxis, rideshare (Uber/Bolt), private boats/water taxis, car hire with driver
      - Document pricing structure: per vehicle (typical for taxis) vs per person (some boats)
      - Check typical journey costs for key routes (hotel to main attractions)

   3. **Walking Assessment**
      - Map walking distances between hotel and activity clusters
      - Consider: distance, terrain (hills, stairs, cobblestones), weather, child-friendliness
      - Note if city is genuinely walkable or if transport is necessary

   **B. Compare Transport Modes for Family Logistics**

   For each major transport need (hotel to cluster, between clusters), calculate and compare:

   1. **Cost Comparison**
      - Public transport: Cost per person × number of paying travelers (account for children's fares)
      - Private transport: Cost per vehicle (often fixed regardless of 2 or 4 passengers)
      - Example: Venice vaporetto €9.50/person × 2 adults = €19 vs water taxi €60-80 total for family of 4
      - Calculate for typical daily usage (multiple trips per day)
      - Consider multi-day passes vs single tickets

   2. **Time Efficiency**
      - Public transport: Journey time + waiting time (frequency matters) + potential transfers
      - Private transport: Direct journey time, typically faster but more expensive
      - Example: Venice water taxi 10 min direct vs vaporetto 20 min + 10 min wait = 30 min total
      - Consider if time savings justify cost premium

   3. **Practical Factors for Families**
      - Crowding: Can family of 4 with children sit together? (important for child supervision)
      - Luggage: Relevant for arrival/departure days or if carrying bags between activities
      - Children's comfort: Can children rest during journey, or must they stand in crowded conditions?
      - Stress level: Complex transfers with children vs direct door-to-door service
      - Safety: Child supervision easier in private vehicle vs crowded public transport

   **C. Within Clusters**

   Once at a cluster, assess movement between activities:
   - Walking distance between activities (consider time with children, terrain, weather)
   - If cluster is large, note internal transport options (e.g., park shuttles, local buses)
   - Identify rest points between activities (cafes, parks where children can break)

   **D. Between Clusters**

   For movement from hotel to clusters and between different clusters:
   - Transport time from hotel to each cluster (using most practical mode researched above)
   - Example consideration: Lisbon east (aquarium, MEO arena) to centre = 30+ minutes despite <10km
   - If transport time > 30 min each way with children, consider if multi-day stays in different areas are more practical than daily cross-city transport
   - Daily commute of 1+ hour round-trip consumes ~25% of children's effective activity time (~4 hours/day)

   **E. Document Recommendations**

   In the itinerary, present transport mode recommendations with reasoning:

   **Format:**
   ```
   **Hotel to [Cluster Name] Transport**

   Available options:
   - [Mode 1]: [Cost for family], [Time], [Frequency/Availability]
   - [Mode 2]: [Cost for family], [Time], [Frequency/Availability]

   Recommended: [Mode X]
   Reasoning: [Brief explanation of why this mode is most suitable - cost-effective, time-efficient, family-friendly, etc.]
   ```

   **Example:**
   ```
   **Sant'Elena Hotel to St Mark's Square Transport**

   Available options:
   - Vaporetto Line 1: €19 for 2 adults (children under 6 free), ~20 min journey + 5-10 min wait, frequent service
   - Water taxi: €60-80 for family of 4, ~10 min direct, book on demand

   Recommended: Vaporetto Line 1
   Reasoning: Cost-effective for short 1-day visit (€19 vs €60-80). Time difference modest (30 min total vs 10 min).
   Consider water taxi only if very tight schedule or children very young/tired.

   Alternative: 24-hour vaporetto pass (€25/adult = €50 total) if making 3+ trips in day.
   ```

### Phase 6: Accommodation Selection Strategy

**Objective**: Evaluate existing accommodation bookings or present accommodation strategies based on activity clusters, event anchors, and airport positioning research

Review Phase 4 Section 2 findings. If multiple destination-level plans warrant presentation (comparable value ~90%+ or potential 150%+ for specific interests), present accommodation options for each. For each plan, specify hotel location strategy, parking considerations, and how it serves activities. If alternative plans don't meet value threshold, present single primary strategy with brief note that alternatives were considered.

**For Journeys WITHOUT Children:**

1. **Evaluate Existing Accommodations**
   - Assess location relative to planned activities
   - **Assess location relative to conference/event venues** (if applicable)
   - Consider transport accessibility
   - Note any gaps in accommodation coverage

2. **Recommend Accommodations (if needed)**
   
   **Priority considerations:**
   
   a. **If conference/business event exists:**
      - **First priority**: Hotel near conference venue (walking distance if possible, otherwise short transport)
      - Conference attendees need to commute daily, minimise this time
      - Conference may have early starts or late finishes
      - Check if conference hotel room block exists
   
   b. **If major timed events exist:**
      - Consider hotel location relative to event venue
      - Balance between event proximity and other activities
   
   c. **General considerations:**
      - Central locations with good transport links
      - Proximity to major attractions or business centres
      - Standard hotel selection criteria

**For Journeys WITH Children:**

1. **Hotel Location Strategy**
   
   **Primary Objective**: Select hotels that are reasonably close or reasonably accessible to activity clusters
   
   **Critical Constraint**: IHG hotels are LIMITED in many cities
   
   **Anchor Considerations:**
   - **If conference exists**: Conference location overrides other considerations (adult attendee needs daily access)
   - **If major event exists**: Consider event location in hotel selection
   - Otherwise: Base hotel selection on general activity clusters
   
   **Selection Priority:**
   
   a. **First Choice**: IHG hotel reasonably positioned relative to primary activity cluster (or conference venue if applicable)
      - Father has IHG Platinum membership with suite upgrade potential
      - Can book on the day to secure upgrade phone call before arrival
      - One guaranteed upgrade per year available
      - Look for IHG properties with suite availability
      - For conferences: IHG near conference venue is ideal
   
   b. **Second Choice**: IHG hotel reasonably accessible via transport to activity cluster (or conference venue)
      - Not necessarily close, but transport time is manageable
      - Example: 20-30 minute train/metro to cluster
      - Consider: children's energy spent on transport reduces activity time
   
   c. **Third Choice**: Non-IHG hotel better positioned for activity clusters (or conference venue)
      - When no suitable IHG option exists or IHG properties are poorly positioned
      - Prioritise location over brand loyalty when trade-off is significant
      - Note the trade-off in recommendations (no Platinum benefits vs better location)
      - For conferences: Proximity to venue may justify non-IHG selection

2. **Multi-Location Stays**
   
   When cities have geographically separated clusters:
   
   **Consider Split Stays:**
   - Stay in outskirts near primary cluster for multi-day exploration
   - Move to city centre for concentrated city-centre activities
   
   **Example Pattern (from Porto experience):**
   - Days 1-2: Old city centre hotel → visit walkable monuments, markets, river attractions
   - Days 3-4: South of river hotel → visit south-side attractions without cross-river travel
   - Depart from south-side train station → avoid backtracking to city centre

3. **Transport Accessibility Evaluation**
   
   For each accommodation option:
   - Calculate transport time to primary activity cluster
   - Consider transport reliability and frequency
   - Factor in children's reduced effective activity time (travel time = lost activity time)
   - Note if transport requires multiple transfers (especially challenging with children)

### Phase 7: Itinerary Proposal Generation

**Objective**: Synthesise research into actionable plan recommendations at the destination level

**Alternative Plan Approach:**

Based on Phase 4 Section 2 value assessment and Phase 6 accommodation strategies, generate detailed itineraries for plans that warrant presentation (comparable value ~90%+ or potential 150%+ for specific interests). For each plan presented, provide day-by-day recommendations showing how that strategy works. If alternatives don't meet value threshold, present single primary plan with brief note that alternatives were considered but offer limited value. Per-day alternatives can be provided when day-level choices have comparable value (e.g., "Day 3 Option A: Edinburgh" vs "Day 3 Option B: Glasgow day trip").

**Output Style Requirements:**

The recommendations generated in this phase should be **flexible and adaptive**, not pedantic or overly precise. Do NOT create rigid minute-by-minute schedules. Instead:
- Provide time ranges and estimates (e.g., "morning", "afternoon", "around 15:00") rather than exact timestamps
- Focus on activity clusters and options rather than strict sequencing
- Emphasise flexibility and adaptability
- Present information that supports decision-making, not a script to follow
- Recognise that travel is dynamic and plans will change

The detailed research from previous phases provides the knowledge foundation, but the output should reflect the reality that travel is hectic and unpredictable. The goal is to provide useful guidance, not perfect orderliness.

**Avoid Pushing Work Back to User:**

Do NOT include generic advice that pushes research back to the user, such as:
- ❌ "Many restaurants have Christmas Eve bookings - reserve in advance if preferred"
- ❌ "Research dining options in the area"
- ❌ "Check venue websites for opening hours"

Instead, DO the research and provide specific actionable information:
- ✓ "Christmas Eve dining options near George Street: The Ivy (takes bookings, Scottish menu), Dishoom (walk-ins accepted, Indian), Wagamama (open until 22:00, family-friendly)"
- ✓ "Camera Obscura confirmed open Dec 24 until 17:00 (reduced hours), advance booking recommended via website"
- ✓ "National Museum closed Dec 25, reopens Dec 26 at 12:00"

When constraints exist (e.g., limited Christmas Day dining), research WHAT is actually available and WHERE, don't just note that it's limited. When you can't access information, such as anti-bot by the hotels, tersely mention it rather than just asking users to work.

1. **Day-by-Day Activity Recommendations**
   
   For each day in the journey:
   
   a. **Check for Fixed Commitments First**
      - Check if this day has existing event bookings (conferences, timed attractions)
      - Check which travellers are present on this day (account for split travel patterns)
      - Note if day is arrival day or departure day (special timing constraints)
   
   b. **Match Activities to Days**
      - **If event exists**: Plan activities around event timing and location
      - **If seasonal festival exists**: Prioritise attending festival on appropriate day
      - **If arrival day**: Apply arrival day strategy from Phase 3
      - **If departure day**: Apply departure day strategy from Phase 3
      - **If conference day**: Minimal additional activities (conference attendees may be busy all day; non-attendees can have separate plans)
      - Assign activity clusters to specific days
      - **Match activities to days when they're open**: Use day-of-week activity matrix from Phase 4
        - "Monday: Aquarium closed → playground day"
        - "Tuesday: Aquarium open → aquarium + nearby activities"
      - Consider day of week (museum closures, weekend crowds, market days)
      - Balance high-energy and low-energy days
      - **Consider seasonal daylight constraints**: Winter activities must finish before early sunset
      - **Account for traveller composition on this specific day** (may differ from other days)
   
   c. **Estimate Daily Timeline**
      - **If arrival day**: Follow arrival day strategy (night/afternoon/morning)
      - **If departure day**: Follow departure day strategy
      - Morning routine time (with children: ~3 hours before departure)
      - Travel to activity cluster (or to conference venue if applicable)
      - Activity duration (with children: max 1.5-2 hours before rest; with conference: minimal)
      - **Consider sunset time**: Winter activities must conclude before dark (sunset may be 16:00-17:00)
      - Return to hotel for rest (if children present)
      - Optional second outing (if energy permits and daylight available)
      - Evening settling time (with children: significant time needed)
      - **Note seasonal festivals and events scheduled for this day**
      - **Note separate plans for split travellers** (e.g., "Parent at conference, other parent with children visiting aquarium")
      - **IMPORTANT**: Present these as flexible time estimates and general patterns, NOT rigid minute-by-minute schedules. Use ranges and approximate times (e.g., "morning", "early afternoon", "around 15:00") rather than precise timestamps.
   
   d. **Provide Booking Guidance**
      - List activities requiring advance booking
      - Note booking URLs or methods
      - Indicate recommended booking timeline
      - **Note which travellers each booking is for** (important when travellers split)

2. **Accommodation Recommendations**
   
   For each accommodation decision:
   
   a. **Check Current Booking Status**
      - If accommodation already booked for these dates:
        - Note the actual hotel in recommendations
        - Compare to any previous suggestions
        - Explain any implications of the choice (if different from suggestion)
        - Mark as "☑ Booked" in to-do section
      - If accommodation not yet booked:
        - Present as active to-do item
        - Mark as "☐ To book" in to-do section
   
   b. **Present Options** (for unbooked accommodations)
      - List 2-3 viable options with pros/cons
      - **Highlight primary suggestion** (this becomes the to-do item)
      - Format: "Primary suggestion: Hotel A (IHG): [location description], [distance to cluster], [upgrade potential]. Pros: [list]. Cons: [list]. Alternative: Hotel B [brief description]."
      - Include fallback options when primary choice has limitations
   
   c. **Explain Reasoning**
      - Why this location was selected
      - How it serves the activity clusters
      - What trade-offs were considered
      - Transport accessibility notes
   
   d. **Update for Actual Bookings**
      - If hotel was booked differently than suggested:
        - Update all itinerary references to actual hotel
        - Update location-based recommendations if hotel location differs
        - Update transport accessibility notes if needed
        - Re-evaluate activity clusters if hotel location significantly different

3. **Integration with Existing Bookings**
   
   **Update Mode (90% of cases):**
   - Preserve existing bookings
   - Build activity recommendations around confirmed accommodations
   - Propose accommodation changes ONLY if existing bookings are poorly positioned
   - Explain why changes are suggested (if proposing changes)
   
   **Creation Mode (10% of cases):**
   - Propose complete accommodation strategy
   - Prioritise IHG options where feasible
   - Present alternatives with clear reasoning

### Phase 8: Document Integration Preparation

**Objective**: Prepare structured recommendations for integration into the itinerary document

1. **Structure Recommendations**
   
   Prepare content in format ready for Procedure 3:
   
   a. **Event Anchors Summary**
      - List all confirmed events with dates, times, locations
      - **List seasonal festivals and limited-time events** (Christmas markets, New Year's parties, etc.)
      - Note which travellers are attending each event
      - Explain how these events anchor the itinerary
   
   b. **Activity Clusters Summary**
      - Cluster name and location
      - Activities within cluster
      - Relationship to event anchors (if applicable)
      - Estimated time requirements
      - Booking requirements
   
   c. **Accommodation Strategy Summary**
      - Recommended accommodations with reasoning
      - Explanation of conference/event proximity (if applicable)
      - Transport accessibility notes
      - IHG upgrade potential notes (when applicable)

   d. **Regional Transport Mode Decision** (from Phase 4 Section 2f)
      - Document the conclusion about car rental vs public transport for this destination
      - Include explicit reasoning based on regional accessibility research
      - This demonstrates the transport strategy was evaluated, not overlooked

   e. **Day-by-Day Plan Outline**
      - Daily activity assignments
      - Fixed commitments per day (events, arrival/departure, seasonal festivals)
      - **Operating day alignments** (activities scheduled for days when they're open)
      - **Seasonal considerations** (daylight constraints, weather appropriateness)
      - Traveller composition per day (note if split)
      - Transport considerations
      - Energy/time constraints (especially for children)

2. **Flag Items Requiring Booking**
   - List accommodations that need to be booked
   - List activities requiring advance tickets
   - Note priorities and deadlines

### Checkpoint: Itinerary Planning Complete

All research phases completed: traveller composition identified, event anchors categorised, seasonal context established, activities clustered geographically with operating schedules verified, accommodation strategy developed (IHG prioritised for children, conference proximity where applicable), day-by-day recommendations prepared, update mode respected.

**Critical quality requirements verified:**
- Seasonal festivals researched with **specific dates** (not "likely open", but "open Dec 1-24, CLOSES Dec 30")
- Weekly closure patterns documented with **day-of-week mapped to travel dates** (not "Monday closures", but "Dec 29 is Monday - Museum X CLOSED")
- Operating hours researched with **date-specific schedules** (not "special Christmas hours", but "Dec 24: 10:00-14:00, Dec 25: CLOSED, Dec 26: 10:00-18:00")
- Activity costs documented with **children's pricing details** (not "~€20-25", but "Adults €23, Children 4-14 €12, Under-4 free")

## Procedure 2: Mental Journey Simulation and Completeness Evaluation

### Purpose

Validate the itinerary by walking through it as if you are the traveller. This procedure delegates to a separate Mental Journey Simulation SOP that produces a narrative walkthrough revealing gaps, timing issues, and logistical problems.

### Input

- Previous or existing itinerary document from journey folder
- Journey folder path

### Output

- Journey narrative identifying issues
- Categorised list of problems (Critical/Significant/Minor/Verify)
- Recommendations for fixes

### Execution

**Step 1: Launch Mental Journey Simulation**

Run the mental journey simulation SOP on the current itinerary:

```bash
claude -p "Follow travel/sop-mental-journey-simulation.md to simulate the journey in [JOURNEY_FOLDER_PATH]/[Itinerary-File].md" --allowedTools "Read,Glob,Grep,WebSearch,WebFetch" --permission-mode acceptEdits
```

Replace `[JOURNEY_FOLDER_PATH]` with the actual journey folder path.

**Step 2: Review Simulation Output**

The simulation produces:
- **Journey Narrative**: Story-format walkthrough from traveller's perspective
- **Issues Summary**: Problems categorised by severity
- **Verdict**: GREEN (minor issues only) / YELLOW (significant but sound) / RED (critical problems)

**Step 3: Iterate Until Reasonably Good**

If the simulation verdict is RED or YELLOW with critical issues:

1. Address the critical issues identified in the simulation
2. Update the itinerary with fixes (missing bookings noted, timing adjusted, etc.)
3. Re-run the mental journey simulation
4. Repeat until verdict is GREEN or YELLOW with only acceptable issues

**Iteration Stopping Criteria:**
- All CRITICAL issues resolved or documented as to-do items
- SIGNIFICANT issues either resolved or have clear mitigation plans
- Verdict is GREEN, or YELLOW with justified remaining issues

**Step 4: Extract Findings for Procedure 3**

From the final simulation, extract:
- Gaps requiring booking (add to Completeness Checklist)
- Timing issues (note in day-by-day timeline)
- Verification items (add to checklist)

### Issue Categories (from Simulation SOP)

**Critical** - Journey may fail:
- Missing transport/accommodation booking
- Impossible connection

**Significant** - Major discomfort/risk:
- 4+ hours without food for children
- Midnight hotel arrival with children
- Activity during closure hours

**Minor** - Inconvenience:
- Early hotel arrival before check-in
- Tight but achievable connection

**Verify** - Confirmation needed:
- Operating hours not confirmed
- Booking status unclear

### Checkpoint: Mental Journey Simulation Complete

Simulation run at least once, critical issues addressed or documented, findings extracted for integration into the itinerary.

## Procedure 3: Itinerary Document Creation/Update with Completeness Assessment

### Purpose

Create or update the comprehensive itinerary document within the journey folder, integrating completeness findings from mental journey simulation with detailed travel information. The document serves as the definitive reference for travellers, synthesising gap analysis, booking recommendations, transportation overview, and day-by-day timeline into one cohesive resource.

### Input

- All travel documents from journey folder (Fares, Accommodations, Passes)
- Results from Procedure 1 (Itinerary Creation and Planning)
- Results from Procedure 2 (Mental Journey Simulation and Completeness Evaluation)
- Results from folder management email checking (including missing invoice identification)
- Existing itinerary document (if present, for revision)

### Output

Itinerary markdown file in the journey folder, containing integrated completeness assessment and comprehensive travel timeline. Filename follows the convention: `[Start Date] - [End Date] [Destination]_Itinerary.md`

### Process Overview

This procedure generates or updates the itinerary document through a holistic revision approach:

1. **If the document already exists**: Read the existing contents first, then rewrite it to ensure a single, cohesive narrative. Every update must be integrated as if it were part of the original design. Eliminate any transitional phrasing like "Update:" or "New:".

2. **If the document does not exist**: Generate the complete document from scratch based on current folder contents and evaluation results.

This approach ensures the document remains an elegant, authoritative source of truth, rather than an accumulation of patches. Documentation of the "planning history" is prohibited.

### Document Structure

The itinerary document comprises three integrated components:

---

#### Component 1: Completeness Checklist

This section appears at the beginning of the document and provides a concise assessment of travel readiness, identified gaps, and action items.

**Purpose**: Enable quick identification of what requires attention versus what is complete.

**Conciseness requirement**: Under half a page total (approximately 10 items maximum)

**Content to include:**

1. **Missing Bookings** (Genuine gaps - High Priority):
   - List critical missing bookings requiring immediate action
   - Include date ranges and destination information
   - **Include specific hotel suggestions with reasoning**
   - Example: "☐ Book accommodation in Lisbon (Nov 17-18) - Suggested: InterContinental Lisbon (IHG Platinum upgrade potential, near conference venue, 15-min walk to MEO Arena)"
   - **Format for unbooked accommodations**: "☐ Book [Hotel Name] for [dates] - [brief reasoning]"
   - **Note**: The ☐ checkbox indicates "not yet complete" status. Once booked, this item should be REMOVED from the checklist entirely, and the booking should be integrated into the main itinerary timeline.

3. **Verification Items** (Medium Priority):
   - Transport methods requiring confirmation (e.g., ground transport between airports, hired car date alignment)
   - Timing concerns that need investigation
   - Date alignment issues requiring verification
   - Example: "Verify hired car booking covers Sofia to Skopje travel on Nov 22"

3. **Acceptable Gaps with Notes** (Low Priority):
   - Gaps that are contextually reasonable but worth documenting
   - Include brief rationale for why the gap is acceptable
   - Example: "Ground transport Abu Dhabi (AUH) to Dubai (DXB) - airports 100km apart, can arrange on arrival or pre-book taxi"

4. **Missing Invoices** (from folder management email checking):
   - List booking references lacking email confirmations
   - Note provider name (airline, hotel, etc.)
   - Example: "Missing invoice for Ryanair booking DTF7HZ - check alternative email addresses or contact airline"

5. **Booking Guidance** (if gaps require booking):
   - Brief notes on options and considerations
   - Format: "To book X, you need to do Y. Options: A (pros/cons), B (pros/cons), C (pros/cons)"
   - Keep concise, focus on actionable next steps

**Contextual Assessment Integration:**

For each item, include brief contextual reasoning:
- **Geographic context**: Airport proximity, regional travel patterns
- **Temporal context**: Time of day, timing adequacy, buffer requirements
- **Traveller composition**: Consider children, elderly, special needs when assessing transport appropriateness
- **Severity categorisation**: Use priority levels (High/Medium/Low) to guide attention

**Granularity matching**: If travel is simple (round trip, one destination), keep checklist minimal. If travel is complex (multi-city, multiple transport modes, events), provide more detail where needed, but still respect the half-page constraint.

---

#### Component 2: Key Transportation Segments Table

This table provides a high-level overview of all intercity travel, enabling quick reference to major movements between locations.

**Purpose**: Show the journey's transportation backbone without day-by-day detail.

**Format**:

| Date | Departure Time | Origin (Location) | Arrival Time | Destination (Location) | Transport Type | Booking Reference | Notes |
|------|----------------|-------------------|--------------|------------------------|----------------|-------------------|-------|

**Content guidelines:**

- Include ALL intercity transportation in chronological order:
  - Flights (include flight numbers)
  - Trains (include train numbers if available)
  - Buses, ferries, hired car segments between cities
  - Ground transport between airports (if different airports in different cities)

- Note special requirements:
  - Visa requirements
  - Long layovers (specify duration)
  - Terminal changes
  - Border crossings

- **Verification approach**: Cross-check this table against the Completeness Checklist. Ensure all cities mentioned in the checklist appear as destinations in this table. If a city is mentioned but not in the table, it indicates a missing transport segment (genuine gap).

**Example row**:
```
| 2025-11-15 | 14:20 | Seville (SVQ) | 16:05 | Porto (OPO) | Flight - Ryanair | DTF7HZ | Check-in baggage included |
```

---

#### Component 3: Day-by-Day Itinerary

This section provides a flexible daily guide organized around key events and feasibility windows, NOT a minute-by-minute schedule.

**Purpose**: Serve as a flexible reference that helps travellers make decisions during the journey by providing context, options, and feasibility windows rather than a rigid timeline to follow.

**Critical Output Style Requirement:**

**ABSOLUTELY DO NOT create schedules like this (BAD EXAMPLE):**
```
❌ BAD - Too rigid and pedantic:
**13:00-13:30** - Airport transfer to city centre
**13:30** - Arrival at hotel
**13:30-15:00** - Hotel check-in or lunch
**15:00-15:30** - Walk to market
**15:30-17:00** - Market visit
**17:00** - Return to hotel
**18:00-19:30** - Dinner
**19:30-21:00** - Bedtime routine
```

This minute-by-minute format suggests strict orderliness and perfectionism that doesn't match the reality of hectic travel with children.

**INSTEAD, create schedules like this (GOOD EXAMPLE):**
```
✓ GOOD - Flexible and realistic:
**Flight Arrival**
- Arrive Edinburgh 12:40
- Airport exit and transfer to city centre (~30 min)
- Arrive hotel: early-mid afternoon

**Afternoon**
Hotel check-in (standard: 15:00) - if room not ready, store luggage and have lunch nearby

**Afternoon/Evening Options**
Once settled at hotel, options for remainder of day include:

Christmas Market (Princes Street Gardens)
- Walking distance from suggested hotel (~5 min walk)
- Open until 22:00
- Traditional market stalls + family funfair zone
- Recommended duration: 1-1.5 hours maximum (light first day after travel)

OR

- Rest at hotel (valid choice after long travel day with children)
- Early dinner near hotel and prepare for tomorrow

**Evening**
Early dinner and bedtime routine (children need good rest after travel day)
```

**Key Principles:**
- Use broad time blocks: Morning / Afternoon / Evening, NOT 30-minute increments
- Present OPTIONS, not sequential steps
- Emphasize FLEXIBILITY and ADAPTABILITY
- Acknowledge that plans WILL change based on energy, weather, children's moods

**IMPORTANT EXCEPTIONS - When to Use Exact Times:**
- ✓ Booked transport: Flights, trains, buses (show exact departure/arrival times)
- ✓ Timed events: Ballet, concerts, museum bookings with specific entry times
- ✓ Critical deadlines: "Must leave hotel by 05:15 to catch 07:15 flight"
- ✓ Venue opening hours: "Museum opens at 10:00, closes at 17:00"

For everything else (transfers, walks, meals, rest periods, estimated arrivals), use flexible time blocks and ranges.

**Structure for each day:**

**Date and Location Header**
- Date (e.g., "**November 15, 2025 - Seville to Porto**")
- Primary location(s) for the day
- Indicate if it's a travel day (multiple locations) or stationary day (one location)

**Daily Structure: Organized by Time Blocks and Activity Clusters**

Present each day using broad time blocks (morning/afternoon/evening) with activity clusters and options, rather than detailed chronological timestamps. Only show exact times for confirmed bookings (flights, trains, event tickets).

**Confirmed Bookings (Show Exact Times):**

For flights, trains, and booked events with fixed times:
- State exact departure and arrival times
- Include booking references
- Note operational requirements (check-in times, baggage allowances, special requirements)

**Accommodations:**
- Hotel name and address
- Standard check-in/check-out times
- Describe arrival time in broad terms (e.g., "late afternoon after 16:05 flight arrival") rather than calculating precise timestamps
- Note any special arrangements (late check-in, early departure)

**Activities and Attractions:**
- List activities within time blocks (morning/afternoon/evening)
- Present as **options and clusters** rather than sequential steps
- Note key constraints:
  - Opening hours (so travellers can check on the day)
  - Booking requirements (if advance tickets needed)
  - Typical duration (to gauge feasibility)
  - Proximity to hotel or other activities (walking distance, transport time range)
- Use language like: "Options for afternoon include...", "Consider visiting...", "If energy permits..."

**Transport Between Activities:**
- Describe transport broadly (e.g., "5-minute walk", "15-20 minute taxi ride", "accessible by metro")
- Don't calculate arrival/departure times for every movement
- Note if transport needs booking in advance vs. available on-demand

**Airport/Station to Hotel Transport (Arrival Days):**
- Include the transport evaluation and reasoning from Procedure 2, Section 5 (Airport-to-Hotel Transport Evaluation)
- Present multiple options with costs and a recommended option based on family logistics
- Include explicit reasoning for the recommendation (hotel location, luggage handling, cost comparison, traveller composition)
- This demonstrates that practical travel logistics were considered, not just default assumptions

**Feasibility Window Approach:**

Instead of calculating precise timestamps, establish feasibility windows that show what's realistic:

**For Arrival Days:**
- **Morning arrival** (before 12:00): "Afternoon available for activities after hotel check-in (typically 15:00)"
- **Afternoon arrival** (12:00-18:00): "Evening activities possible if energy permits"
- **Evening arrival** (after 18:00): "Proceed to hotel, minimal additional activities"

**For Full Activity Days:**
- Group activities into **morning** / **afternoon** / **evening** blocks
- Within each block, list feasible activities and options
- Note constraints (opening hours, daylight hours, energy levels)
- Emphasize that sequencing within blocks is flexible

**For Departure Days:**
- **Morning departure** (before 12:00): "Minimal activities, focus on departure"
- **Afternoon departure** (12:00-18:00): "Morning activities near hotel possible"
- **Evening departure** (after 18:00): "Full day activities possible before departure"

**Example Feasibility Presentation:**

```
Flight arrival: 16:05
→ Estimated arrival at hotel: late afternoon (around 17:00-18:00 accounting for airport exit and transfer)
→ Evening: Light activity possible if energy permits - Christmas market within walking distance, open until 22:00

Options for evening:
- Visit Christmas market (5-minute walk, 1-1.5 hours)
- Dinner near hotel and early rest
- Rest at hotel (long travel day with children)
```

**Key Principle:** Present what's feasible and what options exist, not a step-by-step timeline. Let travellers make real-time decisions based on actual energy, weather, and circumstances.

**Full Day Example Format:**

```
### December 24, 2025 (Tuesday) - Full Activity Day in Edinburgh

**Confirmed Transport:** None (stationary day)

**Morning (08:00-12:00)**
- Morning routine with children (typically ~3 hours with breakfast and preparation)
- Depart for Royal Mile area when ready

**Morning/Early Afternoon Activity Options - Royal Mile Cluster**

Camera Obscura & World of Illusions (549 Castlehill)
- Interactive exhibits suitable for children
- Typical visit: 1.5 hours
- Note: Verify Christmas Eve opening hours (may have reduced hours)
- Walking distance from suggested hotel (~10 minutes)

After Camera Obscura, options include:
- Walk along Royal Mile (historic street with Christmas decorations)
- Lunch at child-friendly cafe/restaurant on or near Royal Mile
- Note: Edinburgh Castle CLOSED (Dec 18 - Jan 4)

**Midday**
- Return to hotel for rest period (critical for children after 1.5-hour morning activity)
- Walk back: ~10 minutes
- Rest: 30+ minutes recommended

**Afternoon Activity Options - Old Town Cluster**

National Museum of Scotland (Chambers Street)
- Free admission
- Child-friendly areas: interactive exhibits, giant hamster wheel, Scottish history
- Indoor activity (good as daylight fades after 15:45 sunset)
- Typical visit: 1-1.5 hours (select specific galleries)
- Important: Verify Christmas Eve hours (may close early)
- Walking distance from hotel (~15 minutes)

**Evening**
- Return to hotel by late afternoon/early evening (dark after 15:45 sunset)
- Rest period
- Christmas Eve dinner - consider booking in advance (popular evening)
- Hotel settling and bedtime routine

**Key Constraints:**
- Sunset: 15:45 (plan outdoor activities before this time)
- Both activities in same geographic cluster (Royal Mile/Old Town)
- Children's stamina: max 1.5-2 hours per activity with rest between
```

This example shows activities grouped by time blocks with options, constraints noted, and flexible language rather than minute-by-minute scheduling.

**Free Time vs Gaps:**
- **Free time**: Clearly mark intentional periods with no planned activities (e.g., "Free afternoon - consider exploring Ribeira district")
- **Gaps**: Distinguish from free time by noting uncertainty (e.g., "Gap: No accommodation booking for this night - see Completeness Checklist")

**Daily Integration with Completeness Checklist:**

Reference completeness items within day-by-day timeline where relevant:
- If a gap exists on a specific day, note it inline (e.g., "**Gap**: Transport from Abu Dhabi to Dubai - see Completeness Checklist for options")
- If booking guidance is needed, reference briefly (e.g., "Accommodation needed - see Completeness Checklist for options under consideration")

This integration ensures the day-by-day view and the completeness assessment are not disconnected, providing context for gaps directly where they occur in the timeline.

---

### Implementation Steps

1. **Read Existing Itinerary Document (if present)**
   - Extract current completeness checklist
   - **Note which items are marked complete (☑) vs incomplete (☐)**
   - Note current transportation table
   - Note suggested accommodations vs actual bookings
   - Review day-by-day timeline
   - Identify what has changed since last RUN (new bookings, resolved gaps, new gaps)

2. **Cross-Reference Suggestions with Current Folder State**
   - **For each accommodation to-do from previous RUN**:
     - Check if accommodation now exists in Accommodations folder
     - If booked (exactly as suggested): Mark to-do as complete (☑)
     - If booked (different hotel): Mark to-do as complete (☑), note the actual booking
     - If still unbooked: Keep as active to-do (☐), review if suggestion still appropriate
   - **For other to-do items** (transport, activities):
     - Check if now booked/resolved
     - Update status accordingly

2. **Synthesise Completeness Findings**
   - Compile activity and accommodation recommendations from Procedure 1 (itinerary creation and planning)
   - Compile gaps from Procedure 2 (mental journey simulation)
   - Compile missing invoices from folder management email checking
   - Categorise by priority (High/Medium/Low)
   - Draft booking guidance for genuine gaps

3. **Update Completeness Checklist**
   - If revising existing checklist:
     - **Mark complete (☑) items that were suggestions but are now booked**
     - Remove fully resolved items that need no further tracking
     - Add newly identified gaps as active to-dos (☐)
     - Update status of verification items
     - **If actual booking differs from suggestion**: Mark complete but note the difference
   - If creating new checklist:
     - Start with High Priority items (missing accommodations, critical bookings)
     - **Format unbooked items with ☐ checkbox**
     - Add Medium and Low Priority items
     - Ensure under half-page constraint

4. **Generate/Update Transportation Table**
   - Extract all intercity transport from Fares folder
   - Verify chronological order
   - Cross-reference against completeness checklist (ensure all destination cities appear)
   - Add any notes (layovers, special requirements)

5. **Generate/Update Day-by-Day Timeline**
   - For each day, extract relevant bookings (flights, accommodations, events)
   - **Use actual accommodation bookings** (not suggestions, if bookings exist)
   - Calculate estimated timestamps using methodology
   - **If actual hotel differs from original suggestion**: Update activity recommendations and transport plans to reflect actual hotel location
   - Integrate gaps inline with references to checklist
   - Mark free time vs uncertain gaps clearly

6. **Write/Update Itinerary Document**
   - Assemble all three components in order
   - Ensure completeness checklist references are consistent with day-by-day timeline
   - Verify transportation table matches timeline
   - Save to journey folder root

### Checkpoint: Itinerary Document Complete

Existing itinerary reviewed, to-do items updated (☑ for booked, ☐ for pending), accommodation reflects actual bookings, day-by-day timeline uses actual hotel locations, completeness checklist integrated (concise, under half page), transportation table complete with all intercity segments, gaps referenced inline, document saved.

**Critical output quality verified:**
- Day-by-day section uses **actual calendar dates** (not "Day 1, Day 2", but "December 26, 2025 (Friday), December 27, 2025 (Saturday)")
- Seasonal events documented with **specific closure dates** (not "some markets close Dec 24-25", but "Alexanderplatz market: Nov 24-Dec 30, CLOSES Dec 30 - last day for Dec 29 travelers")
- Activity operating hours include **date-specific schedules** mapped to actual travel dates
- Accommodation to-do items include **specific hotel names with reasoning** (not "book accommodation", but "Book InterContinental Berlin - near Alexanderplatz, IHG Platinum upgrade potential")
- Transport costs documented as **family totals with children's fare policies** (not "€9.50/adult", but "€12.30/adult, children 6-14 free with adult pass, family of 4 = €24.60/day")

## Procedure 4: Quality Control Checklist and Iteration

### Purpose

Verify that the generated itinerary meets all quality standards and completeness requirements. If any checklist item fails, iterate on the itinerary until all items pass. This procedure ensures that implicit requirements from earlier procedures actually manifest in the final output.

### Input

- Completed itinerary document from Procedure 3
- Research and analysis from Procedures 1 and 2

### Output

- Verified itinerary that passes all QC checklist items
- OR: Revised itinerary with failures corrected

### Quality Control Checklist

Review the generated itinerary against each item below. For each item, verify PASS or identify FAIL with specific gap.

#### 1. Role Fulfillment - Creator vs Advisor

☐ **Itinerary provides complete information, not advisory placeholders**
- PASS: Contains actual recommendations with reasoning ("Take S-Bahn because..." or "Stay at Hotel X because...")
- FAIL: Contains advisory language ("Consider checking...", "You should research...", "Verify hotel distance from station")
- If FAIL: Replace all advisory language with researched information and clear recommendations

#### 2. Transport Mode Decision - Car Rental

☐ **Car rental vs public transport decision is explicitly documented with reasoning**
- PASS: Itinerary contains a statement like "Car rental not recommended: [City] has excellent public transport..." OR "Car rental recommended: Attractions spread across region..."
- FAIL: No mention of whether car was considered, or only mentions public transport options without explaining why car wasn't chosen
- If FAIL: Add transport mode decision section with reasoning based on Phase 4 Section 2 research
- Location: Should appear in "Seasonal Context" or "Transport Strategy" or "Accommodation Strategy" section

#### 3. Airport/Station-to-Hotel Transport Reasoning

☐ **Arrival transport includes recommendation with comparative reasoning**
- PASS: States recommended option AND explains why (hotel distance from station, cost comparison for family, luggage considerations)
- EXAMPLE PASS: "Take S-Bahn (€20 for family). Recommended as hotel is 3-min walk from station exit, making this more practical than taxi (€45) despite family with luggage."
- FAIL: Just lists transport options without recommendation, OR gives recommendation without reasoning
- If FAIL: Add reasoning that demonstrates mental journey evaluation (cost per family, hotel location, luggage handling)

#### 4. Events and Festivals

☐ **Seasonal events/festivals are documented, OR absence is explicitly stated**
- PASS: Lists events found ("Christmas markets open Dec 1-24 at...") OR states "No major events or festivals scheduled during [dates]"
- FAIL: No mention of events at all (ambiguous whether researched or overlooked)
- If FAIL: Add explicit statement about events research findings

#### 5. Hotel Location Specificity

☐ **Hotel recommendations include specific location details relative to transport**
- PASS: "Hotel X is 5-min walk from U-Bahn exit" OR "Hotel Y requires 15-min walk uphill from nearest station"
- FAIL: "Hotel accessible by public transport" (vague, requires user to look up)
- If FAIL: Research and add specific walking distances/times from transport to recommended hotels

#### 6. Activity Operating Hours and Closures

☐ **Weekly closure patterns documented and activities scheduled accordingly**
- PASS: "Museum A CLOSED Mondays - scheduled for Tuesday" with Monday-appropriate alternative activities identified
- FAIL: Suggests Monday museum visit without noting Monday closure, OR doesn't plan for Monday closures
- If FAIL: Cross-check all suggested activities against day-of-week, add closure notes, reschedule conflicts

#### 7. Cost Information Completeness

☐ **Transport and activity costs provided for family budgeting**
- PASS: "ABC day ticket €12.30/adult, family of 4 = €24.60/day" with children's fare policy noted
- FAIL: "Day tickets available" without cost information
- If FAIL: Research and add actual costs researched during planning

#### 8. Booking Requirements Clarity

☐ **Pre-booking requirements stated with specific instructions**
- PASS: "Reichstag Dome requires booking 2-4 weeks advance at bundestag.de" with exact URL and timeline
- FAIL: "Reichstag requires advance booking" (when? where? how far ahead?)
- If FAIL: Add specific booking timelines, URLs, and procedures

#### 9. Seasonal Appropriateness

☐ **Activities appropriate for season with daylight constraints noted**
- PASS: "Sunset 15:52 - outdoor activities must finish by 15:30" with schedule adjusted accordingly
- FAIL: Outdoor evening activities scheduled for 17:00 in winter without noting sunset at 16:00
- If FAIL: Add sunset/sunrise times, adjust activity timing to match daylight availability

#### 10. Family Logistics (if children present)

☐ **Child-specific considerations integrated into timing and activity selection**
- PASS: "Return to hotel for 30-min rest between morning museum (2 hours) and afternoon activity"
- FAIL: Schedules 4 consecutive hours of activities without rest breaks noted
- If FAIL: Add rest periods, adjust activity durations, note child-friendly facilities

### Iteration Process

1. **First QC Pass**: Review generated itinerary against all 10 checklist items
2. **Identify Failures**: For each FAIL, note the specific gap (e.g., "Item 2 FAIL: No car rental decision documented")
3. **Revise Itinerary**: Return to itinerary document and add/revise content to address each failure
4. **Second QC Pass**: Re-review revised sections against failed items
5. **Repeat if Necessary**: Continue iteration until all items PASS
6. **Final Verification**: Confirm all 10 items pass before completing procedure

### Checkpoint: Quality Control Complete

All 10 QC items verified PASS, failures corrected through iteration, creator role fulfilled, key decisions documented with reasoning.

## Appendix: Contextual Reasoning Guidelines

### Child-Specific Planning Considerations

When children (Alice and Zoe, or others detected via ticket indicators) are part of the travel party, apply the following planning principles:

#### Daily Time and Energy Constraints

**Morning Routine:**
- Children often require ~3 hours from waking to being ready to depart
- Not always, but commonly enough to factor into planning
- Can be shortened in some circumstances, but default planning assumes longer preparation time

**Evening Settling:**
- Significant time required for children to wind down and prepare for sleep
- Reduces effective activity window in the evening

**Effective Activity Time:**
- In a typical 12-hour day (e.g., 7am-7pm), actual exploring time is approximately 4 hours
- Represents roughly one-third of the day
- Remaining time consumed by: morning routine, meals, transport, rest periods, evening routine
- **Important**: Car travel time (e.g., 45-minute drive to another city) should be categorized as transport overhead similar to flights or trains, NOT as a reduction from the 4-hour activity budget. The 4-hour estimate already accounts for children's reduced energy compared to full daylight hours.

**Activity Duration Limits:**
- On-foot activities: Maximum 1.5 hours before children need to return to hotel or at least in car for rest
- Indoor activities: Up to 2 hours possible with appropriate breaks
- Multiple short outings per day more successful than one long outing

#### Hotel Location Strategy

**Core Principle:**
- Hotels should be reasonably close or reasonably accessible to activity clusters
- "Reasonably close" does NOT mean walking distance (often impossible to achieve)
- "Reasonably accessible" means manageable transport time considering children's constraints

**IHG Platinum Membership Benefits:**
- Father has IHG Platinum with suite upgrade potential
- Can book on the day to secure upgrade phone call before arrival
- One guaranteed upgrade per year available
- Suites provide valuable extra space for families with children

**Reality of IHG Availability:**
- IHG hotels are LIMITED in many cities
- Perfect positioning is often not achievable
- Must balance IHG benefits against location suitability

**Hotel Selection Decision Tree:**

1. **Ideal scenario**: IHG hotel reasonably close to primary activity cluster
   - Provides both upgrade potential and location benefits
   - Select this option when available

2. **Common scenario**: IHG hotel reasonably accessible via transport to cluster
   - Example: 20-30 minute train/metro ride to cluster
   - Trade-off: Transport time reduces available activity time
   - Consider whether transport time is acceptable given children's energy constraints

3. **Fallback scenario**: Non-IHG hotel better positioned for clusters
   - When IHG options are poorly positioned or excessively distant
   - Trade-off: Lose Platinum benefits (suite upgrade, points) but gain location benefits
   - Explicitly note this trade-off in recommendations

4. **Multi-location scenario**: Split stay across different areas
   - When city has geographically separated activity clusters
   - Example: Stay in outskirts near cluster A for days 1-2, move to city centre for days 3-4
   - Reduces daily transport burden at cost of hotel change mid-journey

#### Transport Time Impact

**Critical Understanding:**
- Every minute spent on transport is time NOT spent exploring or resting
- Children's limited daily energy makes transport time particularly costly
- Example: 30-minute journey to attraction + 30-minute return = 1 hour lost = 25% of effective activity time

**Transport Evaluation Factors:**
- Distance alone is misleading (Lisbon east to centre: <10km but 30+ minutes)
- Consider: traffic patterns, public transport routes, frequency, transfers required
- Multiple transfers especially challenging with children (coordination, fatigue, potential for issues)

#### Activity Selection and Clustering

**Child-Friendly Activity Categories:**

Priority categories that engage children:
- Castles and fortifications (exploration, imagination, physical activity)
- Natural scenery (parks, beaches, gardens - outdoor play opportunities)
- Aquariums and science museums (interactive, educational, age-appropriate)
- Outdoor attractions (zoos, adventure parks, playgrounds)
- Interactive cultural sites (hands-on museums, child-oriented exhibits)

**Geographic Clustering Principles:**

1. **Cluster Size:**
   - Group activities that can be visited in one outing (1.5-2 hours total)
   - Typically 2-3 activities per cluster, not more
   - Allow return to hotel between clusters for rest

2. **Cluster Accessibility:**
   - Consider transport from hotel to cluster entry point
   - Consider walking distances between activities within cluster
   - Note if cluster requires extensive walking (may need to reduce activity count)

3. **Multi-Day Cluster Approach:**
   - For rich clusters, spread across multiple days
   - Day 1: Visit subset of cluster, return to hotel for rest, optional second outing
   - Day 2: Visit remaining attractions in same cluster
   - Advantage: Children can pace themselves, flexibility for energy levels

#### Booking and Availability Research

For each child-friendly activity identified:

1. **Opening Hours:**
   - Check specific dates of travel
   - Many attractions close one day per week (often Monday)
   - Note any seasonal closures or special event closures

2. **Pre-Booking Requirements:**
   - Timed entry systems (increasingly common post-pandemic)
   - Advance ticket purchase requirements
   - Walk-up availability and queue times
   - Cancellation policies (important with children - illness, fatigue can necessitate changes)

3. **Practical Facilities:**
   - Restroom availability (critical with children)
   - Food/snack options on-site or nearby
   - Stroller accessibility or baby changing facilities
   - Rest areas within venue

#### Example Planning Pattern: Porto (Reference Case)

**Day 1-2: Old City Centre Hotel**
- Walking distance to Ribeira district, monuments, markets
- Short excursions: 1.5 hours to specific attraction, return to hotel
- Second outing after rest: Visit riverside, World of Discovery museum
- All activities within manageable walking distance or short transport

**Day 3-4: South of River Hotel**
- Near Cristo Rei church and south-side attractions
- No need to cross river (avoids 30+ minute transport each way)
- All activities located south of river, clustered around hotel area
- Positioned near train station for departure (avoids final cross-river journey)

**Reasoning:**
- Minimises daily transport burden
- Clusters activities geographically by hotel location
- Allows multiple short outings with hotel rest periods
- Strategic hotel positioning eliminates unnecessary travel on departure day

### Geographic Proximity Judgement

**Close Airports (Ground Transport Expected)**:
- Abu Dhabi (AUH) ↔ Dubai (DXB): ~100km, ground transport expected
- Istanbul Sabiha Gökçen (SAW) ↔ Istanbul Atatürk (IST): ~50km, ground transport expected
- Paris Charles de Gaulle (CDG) ↔ Paris Orly (ORY): ~40km, ground transport expected

**When evaluating gaps**: If travel involves close airports, expect ground transport booking, not a missing flight. Verify ground transport exists or can be arranged.

### Regional Travel Patterns

**Balkan Countries**:
- Multiple cities typically traversed by hired car, not individual flights
- If hired car booking exists, verify it covers the date range of multi-city travel
- Individual flights between Balkan cities are unusual unless distance is significant

**Middle East Connections**:
- Close airports (Abu Dhabi-Dubai) use ground transport
- Research airport transfer services, taxis, or shuttles

**European Inter-City**:
- Train connections common for distances under 500km
- High-speed rail often preferred over flights for environmental and convenience reasons

### Transport Mode Considerations

**Time of Day Factors**:
- Late night arrivals (after 22:00): Public transport may be unavailable, private transfer likely needed
- Early morning departures (before 06:00): May require pre-booked transport or overnight stay near airport
- Rush hours: Add buffer time for ground transport

**Time Zone and Body Clock Factors**:

- When comparing options for travel from A to B, evaluate whether the travel period falls in the traveller's expected sleep window based on their current body clock (often still anchored to the previous city), not only the departure city's local time
- For Weiwu specifically: default to avoiding overnight travel (night trains, overnight buses, red-eye flights) because it is disproportionately tiring and often degrades the following day
- Exception: an overnight-in-local-time journey can be acceptable when it occurs during body-clock daytime (i.e., it is not "overnight" for the traveller)
- Exception: business class (or other lie-flat seating or sleeper berth in a train) can make overnight flights acceptable
- In the itinerary, state the recommendation explicitly and include brief reasoning that references local time and body clock alignment (e.g., "local night, but body-clock daytime")
- If the journey crosses a large time zone gap (rule of thumb: \u2265 5 hours difference between the starting location and destination, or intercontinental travel), add a table that converts each long-haul leg's local departure/arrival times into the traveller's starting time zone ("bio-clock time") so the fatigue impact is explicit

**Traveller Composition Factors**:
- Children: Require car seats, may need more comfortable transport, slower pace
- Elderly: May require assistance, accessible transport, more time
- Large groups: May prefer private transfer over multiple taxis
- Special needs: May require specific transport arrangements

**Distance Factors**:
- Under 50km: Taxi or private transfer typical
- 50-200km: Train or bus may be available and preferred
- Over 200km: Flight more likely, but verify based on regional patterns

### Date Continuity Verification Principles

Even when transport method is reasonable, always verify dates align:

1. **Car Hire**: Start date must be before or on first use; end date must be after or on last use
2. **Hotel Bookings**: Check-in date must align with arrival date (or one day before if early arrival expected)
3. **Event Tickets**: Event date must align with location (traveller must be in that city on that date)
4. **Train Reservations**: Travel date must match train booking date

### Distinguishing Intentional Gaps from Problems

**Intentional Gaps** (Not problems):
- Direct bookings made outside folder system (traveller has confirmation elsewhere)
- Walk-up tickets (standard practice for some transport types)
- Intentional free time (no activities planned, by design)
- Last-minute bookings (traveller handles directly)

**Problems** (Require action):
- Missing accommodation for a night
- Missing critical flight segment with no alternative transport
- Date misalignments that create accommodation gaps
- Timing incompatibilities that prevent successful travel

## RUN Re-runnability Checklist

Verify RUN is properly idempotent: existing itinerary read before updates, valid plans preserved, only needed changes proposed, resolved gaps removed, new gaps added, cancelled bookings excluded, state preserved across runs. First RUN creates complete plan; subsequent RUNs incrementally refine based on new bookings without duplication.

---

**End of Standard Operating Procedure**

