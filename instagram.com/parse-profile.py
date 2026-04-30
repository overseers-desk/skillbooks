#!/usr/bin/env python3
"""Parse an Instagram profile page HTML.

Usage: python3 parse-profile.py <html-file>

Third-party profile dumps in a headless browser reliably contain:
  - <meta property="og:title">        — "Display Name (@handle) • ..."
  - <meta property="og:description">  — "N followers, M following, K posts - ..."
  - <meta property="og:url">          — canonical URL, source of truth for handle
  - <meta property="og:image">        — avatar
  - <meta name="description">         — same counts + a snippet of a recent caption

GraphQL-hydrated JSON fields (biography, external_url, is_verified) are usually
NOT populated within a normal virtual-time-budget for a profile the viewer does
not already follow. The logged-in user's OWN profile data often IS in the dump
(hydrated in the left-nav app shell) — the parser filters those out by keying
on the og:url handle.

Counts are parsed locale-agnostically: the og:description contains three
numbers in a fixed order (followers, following, posts) regardless of language.
"""

import json
import re
import sys
from html import unescape


def get_meta(html, key_attr, key_value):
    """Return content of <meta {key_attr}='{key_value}' content='...'> — both orders."""
    patterns = [
        rf'<meta[^>]*{key_attr}="{re.escape(key_value)}"[^>]*content="([^"]*)"',
        rf'<meta[^>]*content="([^"]*)"[^>]*{key_attr}="{re.escape(key_value)}"',
    ]
    for p in patterns:
        m = re.search(p, html)
        if m:
            return unescape(m.group(1))
    return None


def parse_count_triple(og_desc):
    """From 'N followers, M following, K posts - ...' extract three numbers.

    Works across locales (English, Spanish, etc.) because the three numeric
    tokens always appear in the same order, separated by the locale's
    equivalents of 'followers', 'following', 'posts', and comma/space.

    Numbers may include thousand separators (',' or '.') and unit suffixes
    (K, M, B, or localised Mil/Mio). We return the three raw strings.
    """
    if not og_desc:
        return None
    # Cut off at the first " - " or " • " — the counts always precede that
    head = re.split(r"\s[-–—]\s|\s•\s", og_desc, maxsplit=1)[0]
    # Extract tokens that look like numbers, optionally with suffix letter
    nums = re.findall(r"[\d][\d\.,]*[KMB]?", head, flags=re.IGNORECASE)
    if len(nums) >= 3:
        return nums[:3]
    return None


def parse_handle_and_name(og_title, og_url):
    """og:title looks like 'Display Name (@handle) • Fotos y vídeos de Instagram'.

    og:url looks like 'https://www.instagram.com/handle/' — this is the
    authoritative source for the handle.
    """
    handle = None
    if og_url:
        m = re.search(r"instagram\.com/([A-Za-z0-9_.]+)/?", og_url)
        if m:
            handle = m.group(1)

    name = None
    if og_title:
        # Prefer the part before " (@" — that's the display name
        m = re.match(r"^(.*?)\s*\(@([A-Za-z0-9_.]+)\)", og_title)
        if m:
            name = m.group(1).strip()
            if not handle:
                handle = m.group(2)

    return handle, name


def parse_recent_caption(meta_description):
    """The <meta name='description'> tag includes: 'Name (@handle) on/en Instagram: "caption"'.

    Extract the quoted caption if present.
    """
    if not meta_description:
        return None
    # Look for text in double or smart quotes after "Instagram:"
    m = re.search(r'Instagram:\s*["“](.+?)["”]', meta_description)
    return m.group(1).strip() if m else None


def extract_json_fields_for_handle(html, handle):
    """When the profile's own data is hydrated inline (e.g. the logged-in user's
    own profile), JSON objects contain biography / external_url / follower_count.

    We look for any JSON object within a window around '"username":"<handle>"'.
    Returns a dict of any fields we found.
    """
    if not handle:
        return {}
    out = {}
    for m in re.finditer(r'"username"\s*:\s*"' + re.escape(handle) + r'"', html):
        window = html[max(0, m.start() - 3000):m.end() + 5000]
        for field in ("biography", "full_name", "external_url",
                      "category_name", "business_category_name"):
            mm = re.search(rf'"{field}"\s*:\s*"([^"]{{0,500}})"', window)
            if mm and field not in out:
                try:
                    out[field] = json.loads(f'"{mm.group(1)}"')
                except Exception:
                    out[field] = mm.group(1)
        for field in ("follower_count", "following_count", "media_count"):
            mm = re.search(rf'"{field}"\s*:\s*(\d+)', window)
            if mm and field not in out:
                out[field] = int(mm.group(1))
        for field in ("is_verified", "is_private"):
            mm = re.search(rf'"{field}"\s*:\s*(true|false)', window)
            if mm and field not in out:
                out[field] = mm.group(1) == "true"
    return out


def main(path):
    with open(path, "r") as f:
        html = f.read()

    # Login redirect check
    if "/accounts/login" in html[:30000] and "og:url" not in html[:50000]:
        print("ERROR: redirected to /accounts/login/. Log in via Chrome or a Chrome-compatible browser first.")
        sys.exit(1)

    og_title = get_meta(html, "property", "og:title")
    og_desc = get_meta(html, "property", "og:description")
    og_url = get_meta(html, "property", "og:url")
    og_image = get_meta(html, "property", "og:image")
    meta_desc = get_meta(html, "name", "description")

    handle, name = parse_handle_and_name(og_title, og_url)
    counts = parse_count_triple(og_desc)
    caption_snippet = parse_recent_caption(meta_desc)

    print(f"HTML size: {len(html):,} bytes")
    if not (og_title or og_url):
        print("WARNING: no og:* tags found. Page may be a login redirect or an error page.")

    print()
    if handle:
        print(f"handle:   @{handle}")
        print(f"url:      https://www.instagram.com/{handle}/")
    if name:
        print(f"name:     {name}")
    if counts:
        # The og:description order is: followers, following, posts
        print(f"followers: {counts[0]}")
        print(f"following: {counts[1]}")
        print(f"posts:     {counts[2]}")
    if og_image:
        print(f"avatar:   {og_image}")

    # JSON-hydrated fields (may be absent for third-party profiles)
    extra = extract_json_fields_for_handle(html, handle) if handle else {}
    if extra:
        print()
        print("Hydrated JSON fields (when present):")
        for k in ("full_name", "biography", "external_url", "category_name",
                  "business_category_name", "follower_count", "following_count",
                  "media_count", "is_verified", "is_private"):
            if k in extra:
                print(f"  {k}: {extra[k]}")

    if caption_snippet:
        print()
        print(f"recent-post caption snippet: {caption_snippet}")

    print()
    print("--- og:description (raw) ---")
    print(og_desc or "(none)")
    print()
    print("--- meta name=description (raw) ---")
    print(meta_desc or "(none)")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <profile.html>")
        sys.exit(1)
    main(sys.argv[1])
