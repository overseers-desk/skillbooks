#!/usr/bin/env python3
"""
harvest_email.py — Thread-centric email harvest pipeline.

Three phases:
  1. Harvest message headers from mu → email_message
  2. Group messages into threads using mu's thread_id → email_thread
  3. Resolve participants to humans → email_thread_participant

No AI calls. ~80 seconds for the full corpus.

Usage:
  python3 harvest_email.py                          # all phases, all accounts
  python3 harvest_email.py --phase 1 --limit 200    # Phase 1 only, 200/account
  python3 harvest_email.py --phase 3 --workers 8    # Phase 3 with 8 workers
  python3 harvest_email.py --wipe                    # wipe tables, then full run
"""

import argparse
import json
import logging
import os
import re
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SCRIPT_DIR = Path(__file__).parent.resolve()
load_dotenv(SCRIPT_DIR / '.env')

DATABASE_URL = os.environ['DATABASE_URL']

ACTIVE_ACCOUNTS = [
    'director-rivermill-au',
    'admin-rivermill-au',
    'yuliansu-gmail-com',
]

DATE_MIN = 1
DATE_MAX = 4_102_444_800  # 2100-01-01
BATCH_SIZE = 5000

log = logging.getLogger('harvest')

# ---------------------------------------------------------------------------
# Runtime state (loaded from DB at startup)
# ---------------------------------------------------------------------------

INTERNAL_ADDRESSES: set[str] = set()
IGNORED_DOMAINS: set[str] = set()
IGNORED_ADDRESSES: set[str] = set()
IGNORED_REGEXES: list[re.Pattern] = []
IGNORED_SUBJECTS: list[str] = []


# ---------------------------------------------------------------------------
# DB helpers
# ---------------------------------------------------------------------------

def db_connect():
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False
    return conn


def load_runtime_state(conn):
    """Load ignored patterns and internal addresses from DB."""
    with conn.cursor() as cur:
        cur.execute("""
            SELECT ea.address FROM email_address ea
            JOIN human h ON h.id = ea.human_id
            WHERE h.internal = TRUE
        """)
        for (addr,) in cur.fetchall():
            INTERNAL_ADDRESSES.add(addr.lower())

        cur.execute("SELECT pattern, pattern_type FROM email_ignored_pattern")
        for pattern, ptype in cur.fetchall():
            if ptype == 'domain':
                IGNORED_DOMAINS.add(pattern.lower())
            elif ptype == 'address':
                IGNORED_ADDRESSES.add(pattern.lower())
            elif ptype == 'regex':
                try:
                    IGNORED_REGEXES.append(re.compile(pattern))
                except re.error:
                    log.warning("Bad regex in email_ignored_pattern: %s", pattern)
            elif ptype == 'subject':
                IGNORED_SUBJECTS.append(pattern.lower())

    log.info(
        "Runtime state: %d internal addrs, %d ignored domains, "
        "%d ignored addrs, %d ignored regexes, %d ignored subjects",
        len(INTERNAL_ADDRESSES), len(IGNORED_DOMAINS),
        len(IGNORED_ADDRESSES), len(IGNORED_REGEXES), len(IGNORED_SUBJECTS),
    )


# ---------------------------------------------------------------------------
# Filter helpers
# ---------------------------------------------------------------------------

def is_ignored_address(addr: str) -> bool:
    a = addr.lower()
    if a in IGNORED_ADDRESSES:
        return True
    domain = a.rsplit('@', 1)[1] if '@' in a else ''
    if domain in IGNORED_DOMAINS:
        return True
    for d in IGNORED_DOMAINS:
        if domain.endswith('.' + d):
            return True
    for rx in IGNORED_REGEXES:
        if rx.search(a):
            return True
    return False


def is_ignored_subject(subject: str) -> bool:
    if not subject:
        return False
    sl = subject.lower()
    return any(p in sl for p in IGNORED_SUBJECTS)


# ---------------------------------------------------------------------------
# mu helpers
# ---------------------------------------------------------------------------

def mu_query_account(account: str) -> list[dict]:
    """Return messages for one account sorted newest-first (JSON)."""
    cmd = ['mu', 'find', f'maildir:/{account}/*',
           '--format=json', '--sortfield=date', '--reverse']
    result = subprocess.run(
        cmd, capture_output=True, text=True, errors='replace', timeout=300,
    )
    raw = result.stdout
    if not raw.strip() or raw.strip() == '[]':
        return []
    clean = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', '', raw)
    try:
        return json.JSONDecoder(strict=False).decode(clean)
    except json.JSONDecodeError as exc:
        log.warning("JSON parse error for %s: %s", account, exc)
        return []


