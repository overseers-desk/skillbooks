#!/usr/bin/env python3
"""Fetch comments from a Facebook reel via CDP.

The reel viewer (https://www.facebook.com/reel/{id}) is an authenticated SPA
that defers comment loading until the user clicks the Comment button. A plain
--dump-dom captures the player chrome but no comment text. This script drives
the viewer over CDP: clicks Comment, scrolls the comment list, and clicks
"View more comments" / "View N replies" until the rendered count stops growing.

Output: the final document.documentElement.outerHTML on stdout, suitable for
piping into parse-reel-comments.py.

The wrapper (not-google-chrome --cdp) owns the browser lifecycle and exports
CDP_WS_URL; this script is a pure CDP client and exits if run without it.

Usage:
    not-google-chrome --cdp -- python3 reel-comments-cdp.py URL [--out PATH] [--max-rounds N] [--debug]
"""

import argparse
import base64
import json
import os
import re
import socket
import struct
import sys
import time


# WebSocket over stdlib socket. Local CDP, no TLS, no extensions.

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


# JS expressions kept as constants for readability. Each evaluates inside
# the page and returns a plain value through Runtime.evaluate(returnByValue).

# Count how many distinct top-level comments are currently in the DOM.
# Comments live inside a structure with role="article" and an aria-label of
# the form "Comment by {Name}". Reply articles use "Reply by {Name}".
JS_COMMENT_COUNT = r"""
(function(){
  var arts = document.querySelectorAll('div[role="article"][aria-label^="Comment by "]');
  return arts.length;
})()
"""

JS_REPLY_COUNT = r"""
(function(){
  var arts = document.querySelectorAll('div[role="article"][aria-label^="Reply by "]');
  return arts.length;
})()
"""

# Click the Comment button (action button in the reel side rail).
JS_CLICK_COMMENT_BUTTON = r"""
(function(){
  var btns = document.querySelectorAll('[aria-label="Comment"]');
  for (var i = 0; i < btns.length; i++) {
    var b = btns[i];
    var r = b.getBoundingClientRect();
    if (r.width > 0 && r.height > 0) {
      b.click();
      return true;
    }
  }
  return false;
})()
"""

# Find the comment list's scroll container and scroll it to the bottom.
# Strategy: pick the closest scrollable ancestor of the first comment article.
JS_SCROLL_COMMENTS = r"""
(function(){
  var art = document.querySelector('div[role="article"][aria-label^="Comment by "]');
  if (!art) return false;
  var el = art.parentElement;
  while (el) {
    var s = getComputedStyle(el);
    if ((s.overflowY === 'auto' || s.overflowY === 'scroll') &&
        el.scrollHeight > el.clientHeight + 5) {
      el.scrollTop = el.scrollHeight;
      return true;
    }
    el = el.parentElement;
  }
  // Fallback: scroll the document.
  window.scrollTo(0, document.body.scrollHeight);
  return false;
})()
"""

# Click every visible expander button: top-level pagination, reply threads,
# and "See more" body expanders. Returns the number clicked this pass.
#
# Patterns observed in the reel comment panel (May 2026):
#   - "View more comments" / "View N more comments" — top-level pagination
#   - "View previous comments" — older comments
#   - "N reply" / "N replies" — expand a reply thread (e.g. "3 replies")
#   - "View N more replies" — paginate within an already-expanded thread
#   - "See more" — expand a truncated comment body
#
# Excludes "Reply" (the per-comment action button) because clicking it opens
# a compose box, which would pollute the DOM and could send a comment.
JS_CLICK_VIEW_MORE = r"""
(function(){
  var clicked = 0;
  // Reply expanders are bare <span>s whose direct text is "N replies".
  // Top-level "View more comments" can be a span OR a role=button.
  // Match by text first, then click both the leaf and its nearest clickable
  // ancestor so React listeners at either level fire.
  var seen = new Set();
  var spans = document.querySelectorAll('span, div[role="button"], a[role="button"]');
  for (var i = 0; i < spans.length; i++) {
    var n = spans[i];
    var t = (n.textContent || '').trim().toLowerCase();
    if (!t || t.length > 80) continue;
    var match = (
      t === 'view more comments' ||
      t === 'view previous comments' ||
      /^view\s+\d[\d,]*\s+more\s+(comment|reply|replie)/.test(t) ||
      /^view\s+\d[\d,]*\s+(reply|replie)/.test(t) ||
      /^\d[\d,]*\s+(reply|replies)$/.test(t) ||
      t === 'view more replies' ||
      t === 'view all replies' ||
      t === 'see more'
    );
    if (!match) continue;
    var r = n.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) continue;
    // Avoid double-click on the same logical button (span + its container)
    var key = Math.round(r.top) + ':' + Math.round(r.left) + ':' + t;
    if (seen.has(key)) continue;
    seen.add(key);
    try { n.click(); } catch(e) {}
    var clickable = n.closest('[role="button"], [tabindex="0"], button, a');
    if (clickable && clickable !== n) {
      try { clickable.click(); } catch(e) {}
    }
    clicked++;
  }
  return clicked;
})()
"""

