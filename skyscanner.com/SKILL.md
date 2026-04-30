---
name: skyscanner.com
description: Search Skyscanner for flight prices with dual-timezone display (local + body clock). Use when the user asks about flight prices, cheapest flights, or travel between cities.
allowed-tools: Bash, Read
---

# Skyscanner Flight Search

## Prerequisites

No credentials required. One optional setting:

- **Home timezone:** set in `~/.claude/config/skill-config.yaml` under `skyscanner.com.home_timezone` (IANA format, e.g. `"Europe/Madrid"`). Used for body-clock display alongside local times. Defaults to UTC if absent.

## Capabilities

1. **Flight search with pricing:** given origin, destination, date, and passenger info, returns flight itineraries sorted by price/duration/stops. Uses Skyscanner's internal conductor API via curl. Tested and working.
2. **City/airport code resolution:** resolves city names to Skyscanner codes via the autosuggest API. Handles multi-airport cities (e.g. "London" includes LHR, LGW, STN, LTN, LCY, SEN). No auth needed.
3. **Dual-timezone display:** each segment shows times in local airport time AND the departure city's timezone ("body clock"), so the traveller can see whether an "overnight" flight is actually overnight for their body.

## Quick start

Run `search.py` from the skill directory. It handles code resolution, cookie acquisition, API calls, and formatting.

```bash
python3 $HOME/code/aesop/skyscanner.com/search.py "Seville" "Brisbane" 2026-05-13
```

### With options

```bash
python3 $HOME/code/aesop/skyscanner.com/search.py "London" "Sydney" 2026-06-01 \
    --adults 2 --children "7,12" --cabin economy --currency EUR --top 10 --sort duration
```

### Arguments

| Argument | Description |
|---|---|
| origin | City name or IATA code (e.g. "Seville", "SVQ", "London") |
| destination | City name or IATA code |
| date | YYYY-MM-DD |
| --adults N | Number of adults (default: 1) |
| --children AGES | Comma-separated child ages (e.g. "7,12") |
| --cabin CLASS | economy, premiumeconomy, business, first |
| --currency CUR | Currency code (default: AUD) |
| --market MK | Market code affects pricing locale (default: AU) |
| --top N | Show top N results (default: 15) |
| --sort FIELD | price, duration, or stops (default: price) |
| --json | Output raw JSON instead of formatted table |

## Output format

Each itinerary shows price, total duration, stop count, airlines, and booking agent. Segments show local times and body clock times:

```
#4    1,109         34h10m     2stop    TK/QF            via Gotogate
     TK1298   SVQ 11:50   -> IST 17:15    4h25m  (body: 11:50->16:15)
     TK518    IST 19:10   -> SIN 11:10+1  11h00m  (body: 18:10->05:10+1)
     QF52     SIN 20:30+1 -> BNE 06:00+2  7h30m  (body: 14:30+1->22:00+1)
```

The "+1", "+2" suffixes indicate days after departure. "body:" times show what the traveller's body clock (origin timezone) reads at that moment. In this example, the SIN→BNE "overnight" segment (20:30→06:00) is actually 14:30→22:00 body time — not a lost night for the traveller.

## How it works

### Step 1: Autosuggest API (no auth)

`GET https://www.skyscanner.com.au/g/autosuggest-flights/{market}/{locale}/{market}/{query}`

Returns PlaceId (IATA for airports, 4-char for cities like LOND). Multi-airport cities return the city code first, then individual airports.

### Step 2: Cookie acquisition

`GET https://www.skyscanner.com.au/transport/flights/{origin}/{dest}/{YYMMDD}/` with browser headers. Sets PerimeterX session cookies needed for the API.

### Step 3: Conductor API

`POST https://www.skyscanner.com.au/g/conductor/v1/fps3/search?geo_schema=skyscanner&carrier_schema=skyscanner&response_include=deeplink;segment&pageindex=0&pagesize=50`

Request body:
```json
{
  "adults": 1,
  "cabin_class": "economy",
  "child_ages": [],
  "children": 0,
  "infants": 0,
  "currency": "AUD",
  "locale": "en-AU",
  "market": "AU",
  "legs": [{"origin": "SVQ", "destination": "BNE", "date": "2026-05-13"}],
  "options": {"cached_prices_only": false, "include_unpriced_itineraries": true, "include_mixed_booking_options": true}
}
```

Required headers: `Content-Type: application/json`, `Accept: application/json`, `X-Skyscanner-ChannelId: website`, `X-Skyscanner-ViewId: <uuid4>`, and browser UA.

### Step 4: Poll

`GET` the same URL with `/{session_id}` appended (from `context.session_id` in the Step 3 response). Returns complete results after all agents finish.

## Rate limiting and fallback

The script enforces a minimum 3-second interval between curl requests. PerimeterX blocks the IP after ~15 rapid requests.

**Fallback chain when curl is blocked:**
1. Script automatically tries `--headless=new` + `--virtual-time-budget=15000` (the browser's new headless mode bypasses PerimeterX in many cases)
2. If headless also fails (full IP block), prints the flight page URL and asks the user to open it in their browser to solve the captcha
3. After solving, re-run the search

The headless fallback produces summary-level results (price, airlines, duration, stops, departure/arrival times) but without per-segment breakdown. The curl path gives full segment detail with flight numbers and individual leg times.

To minimize blocks:
- Don't make many searches in rapid succession
- One cookie set from Step 2 can be reused for multiple searches

## Timezone data

`iata_tz.json` contains 7883 IATA airport code to IANA timezone mappings (from the `airportsdata` package). The script loads this at startup for body-clock conversion.

## Typical workflow

1. User asks about flights between two cities on a date.
2. Run `search.py` with city names — it resolves codes automatically.
3. Present the formatted table to the user.
4. If user wants different sorting or more results, re-run with `--sort` or `--top`.
5. For raw data (e.g. to build custom comparisons), use `--json`.

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| "BLOCKED by PerimeterX" | Too many requests, IP rate-limited | Script auto-falls back to headless browser. If that also fails, ask user to open the printed URL in their browser and solve the captcha, then re-run |
| "Could not resolve" | City name not found in autosuggest | Try a more specific name or IATA code |
| 0 itineraries | No flights on that route/date, or API returned empty | Try a different date or check the route exists |
