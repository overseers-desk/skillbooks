#!/usr/bin/env python3
"""
resolve_candidates.py

Resolves email_address_candidate rows into the permanent email_address and
human tables. Run once after the staging table is populated; safe to re-run
(idempotent where possible).

Phases:
  0  Seed ignored_pattern (if empty)
  1  Prune candidates (already resolved / ignore patterns / self-addresses)
  2  Display name enrichment via mu/Xapian (up to 200 blanks)
  3  Display name clustering → match existing humans / auto-create personal
  4  Domain ownership rules
  5  Insert into email_address (ON CONFLICT DO NOTHING)
  6  Correct Aiqin Li address spelling
  7  Report

Usage:
  python3 resolve_candidates.py [--dry-run]

With --dry-run no writes are committed; report is still printed.
"""

import os
import re
import sys
import subprocess
import unicodedata
from pathlib import Path
from collections import defaultdict

import psycopg2
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SCRIPT_DIR = Path(__file__).parent.resolve()
load_dotenv(SCRIPT_DIR / '.env')

DATABASE_URL = os.environ['DATABASE_URL']
SEED_SQL = SCRIPT_DIR / 'ignored_pattern_seed.sql'

MU_ENRICH_CAP = 200   # max Xapian calls in Phase 2
DRY_RUN = '--dry-run' in sys.argv

# Self-addresses (source-email.md § 5) — excluded from graph
SELF_ADDRESSES = {
    'zhangweiwu@realss.com',
    'a@colourful.land',
    'director@rivermill.au',
    'me@weiwu.au',
    'me@weiwu.eu',
    'me@weiwu.id.au',
    'amanuensis@weiwu.au',
    'w@smarttokenlabs.com',
    'weiwu.zhang@alphawallet.com',
    'weiwu.zhang@awallet.io',
    'zhangweiwu@yahoo.com',
    'zhangweiwu@private.21cn.com',
    'yuliansu@gmail.com',
}

# Corporate-name signals for Phase 3 filtering
CORPORATE_TOKENS = {
    'team', 'support', 'billing', 'alert', 'alerts', 'newsletter', 'newsletters',
    'system', 'noreply', 'no-reply', 'notification', 'notifications', 'service',
    'services', 'mailer', 'admin', 'info', 'hello', 'contact', 'sales',
    'help', 'helpdesk', 'news', 'marketing', 'offers', 'updates', 'mail',
    'office', 'accounts', 'finance', 'legal', 'hr', 'recruitment', 'careers',
    'feedback', 'reply', 'do-not-reply',
    # Institutional / org types
    'school', 'college', 'university', 'institute', 'foundation', 'association',
    'society', 'council', 'government', 'department', 'ministry', 'agency',
    'charity', 'trust', 'committee', 'group', 'clinic', 'hospital', 'centre',
    'center', 'academy', 'saddlery', 'care', 'press', 'media', 'digital',
    'technologies', 'solutions', 'consulting', 'management', 'international',
    'global', 'national', 'enterprises', 'roadshow', 'enquiries', 'enquiry',
    'submissions', 'submission', 'historic', 'vision', 'anonymous', 'anonymous',
}

# Domain → human_id mapping for Phase 4
# Weiwu (id=1), Liansu (id=2)
DOMAIN_OWNERSHIP = [
    # Pattern, owner_human_id, note
    (r'\.weiwu\.au$',      1, 'weiwu.au subdomain'),
    (r'\.weiwu\.eu$',      1, 'weiwu.eu subdomain'),
    (r'\.weiwu\.id\.au$',  1, 'weiwu.id.au subdomain'),
    (r'^weiwu\.au$',       1, 'weiwu.au apex'),
    (r'^weiwu\.eu$',       1, 'weiwu.eu apex'),
    (r'^weiwu\.id\.au$',   1, 'weiwu.id.au apex'),
]

