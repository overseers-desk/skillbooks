#!/usr/bin/env python3
"""
harvest_email.py

Email harvest and entity extraction pipeline for contact-graph.

Reads emails from the local mu/Maildir index, inserts header data into
email_message and item_participant, then calls `claude -p` per email to
extract named entities into item_entity.

Usage:
  python3 harvest_email.py                              # full run, all accounts
  python3 harvest_email.py --sample 200 --out /tmp/s   # 200 emails → JSON files, no DB
  python3 harvest_email.py --sample 50                  # 50 emails → DB
  python3 harvest_email.py --accounts director-rivermill-au  # one account only
  python3 harvest_email.py --dry-run                    # parse only, no DB or claude
"""

import argparse
import email as email_lib
import email.policy
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SCRIPT_DIR = Path(__file__).parent.resolve()
load_dotenv(SCRIPT_DIR / '.env')

DATABASE_URL = os.environ['DATABASE_URL']

ACCOUNTS = [
    'director-rivermill-au',
    'admin-rivermill-au',
    'me-weiwu-id-au',
    'yuliansu-gmail-com',
]

HEAD_STOP_AFTER = 3       # consecutive already-seen messages before ending head phase
DATE_MIN = 1
DATE_MAX = 4_102_444_800  # year 2100

RATE_LIMIT_WAIT = 900     # seconds to wait on credit exhaustion

MODEL = 'claude-haiku-4-5-20251001'

EXTRACTION_SYSTEM_PROMPT = """\
You are an entity extractor for a contact relationship graph system. Given an email \
(headers + body), extract named entities from the body text and output a single JSON object.

Output format:
{"entities": [{"type": "...", "value": "...", "context": "..."}]}

Entity types and rules:

person_mentioned — a real person named in the body who is NEITHER the sender NOR any \
recipient (addresses in FROM, TO, or CC). Exclude names that appear only in email \
signatures. Exclude generic role titles without a person's name. Exclude the email \
account owner if they appear as an addressee.

organisation — a company, agency, software platform, government department, or \
industry body explicitly named in the body. Skip if the organisation is the sender's \
own employer.

project — a named initiative, program, effort, or project referenced in the body.

product — a named physical or digital product, asset, or offering (e.g. a horse, \
a software feature, a menu item, a vehicle, a tour activity). Must be a proper name, \
not a generic description.

domain — activity classification of this email. Use only these exact values, include \
1-3 that best describe the main subject matter:
  operations, hr, safety, compliance, legal, finance, sales, marketing, \
product-development, procurement, governance, systems-technology, crisis-pr, \
external-relations, sop, product, events

Use crisis-pr only when the email is explicitly about managing a reputational threat \
or public crisis. Routine complaints or pending approvals are operations, not crisis-pr.

General rules:
- Only extract what is clearly stated in the body; do not infer or speculate.
- Skip content that is clearly CSS, HTML artifacts, code, or boilerplate text.
- context: a brief phrase explaining relevance, or null.
- Return {"entities": []} when nothing substantive applies.
- Output valid JSON only. No preamble, no explanation, no markdown fences.
"""

# ---------------------------------------------------------------------------
# Runtime state (loaded from DB at startup)
# ---------------------------------------------------------------------------

INTERNAL_ADDRESSES: set[str] = set()
IGNORED_DOMAINS: set[str] = set()
IGNORED_ADDRESSES: set[str] = set()
IGNORED_REGEXES: list[str] = []
IGNORED_SUBJECTS: list[str] = []


# ---------------------------------------------------------------------------
# DB helpers
# ---------------------------------------------------------------------------

def db_connect():
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False
    return conn


def load_runtime_state(conn):
    with conn.cursor() as cur:
        # Internal addresses
        cur.execute("""
            SELECT ea.address FROM email_address ea
            JOIN human h ON h.id = ea.human_id
            WHERE h.internal = TRUE
        """)
        for (addr,) in cur.fetchall():
            INTERNAL_ADDRESSES.add(addr.lower())

        # Ignored patterns
        cur.execute("SELECT pattern, pattern_type FROM ignored_pattern")
        for pattern, ptype in cur.fetchall():
            if ptype == 'domain':
                IGNORED_DOMAINS.add(pattern.lower())
            elif ptype == 'address':
                IGNORED_ADDRESSES.add(pattern.lower())
            elif ptype == 'regex':
                IGNORED_REGEXES.append(pattern)
            elif ptype == 'subject':
                IGNORED_SUBJECTS.append(pattern.lower())

    print(
        f"Loaded {len(INTERNAL_ADDRESSES)} internal addrs, "
        f"{len(IGNORED_DOMAINS)} ignored domains, "
        f"{len(IGNORED_ADDRESSES)} ignored addrs, "
        f"{len(IGNORED_REGEXES)} ignored regexes, "
        f"{len(IGNORED_SUBJECTS)} ignored subjects",
        flush=True,
    )


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
        try:
            if re.search(rx, a):
                return True
        except re.error:
            pass
    return False


