#!/usr/bin/env python3
"""Parse a Facebook profile page HTML to extract recent posts with hashtags and tagged people.

Usage: python3 parse-posts.py <html-file> [--owner-id ID]

Extracts from each post:
  - Post text content
  - Hashtags used
  - Tagged/mentioned people and pages (with profile URLs)

Facebook's DOM uses randomised class names (e.g. x1lliihq x6ikm8r).
We rely on structural markers instead:
  - data-ad-preview="message" marks the start of each post's text content
  - __cft__[0] tokens are unique per post and link all elements (hashtags, tags, photos)
  - /hashtag/TAGNAME links for hashtags
  - Profile/page links with __cft__ tokens for tagged people
"""

import json
import re
import sys
from collections import Counter
from urllib.parse import unquote


def parse_posts(html_path, owner_id=None):
    with open(html_path, "r") as f:
        html = f.read()

    # --- Check for login page ---
    title_match = re.findall(r"<title[^>]*>(.*?)</title>", html, re.DOTALL)
    title = title_match[0].strip() if title_match else "NOT FOUND"
    if any(t in title.lower() for t in ["log in", "log into", "iniciar sesión"]):
        print("ERROR: Facebook session expired. Log in to Chromium first.")
        sys.exit(1)

    name = title
    for sep in [" | Facebook", " - Facebook", " – Facebook"]:
        if sep in name:
            name = name.split(sep)[0].strip()
            break

    print(f"Profile: {name}")
    print(f"HTML size: {len(html):,} bytes")

    # --- Auto-detect owner ID from profile links ---
    if not owner_id:
        owner_id = detect_owner_id(html)
    if owner_id:
        print(f"Owner ID: {owner_id}")

    # --- Find post content markers ---
    preview_positions = [m.start() for m in re.finditer(r'data-ad-preview="message"', html)]
    if not preview_positions:
        print("\nNo posts found (no data-ad-preview markers).")
        print("The profile may have no visible posts, or the DOM structure has changed.")
        return

    print(f"Posts found: {len(preview_positions)}")
    print()

    # --- Build post regions ---
    # Each post region spans from the midpoint between this post and the previous one
    # to the midpoint between this post and the next one.
    posts = []
    for i, pos in enumerate(preview_positions):
        # Region start: midpoint with previous post, or 25000 chars before
        # The first post needs extra lookback because the post header (author,
        # page tags, "shared with") can be 20000+ chars before the content marker
        # due to Facebook's deeply nested DOM.
        if i == 0:
            region_start = max(0, pos - 25000)
        else:
            region_start = (preview_positions[i - 1] + pos) // 2

        # Region end: midpoint with next post, or 10000 chars after
        if i == len(preview_positions) - 1:
            region_end = min(len(html), pos + 15000)
        else:
            region_end = (pos + preview_positions[i + 1]) // 2

        region = html[region_start:region_end]
        content_offset = pos - region_start  # where data-ad-preview is within region

        post = extract_post(region, content_offset, owner_id)
        posts.append(post)

    # --- Output ---
    for i, post in enumerate(posts, 1):
        print(f"=== POST {i} ===")
        if post["content"]:
            print(f"  Content: {post['content']}")
        else:
            print("  Content: (empty or not extracted)")

        if post["hashtags"]:
            print(f"  Hashtags: {', '.join('#' + h for h in post['hashtags'])}")

        if post["tagged"]:
            print(f"  Tagged/mentioned:")
            for tag in post["tagged"]:
                label = tag.get("name", tag["url"])
                print(f"    - {label}  ({tag['url']})")

        if post["shared_from"]:
            print(f"  Shared from: {post['shared_from']}")

        print()

    # --- Summary ---
    all_hashtags = Counter()
    all_tagged = Counter()
    for post in posts:
        for h in post["hashtags"]:
            all_hashtags[h] += 1
        for t in post["tagged"]:
            all_tagged[t.get("name", t["url"])] += 1

    if all_hashtags:
        print("--- Hashtag summary ---")
        for tag, count in all_hashtags.most_common():
            print(f"  #{tag}: {count}")
        print()

    if all_tagged:
        print("--- Tagged/mentioned summary ---")
        for name, count in all_tagged.most_common():
            print(f"  {name}: {count}")
        print()

    print(f"--- End of posts parse ({len(posts)} posts) ---")


