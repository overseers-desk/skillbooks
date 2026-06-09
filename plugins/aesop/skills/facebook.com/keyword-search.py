#!/usr/bin/env python3
"""Search a Facebook profile HTML for specific keywords and show context.

Usage: python3 keyword-search.py <html-file> keyword1 keyword2 ...

For each keyword found, prints the count and surrounding text (with HTML tags stripped).
Useful for quickly checking whether a profile mentions specific companies,
roles, locations, or topics without reading the entire DOM.
"""

import re
import sys


def keyword_search(html_path, keywords):
    with open(html_path, "r") as f:
        html = f.read()

    title_match = re.findall(r"<title[^>]*>(.*?)</title>", html, re.DOTALL)
    title = title_match[0].strip() if title_match else "NOT FOUND"
    print(f"Profile: {title}")
    print(f"HTML size: {len(html):,} bytes")
    print()

    found_any = False
    for kw in keywords:
        matches = list(re.finditer(re.escape(kw), html, re.IGNORECASE))
        if not matches:
            print(f"  {kw}: NOT FOUND")
            continue

        found_any = True
        print(f"  {kw}: {len(matches)} occurrences")

        # Show up to 3 unique context snippets
        seen_contexts = set()
        shown = 0
        for m in matches:
            if shown >= 3:
                break
            # Extract surrounding HTML and strip tags
            start = max(0, m.start() - 200)
            end = min(len(html), m.end() + 300)
            ctx = html[start:end]
            clean = re.sub(r"<[^>]+>", " ", ctx)
            clean = re.sub(r"\s+", " ", clean).strip()

            # Skip framework noise
            if any(noise in clean for noise in ["__MODULE", "webpack", "require("]):
                continue
            if len(clean) < 30:
                continue

            # Deduplicate similar contexts
            sig = clean[:100]
            if sig in seen_contexts:
                continue
            seen_contexts.add(sig)

            print(f"    ...{clean[:400]}...")
            shown += 1

        print()

    if not found_any:
        print("None of the keywords were found in this profile.")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <profile.html> keyword1 [keyword2 ...]")
        sys.exit(1)
    keyword_search(sys.argv[1], sys.argv[2:])
