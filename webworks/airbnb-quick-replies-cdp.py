#!/usr/bin/env python3
"""
Diagnostic script: discover Airbnb quick replies API endpoint.

## Test 1: Network interception - capture XHR/fetch calls while navigating to quick-replies page
## Test 2: JS fetch fallback - try common REST paths with credentials
## Test 3: DOM extraction - scrape quick reply content from rendered page
"""

import json
import os
import subprocess
import sys
import time
import threading
import urllib.request

try:
    import websocket
except ImportError:
    print(json.dumps({"error": "websocket-client not installed. Run: pip install websocket-client"}))
    sys.exit(1)

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")

TARGET_URL = "https://www.airbnb.com/hosting/messages/settings/quick-replies?product=STAYS"


def detect_browser():
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


def detect_user_data_dir():
    if sys.platform == "darwin":
        candidates = [os.path.expanduser("~/Library/Application Support/Chromium")]
    else:
        candidates = [
            os.path.expanduser("~/snap/chromium/common/chromium"),
            os.path.expanduser("~/.config/chromium"),
        ]
    for path in candidates:
        if os.path.isdir(path):
            return path
    return None


def launch_browser(user_data_dir):
    browser = detect_browser()
    if not browser:
        return None, None
    proc = subprocess.Popen(
        [browser, "--headless=new", "--disable-gpu",
         f"--user-agent={UA}",
         f"--user-data-dir={user_data_dir}",
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
    ws = websocket.create_connection(ws_url, timeout=30)
    return ws


def send_cdp(ws, method, params=None, counter=[0]):
    counter[0] += 1
    mid = counter[0]
    msg = {"id": mid, "method": method}
    if params:
        msg["params"] = params
    ws.send(json.dumps(msg))
    deadline = time.time() + 30
    while time.time() < deadline:
        resp = json.loads(ws.recv())
        if resp.get("id") == mid:
            return resp
    return None


def eval_js(ws, expression, timeout=60):
    send_cdp(ws, "Runtime.evaluate", {
        "expression": expression,
        "awaitPromise": False,
        "returnByValue": False,
    })
    # Use a longer-timeout version
    counter = [0]
    counter[0] += 1
    mid = counter[0]
    # Actually use the proper approach with a new counter
    import random
    mid = random.randint(10000, 99999)
    msg = {"id": mid, "method": "Runtime.evaluate", "params": {
        "expression": expression,
        "awaitPromise": True,
        "returnByValue": True,
    }}
    ws.send(json.dumps(msg))
    deadline = time.time() + timeout
    while time.time() < deadline:
        resp = json.loads(ws.recv())
        if resp.get("id") == mid:
            val = resp.get("result", {}).get("result", {}).get("value")
            exc = resp.get("result", {}).get("exceptionDetails")
            if exc:
                return {"error": exc.get("text", "JS exception"), "details": str(exc)}
            if val is None:
                return {"error": "No value returned from JS", "raw_resp": str(resp)}
            try:
                return json.loads(val)
            except (json.JSONDecodeError, TypeError):
                return {"raw": val}
    return {"error": "Timeout waiting for JS evaluation"}


def navigate_and_wait(ws, url, wait_seconds=8):
    """Navigate using Page.navigate and sleep."""
    # Use a unique ID for navigation
    import random
    mid = random.randint(10000, 99999)
    msg = {"id": mid, "method": "Page.navigate", "params": {"url": url}}
    ws.send(json.dumps(msg))
    # Don't wait for response - just sleep
    deadline = time.time() + wait_seconds
    while time.time() < deadline:
        try:
            ws.settimeout(0.1)
            ws.recv()
        except Exception:
            pass
    ws.settimeout(30)


def listen_for_network_events(ws, duration=12):
    """
    Listen for Network events for `duration` seconds.
    Returns list of interesting (responseReceived, requestId, url) tuples.
    """
    interesting = []
    deadline = time.time() + duration
    seen_ids = set()

    while time.time() < deadline:
        try:
            ws.settimeout(0.5)
            raw = ws.recv()
        except Exception:
            continue
        try:
            msg = json.loads(raw)
        except Exception:
            continue

        method = msg.get("method", "")
        params = msg.get("params", {})

        if method == "Network.responseReceived":
            url = params.get("response", {}).get("url", "")
            req_id = params.get("requestId", "")
            rtype = params.get("type", "")
            status = params.get("response", {}).get("status", 0)

            # Filter for API-looking calls
            url_lower = url.lower()
            if any(kw in url_lower for kw in [
                "quick", "graphql", "api/v", "niobe", "api.airbnb",
                "messaging", "message", "template", "reply", "hosting"
            ]):
                if req_id not in seen_ids:
                    seen_ids.add(req_id)
                    interesting.append({
                        "requestId": req_id,
                        "url": url,
                        "type": rtype,
                        "status": status,
                        "headers": params.get("response", {}).get("headers", {}),
                    })
                    print(f"  [NET] {rtype} {status} {url[:120]}", file=sys.stderr)

    ws.settimeout(30)
    return interesting


def get_response_body(ws, request_id):
    import random
    mid = random.randint(10000, 99999)
    msg = {"id": mid, "method": "Network.getResponseBody",
           "params": {"requestId": request_id}}
    ws.send(json.dumps(msg))
    deadline = time.time() + 10
    while time.time() < deadline:
        try:
            ws.settimeout(2)
            raw = ws.recv()
        except Exception:
            break
        try:
            resp = json.loads(raw)
        except Exception:
            continue
        if resp.get("id") == mid:
            ws.settimeout(30)
            result = resp.get("result", {})
            body = result.get("body", "")
            b64 = result.get("base64Encoded", False)
            if b64:
                import base64
                body = base64.b64decode(body).decode("utf-8", errors="replace")
            return body
    ws.settimeout(30)
    return None


def main():
    results = {}

    print("\n## Test 1: Network interception - capture API calls during page load", file=sys.stderr)
    print("- Hypothesis: Airbnb loads quick replies via XHR/fetch, interceptable via CDP Network domain", file=sys.stderr)
    print("- If succeeds: we get the exact endpoint URL and request shape", file=sys.stderr)
    print("- If fails: page may use SSR or non-standard transport", file=sys.stderr)

    user_data_dir = detect_user_data_dir()
    if not user_data_dir:
        print(json.dumps({"error": "Browser user-data-dir not found"}))
        sys.exit(1)

    print(f"  Using user-data-dir: {user_data_dir}", file=sys.stderr)

    proc, port = launch_browser(user_data_dir)
    if not proc:
        print(json.dumps({"error": "Failed to launch headless browser"}))
        sys.exit(1)

    print(f"  Browser launched on port {port}", file=sys.stderr)

    try:
        ws = connect_cdp(port)
        print("  CDP connected", file=sys.stderr)

        # Enable Network domain BEFORE navigating
        send_cdp(ws, "Network.enable", {})
        send_cdp(ws, "Page.enable", {})
        print("  Network domain enabled", file=sys.stderr)

        # Start listening in a thread while we navigate
        captured_events = []
        listen_done = threading.Event()

        def listen_thread():
            evts = listen_for_network_events(ws, duration=15)
            captured_events.extend(evts)
            listen_done.set()

        t = threading.Thread(target=listen_thread, daemon=True)
        t.start()

        # Navigate to the quick replies page
        print(f"  Navigating to {TARGET_URL}", file=sys.stderr)
        import random
        mid = random.randint(10000, 99999)
        msg = {"id": mid, "method": "Page.navigate", "params": {"url": TARGET_URL}}
        ws.send(json.dumps(msg))

        # Wait for listener to finish
        listen_done.wait(timeout=18)
        print(f"  Captured {len(captured_events)} interesting network events", file=sys.stderr)

        results["test1_network_events"] = captured_events

        # Test 1b: get response bodies for captured events
        print("\n## Test 1b: Fetch response bodies for captured API calls", file=sys.stderr)
        bodies = {}
        for evt in captured_events[:10]:  # limit to first 10
            req_id = evt["requestId"]
            url = evt["url"]
            print(f"  Fetching body for: {url[:100]}", file=sys.stderr)
            body = get_response_body(ws, req_id)
            if body:
                # Try to parse as JSON, truncate if huge
                try:
                    parsed = json.loads(body)
                    bodies[url] = {"parsed": parsed, "length": len(body)}
                except Exception:
                    bodies[url] = {"raw": body[:2000], "length": len(body)}
            else:
                bodies[url] = {"error": "no body or already consumed"}

        results["test1b_bodies"] = bodies

        # Test 2: JS fetch - try common Airbnb API paths
        print("\n## Test 2: JS fetch fallback - try known Airbnb API paths", file=sys.stderr)
        print("- Hypothesis: quick replies available at /api/v2/quick_replies or similar REST path", file=sys.stderr)

        # First check page title to verify login
        title_js = "document.title"
        import random
        mid = random.randint(10000, 99999)
        msg = {"id": mid, "method": "Runtime.evaluate", "params": {
            "expression": title_js, "awaitPromise": False, "returnByValue": True
        }}
        ws.send(json.dumps(msg))
        deadline = time.time() + 5
        page_title = "unknown"
        while time.time() < deadline:
            try:
                ws.settimeout(1)
                raw = ws.recv()
                resp = json.loads(raw)
                if resp.get("id") == mid:
                    page_title = resp.get("result", {}).get("result", {}).get("value", "unknown")
                    break
            except Exception:
                continue
        ws.settimeout(30)
        print(f"  Page title: {page_title}", file=sys.stderr)
        results["page_title"] = page_title

        # Try several API paths via fetch
        api_attempts_js = """
        (async () => {
            const results = {};

            // Helper to try a fetch and return status + truncated body
            async function tryFetch(url, opts) {
                try {
                    const r = await fetch(url, {credentials: 'include', ...opts});
                    const txt = await r.text();
                    return {status: r.status, body: txt.substring(0, 3000), headers: Object.fromEntries(r.headers.entries())};
                } catch(e) {
                    return {error: e.toString()};
                }
            }

            // Get CSRF token from cookies
            const csrf = document.cookie.match(/_csrf_token=([^;]+)/)?.[1] ||
                         document.cookie.match(/csrftoken=([^;]+)/)?.[1] || '';
            results.csrf_found = csrf ? 'yes (length=' + csrf.length + ')' : 'no';

            // Also look for airbnb-specific tokens in page
            const metaApiKey = document.querySelector('meta[name="api-key"]')?.content || '';
            results.meta_api_key = metaApiKey ? 'found: ' + metaApiKey.substring(0, 20) : 'not found';

            // Try REST v2 quick_replies
            results.v2_quick_replies = await tryFetch('/api/v2/quick_replies?product=STAYS');
            results.v2_quick_replies_no_param = await tryFetch('/api/v2/quick_replies');
            results.v3_quick_replies = await tryFetch('/api/v3/quick_replies?product=STAYS');

            // Try niobe (Airbnb's internal GraphQL-like API)
            results.niobe_check = await tryFetch('/api/v3/niobe?operationName=QuickRepliesQuery', {
                method: 'POST',
                headers: {'content-type': 'application/json', 'x-csrf-token': csrf},
                body: JSON.stringify({
                    operationName: 'QuickRepliesQuery',
                    variables: {},
                    query: 'query QuickRepliesQuery { quickReplies { id title message } }'
                })
            });

            // Get current URL to verify we're on the right page
            results.current_url = window.location.href;
            results.cookies_partial = document.cookie.substring(0, 200);

            return JSON.stringify(results);
        })()
        """

        print("  Running JS fetch attempts...", file=sys.stderr)
        fetch_results = eval_js(ws, api_attempts_js, timeout=30)
        results["test2_fetch_attempts"] = fetch_results
        print(f"  Current URL: {fetch_results.get('current_url', 'unknown')}", file=sys.stderr)
        print(f"  CSRF: {fetch_results.get('csrf_found', 'unknown')}", file=sys.stderr)

        # Test 3: DOM extraction - find quick reply text in rendered page
        print("\n## Test 3: DOM extraction - find quick replies in rendered DOM", file=sys.stderr)
        print("- Hypothesis: quick replies are rendered in DOM and extractable via querySelectorAll", file=sys.stderr)

        dom_js = """
        (async () => {
            const results = {};

            // Look for common quick reply patterns
            // Try data-testid, aria labels, heading+paragraph combos
            const testIds = Array.from(document.querySelectorAll('[data-testid]'))
                .filter(el => el.getAttribute('data-testid').toLowerCase().includes('quick'))
                .map(el => ({testid: el.getAttribute('data-testid'), text: el.innerText.substring(0, 200)}));
            results.data_testid_quick = testIds;

            // Look for any elements containing "quick" in text near form fields
            const headings = Array.from(document.querySelectorAll('h1,h2,h3,h4,h5,h6'))
                .map(h => h.innerText.trim())
                .filter(t => t.length > 0);
            results.headings = headings;

            // Get all visible text content sections (divs with substantial text)
            const sections = Array.from(document.querySelectorAll('section, article, [role="listitem"]'))
                .slice(0, 20)
                .map(el => el.innerText.substring(0, 300).trim())
                .filter(t => t.length > 10);
            results.sections = sections;

            // Try to find quick reply list items
            const listItems = Array.from(document.querySelectorAll('li, [role="listitem"]'))
                .slice(0, 30)
                .map(el => el.innerText.substring(0, 200).trim())
                .filter(t => t.length > 5);
            results.list_items = listItems;

            // Check if page has __NEXT_DATA__ (Next.js SSR data)
            const nextData = window.__NEXT_DATA__;
            if (nextData) {
                const str = JSON.stringify(nextData).substring(0, 5000);
                results.next_data_snippet = str;
            }

            // Check for Redux store or Apollo cache
            const reduxStore = window.__REDUX_STATE__ || window.__STORE__ || window.__INITIAL_STATE__;
            if (reduxStore) {
                results.redux_snippet = JSON.stringify(reduxStore).substring(0, 3000);
            }

            // Check window for any quick-reply-related global state
            const globalKeys = Object.keys(window).filter(k =>
                k.toLowerCase().includes('quick') || k.toLowerCase().includes('reply') ||
                k.toLowerCase().includes('airbnb') || k.toLowerCase().includes('bootstrap')
            );
            results.global_keys = globalKeys;

            results.page_title = document.title;
            results.body_text_snippet = document.body.innerText.substring(0, 1000);

            return JSON.stringify(results);
        })()
        """

        print("  Running DOM extraction...", file=sys.stderr)
        dom_results = eval_js(ws, dom_js, timeout=30)
        results["test3_dom"] = dom_results

        # Test 4: Deep inspect network events - try GraphQL specifically
        print("\n## Test 4: Try Airbnb GraphQL / niobe endpoint with discovered tokens", file=sys.stderr)

        graphql_js = """
        (async () => {
            const results = {};

            // Get all cookies to understand auth
            results.all_cookies_preview = document.cookie.substring(0, 500);

            // Try to extract API key from bootstrap data or meta tags
            const bootstrapData = document.querySelector('#data-bootstrap')?.textContent || '';
            results.bootstrap_snippet = bootstrapData.substring(0, 500);

            // Check for Airbnb's niobe/explore API key in scripts
            const scripts = Array.from(document.querySelectorAll('script[src]'))
                .map(s => s.src)
                .filter(s => s.includes('airbnb'));
            results.script_srcs = scripts.slice(0, 10);

            // Look for _csrf_token in page source
            const csrfMeta = document.querySelector('meta[name*="csrf"]')?.content || '';
            results.csrf_meta = csrfMeta;

            // Try to get client_session_id or similar from page bootstrap
            const bootstrap = window.bootstrap || {};
            results.bootstrap_keys = Object.keys(bootstrap).slice(0, 20);

            // Try the hosting messages settings API directly - this is the likely endpoint
            async function tryFetch(url, opts) {
                try {
                    const r = await fetch(url, {credentials: 'include', ...opts});
                    const txt = await r.text();
                    return {status: r.status, body: txt.substring(0, 4000)};
                } catch(e) {
                    return {error: e.toString()};
                }
            }

            // Airbnb uses api_key in query params for some endpoints
            // Try to extract it from the page
            const apiKeyMatch = document.documentElement.innerHTML.match(/"api_key":"([^"]+)"/);
            const apiKey = apiKeyMatch ? apiKeyMatch[1] : '';
            results.api_key_found = apiKey ? 'yes: ' + apiKey.substring(0, 20) : 'no';

            // Try various endpoint patterns
            results.hosting_settings = await tryFetch('/api/v2/hosting_messaging_settings?product=STAYS');
            results.quick_replies_v2 = await tryFetch('/api/v2/quick_replies?product=STAYS&_format=for_remy');
            results.quick_replies_staging = await tryFetch('/api/v2/quick_replies?product=STAYS&key=' + apiKey);

            return JSON.stringify(results);
        })()
        """

        print("  Running GraphQL/niobe exploration...", file=sys.stderr)
        graphql_results = eval_js(ws, graphql_js, timeout=30)
        results["test4_graphql_explore"] = graphql_results

        ws.close()

    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except Exception:
            proc.kill()

    print(json.dumps(results, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
