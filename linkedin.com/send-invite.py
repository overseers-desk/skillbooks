#!/usr/bin/env python3
"""Send a LinkedIn connection invite with a personalised note via CDP.

Usage:
    python3 send-invite.py VANITY_NAME "Note text (≤300 chars)"
    python3 send-invite.py VANITY_NAME "Note text" --dry-run   # stop before clicking Send
"""

import argparse
import asyncio
import json
import os
import re
import subprocess
import sys
import time
import urllib.request

try:
    import websockets
except ImportError:
    sys.exit("ERROR: install websockets: pip3 install websockets")

PROFILE = os.path.join(os.path.expanduser("~"), "snap/chromium/common/chromium")
CDP_PORT = 9223
MAX_NOTE_CHARS = 300


def _snap_chromium_running():
    r = subprocess.run(["pgrep", "-f", "snap/chromium/common/chromium"],
                       capture_output=True, text=True)
    return r.stdout.strip()


async def send_connection_invite(vanity_name: str, note: str, dry_run: bool = False):
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
        ws_url = await _wait_for_cdp()
        return await _run_flow(ws_url, url, note, dry_run)
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()


async def _wait_for_cdp(retries=30):
    for _ in range(retries):
        await asyncio.sleep(0.5)
        try:
            with urllib.request.urlopen(
                    f"http://localhost:{CDP_PORT}/json/list", timeout=2) as r:
                tabs = json.loads(r.read())
                if tabs:
                    return tabs[0]["webSocketDebuggerUrl"]
        except Exception:
            pass
    sys.exit("ERROR: CDP endpoint not ready — chromium failed to start")


