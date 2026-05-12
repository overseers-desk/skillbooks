#!/usr/bin/env python3
"""
collab-expand: walk Instagram handles, surface collab-partner candidates.

For each input handle, scans recent posts (paginated via the feed API,
no per-post page-open required) and accumulates handles found in four
collab-signal fields:

  - tagged_users   (the "tag people" feature on the post)
  - coauthors      (the collab-post co-author feature)
  - sponsors       (branded-content sponsor tags)
  - mentions       (@-mentions in caption text; weaker signal)

Outputs candidate handles NOT already in the input set, ranked by
explicit collab signal first (tagged + coauthor + sponsor) and then
by caption-mention count and number of distinct source handles. Each
candidate row carries the four counts plus the source handles whose
posts surfaced it, so a human or P-phase agent can decide whether the
candidate is in scope.

The "spider" step (recursive expansion) is the orchestrator's call:
take the top N candidates from one run and optionally feed them as the
next run's input. This script does single-level expansion.

Usage:
    python3 collab-expand.py expand handle1,handle2 [--posts-per-handle N]
    python3 collab-expand.py expand --from /path/to/handles.txt
"""

import argparse
import importlib.util
import json
import os
import sys
import time


# Import feed helpers from fetch-recent-posts.py. Hyphen in name prevents
# a normal `import`; importlib lets us load it as a module here.
_HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location(
    "fetch_recent_posts",
    os.path.join(_HERE, "fetch-recent-posts.py"),
)
_frp = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_frp)


SIGNAL_FIELDS = ("tagged_users", "coauthors", "sponsors", "mentions")
SIGNAL_TO_COL = {
    "tagged_users": "tagged",
    "coauthors": "coauthor",
    "sponsors": "sponsor",
    "mentions": "mention",
}


def expand_handles(ws, handles, posts_per_handle, pause_between_handles=2):
    """Walk input handles; return ranked candidate dicts.

    Each candidate dict carries per-signal counts plus a sorted `sources`
    list of input handles whose posts surfaced the candidate.
    """
    input_lower = {h.lower() for h in handles}
    candidates = {}  # candidate_lower -> entry dict

    for handle in handles:
        sys.stderr.write(f"\n=== {handle} ===\n")
        user_id_or_err = _frp.resolve_user_id(ws, handle)
        if isinstance(user_id_or_err, dict) and user_id_or_err.get("error"):
            sys.stderr.write(f"  skipped: {user_id_or_err.get('error')}\n")
            continue
        user_id = user_id_or_err

        time.sleep(2)
        items = _frp.fetch_user_feed_paginated(ws, user_id, posts_per_handle)
        posts = _frp._parse_media_items(items)
        sys.stderr.write(f"  fetched {len(posts)} posts\n")

        for post in posts:
            for field in SIGNAL_FIELDS:
                col = SIGNAL_TO_COL[field]
                for cand in post.get(field, []) or []:
                    cand_lower = cand.lower()
                    if cand_lower in input_lower or cand_lower == handle.lower():
                        continue
                    entry = candidates.setdefault(cand_lower, {
                        "handle": cand_lower,
                        "tagged": 0,
                        "coauthor": 0,
                        "sponsor": 0,
                        "mention": 0,
                        "total": 0,
                        "sources": set(),
                    })
                    entry[col] += 1
                    entry["total"] += 1
                    entry["sources"].add(handle)
        time.sleep(pause_between_handles)

    out = []
    for entry in candidates.values():
        entry["sources"] = sorted(entry["sources"])
        out.append(entry)
    # Rank: explicit-collab signals first, then mentions, then breadth of sources.
    out.sort(key=lambda e: (
        -(e["coauthor"] + e["sponsor"] + e["tagged"]),
        -e["mention"],
        -len(e["sources"]),
        e["handle"],
    ))
    return out


def cmd_expand(ws, handles, posts_per_handle):
    return {
        "input_handles": list(handles),
        "posts_per_handle": posts_per_handle,
        "candidates": expand_handles(ws, handles, posts_per_handle),
    }


def main():
    parser = argparse.ArgumentParser(
        description="Instagram collab-partner expander (CDP)"
    )
    sub = parser.add_subparsers(dest="command")

    p_expand = sub.add_parser(
        "expand", help="Walk handles, surface collab-partner candidates"
    )
    p_expand.add_argument(
        "handles", nargs="?",
        help="Comma-separated input handles (e.g. 'aaa,bbb,ccc')",
    )
    p_expand.add_argument(
        "--from", dest="from_file",
        help="Path to a file with one handle per line (# comments allowed)",
    )
    p_expand.add_argument(
        "--posts-per-handle", type=int, default=24,
        help="Posts to fetch per input handle (default 24 = ~2 pages)",
    )

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    handles = []
    if args.handles:
        handles.extend([h.strip().lstrip("@") for h in args.handles.split(",") if h.strip()])
    if args.from_file:
        with open(args.from_file) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                handles.append(line.lstrip("@"))
    seen = set()
    deduped = []
    for h in handles:
        if h.lower() not in seen:
            seen.add(h.lower())
            deduped.append(h)
    if not deduped:
        print(json.dumps({"error": "No input handles. Pass as positional CSV or --from <file>."}))
        sys.exit(1)
    handles = deduped

    proc, port = _frp.launch_browser()
    if not proc:
        print(json.dumps({"error": "Failed to launch headless browser"}))
        sys.exit(1)

    try:
        ws = _frp.connect_cdp(port)
        _frp.send_cdp(ws, "Page.enable")
        _frp.send_cdp(ws, "Network.enable")
        _frp.navigate_and_wait(ws, "https://www.instagram.com/", wait_seconds=3)

        if not _frp.check_logged_in(ws):
            print(json.dumps({
                "error": "Not logged in to Instagram. Log in via Chromium first."
            }))
            sys.exit(1)

        result = cmd_expand(ws, handles, args.posts_per_handle)
        result["candidate_count"] = len(result["candidates"])
        print(json.dumps(result, indent=2, ensure_ascii=False))
        _frp._ws_close(ws)
    finally:
        proc.terminate()
        proc.wait(timeout=5)


if __name__ == "__main__":
    main()
