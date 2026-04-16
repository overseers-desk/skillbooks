# Source plugin: knowledge-capture (meeting notes)

## 1. Source description

Reads the meeting-notes corpus at `../../rivermill/knowledge-capture/staging/`. Each file is a markdown document recording a meeting or conversation.

## 2. Stable item ID

The filename: `YYYY-MM-DD-slug.md`. The filename is the canonical identifier for deduplication and cross-referencing. Every meeting ingested into the graph must be traceable back to its file in the knowledge-capture folder.

## 3. Scan strategy

Whole-directory diff. On each run, the plugin lists all files in the staging directory and compares the listing against known filenames (by `external_item_id` in `item_participant` where `source_kind = 'meeting'`). Any file not already present, or whose content has changed, is processed. There is no cursor and no directionality — insertion order is irrelevant. A backdated meeting note (`2025-01-15-old-meeting.md` added in April 2026) is discovered on the next run without special handling.

## 4. Parse output

### 4a. Basic parse (heading-only)

For files without frontmatter, the basic parse extracts:

- Date: first 10 characters of the filename (`YYYY-MM-DD`)
- Participants: names listed after the `—` in the `# Title — Name1, Name2, Name3` heading
- Content: the markdown body (available for AI tagging, not used for graph structure)

There is no sender/recipient distinction.

### 4b. Enriched parse (YAML frontmatter)

Each staging file carries YAML frontmatter populated by LLM extraction. The frontmatter is the structured representation of the meeting; the markdown body remains the clean transcript. Ingestion reads the frontmatter for graph construction; the transcript body is available for AI tagging and full-text search but does not drive graph structure directly.

When frontmatter is present, it is authoritative — the heading participant list is not re-parsed.

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `date` | `YYYY-MM-DD` | From filename; duplicated for tool convenience |
| `title` | string | Descriptive meeting title |
| `participants` | list | People present in the meeting (note-taker included or omitted per convention; ingestion treats the note-taker as implicitly present regardless) |
| `participants[].name` | string | Full name as spoken or written |
| `participants[].title` | string | Job title or organisational role (optional; aids identity resolution for first-name-only participants) |
| `people_mentioned` | list | People referenced in discussion but not present |
| `people_mentioned[].name` | string | Full name, or first name if surname unknown |
| `people_mentioned[].context` | string | Who they are or why mentioned — aids identity resolution and tag generation (e.g. "journalist, Gold Coast Bulletin" gives both role and org affiliation) |
| `organisations` | list | Companies, agencies, software platforms, industry bodies |
| `organisations[].name` | string | Organisation name as commonly used |
| `organisations[].context` | string | Relationship to discussion (optional) |
| `projects` | list | Named initiatives or identifiable efforts discussed in the meeting |
| `projects[].name` | string | Project name if named; descriptive label if unnamed (e.g. "inventory tracking system") |
| `projects[].type` | enum | See project type taxonomy below |
| `products` | list | Named products, assets, or offerings discussed (horses, software products, menu items, vehicles — anything with a name that the business operates, sells, or maintains) |
| `products[].name` | string | Product or asset name |
| `products[].context` | string | What it is and why discussed (optional) |
| `domains` | list | Activity classification; one or more from domain taxonomy below |

**Project type taxonomy:**

| Type | Scope |
|------|-------|
| `development` | Building or creating something new |
| `purchase` | Acquiring equipment, services, or property |
| `campaign` | Marketing, sales, or PR effort |
| `event` | One-off event being planned or reviewed |
| `initiative` | Ongoing programme without a fixed end |
| `investigation` | Inquiry, audit, or review |
| `crisis` | Reactive response to an incident or threat |

**Domain taxonomy:**

| Domain | Scope |
|--------|-------|
| `operations` | Day-to-day running, scheduling, logistics |
| `hr` | Hiring, performance, workplace relations, training |
| `safety` | Workplace safety, animal welfare, incident response |
| `compliance` | Regulatory requirements, licensing, audits |
| `legal` | Contracts, disputes, liability |
| `finance` | Budget, pricing, payroll, cash management |
| `sales` | Revenue, bookings, customer acquisition |
| `marketing` | Promotion, branding, non-crisis PR |
| `product-development` | New offerings, menu or experience design |
| `procurement` | Purchasing, vendor selection, equipment |
| `governance` | Strategy, board decisions, organisational structure |
| `systems-technology` | IT, integrations, software, AI tools |
| `crisis-pr` | Crisis communication, reputation management |
| `external-relations` | Government, industry bodies, partnerships |
| `sop` | Process design, documentation, standard procedures |
| `product` | Discussion of specific products, assets, or offerings (menu items, horses, software features) |
| `events` | Event planning, venue hire, weddings |