def mu_query_thread_map(accounts: list[str]) -> dict[str, str]:
    """Query mu for message_id -> thread_id mapping across all accounts.

    Runs two parallel mu queries (fields="i" and fields="w") with identical
    sort order and --skip-dups, then zips the results line by line.
    """
    query = ' OR '.join(f'maildir:/{a}/*' for a in accounts)
    base = ['mu', 'find', query, '--format=plain', '--skip-dups',
            '--sortfield=date', '--reverse']

    proc_i = subprocess.Popen(
        base + ['--fields=i'],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, errors='replace',
    )
    proc_w = subprocess.Popen(
        base + ['--fields=w'],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, errors='replace',
    )

    out_i, _ = proc_i.communicate(timeout=300)
    out_w, _ = proc_w.communicate(timeout=300)

    lines_i = [l for l in out_i.strip().split('\n') if l.strip()]
    lines_w = [l for l in out_w.strip().split('\n') if l.strip()]

    if len(lines_i) != len(lines_w):
        raise RuntimeError(
            f"mu field query mismatch: {len(lines_i)} message_ids "
            f"vs {len(lines_w)} thread_ids"
        )

    thread_map = {}
    for mid_line, tid_line in zip(lines_i, lines_w):
        mid = mid_line.strip()
        tid = tid_line.strip()
        if mid and tid:
            thread_map[mid] = tid

    log.info("Thread map: %d message->thread pairs from mu", len(thread_map))
    return thread_map


def parse_addrs(field) -> list[tuple[str, str]]:
    """Parse a mu JSON address field -> [(email, display_name)]."""
    if not field:
        return []
    if isinstance(field, dict):
        field = [field]
    out = []
    for item in field:
        if not isinstance(item, dict):
            continue
        em = (item.get(':email') or '').strip().lower()
        nm = (item.get(':name') or '').strip()
        if em:
            out.append((em, nm))
    return out


# ---------------------------------------------------------------------------
# Phase 1: Message harvest
# ---------------------------------------------------------------------------

def _flush_message_batch(conn, batch: list[tuple]):
    with conn.cursor() as cur:
        psycopg2.extras.execute_values(
            cur,
            """INSERT INTO email_message (message_id, account, date, date_anomaly, subject)
               VALUES %s ON CONFLICT (message_id) DO NOTHING""",
            batch,
            page_size=BATCH_SIZE,
        )
    conn.commit()


