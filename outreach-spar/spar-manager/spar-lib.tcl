#!/usr/bin/env tclsh9.0
# spar-lib.tcl — Shared library for SPAR batch scripts (Tcl port)
# Source this file or package require spar-lib.
# Works under both tclsh (CLI) and wish (GUI).

package require yaml
package require json
package require json::write

namespace eval spar {
    namespace export slugify load_campaign load_roster find_profile \
        profile_exists get_max_passes lang_instruction channel_desc \
        campaign_primary_channel campaign_secondary_channel \
        campaign_tertiary_channel campaign_in_scope_channels \
        roster_row_has_in_scope_channel
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
                set v [string trim [spar::dict_get_default $row email ""]]
                if {[string match *@* $v]} { return 1 }
            }
            linkedin {
                set v [string trim [spar::dict_get_default $row linkedin_url ""]]
                if {$v ne ""} { return 1 }
            }
            facebook {
                set v [string trim [spar::dict_get_default $row facebook_url ""]]
                if {$v ne ""} { return 1 }
            }
            phone {
                set v [string trim [spar::dict_get_default $row phone ""]]
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
    set data [::yaml::yaml2dict $raw]

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

    # Validate p_strict (opt-in transcript-based audit that the P-stage
    # invoked the linkedin and facebook skills per SPAR-P §4.3 / §4.4).
    # Default off for back-compat; enforcement lives in the harness.
    if {[dict exists $data p_strict]} {
        set v [dict get $data p_strict]
        if {![string is boolean -strict $v]} {
            error "Campaign $yaml_path: p_strict must be a boolean (got '$v')"
        }
    }

    # Validate venue (optional). When present, the dispatcher exposes the
    # address and coordinate to the P prompt so AI-side OSRM can compute
    # target-to-venue driving distance for proximity-relevant angles
    # without guessing. SmartLayer/aesop#93 tracks moving the OSRM call
    # itself into the harness.
    if {[dict exists $data venue]} {
        set venue [dict get $data venue]
        set vaddr [string trim [spar::dict_get_default $venue address ""]]
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
            lappend fields [spar::dict_get_default $row $h ""]
        }
        puts $fd [join $fields \t]
    }
    close $fd
}

# update_roster_field — set one field on the row matching key_col=key_val.
# Atomic for the target file (write to sibling tmp + rename), but assumes
# the caller has serialised concurrent writers. The dispatcher's single-
# threaded event loop is the sole serialiser today: harness children emit
# msg_roster_update via thread::send (defined in spar-dispatcher-initcmd.tcl)
# and the dispatcher invokes this function from on_roster_update. If a
# future caller writes the TSV from multiple processes, reintroduce flock
# here. Returns the count of rows updated. Errors if no row matches.
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
    # source only spar-lib.tcl.
    if {[info procs spar::read_profile_front_matter] eq ""} {
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

# is_null — check for YAML null representations
proc spar::is_null {val} {
    set v [string trim $val]
    return [expr {$v eq "" || $v eq "~" || $v eq "None" || $v eq "null"}]
}

# dict_get_default — get a dict value with a default if missing
proc spar::dict_get_default {d key {default ""}} {
    if {[dict exists $d $key]} {
        return [dict get $d $key]
    }
    return $default
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
    if {[file isdirectory /var/local/logs/spar]} {
        set logs_dir "/var/local/logs/spar/$folder"
    } else {
        set logs_dir "$::env(HOME)/logs/spar/$folder"
    }
    file mkdir $logs_dir
    return $logs_dir
}

# Path conventions for stem-keyed artefacts. SSOT: every consumer that
# resolves a profile or approach by stem uses these. Layout per
# spar-roster-format.md / SmartLayer/aesop#45.
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

package provide spar-lib 1.0