# realss.com display name → known human_id
REALSS_NAMES = {
    'weiwu': 1,
    'weiwu zhang': 1,
    'zhang weiwu': 1,
    'liansu': 2,
    'yu liansu': 2,
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def log(msg):
    print(msg, flush=True)


def normalize_name(name: str) -> str:
    """Lowercase, strip punctuation, sort tokens — 'Weiwu Zhang' == 'Zhang Weiwu'."""
    name = unicodedata.normalize('NFC', name).lower()
    name = re.sub(r"[^\w\s'-]", ' ', name)
    tokens = sorted(t for t in name.split() if t)
    return ' '.join(tokens)


def is_corporate_name(name: str) -> bool:
    """Return True if the name looks like an org/brand rather than a person."""
    tokens = name.lower().split()
    if not tokens:
        return True
    # Single token — likely a brand
    if len(tokens) == 1:
        return True
    # Too many tokens — likely a phrase, not a person
    if len(tokens) > 4:
        return True
    # Contains a dot — looks like a domain or abbreviation
    if any('.' in t for t in tokens):
        return True
    # Contains a corporate signal token
    if any(t in CORPORATE_TOKENS for t in tokens):
        return True
    # Contains a digit — serial/ID in the name
    if any(re.search(r'\d', t) for t in tokens):
        return True
    # Contains relay/attribution particles — mailing list or brand artifact
    # ("Joseph Wang via hyperledger-…", "Crashlytics by Fabric", "Wyatt from Alts")
    if any(t in ('via', 'by', 'from', 'at') for t in tokens):
        return True
    # Contains parentheses — business with location qualifier ("Sydney Smile Care (Burwood)")
    if '(' in name or ')' in name:
        return True
    # All-uppercase token that isn't an initial — org abbreviation (e.g. "PCYC")
    if any(len(t) > 2 and t.upper() == t for t in name.split()):
        return True
    # Starts with "The " — publication or organisation ("The Daily Upside")
    if tokens and tokens[0] == 'the' and len(tokens) > 1:
        return True
    return False


def mu_enrich(addr: str) -> str:
    """Query mu for a display name for addr. Returns '' on failure."""
    try:
        result = subprocess.run(
            ['mu', 'find', f'contact:{addr}', '--fields', 'f'],
            capture_output=True, text=True, timeout=10
        )
        name_re = re.compile(r'^(.*?)\s*<[^>]+>\s*$')
        for line in result.stdout.splitlines():
            line = line.strip()
            if addr.lower() not in line.lower():
                continue
            m = name_re.match(line)
            if m:
                candidate = m.group(1).strip().strip('"').strip("'")
                if candidate and not re.search(r'[@<>]', candidate):
                    return candidate
    except Exception:
        pass
    return ''


def domain_of(addr: str) -> str:
    parts = addr.rsplit('@', 1)
    return parts[1].lower() if len(parts) == 2 else ''


# ---------------------------------------------------------------------------
# Phase 0 — Seed ignored_pattern
# ---------------------------------------------------------------------------

def phase0_seed(cur):
    cur.execute("SELECT COUNT(*) FROM ignored_pattern")
    count = cur.fetchone()[0]
    if count > 0:
        log(f"Phase 0: ignored_pattern already has {count} rows — skipping seed")
        return
    log("Phase 0: seeding ignored_pattern …")
    env = {
        **os.environ,
        'PGPASSWORD': os.environ.get('PGPASSWORD', ''),
    }
    subprocess.run(
        [
            'psql',
            '-h', os.environ.get('PGHOST', 'localhost'),
            '-p', os.environ.get('PGPORT', '5432'),
            '-U', os.environ.get('PGUSER', 'aesop'),
            '-d', os.environ.get('PGDATABASE', 'contact_graph'),
            '-f', str(SEED_SQL),
        ],
        env=env, check=True, capture_output=True,
    )
    cur.execute("SELECT COUNT(*) FROM ignored_pattern")
    count = cur.fetchone()[0]
    log(f"Phase 0: seeded {count} ignored_pattern rows")


# ---------------------------------------------------------------------------
# Phase 1 — Prune candidates
# ---------------------------------------------------------------------------

def _strip_plus_tag(addr: str) -> str:
    """foo+tag@domain → foo@domain.
    Only strips when the local part before + is a normal identifier
    (letters/digits/dots/dashes/underscores). Quoted local parts and
    addresses where the local part is not a clean identifier are returned
    unchanged.
    """
    m = re.match(r'^([a-zA-Z0-9._-]+)\+[^@]+(@.+)$', addr)
    return (m.group(1) + m.group(2)) if m else addr


def phase1_prune(cur):
    log("Phase 1: pruning candidates …")

    # 1a. Already in email_address
    cur.execute("""
        DELETE FROM email_address_candidate
        WHERE address IN (SELECT address FROM email_address)
    """)
    log(f"  1a already-resolved:   -{cur.rowcount}")

    # 1b. Self-addresses
    placeholders = ','.join(['%s'] * len(SELF_ADDRESSES))
    cur.execute(
        f"DELETE FROM email_address_candidate WHERE address IN ({placeholders})",
        list(SELF_ADDRESSES)
    )
    log(f"  1b self-addresses:     -{cur.rowcount}")

    # 1c. Plus-tag normalisation: foo+tag@domain → foo@domain
    #     Runs before ignore-pattern pruning so normalised forms
    #     (e.g. bounces@zohoforms.com.au) become prunable.
    cur.execute("SELECT address, display_name FROM email_address_candidate")
    tagged_rows = [(a, d) for a, d in cur.fetchall() if _strip_plus_tag(a) != a]
    renamed = merged_perm = merged_cand = 0
    for addr, disp in tagged_rows:
        base = _strip_plus_tag(addr)
        # Base is a self-address → delete
        if base in SELF_ADDRESSES:
            cur.execute("DELETE FROM email_address_candidate WHERE address = %s", (addr,))
            merged_perm += 1
            continue
        # Base already in permanent table → delete tagged candidate
        cur.execute("SELECT 1 FROM email_address WHERE address = %s", (base,))
        if cur.fetchone():
            cur.execute("DELETE FROM email_address_candidate WHERE address = %s", (addr,))
            merged_perm += 1
            continue
        # Base already in candidate table → merge display name, delete tagged
        cur.execute("SELECT display_name FROM email_address_candidate WHERE address = %s", (base,))
        row = cur.fetchone()
        if row:
            if not row[0] and disp:
                cur.execute(
                    "UPDATE email_address_candidate SET display_name = %s WHERE address = %s",
                    (disp, base)
                )
            cur.execute("DELETE FROM email_address_candidate WHERE address = %s", (addr,))
            merged_cand += 1
        else:
            # Base not seen anywhere — rename tagged to base
            cur.execute(
                "UPDATE email_address_candidate SET address = %s WHERE address = %s",
                (base, addr)
            )
            renamed += 1
    log(f"  1c plus-tag renamed:   {renamed}")
    log(f"  1c plus-tag merged:    {merged_perm + merged_cand} ({merged_perm} into perm, {merged_cand} into cand)")

    # 1d. Ignore patterns
    cur.execute("SELECT pattern, pattern_type FROM ignored_pattern WHERE pattern_type != 'subject'")
    patterns = cur.fetchall()
    deleted_by_type = defaultdict(int)
    for pattern, ptype in patterns:
        if ptype == 'address':
            cur.execute(
                "DELETE FROM email_address_candidate WHERE lower(address) = lower(%s)",
                (pattern,)
            )
        elif ptype == 'domain':
            cur.execute(
                """
                DELETE FROM email_address_candidate
                WHERE SUBSTRING(address FROM '@(.+)$') = %s
                   OR SUBSTRING(address FROM '@(.+)$') LIKE '%%.' || %s
                """,
                (pattern, pattern)
            )
        elif ptype == 'regex':
            cur.execute(
                "DELETE FROM email_address_candidate WHERE address ~ %s",
                (pattern,)
            )
        deleted_by_type[ptype] += cur.rowcount
    for ptype, n in sorted(deleted_by_type.items()):
        log(f"  1d ignored ({ptype:8s}): -{n}")

    cur.execute("SELECT COUNT(*) FROM email_address_candidate")
    log(f"  → {cur.fetchone()[0]} candidates remaining")


# ---------------------------------------------------------------------------
# Phase 2 — Display name enrichment via Xapian
# ---------------------------------------------------------------------------

def phase2_enrich(cur):
    log("Phase 2: Xapian display name enrichment …")
    cur.execute(
        "SELECT address FROM email_address_candidate WHERE display_name = '' LIMIT %s",
        (MU_ENRICH_CAP,)
    )
    rows = cur.fetchall()
    enriched = 0
    for (addr,) in rows:
        name = mu_enrich(addr)
        if name:
            cur.execute(
                "UPDATE email_address_candidate SET display_name = %s WHERE address = %s",
                (name, addr)
            )
            enriched += 1
    log(f"  enriched {enriched} / {len(rows)} queried (cap={MU_ENRICH_CAP})")


# ---------------------------------------------------------------------------
# Phase 3 — Display name clustering
# ---------------------------------------------------------------------------

def phase3_cluster(cur, resolution: dict) -> None:
    """Populate resolution {addr: human_id} via display-name clustering."""
    log("Phase 3: display name clustering …")

    # Load existing humans for matching
    cur.execute("SELECT id, display_name FROM human")
    raw_humans = [(row[0], row[1]) for row in cur.fetchall() if row[1]]
    existing_humans = {normalize_name(name): hid for hid, name in raw_humans}
    # Token-set index for subset matching (e.g. "Bárbara Quiñones" ⊆ "Bárbara Quiñones Vásquez")
    human_tokensets = [(hid, set(normalize_name(name).split())) for hid, name in raw_humans]

    # Load all candidates with a display name
    cur.execute("SELECT address, display_name FROM email_address_candidate WHERE display_name != ''")
    rows = cur.fetchall()

    # Group by normalized name
    clusters = defaultdict(list)  # norm_name → [address, ...]
    addr_rawname = {}
    for addr, raw_name in rows:
        norm = normalize_name(raw_name)
        clusters[norm].append(addr)
        addr_rawname[addr] = raw_name

    new_humans = 0
    matched = 0

    for norm, addrs in clusters.items():
        # Skip cluster if already resolved
        if any(a in resolution for a in addrs):
            continue

        # Exact normalized match against existing humans
        if norm in existing_humans:
            hid = existing_humans[norm]
            for a in addrs:
                resolution[a] = hid
            matched += len(addrs)
            continue

        # Subset match — cluster tokens ⊆ existing human tokens (min 2 tokens)
        cluster_tokens = set(norm.split())
        if len(cluster_tokens) >= 2:
            best_hid = None
            best_overlap = 0
            for hid, htokens in human_tokensets:
                if cluster_tokens.issubset(htokens) and len(htokens) > best_overlap:
                    best_overlap = len(htokens)
                    best_hid = hid
            if best_hid:
                for a in addrs:
                    resolution[a] = best_hid
                matched += len(addrs)
                continue

        # Corporate filter
        raw_name = addr_rawname[addrs[0]]
        if is_corporate_name(raw_name):
            continue

        # Personal name heuristic: 2–4 tokens
        tokens = raw_name.split()
        if not (2 <= len(tokens) <= 4):
            continue

        # Auto-create human
        best_name = raw_name
        if DRY_RUN:
            log(f"  [dry-run] would create human: {best_name!r} ({len(addrs)} addr)")
            new_humans += 1
            continue

        cur.execute(
            "INSERT INTO human (display_name, internal, notes) VALUES (%s, FALSE, 'corpus-derived') RETURNING id",
            (best_name,)
        )
        hid = cur.fetchone()[0]
        existing_humans[norm] = hid
        for a in addrs:
            resolution[a] = hid
        new_humans += 1

    log(f"  matched to existing humans: {matched} addresses")
    log(f"  new humans created:         {new_humans}")


# ---------------------------------------------------------------------------
# Phase 4 — Domain ownership rules
# ---------------------------------------------------------------------------

def phase4_domain(cur, resolution: dict) -> None:
    """Populate resolution {addr: human_id} via domain ownership rules."""
    log("Phase 4: domain ownership rules …")
    assigned = 0

    cur.execute("SELECT address, display_name FROM email_address_candidate")
    rows = cur.fetchall()

    for addr, disp in rows:
        if addr in resolution:
            continue
        dom = domain_of(addr)
        if not dom:
            continue

        # weiwu.au / weiwu.eu / weiwu.id.au
        matched = False
        for pattern, hid, _ in DOMAIN_OWNERSHIP:
            if re.search(pattern, dom):
                resolution[addr] = hid
                assigned += 1
                matched = True
                break
        if matched:
            continue

        # colourful.land / colorful.land → Weiwu unless display name suggests Liansu
        if dom in ('colourful.land', 'colorful.land') or dom.endswith('.colourful.land') or dom.endswith('.colorful.land'):
            disp_lower = disp.lower()
            hid = 2 if ('liansu' in disp_lower or 'yu lian' in disp_lower) else 1
            resolution[addr] = hid
            assigned += 1
            continue

        # realss.com — match display name against known realss humans
        if dom == 'realss.com':
            norm = normalize_name(disp) if disp else ''
            for key, kid in REALSS_NAMES.items():
                if key in norm:
                    resolution[addr] = kid
                    assigned += 1
                    break

    log(f"  domain-assigned: {assigned} addresses")


# ---------------------------------------------------------------------------
# Phase 5 — Insert into email_address
# ---------------------------------------------------------------------------

def phase5_insert(cur, resolution: dict) -> None:
    """Insert all surviving candidates into email_address."""
    log("Phase 5: inserting into email_address …")
    cur.execute("SELECT address, display_name FROM email_address_candidate")
    rows = cur.fetchall()

    inserted_resolved = 0
    inserted_unresolved = 0
    skipped = 0

    for addr, disp in rows:
        hid = resolution.get(addr)
        cur.execute(
            """
            INSERT INTO email_address (address, human_id, is_canonical, source, display_name_raw)
            VALUES (%s, %s, FALSE, 'corpus', %s)
            ON CONFLICT (address) DO NOTHING
            """,
            (addr, hid, disp or None)
        )
        if cur.rowcount == 1:
            if hid:
                inserted_resolved += 1
            else:
                inserted_unresolved += 1
        else:
            skipped += 1

    log(f"  inserted resolved:   {inserted_resolved}")
    log(f"  inserted unresolved: {inserted_unresolved}")
    log(f"  skipped (conflict):  {skipped}")


# ---------------------------------------------------------------------------
# Phase 6 — Correct Aiqin Li address
# ---------------------------------------------------------------------------

def phase6_aiqin(cur):
    log("Phase 6: correcting Aiqin Li address …")
    wrong = 'liaiqinlahzou@163.com'
    correct = 'liaqinlanzhou@163.com'

    cur.execute("SELECT 1 FROM email_address WHERE address = %s", (wrong,))
    if cur.fetchone():
        cur.execute("UPDATE email_address SET address = %s WHERE address = %s", (correct, wrong))
        log(f"  email_address: {wrong} → {correct}")
    else:
        log(f"  email_address: {wrong} not found (may already be corrected)")

    cur.execute("SELECT 1 FROM email_address_candidate WHERE address = %s", (wrong,))
    if cur.fetchone():
        cur.execute("UPDATE email_address_candidate SET address = %s WHERE address = %s", (correct, wrong))
        log(f"  email_address_candidate: corrected")


# ---------------------------------------------------------------------------
# Phase 7 — Report
# ---------------------------------------------------------------------------

def phase7_report(cur):
    log("\n" + "=" * 60)
    log("Phase 7: report")
    log("=" * 60)

    cur.execute("SELECT COUNT(*) FROM ignored_pattern")
    log(f"ignored_pattern rows:           {cur.fetchone()[0]}")

    cur.execute("SELECT COUNT(*) FROM email_address_candidate")
    log(f"email_address_candidate (after prune): {cur.fetchone()[0]}")

    cur.execute("SELECT COUNT(*) FROM email_address")
    log(f"email_address total:            {cur.fetchone()[0]}")

    cur.execute("SELECT COUNT(*) FROM email_address WHERE source = 'corpus' AND human_id IS NOT NULL")
    log(f"  corpus-resolved:             {cur.fetchone()[0]}")

    cur.execute("SELECT COUNT(*) FROM email_address WHERE source = 'corpus' AND human_id IS NULL")
    log(f"  corpus-unresolved:           {cur.fetchone()[0]}")

    cur.execute("SELECT COUNT(*) FROM human WHERE notes = 'corpus-derived'")
    log(f"humans auto-created:            {cur.fetchone()[0]}")

    log("\nNew corpus-derived humans (sample):")
    cur.execute("""
        SELECT h.display_name, COUNT(e.id) AS addr_count
        FROM human h
        JOIN email_address e ON e.human_id = h.id
        WHERE h.notes = 'corpus-derived'
        GROUP BY h.id, h.display_name
        ORDER BY addr_count DESC, h.display_name
        LIMIT 30
    """)
    for name, cnt in cur.fetchall():
        log(f"  {cnt:3d}  {name}")

    log("\nTop 20 unresolved addresses (worth manual review):")
    cur.execute("""
        SELECT e.address, e.display_name_raw
        FROM email_address e
        WHERE e.source = 'corpus' AND e.human_id IS NULL
        ORDER BY e.address
        LIMIT 20
    """)
    for addr, disp in cur.fetchall():
        label = f" ({disp})" if disp else ''
        log(f"  {addr}{label}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if DRY_RUN:
        log("*** DRY RUN — no changes will be committed ***\n")

    conn = psycopg2.connect(DATABASE_URL)
    conn.autocommit = False
    cur = conn.cursor()

    try:
        # Drop leftover human_id_resolved column if it exists from a prior run
        cur.execute("""
            ALTER TABLE email_address_candidate
            DROP COLUMN IF EXISTS human_id_resolved
        """)

        # addr → human_id: resolution state carried in memory between phases 3–5
        resolution: dict = {}

        phase0_seed(cur)
        phase1_prune(cur)
        phase2_enrich(cur)
        phase3_cluster(cur, resolution)
        phase4_domain(cur, resolution)
        phase5_insert(cur, resolution)
        phase6_aiqin(cur)
        phase7_report(cur)

        if DRY_RUN:
            conn.rollback()
            log("\n[dry-run] rolled back — no changes written")
        else:
            conn.commit()
            log("\nCommitted.")
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == '__main__':
    main()
