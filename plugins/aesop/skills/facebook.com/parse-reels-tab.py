#!/usr/bin/env python3
"""Parse a Facebook profile reels-tab HTML to extract reel cards with view counts.

Usage: python3 parse-reels-tab.py <html-file>

URL form: https://www.facebook.com/profile.php?id=NUMERIC_ID&sk=reels_tab
       or https://www.facebook.com/USERNAME/reels

Headless renders typically yield ~3 reel cards before lazy-load kicks in.
Per card it extracts:
  - reel ID (the /reel/NNNNN link)
  - view count (e.g. 191K, 1.5M)

Structural markers (class names are randomised and cannot be used):
  - Eye SVG path `d="M7.5 10a2.5 2.5 0 1 1 5 0 2.5 2.5 0 0 1-5 0z"` marks
    each view-count widget.
  - The count text is in the first <span>...</span> after the SVG.
  - The reel ID for each card is the last /reel/NNNNN link occurring before
    the eye SVG (cards are laid out link-then-count).
"""

import re
import sys

EYE_SVG_PATH = r'M7\.5 10a2\.5 2\.5 0 1 1 5 0 2\.5 2\.5 0 0 1-5 0z'
COUNT_RE = re.compile(r'<span[^>]*>([\d.,]+[KMB]?)</span>')


def parse_reels_tab(html_path):
    with open(html_path, "r") as f:
        html = f.read()

    title_match = re.findall(r"<title[^>]*>(.*?)</title>", html, re.DOTALL)
    title = title_match[0].strip() if title_match else "NOT FOUND"
    if any(t in title.lower() for t in ["log in", "log into", "iniciar sesión"]):
        print("ERROR: Facebook session expired. Log in via a Chrome-compatible browser first.")
        sys.exit(1)

    name = title
    for sep in [" | Facebook", " - Facebook", " – Facebook"]:
        if sep in name:
            name = name.split(sep)[0].strip()
            break

    print(f"Profile: {name}")
    print(f"HTML size: {len(html):,} bytes")

    eye_positions = [m.start() for m in re.finditer(EYE_SVG_PATH, html)]
    reel_links = [(m.start(), m.group(1)) for m in re.finditer(r'/reel/(\d+)', html)]

    if not eye_positions:
        print("\nNo reel cards found (no view-count SVG markers).")
        print("The reels tab may be empty, or the DOM structure has changed.")
        return

    print(f"Reels rendered: {len(eye_positions)}")
    print("(Headless dumps do not scroll-load; the full list may be longer.)")
    print()

    seen = set()
    for i, pos in enumerate(eye_positions, 1):
        preceding = [rid for (rp, rid) in reel_links if rp < pos]
        reel_id = preceding[-1] if preceding else None

        after = html[pos:pos + 1500]
        count_m = COUNT_RE.search(after)
        count = count_m.group(1) if count_m else "N/A"

        key = (reel_id, count)
        if key in seen:
            continue
        seen.add(key)

        print(f"=== REEL {i} ===")
        print(f"  URL:   https://www.facebook.com/reel/{reel_id}")
        print(f"  Views: {count}")
        print()

    print(f"--- End of reels-tab parse ({len(seen)} unique reels) ---")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <reels-tab.html>")
        sys.exit(1)

    parse_reels_tab(sys.argv[1])
