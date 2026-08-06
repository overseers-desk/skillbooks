#!/usr/bin/env tclsh9.0
# spar-lib.tcl — Shared library for SPAR batch scripts (Tcl port)
# Source this file or package require spar-lib.
# Works under both tclsh (CLI) and wish (GUI).

package require yaml
package require json
package require json::write
package require logger

namespace eval spar {
    namespace export slugify load_campaign load_roster \
        get_max_passes lang_instruction channel_desc \
        campaign_primary_channel campaign_secondary_channel \
        campaign_tertiary_channel campaign_in_scope_channels \
        roster_row_has_in_scope_channel render_rollcall
}

# _parse_fail_reason — split a dispatcher failure reason into {rc cause}.
# The reason is the flat string built by harness_run, e.g.
# "harness exited rc=2 | FAIL (... stalled ...): slug" or a bare
# "ses_send: <error>". Extract rc from an "rc=<n>" token (empty when absent)
# and take the cause as the text after the first " | " (the whole reason when
# there is no separator, so non-harness failures still read sensibly).
proc spar::_parse_fail_reason {reason} {
    set rc ""
    regexp {rc=(\d+)} $reason -> rc
    set sep [string first " | " $reason]
    if {$sep >= 0} {
        set cause [string range $reason [expr {$sep + 3}] end]
    } else {
        set cause $reason
    }
    return [list $rc $cause]
}

# render_rollcall — format a run-end per-contact roll-call from a list of
# outcome dicts (keys: slug, tid, outcome, reason). Returns a multi-line block
# naming every non-DONE contact with its phase, exit class, and cause, so an
# operator reads a worklist rather than a bare Failed count. Empty string when
# there are no records (the caller then prints nothing extra).
proc spar::render_rollcall {records} {
    if {[llength $records] == 0} { return "" }
    set lines [list "Non-DONE contacts:"]
    foreach rec $records {
        set slug    [dict get $rec slug]
        set tid     [expr {[dict exists $rec tid] ? [dict get $rec tid] : ""}]
        set outcome [expr {[dict exists $rec outcome] ? [dict get $rec outcome] : "failed"}]
        set reason  [expr {[dict exists $rec reason] ? [dict get $rec reason] : ""}]
        lassign [spar::_parse_fail_reason $reason] rc cause
        set fields [list $slug]
        if {$tid ne ""}   { lappend fields "\[$tid\]" }
        lappend fields [expr {$rc ne "" ? "rc=$rc" : $outcome}]
        if {$cause ne ""} { lappend fields $cause }
        lappend lines "  [join $fields {  }]"
    }
    return [join $lines "\n"]
}

# _campaign_channel_slot — internal shared implementation for
# campaign_{primary,secondary,tertiary}_channel. Normalises the bare-string
# and map forms documented in spar-campaign-yaml.md §Channels. Returns ""
# when the slot is unset or unparseable.
proc spar::_campaign_channel_slot {cdata key} {
    if {![dict exists $cdata $key]} { return "" }
    set pc [dict get $cdata $key]
    if {[llength $pc] <= 1} { return $pc }
    if {[dict exists $pc channel]} { return [dict get $pc channel] }
    return ""
}

proc spar::campaign_primary_channel {cdata} {
    return [spar::_campaign_channel_slot $cdata primary_channel]
}

proc spar::campaign_secondary_channel {cdata} {
    return [spar::_campaign_channel_slot $cdata secondary_channel]
}

proc spar::campaign_tertiary_channel {cdata} {
    return [spar::_campaign_channel_slot $cdata tertiary_channel]
}

# campaign_in_scope_channels — list of channel names configured on a
# campaign via the primary/secondary/tertiary slots, in that order. Empty
# slots are omitted. Used by dispatch to decide whether a roster row has
# at least one field populated that the campaign cares about.
proc spar::campaign_in_scope_channels {cdata} {
    set out {}
    foreach key {primary_channel secondary_channel tertiary_channel} {
        set ch [spar::_campaign_channel_slot $cdata $key]
        if {$ch ne "" && $ch ni $out} { lappend out $ch }
    }
    return $out
}

# roster_row_has_in_scope_channel — a roster row is dispatchable for A
# when it has at least one field populated for a channel that the
# campaign has declared in its primary/secondary/tertiary slots. Empty
# channel list (campaign declares no slots) returns 1 so pre-#41
# campaigns that relied on the old filter.require_email gate don't
# suddenly block everything.
#
# row        dict with roster fields (email, linkedin_url, facebook_url, phone)
# channels   list from campaign_in_scope_channels; values are the
#            documented channel names: email, linkedin, facebook, phone.
proc spar::roster_row_has_in_scope_channel {row channels} {
    if {[llength $channels] == 0} { return 1 }
    foreach ch $channels {
        switch -- $ch {
            email {
                set v [string trim [dict getdef $row email ""]]
                if {[string match *@* $v]} { return 1 }
            }
            linkedin {
                set v [string trim [dict getdef $row linkedin_url ""]]
                if {$v ne ""} { return 1 }
            }
            facebook {
                set v [string trim [dict getdef $row facebook_url ""]]
                if {$v ne ""} { return 1 }
            }
            phone {
                set v [string trim [dict getdef $row phone ""]]
                if {$v ne ""} { return 1 }
            }
        }
    }
    return 0
}

# slugify — lowercase, strip accents, collapse to hyphens
proc spar::slugify {s} {
    set s [string tolower $s]
    regsub -all -- {[^a-z0-9]} $s {-} s
    regsub -all -- {--+} $s {-} s
    set s [string trim $s -]
    return $s
}

# yaml_parse — parse YAML text through tcllib yaml, guarding its 0.4.2 hang on
# input whose last line is an empty-valued key with no trailing newline (e.g.
# "a: 1\nkey:", which loops forever). A trailing newline is insignificant to
# YAML, so supplying one when absent removes the hang without changing meaning.
proc spar::yaml_parse {text} {
    if {[string index $text end] ne "\n"} { append text \n }
    return [::yaml::yaml2dict $text]
}

