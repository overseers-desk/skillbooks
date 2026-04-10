#!/usr/bin/env wish9.0
# SPAR Campaign Manager — Mock UI
# Static mock with hardcoded data from campaign-2026-04.yaml and update-campaign.py output.

package require Tk

wm title . "SPAR Campaign Manager"

# --- Colour palette ---
set colours(hdr_bottom)  "#f8f9fa"
set colours(totals_bg)   "#e2e2e2"
set colours(muted_fg)    "#999999"

# --- Hardcoded campaign data ---
set campaign_name "2026-04 Partnership Outreach"
set sender_name   "Lia Movsisyan"
set sender_role   "Partnership Manager"
set sender_email  "partnerships@rivermill.au"
set method_ref    "spar-A-approach.md"
set filter_desc   "min_star=3  require_email=true  require_profile=true  exclude_invalid=true"

set segments {
    {animal-event 1 {14 {} 14 100% 14 100% 14 100% 13 93% 13 100% 4 29% 11 79% 0 0% 0 0% 0 -}}
    {car-boot-market 1 {10 {} 10 100% 10 100% 10 100% 9 90% 9 100% 1 10% 9 90% 0 0% 0 0% 0 -}}
    {community-organisation 1 {73 {} 73 100% 65 89% 65 100% 57 88% 57 100% 5 8% 49 75% 3 5% 57 100% 1 2%}}
    {corporate-team-experience 1 {16 {} 16 100% 16 100% 16 100% 15 94% 15 100% 13 81% 3 19% 0 0% 0 0% 0 -}}
    {equestrian-clinic 1 {21 {} 21 100% 19 90% 19 100% 18 95% 18 100% 1 5% 19 100% 0 0% 0 0% 0 -}}
    {event-producer 1 {10 {} 10 100% 9 90% 9 100% 9 100% 9 100% 8 89% 4 44% 0 0% 0 0% 0 -}}
    {film-location 1 {9 {} 9 100% 9 100% 9 100% 8 89% 8 100% 8 89% 1 11% 0 0% 0 0% 0 -}}
    {growers-market 1 {48 {} 48 100% 48 100% 42 88% 41 85% 35 85% 7 15% 48 100% 0 0% 35 100% 0 0%}}
    {line-dance 1 {12 {} 12 100% 10 83% 7 70% 10 100% 7 70% 1 10% 9 90% 0 0% 6 86% 6 100%}}
    {market-operator 1 {9 {} 9 100% 7 78% 7 100% 7 100% 7 100% 7 100% 5 71% 0 0% 0 0% 0 -}}
    {mind-body-spirit 1 {23 {} 23 100% 21 91% 20 95% 17 81% 16 94% 12 57% 13 62% 0 0% 0 0% 0 -}}
    {mothers-group 1 {24 {} 24 100% 21 88% 21 100% 18 86% 18 100% 1 5% 19 90% 1 5% 18 100% 6 33%}}
    {recurring-venue-hire 1 {13 {} 13 100% 13 100% 12 92% 12 92% 11 92% 4 31% 7 54% 0 0% 0 0% 0 -}}
    {repair-cafe 1 {11 {} 11 100% 9 82% 9 100% 9 100% 9 100% 4 44% 9 100% 0 0% 0 0% 0 -}}
    {sustainability-expo 1 {6 {} 6 100% 6 100% 5 83% 6 100% 5 83% 4 67% 3 50% 0 0% 0 0% 0 -}}
    {co-location 1 {8 {} 8 100% 6 75% 5 83% 5 83% 4 80% 5 83% 0 0% 0 0% 2 50% 1 50%}}
    {tour-operator-domestic 1 {84 {} 84 100% 71 85% 70 99% 67 94% 66 99% 30 42% 18 25% 0 0% 66 100% 11 17%}}
    {tour-operator-inbound 1 {19 {} 19 100% 17 89% 14 82% 15 88% 12 80% 13 76% 1 6% 0 0% 12 100% 0 0%}}
    {tourism-board 1 {8 {} 8 100% 8 100% 8 100% 8 100% 8 100% 8 100% 0 0% 0 0% 0 0% 0 -}}
    {wedding-planner 1 {49 {} 49 100% 42 86% 40 95% 39 93% 37 95% 15 36% 3 7% 0 0% 0 0% 0 -}}
    {workshop-series 1 {20 {} 20 100% 20 100% 18 90% 20 100% 18 90% 3 15% 20 100% 0 0% 0 0% 0 -}}
    {bridal-expo 0 {5 {} 3 60% 2 40% 1 50% 2 100% 1 50% 0 0% 2 40% 0 0% 0 0% 0 -}}
}

