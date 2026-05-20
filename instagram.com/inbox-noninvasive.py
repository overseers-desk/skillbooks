#!/usr/bin/env python3
"""
Instagram DM inbox metadata reader — NONINVASIVE.

This script reads inbox thread metadata only: who sent the last message,
when, a short snippet, and whether the thread is marked unread. It MUST NOT
mark any thread as read. It MUST NOT open individual threads or fetch message
content.

If you need message content from a specific thread, that is a separate,
invasive operation — write a different script with a different name.

Any future code change that adds thread-opening, message fetching,
or any is_seen=true/seen-mutation call must be a separate script,
not an addition here. The "noninvasive" word in this filename is load-bearing.

Usage:
    python3 inbox-noninvasive.py list
    python3 inbox-noninvasive.py verify-noninvasive
"""

import argparse
import base64
import json
import os
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
    os.path.dirname(os.path.abspath(__file__)), "..", "headless-browser", "not-google-chrome"
)

# Patterns that identify seen-mutation requests.  These must NEVER leave the browser.
SEEN_BLOCK_PATTERNS = [
    "*/seen/*",
    "*/mark_seen*",
    "*item_seen*",
    "*direct_thread*",
]


def launch_browser():
    """Launch headless browser for CDP using platform config from headless-browser/not-google-chrome --print-args."""
    try:
        info = json.loads(subprocess.check_output([BROWSER_WRAPPER, "--print-args"], text=True))
    except Exception as e:
        sys.stderr.write(f"headless-browser/not-google-chrome --print-args failed: {e}\n")
        return None, None
    binary = info["binary"]
    user_data_dir_args = info["user_data_dir_args"]
    proc = subprocess.Popen(
        [binary] + user_data_dir_args + [
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


def enable_fetch_blocking(ws):
    """Enable Fetch domain with URL patterns that block seen-mutation requests.

    Intercepted requests matching seen-mutation patterns are failed (aborted)
    before they leave the browser. Any interception is logged to stderr.
    This is a defensive layer: even if Instagram's web client fires a
    seen-mutation as a side effect of our reads, it is blocked here.
    """
    patterns = [
        {"urlPattern": p, "requestStage": "Request"}
        for p in SEEN_BLOCK_PATTERNS
    ]
    send_cdp(ws, "Fetch.enable", {"patterns": patterns})


def drain_cdp_events(ws, timeout_seconds=0.5):
    """Drain pending CDP events without blocking for long."""
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


def handle_fetch_events(ws):
    """Check for any pending Fetch.requestPaused events and abort them.

    Call after any operation that might have triggered network activity.
    """
    events = drain_cdp_events(ws, timeout_seconds=1.0)
    for ev in events:
        if ev.get("method") == "Fetch.requestPaused":
            params = ev.get("params", {})
            url = params.get("request", {}).get("url", "")
            method = params.get("request", {}).get("method", "")
            request_id = params.get("requestId")
            sys.stderr.write(
                f"BLOCKED seen-mutation request: {method} {url}\n"
            )
            if request_id:
                send_cdp(ws, "Fetch.failRequest", {
                    "requestId": request_id,
                    "errorReason": "BlockedByClient",
                })


def check_logged_in(ws):
    result = eval_js(ws, "document.title")
    title = result.get("raw", "") if isinstance(result, dict) else str(result)
    if "Log in" in title or "Login" in title or "Sign in" in title:
        return False
    # Also check URL for login redirect
    url_result = eval_js(ws, "window.location.href")
    url = url_result.get("raw", "") if isinstance(url_result, dict) else str(url_result)
    if "accounts/login" in url:
        return False
    return True


def _microseconds_to_iso(ts_micros):
    """Convert Instagram's microsecond timestamp to ISO 8601 string."""
    try:
        ts = int(ts_micros) / 1_000_000
        return datetime.fromtimestamp(ts, tz=timezone.utc).isoformat()
    except Exception:
        return str(ts_micros)


def _parse_inbox_response(data):
    """Parse the direct_v2/inbox API response into a list of thread summaries.

    Read-state derivation: a thread is considered unseen if EITHER
    (a) `marked_as_unread` is true (operator explicitly flagged the thread for
        follow-up via "Mark as unread" in the UI — Lia's primary signal for
        threads needing a response), OR
    (b) the viewer's `last_seen_at[viewer_id].timestamp` is earlier than
        `last_activity_at` (the latest message hasn't been viewed yet).
    Both timestamps are microseconds since epoch.

    The top-level response carries `viewer.pk` (not `viewer_id`); per-thread
    `read_state` is an integer enum, not a dict, so do not index into it.
    """
    inbox = data.get("inbox", data)
    threads = inbox.get("threads", [])
    viewer = data.get("viewer") or {}
    viewer_id = str(viewer.get("pk") or viewer.get("id") or "")
    results = []
    for t in threads:
        users = t.get("users", [])
        if users:
            username = users[0].get("username", "")
            full_name = users[0].get("full_name", "")
        else:
            username = t.get("thread_title", "")
            full_name = ""

        last_activity_ts = t.get("last_activity_at", 0)
        last_activity_iso = _microseconds_to_iso(last_activity_ts)

        # Last snippet: try last_permanent_item first
        snippet = ""
        lpi = t.get("last_permanent_item") or {}
        if lpi:
            item_type = lpi.get("item_type", "")
            if item_type == "text":
                snippet = (lpi.get("text", "") or "")[:120]
            elif item_type == "like":
                snippet = "[like]"
            elif item_type == "media_share":
                snippet = "[shared post]"
            elif item_type == "reel_share":
                rs = lpi.get("reel_share", {}) or {}
                snippet = ("[reel: " + (rs.get("text") or "")[:80] + "]")
            elif item_type:
                snippet = f"[{item_type}]"

        marked = bool(t.get("marked_as_unread", False))
        unseen_by_timestamp = False
        last_seen_at = t.get("last_seen_at") or {}
        if viewer_id and viewer_id in last_seen_at:
            seen_ts_str = last_seen_at[viewer_id].get("timestamp", "0")
            try:
                unseen_by_timestamp = int(last_activity_ts) > int(seen_ts_str)
            except (ValueError, TypeError):
                pass
        unseen = marked or unseen_by_timestamp

        results.append({
            "username": username,
            "full_name": full_name,
            "thread_id": t.get("thread_id", ""),
            "last_activity_iso": last_activity_iso,
            "last_snippet": snippet,
            "unseen": unseen,
            "is_group": t.get("is_group", False),
        })
    return results


def cmd_list(ws):
    """Fetch the DM inbox thread list without navigating to /direct/inbox/."""
    # Get CSRF token and App-ID from the home page session context.
    js = """
    (async () => {
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const appId = '936619743392459';
        const params = new URLSearchParams({
            visual_message_return_type: 'unseen',
            thread_message_limit: '1',
            persistentBadging: 'true',
            limit: '20',
        });
        const resp = await fetch('/api/v1/direct_v2/inbox/?' + params.toString(), {
            credentials: 'include',
            headers: {
                'X-IG-App-ID': appId,
                'X-CSRFToken': csrf,
                'X-Requested-With': 'XMLHttpRequest',
            }
        });
        const status = resp.status;
        if (!resp.ok) {
            return JSON.stringify({error: 'HTTP ' + status, status: status});
        }
        const data = await resp.json();
        return JSON.stringify({status: status, data: data});
    })()
    """
    result = eval_js(ws, js)
    handle_fetch_events(ws)

    if isinstance(result, dict) and result.get("error"):
        return result

    status = result.get("status")
    data = result.get("data", {})

    if status == 401 or status == 403:
        return {"error": f"Instagram returned HTTP {status}. Session may be expired or rate-limited."}

    threads = _parse_inbox_response(data)
    return {"threads": threads, "thread_count": len(threads)}


def cmd_verify_noninvasive(ws):
    """Run list twice with a 45-second sleep; check that no unseen thread flipped to seen."""
    sys.stderr.write("verify-noninvasive: first fetch...\n")
    first = cmd_list(ws)
    if "error" in first:
        return first

    sys.stderr.write("verify-noninvasive: sleeping 45 seconds...\n")
    time.sleep(45)

    sys.stderr.write("verify-noninvasive: second fetch...\n")
    second = cmd_list(ws)
    if "error" in second:
        return second

    first_map = {t["thread_id"]: t for t in first.get("threads", [])}
    second_map = {t["thread_id"]: t for t in second.get("threads", [])}

    flipped = []
    for tid, t1 in first_map.items():
        t2 = second_map.get(tid)
        if t2 and t1["unseen"] and not t2["unseen"]:
            flipped.append({
                "thread_id": tid,
                "username": t1["username"],
                "was_unseen": True,
                "now_unseen": False,
            })

    if flipped:
        return {
            "result": "FAIL",
            "message": "At least one thread changed from unseen to seen between runs.",
            "flipped_threads": flipped,
        }
    return {
        "result": "PASS",
        "message": "No unseen threads changed state between the two reads.",
        "threads_checked": len(first_map),
    }


def cmd_raw(ws):
    """Return the raw inbox API response (for diagnosing parser issues).

    Same fetch as cmd_list, but emits the unparsed JSON. Use this when the
    parsed `unseen` flag or other derived field looks wrong, to inspect
    Instagram's actual field shape.
    """
    js = """
    (async () => {
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const params = new URLSearchParams({
            visual_message_return_type: 'unseen',
            thread_message_limit: '1',
            persistentBadging: 'true',
            limit: '20',
        });
        const resp = await fetch('/api/v1/direct_v2/inbox/?' + params.toString(), {
            credentials: 'include',
            headers: {
                'X-IG-App-ID': '936619743392459',
                'X-CSRFToken': csrf,
                'X-Requested-With': 'XMLHttpRequest',
            }
        });
        return JSON.stringify({status: resp.status, data: resp.ok ? await resp.json() : null});
    })()
    """
    result = eval_js(ws, js)
    handle_fetch_events(ws)
    return result


def main():
    parser = argparse.ArgumentParser(description="Instagram inbox metadata reader (noninvasive)")
    sub = parser.add_subparsers(dest="command")
    sub.add_parser("list", help="Emit inbox thread list as JSON")
    sub.add_parser("verify-noninvasive", help="Run list twice, verify no read-state mutation")
    sub.add_parser("raw", help="Dump raw inbox API response for parser diagnosis")
    args = parser.parse_args()
    if not args.command:
        args.command = "list"

    proc, port = launch_browser()
    if not proc:
        print(json.dumps({"error": "Failed to launch headless browser"}))
        sys.exit(1)

    try:
        ws = connect_cdp(port)
        send_cdp(ws, "Page.enable")

        # Enable Fetch blocking BEFORE any navigation so mutations are caught
        # even if they fire during page load.
        enable_fetch_blocking(ws)

        # Navigate to the Instagram home page (not /direct/inbox/) to establish
        # session context without triggering a "user is viewing inbox" beacon.
        navigate_and_wait(ws, "https://www.instagram.com/", wait_seconds=5)
        handle_fetch_events(ws)

        if not check_logged_in(ws):
            print(json.dumps({
                "error": "Not logged in to Instagram. Log in via a Chrome-compatible browser first."
            }))
            sys.exit(1)

        if args.command == "list":
            result = cmd_list(ws)
        elif args.command == "verify-noninvasive":
            result = cmd_verify_noninvasive(ws)
        elif args.command == "raw":
            result = cmd_raw(ws)
        else:
            result = {"error": f"Unknown command: {args.command}"}

        print(json.dumps(result, indent=2, ensure_ascii=False))
        _ws_close(ws)
    finally:
        proc.terminate()
        proc.wait(timeout=5)


if __name__ == "__main__":
    main()
