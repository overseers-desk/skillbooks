# LinkedIn outreach: daily verify + draft runbook

Read this file at session start. Run one day's verify-and-draft pass, then
stop. You do not send invites. The operator reviews the queue afterwards.

## Your goal for this session

Produce N drafted rows in the `connection_queue` table, where N = (candidates
Google found) + (candidates LinkedIn keyword-search found among the up-to-30
you tried). Stop when `linkedin_searches_used >= 30` or when
`pick_next_candidate.py` returns an empty list.

Candidates arrive already scored and assigned a treatment level. You do not
judge who is worth contacting or what level they deserve; that decision is made
at harvest time (see below). Your job is to resolve each candidate's LinkedIn
profile and, for those not already connected, draft a note at the level the
candidate already carries.

## How candidates are scored (you consume this, you do not compute it)

`pick_next_candidate.py` returns only people worth contacting, ordered by a
memory score `M`, the likelihood the *other* person remembers us. M is summed
over the candidate's two-way, non-calendar email threads, decayed by age, with
group threads discounted. People too cold to remember us are never returned, so
the harvest output is itself the rubric; there is no separate scoring step here.

Each candidate carries a `level` derived from M:

| level | what it means | how you treat it |
|---|---|---|
| 3 | they plainly remember us | bare connect, no note |
| 2 | a real but faded memory | note that reminds them of the last shared topic |
| 1 | faint; we mostly crossed paths | note led by a venue USP, claiming only that paths crossed |

The exact formula and its constants (half-life, group weight, band cutoffs) live
in `pick_next_candidate.py` and nowhere else. Do not re-derive or second-guess
them. `do_not_contact` remains a separate manual veto, set outside this loop.

## Loop

Repeat until the stop condition fires:

1. **Pick.** Run:
   ```bash
   python3 ~/code/aesop/contact-graph/pick_next_candidate.py
   ```
   Output is a JSON list, ordered by `m` descending, each row:
   `{human_id, display_name, m, level, email_addresses, org_hints}`.
   Carry each candidate's `level` through to `record_verify.py` below.

2. **Choose disambiguator.** Order of preference:
   1. `org_hints[0]` if present.
   2. Organisation inferred from the email domain (e.g. `alice@acme.com` →
      `Acme`). Skip generic domains (gmail.com, hotmail.com, outlook.com,
      yahoo.com, icloud.com, proton.me, etc.).
   3. None — query with just the name.

3. **Google via WebSearch.** Issue the query:
   ```
   site:linkedin.com/in/ "DisplayName" "Disambiguator"
   ```
   (Omit the second quoted term if no disambiguator.) Use the WebSearch
   tool.

4. **Read the hits.** Apply the hit-confidence rubric:
   - **Confident**: exactly one `linkedin.com/in/...` URL whose result title
     contains the display-name surname AND the disambiguator (or, with no
     disambiguator, contains the full display name).
   - **Ambiguous**: two or more plausible candidates with different
     organisations or locations in the snippet.
   - **Not found**: zero `linkedin.com/in/...` URLs in the results.

5. **Branch.**
   - **Confident Google hit** →
     ```bash
     python3 ~/code/aesop/contact-graph/record_verify.py \
       --human-id <id> --state verified --vanity <url> --level <level> \
       --evidence '{"source":"google","query":"<query>","m":<m>}'
     ```
     Pass the candidate's `level` and `m` straight from the harvest output.
     Then go to **Drafting**.
   - **Ambiguous Google result** with disambiguator already applied →
     ```bash
     python3 ~/code/aesop/contact-graph/record_verify.py \
       --human-id <id> --state ambiguous \
       --evidence '{"source":"google","candidates":["url1","url2"]}'
     ```
     Skip drafting. Next candidate.
   - **Not found** → go to **LinkedIn fallback**.

6. **LinkedIn fallback.** Only if Google found nothing. First check the
   budget:
   ```bash
   python3 ~/code/aesop/contact-graph/count_today.py | grep linkedin_searches_used
   ```
   If the count is `>= 30`, stop the entire loop. Otherwise use the LinkedIn
   skill's keyword search for `DisplayName Disambiguator`.
   Parse the output. Apply the same confidence rubric. Then:
   - **Confident LinkedIn hit** → `record_verify.py --state verified --vanity
     <url> --level <level> --evidence '{"source":"linkedin","query":"...","m":<m>}'`.
     Continue to **Drafting**.
   - **No LinkedIn hit** → `record_verify.py --state unverifiable --evidence
     '{"source":"linkedin","tried":"..."}'`. Next candidate.
   - **Ambiguous** → `record_verify.py --state ambiguous --evidence
     '{"source":"linkedin","candidates":[...]}'`. Next candidate.