# Switch comment sort from "Most relevant" to an unfiltered view so we get
# every comment, not just the algorithm's pick. Returns the option name that
# was clicked, or null if the menu/option could not be found. Idempotent
# enough to call once at startup.
JS_SWITCH_SORT_ALL = r"""
(function(){
  // Find a role=button whose visible label starts with "Most relevant".
  // The label may include a chevron or sibling text, so don't require an
  // exact match — match the leading visible text only.
  var btns = document.querySelectorAll('div[role="button"], span[role="button"], button');
  for (var i = 0; i < btns.length; i++) {
    var b = btns[i];
    var t = (b.textContent || '').trim();
    if (!t || t.length > 60) continue;
    if (!t.toLowerCase().startsWith('most relevant')) continue;
    var r = b.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) continue;
    b.click();
    return 'opened';
  }
  return null;
})()
"""

JS_PICK_SORT_OPTION = r"""
(function(){
  // After the menu opens, find an option whose visible text starts with
  // a preferred sort name. Facebook's menu items can be div[role=button]
  // inside the menu surface; broaden the selector to catch them.
  var preferred = ['all comments', 'newest', 'newest first'];
  var nodes = document.querySelectorAll(
    '[role="menuitem"], [role="menuitemradio"], [role="menuitemcheckbox"], ' +
    'div[role="button"], span[role="button"], button'
  );
  for (var p = 0; p < preferred.length; p++) {
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i];
      var t = (n.textContent || '').trim().toLowerCase();
      if (!t || t.length > 60) continue;
      if (!t.startsWith(preferred[p])) continue;
      var r = n.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) continue;
      n.click();
      return preferred[p];
    }
  }
  return null;
})()
"""

# Total comment count exposed by the page. The reel page embeds multiple
# feedback objects; we take the maximum (the cross-universe aggregate).
JS_TOTAL_COMMENT_COUNT = r"""
(function(){
  var html = document.documentElement.outerHTML;
  var matches = html.match(/"total_comment_count":\s*(\d+)/g) || [];
  var max = 0;
  for (var i = 0; i < matches.length; i++) {
    var n = parseInt(matches[i].split(':')[1], 10);
    if (n > max) max = n;
  }
  return max || null;
})()
"""

# Facebook virtualizes the comment list: off-screen articles get unmounted
# as we scroll. To beat this, harvest every visible comment article into a
# JS-side dict, keyed by comment_id. We also track the parent comment's id
# (for replies) so the dump can reconstruct thread order, and overwrite when
# we see a longer version of the same article (e.g. after "See more" expands
# the body). The dict persists across DOM churn.
JS_HARVEST_COMMENTS = r"""
(function(){
  if (!window.__harvested) window.__harvested = {};
  if (!window.__order) window.__order = [];
  var arts = document.querySelectorAll(
    'div[role="article"][aria-label^="Comment by "], ' +
    'div[role="article"][aria-label^="Reply by "]'
  );
  var added = 0, expanded = 0;
  for (var i = 0; i < arts.length; i++) {
    var a = arts[i];
    var link = a.querySelector('a[href*="comment_id="]');
    if (!link) continue;
    var m = link.getAttribute('href').match(/comment_id=([^&"]+)/);
    if (!m) continue;
    var cid = m[1];
    var newHtml = a.outerHTML;
    var existing = window.__harvested[cid];
    if (existing) {
      if (newHtml.length > existing.html.length) {
        // Body likely expanded by a "See more" click — keep the longer.
        existing.html = newHtml;
        expanded++;
      }
      continue;
    }
    // Find the enclosing Comment article for replies; null for top-level.
    var parent_cid = null;
    var p = a.parentNode ? a.parentNode.closest(
      'div[role="article"][aria-label^="Comment by "]'
    ) : null;
    if (p && p !== a) {
      var pl = p.querySelector('a[href*="comment_id="]');
      if (pl) {
        var pm = pl.getAttribute('href').match(/comment_id=([^&"]+)/);
        if (pm) parent_cid = pm[1];
      }
    }
    var isReply = a.getAttribute('aria-label').indexOf('Reply by ') === 0;
    window.__harvested[cid] = {
      html: newHtml, parent_cid: parent_cid, is_reply: isReply
    };
    window.__order.push(cid);
    added++;
  }
  return {
    total: Object.keys(window.__harvested).length,
    added: added, expanded: expanded
  };
})()
"""