set warnings {
    "Duplicate To: hello@theromanticsweddings.com in wedding-planner/kate-olivia-morrow-the-romantics.yaml, wedding-planner/kate-and-olivia-morrow-the-romantics-wedding-event-styling.yaml"
    "Duplicate To: info@goldcoastrotary.org.au in community-organisation/maggie-alexander-rotary-gold-coast.yaml, sustainability-expo/david-baguley-rotary-club-of-gold-coast.yaml"
    "Duplicate To: info@imperialpacificcoaches.com.au in tour-operator-domestic/bert-rozema-imperial-pacific-coaches.yaml, tour-operator-domestic/bert-rozema-dene-rozema-imperial-pacific-coaches-pty-ltd.yaml"
    "Duplicate name: Kathy Keogh in growers-market (Scenic Rim Lavender) and market-operator (Boonah Country Markets)"
    "Duplicate email: info@goldcoastrotary.org.au in community-organisation (Maggie Alexander) and sustainability-expo (David Baguley)"
    "Duplicate email: kathy@scenicrimlavender.com.au in growers-market (Kathy Keogh) and market-operator (Kathy Keogh)"
    "Identical subject: \"Venue proposal for Finders Keepers Brisbane: Historic Rivermill\" in market-operator/katie-smith-finders-keepers.yaml, market-operator/lindsay-pepper-finders-keepers.yaml"
}

set transitions {
    {"Sweep \u2192 Profile" 0 {}}
    {"Profile \u2192 Approach" 21 {
        {"Sarah Chen" "Scenic Rim Events" "animal-event" "ready" ""}
        {"Mike Torres" "Gold Coast Team Building" "corporate-team-experience" "ready" ""}
        {"Emma Blackwell" "Barefoot Yoga Studio" "mind-body-spirit" "ready" ""}
        {"David Hartley" "Tamborine Mountain Markets" "growers-market" "pending" "Waiting for credit window"}
        {"Rachel Liu" "Sunset Equestrian" "equestrian-clinic" "done" ""}
    }}
    {"Approach \u2192 Send" 186 {
        {"Anna Petrova" "Currumbin Valley Farms" "growers-market" "ready" ""}
        {"James O'Brien" "Pacific Fair Events" "event-producer" "ready" ""}
        {"Tina Nguyen" "GC Wellness Collective" "mind-body-spirit" "pending" "No email address"}
        {"Paul Whitfield" "Film Gold Coast" "film-location" "ready" ""}
        {"Sophie Marsh" "Little Sprouts Playgroup" "mothers-group" "ready" ""}
    }}
    {"Send \u2192 Reply" 196 {
        {"Carol Jenkins" "Hinterland Community Assoc" "community-organisation" "pending" "Waiting for reply"}
        {"Tom Richardson" "Aussie Day Tours" "tour-operator-domestic" "pending" "Waiting for reply"}
        {"Yuki Tanaka" "Japan Travel Bureau" "tour-operator-inbound" "pending" "Waiting for reply"}
        {"Ben Crawford" "Line Dance Australia" "line-dance" "done" ""}
    }}
    {"Flag invalid" 0 {}}
    {"Stale \u2192 Re-profile" 3 {
        {"Greg Palmer" "Outback Adventures" "tour-operator-domestic" "ready" ""}
        {"Linda Voss" "Hinterland Weddings" "wedding-planner" "ready" ""}
        {"Raj Patel" "Cultural Tours QLD" "tour-operator-inbound" "pending" "Profile stale \u2014 cross-ref update from Linda Voss"}
    }}
    {"Re-profile \u2192 Re-approach" 2 {
        {"Diana Ross-Smith" "Eco Markets Co-op" "growers-market" "ready" ""}
        {"Nathan Cho" "Team Spirit Events" "corporate-team-experience" "done" ""}
    }}
    {"LinkedIn \u2192 Email follow-up" 5 {
        {"Fiona Wright" "Wanderlust Inbound" "tour-operator-inbound" "pending" "LinkedIn request sent 2 days ago, waiting until day 5"}
        {"Chris Delaney" "QLD Film Commission" "film-location" "pending" "LinkedIn request sent 4 days ago, waiting until day 5"}
        {"Amy Zhang" "Bridal Dreams GC" "wedding-planner" "pending" "LinkedIn request sent 1 day ago, waiting until day 5"}
    }}
}

# ============================================================
# Main layout
# ============================================================

ttk::notebook .tabs
pack .tabs -fill both -expand 1

# Placeholder tab
ttk::frame .tabs.tab_old
.tabs add .tabs.tab_old -text "2026-03"
ttk::label .tabs.tab_old.lbl -text "(No data loaded)" -foreground #999
pack .tabs.tab_old.lbl -expand 1

