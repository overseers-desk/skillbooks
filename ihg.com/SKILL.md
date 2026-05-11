---
name: ihg.com
description: "IHG hotels on ihg.com: availability, pricing, search."
allowed-tools: Bash, Read
---

# IHG Hotel Search

## Capabilities

1. **Hotel discovery by destination** — given a place name, finds all nearby IHG hotels with distance. Pure curl, no browser. Tested and working.
2. **Hotel availability with pricing** — given hotel mnemonic codes, dates, and guest count, returns rate plans with prices. Pure curl. Tested and working.
3. **Price calendar** — given a hotel mnemonic and a date range, returns the lowest nightly rate for each night. Tested and working.
4. **Destination resolution** — resolves a place name to coordinates. May return 403 on some IPs. Tested, works on some machines.
5. **Hotel details (names, addresses, brand info)** — given one or more hotel mnemonics, returns hotel name, full GDS name, brand, address, and more. Pure curl. Tested and working.

## Brand codes

| Code | Brand |
|---|---|
| HICP | Crowne Plaza |
| HIEX | Holiday Inn Express |
| HOLI | Holiday Inn |
| HIRT | Holiday Inn Resort |
| ICON | InterContinental |
| INDG | Hotel Indigo |
| VXVX | voco |
| KIMN | Kimpton |
| RGNT | Regent |
| SIXS | Six Senses |
| EVEN | EVEN Hotels |
| STBR | Staybridge Suites |
| CNDW | Candlewood Suites |

## API details

All endpoints use these headers:
- `x-ihg-api-key: se9ym5iAzaW8pxfBjkmgbuGjJcr3Pj6Y` (static client-side key from IHG's JS bundle)
- `ihg-language: en-GB`
- `ihg-sessionid:` (any UUID)
- `ihg-transactionid:` (any UUID)
- `Origin: https://www.ihg.com`
- `Referer: https://www.ihg.com/`
- `Sec-Fetch-Mode: cors`
- `Sec-Fetch-Site: same-site`
- Standard browser `User-Agent`

The hotel details endpoints require `Sec-Fetch-Mode` and `Sec-Fetch-Site`. Including them on all calls is safe — they do not break the availability endpoint.

### Hotel discovery by geo-search

Use the same availability endpoint but with `geoLocation` instead of `hotelMnemonics`. These two modes are mutually exclusive — do not include both.

Endpoint: `POST https://apis.ihg.com/availability/v3/hotels/offers?fieldset=summary,summary.rateRanges`

Request body:
```json
{
  "geoLocation": [{"latitude": -28.017742, "longitude": 153.425732}],
  "radius": 50,
  "maxRadius": 200,
  "incrementRadiusBy": 50,
  "distanceUnit": "KM",
  "distanceType": "STRAIGHT_LINE",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "products": [{
    "productCode": "SR",
    "startDate": "YYYY-MM-DD",
    "endDate": "YYYY-MM-DD",
    "quantity": 1,
    "guestCounts": [{"otaCode": "AQC10", "count": ADULTS}]
  }]
}
```

Critical: `geoLocation` must be an **array** of coordinate objects. A single object not in an array returns 400.

Get coordinates from the destinations API first. Response includes `hotels[].hotelMnemonic`, `hotels[].brandCode`, `hotels[].distance`, and pricing.

### Availability API (by mnemonic codes)

Endpoint: `POST https://apis.ihg.com/availability/v3/hotels/offers?fieldset=summary,summary.rateRanges`

Request body:
```json
{
  "hotelMnemonics": ["OOLSP", "SFPPB"],
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD",
  "products": [{
    "productCode": "SR",
    "startDate": "YYYY-MM-DD",
    "endDate": "YYYY-MM-DD",
    "quantity": 1,
    "guestCounts": [{"otaCode": "AQC10", "count": ADULTS}]
  }]
}
```

Response structure (key fields):
- `hotels[].hotelMnemonic` — hotel code
- `hotels[].brandCode` — see brand table above
- `hotels[].lowestCashOnlyCost.baseAmount` — lowest price for the stay
- `hotels[].propertyCurrency` — e.g. "AUD"
- `hotels[].ratePlanDefinitions[].code` — rate plan code
- `hotels[].ratePlanDefinitions[].rateRange.low.baseAmount` / `.high.baseAmount` — price range per rate plan
- `hotels[].ratePlanDefinitions[].providerDescription` — rate plan description

### Hotel details (batch)

Endpoint: `POST https://apis.ihg.com/hotels/v1/profiles/details?fieldset=profile,brandInfo`

Request body — a JSON array of mnemonic strings:
```json
["OOLSP", "SFPPB"]
```

Response structure (array of objects):
- `[].hotelCode` — hotel mnemonic (e.g. `"OOLSP"`)
- `[].profile.name` — short hotel name (e.g. `"Surfers Paradise"`)
- `[].profile.gdsName` — full name with brand (e.g. `"CROWNE PLAZA SURFERS PARADISE by IHG"`)
- `[].brandInfo.brandName` — brand name (e.g. `"Crowne Plaza"`)
- `[].brandInfo.brandCode` — brand code (e.g. `"HICP"`)

Additional fieldset values available: `address`, `contact`, `reviews`, `facilities`, `location`, `transportation`, `media`, `roomTypes`, `policies`, `parking`, `renovationAlerts`, `tax`, `badges`. Add to the `fieldset` query parameter as needed (comma-separated).

### Price calendar

Use the availability API called once per night across a date range. For each night, set `startDate` to that night and `endDate` to the next day. Read `hotels[0].lowestCashOnlyCost.baseAmount` from each response.

The dedicated calendar endpoint (`/v3/calendar`) exists but is WAF-protected. The per-night approach takes ~1 second per call, so a 30-day calendar completes in ~30 seconds.

### Destinations API (curl, may be IP-restricted)

Endpoint: `GET https://apis.ihg.com/locations/v1/destinations?ihg-language=en-GB&destination=ENCODED_DESTINATION&chainCode=6c`

Returns `[{"latitude":..., "longitude":..., "clarifiedLocation":...}]`.

If this returns 403, coordinates can be obtained from any geocoding service or looked up manually.

## Fallback

If the curl-based API becomes WAF-protected, fall back to `$HOME/.claude/skills/bin/not-google-chrome`.

## Typical workflow

1. User asks about IHG hotels in a destination with dates.
2. Resolve destination to coordinates via the destinations API.
3. Call the availability API with `geoLocation` to discover all nearby hotels.
4. Call the hotel details batch endpoint with the returned mnemonics to get hotel names.
5. Join results by mnemonic code. Present with hotel names, brand, prices, and distance.
6. For price calendar queries, call the availability API once per night per hotel.
