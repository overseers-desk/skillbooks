#!/usr/bin/env python3
"""Skyscanner flight search with dual-timezone display.

Usage:
    python3 search.py <origin> <destination> <date> [options]

Arguments:
    origin       City or airport name (e.g. "Seville", "SVQ")
    destination  City or airport name (e.g. "Brisbane", "BNE")
    date         YYYY-MM-DD format

Options:
    --adults N        Number of adults (default: 1)
    --children AGES   Comma-separated child ages (e.g. "7,12")
    --cabin CLASS     economy|premiumeconomy|business|first (default: economy)
    --currency CUR    Currency code (default: AUD)
    --market MK       Market code (default: AU)
    --top N           Show top N results (default: 15)
    --sort FIELD      Sort by: price|duration|stops (default: price)
    --json            Output raw JSON instead of table
"""

import sys, json, subprocess, urllib.request, urllib.parse, uuid, time, os, argparse, tempfile, re
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from pathlib import Path

def _detect_chrome_version():
    """Get the Chrome version from the installed browser."""
    for cmd in [["chromium", "--version"], ["/snap/bin/chromium", "--version"],
                ["chromium-browser", "--version"], ["google-chrome", "--version"],
                ["google-chrome-stable", "--version"]]:
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            for token in r.stdout.split():
                if token[0].isdigit() and "." in token:
                    return token  # e.g. "146.0.7680.164"
        except Exception:
            continue
    return "146.0.0.0"

_CHROME_VER = _detect_chrome_version()
_CHROME_MAJOR = _CHROME_VER.split(".")[0]
UA = f"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/{_CHROME_VER} Safari/537.36"
# sec-ch-ua header matching the detected version
SEC_CH_UA = f'"Not-A.Brand";v="24", "Chromium";v="{_CHROME_MAJOR}"'

# Rate limiter: at most 1 curl request per MIN_REQUEST_INTERVAL seconds
MIN_REQUEST_INTERVAL = 3.0
_last_request_time = 0.0

def _throttle():
    """Sleep if needed to enforce minimum interval between requests."""
    global _last_request_time
    now = time.time()
    elapsed = now - _last_request_time
    if elapsed < MIN_REQUEST_INTERVAL:
        time.sleep(MIN_REQUEST_INTERVAL - elapsed)
    _last_request_time = time.time()

# Load IATA -> IANA timezone mapping
_tz_file = Path(__file__).parent / "iata_tz.json"
TZ_MAP = json.loads(_tz_file.read_text()) if _tz_file.exists() else {}


def autosuggest(query, market="AU", locale="en-GB"):
    """Resolve a city/airport name to a Skyscanner place code."""
    url = (
        f"https://www.skyscanner.com.au/g/autosuggest-flights/"
        f"{market}/{locale}/{market}/{urllib.parse.quote(query)}"
    )
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.load(resp)
    return data


def resolve_code(query):
    """Return (skyscanner_code, iata_code, display_name) for a query.

    If the query looks like a 3-4 letter IATA/city code, validate via
    autosuggest. If autosuggest returns a non-matching result (rate-limit
    degradation), trust the original code.
    """
    query = query.strip()
    if len(query) <= 4 and query.isalpha():
        code_upper = query.upper()
        try:
            results = autosuggest(query)
            if results:
                top = results[0]
                # Verify the autosuggest result actually matches the code
                if top["PlaceId"].upper() == code_upper:
                    return top["PlaceId"], top.get("IataCode") or top["PlaceId"], top["PlaceName"]
                # Check if any result matches
                for r in results:
                    if r["PlaceId"].upper() == code_upper:
                        return r["PlaceId"], r.get("IataCode") or r["PlaceId"], r["PlaceName"]
        except Exception:
            pass
        # Trust the code as-is (it's a valid IATA code)
        return code_upper, code_upper, code_upper

    results = autosuggest(query)
    if not results:
        print(f"Error: Could not resolve '{query}' to a Skyscanner code.", file=sys.stderr)
        sys.exit(1)

    top = results[0]
    place_id = top["PlaceId"]
    iata = top.get("IataCode") or place_id
    name = top["PlaceName"]
    print(f"  {query} -> {place_id} ({name})", file=sys.stderr)
    if len(results) > 1 and top.get("PlaceClassName") == "City":
        airports = [r for r in results[1:5] if r.get("PlaceClassName") == "Airport"]
        if airports:
            names = ", ".join(f"{a['PlaceId']}" for a in airports)
            print(f"    Includes airports: {names}", file=sys.stderr)
    return place_id, iata, name


