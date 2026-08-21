#!/usr/bin/env tclsh9.0
# Dispatch pre-flight: P and A must refuse to launch on a campaign whose
# declared spec version this tool does not support (version_unsupported).
# The check sits right after load_campaign, before any segment/roster work.
package require yaml
package require TclOO
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::state
package require spar::prompts

set noop {apply {args {}}}

# Build a campaign stamped with $ver, one segment dir without a roster (the
# version gate fires before the segment loop, so no roster is needed).
proc versioned_campaign {ver} {
    set cdir [make_temp_campaign]
    file mkdir [file join $cdir segments seg-a]
    write_campaign_yaml $cdir "campaign: Dispatch Test\nversion: \"$ver\"\nsegments:\n  - seg-a\n"
    return $cdir
}

# ════════════════════════════════════════════════════════════════════════
# 50. dispatch refuses unsupported spec version
# ════════════════════════════════════════════════════════════════════════
section "50. dispatch version pre-flight"

set cdir [versioned_campaign "3.0"]
set opts [dict create campaign_file [file join $cdir campaigns camp.yaml]]

assert_error {spar::p::prepare_for_pool $opts $noop} \
    "*spec version*" "P refuses unsupported campaign version"
assert_error {spar::a::prepare_for_pool $opts $noop} \
    "*spec version*" "A refuses unsupported campaign version"

# A current-version campaign passes the version gate (it may stop later for
# other reasons — empty roster set — but not with a version error).
set cdir_ok [versioned_campaign $spar::CURRENT_SPEC_VERSION]
set opts_ok [dict create campaign_file [file join $cdir_ok campaigns camp.yaml]]
catch {spar::p::prepare_for_pool $opts_ok $noop} perr
assert_eq [string match "*spec version*" $perr] 0 "current version clears the P gate"

finish_tests
