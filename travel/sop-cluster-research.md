# Cluster Research Standard Operating Procedure

**Part of**: `sop-travel-master.md` orchestration system

**Relationship to other SOPs**:
- Orchestrated by: `sop-travel-master.md`
- Consumed by: `sop-itinerary-management.md`
- Input: Journey folder with transport/accommodation bookings

## Purpose Statement

This SOP researches the geographic cluster for a journey and what each destination offers. The output enables the itinerary SOP to schedule across the full cluster with knowledge of attractions, events, and suitability for the travel group.

**What this SOP produces:**

1. **Geographic cluster**: What destinations are accessible from each booked location
2. **What each destination offers**: Attractions, events, experiences ranked by appeal
3. **Suitability assessment**: How well each attraction matches the travel group (children, elderly, interests)
4. **Seasonal context**: Events, operating hours, daylight constraints

**What the itinerary SOP does with this:**

- Schedules which days to visit which destinations
- Groups attractions into daily activity clusters
- Handles logistics (transport, accommodation, timing)

## What is a Cluster?

A cluster is a group of destinations accessible from each other within practical travel time. Examples:

- **City cluster**: Vienna, Budapest, Bratislava - three capitals within 2-3 hours of each other by train
- **Airport-destination cluster**: Glasgow (arrival airport), Edinburgh (destination), Stirling (day trip) - Central Scotland cluster
- **City-region cluster**: Sydney and Blue Mountains - a city with an accessible natural region
- **Multi-city route**: A→B→C where each leg is under 4 hours forms a linear cluster

**Why cluster research matters:**

1. **Arrival ≠ destination**: Flights land where airports are cheap, not necessarily where travellers want to be.

2. **Overnight stays vs day trips**: An overnight stay in a different city requires only one-way travel; a day trip requires round-trip travel. Cities "too far" for day trips become practical as overnight bases.

3. **Regional touring**: Some regions (Scotland, Balkans, Benelux) are best experienced by moving between cities rather than staying in one place.

4. **Activity distribution**: Understanding the cluster enables spreading activities across locations rather than cramming everything into one city.

## Scope

This SOP applies when:
- Creating a new itinerary for a journey
- A destination has multiple nights allocated
- Arrival/departure airports differ from the primary destination city
- The journey involves multiple cities