# load_campaign — parse campaign YAML, resolve relative paths against YAML dir
# Port of spar-a-batch.sh lines 27-67
proc spar::load_campaign {yaml_path} {
    set yaml_path [file normalize $yaml_path]
    if {![file exists $yaml_path]} {
        error "Campaign file not found: $yaml_path"
    }
    set base [file dirname $yaml_path]
    set fd [open $yaml_path r]
    set raw [read $fd]
    close $fd
    set data [spar::yaml_parse $raw]

    # Resolve path fields relative to YAML directory
    foreach key {usp_document antifacts campaign_principles} {
        if {[dict exists $data $key]} {
            set val [dict get $data $key]
            if {$val ne "" && $val ne "~" && $val ne "null"} {
                if {[string index $val 0] ne "/"} {
                    dict set data $key [file normalize [file join $base $val]]
                }
            } else {
                dict set data $key ""
            }
        }
    }

    # Validate prompt_appendices (closed vocabulary)
    if {[dict exists $data prompt_appendices]} {
        set app [dict get $data prompt_appendices]
        set allowed {p_author a_author a_challenger a_assembly}
        dict for {k v} $app {
            if {$k ni $allowed} {
                error "Campaign $yaml_path: unknown prompt_appendices key '$k' (allowed: $allowed)"
            }
        }
    }

    # Validate start_date (optional planned first-approach date). Absent
    # means the campaign has not launched: outgoing transitions block.
    # Present, it is the floor the BI reply derivation keys on, so a
    # malformed value is an error, not a warning.
    if {[dict exists $data start_date]} {
        set sd [dict get $data start_date]
        # yaml2dict parses an unquoted date to epoch seconds; a quoted one
        # stays an ISO string. Normalise to ISO so every consumer compares
        # dates lexically.
        if {[string is wideinteger -strict $sd]} {
            set sd [clock format $sd -format %Y-%m-%d]
            dict set data start_date $sd
        }
        if {![regexp {^\d{4}-\d{2}-\d{2}$} $sd] \
                || [catch {clock scan $sd -format %Y-%m-%d -gmt 1}]} {
            error "Campaign $yaml_path: start_date must be a valid YYYY-MM-DD date (got '$sd')"
        }
    }

    # skip_segments is retired in spec 2.0: only segments/<seg> entries
    # named by the segments: map are read, so there is nothing to fence.
    if {[dict exists $data skip_segments]} {
        puts stderr "Campaign $yaml_path: skip_segments is retired (spec 2.0) and ignored"
    }

    # Validate a_max_passes (hard ceiling on A-phase challenger passes).
    # Integer ≥ 0. 0 disables the challenger entirely (initial draft flows
    # straight to assembly with no fact-check). Absent = default 3, applied
    # at dispatch time.
    if {[dict exists $data a_max_passes]} {
        set v [dict get $data a_max_passes]
        if {![string is integer -strict $v] || $v < 0} {
            error "Campaign $yaml_path: a_max_passes must be an integer ≥ 0 (got '$v')"
        }
    }

    # Validate venue (optional). When present, the dispatcher exposes the
    # address and coordinate to the P prompt so AI-side OSRM can compute
    # target-to-venue driving distance for proximity-relevant angles
    # without guessing. #93 tracks moving the OSRM call
    # itself into the harness.
    if {[dict exists $data venue]} {
        set venue [dict get $data venue]
        set vaddr [string trim [dict getdef $venue address ""]]
        if {$vaddr eq ""} {
            error "Campaign $yaml_path: venue.address must be a non-empty string when venue is present"
        }
        if {![dict exists $venue coordinate]} {
            error "Campaign $yaml_path: venue.coordinate is required when venue is present"
        }
        set coord [dict get $venue coordinate]
        foreach k {latitude longitude} {
            if {![dict exists $coord $k]} {
                error "Campaign $yaml_path: venue.coordinate.$k is required"
            }
            set cv [dict get $coord $k]
            if {![string is double -strict $cv]} {
                error "Campaign $yaml_path: venue.coordinate.$k must be numeric (got '$cv')"
            }
        }
    }

    # Store base directory for later use
    dict set data _base $base

    return $data
}

# resolve_campaign -- shared campaign resolution for the CLI tools
# (spar-progress, spar-validate-cli). Given the campaign spec already teased
# out of argv — a campaign.yaml path in campaign_file, or a directory in
# campaign_dir; either may be empty — discover the campaign YAML, load it, and
# build the list of {label seg_dir} segment paths that carry a roster.
#
# Returns a dict with keys: yaml_path campaign_dir cdata segment_paths
#                           campaign_name min_star primary_channel
# Throws on: campaign YAML not found, or no segments with a roster.
proc spar::resolve_campaign {campaign_file campaign_dir} {
    if {$campaign_file ne ""} {
        set yaml_path [file normalize $campaign_file]
        set campaign_dir [spar::instance_root_for_yaml $yaml_path]
    } else {
        if {$campaign_dir eq ""} { set campaign_dir "." }
        set campaign_dir [file normalize $campaign_dir]
        set candidates [lsort [glob -nocomplain \
            [file join $campaign_dir campaigns *.yaml]]]
        # Only definition files: a dotted doc (2026-07-x.usp.yaml would be
        # unusual, but the rule is cheap) has more than one dot-part.
        set candidates [lmap c $candidates {
            expr {[llength [split [file tail $c] .]] == 2 ? $c : [continue]}
        }]
        set yaml_path [expr {[llength $candidates] > 0 ? [lindex $candidates end] : ""}]
    }
    if {$yaml_path eq "" || ![file exists $yaml_path]} {
        if {$campaign_file ne ""} {
            error "Campaign YAML not found: $campaign_file"
        } else {
            error "No campaign YAML found under $campaign_dir/campaigns/"
        }
    }

    set cdata [spar::load_campaign $yaml_path]
    set campaign_name [dict getdef $cdata campaign [file tail $yaml_path]]
    set primary_channel [spar::campaign_primary_channel $cdata]
    set min_star 0
    if {[dict exists $cdata filter]} {
        set min_star [dict getdef [dict get $cdata filter] min_star 0]
    }
    set segments_list [spar::campaign_segment_names $cdata]

    set segment_paths {}
    foreach seg $segments_list {
        set seg_dir [file join $campaign_dir segments $seg]
        if {[file isdirectory $seg_dir] \
                && [file exists [spar::roster_path_for_segment $seg_dir]]} {
            lappend segment_paths [list $seg $seg_dir]
        }
    }
    if {[llength $segment_paths] == 0} {
        error "No segments found."
    }

    return [dict create yaml_path $yaml_path campaign_dir $campaign_dir \
        cdata $cdata segment_paths $segment_paths campaign_name $campaign_name \
        min_star $min_star primary_channel $primary_channel]
}

# instance_root_for_yaml: the instance root of a campaign YAML at
# <root>/campaigns/<camp>.yaml. Errors when the YAML does not sit in a
# campaigns/ folder, which is the spec-2.0 shape the tool supports.
proc spar::instance_root_for_yaml {yaml_path} {
    set yaml_path [file normalize $yaml_path]
    set parent [file dirname $yaml_path]
    if {[file tail $parent] ne "campaigns"} {
        error "Campaign YAML $yaml_path is not under a campaigns/ folder (spec 2.0 layout; see spar-version-uplift-runbook.md)"
    }
    return [file dirname $parent]
}

# extract_required_skills — convert a segment's profile_reject_if list into
# the platform-token list audit_skills_in_transcript expects. Validates the closed
# vocabulary; errors on unknown conditions or wrong shape. Empty list when
# the field is absent or empty (no audit).
#
# segment_data    parsed segment.yaml dict
# segment_path    path used for error messages
proc spar::extract_required_skills {segment_data segment_path} {
    if {![dict exists $segment_data profile_reject_if]} {
        return {}
    }
    set conditions [dict get $segment_data profile_reject_if]
    set skills {}
    foreach cond $conditions {
        switch -- $cond {
            linkedin_not_invoked {
                if {"linkedin" ni $skills} { lappend skills linkedin }
            }
            facebook_not_invoked {
                if {"facebook" ni $skills} { lappend skills facebook }
            }
            default {
                error "Segment $segment_path: unknown profile_reject_if condition '$cond' (allowed: linkedin_not_invoked, facebook_not_invoked)"
            }
        }
    }
    return $skills
}

