#!/usr/bin/env python3
"""Parse Facebook people search results HTML to extract profile URLs and context.

Usage: python3 parse-search.py <html-file>

Facebook's DOM uses randomised class names, so we cannot select by class.
Instead we:
  1. Find all facebook.com profile URLs in the HTML (both /username and /profile.php?id=)
  2. For each URL, extract nearby visible text to identify the person
  3. Output: URL, inferred name, and context (location, mutual friends, etc.)
"""

import re
import sys
from urllib.parse import unquote


def parse_search_results(html_path):
    with open(html_path, "r") as f:
        html = f.read()

    # Check if this is a login page
    title_match = re.findall(r"<title[^>]*>(.*?)</title>", html, re.DOTALL)
    title = title_match[0].strip() if title_match else ""
    if any(t in title.lower() for t in ["log in", "log into", "iniciar sesión", "facebook – log in"]):
        print("ERROR: Facebook session expired. Log in via a Chrome-compatible browser first.")
        sys.exit(1)

    print(f"Page title: {title}")
    print(f"HTML size: {len(html):,} bytes")
    print()

    # Extract profile URLs — two forms:
    # 1. facebook.com/username (vanity URL)
    # 2. facebook.com/profile.php?id=NNNNN (numeric ID)
    #
    # We look for both in href attributes and in raw text.

    # Pattern 1: vanity usernames in href attributes
    vanity_matches = re.findall(
        r'href="https?://(?:www\.)?facebook\.com/([a-zA-Z0-9._]+?)(?:\?|"|/)',
        html
    )

    # Pattern 2: numeric profile IDs
    numeric_matches = re.findall(
        r'href="https?://(?:www\.)?facebook\.com/profile\.php\?id=(\d+)',
        html
    )

    # Also try to find them in non-href contexts (e.g. data attributes, JSON)
    vanity_matches += re.findall(
        r'facebook\.com/([a-zA-Z0-9._]{5,})(?:[?"/&\s])',
        html
    )
    numeric_matches += re.findall(
        r'facebook\.com/profile\.php\?id=(\d+)',
        html
    )

    # Deduplicate while preserving order
    # Filter out known non-profile paths
    non_profile_paths = {
        "search", "groups", "pages", "marketplace", "watch", "events",
        "gaming", "bookmarks", "saved", "friends", "messages", "notifications",
        "settings", "help", "privacy", "policies", "login", "recover",
        "signup", "photo.php", "photo", "hashtag", "stories", "reels",
        "ads", "business", "developers", "places", "offers", "fundraisers",
        "notes", "flx", "ajax", "api", "plugins", "sharer", "dialog",
        "share", "l.php", "checkpoint", "reg", "bluebar", "public",
        "directory", "pages_reaction_units", "ufi", "composer",
    }

    seen = set()
    profiles = []

    for username in vanity_matches:
        username_lower = username.lower().rstrip(".")
        if username_lower in non_profile_paths:
            continue
        if username_lower in seen:
            continue
        # Skip if it looks like a file or resource path
        if "." in username_lower and not username_lower.replace(".", "").isalnum():
            continue
        seen.add(username_lower)
        profiles.append(("vanity", username))

    for nid in numeric_matches:
        if nid in seen:
            continue
        seen.add(nid)
        profiles.append(("numeric", nid))

    if not profiles:
        print("No profiles found in search results.")
        print("Possible causes: login required, empty results, or DOM structure changed.")
        return

    print(f"Found {len(profiles)} unique profiles:\n")

    for ptype, pid in profiles:
        if ptype == "vanity":
            url = f"https://www.facebook.com/{pid}"
            search_term = f"/{pid}"
        else:
            url = f"https://www.facebook.com/profile.php?id={pid}"
            search_term = f"id={pid}"

        # Find the URL in HTML and extract nearby visible text
        idx = html.find(search_term)
        if idx < 0:
            continue

        # Get a window of HTML around the profile link
        window = html[max(0, idx - 2000):idx + 3000]

        # Extract visible text between tags (>text<)
        fragments = re.findall(r">([^<]{3,300})<", window)

        # Filter out CSS/JS/framework noise
        noise_re = re.compile(
            r"_[0-9a-f]{8}|x[0-9a-z]{6,}|componentkey|tabindex|aria-"
            r"|function\s|var |\.video|padding|margin:|display:|"
            r"|font-|overflow|opacity|cursor:|visibility|pointer-events"
            r"|webpack|__MODULE|require\(|exports\.|React\."
        )
        clean_parts = []
        frag_seen = set()
        for frag in fragments:
            frag = frag.strip()
            # Decode HTML entities
            frag = frag.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
            frag = frag.replace("&#x2F;", "/").replace("&#39;", "'").replace("&quot;", '"')
            if not frag or frag in frag_seen:
                continue
            if noise_re.search(frag):
                continue
            if len(frag) < 4:
                continue
            frag_seen.add(frag)
            clean_parts.append(frag)

        headline = " | ".join(clean_parts[:6]) if clean_parts else "(no text extracted)"

        # Truncate
        if len(headline) > 400:
            headline = headline[:400] + "..."

        print(f"  {url}")
        print(f"    {headline}")
        print()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <search-results.html>")
        sys.exit(1)
    parse_search_results(sys.argv[1])
