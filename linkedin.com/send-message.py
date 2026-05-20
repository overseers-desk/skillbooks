#!/usr/bin/env python3
"""Send a LinkedIn direct message to a connection via CDP.

Usage:
    python3 send-message.py VANITY_NAME "Message text"
    python3 send-message.py VANITY_NAME "Message text" --dry-run   # stop before clicking Send
"""

import argparse
import base64
import configparser
import json
import os
import socket
import struct
import subprocess
import sys
import time
import urllib.request


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


USER_DATA_DIR = os.path.join(os.path.expanduser("~"), "snap/chromium/common/chromium")
CONFIG_PATH = os.path.join(os.path.expanduser("~"), ".claude/skills/config.ini")
CDP_PORT = 9223


def _load_browser_config():
    """Read user_agent and accept_lang from [browser] in config.ini. Exit if absent."""
    if not os.path.exists(CONFIG_PATH):
        sys.exit(f"ERROR: {CONFIG_PATH} not found. Copy config.ini.example to config.ini "
                 "and fill the [browser] section.")
    cp = configparser.ConfigParser()
    cp.read(CONFIG_PATH)
    if "browser" not in cp:
        sys.exit(f"ERROR: {CONFIG_PATH} missing [browser] section. See config.ini.example.")
    ua = cp["browser"].get("user_agent", "").strip()
    lang = cp["browser"].get("accept_lang", "").strip()
    if not ua or not lang:
        sys.exit(f"ERROR: [browser] section in {CONFIG_PATH} needs both "
                 "user_agent and accept_lang.")
    if "HeadlessChrome" in ua:
        sys.exit(f"ERROR: user_agent in {CONFIG_PATH} contains 'HeadlessChrome' — "
                 "that string defeats the override. Capture the UA from a real browser session.")
    return ua, lang


def _snap_chromium_running():
    r = subprocess.run(["pgrep", "-f", "snap/chromium/common/chromium"],
                       capture_output=True, text=True)
    return r.stdout.strip()


def _wait_for_cdp(retries=30):
    for _ in range(retries):
        time.sleep(0.5)
        try:
            with urllib.request.urlopen(
                    f"http://localhost:{CDP_PORT}/json/list", timeout=2) as r:
                tabs = json.loads(r.read())
                if tabs:
                    return tabs[0]["webSocketDebuggerUrl"]
        except Exception:
            pass
    sys.exit("ERROR: CDP endpoint not ready - chromium failed to start")


def send_message(vanity_name: str, text: str, dry_run: bool = False):
    url = f"https://www.linkedin.com/in/{vanity_name}/"

    ua, lang = _load_browser_config()

    pids = _snap_chromium_running()
    if pids:
        print(f"WARNING: snap Chromium running (PIDs: {pids}). User-data-dir may be locked.",
              file=sys.stderr)

    proc = subprocess.Popen(
        [
            "flock", "/tmp/chromium.lock",
            "chromium", "--headless=new",
            f"--remote-debugging-port={CDP_PORT}",
            f"--user-data-dir={USER_DATA_DIR}",
            f"--user-agent={ua}",
            f"--accept-lang={lang}",
            "--window-size=1920,1080",
            "--no-first-run", "--no-default-browser-check",
        ],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )

    try:
        ws_url = _wait_for_cdp()
        return _run_flow(ws_url, url, text, dry_run)
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()


