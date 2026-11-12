# Tax Residency Day Tracking

## Superscript Notation in Travel Folders

Journey folders in `0 Travel Admin/` and `Travel Admin Archive/` use Unicode superscript numbers on a traveller's name to record **that trip's days in a country whose tax authority would treat 183 days in its tax year as residence**, such as Australia or Singapore. Each country's tax year is its own (Australia's runs July 1 – June 30), and every day in the country counts toward that year's total, however short the trip. The superscript is the trip's share of that total, not the total itself, and not the trip's length: the yearly total is calculated separately, from these numbers.

- A single number (e.g. `Name²⁶`) means that many days in the country on this trip.
- A sum (e.g. `Name⁴⁵⁺⁹`) means the trip had a period outside the country mid-trip, splitting the days into separate blocks that together total the sum.
- Folders without superscripts have not yet been annotated; days must be calculated from fare and boarding pass dates in the folder.

Both arrival and departure days count as days in the country (any part-day presence counts).

## How to Calculate Days for a Trip

1. Identify the arrival and departure fares/boarding passes in the journey folder.
2. Count inclusive calendar days between arrival date and departure date.
3. Subtract any days spent outside the country mid-trip (look for side-trip journey folders in the same date range, e.g. a Cusco folder between Cairns arrival and Gold Coast departure).
4. If the trip straddles the start of the country's year, only count the days falling in the target year.
5. The resulting count is what the superscript should show.
