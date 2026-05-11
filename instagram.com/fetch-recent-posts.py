#!/usr/bin/env python3
"""
Instagram recent posts fetcher.

Given a public handle, returns the last N posts (default 12) with:
caption, like count, comment count, posted timestamp (ISO 8601), post type
(image/carousel/reel), is_paid_partnership flag, location tag, hashtags
extracted from caption, and mentioned handles.

Usage:
    python3 fetch-recent-posts.py posts <handle> [--limit N]
"""

import argparse
import base64
import json
import os
import re
import socket
import struct
import subprocess
import sys
import time
import urllib.request
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


UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36")

BROWSER_WRAPPER = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "bin", "not-google-chrome"
)


def launch_browser():
    """Launch headless browser for CDP using platform config from bin/not-google-chrome --print-args."""
    try:
        info = json.loads(subprocess.check_output([BROWSER_WRAPPER, "--print-args"], text=True))
    except Exception as e:
        sys.stderr.write(f"bin/not-google-chrome --print-args failed: {e}\n")
        return None, None
    binary = info["binary"]
    profile_args = info["profile_args"]
    proc = subprocess.Popen(
        [binary] + profile_args + [
            "--headless=new", "--disable-gpu",
            f"--user-agent={UA}",
            "--remote-debugging-port=0",
            "--remote-allow-origins=*",
            "--window-size=1920,1080",
            "--no-first-run", "--no-default-browser-check",
            "about:blank",
        ],
        stderr=subprocess.PIPE,
        stdout=subprocess.DEVNULL,
    )
    port = None
    deadline = time.time() + 15
    while time.time() < deadline:
        line = proc.stderr.readline().decode("utf-8", errors="replace")
        if "DevTools listening on" in line:
            port = line.strip().split(":")[-1].split("/")[0]
            break
    if not port:
        proc.kill()
        return None, None
    return proc, port


def connect_cdp(port):
    targets = json.loads(
        urllib.request.urlopen(f"http://127.0.0.1:{port}/json").read()
    )
    ws_url = targets[0]["webSocketDebuggerUrl"]
    return _ws_connect(ws_url, timeout=20)


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
            "caption": caption_text,
            "hashtags": _extract_hashtags(caption_text),
            "mentions": _extract_mentions(caption_text),
            "is_paid_partnership": bool(item.get("is_paid_partnership", False)),
            "location": location_name,
        })
    return posts


