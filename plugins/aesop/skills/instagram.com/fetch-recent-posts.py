#!/usr/bin/env python3
"""
Instagram recent posts fetcher.

Given a public handle, returns the last N posts (default 12) with:
caption, like count, comment count, posted timestamp (ISO 8601), post type
(image/carousel/reel), is_paid_partnership flag, location tag, hashtags
extracted from caption, and mentioned handles.

Usage:
    not-google-chrome --cdp -- python3 fetch-recent-posts.py posts <handle> [--limit N]
"""

import argparse
import base64
import json
import os
import re
import socket
import struct
import sys
import time
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Hand-rolled WebSocket over stdlib socket.
# CDP runs ws:// on localhost — no TLS, no extensions, no permessage-deflate.
# These helpers are copied from the CDP pattern established in otter.ai/otter-cdp.py.
# ---------------------------------------------------------------------------

def _ws_connect(url, timeout=20):
    url = url[len("ws://"):]
    host_port, path = (url.split("/", 1) + [""])[:2]
    host, port = host_port.rsplit(":", 1)
    sock = socket.create_connection((host, int(port)), timeout=timeout)
    key = base64.b64encode(os.urandom(16)).decode()
    sock.sendall((
        f"GET /{path} HTTP/1.1\r\nHost: {host}\r\n"
        "Upgrade: websocket\r\nConnection: Upgrade\r\n"
        f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n"
    ).encode())
    resp = b""
    while b"\r\n\r\n" not in resp:
        resp += sock.recv(4096)
    if b"101" not in resp:
        raise OSError(f"WebSocket handshake failed: {resp[:120]}")
    return sock


def _ws_send(sock, data):
    if isinstance(data, str):
        data = data.encode()
    n, mask = len(data), os.urandom(4)
    hdr = bytes([0x81])
    if n <= 125:      hdr += bytes([0x80 | n])
    elif n <= 0xFFFF: hdr += bytes([0xFE]) + struct.pack(">H", n)
    else:             hdr += bytes([0xFF]) + struct.pack(">Q", n)
    sock.sendall(hdr + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))


def _ws_recvn(sock, n):
    buf = b""
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise OSError("WebSocket connection lost")
        buf += chunk
    return bytes(buf)


def _ws_recv(sock):
    b0, b1 = _ws_recvn(sock, 2)
    n = b1 & 0x7F
    if n == 126: n = struct.unpack(">H", _ws_recvn(sock, 2))[0]
    elif n == 127: n = struct.unpack(">Q", _ws_recvn(sock, 8))[0]
    mask = _ws_recvn(sock, 4) if b1 & 0x80 else None
    payload = _ws_recvn(sock, n)
    if mask:
        payload = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
    if b0 & 0x0F == 0x8:
        raise OSError("WebSocket closed by server")
    return payload.decode()


def _ws_close(sock):
    try:
        sock.sendall(bytes([0x88, 0x80]) + os.urandom(4))
    except Exception:
        pass
    sock.close()


def send_cdp(ws, method, params=None, counter=[0]):
    counter[0] += 1
    mid = counter[0]
    msg = {"id": mid, "method": method}
    if params:
        msg["params"] = params
    _ws_send(ws, json.dumps(msg))
    deadline = time.time() + 30
    while time.time() < deadline:
        resp = json.loads(_ws_recv(ws))
        if resp.get("id") == mid:
            return resp
    return None


def eval_js(ws, expression):
    result = send_cdp(ws, "Runtime.evaluate", {
        "expression": expression,
        "awaitPromise": True,
        "returnByValue": True,
    })
    val = result.get("result", {}).get("result", {}).get("value")
    exc = result.get("result", {}).get("exceptionDetails")
    if exc:
        return {"error": exc.get("text", "JS exception")}
    if val is None:
        return {"error": "No value returned from JS"}
    try:
        return json.loads(val)
    except json.JSONDecodeError:
        return {"raw": val}


def navigate_and_wait(ws, url, wait_seconds=5):
    send_cdp(ws, "Page.navigate", {"url": url})
    time.sleep(wait_seconds)


