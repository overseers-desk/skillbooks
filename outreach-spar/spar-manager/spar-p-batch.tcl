#!/usr/bin/env tclsh
# spar-p-batch.tcl — Build SPAR-P profiles for roster entries without existing profiles
# Tcl port of ../bin/spar-p-batch.sh
# Usage: tclsh spar-p-batch.tcl <segment-dir> [--campaign=<yaml>] [--dry-run] [--jobs=N] [--logs=DIR]
#        tclsh spar-p-batch.tcl --overview=<path> [--antifacts=<path>] <segment-dir> [--dry-run]

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir spar-lib.tcl]

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

set segment_dir [file normalize $segment_dir]
set roster_path [file join $segment_dir roster.tsv]
set profile_dir [file join $segment_dir profiles]
set goal_path [file join $segment_dir segment.yaml]
if {![file exists $goal_path]} {
    set goal_path [file join $segment_dir goal.md]
}

# SPAR-P procedure doc is one level up from spar-manager/
set spar_p [file normalize [file join $script_dir .. spar-P-profile.md]]

# --- Resolve overview/antifacts from campaign YAML or flags ---
set overview ""
set antifacts ""

if {$campaign_file ne ""} {
    set cdata [spar::load_campaign $campaign_file]
    set overview [spar::dict_get_default $cdata usp_document]
    set antifacts [spar::dict_get_default $cdata antifacts]
} elseif {$user_overview ne ""} {
    set overview [file normalize $user_overview]
    if {$user_antifacts ne ""} {
        set antifacts [file normalize $user_antifacts]
    }
} else {
    puts stderr "Error: provide --campaign=<yaml> or --overview=<path> to specify the organisation overview document."
    exit 1
}

# --- Validate required files ---
foreach {path label} [list $roster_path Roster $goal_path Goal $spar_p SPAR-P $overview Overview] {
    if {![file exists $path]} {
        puts stderr "$label not found: $path"
        exit 1
    }
}
if {$antifacts ne "" && ![file exists $antifacts]} {
    puts stderr "Antifacts not found: $antifacts"
    exit 1
}
file mkdir $profile_dir

# --- Working directories ---
set datestamp [clock format [clock seconds] -format %Y%m%d%H%M]
set workdir "/tmp/spar-p-[file tail $segment_dir]-$datestamp"
set prompts_dir [file join $workdir prompts]
file mkdir $prompts_dir

if {$user_logs ne ""} {
    if {![file isdirectory $user_logs]} {
        puts stderr "Log directory not found: $user_logs"
        exit 1
    }
    set logs_dir $user_logs
} elseif {[file isdirectory /var/local/logs/spar]} {
    set logs_dir "/var/local/logs/spar/spar-p-[file tail $segment_dir]-$datestamp"
} else {
    set logs_dir "$::env(HOME)/logs/spar/spar-p-[file tail $segment_dir]-$datestamp"
}
if {$user_logs eq ""} {
    file mkdir $logs_dir
}

# --- Load roster ---
set rows [spar::load_roster $roster_path]

# --- Generate prompts ---
set count 0
set skipped 0

