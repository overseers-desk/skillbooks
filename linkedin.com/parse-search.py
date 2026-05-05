#!/usr/bin/env python3
"""Parse LinkedIn people search results HTML to extract profile URLs and headlines.

Usage: python3 parse-search.py <html-file>

LinkedIn's DOM uses randomised class names, so we cannot select by class.
Instead we:
  1. Find all /in/ profile slugs in the HTML
  2. For each slug, extract nearby visible text to identify the person's name/headline
  3. Output: URL, inferred name, inferred headline
"""

import re
import sys


def parse_search_results(html_path):
    with open(html_path, "r") as f:
        html = f.read()

    # Check if this is a login page
    title_match = re.findall(r"<title[^>]*>(.*?)</title>", html, re.DOTALL)
    title = title_match[0].strip() if title_match else ""
    if any(t in title.lower() for t in ["sign in", "log in", "iniciar"]):
        print("ERROR: LinkedIn session expired. Log in via a Chrome-compatible browser first.")
        sys.exit(1)

    print(f"Page title: {title}")
    print(f"HTML size: {len(html):,} bytes")
    print()

    # Extract profile slugs — use the simpler pattern that works with modern DOM
    # The href="https://..." pattern often fails because LinkedIn uses relative
    # URLs or encodes them differently. This catches all /in/ references.
    slugs = re.findall(r"linkedin\.com/in/([a-zA-Z0-9_-]+)", html)
    seen = set()
    unique = []
    for s in slugs:
        if s not in seen:
            seen.add(s)
            unique.append(s)

    if not unique:
        print("No profiles found in search results.")
        print("Possible causes: login required, empty results, or DOM structure changed.")
        return

    print(f"Found {len(unique)} unique profiles:\n")

    for slug in unique:
        # Find the slug in HTML and extract nearby visible text
        idx = html.find(f"/in/{slug}")
        if idx < 0:
            continue

        # Get a window of HTML around the profile link
        # LinkedIn's DOM is tag-heavy; visible text for each card spans ~4KB
        window = html[max(0, idx - 2000) : idx + 3000]

        # Extract visible text between tags (>text<)
        fragments = re.findall(r">([^<]{3,300})<", window)

        # Filter out CSS/JS/framework noise
        noise_re = re.compile(
            r"_[0-9a-f]{8}|componentkey|tabindex|aria-|data-display"
            r"|function\s|var |\.video|padding|margin:|display:|"
            r"font-|overflow|opacity|cursor:|visibility|pointer-events"
        )
        clean_parts = []
        seen = set()
        for frag in fragments:
            frag = frag.strip()
            # Decode HTML entities
            frag = frag.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
            if not frag or frag in seen:
                continue
            if noise_re.search(frag):
                continue
            if len(frag) < 5:
                continue
            # Skip connection degree indicators (e.g. "• 3er+", "• 2nd")
            if re.match(r"^[•·]\s*\d", frag):
                continue
            seen.add(frag)
            clean_parts.append(frag)

        headline = " | ".join(clean_parts[:5]) if clean_parts else "(no text extracted)"

        # Truncate
        if len(headline) > 300:
            headline = headline[:300] + "..."

        print(f"  https://www.linkedin.com/in/{slug}/")
        print(f"    {headline}")
        print()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <search-results.html>")
        sys.exit(1)
    parse_search_results(sys.argv[1])
