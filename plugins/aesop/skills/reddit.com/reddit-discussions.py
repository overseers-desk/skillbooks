#!/usr/bin/env python3
"""Return full Reddit discussions (post body + comment tree) for a search or a
subreddit listing, fetched in a single browser session over CDP.

A Reddit search hit is always a post (submission); its `comments/<id>.json`
endpoint returns the post and its comment tree together, so one fetch per hit
yields the whole discussion. This script searches (or lists a subreddit), then
fetches each result's discussion via in-page fetch() inside the authenticated
old.reddit.com origin, so cookies and the configured locale apply.

Usage (driven by the headless-browser wrapper's CDP mode):
    not-google-chrome --cdp -- python3 reddit-discussions.py \
        --query "SEARCH TERMS" [--subreddit SUB] \
        [--sort relevance|new|top|comments] [--time all|year|month|week|day] \
        [--limit 5] [--comments 15]
    not-google-chrome --cdp -- python3 reddit-discussions.py \
        --subreddit SUB [--sort hot|new|top] [--limit 5] [--comments 15]
"""
import argparse
import base64
import json
import os
import socket
import struct
import sys
import time
from urllib.parse import quote_plus

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from reddit import clean, cmd_thread  # noqa: E402  shared parser/printer


# --- Hand-rolled WebSocket over stdlib socket (CDP is ws:// on localhost). ---
# Same pattern the instagram/otter CDP skills use.
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
    if n <= 125:
        hdr += bytes([0x80 | n])
    elif n <= 0xFFFF:
        hdr += bytes([0xFE]) + struct.pack(">H", n)
    else:
        hdr += bytes([0xFF]) + struct.pack(">Q", n)
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
    if n == 126:
        n = struct.unpack(">H", _ws_recvn(sock, 2))[0]
    elif n == 127:
        n = struct.unpack(">Q", _ws_recvn(sock, 8))[0]
    mask = _ws_recvn(sock, 4) if b1 & 0x80 else None
    payload = _ws_recvn(sock, n)
    if mask:
        payload = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
    if b0 & 0x0F == 0x8:
        raise OSError("WebSocket closed by server")
    return payload.decode()


def send_cdp(ws, method, params=None, _counter=[0]):
    _counter[0] += 1
    mid = _counter[0]
    msg = {"id": mid, "method": method}
    if params:
        msg["params"] = params
    _ws_send(ws, json.dumps(msg))
    deadline = time.time() + 40
    while time.time() < deadline:
        resp = json.loads(_ws_recv(ws))
        if resp.get("id") == mid:
            return resp
    return None


def fetch_json(ws, url):
    """Run fetch() inside the page and return the parsed JSON (or {'error':...})."""
    expr = (
        "fetch(%s, {credentials: 'include', headers: {'Accept': 'application/json'}})"
        ".then(r => r.text()).catch(e => 'FETCHERR:' + e)" % json.dumps(url)
    )
    result = send_cdp(ws, "Runtime.evaluate", {
        "expression": expr, "awaitPromise": True, "returnByValue": True,
    })
    if not result:
        return {"error": "no CDP response"}
    exc = result.get("result", {}).get("exceptionDetails")
    if exc:
        return {"error": exc.get("text", "JS exception")}
    val = result.get("result", {}).get("result", {}).get("value")
    if not isinstance(val, str):
        return {"error": "no value"}
    if val.startswith("FETCHERR:"):
        loc_resp = send_cdp(ws, "Runtime.evaluate", {
            "expression": "document.location.href", "returnByValue": True,
        })
        loc = (loc_resp or {}).get("result", {}).get("result", {}).get("value") or ""
        if (not loc) or loc.startswith("about:") or loc.startswith("chrome-error://"):
            return {"error": "in-page fetch before origin established "
                             "(browser-side, not a Reddit response; location=%s): %s"
                             % (loc or "<unknown>", val)}
        return {"error": "%s (page location=%s)" % (val, loc)}
    try:
        return json.loads(val)
    except json.JSONDecodeError:
        return {"error": "non-JSON response (blocked or login wall): " + val[:120]}


def build_listing_url(a):
    if a.query:
        q = quote_plus(a.query)
        if a.subreddit:
            return (f"https://old.reddit.com/r/{a.subreddit}/search.json"
                    f"?q={q}&restrict_sr=on&sort={a.sort}&t={a.time}&limit={a.limit}")
        return (f"https://old.reddit.com/search.json"
                f"?q={q}&sort={a.sort}&t={a.time}&limit={a.limit}")
    # No query: subreddit listing.
    sort = a.sort if a.sort in ("hot", "new", "top", "rising") else "hot"
    return f"https://old.reddit.com/r/{a.subreddit}/{sort}.json?limit={a.limit}&t={a.time}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--query")
    ap.add_argument("--subreddit")
    ap.add_argument("--sort", default="relevance")
    ap.add_argument("--time", default="all")
    ap.add_argument("--limit", type=int, default=5, help="discussions to return")
    ap.add_argument("--comments", type=int, default=15, help="comments per discussion")
    a = ap.parse_args()
    if not a.query and not a.subreddit:
        ap.error("give --query and/or --subreddit")

    ws_url = os.environ.get("CDP_WS_URL")
    if not ws_url:
        print("CDP_WS_URL not set (run via: not-google-chrome --cdp -- python3 ...)", file=sys.stderr)
        sys.exit(78)

    ws = _ws_connect(ws_url)
    try:
        send_cdp(ws, "Page.enable")
        send_cdp(ws, "Page.navigate", {"url": "https://old.reddit.com/"})
        time.sleep(3)  # settle on origin so fetch() carries cookies and locale
        settle = send_cdp(ws, "Runtime.evaluate", {
            "expression": "document.location.href + ' | ' + document.title",
            "returnByValue": True,
        })
        print("settle: " + str((settle or {}).get("result", {}).get("result", {}).get("value", "<no result>")),
              file=sys.stderr)

        listing = fetch_json(ws, build_listing_url(a))
        if "error" in listing:
            print("listing fetch failed: " + listing["error"], file=sys.stderr)
            sys.exit(1)
        children = listing.get("data", {}).get("children", [])
        posts = [c["data"] for c in children if c.get("kind") == "t3"][:a.limit]
        if not posts:
            print("No posts matched.")
            return

        print(f"# {len(posts)} discussion(s) for "
              f"{'q=' + repr(a.query) if a.query else ''}"
              f"{' in r/' + a.subreddit if a.subreddit else ''}\n")
        for i, p in enumerate(posts, 1):
            url = f"https://old.reddit.com{p['permalink']}.json?limit={a.comments}&sort=top"
            data = fetch_json(ws, url)
            print(f"\n===== DISCUSSION {i}/{len(posts)} =====")
            if "error" in data:
                print(f"(comments fetch failed for {p.get('permalink','')}: {data['error']})")
                print(f"# {clean(p.get('title',''))}")
                continue
            cmd_thread(data, a.comments)
            time.sleep(1)  # pace requests
    finally:
        try:
            ws.sendall(bytes([0x88, 0x80]) + os.urandom(4))
        except Exception:
            pass
        ws.close()


if __name__ == "__main__":
    main()