def _print_unblock_instructions(page_url):
    """Print instructions for the user to unblock the IP via browser captcha."""
    print("BLOCKED by PerimeterX bot detection.", file=sys.stderr)
    print("", file=sys.stderr)
    print("To unblock, open this URL in your browser and solve the captcha:", file=sys.stderr)
    print(f"  {page_url}", file=sys.stderr)
    print("", file=sys.stderr)
    print("Then re-run this search.", file=sys.stderr)


def _parse_time_12h(s):
    """Parse '11:50 am' or '7:00 pm' to 24h 'HH:MM'."""
    m = re.match(r'(\d+):(\d+)\s*(am|pm)', s.strip(), re.IGNORECASE)
    if not m:
        return s.strip()
    h, mi, ap = int(m.group(1)), int(m.group(2)), m.group(3).lower()
    if ap == "pm" and h != 12:
        h += 12
    elif ap == "am" and h == 12:
        h = 0
    return f"{h:02d}:{mi:02d}"


def _parse_duration_text(text):
    """Parse '35 hours 10 minutes' or '28 hours 45 minutes' to minutes."""
    hours = minutes = 0
    m = re.search(r'(\d+)\s*hours?', text)
    if m:
        hours = int(m.group(1))
    m = re.search(r'(\d+)\s*minutes?', text)
    if m:
        minutes = int(m.group(1))
    return hours * 60 + minutes


