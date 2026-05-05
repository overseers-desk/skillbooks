#!/usr/bin/env python3
"""Parse Instagram topsearch JSON response.

Usage: python3 parse-search.py <json-file>

Instagram's web search page is GraphQL-hydrated and does not populate results
in a headless DOM dump within a reasonable virtual-time budget. The internal
endpoint /web/search/topsearch/?query=X, when fetched with an authenticated
session, returns clean JSON directly and is the primitive this script expects.

The file may be pure JSON or HTML-wrapped (headless --dump-dom wraps the JSON
body in <html><body><pre>...). This script handles both.
"""

import json
import re
import sys


def load_payload(path):
    with open(path, "r") as f:
        raw = f.read()
    # headless --dump-dom of a JSON endpoint wraps the body in <pre>...</pre>
    m = re.search(r"<pre[^>]*>(.*?)</pre>", raw, re.DOTALL)
    body = m.group(1) if m else raw
    body = body.strip()
    # Decode HTML entities that the browser may have inserted
    body = body.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
    body = body.replace("&quot;", '"').replace("&#39;", "'")
    try:
        return json.loads(body)
    except json.JSONDecodeError as e:
        print(f"ERROR: body is not valid JSON ({e}).")
        # If it looks like an HTML login redirect, say so
        if "login" in raw[:5000].lower() or "/accounts/login" in raw[:5000]:
            print("Looks like the session redirected to /accounts/login/. "
                  "Log in via a Chrome-compatible browser first.")
        else:
            print("First 500 chars of body:")
            print(body[:500])
        sys.exit(1)


def main(path):
    data = load_payload(path)
    users = data.get("users", [])
    places = data.get("places", [])
    hashtags = data.get("hashtags", [])

    print(f"users: {len(users)}   places: {len(places)}   hashtags: {len(hashtags)}")
    print()

    if users:
        print("=== Users ===")
        for entry in users:
            u = entry.get("user", entry)
            handle = u.get("username", "?")
            name = u.get("full_name", "")
            verified = "✓" if u.get("is_verified") else ""
            private = "[private]" if u.get("is_private") else ""
            ctx = u.get("social_context") or u.get("search_social_context") or ""
            url = f"https://www.instagram.com/{handle}/"
            line = f"  @{handle} {verified} {private}".rstrip()
            print(line)
            if name:
                print(f"    name: {name}")
            print(f"    url:  {url}")
            if ctx:
                print(f"    ctx:  {ctx}")
            print()

    if hashtags:
        print("=== Hashtags ===")
        for entry in hashtags:
            h = entry.get("hashtag", entry)
            name = h.get("name", "?")
            count = h.get("media_count", "?")
            print(f"  #{name}   ({count} posts)")
        print()

    if places:
        print("=== Places ===")
        for entry in places:
            p = entry.get("place", entry)
            loc = p.get("location", {}) if isinstance(p.get("location"), dict) else {}
            name = loc.get("name") or p.get("title") or "?"
            address = loc.get("address") or ""
            print(f"  {name}")
            if address:
                print(f"    {address}")
        print()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <topsearch-response.json|.html>")
        sys.exit(1)
    main(sys.argv[1])
