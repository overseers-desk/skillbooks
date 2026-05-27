#!/usr/bin/env tclsh9.0
package require yaml
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

# ════════════════════════════════════════════════════════════════════════
# 30. spec version gate (validate_spec_version, readers, validate_versions)
# ════════════════════════════════════════════════════════════════════════
section "30. validate_spec_version"

# current version → no issue
set i [spar::validate_spec_version $spar::CURRENT_SPEC_VERSION "campaign.yaml"]
assert_eq [llength $i] 0 "current version → no issue"

# missing version → one unstamped warning
set i [spar::validate_spec_version "" "campaign.yaml"]
assert_eq [llength $i] 1 "missing version → one issue"
assert_eq [has_issue $i version_unstamped] 1 "missing version → version_unstamped"
assert_eq [dict get [lindex $i 0] severity] warning "version_unstamped is a warning"

# unknown/future version → one unsupported error
set i [spar::validate_spec_version "2.0" "campaign.yaml"]
assert_eq [has_issue $i version_unsupported] 1 "future version → version_unsupported"
assert_eq [dict get [lindex $i 0] severity] error "version_unsupported is an error"

# extra passthrough carries the segment label
set i [spar::validate_spec_version "2.0" "segment 'growers-market'" {segment growers-market}]
assert_eq [dict get [lindex $i 0] segment] growers-market "extra {segment ...} flows into the issue"

# ════════════════════════════════════════════════════════════════════════
# 31. version readers round-trip through the YAML parser
# ════════════════════════════════════════════════════════════════════════
section "31. campaign_version / segment_version readers"

set c1 [make_temp_campaign]
write_campaign_yaml $c1 "campaign: Test\nversion: \"1.0\"\n"
set cdata1 [spar::load_campaign [file join $c1 campaign.yaml]]
assert_eq [spar::campaign_version $cdata1] "1.0" "campaign_version reads declared version"

set c2 [make_temp_campaign]
write_campaign_yaml $c2 "campaign: Test\n"
set cdata2 [spar::load_campaign [file join $c2 campaign.yaml]]
assert_eq [spar::campaign_version $cdata2] "" "campaign_version returns empty when absent"

set s1 [make_temp_segment]
write_segment_yaml $s1 "title: Widget buyers\nversion: \"1.0\"\n"
set sdata1 [spar::read_segment_yaml [file join $s1 segment.yaml]]
assert_eq [spar::segment_version $sdata1] "1.0" "segment_version reads declared version"

# ════════════════════════════════════════════════════════════════════════
# 32. validate_versions aggregator over campaign + segments
# ════════════════════════════════════════════════════════════════════════
section "32. validate_versions"

# stamped campaign + stamped segment → clean
set sg_ok [make_temp_segment]
write_segment_yaml $sg_ok "title: Seg\nversion: \"1.0\"\n"
set issues [spar::validate_versions [dict create version 1.0] [list [list seg-ok $sg_ok]]]
assert_eq [llength $issues] 0 "stamped campaign + segment → no version issues"

# unstamped campaign + unstamped segment (no segment.yaml) → two warnings
set sg_bare [make_temp_segment]
set issues [spar::validate_versions [dict create] [list [list seg-bare $sg_bare]]]
assert_eq [llength $issues] 2 "unstamped campaign + missing segment.yaml → two issues"
assert_eq [llength [issues_with_code $issues version_unstamped]] 2 "both are version_unstamped"

# unsupported campaign version → error surfaces
set issues [spar::validate_versions [dict create version 2.0] [list [list seg-ok $sg_ok]]]
assert_eq [has_issue $issues version_unsupported] 1 "future campaign version → version_unsupported"

# ════════════════════════════════════════════════════════════════════════
# 33. assert_supported_version (dispatcher refuse-to-start guard)
# ════════════════════════════════════════════════════════════════════════
section "33. assert_supported_version"

assert_error {spar::assert_supported_version "campaign.yaml" "2.0"} \
    "*spec version*" "unsupported version → throws"
# current and unstamped must NOT throw
assert_eq [catch {spar::assert_supported_version "campaign.yaml" $spar::CURRENT_SPEC_VERSION}] 0 \
    "current version → no throw"
assert_eq [catch {spar::assert_supported_version "campaign.yaml" ""}] 0 \
    "unstamped → no throw (legacy proceeds)"

finish_tests