def fetch_flights_headless(page_url, origin_iata, dest_iata, date_str):
    """Fallback: use --headless=new + --virtual-time-budget to render the SPA and parse DOM."""
    print("Trying headless browser fallback...", file=sys.stderr)

    browser = None
    for candidate in ["/snap/bin/chromium", "chromium", "chromium-browser",
                      "google-chrome", "google-chrome-stable"]:
        try:
            subprocess.run([candidate, "--version"], capture_output=True, timeout=3)
            browser = candidate
            break
        except Exception:
            continue
    if not browser:
        print("Error: No Chrome-compatible browser found.", file=sys.stderr)
        return None

    profile = None
    for path in [
        os.path.expanduser("~/snap/chromium/common/chromium"),
        os.path.expanduser("~/.config/chromium"),
        os.path.expanduser("~/.config/google-chrome"),
    ]:
        if os.path.isdir(path):
            profile = path
            break

    result = subprocess.run(
        [
            "flock", "/tmp/browser.lock",
            browser,
            "--headless=new",
            "--dump-dom",
            "--virtual-time-budget=15000",
            *(["--user-data-dir=" + profile] if profile else []),
            page_url,
        ],
        capture_output=True, text=True, timeout=30,
    )

    if result.returncode != 0 or not result.stdout.strip():
        print("Error: Headless browser returned no output.", file=sys.stderr)
        return None

    html = result.stdout
    if "px-captcha" in html or "captcha.js" in html:
        print("Error: Headless browser also blocked by captcha.", file=sys.stderr)
        return None

    # Parse the a11y descriptor blocks
    a11y_pattern = r'FlightsTicketA11yDescriptor_visuallyHidden[^>]*>(.*?)</div>'
    blocks = _re.findall(a11y_pattern, html, _re.DOTALL)

    if not blocks:
        print("Error: No flight tickets found in rendered DOM.", file=sys.stderr)
        return None

    print(f"  Headless rendered {len(blocks)} tickets.", file=sys.stderr)

    date_obj = datetime.strptime(date_str, "%Y-%m-%d")
    itineraries = []
    legs = []
    places_list = []
    carriers_list = []

    # Seed origin/dest places
    place_id_counter = 1
    origin_place_id = place_id_counter
    places_list.append({"id": origin_place_id, "name": origin_iata, "type": "Airport", "display_code": origin_iata})
    place_id_counter += 1
    dest_place_id = place_id_counter
    places_list.append({"id": dest_place_id, "name": dest_iata, "type": "Airport", "display_code": dest_iata})
    place_id_counter += 1

    carrier_id_counter = -1
    carrier_map = {}  # name -> id

    for idx, block in enumerate(blocks):
        h3 = _re.findall(r'<h3[^>]*>(.*?)</h3>', block)
        lis = _re.findall(r'<li>(.*?)</li>', block)
        h3_text = _re.sub(r'<[^>]+>', '', h3[0]).strip() if h3 else ''
        li_texts = [_re.sub(r'<[^>]+>', '', l).strip() for l in lis]

        # Parse price
        price_m = _re.search(r'\$([0-9,]+)', h3_text)
        if not price_m:
            continue
        price = float(price_m.group(1).replace(',', ''))

        # Parse airlines
        airline_names = []
        for li in li_texts:
            am = _re.match(r'Flight with (.+?)\.', li)
            if am:
                airline_names = [a.strip() for a in am.group(1).split(',')]

        # Parse times
        dep_time_str = arr_time_str = None
        day_offset = 0
        for li in li_texts:
            tm = _re.search(r'at (\d+:\d+ [ap]m), arriving.*at (\d+:\d+ [ap]m)(?:, (\d+) days? later|, one day later)?', li)
            if tm:
                dep_time_str = _parse_time_12h(tm.group(1))
                arr_time_str = _parse_time_12h(tm.group(2))
                if tm.group(3):
                    day_offset = int(tm.group(3))
                elif 'one day later' in li:
                    day_offset = 1

        # Parse duration
        duration_min = 0
        for li in li_texts:
            dm = _re.search(r'taking (.+?) with', li)
            if dm:
                duration_min = _parse_duration_text(dm.group(1))
            elif _re.search(r'Direct flight taking (.+?)\.', li):
                dm2 = _re.search(r'Direct flight taking (.+?)\.', li)
                duration_min = _parse_duration_text(dm2.group(1))

        # Parse stops
        stop_count = 0
        stop_names = []
        for li in li_texts:
            sm = _re.search(r'(\d+) stops? in (.+?)\.', li)
            if sm:
                stop_count = int(sm.group(1))
                stop_names = [s.strip() for s in sm.group(2).split(',')]
            elif 'Direct flight' in li:
                stop_count = 0

        if not dep_time_str or not arr_time_str:
            continue

        # Build carrier entries
        carrier_ids = []
        for aname in airline_names:
            if aname not in carrier_map:
                carrier_map[aname] = carrier_id_counter
                carriers_list.append({"id": carrier_id_counter, "name": aname, "display_code": aname[:2].upper(), "display_code_type": "IATA"})
                carrier_id_counter -= 1
            carrier_ids.append(carrier_map[aname])

        # Build departure/arrival datetimes
        dep_dt = f"{date_str}T{dep_time_str}:00"
        arr_date = date_obj + timedelta(days=day_offset)
        arr_dt = f"{arr_date.strftime('%Y-%m-%d')}T{arr_time_str}:00"

        leg_id = f"headless-leg-{idx}"
        # Build a single-segment leg (we don't have segment breakdown from DOM)
        seg_id = f"headless-seg-{idx}"
        segments_list_local = [{
            "id": seg_id,
            "origin_place_id": origin_place_id,
            "destination_place_id": dest_place_id,
            "departure": dep_dt,
            "arrival": arr_dt,
            "duration": duration_min,
            "marketing_flight_number": "",
            "marketing_carrier_id": carrier_ids[0] if carrier_ids else 0,
            "operating_carrier_id": carrier_ids[0] if carrier_ids else 0,
        }]

        leg = {
            "id": leg_id,
            "origin_place_id": origin_place_id,
            "destination_place_id": dest_place_id,
            "departure": dep_dt,
            "arrival": arr_dt,
            "segment_ids": [seg_id],
            "duration": duration_min,
            "stop_count": stop_count,
            "marketing_carrier_ids": carrier_ids or [0],
        }
        legs.append(leg)

        itin = {
            "id": f"headless-itin-{idx}",
            "leg_ids": [leg_id],
            "cheapest_price": {"amount": price},
            "pricing_options": [{"price": {"amount": price}, "items": []}],
        }
        itineraries.append(itin)

    # Assemble into conductor-API-compatible structure
    all_segments = []
    for idx in range(len(blocks)):
        seg_id = f"headless-seg-{idx}"
        # Find corresponding leg
        if idx < len(legs):
            leg = legs[idx]
            all_segments.append({
                "id": seg_id,
                "origin_place_id": origin_place_id,
                "destination_place_id": dest_place_id,
                "departure": leg["departure"],
                "arrival": leg["arrival"],
                "duration": leg["duration"],
                "marketing_flight_number": "",
                "marketing_carrier_id": leg["marketing_carrier_ids"][0] if leg["marketing_carrier_ids"] else 0,
                "operating_carrier_id": leg["marketing_carrier_ids"][0] if leg["marketing_carrier_ids"] else 0,
            })

    return {
        "itineraries": itineraries,
        "legs": legs,
        "segments": all_segments,
        "places": places_list,
        "carriers": carriers_list,
        "agents": [],
        "context": {},
        "query": {},
        "_headless_fallback": True,
    }