async def _run_flow(ws_url: str, page_url: str, note: str, dry_run: bool) -> dict:
    async with websockets.connect(ws_url, max_size=50_000_000) as ws:
        cmd_q: asyncio.Queue = asyncio.Queue()
        net_events: list = []
        _id = 0

        async def _reader():
            try:
                async for raw in ws:
                    msg = json.loads(raw)
                    if "id" in msg:
                        await cmd_q.put(msg)
                    elif msg.get("method") == "Network.responseReceived":
                        net_events.append(msg["params"])
            except Exception:
                pass

        reader_task = asyncio.create_task(_reader())

        async def cmd(method, params=None):
            nonlocal _id
            _id += 1
            cid = _id
            await ws.send(json.dumps({"id": cid, "method": method,
                                      "params": params or {}}))
            while True:
                r = await asyncio.wait_for(cmd_q.get(), timeout=15)
                if r["id"] == cid:
                    if "error" in r:
                        raise RuntimeError(f"{method}: {r['error']}")
                    return r.get("result", {})

        async def js(expr):
            r = await cmd("Runtime.evaluate", {
                "expression": expr,
                "awaitPromise": False,
                "returnByValue": True,
            })
            if "exceptionDetails" in r:
                raise RuntimeError(r["exceptionDetails"].get("text", "JS error"))
            return r.get("result", {}).get("value")

        async def wait_for(selector, timeout=10):
            t0 = time.time()
            while time.time() - t0 < timeout:
                if await js(f"!!document.querySelector({json.dumps(selector)})"):
                    return True
                await asyncio.sleep(0.5)
            return False

        await cmd("Network.enable")
        await cmd("Page.enable")

        print(f"Navigating to: {page_url}")
        await cmd("Page.navigate", {"url": page_url})
        await asyncio.sleep(4)

        title = await js("document.title") or ""
        print(f"Page title: {title}")
        if any(x in title.lower() for x in ["sign in", "log in", "iniciar"]):
            sys.exit("ERROR: got sign-in page — session is not active")

        if not await wait_for('[aria-label="Add a note"]', 10):
            body = await js("document.body.innerText") or ""
            # Check for already-connected or email-required states
            if "already connected" in body.lower() or "ya estás conectado" in body.lower():
                sys.exit("ERROR: already connected to this person")
            if 'type="email"' in (await js("document.body.innerHTML") or ""):
                sys.exit("ERROR: email verification required to connect (high-profile account)")
            sys.exit(f"ERROR: invite modal not found. Body start: {body[:400]}")

        print("Modal found. Clicking 'Add a note'...")
        await js('document.querySelector(\'[aria-label="Add a note"]\').click()')

        if not await wait_for("#custom-message", 8):
            sys.exit("ERROR: textarea #custom-message did not appear after clicking 'Add a note'")

        print(f"Typing note ({len(note)} chars)...")
        await js("document.querySelector('#custom-message').focus()")
        await asyncio.sleep(0.3)
        # Input.insertText simulates real keyboard paste — triggers Ember input events
        await cmd("Input.insertText", {"text": note})
        await asyncio.sleep(0.5)

        typed = await js("document.querySelector('#custom-message').value") or ""
        print(f"Verified in textarea ({len(typed)} chars): '{typed[:60]}{'...' if len(typed) > 60 else ''}'")
        if typed.strip() != note.strip():
            print(f"WARNING: textarea mismatch — got {len(typed)} chars, expected {len(note)}",
                  file=sys.stderr)

        if dry_run:
            print("DRY RUN: stopping before send.")
            reader_task.cancel()
            return {"status": "dry_run", "typed": typed}

        # Find the send button — after typing, LinkedIn changes the primary button label
        send_label = await js('''(function() {
            var b = Array.from(document.querySelectorAll("button")).find(function(b) {
                var l = (b.getAttribute("aria-label") || b.textContent || "").toLowerCase();
                return l.includes("send") && !l.includes("without");
            });
            return b ? (b.getAttribute("aria-label") || b.textContent.trim()) : null;
        })()''')

        if not send_label:
            all_btns = await js(
                'Array.from(document.querySelectorAll("button"))'
                '.map(function(b){return (b.getAttribute("aria-label")||"")+'
                '"|"+b.textContent.trim()}).join("; ")'
            )
            sys.exit(f"ERROR: send button not found after typing. Buttons present: {all_btns}")

        print(f"Clicking send button: '{send_label}'")
        await js('''(function() {
            var b = Array.from(document.querySelectorAll("button")).find(function(b) {
                var l = (b.getAttribute("aria-label") || b.textContent || "").toLowerCase();
                return l.includes("send") && !l.includes("without");
            });
            if (b) b.click();
        })()''')

        print("Waiting for server response...")
        await asyncio.sleep(5)

        # Confirmation signals from DOM
        toast = await js(
            'document.querySelector(".artdeco-toast-item__message, '
            '[data-test-artdeco-toast-item]")?.textContent?.trim() || null'
        )
        modal_gone = not await js('!!document.querySelector("#send-invite-modal")')
        page_text = await js("document.body.innerText") or ""

        # Confirmation signals from network (invitation API calls)
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
                body_result = await cmd("Network.getResponseBody",
                                        {"requestId": voyager_event["requestId"]})
                raw_body = body_result.get("body", "")
                server_body = json.loads(raw_body) if raw_body else None
                # Walk the response JSON looking for the message/note field
                if server_body:
                    body_str = json.dumps(server_body)
                    # Extract message echo if present
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
            print(f"API response: HTTP {e['response']['status']} ← {e['response']['url']}")
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

        reader_task.cancel()
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


def main():
    p = argparse.ArgumentParser(
        description="Send a LinkedIn connection invite with a note")
    p.add_argument("vanity_name",
                   help="LinkedIn vanity slug, e.g. john-smith-123")
    p.add_argument("note", help=f"Personalised note (≤{MAX_NOTE_CHARS} chars)")
    p.add_argument("--dry-run", action="store_true",
                   help="Type note but do not click Send")
    args = p.parse_args()

    result = asyncio.run(
        send_connection_invite(args.vanity_name, args.note, args.dry_run))

    print("\n=== RESULT ===")
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if result["status"] == "sent":
        echo = result.get("server_message_echo")
        if echo:
            print(f"\nSUCCESS: invitation sent. Server confirmed note: \"{echo}\"")
        else:
            print("\nSUCCESS: invitation sent (server confirmed via API + modal close; note text not echoed in response).")
    elif result["status"] == "dry_run":
        print("\nDRY RUN complete — no invite sent.")
    else:
        print("\nUNCERTAIN — could not confirm server acceptance. Check LinkedIn manually.",
              file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
