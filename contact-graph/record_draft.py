#!/usr/bin/env python3
"""
record_draft.py — write a drafted connection note to connection_queue.

UPDATEs the connection_queue row for (human_id, workflow_label). Refuses if
the row is not currently state='verified'. Refuses notes longer than 300
characters (LinkedIn's hard limit). Sets state='drafted', note_text,
with_note, drafted_at.

Usage:
  python3 record_draft.py --human-id 123 --note "Hi Alice, ..."
  python3 record_draft.py --human-id 123 --note "..." --no-note   # connection without a note text
"""

import argparse
import os
import sys
import time
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).parent.resolve()
load_dotenv(SCRIPT_DIR / '.env')

DATABASE_URL = os.environ['DATABASE_URL']
DEFAULT_WORKFLOW = 'linkedin_2026'
LINKEDIN_NOTE_MAX = 300

UPDATE = """
UPDATE connection_queue
SET state = 'drafted',
    note_text = %s,
    with_note = %s,
    drafted_at = %s
WHERE human_id = %s AND workflow_label = %s AND state = 'verified'
RETURNING id;
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--human-id', type=int, required=True)
    ap.add_argument('--note', required=True)
    ap.add_argument('--no-note', dest='with_note', action='store_false',
                    help='record the draft but flag for sending without a note')
    ap.add_argument('--workflow', default=DEFAULT_WORKFLOW)
    ap.set_defaults(with_note=True)
    args = ap.parse_args()

    if len(args.note) > LINKEDIN_NOTE_MAX:
        sys.exit(f'error: note is {len(args.note)} chars, max is {LINKEDIN_NOTE_MAX}')

    now = int(time.time())

    with psycopg2.connect(DATABASE_URL) as conn:
        with conn.cursor() as cur:
            cur.execute(UPDATE, (
                args.note, args.with_note, now,
                args.human_id, args.workflow,
            ))
            row = cur.fetchone()

    if row is None:
        sys.exit(f'error: no verified row for human_id={args.human_id} '
                 f'workflow={args.workflow}; cannot draft')

    print(f'ok: human_id={args.human_id} drafted ({len(args.note)} chars, '
          f'with_note={args.with_note})')


if __name__ == '__main__':
    main()