def fetch_flights(origin_code, dest_code, date_str, adults=1, child_ages=None,
                  cabin="economy", currency="AUD", market="AU", pagesize=50):
    """Two-step curl flow: acquire cookies then call conductor API."""
    child_ages = child_ages or []
    date_obj = datetime.strptime(date_str, "%Y-%m-%d")
    yymmdd = date_obj.strftime("%y%m%d")

    origin_lower = origin_code.lower()
    dest_lower = dest_code.lower()

    params = {
        "adultsv2": str(adults),
        "cabinclass": cabin,
        "ref": "home",
        "rtn": "0",
        "preferdirects": "false",
        "outboundaltsenabled": "false",
        "inboundaltsenabled": "false",
    }
    if child_ages:
        params["childrenv2"] = "|".join(str(a) for a in child_ages)

    page_url = (
        f"https://www.skyscanner.com.au/transport/flights/"
        f"{origin_lower}/{dest_lower}/{yymmdd}/"
        f"?{urllib.parse.urlencode(params)}"
    )

    cookie_jar = tempfile.mktemp(suffix=".txt", prefix="ss_cookies_")

    try:
        # Step 1: GET page to acquire cookies
        print("Acquiring session cookies...", file=sys.stderr)
        _throttle()
        step1 = subprocess.run(
            [
                "curl", "-sS", "-o", "/dev/null",
                "-c", cookie_jar,
                "-H", f"User-Agent: {UA}",
                "-H", "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
                "-H", "Accept-Language: en-AU,en;q=0.9",
                "-H", f"sec-ch-ua: {SEC_CH_UA}",
                "-H", "sec-ch-ua-mobile: ?0",
                "-H", 'sec-ch-ua-platform: "Linux"',
                "-H", "Sec-Fetch-Dest: document",
                "-H", "Sec-Fetch-Mode: navigate",
                "-H", "Sec-Fetch-Site: none",
                "-H", "Sec-Fetch-User: ?1",
                "-H", "Upgrade-Insecure-Requests: 1",
                page_url,
            ],
            capture_output=True, text=True, timeout=30,
        )
        if step1.returncode != 0:
            print(f"Warning: cookie fetch returned {step1.returncode}", file=sys.stderr)

        # Step 2: POST to conductor API
        print("Searching flights...", file=sys.stderr)
        search_url = (
            "https://www.skyscanner.com.au/g/conductor/v1/fps3/search"
            "?geo_schema=skyscanner&carrier_schema=skyscanner"
            "&response_include=deeplink;segment"
            f"&pageindex=0&pagesize={pagesize}"
        )

        body = {
            "adults": adults,
            "cabin_class": cabin,
            "child_ages": child_ages,
            "children": len(child_ages),
            "infants": 0,
            "currency": currency,
            "locale": f"en-{market}",
            "market": market,
            "legs": [{"origin": origin_code.upper(), "destination": dest_code.upper(), "date": date_str}],
            "options": {
                "cached_prices_only": False,
                "include_unpriced_itineraries": True,
                "include_mixed_booking_options": True,
            },
        }

        view_id = str(uuid.uuid4())
        _throttle()
        step2 = subprocess.run(
            [
                "curl", "-sS",
                "-b", cookie_jar,
                "-c", cookie_jar,
                "-X", "POST",
                "-H", f"User-Agent: {UA}",
                "-H", "Content-Type: application/json",
                "-H", "Accept: application/json",
                "-H", "X-Skyscanner-ChannelId: website",
                "-H", f"X-Skyscanner-ViewId: {view_id}",
                "-d", json.dumps(body),
                search_url,
            ],
            capture_output=True, text=True, timeout=30,
        )

        if step2.returncode != 0 or not step2.stdout.strip():
            print(f"Error: conductor API failed (rc={step2.returncode})", file=sys.stderr)
            if step2.stderr:
                print(step2.stderr[:500], file=sys.stderr)
            sys.exit(1)

        try:
            data = json.loads(step2.stdout)
        except json.JSONDecodeError:
            if "px-captcha" in step2.stdout or "captcha" in step2.stdout.lower():
                print("curl blocked by PerimeterX, falling back to headless browser...", file=sys.stderr)
                fallback = fetch_flights_headless(page_url, origin_code, dest_code, date_str)
                if fallback:
                    return fallback
                _print_unblock_instructions(page_url)
            else:
                print(f"Error: Invalid JSON response (first 200 chars): {step2.stdout[:200]}", file=sys.stderr)
            sys.exit(1)

        # Check for PerimeterX block in JSON response
        if data.get("reason") == "blocked" or "captcha" in data.get("redirect_to", ""):
            print("curl blocked by PerimeterX, falling back to headless browser...", file=sys.stderr)
            fallback = fetch_flights_headless(page_url, origin_code, dest_code, date_str)
            if fallback:
                return fallback
            _print_unblock_instructions(page_url)
            sys.exit(1)

        session_id = data.get("context", {}).get("session_id", "")
        if not session_id:
            print("Warning: No session_id in response, cannot poll for more results.", file=sys.stderr)
            return data

        # Step 3: Poll for complete results
        print("Polling for complete results...", file=sys.stderr)
        time.sleep(2)
        poll_url = (
            f"https://www.skyscanner.com.au/g/conductor/v1/fps3/search/"
            f"{session_id}"
            f"?geo_schema=skyscanner&carrier_schema=skyscanner"
            f"&response_include=deeplink;segment"
            f"&pageindex=0&pagesize={pagesize}"
        )

        _throttle()
        step3 = subprocess.run(
            [
                "curl", "-sS",
                "-b", cookie_jar,
                "-H", f"User-Agent: {UA}",
                "-H", "Accept: application/json",
                "-H", "X-Skyscanner-ChannelId: website",
                "-H", f"X-Skyscanner-ViewId: {view_id}",
                poll_url,
            ],
            capture_output=True, text=True, timeout=30,
        )

        if step3.returncode == 0 and step3.stdout.strip():
            try:
                polled = json.loads(step3.stdout)
                n_itin = len(polled.get("itineraries", []))
                if n_itin > len(data.get("itineraries", [])):
                    print(f"  Got {n_itin} itineraries (up from {len(data.get('itineraries', []))})", file=sys.stderr)
                    data = polled
            except json.JSONDecodeError:
                print("  Poll returned non-JSON, using initial results.", file=sys.stderr)

        return data

    finally:
        try:
            os.unlink(cookie_jar)
        except OSError:
            pass


