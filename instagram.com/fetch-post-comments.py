#!/usr/bin/env python3
"""
fetch-post-comments: read the comment list on an Instagram post.

Given a shortcode (e.g. DXsPrn5AvNH) or a full post_id from the feed
API (e.g. 3893054209352269936_1746949701), this script calls the
internal `/api/v1/media/<media_id>/comments/` endpoint via fetch()
from inside an authenticated CDP session and returns one row per
comment with the four free significance signals:

  - username, full_name, is_verified
  - has_default_avatar (true when profile_pic_url is the default ghost)
  - text, text_length_words
  - comment_like_count

These signals support cheap pre-filtering for comment-circle discovery
(see SKILL.md §8) before the expensive step (one profile fetch per
surviving handle through the standard sweep pipeline).

Shortcode-to-media-id conversion is local (base64 decoding of the
shortcode alphabet), so no extra fetch is needed to resolve.

Usage:
    python3 fetch-post-comments.py comments DXsPrn5AvNH
    python3 fetch-post-comments.py comments 3893054209352269936_1746949701 --limit 100
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


# ---------------------------------------------------------------------------
# Hand-rolled WebSocket over stdlib socket. CDP runs ws:// on localhost.
# Copied from the pattern established in otter.ai/otter-cdp.py.
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


def navigate_and_wait(ws, url, wait_seconds=3):
    send_cdp(ws, "Page.navigate", {"url": url})
    time.sleep(wait_seconds)


def check_logged_in(ws):
    title_result = eval_js(ws, "document.title")
    title = title_result.get("raw", "") if isinstance(title_result, dict) else str(title_result)
    if "Log in" in title or "Login" in title or "Sign in" in title:
        return False
    url_result = eval_js(ws, "window.location.href")
    url = url_result.get("raw", "") if isinstance(url_result, dict) else str(url_result)
    if "accounts/login" in url:
        return False
    return True


# ---------------------------------------------------------------------------
# Shortcode <-> media_id (Instagram's base64 encoding; pure local conversion).
# ---------------------------------------------------------------------------

_SHORTCODE_ALPHABET = (
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
)


def shortcode_to_media_id(shortcode):
    """Decode an Instagram shortcode into its numeric media_id."""
    result = 0
    for c in shortcode:
        idx = _SHORTCODE_ALPHABET.find(c)
        if idx < 0:
            raise ValueError(f"shortcode contains invalid char: {c!r}")
        result = result * 64 + idx
    return str(result)


def resolve_post_ref(post_ref):
    """Accept either a shortcode (DXsPrn5AvNH), a full post_id from the feed
    API (e.g. 3893054209352269936_1746949701), or a bare media_id.
    Return the bare media_id string."""
    if "_" in post_ref:
        head, _, _ = post_ref.partition("_")
        if head.isdigit():
            return head
        raise ValueError(f"post_ref looks like post_id but head is not numeric: {post_ref!r}")
    if post_ref.isdigit():
        return post_ref
    # Treat as shortcode.
    return shortcode_to_media_id(post_ref)


# ---------------------------------------------------------------------------
# Comment parsing.
# ---------------------------------------------------------------------------

_DEFAULT_AVATAR_HINTS = (
    "44884218_345707102882519_2446069589734326272_n",  # legacy ghost avatar
    "instagram_default_avatar",
    "anonymous_user",
)


def _has_default_avatar(profile_pic_url, has_anon_flag):
    if has_anon_flag:
        return True
    if not profile_pic_url:
        return True
    return any(h in profile_pic_url for h in _DEFAULT_AVATAR_HINTS)


def _word_count(text):
    if not text:
        return 0
    return len(re.findall(r"\w+", text))


def _parse_comments_response(data):
    """Convert the raw comments API response into structured comment rows."""
    comments = data.get("comments", []) or []
    rows = []
    for c in comments:
        user = c.get("user") or {}
        username = user.get("username", "") or ""
        full_name = user.get("full_name", "") or ""
        profile_pic = user.get("profile_pic_url", "") or ""
        has_anon = bool(user.get("has_anonymous_profile_picture", False))
        is_verified = bool(user.get("is_verified", False))
        text = c.get("text", "") or ""
        rows.append({
            "username": username,
            "full_name": full_name,
            "is_verified": is_verified,
            "has_default_avatar": _has_default_avatar(profile_pic, has_anon),
            "text": text,
            "text_length_words": _word_count(text),
            "comment_like_count": int(c.get("comment_like_count", 0) or 0),
            "created_at": c.get("created_at_utc") or c.get("created_at") or 0,
            "comment_id": str(c.get("pk") or c.get("id") or ""),
        })
    return rows


def cmd_comments(ws, post_ref, limit):
    """Fetch comments for a single post.

    First page only. Pagination via `min_id` cursor can be added later
    if comment-circle yield per first page proves insufficient; the
    first-page comments (most recent) are typically higher signal for
    creator-on-creator engagement than older ones anyway.
    """
    try:
        media_id = resolve_post_ref(post_ref)
    except ValueError as e:
        return {"error": str(e)}

    js = f"""
    (async () => {{
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const resp = await fetch('/api/v1/media/{media_id}/comments/?can_support_threading=true&permalink_enabled=false', {{
            credentials: 'include',
            headers: {{
                'X-IG-App-ID': '936619743392459',
                'X-CSRFToken': csrf,
                'X-Requested-With': 'XMLHttpRequest',
            }}
        }});
        if (!resp.ok) return JSON.stringify({{error: 'HTTP ' + resp.status, status: resp.status}});
        return JSON.stringify(await resp.json());
    }})()
    """
    result = eval_js(ws, js)
    if isinstance(result, dict) and result.get("error"):
        return result

    data = result if isinstance(result, dict) else {}
    comments = _parse_comments_response(data)
    return {
        "post_ref": post_ref,
        "media_id": media_id,
        "comment_count_total": int(data.get("comment_count", len(comments)) or len(comments)),
        "comment_count_returned": len(comments),
        "has_more": bool(data.get("has_more_comments", False)),
        "comments": comments[:limit],
    }


def main():
    parser = argparse.ArgumentParser(description="Instagram post comments reader (CDP)")
    sub = parser.add_subparsers(dest="command")

    p_comments = sub.add_parser("comments", help="Fetch first-page comments for a post")
    p_comments.add_argument("post_ref",
        help="Shortcode (e.g. DXsPrn5AvNH), full post_id (id_userid), or bare media_id")
    p_comments.add_argument("--limit", type=int, default=50,
        help="Cap on returned comments (default 50; the first API page is typically 20-50)")

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
        navigate_and_wait(ws, "https://www.instagram.com/", wait_seconds=3)

        if not check_logged_in(ws):
            print(json.dumps({
                "error": "Not logged in to Instagram. Log in via Chromium first."
            }))
            sys.exit(1)

        result = cmd_comments(ws, args.post_ref, args.limit)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        _ws_close(ws)
    finally:
        proc.terminate()
        proc.wait(timeout=5)


if __name__ == "__main__":
    main()
