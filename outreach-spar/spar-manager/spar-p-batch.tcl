#!/usr/bin/env tclsh
# spar-p-batch.tcl — Build SPAR-P profiles for roster entries without existing profiles
# Thin CLI wrapper around spar::dispatch_profiles (spar-dispatch.tcl)
# Usage: tclsh spar-p-batch.tcl <segment-dir> [--campaign=<yaml>] [--dry-run] [--jobs=N] [--logs=DIR]
#        tclsh spar-p-batch.tcl --overview=<path> [--antifacts=<path>] <segment-dir> [--dry-run]

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-dispatch.tcl]

# --- Argument parsing ---
set segment_dir ""
set dry_run 0
set jobs 4
set user_logs ""
set campaign_file ""
set user_overview ""
set user_antifacts ""

foreach arg $argv {
    switch -glob -- $arg {
        --dry-run       { set dry_run 1 }
        --jobs=*        { set jobs [string range $arg 7 end] }
        --logs=*        { set user_logs [string range $arg 7 end] }
        --campaign=*    { set campaign_file [string range $arg 11 end] }
        --overview=*    { set user_overview [string range $arg 11 end] }
        --antifacts=*   { set user_antifacts [string range $arg 12 end] }
        --*             { puts stderr "Unknown flag: $arg"; exit 1 }
        default         { set segment_dir $arg }
    }
}

if {$segment_dir eq ""} {
    puts stderr "Usage: tclsh spar-p-batch.tcl <segment-dir> \[--campaign=<yaml>\] \[--dry-run\] \[--jobs=N\] \[--logs=DIR\]"
    exit 1
}
if {![file isdirectory $segment_dir]} {
    puts stderr "Segment dir not found: $segment_dir"
    exit 1
}
if {$campaign_file eq "" && $user_overview eq ""} {
    puts stderr "Error: provide --campaign=<yaml> or --overview=<path> to specify the organisation overview document."
    exit 1
}

# --- Build opts dict ---
set opts [dict create \
    dry_run $dry_run \
    jobs $jobs]
if {$user_logs ne ""}       { dict set opts logs_dir $user_logs }
if {$campaign_file ne ""}   { dict set opts campaign_file $campaign_file }
if {$user_overview ne ""}   { dict set opts overview $user_overview }
if {$user_antifacts ne ""}  { dict set opts antifacts $user_antifacts }

# --- CLI callbacks ---
proc cli_on_progress {slug status message} {
    switch -- $status {
        done    { puts "  \[DONE\] $slug" }
        failed  { puts "  \[FAIL\] $slug ($message)" }
        default { }
    }
}

proc cli_on_complete {total_done total_failed result} {
    set ::_final_done $total_done
    set ::_final_failed $total_failed
    set ::alldone 1
}

# --- Dispatch ---
if {[catch {
    set result [spar::dispatch_profiles $segment_dir $opts cli_on_progress cli_on_complete]
} err]} {
    puts stderr $err
    exit 1
}

set count [dict get $result count]
set skipped [dict get $result skipped]

puts "Segment:  [dict get $result segment]"
puts "To build: $count profiles"
puts "Skipped:  $skipped (existing profiles)"

if {$dry_run} {
    puts "Dry run — prompts in [dict get $result prompts_dir]/"
    exit 0
}

if {$count == 0} {
    puts "Nothing to do."
    exit 0
}

puts "Running $count jobs, $jobs concurrent..."
puts ""

# Enter event loop — cli_on_complete sets ::alldone
vwait ::alldone

puts ""
puts "=== Summary ==="
puts "Logs:       [dict get $result logs_dir]/"
puts "Successful: $::_final_done"
puts "Failed:     $::_final_failed"
