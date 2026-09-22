#!/usr/bin/env tclsh9.0
# spar::dealings — the prior-dealings block injected into the P prompt.
# The assertions here are the ones that keep I1 (SPAR INVARIANTS.md):
# the block never carries our outbound, never carries an aggregate, and
# says nothing at all when the contact has never written to us. The
# index is stubbed so the properties are tested rather than the mail.
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
package require spar::dealings

# Record every query the block issues, and answer from a script-set
# table rather than the local index.
namespace eval stub {
    variable queries {}
    variable answers {}
}
proc spar::dealings::_find {query limit} {
    lappend ::stub::queries $query
    foreach {pat rows} $::stub::answers {
        if {[string match $pat $query]} { return $rows }
    }
    return {}
}
proc stub_reset {{answers {}}} {
    set ::stub::queries {}
    set ::stub::answers $answers
}

# --- silence on empty: the property that makes an absence unwritable ---

stub_reset
assert_eq [spar::dealings::inbound_block "A Name" "An Org" "a@example.org"] "" \
    "no hits yields the empty string, not a header and not a date"

stub_reset
assert_eq [spar::dealings::inbound_block "A Name" "An Org" ""] "" \
    "blank email yields the empty string"
assert_eq [llength $::stub::queries] 0 \
    "blank email issues no query at all"

stub_reset
assert_eq [spar::dealings::inbound_block "A Name" "An Org" "via website"] "" \
    "a non-address contact method yields the empty string"
assert_eq [llength $::stub::queries] 0 \
    "a non-address contact method issues no query"

# --- direction: our outbound is never asked for, so it cannot leak ---

stub_reset [list {from:a@example.org AND NOT flag:list} \
    {{Tue Jan 2 10:00:00 2024 Re: a booking}}]
set block [spar::dealings::inbound_block "A Name" "An Org" "a@example.org"]
assert_eq [string match "*Re: a booking*" $block] 1 \
    "an inbound message reaches the block"
foreach q $::stub::queries {
    assert_eq [string match "*to:*" $q] 0 "no query asks for what we sent: $q"
}

# --- bulk traffic is filtered on every query ---

foreach q $::stub::queries {
    assert_eq [string match "*NOT flag:list*" $q] 1 \
        "bulk and list traffic is excluded: $q"
}

# --- no aggregate: the block states no count, score or grade ---

assert_eq [regexp -nocase {(warm|cold|score|rating|[0-9]+ messages)} $block] 0 \
    "the block carries no warmth word, score or message count"

# --- the colleague fallback, and the cap that discards a saturated one ---

stub_reset [list {from:example.org AND NOT from:a@example.org AND NOT flag:list} \
    {{Wed Jan 3 10:00:00 2024 From a colleague}}]
set block [spar::dealings::inbound_block "A Name" "An Org" "a@example.org"]
assert_eq [string match "*From a colleague*" $block] 1 \
    "a colleague at the same domain reaches the block"
assert_eq [string match "*organisation rather than this person*" $block] 1 \
    "the colleague lines are labelled as the organisation, not the contact"

set saturated {}
for {set i 0} {$i < $spar::dealings::domain_cap} {incr i} {
    lappend saturated "Wed Jan 3 10:00:00 2024 Bulk $i"
}
stub_reset [list {from:example.org AND NOT from:a@example.org AND NOT flag:list} $saturated]
assert_eq [spar::dealings::inbound_block "A Name" "An Org" "a@example.org"] "" \
    "a domain query at the cap is matching more than one employer, so it is discarded"

# --- a free webmail domain gets no colleague query ---

stub_reset
spar::dealings::inbound_block "A Name" "An Org" "a@gmail.com"
foreach q $::stub::queries {
    assert_eq [string match "*from:gmail.com *" $q] 0 \
        "no colleague query runs against a free webmail domain: $q"
}

finish_tests
