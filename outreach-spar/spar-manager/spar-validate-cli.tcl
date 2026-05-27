#!/usr/bin/env tclsh9.0
# spar-validate-cli.tcl — Validate SPAR campaign data from the command line.
# Usage: tclsh9.0 spar-validate-cli.tcl [campaign_dir_or_yaml] [--campaign=YAML]
#                                       [--segment=NAME ...] [--json]
#
# Runs the DATA-INTEGRITY validation pass (spec version gate + per-file
# approach/profile + roster cross-checks) with no dispatch and no progress
# table. Send-readiness is deliberately out of scope: the sender block is not
# checked here (it is an AR/send-time concern, surfaced by spar-progress and
# the send transition), and send-readiness codes such as placeholder_to (an
# unsent email whose recipient is obtained later, e.g. phone-first contacts)
# are reported as warnings, not errors. Exit code is nonzero iff a
# data-integrity error is found; warnings do not fail the run.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-state.tcl]

# --- Argument parsing (per-tool; campaign resolution is shared) ---
set campaign_dir ""
set campaign_file ""
set json_mode 0
set only_segments {}
foreach arg $argv {
    switch -glob -- $arg {
        --campaign=* { set campaign_file [string range $arg 11 end] }
        --segment=*  { lappend only_segments [string range $arg 10 end] }
        --json       { set json_mode 1 }
        --*          { puts stderr "Unknown flag: $arg"; exit 2 }
        default      {
            if {[string match *.yaml $arg]} {
                set campaign_file [file normalize $arg]
                set campaign_dir [file dirname $campaign_file]
            } else {
                set campaign_dir $arg
            }
        }
    }
}

# --- Resolve campaign (discover YAML, load, build segment paths) ---
if {[catch {set rc [spar::resolve_campaign $campaign_file $campaign_dir]} err]} {
    puts stderr $err
    exit 2
}
set cdata         [dict get $rc cdata]
set campaign_name [dict get $rc campaign_name]
set segment_paths [dict get $rc segment_paths]

# --- Restrict to --segment=NAME when given ---
if {[llength $only_segments] > 0} {
    set filtered {}
    foreach item $segment_paths {
        lassign $item label seg_dir
        if {$label in $only_segments} { lappend filtered $item }
    }
    set segment_paths $filtered
    if {[llength $segment_paths] == 0} {
        puts stderr "No matching segments for: $only_segments"
        exit 2
    }
}

# --- Classify all segments ---
set State [spar::State new]
set all_contacts {}
foreach item $segment_paths {
    lassign $item label seg_dir
    if {[catch {set classified [$State classify_segment $seg_dir]} cerr]} {
        puts stderr "Error classifying $label: $cerr"
        continue
    }
    lappend all_contacts {*}$classified
}

# --- Run validators (reuse the existing library; sender block excluded) ---
set issues {}
lappend issues {*}[spar::validate_versions $cdata $segment_paths]
lappend issues {*}[spar::validate_campaign $all_contacts 1 1]

# Send-readiness codes are AR/send-time concerns, not data integrity. They are
# always reported as warnings here, never as failures, regardless of the
# severity the library assigns them. placeholder_to: an unsent email whose
# recipient is obtained later (phone-first contacts) — T6 refuses to send it
# anyway, so it is not broken data.
set send_readiness_codes {placeholder_to}

# --- Partition by severity, sort within group ---
proc _issue_sort_key {issue} {
    return "[spar::dict_get_default $issue segment {}]\t[spar::dict_get_default $issue contact_name {}]"
}
set errors {}
set warnings {}
foreach issue $issues {
    if {[dict get $issue code] in $send_readiness_codes} {
        dict set issue severity warning
        lappend warnings $issue
    } elseif {[dict get $issue severity] eq "error"} {
        lappend errors $issue
    } else {
        lappend warnings $issue
    }
}
set errors   [lsort -command {apply {{a b} {string compare [_issue_sort_key $a] [_issue_sort_key $b]}}} $errors]
set warnings [lsort -command {apply {{a b} {string compare [_issue_sort_key $a] [_issue_sort_key $b]}}} $warnings]

# --- Output ---
proc _issue_line {issue} {
    set seg [spar::dict_get_default $issue segment ""]
    set cn  [spar::dict_get_default $issue contact_name ""]
    set ctx {}
    if {$seg ne ""} { lappend ctx $seg }
    if {$cn ne ""}  { lappend ctx $cn }
    set prefix [expr {[llength $ctx] ? "[join $ctx {/}]: " : ""}]
    return "\[[string toupper [dict get $issue severity]]\] [dict get $issue code]: $prefix[dict get $issue message]"
}

if {$json_mode} {
    package require json::write
    proc _issue_json {issue} {
        ::json::write object \
            severity     [::json::write string [dict get $issue severity]] \
            code         [::json::write string [dict get $issue code]] \
            segment      [::json::write string [spar::dict_get_default $issue segment ""]] \
            contact_name [::json::write string [spar::dict_get_default $issue contact_name ""]] \
            message      [::json::write string [dict get $issue message]]
    }
    set err_json {}
    foreach i $errors { lappend err_json [_issue_json $i] }
    set warn_json {}
    foreach i $warnings { lappend warn_json [_issue_json $i] }
    puts [::json::write object \
        campaign [::json::write string $campaign_name] \
        error_count [llength $errors] \
        warning_count [llength $warnings] \
        errors [::json::write array {*}$err_json] \
        warnings [::json::write array {*}$warn_json]]
} else {
    puts "Validating: $campaign_name"
    foreach i $errors   { puts [_issue_line $i] }
    foreach i $warnings { puts [_issue_line $i] }
    puts "[llength $errors] errors, [llength $warnings] warnings"
}

exit [expr {[llength $errors] > 0 ? 1 : 0}]
