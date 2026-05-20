#!/usr/bin/env python3
"""Parse a Facebook reel / page-post permalink HTML to extract caption, counts, and commenter samples.

Usage: python3 parse-reel.py <html-file>

The right URL to fetch is the page-post permalink form, not /reel/{id}:
    https://www.facebook.com/{PAGE_ID}/posts/{POST_ID}
The /reel/{id} URL returns an empty shell with no rendered content.
{POST_ID} for a recent reel can be read from the page's main profile dump
(see SKILL.md for the post_id-from-profile step).

Extracts:
  - Poster (page name)
  - Caption (from <title>)
  - reaction_count, total_comment_count, share_count (from embedded JSON)
  - creation_time (unix → ISO date)
  - Visible commenters and the body text closest to each name

Limits: Facebook lazy-loads the comment list; a headless single-render typically
yields the first ~5-10 comments out of the full thread. The total_comment_count
field tells you the true total. Do not invent comments beyond what is in the DOM.
"""

import json
import re
import sys
from datetime import datetime, timezone


def parse_reel(html_path):
    with open(html_path, "r") as f:
        html = f.read()

    title_match = re.findall(r"<title[^>]*>(.*?)</title>", html, re.DOTALL)
    title = title_match[0].strip() if title_match else ""
    if any(t in title.lower() for t in ["log in", "log into", "iniciar sesión"]):
        print("ERROR: Facebook session expired. Log in via a Chrome-compatible browser first.")
        sys.exit(1)

    if title in ("(16) Facebook", "Facebook") or title.endswith("Facebook") and " - " not in title and " | " not in title:
        # Bare shell page — wrong URL form was fetched
        print(f"WARNING: Title is '{title}'. This dump looks like an empty Facebook shell,")
        print("         not a rendered post. Did you fetch /reel/{id}? Use the")
        print("         /{page_id}/posts/{post_id} permalink URL instead — see SKILL.md.")
        print()

    # --- Caption (truncated, comes from the title) ---
    # Format: "(N) <CAPTION_START...> - <PAGE NAME> | Facebook"
    caption = title
    page_name = None
    caption = re.sub(r"^\(\d+\)\s*", "", caption)  # strip notif badge
    for sep in [" | Facebook", " - Facebook"]:
        if caption.endswith(sep):
            caption = caption[: -len(sep)].strip()
    if " - " in caption:
        left, right = caption.rsplit(" - ", 1)
        caption = left.strip()
        page_name = right.strip()
    caption = _decode_entities(caption)
    if page_name:
        page_name = _decode_entities(page_name)

    print(f"Page: {page_name or '(unknown)'}")
    print(f"Caption (truncated): {caption}")

    # --- Counts from embedded JSON ---
    counts = {}
    cm = re.search(r'"total_comment_count":(\d+)', html)
    if cm:
        counts["total_comment_count"] = int(cm.group(1))

    rm = re.search(r'"reaction_count":\{"count":(\d+)', html)
    if rm:
        counts["reaction_count"] = int(rm.group(1))

    sm = re.search(r'"share_count":\{"count":(\d+)', html)
    if sm:
        counts["share_count"] = int(sm.group(1))

    # creation_time near the first reaction_count is the post's own time
    if rm:
        window = html[max(0, rm.start() - 5000) : rm.start()]
        ct = re.findall(r'"creation_time":(\d{10})', window)
        if ct:
            counts["creation_time"] = int(ct[-1])

    print("\n--- Counts (from embedded JSON; authoritative totals) ---")
    for k, v in counts.items():
        if k == "creation_time":
            iso = datetime.fromtimestamp(v, tz=timezone.utc).isoformat()
            print(f"  {k}: {v}  ({iso})")
        else:
            print(f"  {k}: {v:,}")
    if not counts:
        print("  (none found — this dump probably has no embedded post JSON)")

    # --- Counts visible as rendered text (fallback / cross-check) ---
    # In the post region, the engagement bar renders 3 numeric spans in order:
    # reactions, comments, shares. These match what a logged-in viewer sees.
    rendered_counts = _extract_rendered_engagement(html)
    if rendered_counts:
        print("\n--- Counts (rendered visible text; from engagement bar) ---")
        labels = ["reactions", "comments", "shares"]
        for i, val in enumerate(rendered_counts[:3]):
            label = labels[i] if i < len(labels) else f"slot-{i}"
            print(f"  {label} (visible): {val}")

    # --- Commenter sample from rendered DOM ---
    # Strategy: dir="auto" spans hold visible text. The page's own name appears
    # several times (post header + page replies); commenter names are the
    # remaining short Person-Name-shaped spans. For each commenter span, the
    # closest comment body is the longest plain-text fragment within the next
    # ~3000 chars of HTML that isn't UI chrome.
    spans = list(re.finditer(r'<span[^>]*dir="auto"[^>]*>([^<]{1,500})</span>', html))
    span_text = [(m.start(), _decode_entities(m.group(1).strip())) for m in spans]

    # The page renders a chat sidebar with friend names BEFORE the post region.
    # The post region starts at the "<PageName>'s post" header. Anything before
    # is sidebar, not a commenter. Find that boundary.
    post_region_start = 0
    for pos, text in span_text:
        if text.endswith("'s post") or text.endswith("’s post"):
            post_region_start = pos
            break

    page_name_norm = (page_name or "").replace("&", "&amp;")
    commenter_names_seen = set()
    commenters = []
    for pos, text in span_text:
        if pos < post_region_start:
            continue  # chat sidebar, not commenters
        if not text or text == page_name or text == page_name_norm:
            continue
        # Page name variants with HTML-entity differences
        if page_name and text.replace(" ", "") == page_name.replace(" ", "").replace("&", ""):
            continue
        # Skip page UI navigation labels
        if text in {"More", "All", "About", "Reels", "Photos", "Followers",
                    "Contact info", "Featured", "Posts", "Create group chat",
                    "Videos", "Mentions", "Reviews", "Likes"}:
            continue
        # Skip pure numbers (engagement totals shown as text e.g. "1.1K", "629", "56")
        if re.fullmatch(r"[\d.,]+[KMB]?", text):
            continue
        # Skip Page post-header sentences ("Page's post" etc.)
        if "'s post" in text or text.endswith("'s post"):
            continue
        # Heuristic: commenter name looks like 2-4 capitalised words, no punctuation tail
        if not re.match(r"^[A-ZÀ-ſ][\w'\-À-ſ]*(?:\s+[A-ZÀ-ſ][\w'\-À-ſ]*){0,4}$", text):
            continue
        if text in commenter_names_seen:
            continue
        commenter_names_seen.add(text)

        # Find body: scan 3000 chars after name span for text fragments
        after = html[pos : pos + 3500]
        pieces = re.findall(r">([^<]{2,500})<", after)
        body_parts = []
        for p in pieces:
            p = p.strip()
            if not p or p == text:
                continue
            if _is_ui_noise(p):
                continue
            if p in commenter_names_seen:
                # We've hit the next commenter — stop collecting body
                break
            body_parts.append(_decode_entities(p))
            if len(" ".join(body_parts)) > 600:
                break
        commenters.append({
            "name": text,
            "body": " / ".join(body_parts[:3]) if body_parts else "(no body extracted)",
        })

    print(f"\n--- Visible commenters in DOM ({len(commenters)}; full total above) ---")
    for c in commenters:
        print(f"  {c['name']}:")
        print(f"    {c['body'][:400]}")

    print("\n--- End of reel parse ---")


