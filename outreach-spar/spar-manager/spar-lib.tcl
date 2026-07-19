#!/usr/bin/env tclsh9.0
# spar-lib.tcl — Shared library for SPAR batch scripts (Tcl port)
# Source this file or package require spar-lib.
# Works under both tclsh (CLI) and wish (GUI).

package require yaml
package require json
package require json::write
package require logger

namespace eval spar {
    namespace export slugify load_campaign load_roster find_profile \
        profile_exists get_max_passes lang_instruction channel_desc \
        campaign_primary_channel campaign_secondary_channel \
        campaign_tertiary_channel campaign_in_scope_channels \
        roster_row_has_in_scope_channel render_rollcall
}

# Directory this library lives in, used to locate vendored files under vendor/.
set ::spar::lib_dir [file dirname [file normalize [info script]]]

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
# build the list of {label seg_dir} segment paths that carry a roster.tsv.
#
# Returns a dict with keys: yaml_path campaign_dir cdata segment_paths
#                           campaign_name min_star primary_channel
# Throws on: campaign YAML not found, or no segments with a roster.
proc spar::resolve_campaign {campaign_file campaign_dir} {
    if {$campaign_file ne "" && $campaign_dir eq ""} {
        set campaign_dir [file dirname [file normalize $campaign_file]]
    }
    if {$campaign_dir eq ""} { set campaign_dir "." }
    set campaign_dir [file normalize $campaign_dir]

    if {$campaign_file ne ""} {
        set yaml_path [file normalize $campaign_file]
    } else {
        set yaml_path [file join $campaign_dir campaign.yaml]
        if {![file exists $yaml_path]} {
            set candidates [lsort [glob -nocomplain [file join $campaign_dir campaign*.yaml]]]
            set yaml_path [expr {[llength $candidates] > 0 ? [lindex $candidates end] : ""}]
        }
    }
    if {$yaml_path eq "" || ![file exists $yaml_path]} {
        if {$campaign_file ne ""} {
            error "Campaign YAML not found: $campaign_file"
        } else {
            error "No campaign YAML found in $campaign_dir"
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
    set skip_set {}
    if {[dict exists $cdata skip_segments]} { set skip_set [dict get $cdata skip_segments] }

    set segment_paths {}
    foreach seg $segments_list {
        if {$seg in $skip_set} continue
        set seg_dir [file join $campaign_dir $seg]
        if {[file isdirectory $seg_dir] && [file exists [file join $seg_dir roster.tsv]]} {
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

# extract_required_skills — convert a segment's profile_reject_if list into
# the skill list audit_skills_in_transcript expects. Validates the closed
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
            set fb_path [file join [file dirname $roster_path] sweep-feedback.tsv]
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

# find_profile — find a profile file matching name/org slugs
# Port of spar-a-batch.sh lines 108-117
# Returns the path if found, empty string otherwise
proc spar::find_profile {profile_dir slug_name slug_org} {
    if {![file isdirectory $profile_dir]} {
        return ""
    }
    # Try name+org match first
    set matches [glob -nocomplain -directory $profile_dir \
        "*${slug_name}*${slug_org}*"]
    if {[llength $matches] > 0} {
        return [lindex [lsort $matches] 0]
    }
    # Fall back to name-only match
    set matches [glob -nocomplain -directory $profile_dir \
        "*${slug_name}*"]
    if {[llength $matches] > 0} {
        return [lindex [lsort $matches] 0]
    }
    return ""
}

# profile_exists — check if a profile exists for this contact
# Port of spar-p-batch.sh lines 88-123 (name match + org+initial match)
# Returns 1 if found, 0 otherwise
proc spar::profile_exists {profile_dir slug_name slug_org} {
    if {![file isdirectory $profile_dir]} {
        return 0
    }

    # Check 1: exact slug output path
    set exact [file join $profile_dir "profile-${slug_name}-${slug_org}.md"]
    if {[file exists $exact]} {
        return 1
    }

    # Check 2: name-prefix match on profile filename
    set name_matches [glob -nocomplain \
        [file join $profile_dir "profile-${slug_name}-*.md"]]
    if {[llength $name_matches] > 0} {
        # Multi-word name: prefix match alone is reliable
        if {[string first - $slug_name] >= 0} {
            return 1
        }
        # Single-word name: verify first word of org appears in profile's org section
        set first_org_word [lindex [split $slug_org -] 0]
        foreach match $name_matches {
            set base [file rootname [file tail $match]]
            # Strip "profile-{slug_name}-" prefix to get the org part
            set profile_org [string range $base \
                [expr {[string length "profile-${slug_name}-"]}] end]
            if {[string first $first_org_word $profile_org] >= 0} {
                return 1
            }
        }
    }

    # Check 3: org-slug match with same initial letter
    set initial [string index $slug_name 0]
    set org_matches [glob -nocomplain \
        [file join $profile_dir "profile-*${slug_org}*.md"]]
    foreach match $org_matches {
        set base [file rootname [file tail $match]]
        set profile_name [string range $base [string length "profile-"] end]
        if {[string index $profile_name 0] eq $initial} {
            return 1
        }
    }

    return 0
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

# extract_between — extract text between marker lines (exclusive)
# Port of the earlier shell-based extract_between() used by the A harness.
proc spar::extract_between {text start_marker end_marker} {
    set lines [split $text \n]
    set collecting 0
    set result {}
    foreach line $lines {
        if {$line eq $end_marker && $collecting} {
            break
        }
        if {$collecting} {
            lappend result $line
        }
        if {$line eq $start_marker} {
            set collecting 1
        }
    }
    return [join $result \n]
}

# transcript_assistant_text — concatenate every assistant text block from a
# stream-json transcript (.json), in order, newline-separated. The marker
# blocks the A harness greps for (DRAFT_START/DRAFT_END, RATIONALE_*) live in
# the author's own turns; the envelope's `result` is only the final turn's
# text, which a post-draft turn (e.g. a Stop hook reacting to a `#N` token the
# draft quoted) displaces. Reading the whole transcript recovers the draft
# regardless of what was said after it. Returns "" when the file is absent or
# holds no assistant text.
proc spar::transcript_assistant_text {json_file} {
    if {![file exists $json_file]} { return "" }
    set chunks {}
    set fd [open $json_file r]
    try {
        while {[gets $fd line] >= 0} {
            set line [string trim $line]
            if {$line eq ""} continue
            if {[catch {set obj [::json::json2dict $line]}]} continue
            if {![dict exists $obj type] || [dict get $obj type] ne "assistant"} continue
            if {![dict exists $obj message]} continue
            set msg [dict get $obj message]
            if {![dict exists $msg content]} continue
            set content [dict get $msg content]
            foreach block $content {
                if {[dict exists $block type] && [dict get $block type] eq "text" \
                        && [dict exists $block text]} {
                    lappend chunks [dict get $block text]
                }
            }
        }
    } finally {
        close $fd
    }
    return [join $chunks \n]
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
        skipped { ${::spar::transitions_log}::info "  \[SKIP \] $slug ($message)" }
        warning { ${::spar::transitions_log}::warn "  \[WARN \] $slug: $message" }
    }
}

# Path conventions for stem-keyed artefacts. SSOT: every consumer that
# resolves a profile or approach by stem uses these. Layout per
# spar-roster-format.md / #45.
proc spar::profile_dir_for_segment {segment_dir} {
    return [file join $segment_dir profiles]
}
proc spar::approach_dir_for_segment {segment_dir} {
    return [file join $segment_dir approach]
}
proc spar::profile_path_for_stem {segment_dir stem} {
    return [file join [spar::profile_dir_for_segment $segment_dir] "${stem}.md"]
}
proc spar::legacy_profile_path_for_stem {segment_dir stem} {
    return [file join [spar::profile_dir_for_segment $segment_dir] "profile-${stem}.md"]
}
proc spar::approach_path_for_stem {segment_dir stem} {
    return [file join [spar::approach_dir_for_segment $segment_dir] "${stem}.yaml"]
}

# ── Per-worker cost metering (#114) ───────────────────────────────────
#
# A worker's true spend is its own `claude -p` session plus the research
# subagents it fans out (each its own session file); on the recorded
# $7.83 worker the subagents were ~75% of the bill, so a parent-only
# meter undercounts the governing concern. These procs price one worker
# by its session_id, summing the canonical transcripts claude writes
# under ~/.claude/projects/<campaign>/, so the figure is the same one
# questlog reports — read here directly off the few files that belong to
# this worker, which keeps a watchdog poll sub-second and scoped to the
# one session rather than the whole corpus.
#
# The dispatcher launches workers on a mix of models - a batch's default, the
# fix-loop's opus escalation, the challenger - so the meter prices per model
# rather than at one flat rate: a worker on a costlier model bills the higher
# figure, and the cost cap governs the true spend. Pricing is the vendored
# tallyman module's job; spar reads the token counts off the files and hands
# tallyman the totals and the rate table.
#
# The rate table is a data structure, not a file tallyman reads:
# vendor/anthropic-rates.tcl carries the per-model, time-versioned figures
# (sourced from questlog's upstream table so the two agree), read once and
# cached here.
proc spar::_worker_rates {} {
    variable _worker_rates
    if {![info exists _worker_rates]} {
        set _worker_rates [source \
            [file join $::spar::lib_dir vendor anthropic-rates.tcl]]
    }
    return $_worker_rates
}

# worker_session_files — the canonical transcript files for a worker:
# the parent session plus every research-subagent session it spawned.
# Globs by session_id rather than reconstructing the project dir from
# pwd, mirroring spar::audit_skills_in_transcript: the dispatcher does
# not chdir per-job, so claude inherits a launch cwd that is not
# deterministic from here. Returns {} when the parent transcript has not
# appeared yet (the init event lands within the first second, so an
# empty list early in a run is normal). transcripts_root is injectable
# for tests.
proc spar::worker_session_files {session_id {transcripts_root ""}} {
    if {$session_id eq ""} { return {} }
    if {$transcripts_root eq ""} {
        set transcripts_root [file join $::env(HOME) .claude projects]
    }
    set parents [glob -nocomplain -directory $transcripts_root \
        -types f -- */${session_id}.jsonl]
    if {[llength $parents] == 0} { return {} }
    set parent [lindex $parents 0]
    set files [list $parent]
    set subdir [file join [file dirname $parent] $session_id subagents]
    foreach sub [glob -nocomplain -directory $subdir -types f -- *.jsonl] {
        lappend files $sub
    }
    return $files
}

# worker_cost_usd — accumulated dollar spend of a worker (parent session plus
# its research subagents), priced per model against the vendored rate table.
# Returns 0.0 before the worker's transcript appears, so a watchdog can call it
# from the first poll without a special case. transcripts_root is injectable
# for tests.
proc spar::worker_cost_usd {session_id {transcripts_root ""}} {
    package require tallyman
    set files [spar::worker_session_files $session_id $transcripts_root]
    if {[llength $files] == 0} { return 0.0 }
    # Sum token usage per model across the parent and every subagent file, then
    # price once. Reading each file's lines is ours (tallyman does no I/O); the
    # dedup of a request split across stream records is tallyman's.
    set per_model [dict create]
    foreach f $files {
        if {[catch {open $f r} fd]} continue
        fconfigure $fd -encoding utf-8 -profile replace
        set lines [split [read $fd] "\n"]
        close $fd
        set res [tallyman::parse_lines $lines]
        dict for {m c} [dict get $res per_model] {
            lassign $c i o w r
            lassign [dict getdef $per_model $m {0 0 0 0}] pi po pw pr
            dict set per_model $m [list [expr {$pi+$i}] [expr {$po+$o}] \
                [expr {$pw+$w}] [expr {$pr+$r}]]
        }
    }
    # The worker is spending now, so today's date selects the current rate era.
    # compute_usd returns -1.0 when no model matched any rate (an unpriced local
    # model, or usage not yet landed); the meter reads that as 0.
    set today [clock format [clock seconds] -format %Y-%m-%d]
    set usd [tallyman::compute_usd $per_model [spar::_worker_rates] $today]
    return [expr {$usd < 0 ? 0.0 : $usd}]
}

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