def check_logged_in(ws):
    result = eval_js(ws, "document.title")
    title = result.get("raw", "") if isinstance(result, dict) else str(result)
    if "Log in" in title or "Login" in title or "Sign in" in title:
        return False
    url_result = eval_js(ws, "window.location.href")
    url = url_result.get("raw", "") if isinstance(url_result, dict) else str(url_result)
    if "accounts/login" in url:
        return False
    return True


def enable_network_intercept(ws):
    """Enable Network domain so we can capture XHR responses fired during profile hydration."""
    send_cdp(ws, "Network.enable")


def drain_cdp_events(ws, timeout_seconds=3.0):
    """Drain pending CDP events, collecting Network.responseReceived entries."""
    sock_timeout = ws.gettimeout()
    ws.settimeout(timeout_seconds)
    events = []
    try:
        while True:
            msg = json.loads(_ws_recv(ws))
            events.append(msg)
    except (OSError, socket.timeout):
        pass
    finally:
        ws.settimeout(sock_timeout)
    return events


def _seconds_to_iso(ts):
    """Convert a Unix second timestamp to ISO 8601 string."""
    try:
        return datetime.fromtimestamp(int(ts), tz=timezone.utc).isoformat()
    except Exception:
        return str(ts)


def _extract_hashtags(caption):
    if not caption:
        return []
    return list(dict.fromkeys(re.findall(r"#(\w+)", caption)))


def _extract_mentions(caption):
    if not caption:
        return []
    return list(dict.fromkeys(re.findall(r"@(\w+)", caption)))


def _post_type(item):
    """Determine post type from a media item dict."""
    media_type = item.get("media_type", 0)
    product_type = item.get("product_type", "")
    if media_type == 1:
        return "image"
    if media_type == 2:
        if product_type in ("clips", "reels"):
            return "reel"
        return "video"
    if media_type == 8:
        return "carousel"
    return "unknown"


def _extract_usertags(item):
    """Pull tagged usernames from the "tag people" feature on a post.

    Single-image posts carry usertags directly. Carousel posts carry per-slide
    usertags inside carousel_media[]; aggregate across slides and dedupe.
    """
    handles = []
    seen = set()

    def _pull(node):
        ut = (node.get("usertags") or {}).get("in") or []
        for entry in ut:
            if not isinstance(entry, dict):
                continue
            u = (entry.get("user") or {}).get("username") or ""
            if u and u not in seen:
                seen.add(u)
                handles.append(u)

    _pull(item)
    for slide in item.get("carousel_media") or []:
        if isinstance(slide, dict):
            _pull(slide)
    return handles


def _extract_coauthors(item):
    """Pull coauthor usernames from Instagram's collab-post feature."""
    handles = []
    for c in item.get("coauthor_producers") or []:
        if isinstance(c, dict):
            u = c.get("username") or ""
            if u:
                handles.append(u)
    return handles


def _extract_sponsors(item):
    """Pull sponsor usernames from branded-content sponsor tags."""
    handles = []
    for s in item.get("sponsor_tags") or []:
        if isinstance(s, dict):
            sponsor = s.get("sponsor") or {}
            u = sponsor.get("username") or ""
            if u:
                handles.append(u)
    return handles


def _parse_media_items(items):
    """Convert raw media items into structured post dicts."""
    posts = []
    for item in items:
        caption_obj = item.get("caption") or {}
        caption_text = caption_obj.get("text", "") if isinstance(caption_obj, dict) else ""

        location = item.get("location") or {}
        location_name = location.get("name", "") if isinstance(location, dict) else ""

        like_count = item.get("like_count", 0)
        comment_count = item.get("comment_count", 0)
        taken_at = item.get("taken_at", 0)

        posts.append({
            "post_id": item.get("id", ""),
            "shortcode": item.get("code", ""),
            "url": f"https://www.instagram.com/p/{item.get('code', '')}/",
            "post_type": _post_type(item),
            "taken_at_iso": _seconds_to_iso(taken_at),
            "like_count": like_count,
            "comment_count": comment_count,
            # video/reel play, view and reshare counts (None on stills), the
            # Facebook-crosspost counterparts (None unless shared to FB), the
            # video length, and whether the creator hid metrics: engagement and
            # format signal beyond likes/comments.
            "play_count": item.get("play_count"),
            "ig_play_count": item.get("ig_play_count"),
            "fb_play_count": item.get("fb_play_count"),
            "view_count": item.get("view_count"),
            "media_repost_count": item.get("media_repost_count"),
            "fb_like_count": item.get("fb_like_count"),
            "fb_comment_count": item.get("fb_comment_count"),
            "video_duration": item.get("video_duration"),
            "like_and_view_counts_disabled": bool(item.get("like_and_view_counts_disabled")),
            "caption": caption_text,
            "hashtags": _extract_hashtags(caption_text),
            "mentions": _extract_mentions(caption_text),
            "tagged_users": _extract_usertags(item),
            "coauthors": _extract_coauthors(item),
            "sponsors": _extract_sponsors(item),
            "is_paid_partnership": bool(item.get("is_paid_partnership", False)),
            "location": location_name,
        })
    return posts


