# SPAR Campaign Manager — UI Design

## Overview

A desktop application that provides a campaign dashboard and task dispatch interface for the SPAR outreach pipeline. The application reads campaign YAML files and the filesystem state (roster TSVs, profile files, approach files) to derive contact states and present actionable transitions.

Use ttk widgets throughout. Use Tcl 9.

## Layout

The window is divided into two vertical zones, top to bottom:

1. Campaign panel: config summary + progress table
2. Transition manager: treeview + task detail

A ttk::panedwindow separates the two zones so the user can drag the boundary. Log output lives in an on-demand window (§3), not in a main-window zone.

## 1. Campaign panel

### 1.1 Config summary

Displayed as a read-only block at the top of the campaign panel. Fields drawn from the campaign YAML:

- Campaign name (`campaign:`)
- Sender name, role, email (`sender:`)
- Filter settings (`filter:`)

This is a compact summary, not an editor. Campaign YAML editing is a planned feature, not in scope for this version.

### 1.2 Progress table

A table built with the grid geometry manager, using ttk::Label widgets for cells and ttk::Checkbutton for the segment selection column. All columns are visible without horizontal scrolling; column widths are sized to fit the window. This reproduces the output of `spar-progress.tcl`.

**Why grid, not ttk::treeview.** The progress table requires per-cell background colouring for denominator bands and checkbox widgets in the segment column. ttk::Treeview supports neither: it cannot colour individual cells and cannot embed widgets in cells. The grid geometry manager with individual ttk::Label and ttk::Checkbutton widgets provides full control over cell appearance and per-cell styling. The transition manager (§2) uses ttk::treeview because it has a genuine parent-child hierarchy (transition types containing tasks, with a channel-group level when a send band mixes channels), which is what treeview is designed for.

Columns:

| Segment | Valid | Profile | 3+★ | A/3+★ | Email | LinkedIn | Facebook | Only ☎ | Sent | Repl |

The star threshold (3+★) is drawn from the campaign configuration (`filter.min_star`). All column headers and groupings adjust when this value changes.

#### Column header grouping

Each column's percentage is relative to a parent column, forming a denominator tree:

```
Valid
├── Profile         (/ Valid)
└── N+★             (/ Valid)
    ├── A/N+★       (/ N+★)
    │   └── Sent    (/ A/3+★)
    │       └── Repl  (/ Sent)
    ├── Email       (/ N+★)
    ├── LinkedIn    (/ N+★)
    ├── Facebook    (/ N+★)
    └── Only ☎     (/ N+★)
```

The tree is communicated by the Legend popup (§1.5), not by header rows: the table header is a single row of column labels directly above the data. The table itself uses three frames — a fixed header frame, a scrollable data frame (a canvas with a vertical scrollbar), and a fixed totals frame — with identical `grid columnconfigure -minsize` values keeping the columns aligned. The header and totals rows stay visible at all times; the data rows between them scroll vertically when there are more segments than fit the paned-window allocation. Mouse-wheel scrolling is handled via a `ScrollData` bindtag applied to the canvas and all child widgets.

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

These mirror the warnings produced by `spar::build_warnings` (lib/spar-state.tcl). Each warning is a single line. The area is collapsed by default and shows a summary when collapsed (e.g. "▶ ⚠ 7 warnings (5 duplicate email, 1 duplicate name, 1 identical subject)"). Clicking the toggle button expands the full warning list.

### 1.4 Check email button

A button labelled "Check Email" in the toolbar area of the campaign panel. Clicking it queries the campaign's configured courier account for new replies and updates approach files with reply markers. The button is disabled while a check is in progress. Results appear in the log window (§3) and the progress table refreshes afterward.

### 1.5 Legend popup

A **Legend** button in the campaign toolbar opens a `toplevel` window titled "Column Denominator Tree". The window contains a `canvas` widget that draws the denominator tree (§1.2) as connecting lines between node labels:

```
                         Valid
                        ╱     ╲
                   Profile    N+★
                            ╱  |  ╲        ╲
                        A/N+★ Email LinkedIn Facebook Only☎
                          |
                         Sent
                          |
                         Repl
```

Each node label is accompanied by its denominator in smaller grey text (e.g. "/ Valid", "/ 3+★"). The canvas redraws on `<Configure>` so it adapts to the window being resized. Closing the legend window withdraws it rather than destroying it; reopening raises and deiconifies the existing window. The canvas is not embedded above the table; the legend is on-demand.

## 2. Transition manager

A single ttk::treeview with `selectmode extended`. Top-level items are the fixed set of transition types. Each top-level item shows a task count and can be expanded (via the disclosure triangle ▶) to reveal the individual contact tasks. When a transition's tasks span more than one send channel (a T6 band mixing email and LinkedIn), the contacts sit under one group node per channel: "✉ email (n)", "🔗 linkedin (m)", and "other" for channel-less blocked rows. Selecting a group node selects that whole channel cohort, so one click dispatches it. A single-channel band keeps the contacts directly under the transition row.

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

T7 (Send → Reply) dispatches through `spar::r::run`: it queries the campaign's courier account and appends received replies to the corresponding approach YAMLs (same code path as the toolbar "Check Email" button). T8 (LinkedIn → Email follow-up) remains a monitoring transition — displayed but with no play button.

### 2.2 Tasks (child items)

Expanding a transition type reveals its individual tasks as child rows (under their channel group when the band mixes channels, per §2). Each task row has columns:

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

## 3. Log window

Log output matters during a dispatch run, so it lives in an on-demand window rather than a main-window zone. While a dispatch is active, a **Log…** button appears in the dispatch toolbar; it opens a separate `toplevel` with a scrollable text widget and a "Clear" button, and the window persists across dispatches within a session. All subprocess output (dispatch actions, email checks, filesystem scans) is appended there with timestamps. Error messages from failed tasks appear with the contact name and transition type, providing detail beyond what the red progress block and pending reason convey.

## State derivation

Contact states derive from the filesystem per `state-machine.md` §States; the GUI stores nothing separately and adds no derivation rules of its own. The application scans the filesystem on startup and when the user triggers a refresh (via the Check Email button or after a dispatch completes). If the platform provides a filesystem monitoring facility, use it to trigger automatic refreshes; otherwise rely on manual refresh.

## Scope exclusions (planned for future versions)

- Campaign YAML editing from within the UI
- Segment configuration pop-up (gear icon per segment)

## Scrollbars

Three scrollbars in the application:

- **Segment data rows** — vertical scrollbar on the data canvas, between the fixed header row and the fixed totals row. The canvas requests a small height (100px) so the scrollbar engages whenever the data exceeds the paned-window allocation.
- **Transition treeview** — vertical scrollbar on the treeview widget itself.
- **Log window** — vertical scrollbar on the log text widget inside the log toplevel.

No scrollbar wraps a whole zone or the campaign panel.

## Development notes

### Running the GUI

```bash
wish9.0 spar-manager/spar-ui.tcl
```

### Screenshot debug cycle (Wayland + XWayland)

`wish9.0` uses Tk, which runs on X11. Under a Wayland compositor it runs via XWayland, not as a native Wayland client. This means `ydotool` (which operates on Wayland input events and cannot query X11 window IDs) does not apply. Use `xdotool` to find the window ID and ImageMagick `import` to capture it:

```bash
wish9.0 spar-manager/spar-ui.tcl &
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
