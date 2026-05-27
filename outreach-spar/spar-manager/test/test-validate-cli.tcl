#!/usr/bin/env tclsh9.0
package require yaml
package require json
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

set cli_path [file join $script_dir .. spar-validate-cli.tcl]

# run_cli -- invoke spar-validate-cli.tcl, return {rc stdout}. Captures the
# child exit code from -errorcode CHILDSTATUS, since exec raises on nonzero.
proc run_cli {args} {
    set tmp [file join /tmp "spar-cli-out-[pid]-[clock microseconds]"]
    set rc 0
    if {[catch {exec tclsh9.0 $::cli_path {*}$args > $tmp 2>/dev/null} _ opts]} {
        set ec [dict get $opts -errorcode]
        set rc [expr {[lindex $ec 0] eq "CHILDSTATUS" ? [lindex $ec 2] : -1}]
    }
    set fd [open $tmp r]; set out [read $fd]; close $fd
    file delete $tmp
    return [list $rc $out]
}

# Build a minimal one-segment campaign. Returns the campaign dir.
# opts: -campaign_version, -segment_version (default 1.0 each),
#       -email (roster email, default valid), -approach (raw approach yaml or "")
proc make_cli_campaign {args} {
    set cv [expr {[dict exists $args -campaign_version] ? [dict get $args -campaign_version] : "1.0"}]
    set sv [expr {[dict exists $args -segment_version] ? [dict get $args -segment_version] : "1.0"}]
    set email [expr {[dict exists $args -email] ? [dict get $args -email] : "alice@test.com"}]
    set approach [expr {[dict exists $args -approach] ? [dict get $args -approach] : ""}]

    set cdir [make_temp_campaign]
    set seg [file join $cdir seg-a]
    file mkdir $seg
    file mkdir [file join $seg profiles]
    file mkdir [file join $seg approach]
    write_roster_tsv $seg $::std_headers [list \
        [make_base_row [list stem "alice" contact_name "Alice" star_rating "5" email $email]]]
    write_profile $seg "alice"
    if {$approach ne ""} { write_approach_yaml $seg "alice" $approach }
    write_segment_yaml $seg "title: Seg A\nversion: \"$sv\"\n"
    write_campaign_yaml $cdir "campaign: CLI Test\nversion: \"$cv\"\nsegments:\n  - seg-a\nfilter:\n  min_star: 3\n"
    return $cdir
}

# ════════════════════════════════════════════════════════════════════════
# 40. validate CLI exit codes
# ════════════════════════════════════════════════════════════════════════
section "40. spar-validate-cli.tcl"

# clean, stamped → exit 0
lassign [run_cli [make_cli_campaign] --json] rc out
set parsed [::json::json2dict $out]
assert_eq $rc 0 "clean stamped campaign → exit 0"
assert_eq [dict get $parsed error_count] 0 "clean → zero errors"

# data-integrity error (masked email) → exit 1, code in json errors
lassign [run_cli [make_cli_campaign -email "a***@test.com"] --json] rc out
set parsed [::json::json2dict $out]
assert_eq $rc 1 "masked email → exit 1"
set codes {}
foreach e [dict get $parsed errors] { lappend codes [dict get $e code] }
assert_eq [expr {"masked_email" in $codes}] 1 "masked_email present in errors"

# unsupported spec version → exit 1, version_unsupported
lassign [run_cli [make_cli_campaign -campaign_version "2.0"] --json] rc out
set parsed [::json::json2dict $out]
assert_eq $rc 1 "campaign version 2.0 → exit 1"
set codes {}
foreach e [dict get $parsed errors] { lappend codes [dict get $e code] }
assert_eq [expr {"version_unsupported" in $codes}] 1 "version_unsupported present in errors"

# unstamped (missing version) → warning only, exit 0
set cdir [make_temp_campaign]
set seg [file join $cdir seg-a]
file mkdir $seg; file mkdir [file join $seg profiles]; file mkdir [file join $seg approach]
write_roster_tsv $seg $::std_headers [list \
    [make_base_row {stem "alice" contact_name "Alice" star_rating "5" email "alice@test.com"}]]
write_profile $seg "alice"
write_campaign_yaml $cdir "campaign: CLI Test\nsegments:\n  - seg-a\nfilter:\n  min_star: 3\n"
lassign [run_cli $cdir --json] rc out
set parsed [::json::json2dict $out]
assert_eq $rc 0 "unstamped campaign → exit 0 (warning only)"
set wcodes {}
foreach w [dict get $parsed warnings] { lappend wcodes [dict get $w code] }
assert_eq [expr {"version_unstamped" in $wcodes}] 1 "version_unstamped present in warnings"

# placeholder_to is a send-readiness code → warning, not error, exit 0
set placeholder_approach {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: '[email obtained during call]'
    subject: Hello
    body: Hi there
    actioned_date: null
    replied_date: null
}
lassign [run_cli [make_cli_campaign -approach $placeholder_approach] --json] rc out
set parsed [::json::json2dict $out]
assert_eq $rc 0 "placeholder_to → exit 0 (send-readiness warning)"
set wcodes {}
foreach w [dict get $parsed warnings] { lappend wcodes [dict get $w code] }
assert_eq [expr {"placeholder_to" in $wcodes}] 1 "placeholder_to reported as warning"

finish_tests
