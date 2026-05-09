# Onward from London - plan comparison (Weiwu, June 2026)

Companion to `rivermill-plan.md`. Resolves the "Open Challenge" section of that document.

## Constraint reminder

Tax residency floor: arrive in Australia on or after **Sun 14 June 2026**. Earlier than that triggers tax residency (165 days already spent in AU during FY 25/26; 17 days remain).

## The baseline: same flights as family, 24 hours later

The family flies LGW → PVG → BNE on Thu 11 June (China Eastern **MU214** at 18:00 + MU715), arriving Sat 13 June 09:00 (1 day too early for Weiwu's tax floor). Weiwu takes the same airline pair, but **MU202 instead of MU214** for the LGW→PVG leg. MU202 has a different schedule: it is a daily morning departure, not a same-time-slot sibling of MU214.

Verified routing and price (12 Jun 2026, single seat): **EUR 518** for the through journey LGW → PVG → BNE on China Eastern.

| Leg     | Date                     | From → To    | Local                     | Flight                                                                                                                                              |
| ------- | ------------------------ | ------------ | ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1       | Fri 12 Jun               | LGW → PVG    | 11:35 → 05:55+1 (11h 20m) | China Eastern MU202, B787                                                                                                                           |
| Layover | Sat 13 Jun 05:55 → 21:05 | Shanghai PVG | 15h 10m, mostly daytime   | Long enough that a transit hotel or city tour fits (China Eastern routinely supplies transit accommodation for >8h connections; confirm at booking) |
| 2       | Sat 13 Jun               | PVG → BNE    | 21:05 → 09:00+1 (9h 55m)  | China Eastern MU715, A330                                                                                                                           |

Arrives **BNE Sun 14 Jun 09:00**, full day of Translink service available, train to Nerang straightforward.

A practical side benefit of the morning MU202: Weiwu's flight time does not overlap with the family's 18:00 MU214 on 11 June, so the family-drop-off and his own check-in are cleanly separated by the overnight Gatwick hotel.

### Cost components

- **Flight: EUR 518** for MU202 + MU715, 12 Jun 2026, single economy seat (verified via Kiwi; Google Flights does not surface China Eastern on this route). Slightly above the family's €421.90/pax rate because the family booked 3 pax and MU214 is a different aircraft.
- **Hotel (1 night, 11 → 12 June, Gatwick area):** see IHG availability table below.
- **Other:** transit hotel at PVG potentially included free with the airline; confirm at booking.

### IHG hotels near Gatwick, 11 → 12 June 2026 (1 adult, cheapest first)

Pulled live from IHG's API; prices in GBP.

| Code  | Hotel                                | Brand        | Distance to LGW | Price         |
| ----- | ------------------------------------ | ------------ | --------------- | ------------- |
| LGWWO | Holiday Inn Gatwick Worth            | Holiday Inn  | 3.1 km          | **GBP 63.65** |
| LONEP | Holiday Inn Express Epsom Downs      | HIEX         | 11.5 km         | GBP 78.57     |
| LONCR | Holiday Inn Express Croydon          | HIEX         | 15.6 km         | GBP 81.48     |
| LGWAP | Holiday Inn London - Gatwick Airport | Holiday Inn  | 0.9 km          | GBP 86.33     |
| LGWUK | Crowne Plaza Gatwick Airport         | Crowne Plaza | 2.0 km          | GBP 92.15     |
| LONSU | Holiday Inn Sutton                   | Holiday Inn  | 14.4 km         | GBP 123.19    |
| LONKT | Crowne Plaza Kingston                | Crowne Plaza | 17.5 km         | GBP 134.83    |
| CRYUK | Holiday Inn Express Crawley          | HIEX         | 2.8 km          | sold out      |
| LONWS | Holiday Inn Express Wimbledon S      | HIEX         | 18.3 km         | sold out      |

Cheapest: **Holiday Inn Gatwick Worth at GBP 63.65** (~€75). Closest: Holiday Inn London Gatwick Airport at GBP 86.33 (~€102).

### Plan A total

- Flight: **EUR 518** (MU202 + MU715, verified)
- Gatwick hotel (11→12 Jun, required): **€75** Holiday Inn Worth, 3 km; **€102** Holiday Inn London Gatwick Airport, 0.9 km
- PVG transit hotel (13 Jun, 15h layover): €0 if airline supplies (China Eastern routinely does for >8h; confirm at booking)
- **Total: €593 (cheapest Gatwick hotel, PVG hotel free) to €620 (airport hotel)**

## Plan comparison

All-in prices in EUR. Flights verified via Kiwi 9 May 2026; airlines confirmed via SerpAPI 9 May 2026; hotels from IHG live API 9 May 2026, non-EUR converted at indicative rates.

| | **Shanghai** | **Singapore** | **Bali** | **Istanbul** | **Istanbul** | **Tbilisi** | **Seoul** |
|---|---|---|---|---|---|---|---|
| **London departs** | LGW 11:35 · 12 Jun | LGW 18:00 · 11 Jun | LHR 21:20 · 11 Jun | LGW 13:30 · 11 Jun | LGW 13:30 · 11 Jun | LGW 19:00 · 11 Jun | LHR 19:35 · 11 Jun |
| **Outbound airline** | China Eastern | China Eastern (via PVG) | Air India (via DEL) | Pegasus | Pegasus | Kiwi virtual interline | Korean Air |
| **Via** | PVG arr 13 Jun 05:55 · dep 13 Jun 21:05 | SIN arr 12 Jun 17:10 · dep 14 Jun 21:00 | DPS arr 13 Jun 07:25 · dep 14 Jun 23:20 | IST arr 11 Jun 19:30 · dep 13 Jun 02:10 | IST arr 11 Jun 19:30 · dep 14 Jun 16:55 / MEL arr 16 Jun 06:15 · dep 18:20 | TBS arr 12 Jun 05:00 · dep 14 Jun 11:00 | ICN arr 12 Jun 16:15 · dep 14 Jun 16:10 |
| **Onward airline** | China Eastern | Jetstar | Virgin Australia | flydubai + Emirates | Kiwi virtual interline | Kiwi virtual interline | Jin Air + Jetstar |
| **AU arrives** | BNE 14 Jun 09:00 | BNE 15 Jun 23:15 | OOL 15 Jun 06:55 | BNE 14 Jun 06:25 | OOL 16 Jun 20:25 | BNE 16 Jun 08:20 | BNE 15 Jun 07:30 |
| **Flights** | €518 | €368 + €284 = €652 | €554 + €287 = €841 | €96 + €626 = €722 | €96 + €459 = €555 | €173 + €752 = €925 | €629 + €358 = €987 |
| **Hotel (IHG)** | €75–102 Gatwick | SGD 128/night × 2 (~€178) | USD 35 (~€33) | €74/night × 2 = €148 | €72/night × 3 = €217 | USD 131/night × 2 (~€242) | KRW 298k/night × 2 (~€400) |
| **Flight total** | €518 | €652 | €841 | €722 | €555 | €925 | €987 |
| **All-in** | **€593–620** | ~€830 | ~€909 | ~€870 | ~€772 | ~€1,167 | ~€1,387 |
| **Tickets** | 1 ticket, 1 airline | 2 separate | 2 separate + LGW→LHR | 2 separate | 2 separate | 2 separate | 2 separate + LGW→LHR |
| **Notes** | PVG hotel airline-supplied free for >8h; confirm at booking | Missed-connection risk | Cross-London transfer ~£30 | IST dep 02:10 local = 00:10 London | MEL 06:15–18:20 daytime, no hotel night | No longer outlier; was €2,373 | Korean Air direct LHR only; Weiwu must leave for LHR before family LGW check-in at 18:00 |

## Reading the comparison

Plan A at €593–620 all-in is €152–794 cheaper than every resting-city alternative once hotel nights are counted, with the simplest logistics (one airline, one ticket, baggage through-checked PVG → BNE). The resting-city plans only beat Plan A on the dimension of "more interesting trip"; none win on price, simplicity, or arrival time. Seoul (G) is the most expensive at ~€1,387 all-in, driven by Korean Air fares and Seoul hotel costs; it also requires LHR rather than LGW, so Weiwu cannot see the family off. Tbilisi (F) at ~€1,167 is €547–574 above Plan A. For Plans E and F the onward leg is a Kiwi virtual interline: luggage must be re-checked at each stop and missed-connection protection does not apply.

The 15-hour PVG layover is the meaningful disadvantage of Plan A. It is daytime in Shanghai (05:55 → 21:05), so a city tour or a transit hotel are both viable; China Eastern routinely supplies transit hotels for >8h connections, confirm at booking.

## Open items before booking

1. **Check transit hotel inclusion** at PVG for the 15-hour layover on this fare class.
2. **Book the Gatwick hotel**: Holiday Inn Worth at GBP 63.65 is the standout on price (3km, requires a brief transfer); airport-property Holiday Inn London Gatwick Airport at GBP 86.33 if zero-transfer is worth the £23 premium.

## Source data

- Family booking: `Dropbox:0. Travel Admin/2026-06-10 London, Gold Coast - Liansu, A-Z/Fares/`
- Stopover-route options: `london-au-onward-options.tsv` (original Kiwi pull); all prices reverified via Kiwi on 9 May 2026
- IHG availability: live API call against `apis.ihg.com`, 9 May 2026
