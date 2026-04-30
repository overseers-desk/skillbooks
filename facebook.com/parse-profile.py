#!/usr/bin/env python3
"""Parse a Facebook profile page HTML to extract structured information.

Usage: python3 parse-profile.py <html-file>

Facebook's DOM uses randomised class names (e.g. x1lliihq x6ikm8r).
We cannot select elements by class. Instead we extract:

  1. <title> tag — usually "Name | Facebook" or just "Name"
  2. <meta name="description"> / <meta property="og:description"> — may contain bio
  3. Raw visible text — extract >content< patterns, filter out CSS/JS noise
  4. JSON-LD or embedded JSON data if present
"""

import json
import re
import sys


def parse_profile(html_path):
    with open(html_path, "r") as f:
        html = f.read()

    # --- Title (Name) ---
    title_match = re.findall(r"<title[^>]*>(.*?)</title>", html, re.DOTALL)
    title = title_match[0].strip() if title_match else "NOT FOUND"

    # Check for login page
    if any(t in title.lower() for t in ["log in", "log into", "iniciar sesión"]):
        print("ERROR: Facebook session expired. Log in via Chrome or a Chrome-compatible browser first.")
        sys.exit(1)

    # Extract name from title — Facebook uses various formats:
    # "Name | Facebook", "Name - Facebook", or just "Name"
    name = title
    for sep in [" | Facebook", " - Facebook", " – Facebook"]:
        if sep in name:
            name = name.split(sep)[0].strip()
            break

    print(f"Name: {name}")
    print(f"HTML size: {len(html):,} bytes")

    # --- Meta descriptions ---
    for tag in ["description", "og:description", "og:title"]:
        pat1 = re.findall(
            rf'<meta[^>]*(?:name|property)="{tag}"[^>]*content="([^"]*)"', html
        )
        pat2 = re.findall(
            rf'<meta[^>]*content="([^"]*)"[^>]*(?:name|property)="{tag}"', html
        )
        content = (pat1 or pat2 or [None])[0]
        if content:
            # Decode HTML entities
            content = content.replace("&amp;", "&").replace("&lt;", "<")
            content = content.replace("&gt;", ">").replace("&#39;", "'")
            content = content.replace("&quot;", '"')
            print(f"\n{tag}: {content[:500]}")

    # --- Try to extract bio from JSON-LD ---
    json_ld_matches = re.findall(
        r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>',
        html, re.DOTALL
    )
    for blob in json_ld_matches:
        try:
            data = json.loads(blob)
            if isinstance(data, dict):
                if data.get("@type") == "Person":
                    print(f"\nJSON-LD Person data found:")
                    for k, v in data.items():
                        if k.startswith("@"):
                            continue
                        print(f"  {k}: {v}")
        except (json.JSONDecodeError, TypeError):
            pass

    # --- Extract visible text ---
    texts = extract_visible_texts(html)

    # --- Bio / Intro ---
    # Facebook's intro section often contains short phrases about work, education, location
    # Look for common bio patterns
    bio_keywords = [
        "Lives in", "From", "Works at", "Studied at", "Went to",
        "Married", "Single", "In a relationship", "Engaged",
        "Born on", "Joined Facebook",
        "Vive en", "De", "Trabaja en", "Estudió en",  # Spanish locale
    ]
    bio_texts = [t for t in texts if any(kw in t for kw in bio_keywords)]
    if bio_texts:
        print(f"\nBio/Intro lines:")
        for t in bio_texts[:10]:
            print(f"  - {t}")

    # --- Work / Role ---
    role_keywords = [
        " at ", "Director", "Manager", "CEO", "Founder", "Chairman",
        "Partner", "Consultant", "Engineer", "Analyst", "President",
        "Owner", "Principal", "CTO", "COO", "CFO", "VP ",
        "Vice President", "Head of",
    ]
    role_texts = [
        t for t in texts
        if any(kw in t for kw in role_keywords)
        and len(t) < 200
    ]
    if role_texts:
        print(f"\nRole/Work mentions:")
        for t in role_texts[:10]:
            print(f"  - {t}")

    # --- Location ---
    location_texts = [
        t for t in texts
        if re.search(
            r"India|Mumbai|Delhi|Bangalore|Kolkata|Chennai|Hyderabad|Pune|"
            r"Singapore|Australia|London|New York|Hong Kong|San Francisco|"
            r"Los Angeles|Toronto|Berlin|Paris|Tokyo|Dubai",
            t
        )
        and len(t) < 150
    ]
    if location_texts:
        print(f"\nLocation mentions:")
        for t in location_texts[:5]:
            print(f"  - {t}")

    # --- All meaningful text blocks ---
    print(f"\n--- Visible text blocks ({len(texts)} extracted) ---")
    for t in texts[:80]:
        print(f"  {t}")

    print(f"\n--- End of profile parse ---")


def extract_visible_texts(html):
    """Extract visible text content from Facebook's obfuscated DOM.

    Strategy: find all text between > and < that is 5-500 chars,
    then filter out CSS, JS, and framework noise.
    """
    # Extract text between tags
    raw = re.findall(r">([^<]{5,500})<", html)

    # Filter out noise
    noise_patterns = [
        r"^\s*\{",           # JSON objects
        r"^\s*\.",           # CSS selectors
        r"^\s*var ",         # JS variables
        r"^\s*function",     # JS functions
        r"^\s*return ",      # JS return
        r"^\s*if\s*\(",      # JS if
        r"width:",           # CSS properties
        r"padding",
        r"margin:",
        r"font-",
        r"display:",
        r"background",
        r"border",
        r"position:",
        r"overflow",
        r"opacity",
        r"color:",
        r"transform",
        r"transition",
        r"animation",
        r"z-index",
        r"box-shadow",
        r"text-decoration",
        r"line-height",
        r"letter-spacing",
        r"white-space",
        r"flex",
        r"grid",
        r"align-",
        r"justify-",
        r"cursor:",
        r"visibility",
        r"pointer-events",
        r"x[0-9a-z]{7,}",   # Facebook randomised class names
        r"__MODULE",         # Facebook module system
        r"webpack",
        r"require\(",
        r"exports\.",
        r"React\.",
        r"componentkey",
        r"data-display",
        r"tabindex",
        r"aria-",
    ]

    filtered = []
    seen = set()
    for text in raw:
        text = text.strip()
        if not text or text in seen:
            continue
        if any(re.search(p, text) for p in noise_patterns):
            continue
        if len(text) < 5:
            continue
        # Decode common HTML entities
        text = text.replace("&amp;", "&").replace("&lt;", "<")
        text = text.replace("&gt;", ">").replace("&#39;", "'")
        text = text.replace("&quot;", '"').replace("&#x2F;", "/")
        seen.add(text)
        filtered.append(text)

    return filtered


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <profile.html>")
        sys.exit(1)
    parse_profile(sys.argv[1])
