# Travel Folder Access Standard Operating Procedure

## Purpose

This SOP is the single source of truth for accessing travel folders. All other travel SOPs reference this document for folder access instructions rather than containing their own access logic. This design ensures that changes to the storage backend require updates to only this document.

## Travel Folder Location

Travel folders reside in `0. Travel Admin/` within Dropbox, accessed via rclone. **Travel data is never in the local git repository.** The git repo contains only SOPs and test artifacts — do not search the current working directory for travel files.

Each journey folder follows the naming convention:

`YYYY-MM-DD [Destination(s)] - [Travellers]`

Examples:

- `2025-12-23 Edinburgh, Berlin, Munich, Vienna, Warsaw - Liansu, Weiwu, A-Z`
- `2025-11-29 Venice - Liansu, Weiwu, A-Z`
- `2025-04-04 Lima - Liansu, Weiwu, A-Z`

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
rclone ls "Dropbox:0. Travel Admin/2025-12-23 Edinburgh, Berlin, Munich, Vienna, Warsaw - Liansu, Weiwu, A-Z"
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
mailroom -a me-weiwu-id-au export -f INBOX -u UID -o /tmp/booking.html

# Convert to PDF
weasyprint /tmp/booking.html /tmp/booking.pdf

# Upload to Dropbox
rclone copyto /tmp/booking.pdf "Dropbox:0. Travel Admin/[journey]/Fares/[name].pdf"
```

## Traveller Profiles

Traveller facts live outside the travel folder, in the personal repo:

- `$HOME/code/weiwu/family.yaml`: identities, passports, travel constraints
  (e.g. motion sickness), children's languages, traits and interests
- `$HOME/code/weiwu/weiwu.yaml`: Weiwu as a person (background, roles,
  living pattern); its header routes travel detail back to family.yaml

This section is the single home for these paths. Other travel SOPs refer to
"traveller profiles (per `sop-travel-folder-access.md`)" rather than
repeating them.

## Journey Folder Structure

Each journey folder contains standardised subfolders:

```
[Journey Folder]/
├── Fares/              # Transport booking PDFs (flights, trains, buses, car rentals)
├── Accommodations/     # Hotel/lodging booking PDFs
├── Passes/             # Event tickets, museum passes, boarding passes
└── Reimbursement (Company Name)/  # Optional: pending reimbursement invoices
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
