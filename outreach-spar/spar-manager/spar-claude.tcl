# spar-claude.tcl — TclOO base class for harnessed Claude CLI sessions.
#
# A "harness" wraps a single claude session with the machinery the DbC
# contract requires: JSON invocation, credit-limit retry, session-resume
# for fix loops, per-stage cost ledger. Subclasses (spar::ApproachHarness
# in spar-a-harness.tcl, spar::ProfileHarness in spar-p-harness.tcl)
# supply the phase-specific validate_and_correct loop.
#
# Requires spar-state.tcl or spar-lib.tcl sourced first (for
# spar::dict_get_default).

package require json
package require json::write
package require TclOO

source [file join [file dirname [file normalize [info script]]] spar-mailroom.tcl]

namespace eval spar {}

oo::class create spar::Harness {
    variable Slug LogPrefix CostLog SessionId

    constructor {slug log_prefix} {
        set Slug $slug
        set LogPrefix $log_prefix
        set CostLog "${log_prefix}-cost.jsonl"
        set SessionId ""
        set fd [open $CostLog w]; close $fd
    }

    # Public accessors — subclasses and harness scripts use these.
    method slug        {} { return $Slug }
    method log_prefix  {} { return $LogPrefix }
    method cost_log    {} { return $CostLog }
    method session_id  {} { return $SessionId }

    # call — first or standalone claude call. Returns 0 on success, 1 on
    # failure. Captures session_id from the JSON response; subsequent calls
    # on the same harness reuse it via `resume`.
    method call {stage log_file prompt args} {
        set rc [my _invoke $stage $log_file $prompt {*}$args]
        if {$rc == 0 && $SessionId eq ""} {
            set SessionId [my _extract_session_id "${log_file}.json"]
        }
        return $rc
    }

    # resume — resume the captured session with a fix/revision prompt.
    # Fails if call has not yet been made successfully.
    method resume {stage log_file prompt args} {
        if {$SessionId eq ""} {
            error "spar::Harness::resume: no session_id — call must succeed first"
        }
        return [my _invoke $stage $log_file $prompt --resume $SessionId {*}$args]
    }

    # inject_mailroom — substitute __MAILROOM_SECTION__ in the prompt
    # file with the prefetched mailroom block (accounts header + per-
    # contact correspondence cascade). Runs in the harness so the slow
    # `mailroom -A search` exec parallelises across contacts instead of
    # serialising in the dispatcher's prepare loop. Empty section when
    # mailroom isn't installed.
    method inject_mailroom {prompt_path name org email} {
        set hdr  [spar::mailroom::accounts_block]
        set body [spar::mailroom::contact_block $name $org $email]
        set section [expr {$hdr eq "" ? "" : "\n\n${hdr}${body}"}]
        set prompt [spar::read_file $prompt_path]
        set prompt [string map [list __MAILROOM_SECTION__ $section] $prompt]
        spar::write_file $prompt_path $prompt
        puts "\[$Slug\] \[phase: mailroom\]"
        flush stdout
    }

    # cost_total — sum `cost` fields across the JSONL ledger.
    method cost_total {} {
        set total 0.0
        if {![file exists $CostLog]} { return $total }
        set fd [open $CostLog r]
        while {[gets $fd line] >= 0} {
            set line [string trim $line]
            if {$line eq ""} continue
            if {[catch {set d [::json::json2dict $line]}]} continue
            set total [expr {$total + [spar::dict_get_default $d cost 0]}]
        }
        close $fd
        return $total
    }

    # _invoke — the single claude-CLI call loop. Handles credit-limit
    # waits, JSON parse, result extraction, cost-log append.
    method _invoke {stage log_file prompt args} {
        set json_file "${log_file}.json"
        set max_retries 5
        set attempt 0

        while {1} {
            incr attempt

            set claude_bin [spar::find_tool claude]
            if {$claude_bin eq ""} {
                puts "FAIL ($stage: claude not found — check Settings): $Slug"
                return 1
            }
            set cmd [list $claude_bin -p --output-format json --dangerously-skip-permissions]
            set cmd [concat $cmd $args [list $prompt]]

            if {[catch {
                exec {*}$cmd > $json_file 2> "${log_file}.stderr"
            }]} {
                if {![file exists $json_file] || [file size $json_file] == 0} {
                    puts "FAIL ($stage rc=error): $Slug"
                    return 1
                }
            }

            set fd [open $json_file r]
            set raw_json [read $fd]
            close $fd

            if {[catch {set parsed [::json::json2dict $raw_json]}]} {
                puts "FAIL ($stage: invalid JSON): $Slug"
                return 1
            }

            if {[dict exists $parsed is_error] && [dict get $parsed is_error] eq "true"} {
                set result_text [spar::dict_get_default $parsed result ""]
                if {[string match -nocase *hit*your*limit*resets* $result_text]} {
                    if {$attempt >= $max_retries} {
                        puts "FAIL ($stage: credit limit after $max_retries retries): $Slug"
                        return 1
                    }
                    set wait_secs [my _credit_wait_secs $result_text]
                    puts "\[$Slug\] Credit limit hit (attempt $attempt/$max_retries). Sleeping [expr {$wait_secs/60}]m until reset..."
                    after [expr {$wait_secs * 1000}] set ::_wake 1
                    vwait ::_wake
                    continue
                }
            }

            if {![dict exists $parsed result]} {
                puts "FAIL ($stage: no result in output): $Slug"
                return 1
            }

            set fd [open $log_file w]
            puts -nonewline $fd [dict get $parsed result]
            close $fd

            set _prev_indent [::json::write indented]
            ::json::write indented false
            set cost_entry [::json::write object \
                stage [::json::write string $stage] \
                cost [spar::dict_get_default $parsed total_cost_usd 0]]
            ::json::write indented $_prev_indent
            set fd [open $CostLog a]
            puts $fd $cost_entry
            close $fd

            return 0
        }
    }

    method _extract_session_id {json_file} {
        set fd [open $json_file r]
        set raw [read $fd]
        close $fd
        set parsed [::json::json2dict $raw]
        if {![dict exists $parsed session_id]} { return "" }
        return [dict get $parsed session_id]
    }

    # Parse "resets 3am (Australia/Brisbane)" → seconds to sleep.
    method _credit_wait_secs {msg} {
        if {![regexp {resets (\d{1,2}(?::\d{2})?\s*[ap]m)} $msg -> reset_time]} {
            return 3600
        }
        set tz "Australia/Brisbane"
        if {[regexp {\(([^)]+)\)} $msg -> found_tz]} {
            set tz $found_tz
        }
        set now_epoch [clock seconds]
        if {[catch {
            set reset_epoch [clock scan "today $reset_time" -timezone :$tz]
        }]} {
            return 3600
        }
        if {$reset_epoch <= $now_epoch} {
            if {[catch {
                set reset_epoch [clock scan "tomorrow $reset_time" -timezone :$tz]
            }]} {
                return 3600
            }
        }
        set wait [expr {$reset_epoch - $now_epoch + 120}]
        if {$wait < 60} { set wait 60 }
        return $wait
    }
}

# Lightweight file helpers — used across harness scripts.
proc spar::read_file {path} {
    set fd [open $path r]
    set content [read $fd]
    close $fd
    return $content
}

proc spar::write_file {path content} {
    set fd [open $path w]
    puts -nonewline $fd $content
    close $fd
}

package provide spar-claude 1.0