def resolve_user_id(ws, handle):
    """Navigate to a profile page and resolve the handle to its numeric user_id.

    Returns the user_id string on success. Returns a dict with `error` on
    login redirect, private account, or rate-limit. Reusable across both
    fetch-recent-posts and collab-expand.
    """
    profile_url = f"https://www.instagram.com/{handle}/"
    sys.stderr.write(f"Navigating to {profile_url}...\n")
    send_cdp(ws, "Page.navigate", {"url": profile_url})
    time.sleep(4)

    url_result = eval_js(ws, "window.location.href")
    current_url = url_result.get("raw", "") if isinstance(url_result, dict) else str(url_result)
    if "accounts/login" in current_url:
        return {"error": "Redirected to login. Session may be expired or rate-limited."}

    js_extract_id = """
    (async () => {
        const scripts = Array.from(document.querySelectorAll('script:not([src])'));
        for (const s of scripts) {
            const t = s.textContent || '';
            const m = t.match(/"user_id"\\s*:\\s*"(\\d+)"/);
            if (m) return JSON.stringify({user_id: m[1]});
            const m2 = t.match(/"id"\\s*:\\s*"(\\d+)".*?"is_private"/s);
            if (m2) return JSON.stringify({user_id: m2[1]});
        }
        try {
            const sd = window._sharedData;
            if (sd) {
                const uid = sd?.entry_data?.ProfilePage?.[0]?.graphql?.user?.id;
                if (uid) return JSON.stringify({user_id: uid});
            }
        } catch(e) {}
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const infoResp = await fetch('/api/v1/users/web_profile_info/?username=' + encodeURIComponent(location.pathname.replace(/\\//g, '')), {
            credentials: 'include',
            headers: {
                'X-IG-App-ID': '936619743392459',
                'X-CSRFToken': csrf,
                'X-Requested-With': 'XMLHttpRequest',
            }
        });
        if (infoResp.ok) {
            const info = await infoResp.json();
            const uid = info?.data?.user?.id;
            if (uid) return JSON.stringify({user_id: uid, source: 'web_profile_info'});
        }
        return JSON.stringify({error: 'user_id not found'});
    })()
    """
    id_result = eval_js(ws, js_extract_id)
    if isinstance(id_result, dict) and id_result.get("user_id"):
        return id_result["user_id"]
    return {"error": f"Could not determine user_id for @{handle}", "detail": id_result}


def fetch_user_feed_page(ws, user_id, max_id=None, count=12):
    """Fetch one page of /api/v1/feed/user/<user_id>/.

    Returns the raw JSON dict (with `items`, `more_available`, `next_max_id`)
    or a dict with `error` on HTTP failure.
    """
    params_parts = [f"count={count}"]
    if max_id:
        params_parts.append(f"max_id={max_id}")
    params_str = "&".join(params_parts)
    js = f"""
    (async () => {{
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const resp = await fetch('/api/v1/feed/user/{user_id}/?{params_str}', {{
            credentials: 'include',
            headers: {{
                'X-IG-App-ID': '936619743392459',
                'X-CSRFToken': csrf,
                'X-Requested-With': 'XMLHttpRequest',
            }}
        }});
        if (!resp.ok) return JSON.stringify({{error: 'HTTP ' + resp.status}});
        return JSON.stringify(await resp.json());
    }})()
    """
    result = eval_js(ws, js)
    return result


