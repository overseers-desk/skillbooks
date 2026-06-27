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
    set campaign_name [spar::dict_get_default $cdata campaign [file tail $yaml_path]]
    set primary_channel [spar::campaign_primary_channel $cdata]
    set min_star 0
    if {[dict exists $cdata filter]} {
        set min_star [spar::dict_get_default [dict get $cdata filter] min_star 0]
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

# dict_get_default — get a dict value with a default if missing
proc spar::dict_get_default {d key {default ""}} {
    if {[dict exists $d $key]} {
        return [dict get $d $key]
    }
    return $default
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

proc spar::_orch_emit {service level txt} {
    if {$::spar::_orch_logfile eq ""} return
    set line "\[[clock format [clock seconds]]\] \[$service\] \[$level\] '$txt'"
    catch {puts stderr $line}
    catch {
        set fd [open $::spar::_orch_logfile a]
        puts $fd $line
        close $fd
    }
}

proc spar::install_orchestration_log {logfile services} {
    set ::spar::_orch_logfile $logfile
    file mkdir [file dirname $logfile]
    foreach svc $services {
        set log [logger::init $svc]
        foreach lvl {debug info notice warn error critical alert emergency} {
            ${log}::logproc $lvl txt [format {::spar::_orch_emit %s %s $txt} $svc $lvl]
        }
    }
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
# Workers run on sonnet (the dispatcher launches `--model sonnet`; the
# fix-loop opus escalation and the challenger are resume/side calls on a
# different harness), so the meter prices at sonnet published rates,
# matching the accounting in #114. Per-million-token rates:
namespace eval ::spar {
    variable sonnet_rate_input      3.00
    variable sonnet_rate_output    15.00
    variable sonnet_rate_cache_write 3.75
    variable sonnet_rate_cache_read  0.30
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

# _accumulate_usage — fold one transcript file's assistant usage into the
# running token totals dict (keys: input output cache_write cache_read).
# A single request can surface across several stream records (the same
# requestId reported as tokens accrue); take the max per requestId so the
# figure is not double-counted, then add the per-request maxima. Mirrors
# the dedup in questlog's cost::parse_file. Unreadable or half-written
# files are skipped — the watchdog reads a live, growing transcript.
proc spar::_accumulate_usage {path totalsVar} {
    upvar 1 $totalsVar totals
    if {[catch {open $path r} fd]} { return }
    fconfigure $fd -encoding utf-8 -profile replace
    set req_usage [dict create]
    set dummy 0
    while {[gets $fd line] >= 0} {
        if {![string match {*"type":"assistant"*} $line]} continue
        if {[catch {::json::json2dict $line} rec]} continue
        if {![dict exists $rec message]} continue
        set msg [dict get $rec message]
        if {![dict exists $msg usage]} continue
        set u [dict get $msg usage]
        set req_id [spar::dict_get_default $rec requestId \
            [spar::dict_get_default $msg requestId ""]]
        if {$req_id eq ""} { set req_id "dummy-[incr dummy]" }
        set in [spar::dict_get_default $u input_tokens 0]
        set out [spar::dict_get_default $u output_tokens 0]
        set cw [spar::dict_get_default $u cache_creation_input_tokens 0]
        set cr [spar::dict_get_default $u cache_read_input_tokens 0]
        if {[dict exists $req_usage $req_id]} {
            lassign [dict get $req_usage $req_id] oi oo ow or
            dict set req_usage $req_id [list \
                [expr {max($in,$oi)}] [expr {max($out,$oo)}] \
                [expr {max($cw,$ow)}] [expr {max($cr,$or)}]]
        } else {
            dict set req_usage $req_id [list $in $out $cw $cr]
        }
    }
    close $fd
    dict for {_ c} $req_usage {
        lassign $c i o w r
        dict set totals input       [expr {[dict get $totals input] + $i}]
        dict set totals output      [expr {[dict get $totals output] + $o}]
        dict set totals cache_write [expr {[dict get $totals cache_write] + $w}]
        dict set totals cache_read  [expr {[dict get $totals cache_read] + $r}]
    }
}

# worker_cost_usd — accumulated dollar spend of a worker (parent session
# plus its research subagents) at sonnet published rates. Returns 0.0
# before the worker's transcript appears, so a watchdog can call it from
# the first poll without a special case. transcripts_root is injectable
# for tests.
proc spar::worker_cost_usd {session_id {transcripts_root ""}} {
    set files [spar::worker_session_files $session_id $transcripts_root]
    if {[llength $files] == 0} { return 0.0 }
    set totals [dict create input 0 output 0 cache_write 0 cache_read 0]
    foreach f $files {
        spar::_accumulate_usage $f totals
    }
    variable sonnet_rate_input
    variable sonnet_rate_output
    variable sonnet_rate_cache_write
    variable sonnet_rate_cache_read
    return [expr {(
        [dict get $totals input]       * $sonnet_rate_input +
        [dict get $totals output]      * $sonnet_rate_output +
        [dict get $totals cache_write] * $sonnet_rate_cache_write +
        [dict get $totals cache_read]  * $sonnet_rate_cache_read
    ) / 1000000.0}]
}

package provide spar-lib 1.0