# roster_core_columns — the 14 columns spar-roster-format.md defines, in
# its order. A live roster's header is authoritative (campaigns add their
# own columns, e.g. application_url) and every reader takes the header it
# finds; this list is for the one case where there is no header yet — the
# first sweep of a segment, creating the roster.
proc spar::roster_core_columns {} {
    return {stem contact_name organisation role phone email linkedin_url \
            facebook_url sweep_iteration discovered_via date_excluded \
            s_note p_note star_rating}
}

# load_roster — read TSV, return list of dicts keyed by header columns
# Port of spar-p-batch.sh lines 129-167 and spar_lib.py load_roster()
proc spar::load_roster {tsv_path} {
    set fd [open $tsv_path r]
    fconfigure $fd -translation binary
    set raw [read $fd]
    close $fd

    # TSV is UTF-8; binary translation read it as bytes, so decode explicitly.
    # Without this, non-ASCII names (e.g. "Söderbom", "Café") round-trip as
    # Latin-1 and emerge as mojibake on a UTF-8 stdout.
    set raw [encoding convertfrom utf-8 $raw]

    # Normalise line endings: CRLF → LF, bare CR → LF
    set raw [string map {\r\n \n \r \n} $raw]
    set lines [split $raw \n]

    if {[llength $lines] == 0} {
        return {}
    }

    set header_line [lindex $lines 0]
    set headers [split $header_line \t]

    set header_count [llength $headers]
    set rows {}
    set line_num 1
    foreach line [lrange $lines 1 end] {
        incr line_num
        if {$line eq ""} continue
        set fields [split $line \t]
        set field_count [llength $fields]
        if {$field_count < $header_count} {
            error "Error: roster $tsv_path line $line_num has $field_count fields, expected $header_count — truncated row"
        }
        set row [dict create]
        if {$field_count > $header_count} {
            dict set row _field_count_warning "line $line_num has $field_count fields, expected $header_count"
        }
        set i 0
        foreach h $headers {
            if {$i < [llength $fields]} {
                dict set row $h [lindex $fields $i]
            } else {
                dict set row $h ""
            }
            incr i
        }
        # Skip rows where all values are empty
        set has_value 0
        dict for {k v} $row {
            if {[string trim $v] ne ""} {
                set has_value 1
                break
            }
        }
        if {$has_value} {
            lappend rows $row
        }
    }
    return $rows
}

# write_roster — write rows back to a TSV, preserving column order.
# If $headers is empty, reads the header line from $tsv_path (the classic
# same-file rewrite). Pass $headers explicitly when writing to a tmp file
# for atomic rename (the target doesn't exist yet).
proc spar::write_roster {tsv_path rows {headers {}}} {
    if {[llength $rows] == 0} return

    if {[llength $headers] == 0} {
        set fd [open $tsv_path r]
        fconfigure $fd -translation binary
        gets $fd header_line
        close $fd
        set header_line [string map {\r\n "" \r ""} $header_line]
        set headers [split $header_line \t]
    }

    set fd [open $tsv_path w]
    fconfigure $fd -translation lf
    puts $fd [join $headers \t]
    foreach row $rows {
        set fields {}
        foreach h $headers {
            lappend fields [dict getdef $row $h ""]
        }
        puts $fd [join $fields \t]
    }
    close $fd
}

# update_roster_field — set one field on the row matching key_col=key_val.
# Atomic for the target file (write to sibling tmp + rename), but assumes
# the caller has serialised concurrent writers. The dispatcher's single
# event loop is the sole serialiser today: every worker runs as a jobloop
# coroutine on the one thread, so a worker (the profile harness's
# masked-email guardrail) calls this directly and no two writes interleave.
# If a future caller writes the TSV from multiple processes, reintroduce
# flock here. Returns the count of rows updated. Errors if no row matches.
proc spar::update_roster_field {tsv_path key_col key_val field_col new_val} {
    if {![file exists $tsv_path]} {
        error "roster not found: $tsv_path"
    }

    set fd [open $tsv_path r]
    fconfigure $fd -translation binary
    gets $fd header_line
    close $fd
    set header_line [string map {\r\n "" \r ""} $header_line]
    set headers [split $header_line \t]

    set rows [spar::load_roster $tsv_path]
    set updated 0
    set out_rows {}
    foreach row $rows {
        if {[dict exists $row $key_col] \
            && [dict get $row $key_col] eq $key_val} {
            dict set row $field_col $new_val
            incr updated
        }
        lappend out_rows $row
    }
    if {$updated == 0} {
        error "no row matched $key_col='$key_val' in $tsv_path"
    }

    set tmp [exec mktemp "${tsv_path}.XXXXXX"]
    try {
        spar::write_roster $tmp $out_rows $headers
        file rename -force $tmp $tsv_path
        set tmp ""
    } finally {
        if {$tmp ne "" && [file exists $tmp]} { catch {file delete $tmp} }
    }
    return $updated
}

