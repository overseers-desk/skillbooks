#!/usr/bin/env tclsh
# spar-lib.tcl — Shared library for SPAR batch scripts (Tcl port)
# Source this file or package require spar-lib.
# Works under both tclsh (CLI) and wish (GUI).

package require yaml
package require json
package require json::write

namespace eval spar {
    namespace export slugify load_campaign load_roster find_profile \
        profile_exists get_max_rounds lang_instruction channel_desc
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
    foreach key {method usp_document antifacts campaign_principles} {
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

# write_roster — write rows back to a roster TSV, preserving column order.
# Reads the existing header line to determine column order, then overwrites.
proc spar::write_roster {tsv_path rows} {
    if {[llength $rows] == 0} return

    set fd [open $tsv_path r]
    fconfigure $fd -translation binary
    gets $fd header_line
    close $fd
    set header_line [string map {\r\n "" \r ""} $header_line]
    set headers [split $header_line \t]

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

# get_max_rounds — determine max A2 spar rounds from profile richness.
# Reads the profile's YAML front matter (see spar-P-profile.md §5.1 and
# SmartLayer/aesop#45) for the canonical `richness` value. Returns 3 for rich,
# 1 for medium/thin, 1 for anything unparseable.
proc spar::get_max_rounds {profile_path} {
    if {$profile_path eq "" || ![file exists $profile_path]} {
        return 1
    }
    # read_profile_front_matter lives in spar-state.tcl; guard for callers that
    # source only spar-lib.tcl.
    if {[info procs spar::read_profile_front_matter] eq ""} {
        return 1
    }
    set fm [spar::read_profile_front_matter $profile_path]
    if {$fm eq "" || ![dict exists $fm richness]} {
        return 1
    }
    set r [string tolower [dict get $fm richness]]
    if {$r eq "rich"} {
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
            return "Per SPAR-A §4.2: LinkedIn + verified email + phone = prepare (1) LinkedIn connection note, (2) email after acceptance or 5 days, (3) phone follow-up if no email reply after 3 days."
        } else {
            return "Per SPAR-A §4.2: LinkedIn + verified email = prepare (1) LinkedIn connection note, (2) email after acceptance or 5 days."
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

package provide spar-lib 1.0
