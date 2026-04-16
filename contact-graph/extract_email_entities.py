#!/usr/bin/env python3
"""
extract_email_entities.py — Budget-controlled AI entity extraction from email bodies.

Reads maildir files, strips quoted content, calls claude to extract named entities
(person_mentioned, organisation, project, product, domain), writes to item_entity.

Separate from harvest_email.py: this is the slow, expensive phase (hours/days)
vs the 30-second harvest pipeline.

Usage:
  python3 extract_email_entities.py                        # 4 workers, no limit
  python3 extract_email_entities.py --budget 5.00          # stop after ~$5
  python3 extract_email_entities.py --workers 8
  python3 extract_email_entities.py --limit 100            # max 100 messages
  python3 extract_email_entities.py --dry-run              # show queue, no calls
  python3 extract_email_entities.py --thread TID           # single thread (debug)
  python3 extract_email_entities.py --recompute-priority
"""

import argparse
import email
import email.policy
import json
import logging
import os
import re
import subprocess
import threading
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

BATCH_SIZE = 4
BODY_MAX_CHARS = 2000

# Haiku pricing (USD per million tokens)
PRICE_INPUT = 0.80
PRICE_OUTPUT = 4.00
PRICE_CACHE_WRITE = 1.00
PRICE_CACHE_READ = 0.08

log = logging.getLogger('extract')

# ---------------------------------------------------------------------------
# Extraction prompt
# ---------------------------------------------------------------------------

EXTRACTION_SYSTEM_PROMPT = """\
You are an entity extractor for a contact relationship graph system. Given an email \
(headers + body), classify it and extract named entities from the body text. \
Output a single JSON object.

Output format:
{"is_spam": false, "entities": [{"type": "...", "value": "...", "context": "..."}]}

First, set "is_spam" to true if this is an unsolicited bulk or marketing email: \
newsletters, promotional offers, mass mailings, automated service alerts \
(delivery notifications, account confirmations, billing notices from services), \
or any email that is not genuine personal or business correspondence between real people. \
If is_spam is true, return {"is_spam": true, "entities": []} — do not extract entities.

Entity types and rules (only for non-spam emails):

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
- Return {"is_spam": false, "entities": []} when nothing substantive applies.
- Output valid JSON only. No preamble, no explanation, no markdown fences.
"""

BATCH_SYSTEM_PROMPT = """\
You are an entity extractor for a contact relationship graph system. You will receive \
N emails separated by === Email N === markers. For each email, classify it and extract \
named entities. Return a JSON array of N objects.

Output format:
[{"is_spam": false, "entities": [...]}, {"is_spam": true, "entities": []}, ...]

First, set "is_spam" to true for each email that is an unsolicited bulk or marketing \
email: newsletters, promotional offers, mass mailings, automated service alerts \
(delivery notifications, account confirmations, billing notices), or any email that \
is not genuine personal or business correspondence between real people. \
If is_spam is true, return {"is_spam": true, "entities": []} for that email.

Entity types and rules (only for non-spam emails):

person_mentioned — a real person named in the body who is NEITHER the sender NOR any \
recipient (addresses in FROM, TO, or CC). Exclude names that appear only in email \
signatures. Exclude generic role titles without a person's name.

organisation — a company, agency, software platform, government department, or \
industry body explicitly named in the body.

project — a named initiative, program, effort, or project referenced in the body.

product — a named physical or digital product, asset, or offering. Must be a proper name.

domain — activity classification. Use only these exact values, 1-3 per email:
  operations, hr, safety, compliance, legal, finance, sales, marketing, \
product-development, procurement, governance, systems-technology, crisis-pr, \
external-relations, sop, product, events

General rules:
- Only extract what is clearly stated; do not infer or speculate.
- Skip CSS, HTML artifacts, code, or boilerplate.
- context: a brief phrase or null.
- Return {"is_spam": false, "entities": []} for non-spam emails with nothing substantive.
- Output valid JSON only. No preamble, no explanation, no markdown fences.
"""

VALID_ENTITY_TYPES = {
    'person_mentioned', 'organisation', 'project', 'product', 'domain',
}

# ---------------------------------------------------------------------------
# DB helpers
# ---------------------------------------------------------------------------

def db_connect():
    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False
    return conn


def ensure_tables_exist(conn):
    """Check that prerequisite tables exist."""
    with conn.cursor() as cur:
        for table in ('item_entity', 'email_extraction_log'):
            cur.execute(
                "SELECT 1 FROM information_schema.tables "
                "WHERE table_name = %s", (table,)
            )
            if not cur.fetchone():
                raise RuntimeError(
                    f"Table {table} does not exist. "
                    f"Apply schema.sql DDL before running extraction."
                )