# Emit a synthetic HTML document with one block per top-level comment.
# A Comment article's outerHTML already nests its Reply articles inside
# (Facebook keeps replies as descendants of the parent), so we only emit
# top-level entries. Orphan replies (whose parent was never harvested) are
# appended at the end.
JS_DUMP_HARVEST = r"""
(function(){
  if (!window.__harvested) return null;
  var parts = ['<!DOCTYPE html><html><head><title>__TITLE__</title></head><body>'];
  var order = window.__order || Object.keys(window.__harvested);
  for (var i = 0; i < order.length; i++) {
    var cid = order[i];
    var v = window.__harvested[cid];
    if (!v) continue;
    if (v.is_reply) continue;
    parts.push(v.html);
  }
  // Orphan replies: ones whose parent_cid is missing from the harvest.
  for (var j = 0; j < order.length; j++) {
    var cid2 = order[j];
    var v2 = window.__harvested[cid2];
    if (!v2 || !v2.is_reply) continue;
    if (v2.parent_cid && window.__harvested[v2.parent_cid]) continue;
    parts.push(v2.html);
  }
  parts.push('</body></html>');
  return parts.join('\n');
})()
"""

# Click every visible "See more" expander with synthetic mouse events.
# The plain .click() on Facebook's React-managed elements is unreliable;
# dispatching the full mousedown/mouseup/click trio matches what a real
# pointer would deliver and fires React's onClick.
JS_CLICK_SEE_MORE = r"""
(function(){
  var divs = document.querySelectorAll('div[role="button"][tabindex="0"], span[role="button"]');
  var clicked = 0;
  for (var i = 0; i < divs.length; i++) {
    var d = divs[i];
    if (d.textContent.trim() !== 'See more') continue;
    var r = d.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) continue;
    try {
      d.dispatchEvent(new MouseEvent('mousedown', {bubbles: true, cancelable: true}));
      d.dispatchEvent(new MouseEvent('mouseup', {bubbles: true, cancelable: true}));
      d.dispatchEvent(new MouseEvent('click', {bubbles: true, cancelable: true}));
    } catch(e) {}
    clicked++;
  }
  return clicked;
})()
"""


def _extract_comment_bodies(response_text):
    """Pull every {legacy_fbid -> body.text} pair from a GraphQL response.

    Facebook's comment edges have this shape:
      "legacy_fbid":"NUMERIC","depth":N,"body":{"text":"...","ranges":[...]}
    We anchor on legacy_fbid and scan forward for the nearest body.text.
    """
    out = {}
    # Use re.finditer so we can take a window after each legacy_fbid.
    for m in re.finditer(r'"legacy_fbid":"(\d+)"', response_text):
        cid = m.group(1)
        if cid in out:
            continue
        window = response_text[m.end():m.end() + 4000]
        bm = re.search(r'"body":\{"text":"((?:[^"\\]|\\.)*)"', window)
        if bm:
            text = bm.group(1)
            # JSON-style unescape: handle \n \" \\ \uXXXX
            try:
                text = json.loads('"' + text + '"')
            except Exception:
                pass
            out[cid] = text
    return out


