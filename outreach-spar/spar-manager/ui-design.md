# SPAR Campaign Manager — UI Design

## Overview

A desktop application that provides a campaign dashboard and task dispatch interface for the SPAR outreach pipeline. The application reads campaign YAML files and the filesystem state (roster TSVs, profile files, approach files) to derive contact states and present actionable transitions.

Use ttk widgets throughout. Use Tcl 9.

## Layout

The window is divided into three vertical zones, top to bottom:

1. Campaign panel: config summary + progress table
2. Transition manager: treeview + task detail
3. Log panel

A ttk::panedwindow separates the three zones so the user can drag the boundaries.

## 1. Campaign panel

### 1.1 Config summary

Displayed as a read-only block at the top of the campaign panel. Fields drawn from the campaign YAML:

- Campaign name (`campaign:`)
- Sender name, role, email (`sender:`)
- Filter settings (`filter:`)

This is a compact summary, not an editor. Campaign YAML editing is a planned feature, not in scope for this version.

### 1.2 Progress table

A table built with the grid geometry manager, using ttk::Label widgets for cells and ttk::Checkbutton for the segment selection column. All columns are visible without horizontal scrolling; column widths are sized to fit the window. This reproduces the output of `spar-progress.tcl`.

**Why grid, not ttk::treeview.** The progress table requires multi-level grouped column headers (§1.2 "Column header grouping"), per-cell background colouring for denominator bands, and checkbox widgets in the segment column. ttk::Treeview does not support any of these: it cannot span or group column headings, cannot colour individual cells, and cannot embed widgets in cells. The grid geometry manager with individual ttk::Label and ttk::Checkbutton widgets provides full control over cell appearance, spanning headers, and per-cell styling. The transition manager (§2) uses ttk::treeview because it has a genuine parent-child hierarchy (transition types containing tasks), which is what treeview is designed for.

Columns:

| Segment | Valid | Profile | 3+★ | A/3+★ | Email | A/Eml | LinkedIn | Facebook | Only ☎ | Sent | Repl |

The star threshold (3+★) is drawn from the campaign configuration (`filter.min_star`). All column headers and groupings adjust when this value changes.

#### Column header grouping

Each column's percentage is relative to a parent column, forming a denominator tree:

```
Valid
├── Profile         (/ Valid)
└── N+★             (/ Valid)
    ├── A/N+★       (/ N+★)
    ├── Email       (/ N+★)
    │   └── A/Eml   (/ Email)
    │       └── Sent  (/ A/3+★)
    │           └── Repl  (/ Sent)
    ├── LinkedIn    (/ N+★)
    ├── Facebook    (/ N+★)
    └── Only ☎     (/ N+★)
```

This hierarchy is communicated visually using multi-level header rows above the treeview. Each row is a strip of ttk::Label widgets spanning the columns that share a denominator. From top to bottom:

```
|                  | ← / Valid → |                              ← / N+★ →                                |
|                  |             |            |← / Email →|                             |                  |
|                  |             |            |           |← / A/Eml →|                 |                  |
|                  |             |            |           |           |← / Sent →  |    |                  |
| Segment   | Valid|  Profile    | N+★ | A/N+★|   Email   |    A/Eml  |  Sent  | Repl  | LinkedIn|Facebook| Only ☎|
```

The spanning labels are sized to match the combined width of their child columns. When columns are resized, the spanning labels resize to match. Each level may use a subtle background tint to reinforce the grouping.

Vertical separators (ttk::Separator or label borders) are placed at group boundaries — without them, a spanning header label has no visible edges and the reader cannot tell which columns it covers. The separators run the full height of the header area and continue through the data rows to maintain visual alignment.

Each row represents one segment. Segments fall into two categories:

- **Campaign segments** — named as keys in the campaign YAML's `segments:` map. These rows have a checkbox. All checkboxes are checked by default. Unchecking a segment excludes it from the totals row and from the transition treeview below. The checkbox state does not persist across sessions; it is a transient filter.
- **Non-campaign segments** — segment directories that exist in the campaign folder but are not named in `segments:` (e.g. `bridal-expo`). These rows are displayed in a muted style (greyed out text, no checkbox). They appear in the table for awareness but do not contribute to the totals row or the transition treeview, and cannot be selected.

The final row is a **Totals** row that sums only the checked campaign segments. It updates dynamically when checkboxes change.

Each data column is split into two sub-columns: one for the count (right-aligned) and one for the percentage (right-aligned). The header label for each data column spans both sub-columns, so the divider within a pair is invisible. Separators between column groups remain visible. This ensures counts and percentages align vertically across rows regardless of digit count.

