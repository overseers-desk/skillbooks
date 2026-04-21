#!/usr/bin/env tclsh9.0
# migrate-profile-naming.tcl — one-shot migration for SmartLayer/aesop#45.
#
# Converts legacy profiles/profile-{stem}.md files to profiles/{stem}.md with
# a YAML front-matter block (see spar-P-profile.md §5.1). The legacy file is
# left untouched so humans can diff old vs new during review. Delete the old
# profile-*.md files once satisfied.
#
# Usage:
#   tclsh9.0 migrate-profile-naming.tcl <segment-dir> [--dry-run] [--force]
#
# --dry-run  write nothing; print a per-file summary of what would be written
# --force    overwrite existing {stem}.md files (default: skip if new file exists)
#
# Behaviour per legacy profile:
#   • Extract stem from filename (strip "profile-" prefix).
#   • Parse Profile date / data-point count / Warmth level from the
#     markdown body (best-effort regex; missing fields seed defaults).
#   • Read roster row for contact_name / organisation / role / date_excluded /
#     star_rating.
#   • Write front matter at the top of the new file; preserve original body
#     with the three redundant header lines stripped.
#   • applicable_angles is seeded with the single placeholder slug
#     "to-be-reviewed" — the old prose "Angles (ordered by fit)" section is
#     not reliably parseable. Humans must edit post-migration.
#   • warmth_finding is normalised to the enum {existing, prior, known-of,
#     cold}. If the body does not mention it, "cold" is assumed.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-lib.tcl]

set dry_run 0
set force 0
set segment_dir ""
foreach arg $argv {
    switch -- $arg {
        --dry-run { set dry_run 1 }
        --force   { set force 1 }
        default   { set segment_dir $arg }
    }
}

if {$segment_dir eq ""} {
    puts stderr "usage: tclsh9.0 migrate-profile-naming.tcl <segment-dir> \[--dry-run\] \[--force\]"
    exit 2
}

set segment_dir [file normalize $segment_dir]
if {![file isdirectory $segment_dir]} {
    puts stderr "error: not a directory: $segment_dir"
    exit 2
}

set profile_dir [file join $segment_dir profiles]
set roster_path [file join $segment_dir roster.tsv]
if {![file isdirectory $profile_dir]} {
    puts stderr "error: no profiles/ directory at $segment_dir"
    exit 2
}

# Load roster; build stem → row dict.
array set roster_by_stem {}
if {[file exists $roster_path]} {
    foreach row [spar::load_roster $roster_path] {
        set s [string trim [spar::dict_get_default $row stem ""]]
        if {$s ne ""} { set roster_by_stem($s) $row }
    }
} else {
    puts stderr "warning: no roster.tsv at $segment_dir — snapshot fields will be blank"
}

proc extract_field {text pattern} {
    if {[regexp -line -nocase $pattern $text -> val]} {
        return [string trim $val " *"]
    }
    return ""
}

proc normalise_warmth {raw} {
    set r [string tolower [string trim $raw]]
    if {[string match "existing*" $r]} { return "existing" }
    if {[string match "prior*"    $r]} { return "prior" }
    if {[string match "known*"    $r]} { return "known-of" }
    if {[string match "cold*"     $r]} { return "cold" }
    return "cold"
}

proc extract_yield {raw} {
    # "Rich (8+ data points)" → 8; "Medium (5 data points)" → 5.
    # Prefer the count inside "(N data points)" if present, otherwise first
    # digit sequence, otherwise 0.
    if {[regexp {\((\d+)[^)]*data\s*points?\)} $raw -> n]} { return $n }
    if {[regexp {(\d+)} $raw -> n]} { return $n }
    return 0
}