# Active tab
ttk::frame .tabs.tab_current
.tabs add .tabs.tab_current -text "2026-04"
.tabs select .tabs.tab_current

# Paned window inside active tab
ttk::panedwindow .tabs.tab_current.pw -orient vertical
pack .tabs.tab_current.pw -fill both -expand 1

ttk::frame .tabs.tab_current.pw.campaign
.tabs.tab_current.pw add .tabs.tab_current.pw.campaign -weight 3

ttk::frame .tabs.tab_current.pw.transitions
.tabs.tab_current.pw add .tabs.tab_current.pw.transitions -weight 2

set cpanel .tabs.tab_current.pw.campaign
set tpanel .tabs.tab_current.pw.transitions

# ============================================================
# Zone 2: Campaign panel — no outer scrollbar
# ============================================================

# --- 2.1 Config summary ---
ttk::labelframe ${cpanel}.config -text "Campaign Configuration"
pack ${cpanel}.config -fill x -padx 8 -pady {6 2}

set cf ${cpanel}.config
ttk::label ${cf}.l1 -text "Campaign:" -font "TkDefaultFont 9 bold"
ttk::label ${cf}.v1 -text $campaign_name
ttk::label ${cf}.l2 -text "Sender:" -font "TkDefaultFont 9 bold"
ttk::label ${cf}.v2 -text "$sender_name, $sender_role ($sender_email)"
ttk::label ${cf}.l3 -text "Method:" -font "TkDefaultFont 9 bold"
ttk::label ${cf}.v3 -text $method_ref
ttk::label ${cf}.l4 -text "Filter:" -font "TkDefaultFont 9 bold"
ttk::label ${cf}.v4 -text $filter_desc

grid ${cf}.l1 ${cf}.v1 -sticky w -padx {6 4} -pady 1
grid ${cf}.l2 ${cf}.v2 -sticky w -padx {6 4} -pady 1
grid ${cf}.l3 ${cf}.v3 -sticky w -padx {6 4} -pady 1
grid ${cf}.l4 ${cf}.v4 -sticky w -padx {6 4} -pady 1

# Check email button
ttk::frame ${cpanel}.toolbar
pack ${cpanel}.toolbar -fill x -padx 8 -pady {2 2}
ttk::button ${cpanel}.toolbar.checkemail -text "Check Email" -command {
    tk_messageBox -message "Check Email: not implemented in mock" -title "Mock"
}
pack ${cpanel}.toolbar.checkemail -side right

# Legend button — toggles a canvas showing the denominator tree
ttk::button ${cpanel}.toolbar.legend -text "Legend" -command show_legend_window
pack ${cpanel}.toolbar.legend -side right -padx {0 4}

proc show_legend_window {} {
    if {[winfo exists .legendwin]} {
        wm deiconify .legendwin
        raise .legendwin
        return
    }
    toplevel .legendwin
    wm title .legendwin "Column Denominator Tree"
    canvas .legendwin.c -width 750 -height 220 -highlightthickness 0
    pack .legendwin.c -fill both -expand 1
    bind .legendwin.c <Configure> {draw_legend .legendwin.c}
    wm protocol .legendwin WM_DELETE_WINDOW {wm withdraw .legendwin}
}