# ---------------------------------------------------------------------------
# Path map from mu
# ---------------------------------------------------------------------------

def build_path_map(accounts: list[str]) -> dict[str, str]:
    """Query mu for message_id -> file_path mapping across all accounts."""
    query = ' OR '.join(f'maildir:/{a}/*' for a in accounts)
    base = ['mu', 'find', query, '--format=plain', '--skip-dups',
            '--sortfield=date', '--reverse']

    proc_i = subprocess.Popen(
        base + ['--fields=i'],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, errors='replace',
    )
    proc_l = subprocess.Popen(
        base + ['--fields=l'],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, errors='replace',
    )

    out_i, _ = proc_i.communicate(timeout=300)
    out_l, _ = proc_l.communicate(timeout=300)

    lines_i = [l for l in out_i.strip().split('\n') if l.strip()]
    lines_l = [l for l in out_l.strip().split('\n') if l.strip()]

    if len(lines_i) != len(lines_l):
        raise RuntimeError(
            f"mu field query mismatch: {len(lines_i)} message_ids "
            f"vs {len(lines_l)} paths"
        )

    path_map = {}
    for mid_line, path_line in zip(lines_i, lines_l):
        mid = mid_line.strip()
        path = path_line.strip()
        if mid and path:
            path_map[mid] = path

    log.info("Path map: %d message->path pairs from mu", len(path_map))
    return path_map


# ---------------------------------------------------------------------------
# Body extraction
# ---------------------------------------------------------------------------

def strip_quoted_plain(text: str) -> str:
    """Remove > prefixed lines (quoted content in plain text emails)."""
    lines = text.split('\n')
    out = []
    for line in lines:
        if line.lstrip().startswith('>'):
            continue
        out.append(line)
    return '\n'.join(out)


def strip_quoted_html(html: str) -> str:
    """Remove <blockquote> elements and their content from HTML."""
    return re.sub(
        r'<blockquote[^>]*>.*?</blockquote>',
        ' ', html, flags=re.DOTALL | re.IGNORECASE,
    )


def extract_body(path: str, max_chars: int = BODY_MAX_CHARS) -> str:
    """Read email file, extract body text, strip quoted content."""
    if not path:
        return ''
    try:
        with open(path, 'rb') as f:
            msg = email.message_from_binary_file(f, policy=email.policy.default)
    except Exception:
        return ''

    # Prefer text/plain
    for part in msg.walk():
        if part.get_content_type() == 'text/plain':
            try:
                payload = part.get_content()
                if payload and payload.strip():
                    text = strip_quoted_plain(payload)
                    text = text.replace('\x00', '')
                    text = text.strip()
                    if text:
                        return text[:max_chars]
            except Exception:
                pass

    # Fall back to text/html
    for part in msg.walk():
        if part.get_content_type() == 'text/html':
            try:
                payload = part.get_content()
                if payload:
                    text = strip_quoted_html(payload)
                    text = re.sub(
                        r'<(style|script)[^>]*>.*?</(style|script)>',
                        ' ', text, flags=re.DOTALL | re.IGNORECASE,
                    )
                    text = re.sub(r'<[^>]+>', ' ', text)
                    text = re.sub(r'\s+', ' ', text).strip()
                    text = text.replace('\x00', '')
                    if text:
                        return text[:max_chars]
            except Exception:
                pass

    return ''


# ---------------------------------------------------------------------------
# Work queue
# ---------------------------------------------------------------------------