def detect_owner_id(html):
    """Try to detect the profile owner's ID from the page.

    The owner's profile link appears many times (once per post header).
    We look for the most frequent profile.php?id= value.
    """
    ids = re.findall(r'facebook\.com/profile\.php\?id=(\d+)', html)
    if ids:
        counter = Counter(ids)
        return counter.most_common(1)[0][0]

    # Check og:url meta tag
    og_url = re.findall(r'<meta[^>]*property="og:url"[^>]*content="([^"]*)"', html)
    if og_url:
        m = re.search(r'id=(\d+)', og_url[0])
        if m:
            return m.group(1)
        m = re.search(r'facebook\.com/([a-zA-Z0-9.]+)', og_url[0])
        if m:
            return m.group(1)

    return None


def extract_post(region, content_offset, owner_id):
    """Extract post data from a region of HTML around a data-ad-preview marker."""
    post = {
        "content": "",
        "hashtags": [],
        "tagged": [],
        "shared_from": None,
    }

    # --- Post text content ---
    # Text is in the region after data-ad-preview="message"
    content_region = region[content_offset:content_offset + 5000]
    texts = extract_visible_texts(content_region)

    # Post content ends at interaction buttons (Like, Comment, Share)
    # or at the next structural element
    stop_words = {"Like", "Comment", "Share", "Send", "Haha", "Love", "Wow",
                  "Sad", "Angry", "Care", "comments", "shares", "All comments",
                  "Most relevant", "Write a comment", "Like this post"}
    content_parts = []
    for t in texts:
        if t in stop_words or t.endswith(" comments") or t.endswith(" shares"):
            break
        # Skip very short noise
        if len(t) < 3:
            continue
        content_parts.append(t)

    post["content"] = " ".join(content_parts)

    # --- Hashtags ---
    hashtags = re.findall(
        r'href="https://www\.facebook\.com/hashtag/([a-zA-Z0-9_]+)',
        region
    )
    post["hashtags"] = list(dict.fromkeys(hashtags))  # dedup, preserve order

    # --- Tagged/mentioned people and pages ---
    # Look for profile/page links that are NOT the owner, NOT photos, NOT hashtags.
    # These appear in the post header ("with Person") or in the post body ("@Person").
    # Links with __cft__ tokens belong to this post's context.
    #
    # Only search the header + content area, not the comments section.
    # Comments appear after the interaction buttons (Like/Comment/Share),
    # which are typically within ~5000 chars after the content marker.
    tag_region = region[:content_offset + 5000]
    #
    # Two patterns:
    #   1. Vanity URLs: facebook.com/USERNAME?__cft__...
    #   2. Numeric IDs: facebook.com/profile.php?id=NNNNN&__cft__...
    # Exclude comment_id links — those are commenters, not tagged people
    vanity_links = re.findall(
        r'href="https://www\.facebook\.com/([a-zA-Z0-9._]+)\?(?!comment_id)[^"]*__cft__[^"]*"',
        tag_region
    )
    numeric_links = re.findall(
        r'href="https://www\.facebook\.com/profile\.php\?id=(\d+)[^"]*__cft__[^"]*"',
        tag_region
    )

    non_profile_paths = {
        "search", "groups", "pages", "marketplace", "watch", "events",
        "photo", "photo.php", "hashtag", "stories", "reels", "reel",
        "ads", "business", "share", "sharer", "dialog", "plugins",
        "l.php", "permalink.php", "story.php", "profile.php",
    }

    seen_tagged = set()

    for username in vanity_links:
        username_lower = username.lower().rstrip(".")
        if username_lower in non_profile_paths:
            continue
        if owner_id and username_lower == owner_id.lower():
            continue
        if username_lower in seen_tagged:
            continue
        seen_tagged.add(username_lower)

        url = f"https://www.facebook.com/{username}"
        link_name = extract_link_name(region, f"/{username}?")
        tag_info = {"url": url}
        if link_name:
            tag_info["name"] = link_name
        post["tagged"].append(tag_info)

    for nid in numeric_links:
        if nid == owner_id:
            continue
        if nid in seen_tagged:
            continue
        seen_tagged.add(nid)

        url = f"https://www.facebook.com/profile.php?id={nid}"
        link_name = extract_link_name(region, f"id={nid}")
        tag_info = {"url": url}
        if link_name:
            tag_info["name"] = link_name
        post["tagged"].append(tag_info)

    # --- Shared from (if this is a shared post) ---
    # Look for "shared" in the header region (before content).
    # The pattern is typically: "Vikram Mazumder" > "shared" > "PageName's" > "post"
    # or "shared a link" / "shared a photo".
    header_region = region[:content_offset]
    header_texts = extract_visible_texts(header_region)
    for j, t in enumerate(header_texts):
        if "shared" in t.lower():
            # Look at the next non-trivial text that looks like a name/page
            for k in range(j + 1, min(j + 4, len(header_texts))):
                candidate = header_texts[k]
                # Skip noise: short fragments, domain-looking strings, nbsp, privacy labels
                if len(candidate) < 3:
                    continue
                if re.match(r'^[A-Za-z0-9]+\.(com|org|net|io)', candidate):
                    continue
                if candidate in ("&nbsp;", "Shared with Public", "Public"):
                    continue
                post["shared_from"] = candidate
                break
            break

    return post