def build_lookups(data):
    """Build id->object lookup dicts from the flat lists in the response."""
    places = {p["id"]: p for p in data.get("places", [])}
    carriers = {c["id"]: c for c in data.get("carriers", [])}
    segments = {s["id"]: s for s in data.get("segments", [])}
    legs = {lg["id"]: lg for lg in data.get("legs", [])}
    agents = {a["id"]: a for a in data.get("agents", [])}
    return places, carriers, segments, legs, agents


def get_tz(iata_code):
    """Get ZoneInfo for an IATA airport code."""
    tz_name = TZ_MAP.get(iata_code.upper())
    if tz_name:
        try:
            return ZoneInfo(tz_name)
        except Exception:
            pass
    return None


def format_duration(minutes):
    """Format duration in minutes as Xh Ym."""
    h, m = divmod(int(minutes), 60)
    return f"{h}h{m:02d}m"


def format_time_pair(naive_str, local_tz, origin_tz, depart_date):
    """Format a time showing local and (origin body clock) times.

    Returns (local_str, body_str) like ('17:15', '16:15') with +N day offsets.
    """
    dt = datetime.fromisoformat(naive_str)
    day_offset = (dt.date() - depart_date).days

    local_str = dt.strftime("%H:%M")
    if day_offset > 0:
        local_str += f"+{day_offset}"
    elif day_offset < 0:
        local_str += f"{day_offset}"

    body_str = ""
    if local_tz and origin_tz:
        local_aware = dt.replace(tzinfo=local_tz)
        body_dt = local_aware.astimezone(origin_tz)
        body_day_offset = (body_dt.date() - depart_date).days
        body_str = body_dt.strftime("%H:%M")
        if body_day_offset > 0:
            body_str += f"+{body_day_offset}"
        elif body_day_offset < 0:
            body_str += f"{body_day_offset}"

    return local_str, body_str


