#!/usr/bin/env python3
"""Establish a LinkedIn session via the fastrack (remember-me) flow using CDP.

LinkedIn periodically expires the active session but keeps a remember-me cookie
that allows re-login without a password. This script clicks the "Continue as
<name>" button to mint a fresh session, which persists to the user-data-dir
on disk for subsequent skill runs (send-invite.py, send-message.py).

The wrapper (not-google-chrome --cdp) owns the browser lifecycle and exports
CDP_WS_URL; this script is a pure CDP client and exits if run without it.

Usage:
    not-google-chrome --cdp -- python3 login.py            # report state; if logged out, attempt fastrack login
    not-google-chrome --cdp -- python3 login.py --check    # report current login state only, never click
"""

import argparse
import base64
import json
import os
import socket
import struct
import sys
import time


# Hand-rolled WebSocket over stdlib socket. CDP runs ws:// on localhost,
# so no TLS, no extensions, no permessage-deflate.

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


def login(check_only: bool = False):
    ws_url = os.environ.get("CDP_WS_URL")
    if not ws_url:
        sys.exit("ERROR: CDP_WS_URL not set; run via: "
                 "not-google-chrome --cdp -- python3 login.py [--check]")
    return _run_flow(ws_url, check_only)


# Markers that distinguish logged-in from logged-out on the LinkedIn homepage.
def _login_state(js):
    has_nav = js('!!document.querySelector("[class*=\\"global-nav__me\\"], '
                 'a[href*=\\"/in/\\"][class*=\\"global-nav\\"]")')
    has_feed = js('!!document.querySelector("main [class*=\\"feed\\"], '
                  'div[class*=\\"feed-shared\\"]")')
    has_fastrack = js('!!document.querySelector(".fastrack-sign-in-cta")')
    has_login_form = js('!!document.querySelector("form[action*=\\"login\\"], '
                        'form[action*=\\"authenticate\\"]")')
    if has_nav or has_feed:
        return "logged_in"
    if has_fastrack:
        return "logged_out_remember_me"
    if has_login_form:
        return "logged_out"
    return "unknown"


def _run_flow(ws_url: str, check_only: bool) -> dict:
    sock = _ws_connect(ws_url, timeout=20)
    sock.settimeout(None)  # LinkedIn pages emit a burst of CDP events; blocking reads are fine on localhost
    try:
        _id = 0

        def cmd(method, params=None):
            nonlocal _id
            _id += 1
            cid = _id
            _ws_send(sock, json.dumps({"id": cid, "method": method,
                                       "params": params or {}}))
            while True:
                msg = json.loads(_ws_recv(sock))
                if "id" in msg:
                    if msg["id"] != cid:
                        continue
                    if "error" in msg:
                        raise RuntimeError(f"{method}: {msg['error']}")
                    return msg.get("result", {})

        def js(expr):
            r = cmd("Runtime.evaluate", {
                "expression": expr,
                "awaitPromise": False,
                "returnByValue": True,
            })
            if "exceptionDetails" in r:
                raise RuntimeError(r["exceptionDetails"].get("text", "JS error"))
            return r.get("result", {}).get("value")

        def wait_for(selector, timeout=10):
            t0 = time.time()
            while time.time() - t0 < timeout:
                if js(f"!!document.querySelector({json.dumps(selector)})"):
                    return True
                time.sleep(0.5)
            return False

        cmd("Page.enable")

        print("Navigating to homepage...")
        cmd("Page.navigate", {"url": "https://www.linkedin.com/"})
        time.sleep(4)
        state = _login_state(js)
        print(f"Initial state: {state}  (title: {js('document.title')!r})")

        if state == "logged_in":
            return {"status": "already_logged_in"}

        if check_only:
            return {"status": state}

        if state not in ("logged_out_remember_me",):
            return {"status": state,
                    "note": "no remember-me fastrack available; a password login is required"}

        # Click the fastrack CTA on the homepage -> navigates to the JS-rendered
        # continue page.
        print("Clicking fastrack CTA...")
        js('document.querySelector(".fastrack-sign-in-cta")?.click()')
        time.sleep(5)

        # The continue page is JS-rendered. Wait for a clickable continue control.
        # Match by text rather than CSS class (classes are randomised).
        def find_continue():
            return js('''(function() {
                var els = Array.from(document.querySelectorAll(
                    "button, a, [role=button]"));
                var m = els.find(function(el) {
                    var t = (el.getAttribute("aria-label") || el.textContent || "")
                        .trim().toLowerCase();
                    return t === "continuar" || t === "continue"
                        || t.indexOf("iniciar sesión") === 0
                        || t.indexOf("sign in as") === 0;
                });
                return m ? (m.getAttribute("aria-label") || m.textContent.trim()) : null;
            })()''')

        label = None
        t0 = time.time()
        while time.time() - t0 < 12:
            label = find_continue()
            if label:
                break
            time.sleep(0.5)

        if not label:
            clickables = js(
                'Array.from(document.querySelectorAll("button, a, [role=button]"))'
                '.map(function(el){return (el.getAttribute("aria-label")||"")+'
                '"|"+(el.textContent||"").trim().slice(0,40)})'
                '.filter(function(s){return s.length>1}).slice(0,40).join("; ")'
            )
            return {"status": "continue_button_not_found",
                    "url": js("document.location.href"),
                    "clickables": clickables}

        print(f"Clicking continue control: '{label[:60]}'")
        js('''(function() {
            var els = Array.from(document.querySelectorAll("button, a, [role=button]"));
            var m = els.find(function(el) {
                var t = (el.getAttribute("aria-label") || el.textContent || "")
                    .trim().toLowerCase();
                return t === "continuar" || t === "continue"
                    || t.indexOf("iniciar sesión") === 0
                    || t.indexOf("sign in as") === 0;
            });
            if (m) m.click();
        })()''')

        print("Waiting for login to complete...")
        time.sleep(6)

        # Re-check on the homepage to confirm a session was minted.
        cmd("Page.navigate", {"url": "https://www.linkedin.com/"})
        time.sleep(4)
        final = _login_state(js)
        print(f"Final state: {final}  (title: {js('document.title')!r})")

        return {"status": "logged_in" if final == "logged_in" else "login_failed",
                "final_state": final}

    finally:
        _ws_close(sock)


def main():
    p = argparse.ArgumentParser(
        description="Establish a LinkedIn session via fastrack (remember-me) login")
    p.add_argument("--check", action="store_true",
                   help="Report current login state only; never click")
    args = p.parse_args()

    result = login(check_only=args.check)

    print("\n=== RESULT ===")
    print(json.dumps(result, indent=2, ensure_ascii=False))

    status = result["status"]
    if status in ("already_logged_in", "logged_in"):
        print("\nSUCCESS: session active.")
    elif status == "logged_in" and args.check:
        print("\nLogged in.")
    elif args.check:
        print(f"\nState: {status} (no action taken; --check).")
        sys.exit(1)
    else:
        print(f"\nFAILED: {status}. No active session.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