def _run_flow(ws_url: str, page_url: str, text: str, dry_run: bool) -> dict:
    sock = _ws_connect(ws_url, timeout=20)
    sock.settimeout(None)  # profile pages emit a burst of CDP events; blocking reads are fine on localhost
    try:
        net_events: list = []
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
                if msg.get("method") == "Network.responseReceived":
                    net_events.append(msg["params"])

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

        cmd("Network.enable")
        cmd("Page.enable")

        print(f"Navigating to: {page_url}")
        cmd("Page.navigate", {"url": page_url})
        time.sleep(4)

        title = js("document.title") or ""
        print(f"Page title: {title}")
        if any(x in title.lower() for x in ["sign in", "log in", "iniciar"]):
            sys.exit("ERROR: got sign-in page - session is not active")

        # LinkedIn sometimes shows a language-selection interstitial on first CDP load.
        # Click "English" to set the locale cookie and let LinkedIn redirect to the profile.
        body_check = js("document.body.innerText") or ""
        if "選擇語言" in body_check or "Choose language" in body_check:
            print("Language interstitial detected. Clicking English...")
            clicked = js('''(function() {
                var all = Array.from(document.querySelectorAll("a, button"));
                var en = all.find(function(el) {
                    var t = el.textContent.trim();
                    return t === "English (English)" || t === "English";
                });
                if (en) { en.click(); return true; }
                return false;
            })()''')
            if not clicked:
                sys.exit("ERROR: language interstitial appeared but English option not found")
            print("Clicked English. Waiting for profile to load...")
            time.sleep(6)
            title = js("document.title") or ""
            print(f"Page title after language selection: {title}")
            if any(x in title.lower() for x in ["sign in", "log in", "iniciar"]):
                sys.exit("ERROR: redirected to sign-in after language selection")

        # Find and click the Message button on the profile page
        msg_found = wait_for('[aria-label*="Message"], [aria-label*="Mensaje"]', 15)
        if not msg_found:
            body = js("document.body.innerText") or ""
            sys.exit(f"ERROR: Message button not found. Not connected? Body: {body[:300]}")

        print("Message button found. Clicking...")
        js('''(function() {
            var sel = '[aria-label*="Message"], [aria-label*="Mensaje"]';
            var btn = document.querySelector(sel);
            if (btn) btn.click();
        })()''')
        time.sleep(2)

        # Wait for the compose area — LinkedIn messaging uses a contenteditable div
        compose_selectors = [
            'div[role="textbox"][contenteditable="true"]',
            '[contenteditable="true"][data-placeholder]',
            '[contenteditable="true"]',
        ]
        compose_sel = None
        for sel in compose_selectors:
            if wait_for(sel, 8):
                compose_sel = sel
                break

        if not compose_sel:
            body = js("document.body.innerText") or ""
            sys.exit(f"ERROR: compose area did not appear after clicking Message. Body: {body[:300]}")

        print(f"Compose area found ({compose_sel}). Focusing...")
        js(f"document.querySelector({json.dumps(compose_sel)}).focus()")
        time.sleep(0.3)

        print(f"Typing message ({len(text)} chars)...")
        cmd("Input.insertText", {"text": text})
        time.sleep(0.5)

        typed = js(f"document.querySelector({json.dumps(compose_sel)}).textContent") or ""
        print(f"Verified in compose area ({len(typed)} chars): '{typed[:60]}{'...' if len(typed) > 60 else ''}'")

        if dry_run:
            print("DRY RUN: stopping before send.")
            return {"status": "dry_run", "typed": typed}

        # Find the Send button in the messaging compose panel
        send_label = js('''(function() {
            var btns = Array.from(document.querySelectorAll("button"));
            var b = btns.find(function(b) {
                var label = (b.getAttribute("aria-label") || b.textContent || "").toLowerCase().trim();
                return label === "send" || label === "enviar";
            });
            return b ? (b.getAttribute("aria-label") || b.textContent.trim()) : null;
        })()''')

        if not send_label:
            all_btns = js(
                'Array.from(document.querySelectorAll("button"))'
                '.map(function(b){return (b.getAttribute("aria-label")||"")+'
                '"|"+b.textContent.trim()}).join("; ")'
            )
            sys.exit(f"ERROR: Send button not found. Buttons present: {all_btns}")

        print(f"Clicking send button: '{send_label}'")
        js('''(function() {
            var btns = Array.from(document.querySelectorAll("button"));
            var b = btns.find(function(b) {
                var label = (b.getAttribute("aria-label") || b.textContent || "").toLowerCase().trim();
                return label === "send" || label === "enviar";
            });
            if (b) b.click();
        })()''')

        print("Waiting for server response...")
        time.sleep(4)

        toast = js(
            'document.querySelector(".artdeco-toast-item__message, '
            '[data-test-artdeco-toast-item]")?.textContent?.trim() || null'
        )

        # Check compose area is cleared (message was sent)
        compose_cleared = not (js(
            f"document.querySelector({json.dumps(compose_sel)})?.textContent?.trim()"
        ) or "").strip()

        msg_events = [
            e for e in net_events
            if "messaging" in e["response"]["url"]
            and not e["response"]["url"].startswith("chrome://")
            and not e["response"]["url"].startswith("extension://")
        ]

        print("\n=== Server Confirmation ===")
        if toast:
            print(f"Toast notification: {toast}")
        print(f"Compose area cleared after send: {compose_cleared}")
        for e in msg_events:
            print(f"API response: HTTP {e['response']['status']} <- {e['response']['url']}")

        api_ok = any(e["response"]["status"] in (200, 201, 204) for e in msg_events)
        api_failed = bool(msg_events) and not api_ok

        if api_failed and not toast:
            statuses = [e["response"]["status"] for e in msg_events]
            print(f"ERROR: messaging API returned errors: {statuses}", file=sys.stderr)

        success = bool(
            api_ok
            or (compose_cleared and not api_failed)
            or (toast and not api_failed)
        )

        result = {
            "status": "sent" if success else "uncertain",
            "toast": toast,
            "compose_cleared": compose_cleared,
            "api_responses": [
                {"url": e["response"]["url"], "status": e["response"]["status"]}
                for e in msg_events
            ],
        }
        return result

    finally:
        _ws_close(sock)


def main():
    p = argparse.ArgumentParser(
        description="Send a LinkedIn direct message to a connection")
    p.add_argument("vanity_name",
                   help="LinkedIn vanity slug, e.g. john-smith-123")
    p.add_argument("text", help="Message text")
    p.add_argument("--dry-run", action="store_true",
                   help="Type message but do not click Send")
    args = p.parse_args()

    result = send_message(args.vanity_name, args.text, args.dry_run)

    print("\n=== RESULT ===")
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if result["status"] == "sent":
        print("\nSUCCESS: message sent.")
    elif result["status"] == "dry_run":
        print("\nDRY RUN complete - no message sent.")
    else:
        print("\nUNCERTAIN - could not confirm delivery. Check LinkedIn manually.",
              file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