def format_results(data, origin_iata, dest_iata, sort_by="price", top_n=15):
    """Parse and format flight results into a readable table."""
    places, carriers, segments_map, legs_map, agents = build_lookups(data)

    origin_tz = get_tz(origin_iata)

    itineraries = data.get("itineraries", [])
    if not itineraries:
        print("No flights found.")
        return

    rows = []
    for itin in itineraries:
        cheapest = itin.get("cheapest_price", {})
        price = cheapest.get("amount")
        if price is None:
            for po in itin.get("pricing_options", []):
                p = po.get("price", {}).get("amount")
                if p is not None:
                    if price is None or p < price:
                        price = p
        if price is None:
            continue

        leg_ids = itin.get("leg_ids", [])
        if not leg_ids:
            continue
        leg = legs_map.get(leg_ids[0])
        if not leg:
            continue

        duration = leg.get("duration", 0)
        stop_count = leg.get("stop_count", 0)
        departure = leg.get("departure", "")
        arrival = leg.get("arrival", "")
        depart_date = datetime.fromisoformat(departure).date()

        carrier_ids = leg.get("marketing_carrier_ids", [])
        carrier_codes = []
        for cid in carrier_ids:
            c = carriers.get(cid, {})
            carrier_codes.append(c.get("display_code", "?"))

        seg_details = []
        for seg_id in leg.get("segment_ids", []):
            seg = segments_map.get(seg_id)
            if not seg:
                continue

            orig_place = places.get(seg["origin_place_id"], {})
            dest_place = places.get(seg["destination_place_id"], {})
            orig_code = orig_place.get("display_code", "?")
            dest_code_seg = dest_place.get("display_code", "?")

            orig_seg_tz = get_tz(orig_code)
            dest_seg_tz = get_tz(dest_code_seg)

            dep_local, dep_body = format_time_pair(seg["departure"], orig_seg_tz, origin_tz, depart_date)
            arr_local, arr_body = format_time_pair(seg["arrival"], dest_seg_tz, origin_tz, depart_date)

            mkt_carrier = carriers.get(seg.get("marketing_carrier_id"), {})
            flight_code = f"{mkt_carrier.get('display_code', '??')}{seg.get('marketing_flight_number', '?')}"

            seg_details.append({
                "flight": flight_code,
                "origin": orig_code,
                "dest": dest_code_seg,
                "dep_local": dep_local,
                "arr_local": arr_local,
                "dep_body": dep_body,
                "arr_body": arr_body,
                "duration": seg.get("duration", 0),
            })

        agent_name = ""
        for po in itin.get("pricing_options", []):
            for item in po.get("items", []):
                a = agents.get(item.get("agent_id"), {})
                if a.get("name"):
                    agent_name = a["name"]
                    break
            if agent_name:
                break

        rows.append({
            "price": price,
            "duration": duration,
            "stops": stop_count,
            "carriers": "/".join(dict.fromkeys(carrier_codes)),
            "segments": seg_details,
            "agent": agent_name,
            "depart_date": depart_date,
        })

    if sort_by == "price":
        rows.sort(key=lambda r: r["price"])
    elif sort_by == "duration":
        rows.sort(key=lambda r: r["duration"])
    elif sort_by == "stops":
        rows.sort(key=lambda r: (r["stops"], r["price"]))

    rows = rows[:top_n]
    currency = data.get("query", {}).get("currency") or "AUD"

    print(f"\n{'='*90}")
    print(f"  Flights: {origin_iata} -> {dest_iata}  |  {rows[0]['depart_date'] if rows else '?'}  |  {len(rows)} of {len(itineraries)} shown")
    print(f"  Sorted by: {sort_by}  |  Currency: {currency}")
    if origin_tz:
        print(f"  Body clock reference: {TZ_MAP.get(origin_iata.upper(), '?')} ({origin_iata})")
    print(f"{'='*90}\n")

    for i, row in enumerate(rows, 1):
        price_str = f"{currency} {row['price']:,.0f}"
        dur_str = format_duration(row["duration"])
        stop_str = f"{row['stops']}stop" if row["stops"] > 0 else "direct"

        print(f"#{i:<3} {price_str:<14} {dur_str:<10} {stop_str:<8} {row['carriers']:<16} via {row['agent']}")

        for seg in row["segments"]:
            seg_dur = format_duration(seg["duration"])
            line = f"     {seg['flight']:<8} {seg['origin']} {seg['dep_local']:<8}-> {seg['dest']} {seg['arr_local']:<8} {seg_dur}"
            if seg["dep_body"] and seg["arr_body"]:
                line += f"  (body: {seg['dep_body']}->{seg['arr_body']})"
            print(line)

        # Layover info between segments
        if len(row["segments"]) > 1:
            layover_parts = []
            for j in range(len(row["segments"]) - 1):
                seg_a = row["segments"][j]
                seg_b = row["segments"][j + 1]
                # Compute layover from raw segment arrival/departure
                # We have local time strings which may have +N suffixes
                city = seg_a["dest"]
                layover_parts.append(city)
            print(f"     Layovers at: {', '.join(layover_parts)}")
        print()

    return rows


