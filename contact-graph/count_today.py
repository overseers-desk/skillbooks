#!/usr/bin/env python3
"""
count_today.py — report today's run state for the LinkedIn outreach workflow.

"Today" = since local midnight. Used by the session to know when to stop
(linkedin_searches_used >= 30 is the ceiling per Stage 3 runbook).

Usage:
  python3 count_today.py
  python3 count_today.py --workflow X
"""

import argparse
import os
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).parent.resolve()
load_dotenv(SCRIPT_DIR / '.env')

DATABASE_URL = os.environ['DATABASE_URL']
DEFAULT_WORKFLOW = 'linkedin_2026'

QUERY = """
WITH t AS (SELECT EXTRACT(EPOCH FROM date_trunc('day', NOW()))::INTEGER AS day_start)
SELECT
  COUNT(*) FILTER (
    WHERE verify_evidence->>'source' = 'linkedin'
      AND verified_at >= (SELECT day_start FROM t)
  ) AS linkedin_searches_used,
  COUNT(*) FILTER (
    WHERE state = 'drafted' AND drafted_at >= (SELECT day_start FROM t)
  ) AS candidates_drafted,
  COUNT(*) FILTER (
    WHERE state = 'unverifiable' AND verified_at >= (SELECT day_start FROM t)
  ) AS candidates_unverifiable,
  COUNT(*) FILTER (
    WHERE state = 'ambiguous' AND verified_at >= (SELECT day_start FROM t)
  ) AS candidates_ambiguous,
  COUNT(*) FILTER (
    WHERE state = 'verified' AND verified_at >= (SELECT day_start FROM t)
  ) AS candidates_verified_not_yet_drafted
FROM linkedin.connection_queue
WHERE workflow_label = %s;
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--workflow', default=DEFAULT_WORKFLOW)
    args = ap.parse_args()

    with psycopg2.connect(DATABASE_URL) as conn:
        with conn.cursor() as cur:
            cur.execute(QUERY, (args.workflow,))
            row = cur.fetchone()

    (linkedin_used, drafted, unver, amb, verified_pending) = row
    print(f'linkedin_searches_used={linkedin_used}')
    print(f'candidates_drafted={drafted}')
    print(f'candidates_unverifiable={unver}')
    print(f'candidates_ambiguous={amb}')
    print(f'candidates_verified_not_yet_drafted={verified_pending}')


if __name__ == '__main__':
    main()