def is_ignored_subject(subject: str) -> bool:
    if not subject:
        return False
    sl = subject.lower()
    return any(p in sl for p in IGNORED_SUBJECTS)


def msg_exists(cur, message_id: str) -> bool:
    cur.execute("SELECT 1 FROM email_message WHERE message_id = %s", (message_id,))
    return cur.fetchone() is not None


def get_coverage(cur, account: str) -> tuple:
    cur.execute("""
        SELECT newest_scanned_id, oldest_scanned_id FROM source_coverage
        WHERE source_kind = 'email' AND source_ref = %s
    """, (account,))
    row = cur.fetchone()
    return (row[0], row[1]) if row else (None, None)


def upsert_coverage(cur, account, newest_id, oldest_id):
    """
    Update coverage: newest_scanned_id is set once (first time only, since we scan
    head-first and the very first message of the very first run is the newest).
    oldest_scanned_id always advances toward older messages.
    """
    now = int(time.time())
    cur.execute("""
        INSERT INTO source_coverage
            (source_kind, source_ref, newest_scanned_id, oldest_scanned_id, last_checked_at)
        VALUES ('email', %s, %s, %s, %s)
        ON CONFLICT (source_kind, source_ref) DO UPDATE SET
            newest_scanned_id = COALESCE(source_coverage.newest_scanned_id,
                                         EXCLUDED.newest_scanned_id),
            oldest_scanned_id = EXCLUDED.oldest_scanned_id,
            last_checked_at   = EXCLUDED.last_checked_at
    """, (account, newest_id, oldest_id, now))


# ---------------------------------------------------------------------------
# mu query
# ---------------------------------------------------------------------------

def mu_query_account(account: str) -> list[dict]:
    """Return messages for account sorted newest-first."""
    cmd = ['mu', 'find', f'maildir:/{account}/*',
           '--format=json', '--sortfield=date', '--reverse']
    result = subprocess.run(cmd, capture_output=True, text=True, errors='replace', timeout=120)
    raw = result.stdout
    if not raw.strip() or raw.strip() == '[]':
        return []
    # Sanitise control characters that break JSON parsing
    clean = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', '', raw)
    try:
        return json.JSONDecoder(strict=False).decode(clean)
    except json.JSONDecodeError as exc:
        print(f"  Warning: JSON parse error for {account}: {exc}", flush=True)
        return []


def parse_addrs(field) -> list[tuple[str, str]]:
    """Parse a mu JSON address field → list of (email, display_name)."""
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
# Body extraction
# ---------------------------------------------------------------------------

def extract_body(path: str, max_chars: int = 1500) -> str:
    if not path:
        return ''
    try:
        with open(path, 'rb') as f:
            msg = email_lib.message_from_binary_file(f, policy=email.policy.default)
        # Prefer text/plain
        for part in msg.walk():
            if part.get_content_type() == 'text/plain':
                try:
                    payload = part.get_content()
                    if payload and payload.strip():
                        return payload[:max_chars]
                except Exception:
                    pass
        # Fall back to text/html
        for part in msg.walk():
            if part.get_content_type() == 'text/html':
                try:
                    payload = part.get_content()
                    if payload:
                        # Remove <style> and <script> blocks before tag stripping
                        text = re.sub(r'<(style|script)[^>]*>.*?</(style|script)>',
                                      ' ', payload, flags=re.DOTALL | re.IGNORECASE)
                        text = re.sub(r'<[^>]+>', ' ', text)
                        text = re.sub(r'\s+', ' ', text).strip()
                        return text[:max_chars]
                except Exception:
                    pass
    except Exception:
        pass
    return ''


# ---------------------------------------------------------------------------
# Claude entity extraction
# ---------------------------------------------------------------------------

