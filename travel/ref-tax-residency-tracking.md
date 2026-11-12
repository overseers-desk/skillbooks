# Tax Residency Day Tracking

## Superscript Notation in Travel Folders

Journey folders in `0. Travel Admin/` and `Travel Admin Archive/` use Unicode superscript numbers on a traveller's name to count **that traveller's days in a country where staying 183 days in the year would make them tax resident**: Australia, and in some years Singapore. The count covers only the year that country's test uses (for Australia, the financial year, July 1 – June 30), so a trip straddling the year boundary counts only the days in the relevant year. It is not the total trip length.

The country is the one among the folder's destinations where the traveller stayed long enough for the count to matter; in `Alex⁴⁹ - Singapore` it is Singapore, in `Alex²⁶ - Gold Coast` Australia.

- A single number (e.g. `Alex²⁶`) means that many days in the country during the year.
- A sum (e.g. `Alex⁴⁵⁺⁹`) means the trip had a period outside the country mid-trip, splitting the days into separate blocks that together total the sum.
- Folders without superscripts have not yet been annotated; days must be calculated from fare and boarding pass dates in the folder.

Both arrival and departure days count as days in the country (any part-day presence counts).

## How to Calculate Days for a Trip

1. Identify the arrival and departure fares/boarding passes in the journey folder.
2. Count inclusive calendar days between arrival date and departure date.
3. Subtract any days spent outside the country mid-trip (look for side-trip journey folders in the same date range, e.g. a Cusco folder between Cairns arrival and Gold Coast departure).
4. If the trip straddles the start of the country's year, only count the days falling in the target year.
5. The resulting count is what the superscript should show.