6.5. **Check connection status** — only for `verified` candidates. This step is CHEAP (no CUL, ~3 seconds, direct profile-page fetch). It MUST come before any mailroom or drafting work, because half the candidates may already be first-degree connections and there is no point burning tokens drafting notes for invites that will never go out.

   ```bash
   python3 ~/code/aesop/contact-graph/check_connection_status.py --vanity <vanity-or-url>
   ```

   Output is one of `not_connected`, `invite_pending`, `already_connected`, `fetch_failed`, `parse_failed`.

   - `not_connected` → continue to step 7 (Drafting).
   - `already_connected` → `record_verify.py --human-id <id> --state already_connected`. Skip drafting. Next candidate.
   - `invite_pending` → `record_verify.py --human-id <id> --state invite_pending`. Skip drafting. Next candidate.
   - `fetch_failed` / `parse_failed` → record the parse outcome in `verify_evidence` and skip to next candidate; do NOT draft on a failed check.

7. **Drafting.** Only for `verified` candidates that returned `not_connected` at step 6.5.

   At session start (once, then cache in your working memory):
   - Read `/home/weiwu/code/rivermill/overview.md`.
   - Read `/home/weiwu/code/palaciobizcocheros.com/docs/overview.md`.
   - Note: Bizcocheros is in validation posture, not booking pitch. The
     overview file is explicit on the framing the message must carry.

   Branch on the candidate's `level`.

   **Level 3 (bare connect).** They plainly remember us, so a note adds
   nothing. No mailroom or USP work. Save with:
   ```bash
   python3 ~/code/aesop/contact-graph/record_draft.py --human-id <id> --no-note
   ```
   Next candidate.

   **Levels 2 and 1 (write a note).** First gather context:
   - **Fetch correspondence**:
     ```bash
     mailroom -A search "from:<email> OR to:<email>" -n 10
     ```
     Use the first email in `email_addresses`. If zero results, retry with
     the second address.
   - **Pick a touch-point** from the most recent thread (subject + date is
     usually enough; fetch one body via `mailroom read <UID>` if a subject
     is too generic to anchor to).
   - **Decide which venue fits** this contact. Default: Rivermill. Switch
     to Bizcocheros if the email-thread topic, organisation, or geography
     points to Spain / Andalucía / cruise / DMC-Europe / Sevilla / Cádiz
     / Jerez / Iberian tourism operator.

   Then draft a note of <= 300 characters, shaped by the level:
   - **Level 2**: lead with one concrete shared touch-point from the prior
     correspondence (not a generic "we connected before"), then one venue USP
     relevant to the person.
   - **Level 1**: lead with one venue USP relevant to the person's role, and
     reference the crossing only lightly (the memory is faint; do not overclaim
     a relationship).
   - Either way, carry the venue's framing (Bizcocheros = honest validation
     question, not booking pitch), and include no personal identifiers beyond
     `human.display_name`.
   - **Save the draft**:
     ```bash
     python3 ~/code/aesop/contact-graph/record_draft.py \
       --human-id <id> --note "<the draft>"
     ```

## Stop conditions (any one)

- `count_today.py` reports `linkedin_searches_used >= 30`.
- `pick_next_candidate.py` returns `[]`.
- Operator interrupts the session.

## End-of-run output

Print one block to the operator:

```
=== Run summary ===
X drafted, Y unverifiable, Z ambiguous, W LinkedIn searches used.

Drafted rows:
[human_id] DisplayName | OrgGuess | Rivermill|Bizcocheros | first ~60 chars of note...
[human_id] ...
```

Then exit. Do NOT send invites; sending is the operator's separate step. The
operator reviews `linkedin.connection_queue` and decides what to send manually.

## Boundaries

- 30 LinkedIn keyword-search calls is the daily ceiling, hard stop.
- Never write a draft without having read the relevant venue overview file
  first.
- Never include personal identifiers from `weiwu.yaml` / global CLAUDE.md
  rules in `note_text` or `verify_evidence`.
- Never send invites; sending is the operator's separate step.
- If a Google search returns a result that looks like a different person
  with the same name, prefer `state='ambiguous'` over a guess.
- Skip generic-domain disambiguators (gmail/hotmail/outlook/yahoo/etc.) when
  composing the Google query — they reduce precision rather than improve it.

## Smoke check before the loop

Run these three commands once at session start to confirm the environment:

```bash
psql "$DATABASE_URL" -tA -c "SELECT COUNT(*) FROM linkedin.connection_queue;" 2>&1
python3 ~/code/aesop/contact-graph/pick_next_candidate.py
python3 ~/code/aesop/contact-graph/count_today.py
```

Set `DATABASE_URL` from `~/code/aesop/contact-graph/.env` if not already in
the environment (`set -a; . ~/code/aesop/contact-graph/.env; set +a`). The
helper scripts load it themselves via `python-dotenv`; the psql sanity
check needs it in the shell env.

The first command should return `0` on first run, growing after that. The
second should return one candidate JSON. The third should print five
counters all at zero on first run.
