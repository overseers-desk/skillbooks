#!/usr/bin/env python3
"""
CDP helper for Otter.ai API calls.

Launches a headless Chrome-compatible browser with the user's logged-in profile,
navigates to otter.ai to establish session context, then executes JavaScript
fetch() calls against the Otter.ai internal API. Returns JSON results to stdout.

Usage:
    python3 otter-cdp.py list [--page-size N] [--last-load-ts TS]
    python3 otter-cdp.py rename <otid> <new_title>
    python3 otter-cdp.py export-dropbox <otid> [--format txt|pdf|docx|srt]
    python3 otter-cdp.py fetch-via-dropbox <otid> [--timeout N] [--extended-timeout N]
    python3 otter-cdp.py dropbox-status
"""

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.request

try:
    import websocket
except ImportError:
    print(json.dumps({"error": "websocket-client not installed. Run: pip install websocket-client"}))
    sys.exit(1)

UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36")

def detect_browser():
    """Return the Chromium browser binary, or None if not found."""
    if sys.platform == "darwin":
        candidates = ["/Applications/Chromium.app/Contents/MacOS/Chromium"]
    else:
        candidates = ["chromium-browser", "chromium", "/snap/bin/chromium"]
    for cmd in candidates:
        try:
            subprocess.run([cmd, "--version"], capture_output=True, timeout=3)
            return cmd
        except Exception:
            continue
    return None

def detect_profile():
    """Return the browser user-data-dir, trying known Chromium profile locations."""
    if sys.platform == "darwin":
        candidates = [
            os.path.expanduser("~/Library/Application Support/Chromium"),
        ]
    else:
        candidates = [
            os.path.expanduser("~/snap/chromium/common/chromium"),
            os.path.expanduser("~/.config/chromium"),
        ]
    for path in candidates:
        if os.path.isdir(path):
            return path
    return None