### 1.3 Warnings

Below the progress table, a warnings area displays issues detected during the filesystem scan:

- Duplicate recipients (same email address in multiple approach files)
- Duplicate contacts by name (same person in multiple segments)
- Duplicate contacts by email (same email in multiple segments)
- Identical subject lines in unsent approaches

These mirror the warnings produced by `spar::build_warnings` (spar-state.tcl). Each warning is a single line. The area is collapsed by default and shows a summary when collapsed (e.g. "▶ ⚠ 7 warnings (5 duplicate email, 1 duplicate name, 1 identical subject)"). Clicking the toggle button expands the full warning list.

### 1.4 Check email button

A button labelled "Check Email" in the toolbar area of the campaign panel. Clicking it queries the campaign's configured mailroom account for new replies and updates approach files with reply markers. The button is disabled while a check is in progress. Results appear in the log panel (§3) and the progress table refreshes afterward.

## 2. Transition manager

A single ttk::treeview with `selectmode extended`. Top-level items are the fixed set of transition types. Each top-level item shows a task count and can be expanded (via the disclosure triangle ▶) to reveal the individual contact tasks as child items.

### 2.1 Transition types (top-level items)

The fixed transition types:

| ID | Label | From state | To state |
|----|-------|-----------|----------|
| T1 | Sweep → Profile | DISCOVERED | PROFILED |
| T2 | Profile → Approach | PROFILED | APPROACHED |
| T3 | Stale → Re-profile | PROFILE_STALE | PROFILED |
| T4 | Re-profile → Re-approach | PROFILED (rebuilt) | APPROACHED |
| T6 | Approach → Send | APPROACHED | SENT |
| T7 | Send → Reply | SENT | REPLIED |
| T8 | LinkedIn → Email follow-up | SENT (LinkedIn) | APPROACHED (email) |

Each top-level row displays: the transition label and the count of tasks (e.g. "Profile → Approach (23)"). Counts update dynamically when the user changes segment checkboxes in the progress table.

T7 (Send → Reply) dispatches through `spar::r::run`: it queries the campaign's mailroom account and appends received replies to the corresponding approach YAMLs (same code path as the toolbar "Check Email" button). T8 (LinkedIn → Email follow-up) remains a monitoring transition — displayed but with no play button.

### 2.2 Tasks (child items)

Expanding a transition type reveals its individual tasks as child rows. Each child row has columns:

- Contact name
- Organisation
- Segment
- Task state: **dispatchable**, **awaiting**, **blocked**, or **done**
- Reason (when **awaiting** or **blocked**): a short text naming the dependency or the defect

**awaiting** rows clear themselves once an external dependency resolves (a clock elapses, a third party acts):

- "Waiting for credit window" (any dispatched transition, API budget exhausted)
- "Profile stale — cross-ref update from [other contact]" (T3)
- "LinkedIn request sent 2 days ago, waiting until day 5" (T8)

**blocked** rows need an operator to fix the underlying data before they can move:

- "No email address" (T6, channel is email but contact has no email)
- "invalid_approach_yaml: …" (the approach YAML fails structural validation)

Tasks in the **done** state are shown greyed out. A "Show completed" checkbox above the treeview toggles their visibility.

### 2.3 Dispatch controls

A toolbar below the transition treeview with:

- **Play button** (▶) — dispatches all **ready** tasks for the selected transition type(s). The play button is disabled when no transition type is selected or when the selected types have zero ready tasks.
- **Stop button** (⏹) — cancels a running dispatch. Tasks already completed within the batch remain completed; remaining tasks return to ready state.

### 2.4 Progress bar

When a dispatch is running, a progress bar appears below the toolbar for each active transition type. The progress bar advances block by block, one block per task. Each block is coloured green on success or red on failure. The overall label shows "N / M completed".

The task child items update in real time as individual tasks complete (state changes from ready to done) or fail (state changes to pending with an error reason).

If the block-by-block segmented progress bar is not achievable with ttk::progressbar, a standard determinate progress bar with a numeric label is acceptable as a fallback.

### 2.5 Interaction between progress table and transition manager

The two zones are linked by the segment checkboxes:

1. User unchecks "wedding-planner" in the progress table.
2. Totals row recalculates excluding wedding-planner.
3. Transition treeview counts recalculate excluding wedding-planner contacts.
4. If a transition type is expanded, wedding-planner contacts disappear from its child items.

This filtering is immediate and does not require a refresh button.

## 3. Log panel

