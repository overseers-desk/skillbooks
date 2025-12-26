# Travel Folder Access Standard Operating Procedure

## Purpose

This SOP is the single source of truth for accessing travel folders. All other travel SOPs reference this document for folder access instructions rather than containing their own access logic. This design ensures that changes to the storage backend (e.g., migrating from Dropbox to OneDrive) require updates to only this document.

## Travel Folder Location

Travel folders reside in `0. Travel Admin/` within the cloud storage, accessed via MCP or filesystem mount. **Travel data is never in the local git repository.** The git repo contains only SOPs and test artifacts - do not search the current working directory for travel files.

Each journey folder follows the naming convention:

`YYYY-MM-DD [Destination(s)] - [Travellers]`

Examples:

- `2025-12-23 Edinburgh, Berlin, Munich, Vienna, Warsaw - Liansu, Weiwu, A-Z`
- `2025-11-29 Venice - Liansu, Weiwu, A-Z`
- `2025-04-04 Lima - Liansu, Weiwu, A-Z`

## Access Methods

Two access methods are available: MCP (preferred) and filesystem mount (fallback).

### Method 1: MCP Server (Preferred)

The Rube MCP server provides Dropbox integration. Use this method for all travel folder access.

**Listing Journey Folders:**

```
Tool: DROPBOX_LIST_FILES_IN_FOLDER
Arguments: { "path": "/0. Travel Admin", "limit": 100, "recursive": false }
```

**Finding a Specific Journey Folder:**

```
Tool: DROPBOX_SEARCH_FILE_OR_FOLDER
Arguments: { "query": "2025-12-23 Edinburgh", "options": { "path": "/0. Travel Admin" } }
```

**Listing Contents of a Journey Folder:**

```
Tool: DROPBOX_LIST_FILES_IN_FOLDER
Arguments: { "path": "/0. Travel Admin/2025-12-23 Edinburgh, Berlin, Munich, Vienna, Warsaw - Liansu, Weiwu, A-Z", "recursive": false }
```

**Reading a File:**

Use `DROPBOX_DOWNLOAD_FILE_FROM_PATH` to retrieve file contents.

**Advantages of MCP method:**

- More stable than filesystem mount
- Works regardless of local Dropbox sync status
- Direct API access to cloud storage
- Not affected by selective sync settings

### Method 2: Filesystem Mount (Fallback - Not Preferred)

If MCP access fails, the Dropbox folder may be mounted locally at `~/Dropbox/`. It is a secondary choice because mount points are known to stale. **It's MANDANTORY that you only use this if mcp method above failed.**

**Checking if Mounted:**

```bash
ls ~/Dropbox/0.\ Travel\ Admin/
```

If this command succeeds and returns journey folders, the mount is available.

**Using the Mount:**

Once confirmed, access travel folders at:

```
~/Dropbox/0. Travel Admin/[journey-folder-name]/
```

Example:

```bash
ls ~/Dropbox/0.\ Travel\ Admin/2025-12-23\ Edinburgh,\ Berlin,\ Munich,\ Vienna,\ Warsaw\ -\ Liansu,\ Weiwu,\ A-Z/
```

**Limitations of Mount Method:**

- Mount stability varies (network issues, sync delays)
- Selective sync may exclude some folders
- Changes may not sync immediately
- Requires Dropbox client running locally


## Finding a Journey Folder

When a user specifies a journey by partial name (e.g., "Edinburgh trip" or "Venice journey"):

**Using MCP:**

```
Tool: DROPBOX_LIST_FILES_IN_FOLDER
Arguments: { "path": "/0. Travel Admin", "limit": 100, "recursive": false }
```

Then filter results by matching the destination name or date.

**Using Mount:**

```bash
ls ~/Dropbox/0.\ Travel\ Admin/ | grep -i "edinburgh"
```

## Journey Folder Structure

Each journey folder contains standardised subfolders:

```
[Journey Folder]/
├── Fares/              # Transport booking PDFs (flights, trains, buses)
├── Accommodations/     # Hotel/lodging booking PDFs
├── Passes/             # Event tickets, museum passes, boarding passes
└── Reimburse-Pending (Company Name)/  # Optional: pending reimbursement invoices
```

Some journey folders may also contain:

- `build/` directory for generated artifacts (research, extraction, tests)
- `[Date Range] [Destination]_Itinerary.md` for the itinerary document

## Performance Considerations

**Do NOT use recursive searches at root level.** Dropbox contains 10k+ files outside `0. Travel Admin/`. Always scope searches to `/0. Travel Admin/` or a specific journey folder.

When using the mount, the same principle applies:

```bash
# BAD - searches entire Dropbox
find ~/Dropbox -name "*.pdf"

# GOOD - scoped to Travel Admin
find ~/Dropbox/0.\ Travel\ Admin/ -name "*.pdf"
```

## Error Handling

If both MCP and mount fail:

1. Report the failure clearly: "Unable to access travel folders via MCP or filesystem mount"
2. Do not proceed with folder operations
3. Ask user to verify Dropbox connectivity or provide an alternative path

---

**End of Standard Operating Procedure**