def fetch_user_feed_paginated(ws, user_id, limit, pause_between=2):
    """Paginate /api/v1/feed/user/<user_id>/ until `limit` items collected
    or the feed reports more_available=false.

    Returns a list of raw media items (up to `limit`).
    """
    items = []
    max_id = None
    page_num = 0
    while len(items) < limit:
        page_num += 1
        page = fetch_user_feed_page(ws, user_id, max_id=max_id, count=12)
        if isinstance(page, dict) and page.get("error"):
            sys.stderr.write(f"Page {page_num} fetch error: {page['error']}\n")
            break
        page_items = page.get("items", []) if isinstance(page, dict) else []
        if not page_items:
            sys.stderr.write(f"Page {page_num} returned no items; stopping.\n")
            break
        items.extend(page_items)
        sys.stderr.write(f"Page {page_num}: {len(page_items)} items (cumulative {len(items)})\n")
        if not page.get("more_available"):
            break
        max_id = page.get("next_max_id")
        if not max_id:
            break
        if len(items) >= limit:
            break
        time.sleep(pause_between)
    return items[:limit]


def cmd_posts(ws, handle, limit, raw_out=None):
    """Fetch recent posts for a handle. Paginates if limit > 12.

    Strategy: resolve user_id by navigating to the profile page, then
    fetch the user feed API directly. The XHR-intercept optimization was
    removed since it only saves the first page and complicates pagination.

    raw_out: optional path. When set, the unparsed raw feed-API items are
    written there as JSON before parsing, so a caller can keep the full
    response and re-derive any field later without re-fetching. Off by default.
    """
    user_id_or_err = resolve_user_id(ws, handle)
    if isinstance(user_id_or_err, dict) and user_id_or_err.get("error"):
        return user_id_or_err
    user_id = user_id_or_err

    time.sleep(2)
    items = fetch_user_feed_paginated(ws, user_id, limit)
    if raw_out:
        try:
            with open(raw_out, "w") as f:
                json.dump({"handle": handle, "user_id": user_id, "items": items},
                          f, ensure_ascii=False)
            sys.stderr.write(f"Raw feed items written to {raw_out}\n")
        except OSError as e:
            sys.stderr.write(f"Failed to write --raw-out {raw_out}: {e}\n")
    if not items:
        return {
            "handle": handle,
            "user_id": user_id,
            "post_count": 0,
            "note": "Feed returned no items. Account may be private or feed empty.",
            "posts": [],
        }

    posts = _parse_media_items(items)
    return {
        "handle": handle,
        "user_id": user_id,
        "post_count": len(posts),
        "posts": posts,
    }


def main():
    parser = argparse.ArgumentParser(description="Instagram recent posts fetcher")
    sub = parser.add_subparsers(dest="command")

    p_posts = sub.add_parser("posts", help="Fetch recent posts for a handle")
    p_posts.add_argument("handle")
    p_posts.add_argument("--limit", type=int, default=12)
    p_posts.add_argument("--raw-out", default=None,
                         help="also write the unparsed raw feed-API items to this path (off by default)")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    ws_url = os.environ.get("CDP_WS_URL")
    if not ws_url:
        sys.stderr.write("ERROR: CDP_WS_URL not set; run via: "
                         "not-google-chrome --cdp -- python3 fetch-recent-posts.py ...\n")
        sys.exit(1)

    ws = _ws_connect(ws_url, timeout=20)
    send_cdp(ws, "Page.enable")

    # Navigate to instagram.com first to establish session context (3-second pace).
    navigate_and_wait(ws, "https://www.instagram.com/", wait_seconds=3)

    if not check_logged_in(ws):
        print(json.dumps({
            "error": "Not logged in to Instagram. Log in via a Chrome-compatible browser first."
        }))
        sys.exit(1)

    # Pace: 3 seconds between navigations.
    time.sleep(3)

    if args.command == "posts":
        result = cmd_posts(ws, args.handle, args.limit, raw_out=args.raw_out)
    else:
        result = {"error": f"Unknown command: {args.command}"}

    print(json.dumps(result, indent=2, ensure_ascii=False))
    _ws_close(ws)


if __name__ == "__main__":
    main()
