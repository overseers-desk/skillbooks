#!/usr/bin/env python3
"""
record_verify.py — write a verify-stage outcome to connection_queue.

UPSERTs the connection_queue row for (human_id, workflow_label). Sets state,
profile_id, verify_evidence, verified_at, level; sets terminal_at if state is a
terminal state for this stage (unverifiable, ambiguous).

--level is the treatment band carried over from pick_next_candidate.py (3 bare
connect, 2 remind shared work, 1 USP / crossed paths). Pass it through for
verified rows; the raw memory score belongs in --evidence as {"m": <score>}.

Usage:
  python3 record_verify.py --human-id 123 --state verified --vanity https://www.linkedin.com/in/alice-smith/ --level 2 --evidence '{"source":"google","query":"...","m":1.4}'
  python3 record_verify.py --human-id 456 --state unverifiable --evidence '{"source":"linkedin","tried":"..."}'
  python3 record_verify.py --human-id 789 --state ambiguous --evidence '{"source":"google","candidates":["url1","url2"]}'
"""

import argparse
import json
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

VERIFY_STATES = {'verified', 'unverifiable', 'ambiguous',
                 'already_connected', 'invite_pending'}
TERMINAL_FOR_VERIFY = {'unverifiable', 'ambiguous',
                       'already_connected', 'invite_pending'}

UPSERT_PROFILE = """
INSERT INTO linkedin.profile (human_id, slug)
VALUES (%s, %s)
ON CONFLICT (slug) DO UPDATE SET human_id = EXCLUDED.human_id
RETURNING id;
"""

UPSERT = """
INSERT INTO linkedin.connection_queue
  (human_id, workflow_label, state, profile_id, verify_evidence,
   level, verified_at, queued_at, terminal_at)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
ON CONFLICT (human_id, workflow_label) DO UPDATE SET
  state = EXCLUDED.state,
  profile_id = COALESCE(EXCLUDED.profile_id, linkedin.connection_queue.profile_id),
  verify_evidence = EXCLUDED.verify_evidence,
  level = COALESCE(EXCLUDED.level, linkedin.connection_queue.level),
  verified_at = EXCLUDED.verified_at,
  terminal_at = EXCLUDED.terminal_at;
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--human-id', type=int, required=True)
    ap.add_argument('--state', required=True, choices=sorted(VERIFY_STATES))
    ap.add_argument('--vanity', default=None)
    ap.add_argument('--level', type=int, default=None, choices=[0, 1, 2, 3],
                    help='treatment band from pick_next_candidate.py')
    ap.add_argument('--evidence', default=None,
                    help='JSON string describing the verify attempt')
    ap.add_argument('--workflow', default=DEFAULT_WORKFLOW)
    args = ap.parse_args()

    if args.state == 'verified' and not args.vanity:
        sys.exit('error: --vanity required when --state=verified')

    evidence_json = args.evidence
    if evidence_json is not None:
        try:
            json.loads(evidence_json)
        except json.JSONDecodeError as e:
            sys.exit(f'error: --evidence is not valid JSON: {e}')

    now = int(time.time())
    terminal = now if args.state in TERMINAL_FOR_VERIFY else None

    slug = None
    if args.vanity:
        slug = re.sub(r'^https?://[^/]+/in/([^/?#]+).*', r'\1',
                      args.vanity).strip('/')

    with psycopg2.connect(DATABASE_URL) as conn:
        with conn.cursor() as cur:
            profile_id = None
            if slug:
                cur.execute(UPSERT_PROFILE, (args.human_id, slug))
                profile_id = cur.fetchone()[0]
            cur.execute(UPSERT, (
                args.human_id, args.workflow, args.state,
                profile_id, evidence_json, args.level,
                now, now, terminal,
            ))

    print(f'ok: human_id={args.human_id} state={args.state}'
          + (f' slug={slug}' if slug else ''))


if __name__ == '__main__':
    main()