proc draw_legend {c} {
    $c delete all
    set bfont "TkDefaultFont 9 bold"
    set afont "TkDefaultFont 8"
    set line_colour "#888888"
    set acolour "#666666"

    set w [winfo width $c]
    if {$w < 10} {set w 700}

    # Horizontal layout: spread nodes across the canvas width
    # The tree:
    #                    Valid
    #                   /     \
    #             Profile     3+star
    #                       / | \    \      \
    #                  A/3+s Email LnkdIn FaceB Only-phone
    #                         |
    #                       A/Eml
    #                         |
    #                       Sent
    #                         |
    #                       Repl

    set dy 34
    set y0 14
    set y1 [expr {$y0 + $dy}]
    set y2 [expr {$y0 + 2*$dy}]
    set y3 [expr {$y0 + 3*$dy}]
    set y4 [expr {$y0 + 4*$dy}]
    set y5 [expr {$y0 + 5*$dy}]

    # X positions — spread across canvas
    set margin 50
    set span [expr {$w - 2*$margin}]
    set x_valid    [expr {$w / 2}]
    set x_profile  [expr {$margin + $span * 0.0}]
    set x_star     [expr {$margin + $span * 0.50}]
    set x_astar    [expr {$margin + $span * 0.10}]
    set x_email    [expr {$margin + $span * 0.30}]
    set x_linkedin [expr {$margin + $span * 0.55}]
    set x_facebook [expr {$margin + $span * 0.75}]
    set x_phone    [expr {$margin + $span * 0.95}]
    set x_aeml     [expr {$margin + $span * 0.40}]
    set x_sent     [expr {$margin + $span * 0.50}]
    set x_repl     [expr {$margin + $span * 0.60}]

    # Draw nodes — label includes denominator in grey
    # {label denominator x y}
    set nodes [list \
        "Valid"       ""         $x_valid    $y0 \
        "Profile"     "/ Valid"  $x_profile  $y1 \
        "3+\u2605"    "/ Valid"  $x_star     $y1 \
        "A/3+\u2605"  "/ 3+\u2605" $x_astar $y2 \
        "Email"       "/ 3+\u2605" $x_email $y2 \
        "LinkedIn"    "/ 3+\u2605" $x_linkedin $y2 \
        "Facebook"    "/ 3+\u2605" $x_facebook $y2 \
        "Only \u260e" "/ 3+\u2605" $x_phone $y2 \
        "A/Eml"       "/ Email" $x_aeml     $y3 \
        "\u2709 Sent" "/ A/Eml" $x_sent     $y4 \
        "\u2709 Repl" "/ Sent"  $x_repl     $y5 \
    ]

    foreach {lbl denom x y} $nodes {
        $c create text $x $y -text $lbl -font $bfont -anchor center
        if {$denom ne ""} {
            $c create text $x [expr {$y + 11}] -text $denom -font $afont -fill $acolour -anchor center
        }
    }

    # Draw edges
    set g 14 ;# gap above/below text (accounts for denom subscript)
    set gt 9 ;# gap for top nodes (no denom subscript)
    $c create line $x_valid [expr {$y0+$gt}]  $x_profile [expr {$y1-$gt}] -fill $line_colour
    $c create line $x_valid [expr {$y0+$gt}]  $x_star    [expr {$y1-$gt}] -fill $line_colour
    foreach xc [list $x_astar $x_email $x_linkedin $x_facebook $x_phone] {
        $c create line $x_star [expr {$y1+$g}] $xc [expr {$y2-$gt}] -fill $line_colour
    }
    $c create line $x_email [expr {$y2+$g}] $x_aeml [expr {$y3-$gt}] -fill $line_colour
    $c create line $x_aeml  [expr {$y3+$g}] $x_sent [expr {$y4-$gt}] -fill $line_colour
    $c create line $x_sent  [expr {$y4+$g}] $x_repl [expr {$y5-$gt}] -fill $line_colour
}


# --- 2.2 Progress table ---
# Three frames: header (fixed), data rows (scrollable canvas), totals (fixed).
# Each data column is split into two sub-columns (count, pct) for alignment.
# Headers span both sub-columns so the divider within a pair is invisible.

ttk::labelframe ${cpanel}.progress -text "Progress"
pack ${cpanel}.progress -fill both -expand 1 -padx 8 -pady {2 2}

# Column layout (shared across header, data, totals frames):
# gcol 0: checkbox (width 24)
# gcol 1: segment name (width 180)
# gcol 2: separator
# For each data column pair: count_col, pct_col, then separator
# 11 data columns => 22 sub-columns + 7 group separators
#
# Mapping: data column index ci -> (count_gcol, pct_gcol)
# We lay out: [cb=0] [seg=1] [sep=2] [valid_n=3 valid_p=4] [sep=5] [profile_n=6 profile_p=7]
#   [sep=8] [star_n=9 star_p=10] [astar_n=11 astar_p=12] [sep=13] [email_n=14 email_p=15]
#   [aeml_n=16 aeml_p=17] [sep=18] [linkedin_n=19 linkedin_p=20] [facebook_n=21 facebook_p=22]
#   [phone_n=23 phone_p=24] [sep=25] [sent_n=26 sent_p=27] [repl_n=28 repl_p=29]

set sep_cols {2 5 8 13 18 25}
# ci -> {count_gcol pct_gcol}
set ci_to_gcols {
    0 {3 4}    1 {6 7}    2 {9 10}   3 {11 12}  4 {14 15}
    5 {16 17}  6 {19 20}  7 {21 22}  8 {23 24}  9 {26 27}  10 {28 29}
}
# For header spanning: ci -> count_gcol (span 2 columns)
set header_gcols_list {3 6 9 11 14 16 19 21 23 26 28}

# Column widths
set col_cb_w 24
set col_seg_w 180
set col_num_w 30
set col_pct_w 40
set col_sep_w 1

