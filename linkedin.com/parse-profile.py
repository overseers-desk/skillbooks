#!/usr/bin/env python3
"""Parse a LinkedIn profile page HTML to extract structured information.

Usage: python3 parse-profile.py <html-file>

LinkedIn's DOM uses randomised class names (e.g. _38cb7509 d1e9ae31).
We cannot select elements by class. Instead we extract:

  1. <title> tag — always "Name | LinkedIn"
  2. <meta name="description"> / <meta property="og:description"> — sometimes has summary
  3. Raw visible text — extract >content< patterns, filter out CSS/JS noise
  4. Role keywords — filter text fragments for "at", "Director", "Manager", etc.
"""

import re
import sys


def strip_viewer_content(html):
    """Remove logged-in viewer's own profile data from the page.

    LinkedIn embeds the viewer's profile in <nav> and <aside> elements.
    Without this, text extracted from those sections (viewer's headline,
    bio, employer) pollutes the target profile's output.
    """
    html = re.sub(r'<nav\b[^>]*>.*?</nav>', '', html, flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<aside\b[^>]*>.*?</aside>', '', html, flags=re.DOTALL | re.IGNORECASE)
    for marker in [
        "People also viewed",
        "People you may know",
        "You might also know",
        "Explore collaborative articles",
        "Add profile section",
        "More profiles for you",
    ]:
        idx = html.find(marker)
        if idx > 5000:
            html = html[:idx]
            break
    return html


def parse_profile(html_path):
    with open(html_path, "r") as f:
        html = f.read()

    html = strip_viewer_content(html)

    # --- Title (Name) ---
    title_match = re.findall(r"<title[^>]*>(.*?)</title>", html, re.DOTALL)
    title = title_match[0].strip() if title_match else "NOT FOUND"

    # Check for login page
    if any(t in title.lower() for t in ["sign in", "log in", "iniciar"]):
        print("ERROR: LinkedIn session expired. Log in via a Chrome-compatible browser first.")
        sys.exit(1)

    name = title.replace(" | LinkedIn", "").strip() if " | LinkedIn" in title else title
    print(f"Name: {name}")
    print(f"HTML size: {len(html):,} bytes")

    # --- Meta descriptions ---
    for tag in ["description", "og:description", "og:title"]:
        # Try both attribute orders (name before content, content before name)
        pat1 = re.findall(
            rf'<meta[^>]*(?:name|property)="{tag}"[^>]*content="([^"]*)"', html
        )
        pat2 = re.findall(
            rf'<meta[^>]*content="([^"]*)"[^>]*(?:name|property)="{tag}"', html
        )
        content = (pat1 or pat2 or [None])[0]
        if content:
            print(f"\n{tag}: {content[:500]}")

    # --- Headline ---
    # The headline often appears as visible text right after the name.
    # Look for text fragments that contain "at " (role at company pattern).
    texts = extract_visible_texts(html)

    role_texts = [
        t for t in texts
        if any(kw in t for kw in [" at ", "Director", "Manager", "CEO",
                                   "Founder", "Chairman", "Partner",
                                   "Consultant", "Engineer", "Analyst",
                                   "President", "Owner", "Principal"])
    ]
    if role_texts:
        print(f"\nHeadline (inferred): {role_texts[0]}")
        if len(role_texts) > 1:
            print("Other role mentions:")
            for t in role_texts[1:10]:
                print(f"  - {t}")

    # --- Location ---
    # Match short text that looks like a location: "City, Country", "Region Area",
    # "City y alrededores", or well-known country/region names.
    location_texts = [
        t for t in texts
        if len(t) < 100 and re.search(
            r'(?i)\b(?:area|alrededores|España|Spain|France|Germany|Italy|'
            r'Australia|United\s+States|United\s+Kingdom|Ireland|Singapore|'
            r'California|Texas|Florida|Illinois|Washington|'
            r'Hong\s+Kong|Indonesia|Japan|Malaysia)\b'
            r'|[A-Z][a-z]+(?:,\s*[A-Z][a-z]+)+', t
        )
    ]
    if location_texts:
        print(f"\nLocation (inferred): {location_texts[0]}")

    # --- All meaningful text blocks ---
    print(f"\n--- Visible text blocks ({len(texts)} extracted) ---")
    for t in texts[:50]:
        print(f"  {t}")

    print(f"\n--- End of profile parse ---")


def extract_visible_texts(html):
    """Extract visible text content from LinkedIn's obfuscated DOM.

    Strategy: find all text between > and < that is 10-500 chars,
    then filter out CSS, JS, and framework noise.
    """
    # Extract text between tags
    raw = re.findall(r">([^<]{10,500})<", html)

    # Filter out noise
    noise_patterns = [
        r"^\s*\{",           # JSON objects
        r"^\s*\.",           # CSS selectors
        r"^\s*var ",         # JS variables
        r"^\s*function",     # JS functions
        r"width:",           # CSS properties
        r"padding",          # CSS properties
        r"margin:",          # CSS properties
        r"font-",            # CSS properties
        r"display:",         # CSS properties
        r"background",       # CSS properties
        r"border",           # CSS properties
        r"position:",        # CSS properties
        r"overflow",         # CSS properties
        r"opacity",          # CSS properties
        r"color:",           # CSS properties
        r"transform",        # CSS properties
        r"transition",       # CSS properties
        r"animation",        # CSS properties
        r"z-index",          # CSS properties
        r"box-shadow",       # CSS properties
        r"text-decoration",  # CSS properties
        r"line-height",      # CSS properties
        r"letter-spacing",   # CSS properties
        r"white-space",      # CSS properties
        r"flex",             # CSS properties
        r"grid",             # CSS properties
        r"align-",           # CSS properties
        r"justify-",         # CSS properties
        r"cursor:",          # CSS properties
        r"visibility",       # CSS properties
        r"pointer-events",   # CSS properties
        r"componentkey",     # LinkedIn framework
        r"data-display",     # LinkedIn framework
        r"tabindex",         # HTML attributes
        r"aria-",            # Accessibility attributes (in text context = noise)
        r"\.video-js",       # Video player CSS
        r"vjs-",             # Video player
        r"_[0-9a-f]{8}",    # Randomised class names
    ]

    filtered = []
    seen = set()
    for text in raw:
        text = text.strip()
        if not text or text in seen:
            continue
        if any(re.search(p, text) for p in noise_patterns):
            continue
        if len(text) < 10:
            continue
        seen.add(text)
        filtered.append(text)

    return filtered


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <profile.html>")
        sys.exit(1)
    parse_profile(sys.argv[1])