def launch_browser(profile):
    browser = detect_browser()
    if not browser:
        return None, None
    proc = subprocess.Popen(
        [browser, "--headless=new", "--disable-gpu",
         f"--user-agent={UA}",
         f"--user-data-dir={profile}",
         "--remote-debugging-port=0",
         "--remote-allow-origins=*",
         "--window-size=1920,1080",
         "about:blank"],
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
    ws = websocket.create_connection(ws_url, timeout=20)
    return ws

def send_cdp(ws, method, params=None, counter=[0]):
    counter[0] += 1
    mid = counter[0]
    msg = {"id": mid, "method": method}
    if params:
        msg["params"] = params
    ws.send(json.dumps(msg))
    deadline = time.time() + 25
    while time.time() < deadline:
        resp = json.loads(ws.recv())
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

def navigate_and_wait(ws, url, wait_seconds=6):
    send_cdp(ws, "Page.navigate", {"url": url})
    time.sleep(wait_seconds)

def check_logged_in(ws):
    result = eval_js(ws, "document.title")
    title = result.get("raw", "")
    if "Sign In" in title or "Log In" in title:
        return False
    return True

# --- Commands ---

def cmd_list(ws, args):
    params = f"page_size={args.page_size}"
    if args.last_load_ts:
        params += f"&last_load_ts={args.last_load_ts}"
    js = f"""
    (async () => {{
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const resp = await fetch('/forward/api/v1/speeches?{params}', {{
            credentials: 'include',
            headers: {{'x-csrftoken': csrf}}
        }});
        const data = await resp.json();
        if (data.speeches) {{
            data.speeches = data.speeches.map(s => ({{
                otid: s.otid,
                title: s.title,
                created_at: s.created_at,
                duration: s.duration,
                summary: s.summary,
                start_time: s.start_time,
                process_finished: s.process_finished,
                folder: s.folder,
                link: 'https://otter.ai/u/' + s.otid,
            }}));
        }}
        return JSON.stringify(data);
    }})()
    """
    return eval_js(ws, js)

def cmd_rename(ws, args):
    otid = args.otid
    title = args.new_title
    js = f"""
    (async () => {{
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const params = new URLSearchParams({{
            otid: '{otid}',
            title: {json.dumps(title)},
        }});
        const resp = await fetch('/forward/api/v1/set_speech_title?' + params.toString(), {{
            method: 'POST',
            credentials: 'include',
            headers: {{'x-csrftoken': csrf}}
        }});
        return await resp.text();
    }})()
    """
    return eval_js(ws, js)

def _get_dropbox_id_js():
    """JS snippet that fetches the Dropbox account ID from synced_accounts."""
    return """
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const userResp = await fetch('/forward/api/v1/user', {
            credentials: 'include',
            headers: {'x-csrftoken': csrf}
        });
        const userData = await userResp.json();
        const synced = userData.user?.synced_accounts || [];
        const dbAccount = synced.find(a => a.source === 'DropBox');
        if (!dbAccount) {
            return JSON.stringify({error: 'Dropbox is not connected. Connect at otter.ai Settings > Apps & Integrations > Dropbox.'});
        }
        const dropboxId = dbAccount.dropbox_account_id;
    """

def cmd_export_dropbox(ws, args):
    otid = args.otid
    fmt = args.format

    endpoint_map = {
        "txt": "dropbox_speech_txt",
        "pdf": "dropbox_speech_pdf",
        "docx": "dropbox_speech_word",
        "srt": "dropbox_speech_srt",
    }
    endpoint = endpoint_map.get(fmt, "dropbox_speech_txt")
    get_db_id = _get_dropbox_id_js()

    if fmt == "txt":
        js = f"""
        (async () => {{
            {get_db_id}
            const fd = new FormData();
            fd.append('speaker_names', 'true');
            fd.append('speaker_timestamps', 'true');
            fd.append('dropbox_account_id', dropboxId);
            fd.append('branding', 'true');
            fd.append('merge_same_speaker_segments', 'false');
            fd.append('otids', '{otid}');
            fd.append('highlight_only', 'false');
            const resp = await fetch('/forward/api/v1/{endpoint}', {{
                method: 'POST',
                credentials: 'include',
                headers: {{'x-csrftoken': csrf}},
                body: fd,
            }});
            return await resp.text();
        }})()
        """
    elif fmt == "srt":
        js = f"""
        (async () => {{
            {get_db_id}
            const fd = new FormData();
            fd.append('speaker_names', 'true');
            fd.append('dropbox_account_id', dropboxId);
            fd.append('otids', '{otid}');
            fd.append('advanced_srt', 'false');
            fd.append('max_lines', '2');
            fd.append('char_per_line', '42');
            const resp = await fetch('/forward/api/v1/{endpoint}', {{
                method: 'POST',
                credentials: 'include',
                headers: {{'x-csrftoken': csrf}},
                body: fd,
            }});
            return await resp.text();
        }})()
        """
    else:
        # pdf or docx share the same parameter pattern
        js = f"""
        (async () => {{
            {get_db_id}
            const tz = Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC';
            const fd = new FormData();
            fd.append('speaker_names', 'true');
            fd.append('speaker_timestamps', 'true');
            fd.append('dropbox_account_id', dropboxId);
            fd.append('inline_pictures', 'false');
            fd.append('merge_same_speaker_segments', 'false');
            fd.append('otids', '{otid}');
            fd.append('highlight_only', 'false');
            fd.append('show_highlights', 'true');
            fd.append('monologue', 'false');
            fd.append('time_zone', tz);
            const resp = await fetch('/forward/api/v1/{endpoint}', {{
                method: 'POST',
                credentials: 'include',
                headers: {{'x-csrftoken': csrf}},
                body: fd,
            }});
            return await resp.text();
        }})()
        """

    return eval_js(ws, js)

DROPBOX_OTTER_REMOTE = "Dropbox:Apps/Otter"


def _rclone_lsf_otter():
    """Return the set of filenames in Dropbox:Apps/Otter, or None on rclone failure."""
    try:
        out = subprocess.run(
            ["rclone", "lsf", DROPBOX_OTTER_REMOTE],
            capture_output=True, text=True, timeout=30,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired) as e:
        sys.stderr.write(f"rclone lsf failed: {e}\n")
        return None
    if out.returncode != 0:
        sys.stderr.write(f"rclone lsf failed: {out.stderr.strip()}\n")
        return None
    return {line.strip() for line in out.stdout.splitlines() if line.strip()}


def cmd_fetch_via_dropbox(ws, args):
    """Export <otid> as txt to Dropbox, wait for the file to appear, read it,
    delete it from Dropbox, and return its content.

    Output: {"otid", "dropbox_filename", "content"} on success, {"error", ...} on failure.
    """
    initial = _rclone_lsf_otter()
    if initial is None:
        return {"error": f"rclone lsf {DROPBOX_OTTER_REMOTE} failed (is rclone configured?)"}

    args.format = "txt"
    export_result = cmd_export_dropbox(ws, args)
    if isinstance(export_result, dict) and export_result.get("error"):
        return export_result
    if isinstance(export_result, dict) and export_result.get("failed_speeches"):
        return {"error": "Otter.ai export reported failure",
                "failed_speeches": export_result["failed_speeches"]}

    poll_interval = 5
    start = time.time()
    initial_deadline = start + args.timeout
    extended_deadline = start + args.extended_timeout
    extended_logged = False
    new_files = set()

    while True:
        time.sleep(poll_interval)
        current = _rclone_lsf_otter()
        if current is None:
            return {"error": f"rclone lsf {DROPBOX_OTTER_REMOTE} failed during poll"}
        new_files = current - initial
        if new_files:
            break
        now = time.time()
        if now >= extended_deadline:
            return {"error": "Timeout waiting for Dropbox export",
                    "otid": args.otid,
                    "elapsed": int(now - start)}
        if now >= initial_deadline and not extended_logged:
            sys.stderr.write(
                f"Initial timeout ({args.timeout}s) exceeded, "
                f"extending to {args.extended_timeout}s\n"
            )
            extended_logged = True

    if len(new_files) > 1:
        return {"error": "Multiple new files in Dropbox:Apps/Otter; cannot disambiguate",
                "files": sorted(new_files)}

    filename = next(iter(new_files))
    remote_path = f"{DROPBOX_OTTER_REMOTE}/{filename}"

    cat_out = subprocess.run(
        ["rclone", "cat", remote_path],
        capture_output=True, text=True, timeout=120,
    )
    if cat_out.returncode != 0:
        return {"error": "rclone cat failed",
                "remote_path": remote_path,
                "stderr": cat_out.stderr.strip()}
    content = cat_out.stdout

    del_out = subprocess.run(
        ["rclone", "delete", remote_path],
        capture_output=True, text=True, timeout=30,
    )
    if del_out.returncode != 0:
        sys.stderr.write(
            f"Warning: rclone delete {remote_path} failed: {del_out.stderr.strip()}\n"
        )

    return {"otid": args.otid, "dropbox_filename": filename, "content": content}


def cmd_dropbox_status(ws, args):
    js = """
    (async () => {
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const resp = await fetch('/forward/api/v1/user', {
            credentials: 'include',
            headers: {'x-csrftoken': csrf}
        });
        const data = await resp.json();
        const u = data.user || {};
        const synced = u.synced_accounts || [];
        const dbAccount = synced.find(a => a.source === 'DropBox');
        return JSON.stringify({
            connected: !!dbAccount,
            dropbox_account_id: dbAccount?.dropbox_account_id || null,
            auto_export: dbAccount?.auto_export || false,
            auto_import: dbAccount?.auto_import || false,
            export_format: dbAccount?.export_format || null,
        });
    })()
    """
    return eval_js(ws, js)

def main():
    parser = argparse.ArgumentParser(description="Otter.ai CDP helper")
    sub = parser.add_subparsers(dest="command")

    p_list = sub.add_parser("list")
    p_list.add_argument("--page-size", type=int, default=50)
    p_list.add_argument("--last-load-ts", type=int, default=None)

    p_rename = sub.add_parser("rename")
    p_rename.add_argument("otid")
    p_rename.add_argument("new_title")

    p_export = sub.add_parser("export-dropbox")
    p_export.add_argument("otid")
    p_export.add_argument("--format", choices=["txt", "pdf", "docx", "srt"], default="txt")

    p_fetch = sub.add_parser("fetch-via-dropbox")
    p_fetch.add_argument("otid")
    p_fetch.add_argument("--timeout", type=int, default=60,
        help="Initial poll deadline in seconds (default 60)")
    p_fetch.add_argument("--extended-timeout", type=int, default=120,
        help="Total poll deadline in seconds, used after --timeout expires (default 120)")

    sub.add_parser("dropbox-status")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    profile = detect_profile()
    if not profile:
        print(json.dumps({"error": "Browser profile directory not found"}))
        sys.exit(1)

    proc, port = launch_browser(profile)
    if not proc:
        print(json.dumps({"error": "Failed to launch headless browser"}))
        sys.exit(1)

    try:
        ws = connect_cdp(port)
        navigate_and_wait(ws, "https://otter.ai/my-notes")

        if not check_logged_in(ws):
            print(json.dumps({"error": "Not logged in to Otter.ai. Log in via Chrome or a Chrome-compatible browser first."}))
            sys.exit(1)

        commands = {
            "list": cmd_list,
            "rename": cmd_rename,
            "export-dropbox": cmd_export_dropbox,
            "fetch-via-dropbox": cmd_fetch_via_dropbox,
            "dropbox-status": cmd_dropbox_status,
        }
        result = commands[args.command](ws, args)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        ws.close()
    finally:
        proc.terminate()
        proc.wait(timeout=5)

if __name__ == "__main__":
    main()