# apply_roster_patch — harness-mediated roster writes. A harnessed worker
# declares roster changes in its deliverable's front matter instead of
# writing the TSV itself; this proc validates the declaration and applies
# it, so a worker defect can corrupt at most its own declaration, not the
# roster (the 2026-07-17 incident was a worker UPDATE without a WHERE
# clause reaching 249 rows). Three declaration surfaces:
#   star_rating          — authoritative in the deliverable; the roster
#                          column is a derived cache, synced whenever the
#                          two differ. No stamp: sync is unconditional.
#   roster_patch         — dict of one-shot column writes. One-shot
#                          because a later comparison cannot distinguish
#                          "not yet applied" from "a human corrected the
#                          roster afterwards"; the roster_patch_applied
#                          stamp written back into the deliverable makes
#                          a replay inert and protects the human's edit.
#   sweep_feedback       — list of {kind note} observations, appended to
#                          the segment's sweep-feedback.tsv. Gated by the
#                          same stamp so a reconcile replay cannot
#                          double-append.
# Serialisation matches update_roster_field: the dispatcher's single
# event loop is the sole writer. Returns a list of issue dicts
# (severity/code/message), empty when applied clean; issues feed the
# caller's fix loop.
proc spar::apply_roster_patch {profile_path roster_path stem} {
    set fm [spar::read_profile_front_matter $profile_path]
    if {$fm eq ""} { return {} }

    set issues {}
    set rows [spar::load_roster $roster_path]
    set row ""
    foreach r $rows {
        if {[dict getdef $r stem ""] eq $stem} { set row $r; break }
    }
    if {$row eq ""} {
        return [list [dict create severity error code patch_stem_unknown \
            message "roster_patch: stem '$stem' has no roster row in $roster_path"]]
    }

    set pending {}

    # star_rating: deliverable is home, roster is cache. An excluded row
    # is left alone: exclusion (typically A-phase, star 0 + date_excluded)
    # outranks the profile's pre-exclusion star, and syncing it back
    # would resurrect an excluded contact.
    if {[dict exists $fm star_rating] \
            && [dict getdef $row date_excluded ""] eq ""} {
        set s [dict get $fm star_rating]
        if {[string is integer -strict $s] \
                && [dict getdef $row star_rating ""] ne $s} {
            dict set pending star_rating $s
        }
    }

    set stamped [dict exists $fm roster_patch_applied]
    # star_rating is admitted for the A-phase exclusion write (star 0 with
    # date_excluded); P declares its star through the front matter itself.
    set allowed {contact_name organisation role phone email \
                 linkedin_url facebook_url date_excluded p_note star_rating}

    if {[dict exists $fm roster_patch] && !$stamped} {
        dict for {k v} [dict get $fm roster_patch] {
            if {$k ni $allowed} {
                lappend issues [dict create severity error \
                    code patch_unknown_column \
                    message "roster_patch key '$k' is not an applyable roster column (allowed: $allowed)"]
                continue
            }
            if {$k eq "email" && [string match {*\**} $v]} {
                lappend issues [dict create severity error \
                    code patch_masked_email \
                    message "roster_patch email '$v' is masked; find the unmasked address or omit the key"]
                continue
            }
            dict set pending $k $v
        }
    }

    if {[llength $issues]} { return $issues }

    if {[dict size $pending]} {
        set fd [open $roster_path r]
        fconfigure $fd -translation binary
        gets $fd header_line
        close $fd
        set header_line [string map {\r\n "" \r ""} $header_line]
        set headers [split $header_line \t]
        foreach r $rows {
            if {[dict getdef $r stem ""] eq $stem} {
                dict for {k v} $pending { dict set r $k $v }
            }
            lappend out_rows $r
        }
        set tmp [exec mktemp "${roster_path}.XXXXXX"]
        try {
            spar::write_roster $tmp $out_rows $headers
            file rename -force $tmp $roster_path
            set tmp ""
        } finally {
            if {$tmp ne "" && [file exists $tmp]} { catch {file delete $tmp} }
        }
    }

    if {!$stamped && ([dict exists $fm roster_patch] \
                      || [dict exists $fm sweep_feedback])} {
        if {[dict exists $fm sweep_feedback]} {
            set fb_path [spar::sweep_feedback_path_for_segment [file rootname $roster_path]]
            set fd [open $fb_path a]
            foreach entry [dict get $fm sweep_feedback] {
                set kind [dict getdef $entry kind observation]
                set note [string map {\t " " \n " "} [dict getdef $entry note ""]]
                if {$note ne ""} { puts $fd "$stem\t$kind\t$note" }
            }
            close $fd
        }
        spar::_stamp_patch_applied $profile_path
    }
    return {}
}

# apply_approach_patch — the A-phase twin of apply_roster_patch. Approach
# files are whole-file YAML rather than front-matter documents, so the
# declaration is a root roster_patch key; the stamp is appended as a root
# line. No star sync: the approach is not star_rating's home. Same
# one-shot semantics and issue-list return.
proc spar::apply_approach_patch {approach_path roster_path stem} {
    if {[catch {spar::read_approach_yaml $approach_path} adata]} { return {} }
    if {$adata eq "" || ![dict exists $adata roster_patch]} { return {} }
    if {[dict exists $adata roster_patch_applied]} { return {} }
    set fm [dict create \
        roster_patch [dict get $adata roster_patch]]
    set issues [spar::_apply_patch_only $fm $roster_path $stem]
    if {[llength $issues] == 0} {
        set fd [open $approach_path a]
        puts $fd "roster_patch_applied: [clock format [clock seconds] -format %Y-%m-%d]"
        close $fd
    }
    return $issues
}

# _apply_patch_only — shared core: validate a roster_patch dict and write
# the pending columns onto the stem's roster row in one atomic rewrite.
proc spar::_apply_patch_only {fm roster_path stem} {
    set issues {}
    set rows [spar::load_roster $roster_path]
    set found 0
    foreach r $rows {
        if {[dict getdef $r stem ""] eq $stem} { set found 1; break }
    }
    if {!$found} {
        return [list [dict create severity error code patch_stem_unknown \
            message "roster_patch: stem '$stem' has no roster row in $roster_path"]]
    }
    set allowed {contact_name organisation role phone email \
                 linkedin_url facebook_url date_excluded p_note star_rating}
    set pending {}
    dict for {k v} [dict get $fm roster_patch] {
        if {$k ni $allowed} {
            lappend issues [dict create severity error \
                code patch_unknown_column \
                message "roster_patch key '$k' is not an applyable roster column (allowed: $allowed)"]
            continue
        }
        if {$k eq "email" && [string match {*\**} $v]} {
            lappend issues [dict create severity error \
                code patch_masked_email \
                message "roster_patch email '$v' is masked; find the unmasked address or omit the key"]
            continue
        }
        dict set pending $k $v
    }
    if {[llength $issues]} { return $issues }
    if {[dict size $pending] == 0} { return {} }
    set fd [open $roster_path r]
    fconfigure $fd -translation binary
    gets $fd header_line
    close $fd
    set header_line [string map {\r\n "" \r ""} $header_line]
    set headers [split $header_line \t]
    set out_rows {}
    foreach r $rows {
        if {[dict getdef $r stem ""] eq $stem} {
            dict for {k v} $pending { dict set r $k $v }
        }
        lappend out_rows $r
    }
    set tmp [exec mktemp "${roster_path}.XXXXXX"]
    try {
        spar::write_roster $tmp $out_rows $headers
        file rename -force $tmp $roster_path
        set tmp ""
    } finally {
        if {$tmp ne "" && [file exists $tmp]} { catch {file delete $tmp} }
    }
    return {}
}

# _stamp_patch_applied — insert roster_patch_applied into the deliverable's
# front matter, before the closing --- delimiter. tmp+rename like the
# roster writes, so a crash leaves the old file whole.
proc spar::_stamp_patch_applied {profile_path} {
    set fd [open $profile_path r]
    set content [read $fd]
    close $fd
    set lines [split $content \n]
    set out {}
    set delims 0
    set today [clock format [clock seconds] -format %Y-%m-%d]
    foreach line $lines {
        if {[string trim $line] eq "---" && [incr delims] == 2} {
            lappend out "roster_patch_applied: $today"
        }
        lappend out $line
    }
    set tmp [exec mktemp "${profile_path}.XXXXXX"]
    try {
        set fd [open $tmp w]
        puts -nonewline $fd [join $out \n]
        close $fd
        file rename -force $tmp $profile_path
        set tmp ""
    } finally {
        if {$tmp ne "" && [file exists $tmp]} { catch {file delete $tmp} }
    }
}

# get_max_passes — determine max A2 spar passes from profile yield.
# Reads the profile's YAML front matter (see spar-P-profile.md §5.1) for the
# canonical `yield` integer (substantive data points). Returns 3 when yield ≥ 6,
# 1 otherwise (including when the profile is missing or unparseable).
proc spar::get_max_passes {profile_path} {
    if {$profile_path eq "" || ![file exists $profile_path]} {
        return 1
    }
    # read_profile_front_matter lives in spar-state.tcl; guard for callers that
    # source only spar-lib.tcl. Use the fully-qualified name: this proc runs in
    # the ::spar namespace, where a relative pattern resolves against
    # ::spar:: and never matches the real ::spar::read_profile_front_matter.
    if {[info procs ::spar::read_profile_front_matter] eq ""} {
        return 1
    }
    set fm [spar::read_profile_front_matter $profile_path]
    if {$fm eq "" || ![dict exists $fm yield]} {
        return 1
    }
    set y [dict get $fm yield]
    if {[string is integer -strict $y] && $y >= 6} {
        return 3
    }
    return 1
}

