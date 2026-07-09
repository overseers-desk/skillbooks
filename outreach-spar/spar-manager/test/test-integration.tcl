#!/usr/bin/env tclsh9.0
package require yaml
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

set State [spar::State new]

# ════════════════════════════════════════════════════════════════════════
# 13. Golden snapshot (real campaign data)
# ════════════════════════════════════════════════════════════════════════
section "13. Golden snapshot (real campaign data)"

set campaign_dir [file normalize [file join $script_dir .. .. .. .. rivermill segments-outreach.spar]]
if {![file isdirectory $campaign_dir]} {
    puts "  SKIP: campaign directory not found ($campaign_dir)"
} else {
    # 13a. line-dance segment
    set ld_seg [file join $campaign_dir line-dance]
    set ld_contacts [$State classify_segment $ld_seg]
    set ld_counts [spar::progress_counts $ld_contacts]
    assert_eq [dict get $ld_counts valid] 12 "golden line-dance: valid=12"
    assert_eq [dict get $ld_counts profiled] 12 "golden line-dance: profiled=12"
    assert_eq [dict get $ld_counts star3] 10 "golden line-dance: star3=10"

    # 13b. community-organisation segment
    set co_seg [file join $campaign_dir community-organisation]
    set co_contacts [$State classify_segment $co_seg]
    set co_counts [spar::progress_counts $co_contacts]
    assert_eq [dict get $co_counts valid] 73 "golden community-organisation: valid=73"
    assert_eq [dict get $co_counts profiled] 73 "golden community-organisation: profiled=73"
}

# ════════════════════════════════════════════════════════════════════════
# 20. --json integration test (spar-progress.tcl)
# ════════════════════════════════════════════════════════════════════════
section "20. --json integration test"

package require json


set cdir [make_temp_campaign]
set seg_a [file join $cdir seg-a]
file mkdir $seg_a
file mkdir [file join $seg_a profiles]
file mkdir [file join $seg_a approach]
write_roster_tsv $seg_a $::std_headers [list \
    [make_base_row {stem "alice" contact_name "Alice" star_rating "5" email "a@test.com"}] \
    [make_base_row {stem "bob" contact_name "Bob" star_rating "3" email "b@test.com"}] \
]
write_profile $seg_a "alice"
write_campaign_yaml $cdir "campaign: Test Campaign\nsegments:\n  - seg-a\nfilter:\n  min_star: 3\n"

set progress_script [file join $script_dir .. spar-progress.tcl]
set json_str [exec tclsh9.0 $progress_script $cdir --json 2>/dev/null]
set parsed [::json::json2dict $json_str]

assert_eq [dict get $parsed campaign] "Test Campaign" "json: campaign value"
assert_eq [dict exists $parsed totals] 1 "json: has totals"
set jtotals [dict get $parsed totals]
assert_eq [dict exists $jtotals qualified] 1 "json: totals has qualified"
set jq [dict get $jtotals qualified]
assert_eq [dict exists $jq count] 1 "json: qualified has count"
assert_eq [dict exists $jq approached] 1 "json: qualified has approached"
assert_eq [dict exists $jq sent] 1 "json: qualified has sent"
assert_eq [dict exists $jq replied] 1 "json: qualified has replied"
assert_eq [dict exists $jq channels] 1 "json: qualified has channels"
set jch [dict get $jq channels]
assert_eq [dict exists $jch email] 1 "json: channels has email"
assert_eq [dict exists $jch linkedin] 1 "json: channels has linkedin"
assert_eq [dict exists $jch facebook] 1 "json: channels has facebook"
assert_eq [dict exists $jch phone_only] 1 "json: channels has phone_only"
assert_eq [dict exists $parsed segments] 1 "json: has segments"
assert_eq [llength [dict get $parsed segments]] 1 "json: one segment"
assert_eq [dict exists $parsed transitions] 1 "json: has transitions"
assert_eq [llength [dict get $parsed transitions]] 7 "json: 7 transitions"
assert_eq [dict exists $parsed warnings] 1 "json: has warnings"
assert_eq [dict exists $parsed validation] 1 "json: has validation"

# Test YAML-as-positional-arg
set json_str2 [exec tclsh9.0 $progress_script [file join $cdir campaign.yaml] --json 2>/dev/null]
set parsed2 [::json::json2dict $json_str2]
assert_eq [dict get $parsed2 campaign] "Test Campaign" "json: YAML as positional arg"


finish_tests
