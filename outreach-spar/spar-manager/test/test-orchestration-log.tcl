#!/usr/bin/env tclsh9.0
# FM-LOG-1: the GUI's log-window appender is also the orchestration
# file's tee. install_logger_appender routes spar* logger services
# through _logwin_emit, which forwards every line to spar::_orch_write.
# A line shown in the log window therefore also lands in the
# orchestration file once ensure_orchestration_file has minted one.
#
# Sources Tk (via ui/log-window.tcl) so run.tcl's needs_tk detection
# picks this up as a GUI test and runs it under wish9.0/Xvfb; the
# explicit `package require Tk` line below is what that detection
# keys on (mirrors test-pool-gui.tcl).

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]

package require Tk
wm withdraw .

source [file join $script_dir .. lib spar-state.tcl]
source [file join $script_dir .. lib spar-dispatcher.tcl]
source [file join $script_dir .. ui log-window.tcl]

# ── Scratch orchestration-log root, mirroring test-lib.tcl's idiom ─────
set scratch [make_temp_dir]
proc spar::logs_root {} { return $::scratch }
set ::spar::_orch_logfile ""

set log [spar::ui::LogWindow new 0]
spar::ui::install_logger_appender $log

section "ensure_orchestration_file via the GUI tee"

assert_eq [spar::ensure_orchestration_file /tmp/c.yaml 1] "" \
    "dry run: ensure_orchestration_file returns empty path"
assert_eq [llength [glob -nocomplain -directory $scratch *]] 0 \
    "dry run: no file created"

set orch_file [spar::ensure_orchestration_file /tmp/c.yaml 0]
assert_match $orch_file "$scratch/orchestration-c-*" \
    "live run: ensure_orchestration_file names the file for the campaign"

section "log_row_outcome reaches both the buffer and the orchestration file"

spar::log_row_outcome some-slug failed "boom"

set fd [open $orch_file r]
set contents [read $fd]
close $fd
assert_match $contents "*\\\[spar::transitions\\\]*" \
    "orchestration file: line is tagged with the spar::transitions service"
assert_match $contents "*\\\[FAIL \\\] some-slug (boom)*" \
    "orchestration file: FAIL line for the failed row"

set buffer [$log get_buffer]
set found 0
foreach entry $buffer {
    lassign $entry line level
    if {[string match "*\\\[FAIL \\\] some-slug (boom)*" $line] && $level eq "error"} {
        set found 1
    }
}
assert_eq $found 1 \
    "log window buffer: FAIL line present at level error"

set ::spar::_orch_logfile ""

finish_tests