# lang_instruction — map language code to instruction string
# Port of spar-a-batch.sh lines 81-86
proc spar::lang_instruction {code} {
    switch -- $code {
        en-gb   { return "Use British English." }
        en-au   { return "Use Australian English." }
        en      { return "Use English." }
        default { return "Write in the language specified by code: $code." }
    }
}

# channel_desc — channel selection per SPAR-A §4.2
# Port of spar-a-batch.sh lines 221-230
proc spar::channel_desc {linkedin phone} {
    set has_linkedin [expr {$linkedin ne ""}]
    set has_phone [expr {$phone ne "" && [regexp {\d} $phone]}]

    if {$has_linkedin} {
        if {$has_phone} {
            return "Per SPAR-A §4.2: LinkedIn + email + phone = prepare (1) LinkedIn connection note, (2) email after acceptance or 5 days, (3) phone follow-up if no email reply after 3 days."
        } else {
            return "Per SPAR-A §4.2: LinkedIn + email = prepare (1) LinkedIn connection note, (2) email after acceptance or 5 days."
        }
    } elseif {$has_phone} {
        return "Per SPAR-A §4.2: email + phone, no LinkedIn = prepare (1) email, (2) phone follow-up script."
    } else {
        return "Per SPAR-A §4.2: email only, no phone, no LinkedIn = email only."
    }
}

# is_null — check for YAML null representations
proc spar::is_null {val} {
    set v [string trim $val]
    return [expr {$v eq "" || $v eq "~" || $v eq "None" || $v eq "null"}]
}

# campaign_segment_names — return the list of segment names from a campaign
# dict, accepting both the current map form (segments: a map from name to a
# per-segment plan block) and the legacy list form (segments: a bare list of
# names). The YAML parser represents both as flat Tcl lists; _segments_is_map
# discriminates structurally, so no campaign-version dependency is needed and
# the two shapes can coexist across the migration. Returns {} when absent.
proc spar::campaign_segment_names {cdata} {
    if {![dict exists $cdata segments]} { return {} }
    set segs [dict get $cdata segments]
    if {[llength $segs] == 0} { return {} }
    if {[spar::_segments_is_map $segs]} {
        return [dict keys $segs]
    }
    return $segs
}

# _segments_is_map — true when a parsed `segments` value is the map form
# (name -> plan block) rather than the legacy bare-name list. In list form
# every value position is a bare segment slug (one word, odd token length);
# in map form every value is a plan block (empty, or an even-length dict).
# A bare name in a value position therefore rules out the map reading.
proc spar::_segments_is_map {segs} {
    if {[llength $segs] % 2 != 0} { return 0 }
    foreach {k v} $segs {
        if {$v ne "" && [llength $v] % 2 != 0} { return 0 }
    }
    return 1
}

# filter_segments — keep only segments named in sel_segments. Empty
# sel_segments means no filtering (return original list).
proc spar::filter_segments {segments sel_segments} {
    if {[llength $sel_segments] == 0} { return $segments }
    set out {}
    foreach s $segments {
        if {$s in $sel_segments} { lappend out $s }
    }
    return $out
}

# resolve_logs_dir — pick a campaign-wide logs directory for a phase
# run. user_logs (if non-empty) overrides; otherwise the folder name
# encodes the campaign yaml's directory + stem + phase + datestamp so
# sibling campaigns don't pile into ambiguous sibling folders. Creates
# the directory unless user_logs was supplied. phase is "p" or "a".
proc spar::resolve_logs_dir {campaign_file phase datestamp user_logs} {
    if {$user_logs ne ""} {
        if {![file isdirectory $user_logs]} {
            error "Log directory not found: $user_logs"
        }
        return $user_logs
    }
    set stem [file rootname [file tail $campaign_file]]
    set dir_slug [string map {/ -} \
        [file dirname [file normalize $campaign_file]]]
    set folder "${dir_slug}-${stem}-${phase}-${datestamp}"
    set logs_dir [file join [spar::logs_root] $folder]
    file mkdir $logs_dir
    return $logs_dir
}

# logs_root — base directory for SPAR run logs: the system path when it
# exists (persistent, multi-user), else a per-user fallback. Single source
# for resolve_logs_dir's per-phase dirs and the orchestration log.
proc spar::logs_root {} {
    if {[file isdirectory /var/local/log/spar]} {
        return /var/local/log/spar
    }
    return [file join $::env(HOME) logs spar]
}

# Orchestration log (FM-LOG-1). The spar::transitions / spar::dispatch
# logger services emit only to stderr by default, so a dispatch run launched
# without shell redirection leaves no on-disk record of its outcomes
# (START/DONE/FAIL/Summary). install_orchestration_log tees those services
# to a file so a run is traceable from its log root regardless of how it was
# launched. Per-row worker (spar::harness) lines run in separate tpool
# interps and are not captured here; they persist in the per-row artifacts
# under resolve_logs_dir.
namespace eval ::spar { variable _orch_logfile "" }

# Logger service for per-row dispatch outcomes (FM-LOG-1), shared by the
# CLI and the GUI so both front-ends render the same line format via
# spar::log_row_outcome below.
namespace eval ::spar { variable transitions_log [logger::init spar::transitions] }

proc spar::_orch_format {service level txt} {
    return "\[[clock format [clock seconds]]\] \[$service\] \[$level\] '$txt'"
}

# _orch_write — file half of the orchestration tee. Safe to call from any
# logger sink; a no-op until ensure_orchestration_file has set the path.
proc spar::_orch_write {service level txt} {
    if {$::spar::_orch_logfile eq ""} return
    catch {
        set fd [open $::spar::_orch_logfile a]
        puts $fd [spar::_orch_format $service $level $txt]
        close $fd
    }
}

proc spar::_orch_emit {service level txt} {
    catch {puts stderr [spar::_orch_format $service $level $txt]}
    spar::_orch_write $service $level $txt
}

# ensure_orchestration_file — single home for the orchestration log's path
# policy: no file on dry runs, one file per process, named for the campaign
# and the moment the first real dispatch began. Returns the path, or "" on
# a dry run. Idempotent: a second call returns the path already minted.
proc spar::ensure_orchestration_file {campaign_file dry_run} {
    if {$dry_run} { return "" }
    if {$::spar::_orch_logfile ne ""} { return $::spar::_orch_logfile }
    set stamp [clock format [clock seconds] -format %Y%m%d-%H%M%S]
    set logfile [file join [spar::logs_root] \
        "orchestration-[file rootname [file tail $campaign_file]]-$stamp.log"]
    file mkdir [file dirname $logfile]
    set ::spar::_orch_logfile $logfile
    return $logfile
}

