#!/usr/bin/env python3
"""Parse Qantas Flight Reward Finder HTML — extract Classic Reward flight availability.

Usage:
    python3 parse-rewards.py /tmp/qantas-frf.html
"""

import json
import re
import sys
from datetime import datetime


def _extract_payload(html: str) -> str:
    chunks = re.findall(r'__next_f\.push\(\[(.*?)\]\)</script>', html, re.DOTALL)
    payload = ""
    for c in chunks:
        try:
            parts = json.loads("[" + c + "]")
            if len(parts) >= 2 and isinstance(parts[1], str):
                payload += parts[1]
        except Exception:
            pass
    return payload


_MAX_RECORD_BYTES = 16 * 1024  # availability records are typically <2KB; cap at 16KB


def _find_record_end(text: str, start: int) -> int:
    """Walk forward from `start` (which must point at `{`), tracking string state.
    Returns the index just after the matching `}`, or -1 if not found within
    _MAX_RECORD_BYTES. Bounded — cannot allocate or scan more than the cap."""
    end_limit = min(len(text), start + _MAX_RECORD_BYTES)
    depth = 0
    in_string = False
    escape = False
    for i in range(start, end_limit):
        ch = text[i]
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
        elif ch == '"':
            in_string = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i + 1
    return -1


def _extract_availability_records(text: str) -> list[dict]:
    """Find all availability records: objects starting with `{"id":<digits>,` that
    also contain a `"cabins":` key. Bounded per-record; safe on malformed payloads."""
    results = []
    for m in re.finditer(r'\{"id":\d+,', text):
        start = m.start()
        end = _find_record_end(text, start)
        if end == -1:
            continue
        chunk = text[start:end]
        if '"cabins":' not in chunk:
            continue
        try:
            obj = json.loads(chunk)
        except Exception:
            continue
        if isinstance(obj.get("cabins"), dict):
            results.append(obj)
    return results


def parse(html_path: str) -> list[dict]:
    with open(html_path) as f:
        html = f.read()

    payload = _extract_payload(html)
    if not payload:
        return []

    records = _extract_availability_records(payload)

    flights = []
    for rec in records:
        if not isinstance(rec.get("cabins"), dict):
            continue
        legs = rec.get("legs", [])
        if not legs:
            continue

        departs_raw = rec.get("departsAt", "")
        arrives_raw = rec.get("arrivesAt", "")
        day_offset = rec.get("arrivalDayOffset", 0)
        duration = rec.get("duration", "")
        stopovers = rec.get("stopovers", 0)
        origin = rec.get("origin", {}).get("code", "?")
        dest = rec.get("destination", {}).get("code", "?")

        # Collect leg flight numbers and aircraft
        leg_flights = [l.get("flightNumber", "") for l in legs]
        aircraft = legs[0].get("equipment", "") if len(legs) == 1 else ""

        try:
            dep_dt = datetime.fromisoformat(departs_raw)
            arr_dt = datetime.fromisoformat(arrives_raw)
            dep_str = dep_dt.strftime("%H:%M")
            arr_str = arr_dt.strftime("%H:%M")
            date_str = dep_dt.strftime("%a %d %b %Y")
        except Exception:
            dep_str = departs_raw
            arr_str = arrives_raw
            date_str = departs_raw[:10]

        arr_label = arr_str + (f" (+{day_offset})" if day_offset else "")

        cabin_lines = []
        for name in ("Economy", "PremiumEconomy", "Business", "First"):
            cab = rec["cabins"].get(name)
            if not cab:
                continue
            label = "Prem Economy" if name == "PremiumEconomy" else name
            pts = cab.get("points", "?")
            tax = cab.get("tax", "?")
            currency = cab.get("currency", "")
            seats = cab.get("seats", "?")
            pts_fmt = f"{pts:,}" if isinstance(pts, int) else str(pts)
            cabin_lines.append(
                f"  {label}: {pts_fmt} pts + {currency}{tax} tax  ({seats} seats)"
            )

        flights.append({
            "date": date_str,
            "flight": "/".join(leg_flights),
            "route": f"{origin}→{dest}",
            "departs": dep_str,
            "arrives": arr_label,
            "duration": duration,
            "aircraft": aircraft,
            "stopovers": stopovers,
            "cabin_lines": cabin_lines,
        })

    return flights


def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: parse-rewards.py <html-file>")

    flights = parse(sys.argv[1])
    if not flights:
        print("No Classic Reward flights found in this page.")
        return

    print("Classic Flight Reward availability (flightrewardfinder.qantas.com):")
    print()
    for f in flights:
        stops = "nonstop" if f["stopovers"] == 0 else f"{f['stopovers']} stop(s)"
        aircraft = f"  {f['aircraft']}" if f["aircraft"] else ""
        print(f"{f['flight']}  {f['date']}  {f['route']}  {f['departs']} → {f['arrives']}  {f['duration']}  {stops}{aircraft}")
        for line in f["cabin_lines"]:
            print(line)
        print()


if __name__ == "__main__":
    main()
