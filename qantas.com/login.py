#!/usr/bin/env python3
"""Log into Qantas Frequent Flyer via CDP and print account state.

Reads credentials.json (memberId, lastName, pin) from this directory, drives
the sign-in form on www.qantas.com, navigates to my-account, and extracts
{first_name, tier, member_id, points, status_credits}.

Cookies do not persist between invocations when the snap chromium browser
is open (it locks the profile), so this script is the canonical way to read
the authenticated state - login + balance happen in one CDP session.

Usage:
    python3 login.py            # human-readable
    python3 login.py --json     # JSON
    python3 login.py --check    # open login page, do not submit
"""

import argparse
import asyncio
import configparser
import json
import os
import re
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

try:
    import websockets
except ImportError:
    sys.exit("ERROR: install websockets: pip3 install websockets")

HERE = os.path.dirname(os.path.abspath(__file__))
PROFILE = os.path.join(os.path.expanduser("~"), "snap/chromium/common/chromium")
CDP_PORT = 9224
LOGIN_URL = "https://www.qantas.com/au/en/frequent-flyer/my-account/sign-in.html"
ACCOUNT_URL = "https://www.qantas.com/au/en/frequent-flyer/my-account.html"


def _snap_chromium_running():
    r = subprocess.run(["pgrep", "-f", "snap/chromium/common/chromium"],
                       capture_output=True, text=True)
    return r.stdout.strip()


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
    sys.exit("ERROR: CDP endpoint not ready - chromium failed to start")


def _parse_account_body(body: str) -> dict:
    """Extract {first_name, tier, member_id, points, status_credits} from
    the visible text of the rendered my-account page.

    Layout (line-broken):
        Profile
        , Weiwu
        Bronze:
        1918593383
        ...
        Qantas Points
        151,906
        Status Credits
        0
    """
    out = {}

    # First name: line starting with ", " under Profile header
    m = re.search(r"^,\s*([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\s*$", body, re.M)
    if m:
        out["first_name"] = m.group(1)

    # Tier: a tier name on its own line, optionally with trailing ":"
    m = re.search(
        r"^(Bronze|Silver|Gold|Platinum One|Platinum|Chairman's Lounge):?\s*$",
        body, re.M)
    if m:
        out["tier"] = m.group(1)

    # Member ID: 10 digits on its own line
    m = re.search(r"^(\d{10})\s*$", body, re.M)
    if m:
        out["member_id"] = m.group(1)

    # Points: number on the line after "Qantas Points". The rendered DOM
    # sometimes uses "," and sometimes "." as the thousands separator.
    m = re.search(r"^Qantas Points\s*\n+\s*([\d.,]+)\s*$", body, re.M)
    if m:
        out["points"] = int(re.sub(r"[.,]", "", m.group(1)))

    # Status Credits: same pattern
    m = re.search(r"^Status Credits\s*\n+\s*([\d.,]+)\s*$", body, re.M)
    if m:
        out["status_credits"] = int(re.sub(r"[.,]", "", m.group(1)))

    return out