def extract_link_name(html_region, link_path):
    """Extract the visible text associated with a link in the HTML.

    Looks for >visible_text< immediately after the <a> tag containing this link.
    """
    # Find the link in the HTML
    idx = html_region.find(link_path)
    if idx < 0:
        return None

    # Look forward for the closing > of the <a> tag, then find visible text
    after = html_region[idx:idx + 500]
    # Find the first >text< after the link
    texts = re.findall(r">([^<]{2,100})<", after)
    noise_re = re.compile(
        r"x[0-9a-z]{7,}|padding|margin:|display:|font-|overflow|"
        r"opacity|cursor:|visibility|border|position:|background|"
        r"transform|transition|animation|componentkey|tabindex|aria-"
    )
    for t in texts:
        t = t.strip()
        if not t or len(t) < 2:
            continue
        if noise_re.search(t):
            continue
        if t.startswith("{") or t.startswith("."):
            continue
        # Decode entities
        t = t.replace("&amp;", "&").replace("&#39;", "'")
        t = t.replace("&quot;", '"').replace("&#x2F;", "/")
        return t
    return None


def extract_visible_texts(html_fragment):
    """Extract visible text content, filtering out CSS/JS/framework noise."""
    raw = re.findall(r">([^<]{3,2000})<", html_fragment)

    noise_patterns = [
        r"^\s*\{",
        r"^\s*\.",
        r"^\s*var ",
        r"^\s*function",
        r"^\s*return ",
        r"^\s*if\s*\(",
        r"width:",
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
        r"x[0-9a-z]{7,}",
        r"__MODULE",
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
        if len(text) < 3:
            continue
        text = text.replace("&amp;", "&").replace("&lt;", "<")
        text = text.replace("&gt;", ">").replace("&#39;", "'")
        text = text.replace("&quot;", '"').replace("&#x2F;", "/")
        seen.add(text)
        filtered.append(text)

    return filtered


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <profile.html> [--owner-id ID]")
        sys.exit(1)

    html_path = sys.argv[1]
    owner_id = None
    if "--owner-id" in sys.argv:
        idx = sys.argv.index("--owner-id")
        if idx + 1 < len(sys.argv):
            owner_id = sys.argv[idx + 1]

    parse_posts(html_path, owner_id)