def fetch(url, max_rounds=80, debug=False, bodies_out=None):
    ws_url = os.environ.get("CDP_WS_URL")
    if not ws_url:
        sys.exit("ERROR: CDP_WS_URL not set; run via: not-google-chrome --cdp "
                 "-- python3 reel-comments-cdp.py <reel-url> [--out FILE]")

    sock = _ws_connect(ws_url, timeout=20)
    try:
        _id = 0
        events = []  # buffer of CDP events received while waiting for cmd responses

        def cmd(method, params=None):
            nonlocal _id
            _id += 1
            cid = _id
            _ws_send(sock, json.dumps({"id": cid, "method": method,
                                       "params": params or {}}))
            while True:
                msg = json.loads(_ws_recv(sock))
                if msg.get("id") != cid:
                    if "method" in msg:
                        events.append(msg)
                    continue
                if "error" in msg:
                    raise RuntimeError(f"{method}: {msg['error']}")
                return msg.get("result", {})

        def js(expr, default=None):
            try:
                r = cmd("Runtime.evaluate", {
                    "expression": expr,
                    "awaitPromise": False,
                    "returnByValue": True,
                })
                if "exceptionDetails" in r:
                    return default
                return r.get("result", {}).get("value")
            except Exception:
                return default

        def log(msg):
            if debug:
                print(f"[reel] {msg}", file=sys.stderr)

        cmd("Network.enable")
        cmd("Network.setCacheDisabled", {"cacheDisabled": False})
        cmd("Page.enable")

        log(f"navigate {url}")
        cmd("Page.navigate", {"url": url})
        time.sleep(4)

        # Wait for page chrome to render
        t0 = time.time()
        while time.time() - t0 < 20:
            if js('!!document.querySelector(\'[aria-label="Comment"]\')'):
                break
            time.sleep(0.5)

        # No-session detection. Logged out, Facebook embeds USER_ID/ACCOUNT_ID
        # of "0" in the page config and shows a login wall; the title may still
        # read like a real page (e.g. on a public profile). Check both the
        # title and the config marker so a no-session fetch fails loudly here
        # instead of returning an empty comment harvest.
        title = js("document.title", "") or ""
        no_session = js(
            r'/"(?:USER_ID|ACCOUNT_ID)":"0"/.test(document.documentElement.outerHTML)'
        )
        log(f"title={title!r} no_session={no_session}")
        if no_session or any(
            t in title.lower() for t in ["log in", "log into", "iniciar sesi"]
        ):
            sys.exit("ERROR: Facebook: not logged in - no session in this "
                     "profile. Log in via the GUI Chromium, then close it and "
                     "retry.")

        total = js(JS_TOTAL_COMMENT_COUNT)
        log(f"total_comment_count={total}")

        # Click the Comment button to open the comment panel
        clicked = js(JS_CLICK_COMMENT_BUTTON)
        log(f"clicked Comment button: {clicked}")
        time.sleep(3)

        # Wait for the panel to actually render some content before
        # trying to switch sort. The "Most relevant" label only exists
        # after the comment header has loaded.
        t1 = time.time()
        while time.time() - t1 < 15:
            if (js(JS_COMMENT_COUNT) or 0) > 0:
                break
            time.sleep(0.5)

        # Switch sort from "Most relevant" (which hides duplicates and
        # low-signal comments) to "All comments" / "Newest" so we see
        # every top-level comment.
        if js(JS_SWITCH_SORT_ALL):
            time.sleep(1.5)
            chosen = js(JS_PICK_SORT_OPTION)
            log(f"sort switched to: {chosen}")
            time.sleep(3)
        else:
            log("sort trigger not found; staying on default")

        # Loop: scroll + click "view more" until the harvest stops growing.
        # The harvest dict persists across DOM virtualization, so the
        # stopping condition is based on cumulative harvested IDs, not
        # what's currently mounted.
        js(JS_HARVEST_COMMENTS)  # initialise window.__harvested
        last_total = 0
        stable_rounds = 0
        for round_num in range(max_rounds):
            js(JS_SCROLL_COMMENTS)
            time.sleep(0.6)
            clicked_more = js(JS_CLICK_VIEW_MORE) or 0
            if clicked_more:
                time.sleep(1.2)
            # Harvest after scroll + expand so we catch whatever's now
            # visible (including freshly-loaded items).
            stats = js(JS_HARVEST_COMMENTS) or {"total": 0, "added": 0}
            mounted = (js(JS_COMMENT_COUNT) or 0) + (js(JS_REPLY_COUNT) or 0)
            log(f"round {round_num}: harvested={stats['total']} "
                f"(+{stats['added']})  mounted={mounted}  "
                f"view-more-clicked={clicked_more}")

            if total and stats["total"] >= total:
                log("reached total_comment_count; stopping")
                break
            if stats["added"] == 0 and clicked_more == 0:
                stable_rounds += 1
                if stable_rounds >= 8:
                    log(f"no growth for {stable_rounds} rounds; stopping")
                    break
            else:
                stable_rounds = 0
            last_total = stats["total"]

        # Final pass: scroll back to top, then scroll down again while
        # aggressively clicking "See more" to capture full body text for
        # any comments harvested with truncated bodies on first pass.
        log("final pass: scrolling top->bottom expanding See more")
        for direction in (0, 1):  # 0 = scroll up, 1 = scroll down
            if direction == 0:
                js(r"""(function(){
                  var art = document.querySelector('div[role="article"]');
                  if (!art) return; var el = art.parentElement;
                  while (el) { var s = getComputedStyle(el);
                    if ((s.overflowY=='auto'||s.overflowY=='scroll') &&
                        el.scrollHeight > el.clientHeight+5) {
                      el.scrollTop = 0; return;
                    }
                    el = el.parentElement;
                  } window.scrollTo(0,0);
                })()""")
                time.sleep(2.0)
            # Walk through the panel in small steps so "See more" buttons
            # come into view (and into the DOM if virtualized) and get
            # clicked one section at a time. We hit each section with
            # JS_CLICK_SEE_MORE (synthetic events) and JS_CLICK_VIEW_MORE
            # (for any newly-expanded reply threads).
            for step in range(50):
                sm = js(JS_CLICK_SEE_MORE) or 0
                if sm:
                    time.sleep(1.4)
                vm = js(JS_CLICK_VIEW_MORE) or 0
                if vm:
                    time.sleep(1.0)
                js(JS_HARVEST_COMMENTS)
                moved = js(r"""(function(){
                  var art = document.querySelector('div[role="article"]');
                  if (!art) return false; var el = art.parentElement;
                  while (el) { var s = getComputedStyle(el);
                    if ((s.overflowY=='auto'||s.overflowY=='scroll') &&
                        el.scrollHeight > el.clientHeight+5) {
                      var before = el.scrollTop;
                      el.scrollTop = before + el.clientHeight * 0.6;
                      return el.scrollTop !== before;
                    }
                    el = el.parentElement;
                  } return false;
                })()""")
                if not moved and sm == 0 and vm == 0:
                    break

        title = js("document.title", "") or "Facebook reel"
        html = js(JS_DUMP_HARVEST.replace("__TITLE__", title.replace("'", "")), "") or ""

        # Also splice in the head metadata from the live page (og:url,
        # feedback counts) so the parser can read them. We keep the
        # harvest body since that's the authoritative comment list.
        head_html = js(
            "(function(){"
            "var head = document.querySelector('head');"
            "return head ? head.outerHTML : '';"
            "})()", ""
        ) or ""
        if head_html and "<head>" in html:
            html = html.replace(
                "<head><title>" + title.replace("'", "") + "</title></head>",
                head_html, 1
            )

        # Drain CDP events and harvest canonical comment bodies from
        # every GraphQL response we saw. The DOM may truncate long
        # comments with "See more"; the wire data has the full text.
        if bodies_out is not None:
            cmd("Runtime.evaluate",
                {"expression": "1", "returnByValue": True})  # flush
            gql_rids = []
            for e in events:
                if e.get("method") != "Network.responseReceived":
                    continue
                resp = (e.get("params") or {}).get("response") or {}
                url_ = resp.get("url", "")
                rid = (e.get("params") or {}).get("requestId")
                if rid and "graphql" in url_:
                    gql_rids.append(rid)
            log(f"draining {len(gql_rids)} graphql responses for bodies")
            bodies = {}
            for rid in gql_rids:
                try:
                    body = cmd("Network.getResponseBody",
                               {"requestId": rid})
                    txt = body.get("body", "")
                    if body.get("base64Encoded"):
                        txt = base64.b64decode(txt).decode(
                            "utf-8", "replace"
                        )
                    if '"legacy_fbid"' not in txt:
                        continue
                    bodies.update(_extract_comment_bodies(txt))
                except Exception:
                    continue
            log(f"canonical bodies extracted: {len(bodies)}")
            with open(bodies_out, "w") as f:
                json.dump(bodies, f, ensure_ascii=False)
        return html
    finally:
        _ws_close(sock)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("url", help="Facebook reel URL, e.g. https://www.facebook.com/reel/123")
    p.add_argument("--out", help="Write DOM to this file instead of stdout")
    p.add_argument("--bodies-json",
                   help="Also write a sidecar JSON {legacy_fbid: full_text} "
                        "harvested from GraphQL response bodies. Used by the "
                        "parser to backfill comments truncated by 'See more'.")
    p.add_argument("--max-rounds", type=int, default=80,
                   help="Maximum scroll/expand iterations (default 80)")
    p.add_argument("--debug", action="store_true",
                   help="Verbose progress on stderr")
    args = p.parse_args()

    html = fetch(args.url, max_rounds=args.max_rounds, debug=args.debug,
                 bodies_out=args.bodies_json)
    if args.out:
        with open(args.out, "w") as f:
            f.write(html)
        print(f"wrote {len(html):,} bytes to {args.out}", file=sys.stderr)
    else:
        sys.stdout.write(html)


if __name__ == "__main__":
    main()
