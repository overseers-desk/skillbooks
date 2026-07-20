#!/usr/bin/env tclsh9.0
package require yaml
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. lib spar-state.tcl]
source [file join $script_dir test-helpers.tcl]

set State [spar::State new]

# ════════════════════════════════════════════════════════════════════════
# 11. validate_campaign
# ════════════════════════════════════════════════════════════════════════
section "11. validate_campaign"


# 11a. placeholder_to triggered: approach file with to: PLACEHOLDER → one issue
set seg_v1 [make_temp_segment]
write_profile $seg_v1 "v-placeholder"
write_approach_yaml $seg_v1 "v-placeholder" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: PLACEHOLDER
    subject: Test subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_v1 $::std_headers [list \
    [make_base_row {contact_name "Placeholder Pete" email "pete@acme-venues.au" \
        stem "v-placeholder"}] \
]
set cv1 [$State classify_segment $seg_v1]
set issues_v1 [spar::validate_campaign $cv1]
set pt_issues [issues_with_code $issues_v1 placeholder_to]
assert_eq [llength $pt_issues] 1 "placeholder_to: PLACEHOLDER in to: → one issue"

# 11b. placeholder_to not triggered: valid email in to:
set seg_v2 [make_temp_segment]
write_profile $seg_v2 "v-valid-to"
write_approach_yaml $seg_v2 "v-valid-to" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: foo@bar.com
    subject: Test subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_v2 $::std_headers [list \
    [make_base_row {contact_name "Valid Vic" email "foo@bar.com" \
        stem "v-valid-to"}] \
]
set cv2 [$State classify_segment $seg_v2]
set issues_v2 [spar::validate_campaign $cv2]
set pt_issues2 [issues_with_code $issues_v2 placeholder_to]
assert_eq [llength $pt_issues2] 0 "placeholder_to: valid email in to: → zero issues"

# 11c. email_desync triggered: roster email differs from approach to:
set seg_v3 [make_temp_segment]
write_profile $seg_v3 "v-desync"
write_approach_yaml $seg_v3 "v-desync" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: alice@old.com
    subject: Test subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_v3 $::std_headers [list \
    [make_base_row {contact_name "Desync Alice" email "alice@new.com" \
        stem "v-desync"}] \
]
set cv3 [$State classify_segment $seg_v3]
set issues_v3 [spar::validate_campaign $cv3]
set ed_issues [issues_with_code $issues_v3 email_desync]
assert_eq [llength $ed_issues] 1 "email_desync: roster email differs from approach to: → one issue"

# 11d. email_desync not triggered: roster email matches approach to: (case-insensitive)
set seg_v4 [make_temp_segment]
write_profile $seg_v4 "v-sync"
write_approach_yaml $seg_v4 "v-sync" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: Bob@Acme-Venues.AU
    subject: Test subject
    body: Hello there
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_v4 $::std_headers [list \
    [make_base_row {contact_name "Sync Bob" email "bob@acme-venues.au" \
        stem "v-sync"}] \
]
set cv4 [$State classify_segment $seg_v4]
set issues_v4 [spar::validate_campaign $cv4]
set ed_issues2 [issues_with_code $issues_v4 email_desync]
assert_eq [llength $ed_issues2] 0 "email_desync: matching emails (case-insensitive) → zero issues"

# 11e. merged_contact_name triggered: contact_name contains ' & '
set seg_v5 [make_temp_segment]
write_roster_tsv $seg_v5 $::std_headers [list \
    [make_base_row {contact_name "Anthony O'Flynn & Nina Hansen" \
        stem ""}] \
]
set cv5 [$State classify_segment $seg_v5]
set issues_v5 [spar::validate_campaign $cv5]
set mc_issues [issues_with_code $issues_v5 merged_contact_name]
assert_eq [llength $mc_issues] 1 "merged_contact_name: name with ' & ' → one issue"

# 11f. merged_contact_name not triggered: normal contact_name
set seg_v6 [make_temp_segment]
write_roster_tsv $seg_v6 $::std_headers [list \
    [make_base_row {contact_name "Normal Name" \
        stem ""}] \
]
set cv6 [$State classify_segment $seg_v6]
set issues_v6 [spar::validate_campaign $cv6]
set mc_issues2 [issues_with_code $issues_v6 merged_contact_name]
assert_eq [llength $mc_issues2] 0 "merged_contact_name: normal name → zero issues"

# 11g. orphan_profile triggered: .md file in profiles/ not referenced by roster
set seg_v7 [make_temp_segment]
write_profile $seg_v7 "referenced-profile"
write_profile $seg_v7 "orphan-profile"
write_roster_tsv $seg_v7 $::std_headers [list \
    [make_base_row {contact_name "Ref Contact" \
        stem "referenced-profile"}] \
]
set cv7 [$State classify_segment $seg_v7]
set issues_v7 [spar::validate_campaign $cv7]
set op_issues [issues_with_code $issues_v7 orphan_profile]
assert_eq [llength $op_issues] 1 "orphan_profile: unreferenced .md file → one issue"

# 11h. orphan_profile not triggered: all .md files referenced
set seg_v8 [make_temp_segment]
write_profile $seg_v8 "used-profile"
write_roster_tsv $seg_v8 $::std_headers [list \
    [make_base_row {contact_name "Used Contact" \
        stem "used-profile"}] \
]
set cv8 [$State classify_segment $seg_v8]
set issues_v8 [spar::validate_campaign $cv8]
set op_issues2 [issues_with_code $issues_v8 orphan_profile]
assert_eq [llength $op_issues2] 0 "orphan_profile: all .md files referenced → zero issues"

# 11i. orphan_approach triggered: .yaml file in approach/ not referenced by roster
set seg_v9 [make_temp_segment]
write_profile $seg_v9 "ref-approach-contact"
write_approach_yaml $seg_v9 "ref-approach-contact" [approach_yaml_final_unsent]
write_approach_yaml $seg_v9 "orphan-approach" [approach_yaml_final_unsent]
write_roster_tsv $seg_v9 $::std_headers [list \
    [make_base_row {contact_name "Ref Approach" \
        stem "ref-approach-contact"}] \
]
set cv9 [$State classify_segment $seg_v9]
set issues_v9 [spar::validate_campaign $cv9]
set oa_issues [issues_with_code $issues_v9 orphan_approach]
assert_eq [llength $oa_issues] 1 "orphan_approach: unreferenced .yaml file → one issue"

# 11j. orphan_approach not triggered: all .yaml files referenced
set seg_v10 [make_temp_segment]
write_profile $seg_v10 "used-approach-contact"
write_approach_yaml $seg_v10 "used-approach-contact" [approach_yaml_final_unsent]
write_roster_tsv $seg_v10 $::std_headers [list \
    [make_base_row {contact_name "Used Approach" \
        stem "used-approach-contact"}] \
]
set cv10 [$State classify_segment $seg_v10]
set issues_v10 [spar::validate_campaign $cv10]
set oa_issues2 [issues_with_code $issues_v10 orphan_approach]
assert_eq [llength $oa_issues2] 0 "orphan_approach: all .yaml files referenced → zero issues"


finish_tests
