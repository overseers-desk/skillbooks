# Source plugin: knowledge-capture (meeting notes)

## 1. Source description

Reads the meeting-notes corpus at `../../rivermill/knowledge-capture/staging/`. Each file is a markdown document recording a meeting or conversation.

## 2. Stable item ID

The filename: `YYYY-MM-DD-slug.md`. The filename is the canonical identifier for deduplication and cross-referencing. Every meeting ingested into the graph must be traceable back to its file in the knowledge-capture folder.

## 3. Scan strategy

Whole-directory diff. On each run, the plugin lists all files in the staging directory and compares the listing against known filenames (by `external_item_id` in `item_participant` where `source_kind = 'meeting'`). Any file not already present, or whose content has changed, is processed. There is no cursor and no directionality — insertion order is irrelevant. A backdated meeting note (`2025-01-15-old-meeting.md` added in April 2026) is discovered on the next run without special handling.

## 4. Parse output

- Date: first 10 characters of the filename (`YYYY-MM-DD`)
- Participants: names listed after the `—` in the `# Title — Name1, Name2, Name3` heading
- Content: the markdown body (available for AI tagging, not used for graph structure)

There is no sender/recipient distinction.

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

None. The meeting plugin uses only generic tables (`item_participant`, `coappearance`). If metadata storage beyond what `item_participant` provides becomes necessary, a `meeting_note` table analogous to `email_message` could be added.

## 10. Known difficulty

**Human deduplication.** When the staging process fails to match a name to an existing human — a new person, a misspelling, a name variant the correction index does not cover — a new `human` row is created. If that person already exists under a different name, the database has a duplicate. Merging requires updating `item_participant` rows across all meetings referencing the duplicate, plus re-deriving edges and coappearances. This is manually resolvable but expensive. The staging-time query and the correction index reduce the frequency; automated merge logic is not justified by the expected occurrence rate.
