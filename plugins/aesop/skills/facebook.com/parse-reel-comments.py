#!/usr/bin/env python3
"""Parse comments from a Facebook reel HTML capture into Markdown.

Reads the rendered HTML produced by reel-comments-cdp.py and emits a
human-readable markdown file. Each top-level comment is a numbered list
item; replies are nested.

Per-comment fields extracted:
  - Author display name (from aria-label)
  - Age string (e.g. "5 weeks ago", from aria-label)
  - Body text (visible text inside the comment article)
  - Profile URL (from the comment header link)
  - comment_id (decoded from the base64 query parameter when present)

Usage:
    python3 parse-reel-comments.py HTML_FILE [--md OUT.md]
"""

import argparse
import base64
import html as html_mod
import json
import re
import sys
from urllib.parse import unquote


# aria-label shapes observed on the reel:
#   "Comment by NAME AGE"
#   "Reply by NAME to OTHER's (comment|reply) AGE"
# AGE is "N units ago" / "a unit ago" / "just now" / "yesterday[ at TIME]"
# / "Mon DD[, YYYY][ at TIME]".
AGE_PATTERN = (
    r"(?:\d+|a|an)\s+(?:second|minute|hour|day|week|month|year)s?\s+ago"
    r"|just now|yesterday(?:\s+at\s+[^\"]+?)?"
    r"|[A-Z][a-z]+\s+\d+(?:,\s*\d{4})?(?:\s+at\s+[^\"]+?)?"
)
COMMENT_LABEL_RE = re.compile(
    r'aria-label="(Comment|Reply) by (.+?)'
    r'(?:\s+to\s+([^"]+?))?'
    r'\s+(' + AGE_PATTERN + r')"'
)
PROFILE_HREF_RE = re.compile(
    r'href="(https://www\.facebook\.com/(?:profile\.php\?id=\d+|[a-zA-Z0-9._]+)'
    r'[^"]*comment_id=([^"&]+)[^"]*)"'
)
BODY_DIV_RE = re.compile(
    r'<div dir="auto" style="text-align:\s*start;">(.*?)</div>',
    re.DOTALL,
)
INLINE_TAG_RE = re.compile(r"<[^>]+>")
WHITESPACE_RE = re.compile(r"\s+")


def decode_comment_id(b64_param: str) -> str:
    """Decode a Facebook comment_id URL parameter.

    The value is a URL-encoded base64 string of `comment:STORY_COMMENT_ID`.
    Returns just the numeric STORY_COMMENT_ID, or the raw param on failure.
    """
    try:
        raw = unquote(b64_param)
        pad = "=" * (-len(raw) % 4)
        decoded = base64.b64decode(raw + pad).decode("utf-8", "replace")
        # Looks like "comment:122152789796961846_14475806401868891"
        if ":" in decoded:
            return decoded.split(":", 1)[1]
        return decoded
    except Exception:
        return b64_param


def clean_text(s: str) -> str:
    s = INLINE_TAG_RE.sub(" ", s)
    s = html_mod.unescape(s)
    s = WHITESPACE_RE.sub(" ", s).strip()
    return s