def build_work_queue(
    conn,
    limit: int | None = None,
    thread_id: str | None = None,
) -> list[tuple[str, list[str]]]:
    """Return [(thread_id, [unextracted_message_ids])] ordered by priority."""
    with conn.cursor() as cur:
        if thread_id:
            cur.execute(
                "SELECT %s WHERE EXISTS ("
                "  SELECT 1 FROM email_thread WHERE thread_id = %s"
                ")", (thread_id, thread_id),
            )
            thread_ids = [row[0] for row in cur.fetchall()]
        else:
            q = """
                SELECT et.thread_id
                FROM email_thread et
                WHERE EXISTS (
                    SELECT 1 FROM email_message em
                    WHERE em.thread_id = et.thread_id
                      AND NOT EXISTS (
                          SELECT 1 FROM email_extraction_log el
                          WHERE el.message_id = em.message_id
                      )
                )
                ORDER BY et.priority_score DESC, et.last_message_at DESC
            """
            if limit:
                # Limit threads, not messages — but approximate
                q += f" LIMIT {limit}"
            cur.execute(q)
            thread_ids = [row[0] for row in cur.fetchall()]

        if not thread_ids:
            return []

        # Load unextracted message_ids per thread
        cur.execute("""
            SELECT em.message_id, em.thread_id
            FROM email_message em
            WHERE em.thread_id = ANY(%s)
              AND NOT EXISTS (
                  SELECT 1 FROM email_extraction_log el
                  WHERE el.message_id = em.message_id
              )
        """, (thread_ids,))

        thread_msgs: dict[str, list[str]] = {}
        for mid, tid in cur.fetchall():
            thread_msgs.setdefault(tid, []).append(mid)

    # Preserve priority order from thread_ids
    result = [(tid, thread_msgs[tid]) for tid in thread_ids if tid in thread_msgs]
    total_msgs = sum(len(mids) for _, mids in result)
    log.info("Work queue: %d threads, %d messages", len(result), total_msgs)
    return result


def compute_priority_scores(conn):
    """Update email_thread.priority_score based on known-human participants."""
    with conn.cursor() as cur:
        cur.execute("""
            UPDATE email_thread et SET priority_score = sub.score FROM (
                SELECT etp.thread_id, COUNT(DISTINCT etp.human_id)::float AS score
                FROM email_thread_participant etp
                JOIN human h ON h.id = etp.human_id
                WHERE h.notes IS DISTINCT FROM 'corpus-derived' OR h.internal = TRUE
                GROUP BY etp.thread_id
            ) sub WHERE et.thread_id = sub.thread_id
        """)
        updated = cur.rowcount
    conn.commit()
    log.info("Priority scores updated for %d threads", updated)


# ---------------------------------------------------------------------------
# Budget tracker
# ---------------------------------------------------------------------------

class BudgetTracker:
    def __init__(
        self,
        max_dollars: float | None = None,
        max_messages: int | None = None,
    ):
        self.max_dollars = max_dollars
        self.max_messages = max_messages
        self.total_tokens_in = 0
        self.total_tokens_out = 0
        self.messages_processed = 0
        self._lock = threading.Lock()

    def record(self, tokens_in: int, tokens_out: int, n_messages: int):
        with self._lock:
            self.total_tokens_in += tokens_in
            self.total_tokens_out += tokens_out
            self.messages_processed += n_messages

    def estimated_cost(self) -> float:
        return (
            self.total_tokens_in * PRICE_INPUT
            + self.total_tokens_out * PRICE_OUTPUT
        ) / 1_000_000

    def can_proceed(self) -> bool:
        with self._lock:
            if self.max_dollars is not None and self.estimated_cost() >= self.max_dollars:
                return False
            if self.max_messages is not None and self.messages_processed >= self.max_messages:
                return False
            return True


# ---------------------------------------------------------------------------
# Claude extraction call
# ---------------------------------------------------------------------------

class RateLimitError(Exception):
    pass


def _parse_extraction_result(raw_result: str) -> tuple[list[dict], bool]:
    """Parse a single extraction result. Returns (entities, is_spam)."""
    text = raw_result.strip()
    # Strip markdown fences
    if text.startswith('```'):
        lines = text.split('\n')
        lines = lines[1:]  # remove opening fence
        if lines and lines[-1].strip() == '```':
            lines = lines[:-1]
        text = '\n'.join(lines)

    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return [], False

    if isinstance(data, dict):
        is_spam = bool(data.get('is_spam', False))
        if is_spam:
            return [], True
        raw_entities = data.get('entities', [])
    elif isinstance(data, list):
        is_spam = False
        raw_entities = data
    else:
        return [], False

    entities = []
    for ent in raw_entities:
        if not isinstance(ent, dict):
            continue
        etype = ent.get('type', '')
        value = ent.get('value', '')
        if etype not in VALID_ENTITY_TYPES:
            continue
        if not value:
            continue
        # Value can be string or list
        if isinstance(value, list):
            for v in value:
                if isinstance(v, str) and v.strip():
                    entities.append({
                        'type': etype,
                        'value': v.strip(),
                        'context': ent.get('context'),
                    })
        elif isinstance(value, str):
            entities.append({
                'type': etype,
                'value': value.strip(),
                'context': ent.get('context'),
            })

    return entities, False


