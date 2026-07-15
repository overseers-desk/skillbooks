#!/usr/bin/env python3
"""
check_connection_status.py — direct LinkedIn profile-page visit to determine
whether the operator is already first-degree connected to a person, has a
pending invite outstanding, or is not connected.

Direct URL fetch (no people-search), so it does not count against the
Commercial Use Limit. Cheap; should be called BEFORE courier/draft work
in the outreach loop so we do not burn tokens drafting notes for people
who cannot or should not be invited.

Output (stdout): one of
  not_connected      -- the Connect-invite link is present, can invite
  invite_pending     -- invite already sent, no need to re-send
  already_connected  -- first-degree (Message button, no Connect link)
  fetch_failed       -- could not retrieve the page
  parse_failed       -- page retrieved but neither signal found

Exit code: 0 on success (one of the five strings printed), non-zero on
script/argument error.

Usage:
  python3 check_connection_status.py --vanity https://www.linkedin.com/in/alice-smith/
  python3 check_connection_status.py --vanity alice-smith
"""

import argparse
import os
import re
import subprocess
import sys

# browser-serialiser ships with the serialised-browsing skill (overseer-toolbox
# plugin) and is on PATH when that plugin is installed.
BROWSER_SERIALISER = 'browser-serialiser'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--vanity', required=True,
                    help='full /in/<vanity>/ URL or bare vanity slug')
    ap.add_argument('--timeout', type=int, default=20,
                    help='chromium timeout in seconds (default 20)')
    args = ap.parse_args()

    v = args.vanity.strip()
    if v.startswith('http'):
        url = v.rstrip('/') + '/'
    else:
        url = f'https://www.linkedin.com/in/{v.strip("/")}/'

    try:
        res = subprocess.run(
            [BROWSER_SERIALISER, '--dump', '-t', str(args.timeout), url],
            capture_output=True, text=True, timeout=args.timeout + 10,
        )
    except subprocess.TimeoutExpired:
        print('fetch_failed')
        return
    if res.returncode != 0 or len(res.stdout) < 1000:
        print('fetch_failed')
        return

    dom = res.stdout

    # If the page shows a "Sign In" wall the browser plumbing is broken;
    # bail loudly rather than silently classify.
    if re.search(r'<title>[^<]*Sign In', dom, re.I) or 'Iniciar sesión' in dom:
        sys.exit('error: profile page returned a Sign-In wall; chromium '
                 'profile plumbing is broken')

    # Three signals, checked in this order:
    #
    # 1. Pending invite: aria-label="Pending" or button text "Pending"
    #    near an artdeco-button. LinkedIn renders this when an invite has
    #    been sent and not yet accepted.
    # 2. Connect link present: /preload/custom-invite/?vanityName= — this
    #    is the entry point for sending an invite. Its presence means the
    #    operator is NOT yet connected and can invite.
    # 3. Otherwise: assume already connected. First-degree connections do
    #    not see the Connect link; they see a Message button instead.
    pending_pat = re.compile(r'aria-label="Pending', re.I)
    invite_pat = re.compile(r'/preload/custom-invite/\?vanityName=')

    if pending_pat.search(dom):
        print('invite_pending')
    elif invite_pat.search(dom):
        print('not_connected')
    else:
        print('already_connected')


if __name__ == '__main__':
    main()