def _extract_rendered_engagement(html):
    """Return the numeric spans in the engagement bar, in DOM order."""
    spans = list(re.finditer(r'<span[^>]*dir="auto"[^>]*>([^<]{1,30})</span>', html))
    # Find post region start
    post_start = 0
    for m in spans:
        if m.group(1).strip().endswith("'s post") or m.group(1).strip().endswith("’s post"):
            post_start = m.start()
            break
    rendered = []
    for m in spans:
        if m.start() < post_start:
            continue
        text = m.group(1).strip()
        if re.fullmatch(r"[\d.,]+[KMB]?", text):
            rendered.append(text)
        if len(rendered) >= 3:
            break
    return rendered


def _decode_entities(s):
    s = s.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
    s = s.replace("&#39;", "'").replace("&quot;", '"').replace("&#x2F;", "/")
    s = s.replace("&nbsp;", " ")
    return s


_UI_NOISE_SET = {
    "Reply", "Like", "Edited", "Most relevant", "All comments",
    "Write a comment", "View more comments", "View previous comments",
    "Send", "Comment", "Share", "Save",
}
_UI_NOISE_RE = re.compile(
    r"^\d+[dhmws]$"                          # timestamps: 5d, 2h
    r"|^x[0-9a-z]{7,}"                       # CSS class hashes
    r"|padding|margin|display:|font-|cursor:|overflow|color:"
    r"|webpack|require\(|exports\.|aria-|tabindex"
    r"|^Reply\s*\d+$"                        # reply counts
    r"|^\d+\s+(?:Repl(?:y|ies)|Like|Likes)$"
)


def _is_ui_noise(text):
    if text in _UI_NOISE_SET:
        return True
    if _UI_NOISE_RE.search(text):
        return True
    if text.startswith("{") or text.startswith("."):
        return True
    if len(text) < 2:
        return True
    return False


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <reel-permalink.html>")
        sys.exit(1)
    parse_reel(sys.argv[1])
