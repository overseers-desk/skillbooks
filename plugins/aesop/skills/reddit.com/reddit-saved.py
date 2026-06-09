#!/usr/bin/env python3
"""Return a Reddit account's saved items (posts and comments), newest first,
fetched in a single browser session over CDP.

The saved listing is private: it resolves only for the logged-in account that
owns it, so this reads it through the authenticated old.reddit.com origin (the
user's Chromium cookies, carried by the --cdp wrapper). It follows Reddit's
`after` cursor across pages internally and returns up to --limit items, so the
caller asks for a count and never handles a cursor. A saved list interleaves
posts (kind t3) and comments (kind t1); both are printed, labelled.

Usage (driven by the headless-browser wrapper's CDP mode):
    not-google-chrome --cdp -- python3 reddit-saved.py --user NAME [--limit 25]
"""
import argparse
import base64
import json
import os
import socket
import struct
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from reddit import print_saved  # noqa: E402  shared printer


# --- Hand-rolled WebSocket over stdlib socket (CDP is ws:// on localhost). ---
# Same pattern the other CDP skills use; kept self-contained per skill.
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--user", required=True, help="account whose saved list to read (must be the logged-in account)")
    ap.add_argument("--limit", type=int, default=25, help="saved items to return")
    a = ap.parse_args()

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

        collected, after = [], None
        while len(collected) < a.limit:
            url = f"https://old.reddit.com/user/{a.user}/saved.json?limit=100&raw_json=1"
            if after:
                url += f"&after={after}&count={len(collected)}"
            page = fetch_json(ws, url)
            if "error" in page:
                print("saved fetch failed: " + page["error"], file=sys.stderr)
                sys.exit(1)
            data = page.get("data")
            if not isinstance(data, dict):
                # Reddit returns {"message":"Not Found","error":404} for a saved
                # list it will not show: not logged in, wrong account, or the
                # session is not this user's.
                print(f"no saved listing for u/{a.user} "
                      f"(login as that account, browser closed; Reddit said: "
                      f"{page.get('message', page)})", file=sys.stderr)
                sys.exit(1)
            children = data.get("children", [])
            if not children:
                break
            collected.extend(children)
            after = data.get("after")
            if not after:
                break  # last page
            time.sleep(1)  # pace requests

        collected = collected[:a.limit]
        if not collected:
            print(f"u/{a.user} has no saved items.")
            return
        print(f"# {len(collected)} saved item(s) for u/{a.user} (newest first)\n")
        print_saved(collected, a.limit)
    finally:
        try:
            ws.sendall(bytes([0x88, 0x80]) + os.urandom(4))
        except Exception:
            pass
        ws.close()


if __name__ == "__main__":
    main()
