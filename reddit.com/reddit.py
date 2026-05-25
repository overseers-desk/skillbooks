#!/usr/bin/env python3
"""Parse a Reddit .json dump produced by the headless-browser wrapper.

The wrapper renders the JSON endpoint's response inside an HTML <pre>; this
strips that wrapper, unescapes entities, and prints clean records. Reddit's
JSON carries original-language text, so this path is immune to the account-locale
auto-translation that corrupts the rendered old.reddit HTML.

Usage:
    reddit.py search <dump.html> [--limit N]   # parse a search.json Listing
    reddit.py thread <dump.html> [--limit N]   # parse a comments/<id>.json reply
"""
import sys, re, json, html, argparse, datetime


def load(path):
    text = open(path, encoding="utf-8", errors="replace").read()
    m = re.search(r"<pre[^>]*>(.*?)</pre>", text, re.S)
    raw = html.unescape(m.group(1)) if m else text
    raw = raw.strip()
    start = raw.find("{")
    bracket = raw.find("[")
    if bracket != -1 and (bracket < start or start == -1):
        start = bracket
    if start > 0:
        raw = raw[start:]
    return json.loads(raw)


def iso(epoch):
    if not epoch:
        return ""
    return datetime.datetime.fromtimestamp(int(epoch), datetime.timezone.utc).strftime("%Y-%m-%d")


def clean(s, n=None):
    if not s:
        return ""
    # Reddit escapes <, >, & inside selftext/body, so unescape a second time
    # (the wrapper's <pre> unescape in load() only undoes the HTML rendering layer).
    s = html.unescape(s)
    s = s.replace("\\~", "~").replace("\\_", "_").replace("\r", "")
    s = re.sub(r"\s+", " ", s).strip()
    return s[:n] + "..." if n and len(s) > n else s


def cmd_search(data, limit):
    children = data["data"]["children"]
    for c in children[:limit]:
        d = c["data"]
        print(f"## {clean(d.get('title',''))}")
        meta = [
            f"r/{d.get('subreddit','')}",
            f"u/{d.get('author','')}",
            f"score {d.get('score','?')}",
            f"{d.get('num_comments','?')} comments",
            iso(d.get("created_utc")),
        ]
        print("   " + " | ".join(str(x) for x in meta))
        print(f"   https://old.reddit.com{d.get('permalink','')}")
        body = clean(d.get("selftext", ""), 200)
        if body:
            print(f"   {body}")
        print()


def walk(children, limit, counter, depth=0):
    for c in children:
        if counter[0] >= limit:
            return
        if c.get("kind") != "t1":
            continue
        d = c["data"]
        body = clean(d.get("body", ""))
        if body:
            counter[0] += 1
            indent = "  " * depth
            print(f"{indent}- u/{d.get('author','')} (score {d.get('score','?')}, {iso(d.get('created_utc'))}): {body}")
        replies = d.get("replies")
        if isinstance(replies, dict):
            walk(replies["data"]["children"], limit, counter, depth + 1)


def cmd_thread(data, limit):
    post = data[0]["data"]["children"][0]["data"]
    print(f"# {clean(post.get('title',''))}")
    print(f"r/{post.get('subreddit','')} | u/{post.get('author','')} | score {post.get('score','?')} | {post.get('num_comments','?')} comments | {iso(post.get('created_utc'))}")
    print(f"https://old.reddit.com{post.get('permalink','')}")
    selftext = clean(post.get("selftext", ""))
    if selftext:
        print(f"\n{selftext}\n")
    print("--- comments ---")
    walk(data[1]["data"]["children"], limit, [0])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("mode", choices=["search", "thread"])
    ap.add_argument("dump")
    ap.add_argument("--limit", type=int, default=25)
    a = ap.parse_args()
    data = load(a.dump)
    if a.mode == "search":
        cmd_search(data, a.limit)
    else:
        cmd_thread(data, a.limit)


if __name__ == "__main__":
    main()