def cmd_posts(ws, handle, limit):
    """Fetch recent posts for a handle.

    Strategy:
    1. Navigate to the profile page.
    2. Enable Network domain before navigation so XHR responses are captured.
    3. After the page settles, drain CDP events to find the user feed XHR
       (typically /api/v1/feed/user/<user_id>/ or a GraphQL variant).
    4. If the feed XHR was captured, parse it directly.
    5. Fallback: call /api/v1/feed/user/<user_id>/ directly via fetch() using
       the user_id found in the hydrated page JSON.
    """
    send_cdp(ws, "Network.enable")

    profile_url = f"https://www.instagram.com/{handle}/"
    sys.stderr.write(f"Navigating to {profile_url}...\n")
    send_cdp(ws, "Page.navigate", {"url": profile_url})

    # Collect Network events for up to 8 seconds while the page hydrates.
    collected_events = []
    deadline = time.time() + 8
    sock_timeout = ws.gettimeout()
    ws.settimeout(0.5)
    try:
        while time.time() < deadline:
            try:
                msg = json.loads(_ws_recv(ws))
                collected_events.append(msg)
            except (OSError, socket.timeout):
                pass
    finally:
        ws.settimeout(sock_timeout)

    sys.stderr.write(f"Collected {len(collected_events)} CDP events during page load.\n")

    # Check for login redirect
    url_result = eval_js(ws, "window.location.href")
    current_url = url_result.get("raw", "") if isinstance(url_result, dict) else str(url_result)
    if "accounts/login" in current_url:
        return {"error": "Redirected to login. Session may be expired or rate-limited."}

    title_result = eval_js(ws, "document.title")
    title = title_result.get("raw", "") if isinstance(title_result, dict) else ""
    sys.stderr.write(f"Page title: {title}\n")

    # Try to find user_id from collected network responses or inline page JSON.
    user_id = None

    # Scan collected events for a network response that contains the user feed.
    feed_data = None
    for ev in collected_events:
        if ev.get("method") != "Network.responseReceived":
            continue
        resp_url = ev.get("params", {}).get("response", {}).get("url", "")
        if "/api/v1/feed/user/" in resp_url or "feed/user" in resp_url:
            request_id = ev.get("params", {}).get("requestId")
            if request_id:
                body_resp = send_cdp(ws, "Network.getResponseBody", {"requestId": request_id})
                if body_resp:
                    body = body_resp.get("result", {}).get("body", "")
                    try:
                        feed_data = json.loads(body)
                        sys.stderr.write(f"Captured feed XHR from: {resp_url}\n")
                        break
                    except json.JSONDecodeError:
                        pass

    if feed_data and feed_data.get("items"):
        posts = _parse_media_items(feed_data["items"][:limit])
        return {
            "handle": handle,
            "post_count": len(posts),
            "source": "network_intercept",
            "posts": posts,
        }

    # Fallback: extract user_id from the page's inline JSON and call the feed API directly.
    sys.stderr.write("No feed XHR captured; trying inline JSON extraction + direct fetch.\n")

    js_extract_id = """
    (async () => {
        // Instagram bakes user data into window.__additionalDataLoaded or inline script JSON.
        // Look for a JSON blob containing "user_id" near the profile owner's username.
        const scripts = Array.from(document.querySelectorAll('script:not([src])'));
        for (const s of scripts) {
            const t = s.textContent || '';
            const m = t.match(/"user_id"\s*:\s*"(\d+)"/);
            if (m) return JSON.stringify({user_id: m[1]});
            const m2 = t.match(/"id"\s*:\s*"(\d+)".*?"is_private"/s);
            if (m2) return JSON.stringify({user_id: m2[1]});
        }
        // Try window._sharedData path
        try {
            const sd = window._sharedData;
            if (sd) {
                const uid = sd?.entry_data?.ProfilePage?.[0]?.graphql?.user?.id;
                if (uid) return JSON.stringify({user_id: uid});
            }
        } catch(e) {}
        // Try querying the profile API endpoint directly for the user ID
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
    sys.stderr.write(f"user_id extraction: {id_result}\n")

    if isinstance(id_result, dict) and id_result.get("user_id"):
        user_id = id_result["user_id"]
    else:
        # Last resort: try the web_profile_info endpoint via Python fetch.
        return {"error": f"Could not determine user_id for @{handle}. The account may be private or the session rate-limited.", "detail": id_result}

    # Direct feed API call with the recovered user_id.
    js_feed = f"""
    (async () => {{
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const params = new URLSearchParams({{
            count: '{min(limit, 12)}',
        }});
        const resp = await fetch('/api/v1/feed/user/{user_id}/?' + params.toString(), {{
            credentials: 'include',
            headers: {{
                'X-IG-App-ID': '936619743392459',
                'X-CSRFToken': csrf,
                'X-Requested-With': 'XMLHttpRequest',
            }}
        }});
        const status = resp.status;
        if (!resp.ok) {{
            return JSON.stringify({{error: 'HTTP ' + status}});
        }}
        const data = await resp.json();
        return JSON.stringify({{status: status, data: data}});
    }})()
    """
    feed_result = eval_js(ws, js_feed)
    if isinstance(feed_result, dict) and feed_result.get("error"):
        return feed_result

    raw_data = feed_result.get("data", {})
    items = raw_data.get("items", [])
    if not items:
        return {
            "handle": handle,
            "user_id": user_id,
            "post_count": 0,
            "source": "direct_api",
            "note": "Feed returned no items. Account may be private.",
            "posts": [],
        }

    posts = _parse_media_items(items[:limit])
    return {
        "handle": handle,
        "user_id": user_id,
        "post_count": len(posts),
        "source": "direct_api",
        "posts": posts,
    }


def main():
    parser = argparse.ArgumentParser(description="Instagram recent posts fetcher")
    sub = parser.add_subparsers(dest="command")

    p_posts = sub.add_parser("posts", help="Fetch recent posts for a handle")
    p_posts.add_argument("handle")
    p_posts.add_argument("--limit", type=int, default=12)

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    proc, port = launch_browser()
    if not proc:
        print(json.dumps({"error": "Failed to launch headless browser"}))
        sys.exit(1)

    try:
        ws = connect_cdp(port)
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
            result = cmd_posts(ws, args.handle, args.limit)
        else:
            result = {"error": f"Unknown command: {args.command}"}

        print(json.dumps(result, indent=2, ensure_ascii=False))
        _ws_close(ws)
    finally:
        proc.terminate()
        proc.wait(timeout=5)


if __name__ == "__main__":
    main()