class RateLimitError(Exception):
    pass


def run_extraction(subject: str, body: str, from_line: str, to_line: str) -> list[dict]:
    """
    Call `claude -p` and return list of {type, value, context} dicts.
    Returns [] on non-rate-limit failure.
    Raises RateLimitError when credit window is exhausted.
    """
    if not body.strip() and not subject.strip():
        return []

    user_prompt = f"FROM: {from_line}\nTO: {to_line}\nSUBJECT: {subject}\n\n{body}"
    # Strip null bytes — they are valid in email bodies but kill subprocess on Linux
    user_prompt = user_prompt.replace('\x00', '')

    cmd = [
        'claude', '-p',
        '--model', MODEL,
        '--output-format', 'json',
        '--system-prompt', EXTRACTION_SYSTEM_PROMPT,
        user_prompt,
    ]

    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        print("  Warning: claude timed out", flush=True)
        return []
    except ValueError as exc:
        print(f"  Warning: subprocess ValueError (null byte?): {exc}", flush=True)
        return []

    if proc.returncode != 0:
        err = (proc.stderr or '').lower()
        if any(x in err for x in ['rate limit', 'credit', 'quota', 'overload', 'usage limit',
                                   '429', 'too many']):
            raise RateLimitError(proc.stderr.strip()[:200])
        # Non-rate-limit error: log and skip
        print(f"  Warning: claude error (rc={proc.returncode}): {proc.stderr.strip()[:100]}",
              flush=True)
        return []

    # Parse the --output-format json envelope
    try:
        envelope = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return []

    if envelope.get('is_error'):
        msg = str(envelope).lower()
        if any(x in msg for x in ['rate limit', 'credit', 'quota', 'overload']):
            raise RateLimitError(str(envelope)[:200])
        return []

    result_text = (envelope.get('result') or '').strip()

    # Strip accidental markdown fences
    result_text = re.sub(r'^```(?:json)?\s*', '', result_text)
    result_text = re.sub(r'\s*```$', '', result_text.strip())

    try:
        parsed = json.loads(result_text)
    except json.JSONDecodeError:
        return []

    VALID_TYPES = {'person_mentioned', 'organisation', 'project', 'product', 'domain'}
    result = []
    for e in parsed.get('entities', []):
        if not isinstance(e, dict):
            continue
        if e.get('type') not in VALID_TYPES:
            continue
        val = e.get('value')
        # Normalise: model occasionally returns a list instead of a string
        if isinstance(val, list):
            val = ', '.join(str(v) for v in val if v)
        val = str(val).strip() if val is not None else ''
        if val:
            e['value'] = val
            result.append(e)
    return result


def extract_with_retry(subject, body, from_line, to_line) -> list[dict]:
    """Run extraction with indefinite rate-limit retry."""
    while True:
        try:
            return run_extraction(subject, body, from_line, to_line)
        except RateLimitError as exc:
            print(
                f"  [rate-limit] {str(exc)[:120]} "
                f"— waiting {RATE_LIMIT_WAIT}s before retry",
                flush=True,
            )
            time.sleep(RATE_LIMIT_WAIT)


# ---------------------------------------------------------------------------
# Process one message
# ---------------------------------------------------------------------------

