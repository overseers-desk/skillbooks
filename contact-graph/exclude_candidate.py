#!/usr/bin/env python3
"""
exclude_candidate.py — mark a person do_not_contact in connection_queue.

Resolves exactly one identifier (--email, --human-id or --linkedin-url) to a
human_id, then UPSERTs the connection_queue row for (human_id, workflow_label):
state='do_not_contact', exclusion_reason, terminal_at. A missing row is created:
pick_next_candidate.py skips anyone who has a row, so the row is what keeps a
person who was never surfaced out of the loop.

An identifier that matches no human, or more than one, is an error that names
what was found; nothing is guessed. The schema allows do_not_contact only from
a non-terminal state, so a row already terminal in another state is refused.
Re-running on an excluded row replaces the reason and keeps the original
terminal_at.

Usage:
  python3 exclude_candidate.py --email someone@example.com --reason "..."
  python3 exclude_candidate.py --human-id 1234 --reason "..."
  python3 exclude_candidate.py --linkedin-url https://www.linkedin.com/in/alice-smith/ --reason "..."
"""

import argparse
import os
import re
import sys
import time
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).parent.resolve()
load_dotenv(SCRIPT_DIR / '.env')

DATABASE_URL = os.environ['DATABASE_URL']
DEFAULT_WORKFLOW = 'linkedin_2026'

BY_HUMAN_ID = """
SELECT h.id, h.display_name, NULL FROM human h WHERE h.id = %s;
"""

# Address and slug are matched case-insensitively, so one input can hit several
# rows; each row reports its human (or NULL when not yet resolved).
BY_EMAIL = """
SELECT h.id, h.display_name, ea.address
FROM email_address ea
LEFT JOIN human h ON h.id = ea.human_id
WHERE lower(ea.address) = lower(%s);
"""

BY_SLUG = """
SELECT h.id, h.display_name, lp.slug
FROM linkedin.profile lp
LEFT JOIN human h ON h.id = lp.human_id
WHERE lower(lp.slug) = lower(%s);
"""

# The WHERE on the conflict branch leaves a terminal row in another state
# untouched; RETURNING then yields nothing and the caller reports that state.
UPSERT = """
INSERT INTO linkedin.connection_queue
  (human_id, workflow_label, state, exclusion_reason, queued_at, terminal_at)
VALUES (%s, %s, 'do_not_contact', %s, %s, %s)
ON CONFLICT (human_id, workflow_label) DO UPDATE SET
  state = 'do_not_contact',
  exclusion_reason = EXCLUDED.exclusion_reason,
  terminal_at = COALESCE(linkedin.connection_queue.terminal_at, EXCLUDED.terminal_at)
WHERE linkedin.connection_queue.state = 'do_not_contact'
   OR linkedin.connection_queue.terminal_at IS NULL
RETURNING id;
"""

CURRENT = """
SELECT state, terminal_at FROM linkedin.connection_queue
WHERE human_id = %s AND workflow_label = %s;
"""


def resolve(cur, args):
    """Return (human_id, display_name) for the one identifier given, or exit."""
    if args.human_id is not None:
        label = f'human_id={args.human_id}'
        cur.execute(BY_HUMAN_ID, (args.human_id,))
    elif args.email is not None:
        label = f'email={args.email}'
        cur.execute(BY_EMAIL, (args.email.strip(),))
    else:
        slug = re.sub(r'^https?://[^/]+/in/([^/?#]+).*', r'\1',
                      args.linkedin_url.strip()).strip('/')
        label = f'linkedin slug={slug}'
        cur.execute(BY_SLUG, (slug,))
    rows = cur.fetchall()

    if not rows:
        sys.exit(f'error: {label} matches nothing in the graph')
    unresolved = [key for hid, _, key in rows if hid is None]
    humans = {hid: name for hid, name, _ in rows if hid is not None}
    if not humans:
        sys.exit(f'error: {label} is recorded ({", ".join(unresolved)}) '
                 f'but not resolved to any human')
    if len(humans) > 1:
        found = ', '.join(f'{hid} ({name})' for hid, name in sorted(humans.items()))
        sys.exit(f'error: {label} matches {len(humans)} humans: {found}; '
                 f'rerun with --human-id')
    return next(iter(humans.items()))


def main():
    ap = argparse.ArgumentParser()
    who = ap.add_mutually_exclusive_group(required=True)
    who.add_argument('--email')
    who.add_argument('--human-id', type=int)
    who.add_argument('--linkedin-url',
                     help='profile URL (linkedin.com/in/<slug>) or bare slug')
    ap.add_argument('--reason', required=True,
                    help='why this person is off-limits; stored in exclusion_reason')
    ap.add_argument('--workflow', default=DEFAULT_WORKFLOW)
    args = ap.parse_args()

    if not args.reason.strip():
        sys.exit('error: --reason must not be empty')

    now = int(time.time())

    with psycopg2.connect(DATABASE_URL) as conn:
        with conn.cursor() as cur:
            human_id, name = resolve(cur, args)
            cur.execute(UPSERT, (human_id, args.workflow, args.reason, now, now))
            row = cur.fetchone()
            if row is None:
                cur.execute(CURRENT, (human_id, args.workflow))
                state, terminal_at = cur.fetchone()
                sys.exit(f'error: human_id={human_id} ({name}) is already terminal '
                         f'in workflow={args.workflow} as state={state} '
                         f'(terminal_at={terminal_at}); not changed')

    print(f'ok: human_id={human_id} ({name}) do_not_contact '
          f'workflow={args.workflow}')


if __name__ == '__main__':
    main()