This SOP does NOT:
- Create day-by-day schedules (itinerary SOP's job)
- Book anything
- Decide which attractions to definitely visit (presents options with suitability ratings)

## Input

- Journey folder path
- Transport bookings (from Fares folder) - reveals arrival/departure points and dates
- Accommodation bookings (from Accommodations folder) - reveals where nights are spent
- Traveller composition (from journey folder name) - adults, children, elderly

## Output

A cluster research document per destination segment, saved to `build/research/[destination]-cluster.md`. For example:
- `build/research/edinburgh-cluster.md` (covers Edinburgh, Glasgow, Stirling)
- `build/research/vienna-cluster.md` (covers Vienna, Budapest, Bratislava)

Each document contains:

1. **Cluster map**: Destinations accessible from the base city
2. **Travel connections**: How to get between cluster members
3. **Seasonal context**: Events, sunrise/sunset, weather considerations
4. **Attractions inventory**: For each destination, attractions ranked by suitability
5. **Transport mode recommendation**: Car vs public transport

---

## Procedure

### Phase 1: Extract Journey Context

**1.1 Read Transport Bookings**

- List all files in Fares folder
- Extract arrival and departure cities/airports
- Extract travel dates (journey start and end)
- Note any intermediate stops

**1.2 Read Accommodation Bookings**

- List all files in Accommodations folder
- Extract cities where nights are spent
- Note duration at each location (number of nights)
- Note if hotels change within a city (indicates flexibility)
- Note cancellation flexibility if visible in booking confirmation

**1.3 Identify Traveller Composition**

Extract from journey folder name (format: `YYYY-MM-DD [Destinations] - [Travellers]`):

- **Adults**: Names other than known children
- **Children**: Look for "Alice", "Zoe", "A-Z" or child indicators in tickets
- **Elderly/mobility constraints**: Note if mentioned or if traveller is known to have mobility issues

This composition affects attraction suitability ratings.

**1.4 Establish Journey Skeleton**

Map the sequence:
```
Arrival [Airport/Station] → City A (n nights) → City B (m nights) → ... → Departure [Airport/Station]
```

Note:
- If arrival airport differs from first accommodation city
- If departure airport differs from last accommodation city
- Total journey duration

**1.5 Determine Season and Daylight**

- **Season**: Winter (Dec-Feb), Spring (Mar-May), Summer (Jun-Aug), Autumn (Sep-Nov)
- **Research sunrise/sunset times** for each destination during travel dates
  - Winter: sunset as early as 16:00-17:00
  - Summer: sunset as late as 21:00-22:00
- This affects viable activity hours

### Phase 2: Research Cluster Members

For each city in the journey skeleton, research what other significant destinations are accessible.

**2.1 Nearby Major Cities (Potential Overnight Bases)**

For each city with 2+ nights allocated:

- Search: "major cities near [City] by train"
- Search: "capital cities near [City]"
- Search: "[City] nearby cities worth visiting"

Document cities within approximately 3 hours by train or 2 hours by car. These are potential overnight excursion destinations.

**Why 3 hours for overnight?** Sleeping in the new city means one-way travel only. A 2.5-hour train journey is impractical for a day trip (5 hours round trip) but reasonable for an overnight.

**2.2 Day Trip Destinations**

For each city:

- Search: "day trips from [City]"
- Search: "places to visit near [City]"
- Search: "[Region] day trips by train/car"

Document destinations within approximately 1-1.5 hours travel. These work for day trips (up to 3 hours round trip is acceptable).

**2.3 Airport Positioning**

For arrival and departure airports:

- Search: "Where is [Airport] located"
- Search: "cities near [Airport]"
- Note if the airport serves multiple cities

This identifies when arrival city ≠ logical first destination.

### Phase 3: Research Travel Connections

For each pair of cluster members, research the practical connection:

**3.1 Train Connections**

- Search: "[City A] to [City B] train"
- Document: journey time, frequency, approximate cost
- Note if direct or requires changes

**3.2 Driving Connections**

- Search: "[City A] to [City B] driving time"
- Document: journey time, route characteristics
- Note if car hire would be beneficial

**3.3 Regional Travel Patterns**

- Search: "is [Region] good for train travel" or "touring [Region] by car"
- Document typical transport mode for the region
- Note any statistics found

**3.4 Transport Mode Recommendation**

Based on cluster geography, conclude:
- **Public transport sufficient**: Good rail connections, compact cluster
- **Car recommended**: Spread out attractions, limited public transport
- **Mixed approach**: Car for some segments, train for others

### Phase 4: Research Seasonal Events

**Critical**: Limited-time seasonal events should be prioritised as they define unique opportunities that won't exist on other trips.

**4.1 Check Major Seasonal Events**

For each cluster member destination, search for events during travel dates:

**Winter (December-February):**
- Christmas markets (dates vary - some close Dec 23, others continue to Jan 6)
- New Year's Eve celebrations
- Winter festivals, ice skating, holiday lights
- Winter sports (if mountains nearby)

**Spring (March-May):**
- Spring festivals, flower displays
- Easter events and markets
- Local cultural festivals

**Summer (June-August):**
- Outdoor music/food festivals
- Extended attraction hours
- Beach and water activities

**Autumn (September-November):**
- Harvest festivals, wine festivals
- Autumn foliage
- Cultural season (opera, theatre)

**4.2 Research City-Specific Events**

For each destination:
- Search: "[City name] events [Month Year]"
- Check city tourism websites
- Note festivals, parades, special exhibitions
- **Flag limited-time events prominently**

**4.3 Holiday Closures**

If travel dates include holidays:
- Search: "what's open in [City] on [Holiday]"
- Research ungated attractions: churches, parks, public squares, outdoor monuments
- Document what IS accessible, not just what's closed

**4.4 Document Findings**

For each destination, create an events section:
```markdown
### [City] - Seasonal Events

**During travel dates ([Start] - [End]):**
- [Event 1]: [Dates], [Location], [Notes]
- [Event 2]: ...

**Holiday considerations:**
- [Holiday]: [What's open/closed]

**No events found**: [If applicable, state this explicitly]
```

### Phase 5: Research Attractions

For each destination in the cluster (including day trips and rebase candidates), research what it offers.

**5.1 Attraction Categories**

Research attractions in these categories:

1. **Unique local landmarks**: Castles, fortifications, UNESCO sites, architectural marvels, natural wonders specific to the region
2. **Distinctive natural scenery**: Parks, viewpoints, beaches, gardens unique to the region
3. **Cultural sites**: Museums, galleries, historic buildings
4. **Interactive experiences**: Hands-on museums, tours, activities
5. **Seasonal experiences**: Christmas markets, festivals, outdoor activities
6. **Generic attractions**: Zoos, aquariums, science museums (note if world-class)

**5.2 Prioritisation Principle**

Prioritise unique local experiences over generic attractions:
- Edinburgh: Arthur's Seat and Forth Bridges (unique) over Edinburgh Zoo (generic)
- Vienna: Schönbrunn Palace (unique) over generic city aquarium
- Include generic attractions only as backup or if world-class

**5.3 For Each Attraction, Research:**

**Basic Information:**
- Name and location
- What it is (brief description)
- Why it's notable (unique features, fame, significance)

**Operating Information:**
- Opening hours (check specific travel dates)
- Weekly closure days (Monday closures common in Europe)
- Seasonal schedule changes
- Holiday hours if applicable

**Booking Requirements:**
- Pre-booking required or walk-up
- Ticket costs (note child pricing)
- Lead time needed

**Practical Details:**
- Typical visit duration
- Indoor/outdoor
- Accessibility (stairs, stroller-friendly)
- Facilities (toilets, food, rest areas)

**5.4 Suitability Rating**

Rate each attraction's suitability for the travel group:

**If children present:**
- ⭐⭐⭐ Highly suitable: Interactive, engaging for children, appropriate duration
- ⭐⭐ Suitable with caveats: Good but may need adaptation (shorter visit, specific areas)
- ⭐ Limited suitability: Primarily adult interest, children may be bored
- 🚫 Not suitable: Age-restricted, too long, no child appeal

**If elderly/mobility constraints:**
- Note accessibility issues
- Flag attractions requiring significant walking/stairs
- Highlight those with good accessibility

**For all groups:**
- Note if attraction is weather-dependent
- Flag if it's a "must-see" vs "nice-to-have"

**5.5 Child-Specific Research (if children present)**

For journeys with children, additional research:

**Child-Friendly Priority Order:**
1. Castles and fortifications (exploration, imagination)
2. Natural scenery with space to run
3. Interactive/hands-on museums
4. Outdoor playgrounds and parks
5. Aquariums, zoos (especially if world-class)
6. Child-oriented shows or events

**Practical for Children:**
- Activity duration: 1.5 hours max before rest needed
- Indoor activities: up to 2 hours with breaks
- Note rest areas, playgrounds, child facilities
- Note child pricing and free ages

**Child-Specific Events:**
- Search: "[City] family events [Month Year]"
- Christmas markets (usually very child-friendly)
- Holiday activities, ice skating
- Museums with children's programs

### Phase 6: Generate Cluster Research Document

Compile all findings into `build/research/[destination]-cluster.md`:

**6.1 Document Structure**

```markdown
# Cluster Research: [Region/Journey Name]

**Journey**: [Start Date] - [End Date]
**Travellers**: [Names and composition]
**Season**: [Season], sunset ~[time]

## Cluster Overview

**Booked destinations**: [List with nights]
**Arrival**: [Airport/Station]
**Departure**: [Airport/Station]

### Cluster Members

| Destination | Type | Travel Time | Why Visit |
|-------------|------|-------------|-----------|
| [City] | Booked (n nights) | - | Primary base |
| [City] | Overnight candidate | 2h train | [Brief reason] |
| [City] | Day trip | 45min | [Brief reason] |

### Transport Mode Recommendation

[Car/Public transport/Mixed] - [Reasoning]

---

## [Destination 1]: [City Name]

### Seasonal Events
[Events during travel dates, or "No significant events"]

### Attractions

#### Must-See (Unique to Region)

**[Attraction Name]** ⭐⭐⭐
- What: [Description]
- Hours: [Operating hours, closure days]
- Duration: [Typical visit time]
- Booking: [Required/Walk-up]
- Cost: [Adult €X, Child €Y or free under Z]
- Suitability: [Why rated this way]

[Repeat for each attraction]

#### Worth Visiting

[Secondary attractions]

#### Backup Options

[Generic attractions for bad weather or when others closed]

### Operating Schedule Summary

| Attraction | Mon | Tue | Wed | Thu | Fri | Sat | Sun |
|------------|-----|-----|-----|-----|-----|-----|-----|
| [Name] | ❌ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

---

## [Destination 2]: [City Name]
[Repeat structure]

---

## Rebase Opportunities

### [City] - Overnight Excursion

**Travel**: [Time] by [mode] from [base city], ~€[cost]
**Why visit**: [What makes it worth an overnight]
**Rebase benefit**: One night here = one-way travel vs round trip for day visit
**Considerations**: [Practical notes]

---

## Day Trip Options

### [Destination] - Day Trip

**Travel**: [Time] by [mode], [round trip time] total
**Why visit**: [What it offers]
**Best for**: [Type of interest/traveller]
**When to go**: [Best day of week considering closures]
```

### Phase 7: Save Output

Save the document to: `[journey-folder]/build/research/[destination]-cluster.md`

Where `[destination]` is the primary city name in lowercase (e.g., `vienna-cluster.md`, `edinburgh-cluster.md`).

For a multi-city journey like `2025-12-23 Edinburgh, Berlin, Munich, Vienna, Warsaw`:
- Run this SOP once per destination segment
- Produces: `build/research/edinburgh-cluster.md`, `build/research/berlin-cluster.md`, `build/research/munich-cluster.md`, `build/research/vienna-cluster.md`, `build/research/warsaw-cluster.md`

Each file is consumed by `sop-itinerary-management.md` when generating the itinerary for that segment.

---

## Example Output

```markdown
# Cluster Research: Central Europe - Vienna Region

**Journey**: 2025-12-31 - 2026-01-05
**Travellers**: Weiwu, Liansu, Alice (age 8), Zoe (age 5)
**Season**: Winter, sunset ~16:15

## Cluster Overview

**Booked destinations**: Vienna (5 nights across 2 hotels)
**Arrival**: Munich (train from Berlin)
**Departure**: Vienna (flight to Warsaw)

### Cluster Members

| Destination | Type | Travel Time | Why Visit |
|-------------|------|-------------|-----------|
| Vienna | Booked (5 nights) | - | Primary base, Austrian capital |
| Budapest | Overnight candidate | 2h 40min train | Hungarian capital, thermal baths |
| Bratislava | Day trip | 1h train | Slovak capital, compact old town |
| Salzburg | Day trip | 2h 25min train | Mozart, Sound of Music |

### Transport Mode Recommendation

**Public transport sufficient**: Vienna region has excellent rail connections. Direct trains to Budapest (hourly), Bratislava (hourly), Salzburg (frequent). No car needed in winter.

---

## Vienna

### Seasonal Events

**During travel dates (Dec 31 - Jan 5):**
- **Schönbrunn Christmas Market**: Open until Jan 6, evening only Dec 31
- **New Year's Concert** (Musikverein): Jan 1, sold out but broadcast on screens
- **Silvesterpfad**: New Year's Eve trail through city centre

**Holiday considerations:**
- Jan 1: Many museums closed, but Schönbrunn Palace open
- Most attractions resume normal hours Jan 2

### Attractions

#### Must-See (Unique to Region)

**Schönbrunn Palace** ⭐⭐⭐
- What: Habsburg imperial summer residence, UNESCO World Heritage Site
- Hours: 9:00-17:00 daily (including Jan 1)
- Duration: 2-3 hours (palace + gardens)
- Booking: Recommended online
- Cost: Adults €24, Children 6-18 €15, Under 6 free
- Suitability: Children's Museum inside specifically designed for ages 4-12. Interactive exhibits let children dress as princes/princesses.

**St. Stephen's Cathedral** ⭐⭐⭐
- What: Gothic cathedral, Vienna's symbol
- Hours: 6:00-22:00 daily
- Duration: 30-60 minutes
- Booking: Not required (tower climb separate)
- Cost: Free entry, tower €6
- Suitability: Quick visit, impressive interior. Tower climb not suitable for young children.

**Natural History Museum** ⭐⭐⭐
- What: World-class natural history collection including dinosaurs
- Hours: 9:00-18:30 (Wed until 21:00), CLOSED TUESDAY
- Duration: 2 hours
- Booking: Not required
- Cost: Adults €16, Under 19 FREE
- Suitability: Excellent for children - dinosaur skeletons, interactive exhibits. Free for children under 19.

#### Worth Visiting

**Prater & Giant Ferris Wheel** ⭐⭐⭐
- What: Historic amusement park with iconic Riesenrad
- Hours: Ferris wheel 10:00-21:45
- Duration: 1-2 hours
- Cost: Ferris wheel Adults €15, Children €7
- Suitability: Children love it. Amusement park rides open in winter.

**Technical Museum** ⭐⭐
- What: Science and technology museum
- Hours: 9:00-18:00, CLOSED MONDAY (except holidays)
- Duration: 2 hours
- Cost: Adults €16, Under 19 FREE
- Suitability: Interactive exhibits, good for children but less unique than Natural History.

#### Backup Options (Indoor/Bad Weather)

**Haus des Meeres** (Aquarium) ⭐⭐
- Generic aquarium but good rainy day option
- Hours: 9:00-18:00 daily
- Cost: Adults €23, Children 6-15 €10

### Operating Schedule Summary

| Attraction | Mon | Tue | Wed | Thu | Fri | Sat | Sun | Jan 1 |
|------------|-----|-----|-----|-----|-----|-----|-----|-------|
| Schönbrunn | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Natural History | ✓ | ❌ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Technical Museum | ❌ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

---

## Rebase Opportunities

### Budapest - Overnight Excursion

**Travel**: 2h 40min by direct train (Railjet), departures hourly, ~€20-40
**Why visit**: Hungarian capital with completely different character from Vienna - thermal baths, ruin bars, Danube views, Hungarian cuisine. Children would enjoy Széchenyi Baths (outdoor pools even in winter).
**Rebase benefit**: One night in Budapest = 2h 40min travel. Day trip would be 5h 20min round trip - impractical with children.
**Considerations**: Hotels change anyway on Jan 1 (Radisson RED → InterContinental). Could stay Budapest night of Jan 1 instead, returning Jan 2. Would add Hungarian capital to trip for cost of train tickets only.

**Budapest attractions (if overnight):**
- Széchenyi Thermal Baths ⭐⭐⭐ - outdoor pools, children love it
- Buda Castle ⭐⭐ - funicular ride up, views
- Central Market Hall ⭐⭐ - food, atmosphere

---

## Day Trip Options

### Bratislava - Day Trip

**Travel**: 1h by train, 2h round trip
**Why visit**: Different country, compact historic centre, castle with views
**Best for**: Half-day excursion, morning in Vienna then afternoon Bratislava or vice versa
**When to go**: Any day (no major Monday closures)

**Bratislava attractions:**
- Bratislava Castle ⭐⭐ - hilltop castle, city views
- Old Town ⭐⭐ - compact, walkable, quirky statues children enjoy
```

---

## Checkpoint: Cluster Research Complete

Cluster research document generated with:
- Journey context established (dates, travellers, season)
- Geographic cluster mapped (nearby cities, travel times)
- Seasonal events researched for each destination
- Attractions inventoried with suitability ratings
- Operating schedules documented
- Rebase opportunities identified with reasoning
- Day trip options documented
- Transport mode recommendation provided

Output saved to `build/research/[destination]-cluster.md` for itinerary SOP consumption.

---

**End of Standard Operating Procedure**