proc configure_table_columns {frame} {
    global sep_cols ci_to_gcols col_cb_w col_seg_w col_num_w col_pct_w col_sep_w
    grid columnconfigure $frame 0 -minsize $col_cb_w -weight 0
    grid columnconfigure $frame 1 -minsize $col_seg_w -weight 1
    foreach sc $sep_cols {
        grid columnconfigure $frame $sc -minsize $col_sep_w -weight 0
    }
    dict for {ci gcpair} $ci_to_gcols {
        lassign $gcpair ng pg
        grid columnconfigure $frame $ng -minsize $col_num_w -weight 0
        grid columnconfigure $frame $pg -minsize $col_pct_w -weight 0
    }
}

# --- Header frame ---
set phdr ${cpanel}.progress.hdr
ttk::frame $phdr
pack $phdr -fill x -padx 2 -pady {2 0}
configure_table_columns $phdr

set header_labels {"Segment" "Valid" "Profile" "3+\u2605" "A/3+\u2605" "Email" "A/Eml" "LinkedIn" "Facebook" "Only \u260e" "\u2709 Sent" "\u2709 Repl"}
# gcol for each header; "Segment" maps to column 1, data headers to their count sub-column (spanning 2)
set header_gcols_span {1 3 6 9 11 14 16 19 21 23 26 28}

ttk::label ${phdr}.hdr_cb -text "\u2611" -background $::colours(hdr_bottom) -anchor center -relief groove -borderwidth 1
grid ${phdr}.hdr_cb -row 0 -column 0 -sticky nsew

set lbl_i 0
foreach lbl $header_labels gc $header_gcols_span {
    set safe [string map {" " _ "\u2605" star "\u260e" phone "\u2709" env "/" slash "+" plus} $lbl]
    ttk::label ${phdr}.hdr_${safe} -text $lbl -background $::colours(hdr_bottom) \
        -anchor center -relief groove -borderwidth 1 -font "TkDefaultFont 8 bold"
    if {$lbl_i == 0} {
        grid ${phdr}.hdr_${safe} -row 0 -column $gc -sticky nsew
    } else {
        grid ${phdr}.hdr_${safe} -row 0 -column $gc -columnspan 2 -sticky nsew
    }
    incr lbl_i
}

# Header separators
foreach sc $sep_cols {
    ttk::separator ${phdr}.sep_${sc} -orient vertical
    grid ${phdr}.sep_${sc} -row 0 -column $sc -sticky ns
}

# --- Scrollable data area ---
set scroll_frame ${cpanel}.progress.sf
ttk::frame $scroll_frame
pack $scroll_frame -fill both -expand 1 -padx 2

canvas ${scroll_frame}.canvas -highlightthickness 0 -borderwidth 0 -height 100
ttk::scrollbar ${scroll_frame}.vsb -orient vertical -command [list ${scroll_frame}.canvas yview]
${scroll_frame}.canvas configure -yscrollcommand [list ${scroll_frame}.vsb set]

pack ${scroll_frame}.vsb -side right -fill y
pack ${scroll_frame}.canvas -side left -fill both -expand 1

set ptable ${scroll_frame}.canvas.data
ttk::frame $ptable
${scroll_frame}.canvas create window 0 0 -anchor nw -window $ptable -tags datawin
configure_table_columns $ptable

# Data-area separators
foreach sc $sep_cols {
    ttk::separator ${ptable}.sep_${sc} -orient vertical
    grid ${ptable}.sep_${sc} -row 0 -column $sc -rowspan 30 -sticky ns
}

# --- Data rows ---
array set seg_checked {}
set data_cells [dict create]

set seg_index 0
foreach seg_entry $segments {
    lassign $seg_entry seg_name is_campaign raw_data
    set grow $seg_index

    if {$is_campaign} {
        set seg_checked($seg_name) 1
        ttk::checkbutton ${ptable}.cb_${seg_index} -variable seg_checked($seg_name) \
            -command recalc_totals
        grid ${ptable}.cb_${seg_index} -row $grow -column 0 -sticky nsew
    }

    set lbl_opts [list -anchor w -padding {4 1}]
    set cnt_opts [list -anchor e -padding {2 1 1 1}]
    set pct_opts [list -anchor e -padding {0 1 2 1}]
    if {!$is_campaign} {
        lappend lbl_opts -foreground $::colours(muted_fg)
        lappend cnt_opts -foreground $::colours(muted_fg)
        lappend pct_opts -foreground $::colours(muted_fg)
    }

    ttk::label ${ptable}.seg_${seg_index} -text $seg_name {*}$lbl_opts
    grid ${ptable}.seg_${seg_index} -row $grow -column 1 -sticky nsew

    for {set ci 0} {$ci < 11} {incr ci} {
        set count [lindex $raw_data [expr {$ci * 2}]]
        set pct   [lindex $raw_data [expr {$ci * 2 + 1}]]
        lassign [dict get $ci_to_gcols $ci] ng pg

        ttk::label ${ptable}.dn_${seg_index}_${ci} -text $count {*}$cnt_opts
        grid ${ptable}.dn_${seg_index}_${ci} -row $grow -column $ng -sticky nsew

        set pct_text ""
        if {$pct ne "{}" && $pct ne ""} {
            set pct_text $pct
        }
        ttk::label ${ptable}.dp_${seg_index}_${ci} -text $pct_text {*}$pct_opts
        grid ${ptable}.dp_${seg_index}_${ci} -row $grow -column $pg -sticky nsew

        if {$is_campaign} {
            dict set data_cells $seg_name $ci count $count
        }
    }

    incr seg_index
}

