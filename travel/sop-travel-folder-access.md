# Travel Folder Access Standard Operating Procedure

## Purpose

This SOP is the single source of truth for accessing travel folders. All other travel SOPs reference this document for folder access instructions rather than containing their own access logic. This design ensures that changes to the storage backend require updates to only this document.

## Travel Folder Location

Travel folders reside in `0. Travel Admin/` within Dropbox, accessed via rclone. **Travel data is never in the local git repository.** The git repo contains only SOPs and test artifacts — do not search the current working directory for travel files.

Each journey folder is named by its dates, its travellers and its destinations:

- `YYYY-MM-DD to MM-DD [Travellers] - [Destination(s)]` when the folder holds the travellers' arrival home. The end date carries its year when that differs from the start.
- `YYYY-MM-DD [Travellers] - [Destination(s)]` when it does not: the way home is filed in another folder, or was never found in email.
- `YYYY-MM-DD ✖ [Travellers] - [Destination(s)]` for a trip bought but not taken.

The start date is the day the travellers leave, by any means of transport, a train to the departure airport included. The end date is the day they arrive home; a flight landing after midnight counts on its landing day.

Examples:

- `2025-12-23 to 2026-01-07 Partner, Alex, A-Z - Edinburgh, Berlin, Munich, Vienna, Warsaw`
- `2025-11-29 to 12-01 Partner, Alex, A-Z - Venice`
- `2026-06-10 Partner, Alex, A-Z - London`
- `2025-11-08 ✖ Partner, Alex, A-Z - Marrakesh`

## Access Method: rclone

All travel folder operations use rclone with the `Dropbox:` remote.

### Listing Journey Folders

```bash
rclone lsd "Dropbox:0. Travel Admin"
```

### Finding a Specific Journey Folder

```bash
rclone lsd "Dropbox:0. Travel Admin" | grep -i "keyword"
```

### Listing Contents of a Journey Folder

```bash
rclone ls "Dropbox:0. Travel Admin/2025-12-23 to 2026-01-07 Partner, Alex, A-Z - Edinburgh, Berlin, Munich, Vienna, Warsaw"
```

`rclone ls` lists all files recursively with sizes. For subfolders only, use `rclone lsd`.

### Creating Subfolders

```bash
rclone mkdir "Dropbox:0. Travel Admin/[journey folder]/Fares"
rclone mkdir "Dropbox:0. Travel Admin/[journey folder]/Accommodations"
rclone mkdir "Dropbox:0. Travel Admin/[journey folder]/Passes"
```

### Uploading a File

```bash
rclone copyto /tmp/document.pdf "Dropbox:0. Travel Admin/[journey folder]/Fares/2025-12-23 [Ryanair] Seville-Edinburgh FR1234 ABC123.pdf"
```

### Renaming or Moving a File

```bash
rclone moveto \
  "Dropbox:0. Travel Admin/[journey]/Fares/old_name.pdf" \
  "Dropbox:0. Travel Admin/[journey]/Fares/new_name.pdf"
```

### Deleting a File

```bash
rclone deletefile "Dropbox:0. Travel Admin/[journey folder]/Fares/filename.pdf"
```

### Removing an Empty Directory

```bash
rclone rmdir "Dropbox:0. Travel Admin/[journey folder]/OldFolder"
```

## Saving Email Content as PDF

When a booking confirmation exists only as an email body (no PDF attachment), export it and convert to PDF before uploading:

```bash
# Export the email as HTML
courier --imap me-example-com export -f INBOX -u UID -o /tmp/booking.html

# Convert to PDF
weasyprint /tmp/booking.html /tmp/booking.pdf

# Upload to Dropbox
rclone copyto /tmp/booking.pdf "Dropbox:0. Travel Admin/[journey]/Fares/[name].pdf"
```

## Sourcing hotel-chain availability and price

A hotel chain's own skill, where one exists in the environment, is the source of truth for whether the chain has a property near a place, its availability, and its price. A general aggregator under-lists a chain's properties and misses its member rates, so an aggregator's null or number cannot be delivered to the user as a conclusion about that chain. Attempt the chain's skill before telling the user a chain has, or lacks, a property in an area, or before quoting its rate. Where the environment has no such skill, give the aggregator figure marked unverified and name the source that would confirm it. This holds for any chain or provider that has a dedicated skill, not one brand in particular.

## Journey Folder Structure

Each journey folder contains standardised subfolders:

```
[Journey Folder]/
├── Fares/              # Transport booking PDFs (flights, trains, buses, car rentals)
├── Accommodations/     # Hotel/lodging booking PDFs
├── Passes/             # Event tickets, museum passes, boarding passes
├── Reimbursement (Company Name)/   # Optional: invoices the traveller paid; action: reimburse traveller
└── Reconciliation (Company Name)/  # Optional: invoices a company card paid; action: send to company to reconcile
```

Some journey folders may also contain:

- `build/` directory for generated artifacts (research, extraction, tests)
- `[Date Range] [Destination]_Itinerary.md` for the itinerary document

## Performance Considerations

Do not list or search outside `0. Travel Admin/`. Dropbox contains 10k+ files elsewhere. Always scope operations to the travel folder or a specific journey folder.

```bash
# BAD — too broad
rclone ls "Dropbox:"

# GOOD — scoped
rclone ls "Dropbox:0. Travel Admin/[journey folder]"
```

## Error Handling

If rclone cannot reach Dropbox (network error, authentication expired):

1. Report the failure: "Unable to access travel folders via rclone — Dropbox remote unavailable"
2. Do not proceed with folder operations
3. Ask the user to verify rclone connectivity (`rclone lsd Dropbox:` as a quick test)

---

**End of Standard Operating Procedure**
