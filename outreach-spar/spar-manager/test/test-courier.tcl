#!/usr/bin/env tclsh9.0
# spar::courier::contact_blocks asks the local mail index before courier
# (#225): courier runs only when `mu find` has a hit, or when the index
# cannot answer. `mu` and `courier` are stubbed ahead of PATH; each logs
# its query, and an address or subject containing "known" is a hit.
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::courier

set cr_dir [make_temp_dir]
set cr_log [file join $cr_dir calls.log]
proc cr_stub {name body} {
    set f [file join $::cr_dir $name]
    set fd [open $f w]
    puts $fd "#!/bin/sh"
    puts $fd "for q; do :; done"
    puts $fd "echo \"$name \$q\" >> '$::cr_log'"
    puts $fd $body
    close $fd
    file attributes $f -permissions 0755
}
# mu's own empty answer: exit 2 with its "no matches" message.
set mu_index {case "$q" in *known*) echo "Tue Jan 2 10:00:00 2024 Re: a booking";; *) echo "error: no matches for search expression" >&2; exit 2;; esac}
cr_stub mu $mu_index
cr_stub courier {case "$q" in *known*) echo "UID 41 [Gmail]/All Mail  Re: a booking";; *) exit 1;; esac}
set ::env(PATH) "$cr_dir:$::env(PATH)"
array unset ::auto_execs

proc cr_calls {} {
    if {![file exists $::cr_log]} { return {} }
    set fd [open $::cr_log]
    set lines [split [string trim [read $fd]] \n]
    close $fd
    file delete $::cr_log
    return $lines
}

# No correspondence anywhere: both passes answered by the index, and
# courier is never started.
cr_calls
set b [spar::courier::contact_blocks "Jo Stranger" "Nowhere Ltd" "jo@stranger.example"]
set calls [cr_calls]
assert_eq [llength [lsearch -all $calls courier*]] 0 \
    "index misses on both passes: courier is not called"
assert_eq [llength [lsearch -all $calls mu*]] 2 \
    "index misses: one mu find per pass"
assert_match [dict get $b author] "*\$ mu find 'from:jo@stranger.example OR to:jo@stranger.example'*no messages in the local mail index*" \
    "the author block shows the index lookup and its empty answer"
assert_eq [dict get $b prior] "" "no hits: the prior-correspondence block stays empty"

# A pass-1 hit in the index: courier runs that pass for the UID and
# folder, and pass 2 is skipped as before.
set b [spar::courier::contact_blocks "Jo Known" "" "jo@known.example"]
set calls [cr_calls]
assert_eq $calls [list "mu from:jo@known.example OR to:jo@known.example" \
    "courier from:jo@known.example OR to:jo@known.example"] \
    "index hit: courier runs the same query, once"
assert_match [dict get $b author] "*\$ courier -A search*UID 41*Pass 1 hit*" \
    "the author block carries courier's output"
assert_match [dict get $b prior] "*Prior correspondence*UID 41*" \
    "the prior-correspondence block carries courier's hits"
assert_eq [string match "*\$ courier*" [dict get $b prior]] 0 \
    "the prior-correspondence block carries no command line"

# Pass 1 empty in the index, pass 2 a hit: courier runs pass 2 only.
cr_calls
set b [spar::courier::contact_blocks "Pat Wellknown" "" "jo@stranger.example"]
set calls [cr_calls]
assert_eq [lsearch -all -inline $calls courier*] \
    [list {courier subject:"Pat Wellknown"}] \
    "pass-2 index hit: courier runs pass 2 alone"

# An index that cannot answer (an error other than "no matches") leaves
# the answer to courier, as does a host without mu.
cr_stub mu {echo "error: failed to open database" >&2; exit 1}
array unset ::auto_execs
spar::courier::contact_blocks "Jo Stranger" "" "jo@stranger.example"
assert_eq [llength [lsearch -all [cr_calls] courier*]] 2 \
    "unreadable index: courier answers both passes"

file delete [file join $cr_dir mu]
array unset ::auto_execs
if {[auto_execok mu] eq ""} {
    spar::courier::contact_blocks "Jo Stranger" "" "jo@stranger.example"
    assert_eq [llength [lsearch -all [cr_calls] courier*]] 2 \
        "no mu on PATH: courier answers both passes"
}

# A prefetch that could not run says so in both prompts (#102): an empty
# section would read as a contact with no history. The harness's
# inject_courier is the one caller, exercised on a prompt pair with the
# two placeholders.
section "prefetch that could not run"
package require spar::state
package require spar::harness
set pd [file join $cr_dir prompt]
set ld [file join $cr_dir logs]
file mkdir $pd $ld
proc cr_prompts {} {
    set a [file join $::pd author-draft.txt]
    set c [file join $::pd challenger-template.txt]
    spar::write_file $a "## Contact\n__COURIER_SECTION__\n\n## Channel\n"
    spar::write_file $c "### Your profile\n__PRIOR_CORRESPONDENCE__\n### The message\n"
    return [list $a $c]
}
set h [spar::Harness new $pd $ld]

# `courier list` failing: the reason carries courier's own words.
cr_stub courier {echo "no accounts configured" >&2; exit 1}
array unset ::auto_execs
lassign [cr_prompts] a c
$h inject_courier $a $c "Jo Stranger" "" "jo@stranger.example"
assert_match [spar::courier::not_run_reason] "*courier list*failed*no accounts configured*" \
    "a failing courier list is the reason given"
assert_match [spar::read_file $a] "*## Courier — prefetched by dispatcher*prefetch did not run: `courier list` failed*unknown, not absent*## Channel*" \
    "the author's brief says the prefetch did not run, in the courier section's place"
assert_match [spar::read_file $c] "*### Your profile*### Prior correspondence*Not established*could not be searched*### The message*" \
    "the persona's prior-correspondence slot says the mailbox could not be searched"
assert_eq [llength [lsearch -all [cr_calls] courier*]] 1 \
    "no contact search runs when the account list failed"

# courier absent from PATH: the same sections, with that reason. PATH is
# narrowed to the stub dir so a courier installed on the test machine
# does not answer in its place.
file delete [file join $cr_dir courier]
set saved_path $::env(PATH)
set ::env(PATH) $cr_dir
array unset ::auto_execs
lassign [cr_prompts] a c
$h inject_courier $a $c "Jo Stranger" "" "jo@stranger.example"
assert_eq [spar::courier::not_run_reason] "courier is not installed on this host" \
    "no courier on PATH is the reason given"
assert_match [spar::read_file $a] "*prefetch did not run: courier is not installed on this host*" \
    "the author's brief names the missing courier"
assert_eq [string match "*__PRIOR_CORRESPONDENCE__*" [spar::read_file $c]] 0 \
    "the persona's placeholder is filled"
set ::env(PATH) $saved_path
array unset ::auto_execs

finish_tests