A text widget at the bottom of the window displaying timestamped log entries. All subprocess output (from dispatch actions, email checks, filesystem scans) is appended here. The log panel is scrollable and has a "Clear" button.

Error messages from failed tasks appear here with the contact name and transition type, providing detail beyond what the red progress block and pending reason convey.

## State derivation

Contact states are derived from the filesystem, not stored in a separate database. The derivation rules:

| State | Condition |
|-------|-----------|
| DISCOVERED | Roster row exists, no profile file |
| PROFILED | Profile file exists, no approach file |
| APPROACHED | Approach file exists, no `actioned_date` in final round |
| SENT | `actioned_date` present in final round |
| REPLIED | Reply marker present in approach file |
| EXCLUDED | `date_excluded` set in roster |
| PROFILE_STALE | Profile file exists; its front-matter `dependent_data` snapshot diverges from the current roster row |

The application scans the filesystem on startup and when the user triggers a refresh (via the Check Email button or after a dispatch completes). If the platform provides a filesystem monitoring facility, use it to trigger automatic refreshes; otherwise rely on manual refresh.

## Scope exclusions (planned for future versions)

- Campaign YAML editing from within the UI
- Segment configuration pop-up (gear icon per segment)

## Column header approach: legend popup (chosen)

The multi-level spanning header rows (§1.2) were prototyped but abandoned: placing headers and data rows in separate grid frames prevented column alignment without complex post-layout width synchronisation, and the five header rows consumed vertical space without solving the alignment problem reliably.

The chosen approach uses a single-row column header directly above the data rows, with denominator relationships explained in a separate legend popup rather than embedded in the table header area.

### Legend button and popup window

A **Legend** button in the campaign toolbar opens a `toplevel` window titled "Column Denominator Tree". The window contains a `canvas` widget that draws the denominator tree as connecting lines between node labels:

```
                         Valid
                        ╱     ╲
                   Profile    N+★
                            ╱  |  ╲        ╲
                        A/N+★ Email LinkedIn Facebook Only☎
                              |
                             A/Eml
                              |
                             Sent
                              |
                             Repl
```

Each node label is accompanied by its denominator in smaller grey text (e.g. "/ Valid", "/ 3+★"). The canvas redraws on `<Configure>` so it adapts to the window being resized. Closing the legend window withdraws it rather than destroying it; reopening raises and deiconifies the existing window.

The canvas is not embedded above the table. The table header is a single row; the legend is on-demand.

### Progress table: three-frame layout with scrollable data

The progress table uses three separate frames: a fixed header frame, a scrollable data frame (embedded in a canvas with a vertical scrollbar), and a fixed totals frame. All three frames use identical `grid columnconfigure -minsize` values to ensure column alignment. The header row and totals row remain visible at all times; the data rows between them scroll vertically when there are more segments than fit in the available space. Mouse wheel scrolling is handled via a `ScrollData` bindtag applied to the canvas and all child widgets.

### Log panel removed from main window

The log panel (zone 3) is not a persistent zone. Log output is only relevant during a dispatch run. When a dispatch is active, a progress bar and a **Log…** button appear in the dispatch toolbar. The Log… button opens a separate `toplevel` window with a scrollable text widget. This window persists across dispatches within a session.

### Scrollbars

Three scrollbars in the application:

- **Segment data rows** — vertical scrollbar on the data canvas, between the fixed header row and the fixed totals row. The canvas requests a small height (100px) so the scrollbar engages whenever the data exceeds the paned-window allocation.
- **Transition treeview** — vertical scrollbar on the treeview widget itself.
- **Log window** — vertical scrollbar on the log text widget inside the log toplevel.

No scrollbar wraps a whole zone or the campaign panel.

## Development notes

### Running the mock

```bash
wish9.0 spar-manager/mock-ui.tcl
```

### Screenshot debug cycle (Wayland + XWayland)

`wish9.0` uses Tk, which runs on X11. Under a Wayland compositor it runs via XWayland, not as a native Wayland client. This means `ydotool` (which operates on Wayland input events and cannot query X11 window IDs) does not apply. Use `xdotool` to find the window ID and ImageMagick `import` to capture it:

```bash
wish9.0 spar-manager/mock-ui.tcl &
PID=$!
sleep 2
WID=$(xdotool search --name "SPAR Campaign Manager" | head -1)
import -window "$WID" /tmp/screenshot.png
kill $PID
```

To capture a specific popup (e.g. the legend window), use its title:

```bash
WID=$(xdotool search --name "Column Denominator Tree" | head -1)
import -window "$WID" /tmp/legend.png
```

Requires `imagemagick` and `xdotool`. Both were present on the development machine.