def _update_coverage(conn, account: str, newest_id: str, oldest_id: str):
    now = int(time.time())
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO email_source_coverage
                (source_kind, source_ref, newest_scanned_id,
                 oldest_scanned_id, last_checked_at)
            VALUES ('email', %s, %s, %s, %s)
            ON CONFLICT (source_kind, source_ref) DO UPDATE SET
                newest_scanned_id = COALESCE(
                    email_source_coverage.newest_scanned_id,
                    EXCLUDED.newest_scanned_id),
                oldest_scanned_id = EXCLUDED.oldest_scanned_id,
                last_checked_at = EXCLUDED.last_checked_at
        """, (account, newest_id, oldest_id, now))
    conn.commit()


def phase1_harvest_account(
    account: str, limit: int | None,
) -> tuple[int, int, dict]:
    """Harvest one account. Returns (total, skipped, local_addr_map)."""
    conn = db_connect()
    try:
        messages = mu_query_account(account)
        if limit:
            messages = messages[:limit]
        log.info("[%s] %d messages from mu", account, len(messages))

        local_addr_map: dict[str, dict] = {}
        batch: list[tuple] = []
        total = 0
        skipped_subj = 0
        newest_id = None
        oldest_id = None

        for msg in messages:
            message_id = (msg.get(':message-id') or '').strip()
            if not message_id:
                continue

            subject = (msg.get(':subject') or '').strip()
            if is_ignored_subject(subject):
                skipped_subj += 1
                continue

            date_unix = msg.get(':date-unix') or 0
            date_anomaly = not (DATE_MIN < date_unix < DATE_MAX)
            if date_anomaly:
                date_unix = 1

            local_addr_map[message_id] = {
                'from': parse_addrs(msg.get(':from')),
                'to': parse_addrs(msg.get(':to')),
                'cc': parse_addrs(msg.get(':cc')),
                'date': date_unix,
            }

            batch.append((message_id, account, date_unix, date_anomaly, subject))
            total += 1
            if newest_id is None:
                newest_id = message_id
            oldest_id = message_id

            if len(batch) >= BATCH_SIZE:
                _flush_message_batch(conn, batch)
                log.info("[%s] %d messages flushed", account, total)
                batch.clear()

        if batch:
            _flush_message_batch(conn, batch)

        if newest_id and oldest_id:
            _update_coverage(conn, account, newest_id, oldest_id)

        log.info("[%s] %d harvested, %d skipped (subject)", account, total, skipped_subj)
        return total, skipped_subj, local_addr_map
    finally:
        conn.close()


def phase1_harvest(accounts: list[str], limit: int | None) -> dict:
    """Run Phase 1 for all accounts in parallel. Returns combined addr_map."""
    log.info(
        "Phase 1: harvesting %d accounts%s",
        len(accounts),
        f" (limit {limit}/account)" if limit else "",
    )

    addr_map: dict[str, dict] = {}
    total_all = 0

    with ThreadPoolExecutor(max_workers=len(accounts)) as pool:
        futures = {
            pool.submit(phase1_harvest_account, acct, limit): acct
            for acct in accounts
        }
        for future in as_completed(futures):
            acct = futures[future]
            try:
                n, _, local_map = future.result()
                total_all += n
                addr_map.update(local_map)
            except Exception:
                log.exception("Phase 1 failed for %s", acct)
                raise

    log.info("Phase 1 complete: %d messages harvested, %d in addr_map",
             total_all, len(addr_map))
    return addr_map


# ---------------------------------------------------------------------------
# Phase 2: Thread grouping
# ---------------------------------------------------------------------------

def phase2_thread_grouping(
    conn, accounts: list[str],
) -> dict[str, list[str]]:
    """Create email_thread rows and UPDATE email_message.thread_id.

    Returns thread_messages: {thread_id -> [message_ids]}.
    """
    log.info("Phase 2: building thread map from mu")
    raw_map = mu_query_thread_map(accounts)

    # Load unthreaded messages from DB
    with conn.cursor() as cur:
        cur.execute(
            "SELECT message_id, date FROM email_message WHERE thread_id IS NULL"
        )
        db_messages = dict(cur.fetchall())
    log.info("Phase 2: %d unthreaded messages in DB", len(db_messages))

    # Filter thread map to messages actually in DB
    valid_map = {mid: tid for mid, tid in raw_map.items() if mid in db_messages}
    log.info("Phase 2: %d matched", len(valid_map))

    if not valid_map:
        log.info("Phase 2: nothing to thread")
        return {}

    # Build thread_data: thread_id -> [(message_id, date)]
    thread_data: dict[str, list[tuple[str, int]]] = {}
    for mid, tid in valid_map.items():
        thread_data.setdefault(tid, []).append((mid, db_messages[mid]))

    log.info("Phase 2: %d threads", len(thread_data))

    # Batch-insert email_thread rows
    thread_rows = []
    for tid, msgs in thread_data.items():
        dates = [d for _, d in msgs]
        thread_rows.append((tid, min(dates), max(dates), 'pending'))

    with conn.cursor() as cur:
        for i in range(0, len(thread_rows), BATCH_SIZE):
            psycopg2.extras.execute_values(
                cur,
                """INSERT INTO email_thread
                       (thread_id, first_message_at, last_message_at, status)
                   VALUES %s ON CONFLICT (thread_id) DO NOTHING""",
                thread_rows[i:i + BATCH_SIZE],
                page_size=BATCH_SIZE,
            )
    conn.commit()
    log.info("Phase 2: email_thread rows inserted")

    # Bulk UPDATE email_message.thread_id via temp table
    with conn.cursor() as cur:
        cur.execute(
            "CREATE TEMP TABLE _thread_map "
            "(message_id TEXT PRIMARY KEY, thread_id TEXT NOT NULL)"
        )
        pairs = list(valid_map.items())
        for i in range(0, len(pairs), BATCH_SIZE):
            psycopg2.extras.execute_values(
                cur,
                "INSERT INTO _thread_map (message_id, thread_id) VALUES %s",
                pairs[i:i + BATCH_SIZE],
                page_size=BATCH_SIZE,
            )
        cur.execute("""
            UPDATE email_message m
            SET thread_id = t.thread_id
            FROM _thread_map t
            WHERE m.message_id = t.message_id AND m.thread_id IS NULL
        """)
        updated = cur.rowcount
        cur.execute("DROP TABLE _thread_map")
    conn.commit()
    log.info(
        "Phase 2 complete: %d messages threaded into %d threads",
        updated, len(thread_data),
    )

    return {tid: [mid for mid, _ in msgs] for tid, msgs in thread_data.items()}


# ---------------------------------------------------------------------------
# Phase 3: Participant resolution
# ---------------------------------------------------------------------------

def _load_email_to_human(conn) -> dict[str, int]:
    """Load lowercase(address) -> human_id for all resolved addresses."""
    with conn.cursor() as cur:
        cur.execute(
            "SELECT lower(address), human_id FROM email_address "
            "WHERE human_id IS NOT NULL"
        )
        return dict(cur.fetchall())


def _load_internal_human_ids(conn) -> set[int]:
    with conn.cursor() as cur:
        cur.execute("SELECT id FROM human WHERE internal = TRUE")
        return {row[0] for row in cur.fetchall()}


def _resolve_thread(
    thread_id: str,
    message_ids: list[str],
    addr_map: dict,
    email_to_human: dict[str, int],
    internal_ids: set[int],
) -> list[tuple]:
    """Resolve one thread's participants.

    Returns list of (thread_id, human_id, roles_list, first_seen_at).
    Empty list means all-internal or no resolvable participants.
    """
    human_roles: dict[int, dict] = {}

    for mid in message_ids:
        msg_data = addr_map.get(mid)
        if not msg_data:
            continue
        msg_date = msg_data['date']

        for role_name, addrs in [('from', msg_data['from']),
                                  ('to', msg_data['to']),
                                  ('cc', msg_data['cc'])]:
            for addr, _ in addrs:
                if is_ignored_address(addr):
                    continue
                human_id = email_to_human.get(addr)
                if human_id is None:
                    continue
                if human_id not in human_roles:
                    human_roles[human_id] = {
                        'roles': set(), 'min_date': msg_date,
                    }
                human_roles[human_id]['roles'].add(role_name)
                if msg_date < human_roles[human_id]['min_date']:
                    human_roles[human_id]['min_date'] = msg_date

    # All-internal threads produce no participant rows
    if human_roles and all(h in internal_ids for h in human_roles):
        return []

    return [
        (thread_id, hid, sorted(data['roles']), data['min_date'])
        for hid, data in human_roles.items()
    ]


def _rebuild_addr_map(accounts: list[str]) -> dict:
    """Re-load participant addresses from mu JSON (standalone Phase 3)."""
    log.info("Rebuilding addr_map from mu (standalone mode)")
    addr_map: dict[str, dict] = {}
    for account in accounts:
        messages = mu_query_account(account)
        for msg in messages:
            mid = (msg.get(':message-id') or '').strip()
            if not mid:
                continue
            date_unix = msg.get(':date-unix') or 0
            if not (DATE_MIN < date_unix < DATE_MAX):
                date_unix = 1
            addr_map[mid] = {
                'from': parse_addrs(msg.get(':from')),
                'to': parse_addrs(msg.get(':to')),
                'cc': parse_addrs(msg.get(':cc')),
                'date': date_unix,
            }
    log.info("addr_map rebuilt: %d messages", len(addr_map))
    return addr_map


def phase3_participant_resolution(
    conn,
    accounts: list[str],
    thread_messages: dict[str, list[str]] | None,
    addr_map: dict | None,
    workers: int,
):
    """Resolve participants for all pending threads."""
    email_to_human = _load_email_to_human(conn)
    internal_ids = _load_internal_human_ids(conn)
    log.info(
        "Phase 3: %d address->human mappings, %d internal humans",
        len(email_to_human), len(internal_ids),
    )

    with conn.cursor() as cur:
        cur.execute(
            "SELECT thread_id FROM email_thread WHERE status = 'pending'"
        )
        pending = [row[0] for row in cur.fetchall()]
    log.info("Phase 3: %d pending threads", len(pending))

    if not pending:
        log.info("Phase 3: nothing to process")
        return

    # Rebuild data if not provided (standalone phase run)
    if addr_map is None:
        addr_map = _rebuild_addr_map(accounts)
    if thread_messages is None:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT message_id, thread_id FROM email_message "
                "WHERE thread_id IS NOT NULL"
            )
            thread_messages = {}
            for mid, tid in cur.fetchall():
                thread_messages.setdefault(tid, []).append(mid)

    def process_chunk(chunk: list[str]) -> tuple[int, int, int]:
        """Resolve a chunk of threads and write results to DB."""
        participant_rows: list[tuple] = []
        done_threads: list[str] = []
        error_threads: list[tuple[str, str]] = []

        for tid in chunk:
            msg_ids = thread_messages.get(tid, [])
            if not msg_ids:
                done_threads.append(tid)
                continue
            try:
                rows = _resolve_thread(
                    tid, msg_ids, addr_map, email_to_human, internal_ids,
                )
                participant_rows.extend(rows)
                done_threads.append(tid)
            except Exception as e:
                error_threads.append((tid, str(e)[:200]))

        wconn = db_connect()
        try:
            with wconn.cursor() as cur:
                if participant_rows:
                    psycopg2.extras.execute_values(
                        cur,
                        """INSERT INTO email_thread_participant
                               (thread_id, human_id, roles, first_seen_at)
                           VALUES %s
                           ON CONFLICT (thread_id, human_id) DO NOTHING""",
                        participant_rows,
                        page_size=BATCH_SIZE,
                    )
                now = int(time.time())
                if done_threads:
                    cur.execute(
                        "UPDATE email_thread "
                        "SET status = 'done', last_processed_at = %s "
                        "WHERE thread_id = ANY(%s)",
                        (now, done_threads),
                    )
                for tid, err_msg in error_threads:
                    cur.execute(
                        "UPDATE email_thread "
                        "SET status = 'error', error_message = %s "
                        "WHERE thread_id = %s",
                        (err_msg, tid),
                    )
            wconn.commit()
        finally:
            wconn.close()

        return len(participant_rows), len(done_threads), len(error_threads)

    # Partition into chunks, one per worker
    chunk_size = max(1, len(pending) // workers)
    chunks = [pending[i:i + chunk_size]
              for i in range(0, len(pending), chunk_size)]
    log.info("Phase 3: %d chunks across %d workers", len(chunks), workers)

    total_p, total_d, total_e = 0, 0, 0
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = [pool.submit(process_chunk, ch) for ch in chunks]
        for future in as_completed(futures):
            p, d, e = future.result()
            total_p += p
            total_d += d
            total_e += e

    log.info(
        "Phase 3 complete: %d participant rows, %d threads done, %d errors",
        total_p, total_d, total_e,
    )


# ---------------------------------------------------------------------------
# Wipe
# ---------------------------------------------------------------------------

def wipe_tables(conn):
    """Truncate email pipeline tables (single statement for FK safety)."""
    tables = [
        'email_thread_participant',
        'email_message',
        'email_thread',
        'email_source_coverage',
    ]
    with conn.cursor() as cur:
        for t in tables:
            cur.execute(f"SELECT count(*) FROM {t}")
            log.info("  %s: %d rows", t, cur.fetchone()[0])
        cur.execute("TRUNCATE " + ", ".join(tables))
    conn.commit()
    log.info("Truncated all email tables")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Thread-centric email harvest pipeline',
    )
    parser.add_argument(
        '--phase', choices=['1', '2', '3', 'all'], default='all',
        help='Run one phase or all (default: all)',
    )
    parser.add_argument(
        '--accounts', nargs='+', metavar='ACCT',
        help='Accounts to process (default: all active)',
    )
    parser.add_argument(
        '--limit', type=int, metavar='N',
        help='Phase 1: max N messages per account',
    )
    parser.add_argument(
        '--workers', type=int, default=4, metavar='N',
        help='Phase 3: worker threads (default: 4)',
    )
    parser.add_argument(
        '--wipe', action='store_true',
        help='Truncate email tables before running',
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s %(levelname)s %(message)s',
        datefmt='%H:%M:%S',
    )

    accounts = args.accounts or ACTIVE_ACCOUNTS
    conn = db_connect()

    if args.wipe:
        wipe_tables(conn)

    load_runtime_state(conn)

    phase = args.phase
    addr_map = None
    thread_messages = None
    t0 = time.time()

    if phase in ('1', 'all'):
        addr_map = phase1_harvest(accounts, args.limit)

    if phase in ('2', 'all'):
        thread_messages = phase2_thread_grouping(conn, accounts)

    if phase in ('3', 'all'):
        phase3_participant_resolution(
            conn, accounts, thread_messages, addr_map, args.workers,
        )

    elapsed = time.time() - t0
    log.info("Done in %.1fs", elapsed)
    conn.close()


if __name__ == '__main__':
    main()