def parse(html: str, bodies=None):
    """Parse HTML into structured comments. If `bodies` is a dict mapping
    legacy_fbid (numeric string) -> full body text, use it to override
    rendered bodies that are truncated by Facebook's 'See more'."""
    bodies = bodies or {}
    title_m = re.search(r"<title[^>]*>(.*?)</title>", html, re.DOTALL)
    title = title_m.group(1).strip() if title_m else "Facebook reel"

    # Owner / total count from embedded JSON
    owner_m = re.search(
        r'"owner":\{"__typename":"(?:User|Page)","__isActor"[^}]*?"id":"(\d+)"[^}]*?"name":"([^"]+)"',
        html,
    )
    owner_id = owner_m.group(1) if owner_m else None
    owner_name = (
        html_mod.unescape(owner_m.group(2)) if owner_m else None
    )

    total_m = re.search(r'"total_comment_count":(\d+)', html)
    total = int(total_m.group(1)) if total_m else None

    og_url_m = re.search(
        r'<meta property="og:url" content="([^"]+)"', html
    )
    og_url = og_url_m.group(1) if og_url_m else None

    # Locate every comment / reply article by its anchor aria-label.
    # The aria-label appears on the role="article" container, so the article
    # span is [match.start, next_match.start). We carve regions accordingly.
    anchors = []
    for m in COMMENT_LABEL_RE.finditer(html):
        anchors.append({
            "kind": m.group(1),
            "author": html_mod.unescape(m.group(2)).strip(),
            "in_reply_to": (
                html_mod.unescape(m.group(3)).strip() if m.group(3) else None
            ),
            "age": m.group(4).strip(),
            "start": m.start(),
        })

    items = []
    for i, a in enumerate(anchors):
        start = a["start"]
        end = anchors[i + 1]["start"] if i + 1 < len(anchors) else min(
            len(html), start + 30000
        )
        region = html[start:end]

        # Profile URL + comment_id from the header anchor
        profile_url = None
        comment_id = None
        href_m = PROFILE_HREF_RE.search(region[:6000])
        if href_m:
            profile_url = html_mod.unescape(href_m.group(1))
            comment_id = decode_comment_id(href_m.group(2))
            # Strip the comment_id and other tracking params so the URL is
            # just the profile.
            profile_url = re.sub(r"[?&]comment_id=[^&]+", "", profile_url)
            profile_url = re.sub(r"[?&]__cft__[^&]+", "", profile_url)
            profile_url = re.sub(r"[?&]__tn__=[^&]+", "", profile_url)
            profile_url = profile_url.replace("?&", "?").rstrip("?&")

        # Body: every <div dir="auto" style="text-align: start;">...</div>
        # block within the article. Multiple blocks happen when the comment
        # has line breaks or contains an embedded link.
        body_parts = []
        for bm in BODY_DIV_RE.finditer(region):
            piece = clean_text(bm.group(1))
            if piece:
                body_parts.append(piece)
        body = "\n".join(body_parts)

        # Backfill with canonical body from the GraphQL sidecar when we have
        # it. The DOM render truncates long comments with "… See more"; the
        # wire data has the full text. We index the sidecar by legacy_fbid
        # (the numeric suffix of comment_id).
        legacy_fbid = None
        if comment_id and "_" in comment_id:
            legacy_fbid = comment_id.rsplit("_", 1)[-1]
        full_text = bodies.get(legacy_fbid) if legacy_fbid else None
        if full_text:
            # Use the canonical text if the rendered body looks truncated, or
            # whenever the canonical is meaningfully longer. The DOM body may
            # have inserted username text the wire body lacks ("Bear Bear..."
            # tags); we keep the canonical text as the authoritative version.
            looks_truncated = body.endswith("See more") or "… See more" in body
            if looks_truncated or len(full_text) > len(body) + 8:
                body = full_text

        items.append({
            "kind": a["kind"],  # "Comment" or "Reply"
            "author": a["author"],
            "in_reply_to": a["in_reply_to"],
            "age": a["age"],
            "body": body,
            "profile_url": profile_url,
            "comment_id": comment_id,
        })

    return {
        "title": title,
        "owner_id": owner_id,
        "owner_name": owner_name,
        "total_comment_count": total,
        "og_url": og_url,
        "items": items,
    }


def to_markdown(data, source_url=None):
    """Emit raw comments — author, age, body. Replies indented under parent.
    Minimal preamble only when Facebook's header count exceeds the served
    count (so the file explains the gap inline)."""
    out = []
    rendered = len(data["items"])
    reported = data.get("total_comment_count")
    if reported and reported > rendered:
        url_part = f" ({source_url})" if source_url else ""
        out.append(
            f"[{rendered} of {reported} comments Facebook reports on this reel{url_part}. "
            f"Facebook's GraphQL endpoint only serves {rendered} to a logged-in viewer; "
            f"the larger header count is an aggregate that includes "
            f"spam-filtered, community-standards-removed, or cross-universe items "
            f"the API does not return.]"
        )
        out.append("")
    for item in data["items"]:
        if item["kind"] == "Comment":
            if out:
                out.append("")
            out.append(f"{item['author']} · {item['age']}")
            if item["body"]:
                for line in item["body"].splitlines():
                    out.append(line)
            else:
                out.append("(no text)")
        else:  # Reply
            out.append("")
            label = f"  ↳ {item['author']} · {item['age']}"
            if item["in_reply_to"]:
                label += f" (to {item['in_reply_to']})"
            out.append(label)
            if item["body"]:
                for line in item["body"].splitlines():
                    out.append(f"  {line}")
            else:
                out.append("  (no text)")
    out.append("")
    return "\n".join(out)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("html_file", help="HTML capture from reel-comments-cdp.py")
    p.add_argument("--md", help="Write Markdown to this file (default: stdout)")
    p.add_argument("--source-url", help="Original reel URL (added to header)")
    p.add_argument("--bodies-json",
                   help="Sidecar JSON of {legacy_fbid: full_text} from the "
                        "fetcher. Used to replace bodies truncated by 'See more'.")
    args = p.parse_args()

    with open(args.html_file, "r") as f:
        html = f.read()

    bodies = None
    if args.bodies_json:
        with open(args.bodies_json) as f:
            bodies = json.load(f)

    data = parse(html, bodies=bodies)
    md = to_markdown(data, source_url=args.source_url)

    if args.md:
        with open(args.md, "w") as f:
            f.write(md)
        comments = sum(1 for x in data["items"] if x["kind"] == "Comment")
        replies = sum(1 for x in data["items"] if x["kind"] == "Reply")
        print(
            f"Wrote {len(md):,} bytes to {args.md} "
            f"({comments} comments + {replies} replies)",
            file=sys.stderr,
        )
    else:
        sys.stdout.write(md)


if __name__ == "__main__":
    main()