foreach row $rows {
    set name [string trim [spar::dict_get_default $row contact_name]]
    set org [string trim [spar::dict_get_default $row organisation]]
    set role [string trim [spar::dict_get_default $row role]]
    set phone [string trim [spar::dict_get_default $row phone]]
    set email [string trim [spar::dict_get_default $row email]]
    set linkedin [string trim [spar::dict_get_default $row linkedin_url]]
    set facebook [string trim [spar::dict_get_default $row facebook_url]]
    set date_invalid [string trim [spar::dict_get_default $row date_found_invalid]]
    set s_note [string trim [spar::dict_get_default $row s_note]]
    set p_note [string trim [spar::dict_get_default $row p_note]]

    # Skip header fragments, blank rows, invalidated entries
    if {$name eq "" || $name eq "contact_name" || $name eq "organisation"} continue
    if {$org eq ""} continue
    if {$date_invalid ne ""} continue

    set slug_name [spar::slugify $name]
    set slug_org [spar::slugify $org]
    set outfile [file join $profile_dir "profile-${slug_name}-${slug_org}.md"]

    # Skip if profile already exists (any of three matching strategies)
    if {[file exists $outfile] || [spar::profile_exists $profile_dir $slug_name $slug_org]} {
        incr skipped
        continue
    }

    incr count
    set prompt_slug [format "%03d-%s-%s" $count $slug_name $slug_org]
    set prompt_file [file join $prompts_dir "${prompt_slug}.txt"]

    set antifacts_line ""
    if {$antifacts ne ""} {
        set antifacts_line "Antifact checklist: read $antifacts — flag any claims not supported by these sources."
    }

    set prompt "Follow the SPAR-P procedure at $spar_p.

Target: $name at $org, role: $role. Phone: $phone. Email: $email. LinkedIn: $linkedin. Facebook: $facebook.
Roster notes — s_note: $s_note, p_note: $p_note.

Campaign context: read $goal_path for the segment's objective, USPs, and angle table.
Organisation overview: read $overview for ground truth about the organisation.
$antifacts_line

Output file: $outfile
Roster file: $roster_path

Follow SPAR-P §5 profile structure exactly. After writing the profile, follow SPAR-P §4.9 to write star_rating and response_likelihood to the roster TSV (not to the profile document). Then follow §4.11 to backfill any missing contact details (email, linkedin_url, facebook_url) and replace stale contacts discovered during research with the person currently in the role.
Web search is the primary research method. Use Chromium only when the target has a LinkedIn or Facebook URL and WebFetch returns insufficient data. Wrap Chromium with flock: flock /tmp/chromium.lock /snap/bin/chromium --headless --dump-dom --virtual-time-budget=30000 --window-size=1920,10000 --user-data-dir=\"\$HOME/snap/chromium/common/chromium\" \"URL\" 2>/dev/null"

    set fd [open $prompt_file w]
    puts $fd $prompt
    close $fd
}

puts "Segment:  [file tail $segment_dir]"
puts "To build: $count profiles"
puts "Skipped:  $skipped (existing profiles)"

if {$dry_run} {
    puts "Dry run — prompts in $prompts_dir/"
    exit 0
}

if {$count == 0} {
    puts "Nothing to do."
    exit 0
}

puts "Running $count jobs, $jobs concurrent..."
puts ""

# --- Concurrent dispatch via event loop ---
# Collect all prompt files, then run up to $jobs at a time
set prompt_files [lsort [glob -nocomplain [file join $prompts_dir *.txt]]]
set active 0
set completed 0
set failed 0
set queue $prompt_files
set queue_idx 0

proc start_next {} {
    global queue queue_idx jobs active completed failed count logs_dir

    while {$queue_idx < [llength $queue] && $active < $jobs} {
        set pfile [lindex $queue $queue_idx]
        incr queue_idx
        set slug [file rootname [file tail $pfile]]
        set logfile [file join $logs_dir "${slug}.log"]

        set pipe [open "| /bin/sh -c {cat \"$pfile\" | claude -p --dangerously-skip-permissions --model sonnet --max-budget-usd 3.00 > \"$logfile\" 2>&1; echo \"EXIT:\$?\"}" r]
        fconfigure $pipe -blocking 0 -buffering line
        fileevent $pipe readable [list on_worker_done $pipe $slug]
        incr active
    }

    if {$active == 0 && $queue_idx >= [llength $queue]} {
        set ::alldone 1
    }
}

proc on_worker_done {pipe slug} {
    global active completed failed count

    if {[gets $pipe line] >= 0} {
        # Check for our exit status sentinel
        if {[string match "EXIT:*" $line]} {
            set rc [string range $line 5 end]
            if {$rc ne "0"} {
                puts "  \[FAIL\] $slug (rc=$rc)"
                incr failed
            } else {
                puts "  \[DONE\] $slug"
                incr completed
            }
        }
        return
    }
    if {[eof $pipe]} {
        catch {close $pipe}
        incr active -1
        start_next
    }
}

start_next
if {$count > 0} {
    vwait ::alldone
}

puts ""
puts "=== Summary ==="
puts "Logs:       $logs_dir/"
puts "Successful: $completed"
puts "Failed:     $failed"
