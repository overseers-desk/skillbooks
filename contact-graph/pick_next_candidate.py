#!/usr/bin/env python3
"""
pick_next_candidate.py — return next LinkedIn outreach candidate(s), already scored.

Each candidate carries a memory score M: the likelihood the *other* person
remembers us. M is summed over the candidate's qualifying email threads, where a
thread qualifies only if it is two-way (the candidate sent AND one of our people
sent, both as role 'from') and is not a calendar invitation. A private (sole
external) thread counts in full; a group thread counts at GROUP_WEIGHT. Each
thread decays with a half-life of HALF_LIFE_YEARS from its last message.

M maps to a treatment level: 3 (bare connect), 2 (remind shared work), 1 (USP /
crossed paths). Candidates below DROP_FLOOR are never returned, so the harvest
output is itself the rubric — there is no separate scoring step downstream.

Usage:
  python3 pick_next_candidate.py                # one candidate
  python3 pick_next_candidate.py --limit 5      # top five by M
  python3 pick_next_candidate.py --workflow X   # different campaign label
"""

import argparse
import json
import os
import sys
from pathlib import Path

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

SCRIPT_DIR = Path(__file__).parent.resolve()
load_dotenv(SCRIPT_DIR / '.env')

DATABASE_URL = os.environ['DATABASE_URL']
DEFAULT_WORKFLOW = 'linkedin_2026'

# --- Rubric constants (single source of truth for the memory score) ----------
HALF_LIFE_YEARS = 10.0   # a thread is worth half as much after this many years
GROUP_WEIGHT = 0.2       # a group thread vs a private (sole-external) one
DROP_FLOOR = 0.1         # below this M, the person is too cold to surface
LEVEL2_CUTOFF = 1.0      # M >= this -> level 2 (remind shared work)
LEVEL3_CUTOFF = 4.0      # M >= this -> level 3 (bare connect, no note)
# -----------------------------------------------------------------------------

QUERY = """
WITH thread_meta AS (
  SELECT et.thread_id, et.last_message_at,
         bool_or(COALESCE(em.subject, '') !~*
           '^(invitation|updated invitation|accepted|declined|tentative|canceled|cancelled):'
         ) AS has_real
  FROM email_thread et
  LEFT JOIN email_message em ON em.thread_id = et.thread_id
  GROUP BY et.thread_id, et.last_message_at
),
thread_part AS (
  SELECT etp.thread_id,
         COUNT(*) FILTER (WHERE NOT h.internal) AS ext_count,
         bool_or(h.internal AND 'from' = ANY(etp.roles)) AS internal_sent
  FROM email_thread_participant etp
  JOIN human h ON h.id = etp.human_id
  GROUP BY etp.thread_id
),
scored AS (
  SELECT etp.human_id,
         SUM(
           (CASE WHEN tp.ext_count = 1 THEN 1.0 ELSE %(group_weight)s END)
           * POWER(0.5,
               (EXTRACT(EPOCH FROM NOW()) - tm.last_message_at)
               / (%(half_life)s * 365.25 * 86400))
         ) AS m
  FROM email_thread_participant etp
  JOIN human h ON h.id = etp.human_id AND NOT h.internal
  JOIN thread_meta tm ON tm.thread_id = etp.thread_id
  JOIN thread_part tp ON tp.thread_id = etp.thread_id
  WHERE tm.has_real                    -- not a calendar invitation
    AND 'from' = ANY(etp.roles)        -- the candidate themselves wrote
    AND tp.internal_sent               -- one of our people wrote back
  GROUP BY etp.human_id
)
SELECT
  h.id AS human_id,
  h.display_name,
  round(sc.m::numeric, 3) AS m,
  CASE WHEN sc.m >= %(l3)s THEN 3
       WHEN sc.m >= %(l2)s THEN 2
       ELSE 1 END AS level,
  COALESCE(
    (SELECT array_agg(address ORDER BY is_canonical DESC, id ASC)
     FROM email_address WHERE human_id = h.id),
    ARRAY[]::text[]
  ) AS email_addresses,
  COALESCE(
    (SELECT array_agg(DISTINCT o.name)
     FROM item_entity ie
     JOIN organisation o ON o.id = ie.organisation_id
     WHERE ie.human_id = h.id AND ie.organisation_id IS NOT NULL),
    ARRAY[]::text[]
  ) AS org_hints
FROM human h
JOIN scored sc ON sc.human_id = h.id
WHERE h.linkedin_url IS NULL
  AND sc.m >= %(floor)s
  AND NOT EXISTS (
    SELECT 1 FROM connection_queue cq
    WHERE cq.human_id = h.id AND cq.workflow_label = %(workflow)s
  )
ORDER BY sc.m DESC
LIMIT %(limit)s;
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--limit', type=int, default=1)
    ap.add_argument('--workflow', default=DEFAULT_WORKFLOW)
    args = ap.parse_args()

    params = {
        'group_weight': GROUP_WEIGHT,
        'half_life': HALF_LIFE_YEARS,
        'floor': DROP_FLOOR,
        'l2': LEVEL2_CUTOFF,
        'l3': LEVEL3_CUTOFF,
        'workflow': args.workflow,
        'limit': args.limit,
    }

    with psycopg2.connect(DATABASE_URL) as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(QUERY, params)
            rows = cur.fetchall()

    json.dump([dict(r) for r in rows], sys.stdout, indent=2, default=str)
    sys.stdout.write('\n')


if __name__ == '__main__':
    main()
