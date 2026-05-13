#!/usr/bin/env python3
"""
CDP helper for Otter.ai API calls.

Launches a headless Chrome-compatible browser with the user's logged-in profile,
navigates to otter.ai to establish session context, then executes JavaScript
fetch() calls against the Otter.ai internal API. Returns JSON results to stdout.

Usage:
    python3 otter-cdp.py list [--page-size N] [--last-load-ts TS]
    python3 otter-cdp.py rename <otid> <new_title>
    python3 otter-cdp.py trash <otid>
    python3 otter-cdp.py export-dropbox <otid> [--format txt|pdf|docx|srt]
    python3 otter-cdp.py fetch-via-dropbox <otid> [--timeout N] [--extended-timeout N]
    python3 otter-cdp.py dropbox-status

Note: `trash` moves the recording to Otter Trash (recoverable via the web UI for
~30 days). There is deliberately no `delete` subcommand: Otter's delete_speech /
permanently_delete_speech endpoints are unrecoverable and easy to misname. If
you really need permanent deletion, do it from the Otter web UI.
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

BROWSER_WRAPPER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "bin", "not-google-chrome")

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
    deadline = time.time() + 25
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
        # Otter's API requires `modified_after` on subsequent pages; the cursor
        # is `last_load_ts` from the previous response. Setting modified_after=1
        # (epoch start) means "no modification-time filter" so the cursor alone
        # controls pagination.
        params += f"&modified_after=1&last_load_ts={args.last_load_ts}"
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
    warning = None
    if not title.endswith(".txt"):
        warning = (
            f"Title {title!r} does not end in '.txt'. Project convention is "
            "YYYY-MM-DD-kebab-case-description.txt; transcripts are picked up "
            "downstream by their .txt suffix, so a non-.txt title means the "
            "next rename pass will see this recording as still-unnamed and "
            "rename it again (not idempotent)."
        )
        sys.stderr.write(f"Warning: {warning}\n")
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
    result = eval_js(ws, js)
    if warning:
        if isinstance(result, dict):
            result["warning"] = warning
        else:
            result = {"result": result, "warning": warning}
    return result

# =============================================================================
# DANGER: do not call /forward/api/v1/delete_speech (or permanently_delete_speech,
# bulk_delete_speech). They are HARD DELETES that bypass Otter Trash and are
# unrecoverable, even though their names sound like "move to recycle bin" from
# UI vocabulary. The UI's "Move to Trash" button calls move_to_trash_bin, which
# IS recoverable from Trash for ~30 days. This skill only exposes the
# move_to_trash_bin variant. A 2026-05-13 incident lost a real recording to
# delete_speech because the name was assumed to mean soft-delete; the lesson is
# that destructive endpoints in Otter's API are differentiated only by the
# token "permanently" or by belonging to a *_trash_bin family. When in doubt,
# pick the *_trash_bin one.
#
# Endpoint family observed in main.<hash>.js bundle (Speech*-prefixed registry):
#   SpeechMoveToTrashBin        -> move_to_trash_bin           [SAFE: recoverable]
#   SpeechBulkMoveToTrashBin    -> bulk_to_trash_bin           [SAFE: recoverable]
#   SpeechMoveOutTrashBin       -> move_back_from_trash_bin    [SAFE: restore]
#   SpeechBulkMoveOutTrashBin   -> bulk_back_from_trash_bin    [SAFE: restore]
#   SpeechListTrashBin          -> get_deleted_speeches        [SAFE: read]
#   SpeechClearTrashBin         -> clear_trash_bin             [DANGER: empties trash]
#   SpeechPermanentlyDelete     -> permanently_delete_speech   [DANGER: hard]
#   SpeechBulkPermanentlyDelete -> bulk_delete_speech          [DANGER: hard]
#   SpeechDelete                -> delete_speech               [DANGER: hard, named misleadingly]
# =============================================================================

def cmd_trash(ws, args):
    """Move a recording to Otter Trash (recoverable from the web UI for ~30 days).

    Calls POST /forward/api/v1/move_to_trash_bin with `otid=<otid>` as a form body.
    Returns the JSON response from Otter on success, {"error": ...} otherwise.

    Do NOT switch this to /forward/api/v1/delete_speech: that endpoint is a hard
    delete that bypasses Trash. See the header comment above this function.
    """
    otid = args.otid
    js = f"""
    (async () => {{
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const body = 'otid=' + encodeURIComponent({json.dumps(otid)});
        const resp = await fetch('/forward/api/v1/move_to_trash_bin', {{
            method: 'POST',
            credentials: 'include',
            headers: {{
                'x-csrftoken': csrf,
                'content-type': 'application/x-www-form-urlencoded',
            }},
            body,
        }});
        const text = await resp.text();
        return JSON.stringify({{status_code: resp.status, body: text}});
    }})()
    """
    raw = eval_js(ws, js)
    if isinstance(raw, dict) and raw.get("error"):
        return raw
    status_code = raw.get("status_code") if isinstance(raw, dict) else None
    body = raw.get("body", "") if isinstance(raw, dict) else ""
    if status_code != 200:
        return {"error": f"move_to_trash_bin returned HTTP {status_code}", "body": body[:300]}
    try:
        return json.loads(body)
    except json.JSONDecodeError:
        return {"raw": body}


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

    p_trash = sub.add_parser("trash", help="Move recording to Otter Trash (recoverable for ~30 days). No hard-delete subcommand is exposed; see file header.")
    p_trash.add_argument("otid")

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

    proc, port = launch_browser()
    if not proc:
        print(json.dumps({"error": "Failed to launch headless browser"}))
        sys.exit(1)

    try:
        ws = connect_cdp(port)
        navigate_and_wait(ws, "https://otter.ai/my-notes")

        if not check_logged_in(ws):
            print(json.dumps({"error": "Not logged in to Otter.ai. Log in via a Chrome-compatible browser first."}))
            sys.exit(1)

        commands = {
            "list": cmd_list,
            "rename": cmd_rename,
            "trash": cmd_trash,
            "export-dropbox": cmd_export_dropbox,
            "fetch-via-dropbox": cmd_fetch_via_dropbox,
            "dropbox-status": cmd_dropbox_status,
        }
        result = commands[args.command](ws, args)
        print(json.dumps(result, indent=2, ensure_ascii=False))
        _ws_close(ws)
    finally:
        proc.terminate()
        proc.wait(timeout=5)

if __name__ == "__main__":
    main()