def main():
    parser = argparse.ArgumentParser(description="Search Skyscanner flights with dual-timezone display")
    parser.add_argument("origin", help="Origin city or airport code")
    parser.add_argument("destination", help="Destination city or airport code")
    parser.add_argument("date", help="Date in YYYY-MM-DD format")
    parser.add_argument("--adults", type=int, default=1, help="Number of adults")
    parser.add_argument("--children", type=str, default="", help="Comma-separated child ages")
    parser.add_argument("--cabin", default="economy", choices=["economy", "premiumeconomy", "business", "first"])
    parser.add_argument("--currency", default="AUD", help="Currency code")
    parser.add_argument("--market", default="AU", help="Market code")
    parser.add_argument("--top", type=int, default=15, help="Number of results to show")
    parser.add_argument("--sort", default="price", choices=["price", "duration", "stops"])
    parser.add_argument("--json", action="store_true", help="Output raw JSON")
    args = parser.parse_args()

    child_ages = [int(a.strip()) for a in args.children.split(",") if a.strip()] if args.children else []

    print("Resolving airports...", file=sys.stderr)
    origin_code, origin_iata, origin_name = resolve_code(args.origin)
    dest_code, dest_iata, dest_name = resolve_code(args.destination)

    print(f"Searching: {origin_name} ({origin_code}) -> {dest_name} ({dest_code}) on {args.date}", file=sys.stderr)

    data = fetch_flights(
        origin_code, dest_code, args.date,
        adults=args.adults, child_ages=child_ages,
        cabin=args.cabin, currency=args.currency, market=args.market,
    )

    if args.json:
        json.dump(data, sys.stdout, indent=2)
        return

    n_itin = len(data.get("itineraries", []))
    print(f"Found {n_itin} itineraries.", file=sys.stderr)

    if n_itin == 0:
        print("No flights found. The route may not be available on this date.")
        sys.exit(0)

    format_results(data, origin_iata, dest_iata, sort_by=args.sort, top_n=args.top)


if __name__ == "__main__":
    main()