# Update canvas scroll region and width tracking
proc update_data_scroll {} {
    global scroll_frame ptable
    set canvas ${scroll_frame}.canvas
    update idletasks
    set bbox [$canvas bbox all]
    $canvas configure -scrollregion $bbox
    # Match canvas width to the data frame
    $canvas configure -width [winfo reqwidth $ptable]
}

bind ${scroll_frame}.canvas <Configure> [list apply {{canvas ptable} {
    # Keep the embedded frame as wide as the canvas
    $canvas itemconfigure datawin -width [winfo width $canvas]
}} ${scroll_frame}.canvas $ptable]

# Mouse wheel scrolling — use a bindtag so all child widgets scroll the canvas
set scroll_canvas ${scroll_frame}.canvas
bind ScrollData <Button-4> [list $scroll_canvas yview scroll -3 units]
bind ScrollData <Button-5> [list $scroll_canvas yview scroll 3 units]
bind ScrollData <MouseWheel> [string map [list %CANVAS% $scroll_canvas] {
    %CANVAS% yview scroll [expr {-%D/120}] units
}]

# Add ScrollData tag to canvas and data frame (covers child widgets via propagation)
foreach w [list $scroll_canvas $ptable] {
    bindtags $w [linsert [bindtags $w] 1 ScrollData]
}
# Also add to all child widgets of the data frame after they're created
after idle [list apply {{ptable} {
    foreach child [winfo children $ptable] {
        bindtags $child [linsert [bindtags $child] 1 ScrollData]
    }
}} $ptable]

# --- Totals frame (fixed below scroll area) ---
set ptotals ${cpanel}.progress.totals
ttk::frame $ptotals
pack $ptotals -fill x -padx 2 -pady {0 2}
configure_table_columns $ptotals

ttk::label ${ptotals}.tot_lbl -text "TOTAL" -anchor w -font "TkDefaultFont 9 bold" \
    -background $::colours(totals_bg) -padding {4 2}
grid ${ptotals}.tot_lbl -row 0 -column 0 -columnspan 2 -sticky nsew

for {set ci 0} {$ci < 11} {incr ci} {
    lassign [dict get $ci_to_gcols $ci] ng pg
    ttk::label ${ptotals}.tn_${ci} -text "" -anchor e -font "TkDefaultFont 9 bold" \
        -background $::colours(totals_bg) -padding {2 2 1 2}
    grid ${ptotals}.tn_${ci} -row 0 -column $ng -sticky nsew
    ttk::label ${ptotals}.tp_${ci} -text "" -anchor e -font "TkDefaultFont 9 bold" \
        -background $::colours(totals_bg) -padding {0 2 2 2}
    grid ${ptotals}.tp_${ci} -row 0 -column $pg -sticky nsew
}

# Totals separators
foreach sc $sep_cols {
    ttk::separator ${ptotals}.sep_${sc} -orient vertical
    grid ${ptotals}.sep_${sc} -row 0 -column $sc -sticky ns
}

# Denominator parent indices for percentage:
# 0=valid, 1=profile(/valid), 2=star(/valid), 3=astar(/star), 4=email(/star),
# 5=aeml(/email), 6=linkedin(/star), 7=facebook(/star), 8=phone(/star),
# 9=sent(/aeml), 10=repl(/sent)
set denom_parent {-1 0 0 2 2 4 2 2 2 5 9}

