#!/usr/bin/env python3
"""
fetch-followers: list a profile's followers or following set.

Given a public handle, paginates the authenticated friendships API and
emits one row per user. Works for the followers list and the following
list (same endpoint shape, different path segment).

Endpoints (called via fetch() from inside an authenticated CDP session):
  /api/v1/friendships/<user_id>/followers/?count=N&max_id=...
  /api/v1/friendships/<user_id>/following/?count=N&max_id=...

Output: JSON to stdout by default, or CSV when --csv PATH is given.

Per-entry fields:
  user_id, username, full_name, is_verified, is_private,
  has_default_avatar, profile_pic_url

Pagination: cursor-based (`next_max_id`). Pacing: ~2.5s/page, which is
roughly the upper bound of what the endpoint tolerates over a sustained
run. The script stops on the first of: --limit reached, `big_list` false
with no next cursor, or an HTTP error.

Visibility rules: a private profile returns 0 entries unless the logged-in
viewer follows it. A public profile may still return fewer entries than
the header count if Instagram throttles the session mid-run.

Usage:
    not-google-chrome --cdp -- python3 fetch-followers.py followers <handle> [--limit N] [--csv PATH]
    not-google-chrome --cdp -- python3 fetch-followers.py following <handle> [--limit N] [--csv PATH]
"""

import argparse
import csv
import importlib.util
import json
import os
import sys
import time


_HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location(
    "fetch_recent_posts",
    os.path.join(_HERE, "fetch-recent-posts.py"),
)
_frp = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_frp)


_DEFAULT_AVATAR_HINTS = (
    "44884218_345707102882519_2446069589734326272_n",  # legacy ghost
    "instagram_default_avatar",
    "anonymous_user",
)


def _has_default_avatar(profile_pic_url, has_anon_flag):
    if has_anon_flag:
        return True
    if not profile_pic_url:
        return True
    return any(h in profile_pic_url for h in _DEFAULT_AVATAR_HINTS)


def _parse_user_row(u):
    profile_pic = u.get("profile_pic_url", "") or ""
    has_anon = bool(u.get("has_anonymous_profile_picture", False))
    return {
        "user_id": str(u.get("pk") or u.get("id") or ""),
        "username": u.get("username", "") or "",
        "full_name": u.get("full_name", "") or "",
        "is_verified": bool(u.get("is_verified", False)),
        "is_private": bool(u.get("is_private", False)),
        "has_default_avatar": _has_default_avatar(profile_pic, has_anon),
        "profile_pic_url": profile_pic,
    }


def fetch_friendships_page(ws, user_id, kind, max_id=None, count=25):
    """Fetch one page of /api/v1/friendships/<user_id>/<kind>/.

    `kind` must be "followers" or "following". Returns the raw JSON dict
    (with `users`, `big_list`, `next_max_id`) or a dict with `error` on
    HTTP failure.
    """
    if kind not in ("followers", "following"):
        return {"error": f"invalid kind: {kind!r}"}
    parts = [f"count={count}"]
    if max_id:
        parts.append(f"max_id={max_id}")
    qs = "&".join(parts)
    js = f"""
    (async () => {{
        const csrf = document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
        const resp = await fetch('/api/v1/friendships/{user_id}/{kind}/?{qs}', {{
            credentials: 'include',
            headers: {{
                'X-IG-App-ID': '936619743392459',
                'X-CSRFToken': csrf,
                'X-Requested-With': 'XMLHttpRequest',
            }}
        }});
        if (!resp.ok) return JSON.stringify({{error: 'HTTP ' + resp.status, status: resp.status}});
        return JSON.stringify(await resp.json());
    }})()
    """
    return _frp.eval_js(ws, js)


def fetch_friendships_paginated(ws, user_id, kind, limit, pause_between=2.5):
    """Paginate the friendships endpoint until `limit` users collected or
    the API reports no more pages.

    Returns (rows, stop_reason) where stop_reason is one of:
    "limit", "exhausted", "error:<detail>".
    """
    rows = []
    max_id = None
    page_num = 0
    while len(rows) < limit:
        page_num += 1
        page = fetch_friendships_page(ws, user_id, kind, max_id=max_id, count=25)
        if isinstance(page, dict) and page.get("error"):
            sys.stderr.write(f"Page {page_num} fetch error: {page['error']}\n")
            return rows, f"error:{page['error']}"
        users = page.get("users", []) if isinstance(page, dict) else []
        if not users:
            sys.stderr.write(f"Page {page_num} returned no users; stopping.\n")
            return rows, "exhausted"
        for u in users:
            rows.append(_parse_user_row(u))
            if len(rows) >= limit:
                break
        sys.stderr.write(
            f"Page {page_num}: {len(users)} users (cumulative {len(rows)})\n"
        )
        if len(rows) >= limit:
            return rows, "limit"
        next_max = page.get("next_max_id")
        # `big_list` is the documented "there is more" flag, but it is sometimes
        # absent on small lists; trust next_max_id as the cursor of truth.
        if not next_max:
            return rows, "exhausted"
        max_id = next_max
        time.sleep(pause_between)
    return rows, "limit"


def _write_csv(path, rows):
    fieldnames = [
        "user_id", "username", "full_name",
        "is_verified", "is_private",
        "has_default_avatar", "profile_pic_url",
    ]
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)


def cmd_friendships(ws, handle, kind, limit, csv_path):
    user_id_or_err = _frp.resolve_user_id(ws, handle)
    if isinstance(user_id_or_err, dict) and user_id_or_err.get("error"):
        return user_id_or_err
    user_id = user_id_or_err

    time.sleep(2)
    rows, stop_reason = fetch_friendships_paginated(ws, user_id, kind, limit)

    result = {
        "handle": handle,
        "user_id": user_id,
        "kind": kind,
        "count_returned": len(rows),
        "limit_requested": limit,
        "stop_reason": stop_reason,
    }
    if csv_path:
        _write_csv(csv_path, rows)
        result["csv_path"] = os.path.abspath(csv_path)
    else:
        result["users"] = rows
    return result


def main():
    parser = argparse.ArgumentParser(description="Instagram followers/following list extractor")
    sub = parser.add_subparsers(dest="command")

    for name, helptext in (
        ("followers", "List a profile's followers"),
        ("following", "List who a profile follows"),
    ):
        p = sub.add_parser(name, help=helptext)
        p.add_argument("handle")
        p.add_argument("--limit", type=int, default=500,
            help="Cap on returned users (default 500; raise carefully — endpoint throttles)")
        p.add_argument("--csv", dest="csv_path", default=None,
            help="Write rows to this CSV path instead of printing user objects in JSON")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    ws_url = os.environ.get("CDP_WS_URL")
    if not ws_url:
        sys.stderr.write("ERROR: CDP_WS_URL not set; run via: "
                         "not-google-chrome --cdp -- python3 fetch-followers.py ...\n")
        sys.exit(1)

    ws = _frp._ws_connect(ws_url, timeout=20)
    _frp.send_cdp(ws, "Page.enable")
    _frp.navigate_and_wait(ws, "https://www.instagram.com/", wait_seconds=3)

    if not _frp.check_logged_in(ws):
        print(json.dumps({
            "error": "Not logged in to Instagram. Log in via a Chrome-compatible browser first."
        }))
        sys.exit(1)

    time.sleep(3)
    result = cmd_friendships(ws, args.handle, args.command, args.limit, args.csv_path)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    _frp._ws_close(ws)


if __name__ == "__main__":
    main()