proc spar::install_orchestration_log {services} {
    foreach svc $services {
        set log [logger::init $svc]
        foreach lvl {debug info notice warn error critical alert emergency} {
            ${log}::logproc $lvl txt [format {::spar::_orch_emit %s %s $txt} $svc $lvl]
        }
    }
}

# log_row_outcome — the one renderer for per-row dispatch outcomes, shared
# by both front-ends so the line format has a single home (FM-LOG-1).
# dry_run swaps the done glyph so a rehearsal is visibly not a send.
proc spar::log_row_outcome {slug status message {dry_run 0}} {
    switch -- $status {
        started { if {$message eq ""} { ${::spar::transitions_log}::info "  \[START\] $slug" } }
        done    { ${::spar::transitions_log}::info "  \[[expr {$dry_run ? " ○   " : "DONE "}]\] $slug[expr {$message ne "" ? " ($message)" : ""}]" }
        failed  { ${::spar::transitions_log}::error "  \[FAIL \] $slug ($message)" }
        retry   { ${::spar::transitions_log}::warn "  \[RETRY\] $slug ($message)" }
        skipped { ${::spar::transitions_log}::info "  \[SKIP \] $slug ($message)" }
        warning { ${::spar::transitions_log}::warn "  \[WARN \] $slug: $message" }
    }
}

# Path conventions for the spec-2.0 instance layout. SSOT: every consumer
# that resolves a segment artefact or a stem-keyed file uses these. Layout
# per spar-campaign-directory.md: the instance root holds segments/ and
# campaigns/; a definition file and a same-stem folder of its contents sit
# side by side (segments/<seg>.yaml + segments/<seg>/, campaigns/<camp>.yaml
# + campaigns/<camp>/).
#
# segment_dir is segments/<seg>, the folder holding profile files directly
# (no profiles/ wrapper). The roster and segment definition are its dotted
# stem siblings.
proc spar::profile_dir_for_segment {segment_dir} {
    return $segment_dir
}
proc spar::roster_path_for_segment {segment_dir} {
    return "${segment_dir}.tsv"
}
proc spar::segment_yaml_for_segment {segment_dir} {
    return "${segment_dir}.yaml"
}
proc spar::sweep_feedback_path_for_segment {segment_dir} {
    return "${segment_dir}.sweep-feedback.tsv"
}
proc spar::sweep_yaml_for_segment {segment_dir} {
    return "${segment_dir}.sweep.yaml"
}
proc spar::profile_path_for_stem {segment_dir stem} {
    return [file join [spar::profile_dir_for_segment $segment_dir] "${stem}.md"]
}
# An approach is a campaign×contact fact: it lives in the campaign's
# folder, campaigns/<camp>/<stem>.yaml, beside the campaign YAML it is
# keyed to. The folder is the campaign attribution.
proc spar::approach_dir_for_campaign {campaign_yaml} {
    return [file rootname [file normalize $campaign_yaml]]
}
proc spar::approach_path_for_stem {campaign_yaml stem} {
    return [spar::approach_path_in_dir [spar::approach_dir_for_campaign $campaign_yaml] $stem]
}
proc spar::approach_path_in_dir {approach_dir stem} {
    return [file join $approach_dir "${stem}.yaml"]
}

# ══ The sweep file: segments/<seg>.sweep.yaml ═════════════════════════
#
# The segment's discovery record (spar-S-search.md §7): the denominator,
# the source census, the rounds log. T0 is the first transition to write
# it — until now it was hand-written after a sweep, and four files were
# broken by the same defect class: a scalar carrying ": " mid-text, or an
# unquoted date, which tcllib yaml turns into epoch seconds.
#
# So the two writers here never hand a raw string to the file. Every
# scalar goes through spar::yaml_scalar (quotes what would otherwise
# re-parse as something else) and every multi-line value becomes a block
# scalar. And they are surgical: a writer rewrites the lines it owns and
# leaves the rest of the file byte-identical, so an author's comments and
# block scalars survive a round record.

# _sweep_read / _sweep_write — UTF-8 text IO for the sweep file, atomic on
# the write (tmp + rename), like every roster write here.
proc spar::_sweep_read {path} {
    set fd [open $path r]
    fconfigure $fd -encoding utf-8
    set raw [read $fd]
    close $fd
    return $raw
}

proc spar::_sweep_write {path text} {
    set tmp [exec mktemp "${path}.XXXXXX"]
    try {
        set fd [open $tmp w]
        fconfigure $fd -encoding utf-8 -translation lf
        puts -nonewline $fd $text
        close $fd
        file rename -force $tmp $path
        set tmp ""
    } finally {
        if {$tmp ne "" && [file exists $tmp]} { catch {file delete $tmp} }
    }
}

# read_sweep_yaml — parse a segment's sweep file. Parsing goes through
# spar::yaml_parse, never ::yaml::yaml2dict directly (the 0.4.2 hang).
proc spar::read_sweep_yaml {path} {
    if {![file exists $path]} {
        error "sweep file not found: $path"
    }
    set data [spar::yaml_parse [spar::_sweep_read $path]]
    if {[llength $data] % 2 != 0} {
        error "sweep file $path did not parse as a mapping"
    }
    return $data
}

# sweep_status_token — a source's status leads with a base token from the
# closed vocabulary and may carry a free-text reason after it ("partial —
# 40 of 120 resolved"). This is the single tokeniser: the sweep-file
# validator, the T0 task selector, and the return validator all split the
# same way, so a status that reads as exhausted to one reads that way to
# all three.
proc spar::sweep_status_token {status} {
    return [string tolower [lindex [split [string trim $status] " ;:(,.-"] 0]]
}

# sweep_status_vocab — the closed vocabulary of base tokens.
proc spar::sweep_status_vocab {} {
    return {unharvested partial exhausted unreachable stale}
}

# sweep_source_open — 1 when a source still holds work for T0. Exhausted
# and unreachable are the two closed states; everything else (including a
# status whose token is not in the vocabulary, which the seed validator
# flags separately) is work.
proc spar::sweep_source_open {status} {
    return [expr {[spar::sweep_status_token $status] ni {exhausted unreachable}}]
}

# sweep_task_stem — the pool key for one T0 task: one segment's one
# census source. The pool keys a job by its stem and both front ends
# filter selections by it, so a sweep task needs the same shape a contact
# has. The `sweep-` prefix keeps it out of any roster stem's space.
proc spar::sweep_task_stem {segment source_name} {
    return "sweep-[spar::slugify "${segment}-${source_name}"]"
}

# ── Quote-safe YAML emission ──────────────────────────────────────────