proc recalc_totals {} {
    global seg_checked data_cells segments ptotals ci_to_gcols denom_parent

    set sums [list 0 0 0 0 0 0 0 0 0 0 0]
    foreach seg_entry $segments {
        lassign $seg_entry seg_name is_campaign raw_data
        if {!$is_campaign} continue
        if {![set ::seg_checked($seg_name)]} continue
        for {set ci 0} {$ci < 11} {incr ci} {
            lset sums $ci [expr {[lindex $sums $ci] + [dict get $data_cells $seg_name $ci count]}]
        }
    }

    for {set ci 0} {$ci < 11} {incr ci} {
        set count [lindex $sums $ci]
        set pi [lindex $denom_parent $ci]
        lassign [dict get $ci_to_gcols $ci] ng pg
        if {$pi == -1} {
            ${ptotals}.tn_${ci} configure -text $count
            ${ptotals}.tp_${ci} configure -text ""
        } else {
            set denom [lindex $sums $pi]
            ${ptotals}.tn_${ci} configure -text $count
            if {$denom == 0} {
                ${ptotals}.tp_${ci} configure -text "-"
            } else {
                set pct [expr {$count * 100 / $denom}]
                ${ptotals}.tp_${ci} configure -text "${pct}%"
            }
        }
    }
}

recalc_totals

# Initialise scroll region after layout
after idle update_data_scroll

# --- 2.3 Warnings (collapsed by default) ---

# Summarise warnings by category
set warn_dup_email 0
set warn_dup_name 0
set warn_dup_subject 0
set warn_other 0
foreach w $warnings {
    if {[string match "*Duplicate To:*" $w] || [string match "*Duplicate email:*" $w]} {
        incr warn_dup_email
    } elseif {[string match "*Duplicate name:*" $w]} {
        incr warn_dup_name
    } elseif {[string match "*Identical subject:*" $w]} {
        incr warn_dup_subject
    } else {
        incr warn_other
    }
}
set warn_parts {}
if {$warn_dup_email > 0} { lappend warn_parts "${warn_dup_email} duplicate email" }
if {$warn_dup_name > 0}  { lappend warn_parts "${warn_dup_name} duplicate name" }
if {$warn_dup_subject > 0} { lappend warn_parts "${warn_dup_subject} identical subject" }
if {$warn_other > 0}     { lappend warn_parts "${warn_other} other" }
set warn_summary [join $warn_parts ", "]

set warnings_expanded 0

ttk::frame ${cpanel}.warnings
pack ${cpanel}.warnings -fill x -padx 8 -pady {2 4}

set wframe ${cpanel}.warnings

ttk::button ${wframe}.toggle -text "\u25b6 \u26a0 [llength $warnings] warnings ($warn_summary)" \
    -command toggle_warnings -style Toolbutton
pack ${wframe}.toggle -fill x -anchor w

text ${wframe}.txt -height 5 -wrap word -font "TkDefaultFont 8" -state disabled \
    -background "#fff8e1" -relief flat
# Not packed initially — collapsed by default

${wframe}.txt tag configure bold -font "TkDefaultFont 8 bold"
${wframe}.txt configure -state normal
foreach w $warnings {
    set colon [string first ":" $w]
    if {$colon >= 0} {
        ${wframe}.txt insert end "\u2022 " {} [string range $w 0 $colon] bold [string range $w [expr {$colon+1}] end] {}
    } else {
        ${wframe}.txt insert end "\u2022 $w"
    }
    ${wframe}.txt insert end "\n"
}
${wframe}.txt configure -state disabled

proc toggle_warnings {} {
    global warnings_expanded wframe warnings warn_summary
    if {$warnings_expanded} {
        pack forget ${wframe}.txt
        ${wframe}.toggle configure -text "\u25b6 \u26a0 [llength $warnings] warnings ($warn_summary)"
        set warnings_expanded 0
    } else {
        pack ${wframe}.txt -fill x -padx 4 -pady 2
        ${wframe}.toggle configure -text "\u25bc \u26a0 [llength $warnings] warnings ($warn_summary)"
        set warnings_expanded 1
    }
}

# ============================================================
# Zone 3: Transition manager
# ============================================================

ttk::frame ${tpanel}.toolbar
pack ${tpanel}.toolbar -fill x -padx 4 -pady {4 0}

set show_completed 1
ttk::checkbutton ${tpanel}.toolbar.showcomplete -text "Show completed" \
    -variable show_completed
pack ${tpanel}.toolbar.showcomplete -side left

ttk::frame ${tpanel}.treeframe
pack ${tpanel}.treeframe -fill both -expand 1 -padx 4 -pady 2

ttk::treeview ${tpanel}.treeframe.tree -columns {org segment state reason} \
    -show {tree headings} -selectmode extended
ttk::scrollbar ${tpanel}.treeframe.vsb -orient vertical \
    -command [list ${tpanel}.treeframe.tree yview]
${tpanel}.treeframe.tree configure -yscrollcommand [list ${tpanel}.treeframe.vsb set]

pack ${tpanel}.treeframe.vsb -side right -fill y
pack ${tpanel}.treeframe.tree -fill both -expand 1

set tree ${tpanel}.treeframe.tree