def _parse_batch_result(raw_result: str, n: int) -> list[tuple[list[dict], bool]] | None:
    """Parse a batch extraction result. Returns list of (entities, is_spam) or None on failure."""
    text = raw_result.strip()
    if text.startswith('```'):
        lines = text.split('\n')
        lines = lines[1:]
        if lines and lines[-1].strip() == '```':
            lines = lines[:-1]
        text = '\n'.join(lines)

    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return None  # signal parse failure

    if not isinstance(data, list) or len(data) != n:
        return None  # length mismatch

    results = []
    for item in data:
        if isinstance(item, dict):
            results.append(_parse_extraction_result(json.dumps(item)))
        else:
            results.append(([], False))

    return results


def call_claude_extract(
    messages: list[dict],
    rate_event: threading.Event,
    backoff_state: dict,
) -> tuple[list[tuple[list[dict], bool]], int, int]:
    """Call claude -p for entity extraction.

    Returns (results, tokens_in, tokens_out) where results is a list of
    (entities, is_spam) tuples, one per message.
    Each message dict has keys: message_id, subject, body, from_line, to_line.
    """
    n = len(messages)
    timeout = 60 + 30 * n

    if n == 1:
        system_prompt = EXTRACTION_SYSTEM_PROMPT
        m = messages[0]
        user_prompt = (
            f"FROM: {m['from_line']}\n"
            f"TO: {m['to_line']}\n"
            f"SUBJECT: {m['subject']}\n\n"
            f"{m['body']}"
        )
    else:
        system_prompt = BATCH_SYSTEM_PROMPT
        parts = []
        for i, m in enumerate(messages, 1):
            parts.append(
                f"=== Email {i} ===\n"
                f"FROM: {m['from_line']}\n"
                f"TO: {m['to_line']}\n"
                f"SUBJECT: {m['subject']}\n\n"
                f"{m['body']}"
            )
        user_prompt = '\n\n'.join(parts)

    # Strip null bytes
    user_prompt = user_prompt.replace('\x00', '')

    cmd = [
        'claude', '-p',
        '--model', 'claude-haiku-4-5-20251001',
        '--output-format', 'json',
        '--system-prompt', system_prompt,
        user_prompt,
    ]

    try:
        proc = subprocess.run(
            cmd, capture_output=True, text=True,
            errors='replace', timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        log.warning("Claude call timed out after %ds for %d messages", timeout, n)
        return [([], False) for _ in range(n)], 0, 0

    # Parse the JSON envelope
    tokens_in, tokens_out = 0, 0
    try:
        envelope = json.loads(proc.stdout)
    except json.JSONDecodeError:
        log.warning("Failed to parse claude JSON envelope")
        return [([], False) for _ in range(n)], 0, 0

    # Check for rate limit
    if envelope.get('is_error'):
        result_text = envelope.get('result', '')
        if 'rate' in result_text.lower() or 'limit' in result_text.lower():
            raise RateLimitError(result_text[:200])
        log.warning("Claude error: %s", result_text[:200])
        return [([], False) for _ in range(n)], 0, 0

    # Extract token usage
    usage = envelope.get('usage', {})
    tokens_in = (
        usage.get('input_tokens', 0)
        + usage.get('cache_creation_input_tokens', 0)
        + usage.get('cache_read_input_tokens', 0)
    )
    tokens_out = usage.get('output_tokens', 0)

    raw_result = envelope.get('result', '')
    if not raw_result:
        return [([], False) for _ in range(n)], tokens_in, tokens_out

    # Parse extraction results
    if n == 1:
        result = _parse_extraction_result(raw_result)
        return [result], tokens_in, tokens_out
    else:
        batch_result = _parse_batch_result(raw_result, n)
        if batch_result is not None:
            return batch_result, tokens_in, tokens_out
        # Fallback: return empty on parse failure
        log.warning(
            "Batch parse failed for %d messages, falling back to empty",
            n,
        )
        return [([], False) for _ in range(n)], tokens_in, tokens_out


# ---------------------------------------------------------------------------
# Rate-limit handling
# ---------------------------------------------------------------------------

def handle_rate_limit(rate_event: threading.Event, backoff_state: dict):
    """Block all workers via shared event, exponential backoff."""
    with backoff_state['lock']:
        if rate_event.is_set():
            # Another thread already handling it; just wait
            rate_event.wait()
            return

        rate_event.set()
        wait = backoff_state.get('next_wait', 60)
        log.warning("Rate limit hit. All workers pausing for %ds", wait)

    time.sleep(wait)

    with backoff_state['lock']:
        backoff_state['next_wait'] = min(wait * 2, 900)
        rate_event.clear()


def reset_backoff(backoff_state: dict):
    """Reset backoff after a successful call."""
    with backoff_state['lock']:
        backoff_state['next_wait'] = 60


# ---------------------------------------------------------------------------
# Thread worker
# ---------------------------------------------------------------------------

def process_thread(
    thread_id: str,
    message_ids: list[str],
    path_map: dict[str, str],
    budget: BudgetTracker,
    rate_event: threading.Event,
    backoff_state: dict,
    dry_run: bool = False,
) -> dict:
    """Process one thread: advisory lock, extract bodies, call claude, write results."""
    stats = {'processed': 0, 'empty': 0, 'error': 0, 'entities': 0, 'skipped_lock': 0, 'spam': 0}

    conn = db_connect()
    try:
        # Acquire advisory lock
        with conn.cursor() as cur:
            cur.execute(
                "SELECT pg_try_advisory_lock(hashtext(%s))", (thread_id,)
            )
            acquired = cur.fetchone()[0]

        if not acquired:
            stats['skipped_lock'] = 1
            log.debug("Thread %s locked by another worker, skipping", thread_id[:20])
            return stats

        try:
            # Filter to unextracted messages (handles partial resume)
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT message_id FROM email_extraction_log "
                    "WHERE message_id = ANY(%s)",
                    (message_ids,),
                )
                already_done = {row[0] for row in cur.fetchall()}

            remaining = [mid for mid in message_ids if mid not in already_done]
            if not remaining:
                return stats

            # Load headers for context (subject, from, to)
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT message_id, subject FROM email_message "
                    "WHERE message_id = ANY(%s)",
                    (remaining,),
                )
                msg_subjects = dict(cur.fetchall())

            # Extract bodies
            to_extract = []
            now = int(time.time())

            for mid in remaining:
                path = path_map.get(mid)
                body = extract_body(path) if path else ''

                if not body.strip():
                    stats['empty'] += 1
                    if not dry_run:
                        with conn.cursor() as cur:
                            cur.execute(
                                "INSERT INTO email_extraction_log "
                                "(message_id, status, extracted_at) "
                                "VALUES (%s, 'empty', %s) "
                                "ON CONFLICT (message_id) DO NOTHING",
                                (mid, now),
                            )
                        conn.commit()
                    continue

                to_extract.append({
                    'message_id': mid,
                    'subject': msg_subjects.get(mid, ''),
                    'body': body,
                    'from_line': '',  # Not stored in DB; omit for now
                    'to_line': '',
                })

            if dry_run:
                log.info(
                    "DRY RUN thread %s: %d extractable, %d empty",
                    thread_id[:20], len(to_extract), stats['empty'],
                )
                stats['processed'] = len(to_extract)
                return stats

            # Batch and extract
            for i in range(0, len(to_extract), BATCH_SIZE):
                if not budget.can_proceed():
                    log.info("Budget exhausted, stopping mid-thread")
                    break

                # Wait if rate limited
                if rate_event.is_set():
                    rate_event.wait()

                batch = to_extract[i:i + BATCH_SIZE]
                try:
                    results, tok_in, tok_out = call_claude_extract(
                        batch, rate_event, backoff_state,
                    )
                    reset_backoff(backoff_state)
                except RateLimitError:
                    handle_rate_limit(rate_event, backoff_state)
                    # Retry this batch once after backoff
                    try:
                        results, tok_in, tok_out = call_claude_extract(
                            batch, rate_event, backoff_state,
                        )
                        reset_backoff(backoff_state)
                    except RateLimitError:
                        log.error("Rate limit persists after backoff, marking batch as error")
                        for m in batch:
                            with conn.cursor() as cur:
                                cur.execute(
                                    "INSERT INTO email_extraction_log "
                                    "(message_id, status, extracted_at, error_detail) "
                                    "VALUES (%s, 'error', %s, %s) "
                                    "ON CONFLICT (message_id) DO NOTHING",
                                    (m['message_id'], int(time.time()),
                                     'rate_limit_persistent'),
                                )
                            conn.commit()
                            stats['error'] += 1
                        continue

                budget.record(tok_in, tok_out, len(batch))

                # Write results
                now = int(time.time())
                with conn.cursor() as cur:
                    for msg, (entities, is_spam) in zip(batch, results):
                        mid = msg['message_id']
                        tok_in_per = tok_in // len(batch)
                        tok_out_per = tok_out // len(batch)

                        if is_spam:
                            cur.execute(
                                "UPDATE email_message SET is_spam = TRUE "
                                "WHERE message_id = %s",
                                (mid,),
                            )
                            status = 'skipped'
                            stats['spam'] += 1
                        elif entities:
                            for ent in entities:
                                cur.execute(
                                    "INSERT INTO item_entity "
                                    "(source_kind, external_item_id, entity_type, "
                                    " value, context, extracted_at) "
                                    "VALUES ('email', %s, %s, %s, %s, %s) "
                                    "ON CONFLICT (source_kind, external_item_id, "
                                    "            entity_type, value) "
                                    "DO NOTHING",
                                    (mid, ent['type'], ent['value'],
                                     ent.get('context'), now),
                                )
                            status = 'done'
                            stats['entities'] += len(entities)
                        else:
                            status = 'empty'

                        cur.execute(
                            "INSERT INTO email_extraction_log "
                            "(message_id, status, extracted_at, tokens_in, tokens_out) "
                            "VALUES (%s, %s, %s, %s, %s) "
                            "ON CONFLICT (message_id) DO NOTHING",
                            (mid, status, now, tok_in_per, tok_out_per),
                        )
                        stats['processed'] += 1
                        if status == 'empty':
                            stats['empty'] += 1

                conn.commit()

        finally:
            # Release advisory lock
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT pg_advisory_unlock(hashtext(%s))", (thread_id,)
                )
            conn.commit()

    finally:
        conn.close()

    return stats


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Budget-controlled AI entity extraction from email bodies',
    )
    parser.add_argument(
        '--budget', type=float, metavar='USD',
        help='Stop after estimated spend reaches this amount',
    )
    parser.add_argument(
        '--limit', type=int, metavar='N',
        help='Max threads to process',
    )
    parser.add_argument(
        '--workers', type=int, default=4, metavar='N',
        help='Concurrent worker threads (default: 4)',
    )
    parser.add_argument(
        '--thread', metavar='THREAD_ID',
        help='Process a single thread (for debugging)',
    )
    parser.add_argument(
        '--dry-run', action='store_true',
        help='Show queue and extract bodies, but no claude calls or DB writes',
    )
    parser.add_argument(
        '--recompute-priority', action='store_true',
        help='Recompute thread priority scores before extraction',
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s %(levelname)s %(message)s',
        datefmt='%H:%M:%S',
    )

    conn = db_connect()
    ensure_tables_exist(conn)

    if args.recompute_priority:
        compute_priority_scores(conn)

    log.info("Building path map from mu...")
    path_map = build_path_map(ACTIVE_ACCOUNTS)

    queue = build_work_queue(conn, limit=args.limit, thread_id=args.thread)
    if not queue:
        log.info("Nothing to process")
        conn.close()
        return

    budget = BudgetTracker(max_dollars=args.budget)
    rate_event = threading.Event()
    backoff_state = {'next_wait': 60, 'lock': threading.Lock()}

    totals = {
        'processed': 0, 'empty': 0, 'error': 0,
        'spam': 0, 'entities': 0, 'skipped_lock': 0, 'threads': 0,
    }
    totals_lock = threading.Lock()
    t0 = time.time()

    def worker(thread_id: str, message_ids: list[str]):
        if not budget.can_proceed():
            return
        result = process_thread(
            thread_id, message_ids, path_map, budget,
            rate_event, backoff_state, dry_run=args.dry_run,
        )
        with totals_lock:
            for k in result:
                totals[k] = totals.get(k, 0) + result[k]
            totals['threads'] += 1

    workers = 1 if args.thread else args.workers
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {}
        for thread_id, message_ids in queue:
            if not budget.can_proceed():
                break
            f = pool.submit(worker, thread_id, message_ids)
            futures[f] = thread_id

        for future in as_completed(futures):
            tid = futures[future]
            try:
                future.result()
            except Exception:
                log.exception("Worker failed on thread %s", tid[:20])

    elapsed = time.time() - t0
    log.info(
        "Done in %.1fs: %d threads, %d messages processed, %d empty, "
        "%d spam, %d errors, %d entities, %d lock-skipped, ~$%.4f estimated spend",
        elapsed, totals['threads'], totals['processed'], totals['empty'],
        totals['spam'], totals['error'], totals['entities'], totals['skipped_lock'],
        budget.estimated_cost(),
    )
    conn.close()


if __name__ == '__main__':
    main()
