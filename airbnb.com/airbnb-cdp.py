#!/usr/bin/env python3
"""CDP helper for Airbnb hosting quick replies.

Launches a headless browser with the user's logged-in profile, navigates to
the quick replies settings page, intercepts the API response that page makes,
and returns the quick replies as JSON.

Usage:
    python3 airbnb-cdp.py list [--product STAYS|EXPERIENCES]
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


# Hand-rolled WebSocket over stdlib socket. CDP runs ws:// on localhost,
# so no TLS, no extensions, no permessage-deflate. socket.settimeout() works
# on the returned socket directly.

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

BROWSER_WRAPPER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "bin", "browser")

# Buffered CDP events (unsolicited messages that arrive during send_cdp calls)
_event_buffer = []


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
    targets = json.loads(urllib.request.urlopen(f"http://127.0.0.1:{port}/json").read())
    ws_url = targets[0]["webSocketDebuggerUrl"]
    return _ws_connect(ws_url, timeout=20)


def send_cdp(ws, method, params=None, counter=[0]):
    """Send a CDP command and return its response, buffering any events that arrive."""
    counter[0] += 1
    mid = counter[0]
    msg = {"id": mid, "method": method}
    if params:
        msg["params"] = params
    _ws_send(ws, json.dumps(msg))
    deadline = time.time() + 25
    while time.time() < deadline:
        ws.settimeout(1.0)
        try:
            raw = _ws_recv(ws)
        except (TimeoutError, OSError):
            continue
        resp = json.loads(raw)
        if "method" in resp:
            _event_buffer.append(resp)
            continue
        if resp.get("id") == mid:
            return resp
    return None


def drain_events(ws, duration):
    """Collect CDP events for `duration` seconds, buffering them all."""
    deadline = time.time() + duration
    while time.time() < deadline:
        ws.settimeout(0.3)
        try:
            raw = _ws_recv(ws)
            msg = json.loads(raw)
            if "method" in msg:
                _event_buffer.append(msg)
        except Exception:
            pass


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
    except (json.JSONDecodeError, TypeError):
        return {"raw": val}


def check_logged_in(ws):
    """Return True if the current page is an authenticated Airbnb hosting page."""
    result = eval_js(ws, "window.location.href")
    url = result.get("raw", "") if isinstance(result, dict) else str(result)
    # If redirected to login, we're not logged in
    if "/login" in url or "/signup" in url:
        return False
    title = eval_js(ws, "document.title")
    t = title.get("raw", "") if isinstance(title, dict) else str(title)
    if "Log in" in t or "Sign up" in t:
        return False
    return True


def cmd_list(ws, args):
    product = args.product
    url = f"https://www.airbnb.com/hosting/messages/settings/quick-replies?product={product}"

    send_cdp(ws, "Network.enable")
    send_cdp(ws, "Page.navigate", {"url": url})

    # Collect network events while the page loads
    drain_events(ws, duration=10)

    if not check_logged_in(ws):
        return {"error": "Not logged in to Airbnb. Log in via your browser first, then close it before running this script."}

    # Find quick-reply-related API responses in the event buffer
    pending = {}
    for evt in _event_buffer:
        if evt.get("method") == "Network.responseReceived":
            resp_url = evt["params"]["response"]["url"]
            # Match any API call that looks like quick replies
            if "quick" in resp_url.lower() and "airbnb.com/api" in resp_url:
                req_id = evt["params"]["requestId"]
                pending[req_id] = {
                    "url": resp_url,
                    "status": evt["params"]["response"]["status"],
                }

    # Fetch response bodies while they're still in the CDP network cache
    captured = []
    for req_id, meta in pending.items():
        body_resp = send_cdp(ws, "Network.getResponseBody", {"requestId": req_id})
        if body_resp:
            raw_body = body_resp.get("result", {}).get("body", "")
            try:
                meta["data"] = json.loads(raw_body)
            except json.JSONDecodeError:
                meta["raw"] = raw_body
        captured.append(meta)

    if captured:
        return captured

    # Fallback: make API calls directly from JS using the page's auth tokens
    js = """
    (async () => {
        const apiKeyMeta = document.querySelector('meta[name="api-key"]');
        const apiKey = apiKeyMeta ? apiKeyMeta.getAttribute('content') : '';

        const csrfMeta = document.querySelector('meta[name="_csrf_token"]') ||
                         document.querySelector('meta[name="csrf-token"]');
        const csrf = csrfMeta ? csrfMeta.getAttribute('content') : '';

        const headers = {'Accept': 'application/json'};
        if (apiKey) headers['X-Airbnb-API-Key'] = apiKey;
        if (csrf) headers['X-CSRF-Token'] = csrf;

        const endpoints = [
            '/api/v2/messaging_quick_replies?locale=en&currency=AUD&role=host',
            '/api/v2/messaging_quick_replies?locale=en&role=host',
        ];

        for (const ep of endpoints) {
            try {
                const resp = await fetch(ep, {credentials: 'include', headers});
                const body = await resp.text();
                let parsed;
                try { parsed = JSON.parse(body); } catch(e) { parsed = null; }
                return JSON.stringify({
                    endpoint: ep,
                    status: resp.status,
                    data: parsed,
                    raw: parsed ? undefined : body,
                    api_key_found: !!apiKey,
                    csrf_found: !!csrf,
                });
            } catch(e) {
                continue;
            }
        }

        return JSON.stringify({
            error: 'All endpoints failed',
            api_key_found: !!apiKey,
            csrf_found: !!csrf,
            current_url: window.location.href,
        });
    })()
    """
    return eval_js(ws, js)


def main():
    parser = argparse.ArgumentParser(description="Airbnb hosting quick replies CDP helper")
    sub = parser.add_subparsers(dest="command")

    p_list = sub.add_parser("list", help="List all quick replies")
    p_list.add_argument("--product", choices=["STAYS", "EXPERIENCES"], default="STAYS",
                        help="Product type (default: STAYS)")

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
        commands = {
            "list": cmd_list,
        }
        result = commands[args.command](ws, args)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        _ws_close(ws)
    finally:
        proc.terminate()
        proc.wait(timeout=5)


if __name__ == "__main__":
    main()