def process_one(conn, msg: dict, account: str, dry_run: bool, out_dir: Path | None) -> str:
    """
    Process a single mu message dict.
    Returns: 'processed' | 'skipped:already-exists' | 'skipped:ignored-subject'
             | 'skipped:date-anomaly' | 'skipped:no-id'
    """
    message_id = (msg.get(':message-id') or '').strip()
    if not message_id:
        return 'skipped:no-id'

    subject = (msg.get(':subject') or '').strip()
    if is_ignored_subject(subject):
        return 'skipped:ignored-subject'

    date_unix = msg.get(':date-unix') or 0
    date_anomaly = not (DATE_MIN < date_unix < DATE_MAX)
    if date_anomaly:
        date_unix = 1

    path = msg.get(':path', '')
    from_addrs = parse_addrs(msg.get(':from'))
    to_addrs = parse_addrs(msg.get(':to'))
    cc_addrs = parse_addrs(msg.get(':cc'))

    with conn.cursor() as cur:
        if msg_exists(cur, message_id):
            return 'skipped:already-exists'

    from_line = ', '.join(f"{n} <{e}>" if n else e for e, n in from_addrs)
    to_line = ', '.join(
        f"{n} <{e}>" if n else e for e, n in (to_addrs + cc_addrs)
    )

    body = extract_body(path) if not dry_run else ''
    entities: list[dict] = []
    if not dry_run:
        entities = extract_with_retry(subject, body, from_line, to_line)

    if out_dir:
        safe_id = re.sub(r'[^\w@.=-]', '_', message_id)[:120]
        record = {
            'message_id': message_id,
            'account': account,
            'date_unix': date_unix,
            'subject': subject,
            'from': from_line,
            'to': to_line,
            'body_preview': body[:400],
            'entities': entities,
        }
        (out_dir / f"{safe_id}.json").write_text(
            json.dumps(record, indent=2, ensure_ascii=False)
        )

    if not dry_run and out_dir is None:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO email_message (message_id, account, date, subject, date_anomaly)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (message_id) DO NOTHING
            """, (message_id, account, date_unix, subject, date_anomaly))

            for addr, _ in from_addrs:
                if not is_ignored_address(addr):
                    cur.execute("""
                        INSERT INTO item_participant
                            (source_kind, external_item_id, identifier_ref, role)
                        VALUES ('email', %s, %s, 'from')
                        ON CONFLICT DO NOTHING
                    """, (message_id, addr))

            for addr, _ in to_addrs:
                if not is_ignored_address(addr):
                    cur.execute("""
                        INSERT INTO item_participant
                            (source_kind, external_item_id, identifier_ref, role)
                        VALUES ('email', %s, %s, 'to')
                        ON CONFLICT DO NOTHING
                    """, (message_id, addr))

            for addr, _ in cc_addrs:
                if not is_ignored_address(addr):
                    cur.execute("""
                        INSERT INTO item_participant
                            (source_kind, external_item_id, identifier_ref, role)
                        VALUES ('email', %s, %s, 'cc')
                        ON CONFLICT DO NOTHING
                    """, (message_id, addr))

            now = int(time.time())
            for ent in entities:
                etype = ent.get('type', '')
                value = (ent.get('value') or '').strip()
                context = ent.get('context') or None
                if etype and value:
                    cur.execute("""
                        INSERT INTO item_entity
                            (source_kind, external_item_id, entity_type, value,
                             context, extracted_at)
                        VALUES ('email', %s, %s, %s, %s, %s)
                        ON CONFLICT DO NOTHING
                    """, (message_id, etype, value, context, now))

        conn.commit()

    n_ents = len(entities)
    import datetime
    try:
        dt = datetime.datetime.fromtimestamp(date_unix).strftime('%Y-%m-%d')
    except Exception:
        dt = '????-??-??'
    mid_short = message_id[:40]
    subj_short = subject[:50]
    print(f"  [{account}] {dt}  {mid_short!r:44}  subj={subj_short!r:52}  entities={n_ents}",
          flush=True)

    return 'processed'


# ---------------------------------------------------------------------------
# Account scan (head + tail phases)
# ---------------------------------------------------------------------------

def scan_account(conn, account: str, dry_run: bool, out_dir: Path | None):
    """
    Scan one account: head phase (newest → 3 consecutive seen) then tail
    (continues processing everything older not yet seen).
    """
    print(f"\n=== {account} ===", flush=True)
    messages = mu_query_account(account)
    if not messages:
        print("  mu returned no messages", flush=True)
        return 0, 0

    print(f"  {len(messages)} messages loaded from mu", flush=True)

    with conn.cursor() as cur:
        _, oldest_cov = get_coverage(cur, account)
    has_history = oldest_cov is not None

    processed = 0
    skipped_seen = 0
    other_skipped = 0
    consecutive_seen = 0
    head_done = False
    newest_processed_id = None
    oldest_processed_id = None

    for msg in messages:
        msg_id = (msg.get(':message-id') or '').strip()
        if not msg_id:
            continue

        # HEAD PHASE: stop once we hit N consecutive already-seen messages
        # (only applicable once we have history — first run processes everything)
        if not head_done and has_history:
            with conn.cursor() as cur:
                already = msg_exists(cur, msg_id)
            if already:
                consecutive_seen += 1
                skipped_seen += 1
                if consecutive_seen >= HEAD_STOP_AFTER:
                    print(f"  Head phase complete ({consecutive_seen} consecutive seen)",
                          flush=True)
                    head_done = True
                    # Continue into tail phase — keep iterating the list
                continue
            else:
                consecutive_seen = 0

        status = process_one(conn, msg, account, dry_run, out_dir)

        if status == 'processed':
            processed += 1
            if newest_processed_id is None:
                newest_processed_id = msg_id
            oldest_processed_id = msg_id
        elif status == 'skipped:already-exists':
            skipped_seen += 1
        else:
            other_skipped += 1

    if not dry_run and out_dir is None and (newest_processed_id or oldest_processed_id):
        with conn.cursor() as cur:
            upsert_coverage(
                cur, account,
                newest_processed_id or oldest_cov,
                oldest_processed_id,
            )
        conn.commit()

    print(
        f"  processed={processed} skipped_seen={skipped_seen} other_skipped={other_skipped}",
        flush=True,
    )
    return processed, skipped_seen


# ---------------------------------------------------------------------------
# Sample mode (spread across accounts and date range)
# ---------------------------------------------------------------------------

def scan_sample(conn, accounts: list[str], n: int, dry_run: bool, out_dir: Path | None):
    """
    Process N messages spread evenly across accounts and across each account's date
    range (not just newest). Useful for prompt quality review.
    """
    per_account = max(1, n // len(accounts))
    total_processed = 0

    for account in accounts:
        print(f"\n=== {account} (sample={per_account}) ===", flush=True)
        messages = mu_query_account(account)
        if not messages:
            print("  mu returned no messages", flush=True)
            continue

        # Spread sample across time: thirds of the date-sorted list
        all_ids_paths = messages  # already newest-first
        total = len(all_ids_paths)
        print(f"  {total} messages loaded", flush=True)

        chunk = per_account // 3
        remainder = per_account - 3 * chunk
        if chunk > 0:
            indices = (
                list(range(0, min(chunk, total))) +
                list(range(max(0, total // 3), min(total // 3 + chunk, total))) +
                list(range(max(0, total - chunk - remainder), total))
            )
        else:
            indices = list(range(min(per_account, total)))

        seen_ids: set[str] = set()
        sample_msgs = []
        for i in indices:
            mid = (messages[i].get(':message-id') or '').strip()
            if mid and mid not in seen_ids:
                seen_ids.add(mid)
                sample_msgs.append(messages[i])

        print(f"  {len(sample_msgs)} sampled for processing", flush=True)

        for msg in sample_msgs:
            status = process_one(conn, msg, account, dry_run, out_dir)
            if status == 'processed':
                total_processed += 1

    print(f"\nSample run complete: {total_processed} processed", flush=True)
    return total_processed


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description='Email harvest and entity extraction')
    parser.add_argument('--sample', type=int, metavar='N',
                        help='Sample N emails across accounts (spread over date range)')
    parser.add_argument('--out', metavar='DIR',
                        help='Write extraction JSON files to DIR instead of DB')
    parser.add_argument('--dry-run', action='store_true',
                        help='No DB writes and no claude calls; parse headers only')
    parser.add_argument('--accounts', nargs='+', metavar='ACCT',
                        help='Restrict to specific accounts (default: all four)')
    args = parser.parse_args()

    accounts = args.accounts or ACCOUNTS
    out_dir = Path(args.out) if args.out else None
    if out_dir:
        out_dir.mkdir(parents=True, exist_ok=True)

    # out_dir mode: skip DB writes for entities/messages (still need DB for state checks)
    db_write = not args.dry_run and out_dir is None

    conn = db_connect()

    load_runtime_state(conn)

    run_id = None
    if db_write:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO harvest_run (started_at) VALUES (%s) RETURNING id",
                (int(time.time()),)
            )
            run_id = cur.fetchone()[0]
        conn.commit()
        print(f"Harvest run #{run_id} started", flush=True)

    total_processed = 0

    if args.sample:
        total_processed = scan_sample(conn, accounts, args.sample, args.dry_run, out_dir)
    else:
        for account in accounts:
            n, _ = scan_account(conn, account, args.dry_run, out_dir)
            total_processed += n

    if run_id:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE harvest_run SET completed_at=%s, items_processed=%s WHERE id=%s",
                (int(time.time()), total_processed, run_id),
            )
        conn.commit()
        print(f"\nHarvest run #{run_id} done: {total_processed} processed", flush=True)

    conn.close()
    print("Done.", flush=True)


if __name__ == '__main__':
    main()