$tree heading #0    -text "Transition / Contact"
$tree heading org   -text "Organisation"
$tree heading segment -text "Segment"
$tree heading state -text "State"
$tree heading reason -text "Pending Reason"

$tree column #0     -width 250 -minwidth 150
$tree column org    -width 200 -minwidth 100
$tree column segment -width 150 -minwidth 80
$tree column state  -width 70  -minwidth 50
$tree column reason -width 300 -minwidth 100

set ti 0
foreach tentry $transitions {
    lassign $tentry tlabel tcount ttasks

    set parent_id "t$ti"
    $tree insert {} end -id $parent_id -text "$tlabel ($tcount)" -open false

    foreach task $ttasks {
        lassign $task tname torg tseg tstate treason
        set tags {}
        if {$tstate eq "done"} {
            set tags {done}
        } elseif {$tstate eq "pending"} {
            set tags {pending}
        }
        $tree insert $parent_id end -text $tname \
            -values [list $torg $tseg $tstate $treason] -tags $tags
    }

    incr ti
}

$tree tag configure done    -foreground #999999
$tree tag configure pending -foreground #cc6600

# Dispatch controls — progress bar and log button appear only during dispatch
ttk::frame ${tpanel}.dispatch
pack ${tpanel}.dispatch -fill x -padx 4 -pady {0 4}

ttk::button ${tpanel}.dispatch.play -text "\u25b6 Dispatch" -state disabled
ttk::button ${tpanel}.dispatch.stop -text "\u23f9 Stop"     -state disabled

pack ${tpanel}.dispatch.play -side left -padx {0 4}
pack ${tpanel}.dispatch.stop -side left -padx {0 8}

# Progress bar and log button — hidden until a dispatch starts
ttk::progressbar ${tpanel}.dispatch.pbar -mode determinate -value 0
ttk::button ${tpanel}.dispatch.logbtn -text "Log\u2026" -command show_log_window
# Not packed yet — shown when dispatch begins

proc show_dispatch_bar {} {
    global tpanel
    pack ${tpanel}.dispatch.pbar -side left -fill x -expand 1 -padx {8 4}
    pack ${tpanel}.dispatch.logbtn -side left
}

# Log window (toplevel, opened on demand)
proc show_log_window {} {
    if {[winfo exists .logwin]} {
        wm deiconify .logwin
        raise .logwin
        return
    }
    toplevel .logwin
    wm title .logwin "Dispatch Log"

    ttk::frame .logwin.bar
    pack .logwin.bar -fill x -padx 4 -pady {4 0}
    ttk::button .logwin.bar.clear -text "Clear" -command {
        .logwin.txt configure -state normal
        .logwin.txt delete 1.0 end
        .logwin.txt configure -state disabled
    }
    pack .logwin.bar.clear -side right

    text .logwin.txt -wrap word -font "TkFixedFont 8" -state disabled
    ttk::scrollbar .logwin.sb -orient vertical -command {.logwin.txt yview}
    .logwin.txt configure -yscrollcommand {.logwin.sb set}

    pack .logwin.sb -side right -fill y -padx {0 4} -pady {0 4}
    pack .logwin.txt -fill both -expand 1 -padx {4 0} -pady {0 4}

    # Seed with mock log entries
    .logwin.txt configure -state normal
    .logwin.txt insert end "10:32:15 Campaign loaded: 2026-04 Partnership Outreach\n"
    .logwin.txt insert end "10:32:15 Scanned 22 segment directories, 487 roster entries\n"
    .logwin.txt insert end "10:32:16 Derived 441 profiled, 420 approached, 196 sent, 25 replied\n"
    .logwin.txt configure -state disabled

    wm protocol .logwin WM_DELETE_WINDOW {wm withdraw .logwin}
}

bind $tree <<TreeviewSelect>> [list apply {{tree play} {
    set sel [$tree selection]
    set enable 0
    foreach item $sel {
        if {[$tree parent $item] eq "" && [$tree children $item] ne ""} {
            set enable 1
            break
        }
    }
    $play configure -state [expr {$enable ? "normal" : "disabled"}]
}} $tree ${tpanel}.dispatch.play]

# Show the dispatch bar for the mock so the user can see it
show_dispatch_bar

# Set initial sash position so the campaign/progress table gets most of the space.
# The canvas requests only 100px, so weight-based allocation under-sizes the campaign
# panel.  Use a <Map> binding so the window is fully realised before we read its height.
bind .tabs.tab_current.pw <Map> {
    after 50 {
        set h [winfo height .tabs.tab_current.pw]
        if {$h > 100} {
            .tabs.tab_current.pw sashpos 0 [expr {int($h * 0.65)}]
        }
    }
    bind .tabs.tab_current.pw <Map> {}
}
