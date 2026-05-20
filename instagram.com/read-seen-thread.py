#!/usr/bin/env python3
"""
read-seen-thread: fetch message history from an Instagram DM thread, but ONLY
when the thread is already marked SEEN by the operator. Refuses unread threads.

The hyphen-delimited word "seen" in the filename is load-bearing. This script
exists alongside `inbox-noninvasive.py` because reading a thread's message
content is fundamentally an invasive operation in the general case: if the
thread carries unread messages, the fetch will mark them seen and that change
is visible to the other party.

The seen-only guarantee is enforced by checking the thread's unread status
(via the same `/api/v1/direct_v2/inbox/` call inbox-noninvasive uses) BEFORE
issuing any thread-content fetch. If the thread is unread, the script returns
an error and exits without making the thread-content call. The defensive
Fetch.enable block list from inbox-noninvasive is also armed, so even an
unexpected seen-mutation request from elsewhere in the React bundle is
aborted before leaving the browser.

Use this script when P-phase profiling needs prior-correspondence content for
a contact and the operator has already read the conversation. For unread
threads, the appropriate downstream action is to flag the contact as
"warm: messages pending, not yet read" and either skip or surface to the
operator for human review before any further fetch.

Usage:
    python3 read-seen-thread.py thread <thread_id> [--limit N]
    python3 read-seen-thread.py by-handle <handle>  [--limit N]
    python3 read-seen-thread.py all-seen            [--limit N]
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
# Hand-rolled WebSocket over stdlib socket (CDP runs ws:// on localhost).
# Copied from otter.ai/otter-cdp.py per project CLAUDE.md convention.
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


# Patterns identifying potential seen-mutation requests. The script never
# navigates to a thread page, so the React bundle should never fire one of
# these in our context; the block list is defence-in-depth.
SEEN_BLOCK_PATTERNS = [
    "*/seen/*",
    "*/mark_seen*",
    "*item_seen*",
    "*/items/*/seen*",
]


def launch_browser():
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


def navigate_and_wait(ws, url, wait_seconds=3):
    send_cdp(ws, "Page.navigate", {"url": url})
    time.sleep(wait_seconds)


def enable_fetch_blocking(ws):
    """Arm CDP Fetch domain to block seen-mutation URL patterns."""
    patterns = [
        {"urlPattern": p, "requestStage": "Request"}
        for p in SEEN_BLOCK_PATTERNS
    ]
    send_cdp(ws, "Fetch.enable", {"patterns": patterns})


def drain_cdp_events(ws, timeout_seconds=0.5):
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
    events = drain_cdp_events(ws, timeout_seconds=1.0)
    for ev in events:
        if ev.get("method") == "Fetch.requestPaused":
            params = ev.get("params", {})
            url = params.get("request", {}).get("url", "")
            method = params.get("request", {}).get("method", "")
            request_id = params.get("requestId")
            sys.stderr.write(f"BLOCKED seen-mutation request: {method} {url}\n")
            if request_id:
                send_cdp(ws, "Fetch.failRequest", {
                    "requestId": request_id,
                    "errorReason": "BlockedByClient",
                })


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


def _micros_to_iso(ts_micros):
    try:
        ts = int(ts_micros) / 1_000_000
        return datetime.fromtimestamp(ts, tz=timezone.utc).isoformat()
    except Exception:
        return str(ts_micros)


# ---------------------------------------------------------------------------
# Inbox-state checking. Same call as inbox-noninvasive uses; the inbox-list
# endpoint is metadata-only and does not change read state.
# ---------------------------------------------------------------------------

def fetch_inbox(ws):
    js = """
    (async () => {
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const params = new URLSearchParams({
            visual_message_return_type: 'unseen',
            thread_message_limit: '1',
            persistentBadging: 'true',
            limit: '50',
        });
        const resp = await fetch('/api/v1/direct_v2/inbox/?' + params.toString(), {
            credentials: 'include',
            headers: {
                'X-IG-App-ID': '936619743392459',
                'X-CSRFToken': csrf,
                'X-Requested-With': 'XMLHttpRequest',
            }
        });
        if (!resp.ok) return JSON.stringify({error: 'HTTP ' + resp.status, status: resp.status});
        return JSON.stringify(await resp.json());
    })()
    """
    return eval_js(ws, js)


def is_thread_unseen(thread, viewer_id):
    """Same derivation as inbox-noninvasive: marked_as_unread OR
    (viewer's last_seen_at timestamp < last_activity_at)."""
    if thread.get("marked_as_unread"):
        return True
    last_seen_at = thread.get("last_seen_at") or {}
    if viewer_id and viewer_id in last_seen_at:
        try:
            seen_ts = int(last_seen_at[viewer_id].get("timestamp", "0") or "0")
            act_ts = int(thread.get("last_activity_at", 0) or 0)
            if act_ts > seen_ts:
                return True
        except (ValueError, TypeError):
            pass
    return False


def find_thread(inbox_data, thread_id=None, handle=None):
    """Locate the matching thread dict in the inbox response. Returns
    (thread_dict, viewer_id_str) or (None, viewer_id_str)."""
    viewer = inbox_data.get("viewer") or {}
    viewer_id = str(viewer.get("pk") or viewer.get("id") or "")
    inbox = inbox_data.get("inbox") or inbox_data
    threads = inbox.get("threads", []) or []
    if thread_id:
        for t in threads:
            if t.get("thread_id") == thread_id:
                return t, viewer_id
        return None, viewer_id
    if handle:
        h = handle.lower()
        for t in threads:
            users = t.get("users") or []
            for u in users:
                if (u.get("username") or "").lower() == h:
                    return t, viewer_id
        return None, viewer_id
    return None, viewer_id


# ---------------------------------------------------------------------------
# Thread message fetch (only invoked after the seen gate has passed).
# ---------------------------------------------------------------------------

def fetch_thread_messages(ws, thread_id, message_limit):
    """Call /api/v1/direct_v2/threads/<thread_id>/ for message content.

    Must only be called after is_thread_unseen() returned False for this
    thread on the same inbox snapshot.
    """
    js = f"""
    (async () => {{
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const params = new URLSearchParams({{
            visual_message_return_type: 'unseen',
            direction: 'older',
            limit: '{message_limit}',
        }});
        const resp = await fetch('/api/v1/direct_v2/threads/{thread_id}/?' + params.toString(), {{
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
    return eval_js(ws, js)


def _parse_thread_items(items, viewer_id):
    """Convert raw thread.items into structured message rows."""
    rows = []
    for it in items:
        user_id = str(it.get("user_id", "") or "")
        item_type = it.get("item_type", "")
        ts = it.get("timestamp", 0)

        text = ""
        if item_type == "text":
            text = it.get("text", "") or ""
        elif item_type == "like":
            text = "[like]"
        elif item_type == "media_share":
            ms = it.get("media_share") or {}
            cap = (ms.get("caption") or {})
            cap_text = (cap.get("text") if isinstance(cap, dict) else "") or ""
            text = f"[shared post] {cap_text[:120]}".strip()
        elif item_type == "reel_share":
            rs = it.get("reel_share") or {}
            text = f"[reel-share] {(rs.get('text') or '')[:200]}".strip()
        elif item_type == "raven_media":
            text = "[disappearing media]"
        elif item_type == "story_share":
            text = "[story-share]"
        elif item_type == "media":
            text = "[media]"
        elif item_type == "link":
            ln = it.get("link") or {}
            text = f"[link] {(ln.get('link_context') or {}).get('link_url', '')}".strip()
        elif item_type == "action_log":
            al = it.get("action_log") or {}
            text = f"[action] {al.get('description', '')[:120]}"
        else:
            text = f"[{item_type}]"

        rows.append({
            "is_from_viewer": (user_id == viewer_id) if viewer_id else None,
            "from_user_id": user_id,
            "item_type": item_type,
            "timestamp_iso": _micros_to_iso(ts),
            "text": text,
            "item_id": str(it.get("item_id") or ""),
        })
    return rows


def _build_thread_result(target, inbox_data, msg_data, viewer_id):
    """Combine inbox-side metadata and thread-side message list into one dict."""
    thread = (msg_data.get("thread") or {}) if isinstance(msg_data, dict) else {}
    items = thread.get("items", []) or []
    users = target.get("users") or []
    other_party = ""
    if users:
        other_party = users[0].get("username", "")
    return {
        "thread_id": target.get("thread_id"),
        "other_party": other_party,
        "is_group": bool(target.get("is_group")),
        "last_activity_iso": _micros_to_iso(target.get("last_activity_at", 0)),
        "viewer_id": viewer_id,
        "message_count_returned": len(items),
        "messages": _parse_thread_items(items, viewer_id),
    }


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def _seen_or_refuse(target, viewer_id):
    """If target is unseen, return a refusal dict; else return None."""
    if target is None:
        return {"error": "thread not found in current inbox snapshot"}
    if is_thread_unseen(target, viewer_id):
        last_seen = (target.get("last_seen_at") or {}).get(viewer_id, {}) or {}
        return {
            "error": "REFUSED: thread is unread; reading would mark messages as seen",
            "thread_id": target.get("thread_id"),
            "other_party": ((target.get("users") or [{}])[0].get("username", "")),
            "unread_state": {
                "marked_as_unread": bool(target.get("marked_as_unread")),
                "last_activity_iso": _micros_to_iso(target.get("last_activity_at", 0)),
                "last_seen_by_viewer_iso": _micros_to_iso(last_seen.get("timestamp", 0)) if last_seen else None,
            },
        }
    return None


def cmd_thread(ws, thread_id, message_limit):
    inbox_data = fetch_inbox(ws)
    handle_fetch_events(ws)
    if isinstance(inbox_data, dict) and inbox_data.get("error"):
        return inbox_data
    target, viewer_id = find_thread(inbox_data, thread_id=thread_id)
    refused = _seen_or_refuse(target, viewer_id)
    if refused:
        return refused
    time.sleep(2)
    msg_data = fetch_thread_messages(ws, thread_id, message_limit)
    handle_fetch_events(ws)
    if isinstance(msg_data, dict) and msg_data.get("error"):
        return msg_data
    return _build_thread_result(target, inbox_data, msg_data, viewer_id)


def cmd_by_handle(ws, handle, message_limit):
    inbox_data = fetch_inbox(ws)
    handle_fetch_events(ws)
    if isinstance(inbox_data, dict) and inbox_data.get("error"):
        return inbox_data
    target, viewer_id = find_thread(inbox_data, handle=handle)
    refused = _seen_or_refuse(target, viewer_id)
    if refused:
        return refused
    time.sleep(2)
    msg_data = fetch_thread_messages(ws, target.get("thread_id"), message_limit)
    handle_fetch_events(ws)
    if isinstance(msg_data, dict) and msg_data.get("error"):
        return msg_data
    return _build_thread_result(target, inbox_data, msg_data, viewer_id)


def cmd_all_seen(ws, message_limit):
    inbox_data = fetch_inbox(ws)
    handle_fetch_events(ws)
    if isinstance(inbox_data, dict) and inbox_data.get("error"):
        return inbox_data
    viewer = inbox_data.get("viewer") or {}
    viewer_id = str(viewer.get("pk") or viewer.get("id") or "")
    threads = (inbox_data.get("inbox") or inbox_data).get("threads", []) or []

    results = {"viewer_id": viewer_id, "threads": [], "refused": []}
    for t in threads:
        users = t.get("users") or []
        username = users[0].get("username", "") if users else ""
        tid = t.get("thread_id")
        if is_thread_unseen(t, viewer_id):
            results["refused"].append({
                "thread_id": tid,
                "other_party": username,
                "reason": "unread",
                "marked_as_unread": bool(t.get("marked_as_unread")),
            })
            continue
        time.sleep(2)
        msg_data = fetch_thread_messages(ws, tid, message_limit)
        handle_fetch_events(ws)
        if isinstance(msg_data, dict) and msg_data.get("error"):
            results["threads"].append({
                "thread_id": tid,
                "other_party": username,
                "error": msg_data.get("error"),
            })
            continue
        results["threads"].append(_build_thread_result(t, inbox_data, msg_data, viewer_id))
    return results


def main():
    parser = argparse.ArgumentParser(description="Instagram seen-only DM thread reader (CDP)")
    sub = parser.add_subparsers(dest="command")

    p_thread = sub.add_parser("thread", help="Read a thread by thread_id (refuses if unread)")
    p_thread.add_argument("thread_id")
    p_thread.add_argument("--limit", type=int, default=50,
        help="Max messages to return per thread")

    p_handle = sub.add_parser("by-handle", help="Read the thread for a handle (refuses if unread)")
    p_handle.add_argument("handle")
    p_handle.add_argument("--limit", type=int, default=50)

    p_all = sub.add_parser("all-seen", help="Read every SEEN thread; refuses each unread one separately")
    p_all.add_argument("--limit", type=int, default=50)

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

        # Arm defensive Fetch interception BEFORE the first navigation.
        enable_fetch_blocking(ws)

        navigate_and_wait(ws, "https://www.instagram.com/", wait_seconds=4)
        handle_fetch_events(ws)

        if not check_logged_in(ws):
            print(json.dumps({"error": "Not logged in to Instagram. Log in via Chromium first."}))
            sys.exit(1)

        if args.command == "thread":
            result = cmd_thread(ws, args.thread_id, args.limit)
        elif args.command == "by-handle":
            result = cmd_by_handle(ws, args.handle, args.limit)
        elif args.command == "all-seen":
            result = cmd_all_seen(ws, args.limit)
        else:
            result = {"error": f"Unknown command: {args.command}"}

        print(json.dumps(result, indent=2, ensure_ascii=False))
        _ws_close(ws)
    finally:
        proc.terminate()
        proc.wait(timeout=5)


if __name__ == "__main__":
    main()
