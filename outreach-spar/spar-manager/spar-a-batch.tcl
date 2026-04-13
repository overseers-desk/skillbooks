#!/usr/bin/env tclsh9.0
# spar-a-batch.tcl — Generate SPAR-A approach files from a campaign YAML
# Thin CLI wrapper around spar::dispatch_approaches (spar-dispatch.tcl)
# Usage: tclsh9.0 spar-a-batch.tcl <campaign.yaml> [--dry-run] [--jobs=N] [--logs=DIR]

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-dispatch.tcl]

# --- Argument parsing ---
set campaign_file ""
set dry_run 0
set jobs 8
set user_logs ""

foreach arg $argv {
    switch -glob -- $arg {
        --dry-run   { set dry_run 1 }
        --jobs=*    { set jobs [string range $arg 7 end] }
        --logs=*    { set user_logs [string range $arg 7 end] }
        --*         { puts stderr "Unknown flag: $arg"; exit 1 }
        default     { set campaign_file $arg }
    }
}

if {$campaign_file eq ""} {
    puts stderr "Usage: tclsh9.0 spar-a-batch.tcl <campaign.yaml> \[--dry-run\] \[--jobs=N\] \[--logs=DIR\]"
    exit 1
}
if {![file exists $campaign_file]} {
    puts stderr "Campaign file not found: $campaign_file"
    exit 1
}

# --- Build opts dict ---
set opts [dict create \
    dry_run $dry_run \
    jobs $jobs]
if {$user_logs ne ""} { dict set opts logs_dir $user_logs }

# --- CLI callbacks ---
proc cli_on_progress {slug status message} {
    switch -- $status {
        done    { }
        failed  { puts "  \[FAIL\] $slug" }
        started {
            # Forward harness output lines (message contains the line)
            if {$message ne ""} {
                puts "  $message"
            }
        }
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
    set result [spar::dispatch_approaches $campaign_file $opts cli_on_progress cli_on_complete]
} err]} {
    puts stderr $err
    exit 1
}

# --- Print campaign summary ---
puts "Campaign:    [dict get $result campaign]"
puts "Sender:      [dict get $result sender_name] <[dict get $result sender_email]>"
puts "Language:    [dict get $result language]"
puts "Segments:    [dict get $result segments]"
puts "Filters:     [dict get $result filter_desc]"
puts ""

set count [dict get $result count]
set skipped [dict get $result skipped]

puts "Generated $count prompt files in [dict get $result prompts_dir]/"
puts "Skipped $skipped (approach file already exists)"
puts ""

if {$dry_run} {
    puts "Dry run complete. Review prompts in [dict get $result prompts_dir]/"
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
