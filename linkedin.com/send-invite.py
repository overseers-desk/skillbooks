#!/usr/bin/env python3
"""Send a LinkedIn connection invite with a personalised note via CDP.

Usage:
    python3 send-invite.py VANITY_NAME "Note text (<=300 chars)"
    python3 send-invite.py VANITY_NAME "Note text" --dry-run   # stop before clicking Send
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


PROFILE = os.path.join(os.path.expanduser("~"), "snap/chromium/common/chromium")
CDP_PORT = 9223
MAX_NOTE_CHARS = 300


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


def send_connection_invite(vanity_name: str, note: str, dry_run: bool = False):
    if len(note) > MAX_NOTE_CHARS:
        sys.exit(f"ERROR: note is {len(note)} chars; LinkedIn limit is {MAX_NOTE_CHARS}")

    url = f"https://www.linkedin.com/preload/custom-invite/?vanityName={vanity_name}"

    pids = _snap_chromium_running()
    if pids:
        print(f"WARNING: snap Chromium running (PIDs: {pids}). Profile may be locked.",
              file=sys.stderr)

    proc = subprocess.Popen(
        [
            "chromium", "--headless=new",
            f"--remote-debugging-port={CDP_PORT}",
            f"--user-data-dir={PROFILE}",
            "--user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
            "(KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36",
            "--window-size=1920,1080",
            "--no-first-run", "--no-default-browser-check",
        ],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )

    try:
        ws_url = _wait_for_cdp()
        return _run_flow(ws_url, url, note, dry_run)
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()


def _run_flow(ws_url: str, page_url: str, note: str, dry_run: bool) -> dict:
    sock = _ws_connect(ws_url, timeout=20)
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
                        continue  # response to a different command (shouldn't happen sequentially)
                    if "error" in msg:
                        raise RuntimeError(f"{method}: {msg['error']}")
                    return msg.get("result", {})
                if msg.get("method") == "Network.responseReceived":
                    net_events.append(msg["params"])
                # other events: discard

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

        if not wait_for('[aria-label="Add a note"]', 10):
            body = js("document.body.innerText") or ""
            if "already connected" in body.lower() or "ya estás conectado" in body.lower():
                sys.exit("ERROR: already connected to this person")
            if 'type="email"' in (js("document.body.innerHTML") or ""):
                sys.exit("ERROR: email verification required to connect (high-profile account)")
            sys.exit(f"ERROR: invite modal not found. Body start: {body[:400]}")

        print("Modal found. Clicking 'Add a note'...")
        js('document.querySelector(\'[aria-label="Add a note"]\').click()')

        if not wait_for("#custom-message", 8):
            sys.exit("ERROR: textarea #custom-message did not appear after clicking 'Add a note'")

        print(f"Typing note ({len(note)} chars)...")
        js("document.querySelector('#custom-message').focus()")
        time.sleep(0.3)
        # Input.insertText simulates real keyboard paste - triggers Ember input events
        cmd("Input.insertText", {"text": note})
        time.sleep(0.5)

        typed = js("document.querySelector('#custom-message').value") or ""
        print(f"Verified in textarea ({len(typed)} chars): '{typed[:60]}{'...' if len(typed) > 60 else ''}'")
        if typed.strip() != note.strip():
            print(f"WARNING: textarea mismatch - got {len(typed)} chars, expected {len(note)}",
                  file=sys.stderr)

        if dry_run:
            print("DRY RUN: stopping before send.")
            return {"status": "dry_run", "typed": typed}

        # After typing, LinkedIn changes the primary button label
        send_label = js('''(function() {
            var b = Array.from(document.querySelectorAll("button")).find(function(b) {
                var l = (b.getAttribute("aria-label") || b.textContent || "").toLowerCase();
                return l.includes("send") && !l.includes("without");
            });
            return b ? (b.getAttribute("aria-label") || b.textContent.trim()) : null;
        })()''')

        if not send_label:
            all_btns = js(
                'Array.from(document.querySelectorAll("button"))'
                '.map(function(b){return (b.getAttribute("aria-label")||"")+'
                '"|"+b.textContent.trim()}).join("; ")'
            )
            sys.exit(f"ERROR: send button not found after typing. Buttons present: {all_btns}")

        print(f"Clicking send button: '{send_label}'")
        js('''(function() {
            var b = Array.from(document.querySelectorAll("button")).find(function(b) {
                var l = (b.getAttribute("aria-label") || b.textContent || "").toLowerCase();
                return l.includes("send") && !l.includes("without");
            });
            if (b) b.click();
        })()''')

        print("Waiting for server response...")
        time.sleep(5)

        toast = js(
            'document.querySelector(".artdeco-toast-item__message, '
            '[data-test-artdeco-toast-item]")?.textContent?.trim() || null'
        )
        modal_gone = not js('!!document.querySelector("#send-invite-modal")')

        # net_events fills as cmd() recvs frames; the js() calls above drained any
        # buffered events along with their responses.
        inv_events = [
            e for e in net_events
            if any(k in e["response"]["url"]
                   for k in ["invitation", "relationship", "connect"])
        ]

        # Fetch response body from the Voyager invitation API call
        server_body = None
        server_message_echo = None
        voyager_event = next(
            (e for e in inv_events if "verifyQuotaAndCreate" in e["response"]["url"]),
            None,
        )
        if voyager_event:
            try:
                body_result = cmd("Network.getResponseBody",
                                  {"requestId": voyager_event["requestId"]})
                raw_body = body_result.get("body", "")
                server_body = json.loads(raw_body) if raw_body else None
                if server_body:
                    body_str = json.dumps(server_body)
                    msg_match = re.search(
                        r'"(?:message|customMessage|note)"\s*:\s*"([^"]+)"', body_str)
                    if msg_match:
                        server_message_echo = msg_match.group(1)
            except Exception as e:
                print(f"WARNING: could not fetch API response body: {e}", file=sys.stderr)

        print("\n=== Server Confirmation ===")
        if toast:
            print(f"Toast notification: {toast}")
        print(f"Modal closed after send: {modal_gone}")
        for e in inv_events:
            print(f"API response: HTTP {e['response']['status']} <- {e['response']['url']}")
        if server_message_echo:
            print(f"Message confirmed by server: \"{server_message_echo}\"")
        elif server_body is not None:
            print(f"Server response body (no message field found): {json.dumps(server_body)[:400]}")
        elif voyager_event:
            print("WARNING: Voyager API called but response body was empty or unreadable",
                  file=sys.stderr)
        else:
            print("WARNING: Voyager invitation API call not captured in network monitor",
                  file=sys.stderr)

        success = bool(
            toast
            or modal_gone
            or any(e["response"]["status"] in (200, 201, 204) for e in inv_events)
        )

        return {
            "status": "sent" if success else "uncertain",
            "toast": toast,
            "modal_closed": modal_gone,
            "server_message_echo": server_message_echo,
            "api_responses": [
                {"url": e["response"]["url"], "status": e["response"]["status"]}
                for e in inv_events
            ],
        }
    finally:
        _ws_close(sock)


def main():
    p = argparse.ArgumentParser(
        description="Send a LinkedIn connection invite with a note")
    p.add_argument("vanity_name",
                   help="LinkedIn vanity slug, e.g. john-smith-123")
    p.add_argument("note", help=f"Personalised note (<={MAX_NOTE_CHARS} chars)")
    p.add_argument("--dry-run", action="store_true",
                   help="Type note but do not click Send")
    args = p.parse_args()

    result = send_connection_invite(args.vanity_name, args.note, args.dry_run)

    print("\n=== RESULT ===")
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if result["status"] == "sent":
        echo = result.get("server_message_echo")
        if echo:
            print(f"\nSUCCESS: invitation sent. Server confirmed note: \"{echo}\"")
        else:
            print("\nSUCCESS: invitation sent (server confirmed via API + modal close; note text not echoed in response).")
    elif result["status"] == "dry_run":
        print("\nDRY RUN complete - no invite sent.")
    else:
        print("\nUNCERTAIN - could not confirm server acceptance. Check LinkedIn manually.",
              file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