**Example** (for a systems-integration meeting):

```yaml
---
date: 2026-02-11
title: Payroll-roster-booking-POS multi-system integration

participants:
  - name: Weiwu Zhang
    title: director
  - name: Marco
    title: systems architect

people_mentioned:
  - name: Edrian
    context: BPO digital service provider
  - name: Belinda
    context: weddings coordinator, raised booking-roster constraint gap

organisations:
  - name: Deputy
    context: rostering platform, broken integration with Xero
  - name: Xero
    context: payroll system
  - name: Rezdy
    context: booking system, no constraint communication with Deputy

projects:
  - name: payroll-roster integration
    type: development
  - name: inventory tracking system
    type: development
  - name: AI-assisted rostering
    type: investigation

domains:
  - systems-technology
  - operations
  - finance
---
```

**Example** (for a crisis-response board meeting):

```yaml
---
date: 2026-01-24
title: Emergency board meeting — animal welfare media response

participants:
  - name: Weizhu Zhang
    title: director
  - name: Liansu Yu
    title: co-director
  - name: Michal Janalik
    title: board member
  - name: John Edwards
    title: operations manager

people_mentioned:
  - name: Till Cordwell
    context: former contractor, alleged animal neglect
  - name: Sarah
    context: equestrian manager, found unsuitable for horse work
  - name: Crystal Fox
    context: journalist, Gold Coast Bulletin

organisations:
  - name: Gold Coast Bulletin
    context: newspaper publishing animal abuse allegations
  - name: RSPCA
    context: animal welfare authority, potential involvement

projects:
  - name: animal welfare media response
    type: crisis
  - name: equestrian SOP overhaul
    type: initiative

products:
  - name: Bella
    context: horse that spooked and injured a child
  - name: Sombra
    context: horse alleged to have been neglected under previous contractor

domains:
  - crisis-pr
  - safety
  - legal
  - governance
  - product
---
```

## 5. Identity

The note-taker is implicitly "me." The participant heading lists the other people in the meeting; the note-taker is absent from it. This is a fixed convention of the staging format.

## 6. Participant resolution

Resolution happens at staging time, not at graph-ingest time. The staging file maker queries the database (or the capture-correction index) to find the canonical name before writing the heading. The staging file therefore contains resolved names — either a full name matching an existing `human.display_name`, or a name qualified by organisation (e.g. "Alice Chen (Rivermill)") when disambiguation is needed.

The graph ingest reads the staging file and matches the name exactly against the database. If the person is not in the database, a new `human` row is created. This means duplicates can occur when the staging process fails to match a name that already exists under a different form. Unlike the email case (where merging is a single `email_address.human_id` update), merging duplicate humans requires updating `item_participant` rows across all meetings referencing the duplicate, plus derived edges and coappearances. This is expensive and handled manually.

The `identifier_ref` column in `item_participant` holds the display name as written in the heading. After initial resolution, `identifier_ref` is inert — it records what the source said, not what the graph uses for joins. A later name change does not break existing rows.

## 7. Edge semantics

Undirected coappearance only. All participants are co-attendees; there is no from/to distinction. Entries go into the `coappearance` table. No directed edges are created in the `edge` table from this source — meetings have no sender, so they produce no directionality signal.

## 8. Deduplication

By filename. On each directory scan, if a filename already exists as an `external_item_id` in `item_participant` with `source_kind = 'meeting'` and the file content has not changed, the item is skipped. If the content has changed (detected by modification time or hash), all `item_participant` rows for that filename are replaced wholesale and edges re-derived.

## 9. Tables owned

None. The meeting plugin uses only generic tables. During ingestion, the plugin populates:

- `item_participant` — one row per participant per meeting (coappearance derived from this)
- `item_entity` — one row per entity from the frontmatter `people_mentioned`, `organisations`, `projects`, `products`, and `domains` fields; `source_kind = 'meeting'`, `external_item_id = filename`

If metadata storage beyond what these generic tables provide becomes necessary, a `meeting_note` table analogous to `email_message` could be added.

## 10. Known difficulty

**Human deduplication.** When the staging process fails to match a name to an existing human — a new person, a misspelling, a name variant the correction index does not cover — a new `human` row is created. If that person already exists under a different name, the database has a duplicate. Merging requires updating `item_participant` rows across all meetings referencing the duplicate, plus re-deriving edges and coappearances. This is manually resolvable but expensive. The staging-time query and the correction index reduce the frequency; automated merge logic is not justified by the expected occurrence rate.