async def run(check_only: bool, debug: bool):
    cfg_file = Path.home() / ".claude" / "skills" / "config.ini"
    if not cfg_file.exists():
        sys.exit(f"ERROR: {cfg_file} not found. See Prerequisites in the aesop qantas.com SKILL.md.")
    cp = configparser.ConfigParser(interpolation=None)
    cp.read(cfg_file)
    member_id = cp.get("qantas.com", "member_id", fallback="").strip()
    last_name = cp.get("qantas.com", "last_name", fallback="").strip()
    pin = cp.get("qantas.com", "pin", fallback="").strip()
    for k, v in (("member_id", member_id), ("last_name", last_name), ("pin", pin)):
        if not v:
            sys.exit(f"ERROR: ~/.claude/skills/config.ini missing [qantas.com] {k}")

    pids = _snap_chromium_running()
    if pids and debug:
        print(f"[snap chromium running, PIDs: {pids}]", file=sys.stderr)

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
        async with websockets.connect(ws_url, max_size=50_000_000) as ws:
            cmd_q: asyncio.Queue = asyncio.Queue()
            _id = 0

            async def reader():
                try:
                    async for raw in ws:
                        msg = json.loads(raw)
                        if "id" in msg:
                            await cmd_q.put(msg)
                except Exception:
                    pass

            reader_task = asyncio.create_task(reader())

            async def cmd(method, params=None):
                nonlocal _id
                _id += 1
                cid = _id
                await ws.send(json.dumps({"id": cid, "method": method,
                                          "params": params or {}}))
                while True:
                    r = await asyncio.wait_for(cmd_q.get(), timeout=20)
                    if r["id"] == cid:
                        if "error" in r:
                            raise RuntimeError(f"{method}: {r['error']}")
                        return r.get("result", {})

            async def js(expr, default=None):
                try:
                    r = await cmd("Runtime.evaluate", {
                        "expression": expr,
                        "awaitPromise": False,
                        "returnByValue": True,
                    })
                    if "exceptionDetails" in r:
                        return default
                    return r.get("result", {}).get("value")
                except Exception:
                    return default

            async def wait_for(selector, timeout=10):
                t0 = time.time()
                while time.time() - t0 < timeout:
                    if await js(f"!!document.querySelector({json.dumps(selector)})"):
                        return True
                    await asyncio.sleep(0.4)
                return False

            await cmd("Network.enable")
            await cmd("Page.enable")

            if debug:
                print(f"[navigate] {LOGIN_URL}", file=sys.stderr)
            await cmd("Page.navigate", {"url": LOGIN_URL})
            await asyncio.sleep(5)

            if not await wait_for("#pin", 12):
                body = (await js("document.body.innerText", "") or "")[:400]
                sys.exit(f"ERROR: PIN field did not appear. Body: {body}")

            if check_only:
                print("Check only - login form ready, not submitting.")
                reader_task.cancel()
                return 0, {}

            for fid, val in (("memberId", member_id),
                             ("lastName", last_name),
                             ("pin", pin)):
                await js(f'document.querySelector("#{fid}").focus();'
                         f'document.querySelector("#{fid}").value = "";'
                         f'document.querySelector("#{fid}").dispatchEvent(new Event("input",{{bubbles:true}}));')
                await asyncio.sleep(0.2)
                await cmd("Input.insertText", {"text": val})
                await asyncio.sleep(0.2)
                if debug:
                    got = await js(f'document.querySelector("#{fid}").value', "") or ""
                    shown = "*" * len(got) if fid == "pin" else got
                    print(f"[fill] {fid}={shown} ({len(got)} chars)", file=sys.stderr)

            clicked = await js('''(function(){
                var btns = Array.from(document.querySelectorAll("button"));
                var b = btns.find(function(x){
                    var t = (x.textContent || "").trim().toLowerCase();
                    return x.type === "submit" || t === "log in" || t === "login";
                });
                if (b) { b.click(); return true; }
                return false;
            })()''')
            if not clicked:
                sys.exit("ERROR: LOG IN button not found")

            # Wait until URL is no longer sign-in (login redirect completes)
            t0 = time.time()
            while time.time() - t0 < 25:
                await asyncio.sleep(1)
                u = await js("window.location.href", "") or ""
                if "/my-account" in u and "sign-in" not in u:
                    break

            # Confirm we're on my-account; if still on sign-in, login failed
            ma_url = await js("window.location.href", "") or ""
            ma_title = await js("document.title", "") or ""
            if "sign-in" in ma_url or "Login" in ma_title:
                err = await js(
                    '(function(){var e=document.querySelector('
                    '"[role=\\"alert\\"], .error, [data-testid*=\\"error\\"]");'
                    'return e ? e.textContent.trim() : null;})()')
                reader_task.cancel()
                msg = f"login did not complete (URL={ma_url}, title={ma_title})"
                if err:
                    msg += f"; page error: {err}"
                return 1, {"error": msg}

            # Read balance from current my-account page; if not there yet, navigate
            if "/my-account" not in ma_url:
                await cmd("Page.navigate", {"url": ACCOUNT_URL})
                await asyncio.sleep(6)

            # Wait for points to render (SPA may hydrate after navigation)
            t0 = time.time()
            body = ""
            while time.time() - t0 < 15:
                await asyncio.sleep(1)
                body = await js("document.body.innerText", "") or ""
                if "Qantas Points" in body and re.search(r"\d{1,3}(?:,\d{3})", body):
                    break

            data = _parse_account_body(body)
            reader_task.cancel()
            return 0, data
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--check", action="store_true",
                   help="Open the login page but do not submit.")
    p.add_argument("--json", action="store_true",
                   help="Print JSON instead of human-readable summary.")
    p.add_argument("--debug", action="store_true",
                   help="Verbose progress on stderr.")
    args = p.parse_args()

    code, data = asyncio.run(run(check_only=args.check, debug=args.debug))

    if args.json:
        print(json.dumps(data, indent=2))
    elif code == 0 and data:
        name = data.get("first_name", "?")
        tier = data.get("tier", "?")
        mid = data.get("member_id", "?")
        pts = data.get("points")
        sc = data.get("status_credits")
        pts_str = f"{pts:,}" if isinstance(pts, int) else "?"
        sc_str = f"{sc:,}" if isinstance(sc, int) else "?"
        print(f"{name} ({tier}, {mid}): {pts_str} pts, {sc_str} status credits")
    elif code != 0 and data.get("error"):
        print(f"ERROR: {data['error']}", file=sys.stderr)

    sys.exit(code)


if __name__ == "__main__":
    main()