# yaml_scalar — render one single-line value as a YAML scalar, quoting
# whenever the bare form would re-parse as something other than the
# string handed in: a date (epoch seconds), a ": " (a nested mapping), a
# leading indicator character, a bool/null token, trailing space, an
# inline comment. Errors on a multi-line value — that is the block
# scalar's job, and silently flattening it would lose the text.
proc spar::yaml_scalar {value} {
    if {[string first "\n" $value] >= 0} {
        error "spar::yaml_scalar: value spans lines; emit it as a block scalar"
    }
    if {$value eq ""} { return {""} }
    # Bare numbers stay bare, except when a leading zero carries meaning
    # (a phone number, a postcode) that renumbering would eat.
    if {[string is integer -strict $value] && ![string match {0?*} $value]} {
        return $value
    }
    set quote 0
    if {[string trim $value] ne $value}                        { set quote 1 }
    if {[string first ": " $value] >= 0}                       { set quote 1 }
    if {[string index $value end] eq ":"}                      { set quote 1 }
    if {[string first " #" $value] >= 0}                       { set quote 1 }
    if {[string first "\t" $value] >= 0}                       { set quote 1 }
    if {[string index $value 0] in \
            {- ? : , \[ \] \{ \} # & * ! | > ' \" % @ `}}      { set quote 1 }
    if {[regexp {^\d{4}-\d{2}-\d{2}} $value]}                  { set quote 1 }
    if {[string tolower $value] in {true false yes no on off null ~}} { set quote 1 }
    if {!$quote} { return $value }
    return "\"[string map [list \\ \\\\ \" \\\"] $value]\""
}

# _yaml_block_lines — a multi-line value as a literal block scalar
# (`key: |-`), the one form that carries prose containing colons, dashes
# and quotes without any escaping. Leading whitespace on the first line
# is dropped: YAML would need an explicit indentation indicator to keep
# it, and no value here depends on it.
proc spar::_yaml_block_lines {key value indent} {
    set pad   [string repeat " " $indent]
    set inner [string repeat " " [expr {$indent + 2}]]
    set out [list "${pad}${key}: |-"]
    set body [split [string trimright $value "\n"] "\n"]
    set body [lreplace $body 0 0 [string trimleft [lindex $body 0]]]
    foreach line $body { lappend out "${inner}${line}" }
    return $out
}

# _yaml_emit_pairs — a dict as YAML mapping lines at $indent. Keys named
# in $list_keys are emitted as block sequences of scalars; every other
# value is a scalar, or a block scalar when it spans lines. Typing is by
# key name, not by guessing at Tcl's string/list ambiguity.
proc spar::_yaml_emit_pairs {d indent {list_keys {}}} {
    set pad [string repeat " " $indent]
    set out {}
    dict for {k v} $d {
        if {$k in $list_keys} {
            if {[llength $v] == 0} {
                lappend out "${pad}${k}: \[\]"
                continue
            }
            lappend out "${pad}${k}:"
            foreach item $v {
                lappend out "${pad}  - [spar::yaml_scalar $item]"
            }
            continue
        }
        if {[string first "\n" $v] >= 0} {
            lappend out {*}[spar::_yaml_block_lines $k $v $indent]
            continue
        }
        lappend out "${pad}${k}: [spar::yaml_scalar $v]"
    }
    return $out
}

# _yaml_unquote — strip one layer of surrounding quotes from a parsed-
# by-eye scalar (these readers work on lines, not on the parse tree).
proc spar::_yaml_unquote {s} {
    set s [string trim $s]
    if {[string length $s] >= 2} {
        set a [string index $s 0]
        set b [string index $s end]
        if {($a eq "\"" && $b eq "\"") || ($a eq "'" && $b eq "'")} {
            return [string range $s 1 end-1]
        }
    }
    return $s
}

# ── Surgical line edits on the sweep file ─────────────────────────────

# _yaml_block_entries — locate a top-level block sequence (`sources:`,
# `rounds:`) and the line range of each of its items. Returns a dict:
#   key_line   index of the `<key>:` line, -1 when absent
#   inline     what followed the key on that line ("" or "[]")
#   entries    list of {first_line last_line key_indent}
#   block_end  index of the first line after the block
# Nested sequences inside an item are not items: only dashes at the
# first item's indentation start a new one.
proc spar::_yaml_block_entries {lines key} {
    set n [llength $lines]
    set key_line -1
    set inline ""
    for {set i 0} {$i < $n} {incr i} {
        if {[regexp "^${key}:(.*)\$" [lindex $lines $i] -> rest]} {
            set key_line $i
            set inline [string trim $rest]
            break
        }
    }
    if {$key_line < 0} {
        return [dict create key_line -1 inline "" entries {} block_end $n]
    }
    set entries {}
    set cur_start -1
    set cur_indent 0
    set item_indent -1
    set block_end $n
    for {set i [expr {$key_line + 1}]} {$i < $n} {incr i} {
        set line [lindex $lines $i]
        if {[string trim $line] eq ""} continue
        if {[string index $line 0] ni {" " "\t"}} { set block_end $i; break }
        if {[regexp {^(\s*)-(\s+)} $line -> ind dash]} {
            set this_indent [string length $ind]
            if {$item_indent < 0} { set item_indent $this_indent }
            if {$this_indent != $item_indent} continue
            if {$cur_start >= 0} {
                lappend entries [list $cur_start [expr {$i - 1}] $cur_indent]
            }
            set cur_start $i
            set cur_indent [expr {$this_indent + 1 + [string length $dash]}]
        }
    }
    if {$cur_start >= 0} {
        lappend entries [list $cur_start [expr {$block_end - 1}] $cur_indent]
    }
    return [dict create key_line $key_line inline $inline \
        entries $entries block_end $block_end]
}

# _entry_scalar — read one key's raw value from an entry's line range.
proc spar::_entry_scalar {lines first last key} {
    for {set i $first} {$i <= $last} {incr i} {
        if {[regexp "^\\s*(?:-\\s+)?${key}:\\s*(.*)\$" [lindex $lines $i] -> v]} {
            return [list $i [spar::_yaml_unquote $v]]
        }
    }
    return {}
}

# update_source_status — set one census source's status line. The rest of
# the file is untouched, so the author's derivation block scalars and
# comments survive. Errors when the source is not in the census (a worker
# renaming its own source would otherwise write a second entry) or when
# the existing status is a block scalar (nothing here should produce one,
# so a hand edit that did is left for a human).
proc spar::update_source_status {sweep_path source_name status} {
    set lines [split [string trimright [spar::_sweep_read $sweep_path] "\n"] "\n"]
    set blk [spar::_yaml_block_entries $lines sources]
    foreach entry [dict get $blk entries] {
        lassign $entry first last indent
        set nm [spar::_entry_scalar $lines $first $last name]
        if {[llength $nm] == 0 || [lindex $nm 1] ne $source_name} continue
        set st [spar::_entry_scalar $lines $first $last status]
        if {[llength $st] > 0} {
            set idx [lindex $st 0]
            if {[string index [lindex $st 1] 0] in {| >}} {
                error "update_source_status: '$source_name' status is a block scalar in $sweep_path; rewrite it by hand"
            }
            set lead [string repeat " " $indent]
            regexp {^(\s*-\s+)status:} [lindex $lines $idx] -> lead
            set lines [lreplace $lines $idx $idx \
                "${lead}status: [spar::yaml_scalar $status]"]
        } else {
            set lines [linsert $lines [expr {[lindex $nm 0] + 1}] \
                "[string repeat { } $indent]status: [spar::yaml_scalar $status]"]
        }
        spar::_sweep_write $sweep_path "[join $lines \n]\n"
        return 1
    }
    error "update_source_status: no source named '$source_name' in $sweep_path"
}

# append_sweep_round — write a round record into the rounds log.
#
# One T0 dispatch is one round worked source by source, and each source's
# worker lands independently: there is no batch-end hook in either front
# end, and inventing one would change the dispatch contract both consume.
# So the round is written incrementally and keyed by its number — the
# first source to finish creates round n, the rest merge into it. A batch
# that dies half way leaves a truthful partial round rather than nothing.
#
# Merge rule per key: `inputs` and `surprises` union, `reconciliation`
# gains a line, `yield` sums when both sides are integers, everything else
# is last-writer (the later worker's `coverage_after` is the fresher count).
proc spar::append_sweep_round {sweep_path round} {
    if {![dict exists $round n]} {
        error "append_sweep_round: round record has no 'n'"
    }
    set data [spar::read_sweep_yaml $sweep_path]
    set existing [dict getdef $data rounds {}]
    set merged $round
    set match -1
    set idx 0
    foreach r $existing {
        if {[dict exists $r n] && [dict get $r n] eq [dict get $round n]} {
            set match $idx
            set merged [spar::_merge_round $r $round]
        }
        incr idx
    }

    set lines [split [string trimright [spar::_sweep_read $sweep_path] "\n"] "\n"]
    set blk [spar::_yaml_block_entries $lines rounds]
    set block [spar::_emit_round_block $merged 2]
    set key_line [dict get $blk key_line]
    set entries  [dict get $blk entries]

    if {$key_line < 0} {
        lappend lines "rounds:"
        set lines [concat $lines $block]
    } elseif {$match >= 0 && $match < [llength $entries]} {
        lassign [lindex $entries $match] first last _
        set lines [lreplace $lines $first $last {*}$block]
    } elseif {[llength $entries] == 0} {
        # `rounds: []` or a bare `rounds:` — the key line carries the
        # empty flow sequence, so it is replaced, not appended to.
        set lines [lreplace $lines $key_line $key_line "rounds:" {*}$block]
    } else {
        lassign [lindex $entries end] first last _
        set lines [linsert $lines [expr {$last + 1}] {*}$block]
    }
    spar::_sweep_write $sweep_path "[join $lines \n]\n"
    return [dict get $merged n]
}

proc spar::_merge_round {old new} {
    set out $old
    dict for {k v} $new {
        switch -- $k {
            inputs - surprises {
                set acc [dict getdef $old $k {}]
                foreach item $v {
                    if {$item ni $acc} { lappend acc $item }
                }
                dict set out $k $acc
            }
            reconciliation {
                set prev [string trim [dict getdef $old $k ""]]
                if {$prev eq ""} {
                    dict set out $k $v
                } elseif {[string first $v $prev] < 0} {
                    dict set out $k "$prev\n$v"
                }
            }
            yield {
                set prev [dict getdef $old $k ""]
                if {[string is integer -strict $prev] \
                        && [string is integer -strict $v]} {
                    dict set out $k [expr {$prev + $v}]
                } else {
                    dict set out $k $v
                }
            }
            default { dict set out $k $v }
        }
    }
    return $out
}

# _emit_round_block — one round as a block-sequence item at $indent.
# Keys come out in the order spar-S-search.md §7 lists them, so a rounds
# log reads the same whoever wrote the entry; unknown keys follow.
proc spar::_emit_round_block {round indent} {
    set order {n date method inputs reconciliation surprises \
               coverage_after merge lesson yield}
    set ordered [dict create]
    foreach k $order {
        if {[dict exists $round $k]} { dict set ordered $k [dict get $round $k] }
    }
    dict for {k v} $round {
        if {![dict exists $ordered $k]} { dict set ordered $k $v }
    }
    set lines [spar::_yaml_emit_pairs $ordered [expr {$indent + 2}] \
        {inputs surprises}]
    set pad [string repeat " " $indent]
    return [lreplace $lines 0 0 "${pad}- [string trimleft [lindex $lines 0]]"]
}

# ── Per-worker cost metering (#114) ───────────────────────────────────
#
# ─── Coroutine-aware I/O helpers ─────────────────────────────────────────
#
# A pool worker (a jobloop coroutine) waits the loop's way: it never blocks
# on a synchronous read or a bare vwait, which would stall every other job
# in the process. These helpers arm a timer, a subprocess pipe, or an http
# callback that resumes the coroutine, then yield. Called outside a
# coroutine (a test, a standalone harness run) each falls back to the
# blocking form, so the same body works either way. They live here, the
# shared base, because both the pool's worker bodies and the harness path
# (spar-courier, the SMTP credential lookup) reach them. deadman and http
# are required lazily, in the branch that needs them, so a lightweight
# consumer of this library does not pull them in.

# spar::pool_sleep - wait `ms` milliseconds. In a coroutine: arm a timer
# that resumes it, then yield, so the loop runs every other job meanwhile.
# The timer's resume is guarded, so a coroutine torn down (pool destroyed)
# before the timer fires leaves nothing to fire into.
proc spar::pool_sleep {ms} {
    set co [info coroutine]
    if {$co eq ""} {
        set var ::spar::__pool_sleep([incr ::spar::__pool_sleep_seq])
        after $ms [list set $var 1]
        vwait $var
        unset -nocomplain $var
        return
    }
    after $ms [list apply {co {
        if {[llength [info commands $co]]} { $co }
    }} $co]
    yield
}

# spar::pool_exec - run a child and return its merged stdout+stderr, the
# shape of `exec ... 2>@1`: the output on success, and on a non-zero exit
# or a signal an error whose message is that same output. In a coroutine
# the child is driven through deadman (pipe + fileevent) and awaited with a
# yield, so it never blocks the loop; outside one it is a plain exec.
# deadman arrives with the dispatcher's or the harness's vendor path, both
# loaded wherever a coroutine can run, so the lazy require resolves.
proc spar::pool_exec {args} {
    if {[info coroutine] eq ""} {
        return [exec {*}$args 2>@1]
    }
    package require deadman
    deadman::run $args -err stdout -done [info coroutine]
    set r [yield]
    set out [string trimright [dict get $r stdout] \n]
    if {[dict get $r exit] != 0 || [dict get $r signal] ne ""} {
        # Mirror exec's CHILDSTATUS errorCode so a caller reads the
        # child's exit code the same way on both branches.
        set code [dict get $r exit]
        if {[string is integer -strict $code] && $code != 0} {
            return -code error -errorcode [list CHILDSTATUS 0 $code] $out
        }
        return -code error $out
    }
    return $out
}

# spar::pool_http - http::geturl that does not block the loop. In a
# coroutine the request is issued with -command resuming the coroutine, so
# the socket exchange runs on the event loop; the caller gets the token
# back and owns http::cleanup as with a synchronous geturl.
proc spar::pool_http {args} {
    package require http
    if {[info coroutine] eq ""} {
        return [http::geturl {*}$args]
    }
    set tok [http::geturl {*}$args -command [info coroutine]]
    yield
    return $tok
}

package provide spar-lib 1.0