# yaml_scalar -- quote a string so the YAML parser reads it as a single scalar.
# Required when the value contains ':', '#', leading/trailing space, or other
# indicator characters. Uses double-quoted style with \ escapes.
proc yaml_scalar {s} {
    if {$s eq "null" || $s eq ""} { return $s }
    # If the value has no YAML-meaningful chars, emit bare.
    if {[regexp {^[A-Za-z0-9_][A-Za-z0-9 _/.,@&+-]*$} $s]} { return $s }
    set esc [string map {\\ \\\\ \" \\\"} $s]
    return "\"$esc\""
}

proc strip_legacy_headers {text} {
    # Remove the three bold-label lines and the Warmth level bold line inside
    # the Prior correspondence section. Leave everything else verbatim.
    set lines [split $text \n]
    set out {}
    foreach line $lines {
        if {[regexp -nocase {^\s*\*\*Profile date:\*\*} $line]} continue
        if {[regexp -nocase {^\s*\*\*(Richness classification|Profile yield):\*\*} $line]} continue
        if {[regexp -nocase {^\s*\*\*Warmth level:\*\*} $line]} continue
        lappend out $line
    }
    return [join $out \n]
}

set migrated 0
set skipped 0
set warnings 0

foreach old_path [lsort [glob -nocomplain [file join $profile_dir profile-*.md]]] {
    set base [file rootname [file tail $old_path]]
    set stem [string range $base [string length "profile-"] end]
    set new_path [file join $profile_dir "${stem}.md"]

    if {!$force && [file exists $new_path]} {
        puts "SKIP $stem — new file already exists (use --force to overwrite)"
        incr skipped
        continue
    }

    set fd [open $old_path r]
    fconfigure $fd -encoding utf-8
    set body [read $fd]
    close $fd

    set profile_date [extract_field $body {^\s*\*\*Profile date:\*\*\s*(.+)$}]
    if {$profile_date eq ""} { set profile_date [clock format [clock seconds] -format %Y-%m-%d] }

    set yield_raw [extract_field $body {^\s*\*\*(?:Richness classification|Profile yield):\*\*\s*(.+)$}]
    set yield [extract_yield $yield_raw]

    set warmth_raw [extract_field $body {^\s*\*\*Warmth level:\*\*\s*(.+)$}]
    set warmth_finding [normalise_warmth $warmth_raw]

    # Roster snapshot
    set contact_name ""
    set organisation ""
    set role ""
    set date_excluded "null"
    set star_rating 1
    if {[info exists roster_by_stem($stem)]} {
        set r $roster_by_stem($stem)
        set contact_name [string trim [spar::dict_get_default $r contact_name ""]]
        set organisation [string trim [spar::dict_get_default $r organisation ""]]
        set role [string trim [spar::dict_get_default $r role ""]]
        set de [string trim [spar::dict_get_default $r date_excluded ""]]
        if {$de ne ""} { set date_excluded $de }
        set sr [string trim [spar::dict_get_default $r star_rating ""]]
        if {[string is integer -strict $sr] && $sr >= 1 && $sr <= 5} {
            set star_rating $sr
        }
    } else {
        puts "WARN $stem — no roster row for stem; dependent_data snapshot will be blank"
        incr warnings
    }

    set fm {}
    lappend fm "---"
    lappend fm "profile_date: $profile_date"
    lappend fm "star_rating: $star_rating"
    lappend fm "yield: $yield"
    lappend fm "warmth_finding: $warmth_finding"
    lappend fm "applicable_angles:"
    lappend fm "  - to-be-reviewed"
    lappend fm "dependent_data:"
    if {$contact_name ne ""} { lappend fm "  contact_name: [yaml_scalar $contact_name]" }
    if {$organisation ne ""} { lappend fm "  organisation: [yaml_scalar $organisation]" }
    if {$role ne ""}         { lappend fm "  role: [yaml_scalar $role]" }
    lappend fm "  date_excluded: $date_excluded"
    lappend fm "---"

    set cleaned_body [strip_legacy_headers $body]
    set new_content [join $fm \n]\n\n[string trimleft $cleaned_body \n]

    if {$dry_run} {
        puts "DRYRUN $stem → $new_path"
        puts "       profile_date=$profile_date star=$star_rating yield=$yield warmth=$warmth_finding"
    } else {
        set fd [open $new_path w]
        fconfigure $fd -encoding utf-8
        puts -nonewline $fd $new_content
        close $fd
        puts "OK     $stem → [file tail $new_path]"
    }
    incr migrated
}

puts ""
puts "Migrated: $migrated   Skipped: $skipped   Warnings: $warnings"
if {$dry_run} {
    puts "(dry-run — no files written)"
}
