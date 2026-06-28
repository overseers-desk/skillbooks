#!/usr/bin/env tclsh9.0
package require yaml
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir .. spar-state.tcl]
source [file join $script_dir .. spar-email.tcl]
source [file join $script_dir test-helpers.tcl]

set State [spar::State new]

# ════════════════════════════════════════════════════════════════════════
# 12. validate_approach (per-file guard rail)
# ════════════════════════════════════════════════════════════════════════
section "validate_approach"

# 12a. Valid email in to: field → no errors
set seg_va1 [make_temp_segment]
set va1_path [write_approach_yaml $seg_va1 "va-valid" [approach_yaml_final_unsent]]
set va1_issues [spar::validate_approach $va1_path "test@acme-venues.au" "Test Contact"]
assert_eq [llength $va1_issues] 0 "validate_approach: valid email → no issues"

# 12a-bis. Engagement root keys response_likelihood / a_note / r_note are
# canonical at root (the campaign-bound A/R outputs now live in the approach
# YAML, not the roster) → no unknown_key_root / wrong_level errors.
set seg_va1b [make_temp_segment]
set va1b_path [write_approach_yaml $seg_va1b "va-engagement" {decisions:
  channel: email
angle_rationale: Why this angle fits.
response_likelihood: 75
a_note: shared-venue angle; email; warm; en
r_note: ""
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test subject
    body: Hello there
    actioned_date: null
    replied_date: null
}]
set va1b_issues [spar::validate_approach $va1b_path "test@acme-venues.au" "Test Contact"]
set va1b_unknown [lsearch -all -inline -glob [lmap i $va1b_issues {dict get $i code}] "unknown_key*"]
set va1b_wrong   [lsearch -all -inline [lmap i $va1b_issues {dict get $i code}] "wrong_level"]
assert_eq [llength $va1b_unknown] 0 "validate_approach: response_likelihood/a_note/r_note → no unknown_key_root"
assert_eq [llength $va1b_wrong] 0 "validate_approach: engagement root keys → no wrong_level"

# 12b. Placeholder to: field → placeholder_to error
set seg_va2 [make_temp_segment]
set va2_path [write_approach_yaml $seg_va2 "va-placeholder" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: PLACEHOLDER
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va2_issues [spar::validate_approach $va2_path "real@acme-venues.au" "VA Placeholder"]
set va2_errors [issues_with_code $va2_issues placeholder_to]
assert_eq [llength $va2_errors] 1 "validate_approach: placeholder to: → placeholder_to error"
assert_eq [dict get [lindex $va2_errors 0] severity] "error" "validate_approach: placeholder_to severity is error"

# 12b2. Syntactically-valid placeholder domain (RFC 2606) → placeholder_to error
set seg_va2b [make_temp_segment]
set va2b_path [write_approach_yaml $seg_va2b "va-rfc-placeholder" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: recipient@example.com
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va2b_issues [spar::validate_approach $va2b_path "recipient@example.com" "VA RFC Placeholder"]
set va2b_errors [issues_with_code $va2b_issues placeholder_to]
assert_eq [llength $va2b_errors] 1 "validate_approach: @example.com to: → placeholder_to error"

# 12b3. Stub local-part (e.g. todo@real.com) → placeholder_to error
set seg_va2c [make_temp_segment]
set va2c_path [write_approach_yaml $seg_va2c "va-stub-local" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: todo@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va2c_issues [spar::validate_approach $va2c_path "todo@acme-venues.au" "VA Stub Local"]
set va2c_errors [issues_with_code $va2c_issues placeholder_to]
assert_eq [llength $va2c_errors] 1 "validate_approach: stub local-part → placeholder_to error"

# 12c. to: differs from roster email → email_desync warning
set seg_va3 [make_temp_segment]
set va3_path [write_approach_yaml $seg_va3 "va-desync" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: wrong@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va3_issues [spar::validate_approach $va3_path "correct@acme-venues.au" "VA Desync"]
set va3_warnings [issues_with_code $va3_issues email_desync]
assert_eq [llength $va3_warnings] 1 "validate_approach: to: differs from roster email → email_desync warning"
assert_eq [dict get [lindex $va3_warnings 0] severity] "warning" "validate_approach: email_desync severity is warning"

# 12d. No final round → structural error (no_final_round)
set seg_va4 [make_temp_segment]
set va4_path [write_approach_yaml $seg_va4 "va-nofinal" [approach_yaml_no_final]]
set va4_issues [spar::validate_approach $va4_path "test@acme-venues.au" "Test Contact"]
assert_eq [has_issue $va4_issues no_final_round] 1 "validate_approach: no final round → no_final_round error"

# 12d1. profile_hash matches profile bytes → no issue (issue #63)
set seg_va_ph_ok [make_temp_segment]
write_profile $seg_va_ph_ok "va-ph-ok"
set _ph_ok_profile [file join $seg_va_ph_ok profiles "va-ph-ok.md"]
set _ph_ok_hex [string tolower [::sha2::sha256 -hex -file $_ph_ok_profile]]
set va_ph_ok_path [write_approach_yaml $seg_va_ph_ok "va-ph-ok" "profile_hash: sha256:$_ph_ok_hex
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
"]
set va_ph_ok_issues [spar::validate_approach $va_ph_ok_path "test@acme-venues.au" "VA PH OK" "Some Org"]
assert_eq [has_issue $va_ph_ok_issues profile_hash_mismatch] 0 \
    "validate_approach: profile_hash matches profile bytes → no profile_hash_mismatch"

# 12d2. profile_hash differs from profile bytes → profile_hash_mismatch error
set seg_va_ph_bad [make_temp_segment]
write_profile $seg_va_ph_bad "va-ph-bad"
set va_ph_bad_path [write_approach_yaml $seg_va_ph_bad "va-ph-bad" {profile_hash: sha256:0000000000000000000000000000000000000000000000000000000000000000
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va_ph_bad_issues [spar::validate_approach $va_ph_bad_path "test@acme-venues.au" "VA PH BAD" "Some Org"]
set va_ph_bad_errors [issues_with_code $va_ph_bad_issues profile_hash_mismatch]
assert_eq [llength $va_ph_bad_errors] 1 \
    "validate_approach: profile_hash diverges from profile bytes → profile_hash_mismatch error"
assert_eq [dict get [lindex $va_ph_bad_errors 0] severity] "error" \
    "validate_approach: profile_hash_mismatch severity is error"

# 12d3. Approach without profile_hash → no issue (optional field)
set seg_va_ph_none [make_temp_segment]
write_profile $seg_va_ph_none "va-ph-none"
set va_ph_none_path [write_approach_yaml $seg_va_ph_none "va-ph-none" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va_ph_none_issues [spar::validate_approach $va_ph_none_path "test@acme-venues.au" "VA PH NONE" "Some Org"]
assert_eq [has_issue $va_ph_none_issues profile_hash_mismatch] 0 \
    "validate_approach: no profile_hash → no profile_hash_mismatch (optional)"

# 12d4. Approach with profile_hash but profile file absent → no error
# (state machine routes via T3 → T4; validator does not block).
set seg_va_ph_abs [make_temp_segment]
set va_ph_abs_path [write_approach_yaml $seg_va_ph_abs "va-ph-abs" {profile_hash: sha256:1111111111111111111111111111111111111111111111111111111111111111
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va_ph_abs_issues [spar::validate_approach $va_ph_abs_path "test@acme-venues.au" "VA PH ABS" "Some Org"]
assert_eq [has_issue $va_ph_abs_issues profile_hash_mismatch] 0 \
    "validate_approach: profile_hash with absent profile → no error (state machine handles)"

# 12d5. profile_hash present but not on the first line → profile_hash_misplaced.
# The position discipline (#63) reserves a fast-classify path that reads only
# line 1; drift would silently break it, so the validator catches misplacement
# even when the hash itself matches the profile bytes.
set seg_va_ph_pos [make_temp_segment]
write_profile $seg_va_ph_pos "va-ph-pos"
set _ph_pos_hex [string tolower [::sha2::sha256 -hex -file [file join $seg_va_ph_pos profiles "va-ph-pos.md"]]]
set va_ph_pos_path [write_approach_yaml $seg_va_ph_pos "va-ph-pos" "decisions:
  channel: email
profile_hash: sha256:$_ph_pos_hex
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
"]
set va_ph_pos_issues [spar::validate_approach $va_ph_pos_path "test@acme-venues.au" "VA PH POS" "Some Org"]
set va_ph_pos_errors [issues_with_code $va_ph_pos_issues profile_hash_misplaced]
assert_eq [llength $va_ph_pos_errors] 1 \
    "validate_approach: profile_hash not on line 1 → profile_hash_misplaced error"
assert_eq [dict get [lindex $va_ph_pos_errors 0] severity] "error" \
    "validate_approach: profile_hash_misplaced severity is error"

# 12d6. profile_hash absent → no profile_hash_misplaced (the rule only fires
# when the file declares a hash; legacy/manual files without one are clean).
set seg_va_ph_none2 [make_temp_segment]
write_profile $seg_va_ph_none2 "va-ph-none2"
set va_ph_none2_path [write_approach_yaml $seg_va_ph_none2 "va-ph-none2" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}]
set va_ph_none2_issues [spar::validate_approach $va_ph_none2_path "test@acme-venues.au" "VA PH NONE2" "Some Org"]
assert_eq [has_issue $va_ph_none2_issues profile_hash_misplaced] 0 \
    "validate_approach: no profile_hash → no profile_hash_misplaced (rule scoped to declared hashes)"

# 12e. Nonexistent file → no errors (graceful)
set va5_issues [spar::validate_approach "/tmp/nonexistent-approach.yaml" "test@acme-venues.au" "VA Missing"]
assert_eq [llength $va5_issues] 0 "validate_approach: nonexistent file → no issues"

# 12e2. Unknown key inside script_item is reported when the validator
# operates on the projection from approach_summary (Phase B field-set
# audit). project_approach_data preserves script_item key skeleton —
# only `text` is blanked, other keys (canonical or unknown) flow
# through — so _check_unknown_keys at script_item level still rejects
# drift. Without this preservation, a typo'd script_item key would slip
# silently past the render-path validator.
set seg_va_si [make_temp_segment]
write_profile $seg_va_si "va-si-unknown"
set _va_si_ppath [file join $seg_va_si profiles "va-si-unknown.md"]
set _va_si_hash [::sha2::sha256 -hex -file $_va_si_ppath]
set va_si_path [write_approach_yaml $seg_va_si "va-si-unknown" \
"profile_hash: sha256:$_va_si_hash
decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: test@acme-venues.au
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
    script:
    - point: opener
      text: Hi there
      bogus_field: should_be_rejected
"]
write_roster_tsv $seg_va_si $::std_headers [list \
    [make_base_row {contact_name "Script Drift" email "test@acme-venues.au" \
        stem "va-si-unknown"}]]
set cv_va_si [$State classify_segment $seg_va_si]
set _va_si_contact ""
foreach _c $cv_va_si {
    if {[dict get $_c stem] eq "va-si-unknown"} { set _va_si_contact $_c; break }
}
# Render-path: drive validation through the projection (approach_summary
# → validate_approach_data) the way T6/T7/T9/T10 do via
# approach_validation_error.
set _va_si_proj [$State approach_summary $_va_si_contact]
set _va_si_issues [spar::validate_approach_data $_va_si_proj $va_si_path \
    "test@acme-venues.au" "Script Drift" "Some Org"]
set _va_si_unknown [issues_with_code $_va_si_issues unknown_key_script_item]
assert_eq [llength $_va_si_unknown] 1 \
    "validate_approach_data via projection: unknown key 'bogus_field' in script_item → unknown_key_script_item"
assert_eq [dict get [lindex $_va_si_unknown 0] severity] "error" \
    "validate_approach_data via projection: unknown_key_script_item severity is error"

# 12f. validate_campaign still produces same results via delegation
# Reuse seg_va2 (placeholder) through classify_segment path
set seg_va6 [make_temp_segment]
write_profile $seg_va6 "va-campaign-check"
write_approach_yaml $seg_va6 "va-campaign-check" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    to: PLACEHOLDER_EMAIL
    subject: Test
    body: Hello
    actioned_date: null
    replied_date: null
}
write_roster_tsv $seg_va6 $::std_headers [list \
    [make_base_row {contact_name "Campaign Check" email "real@acme-venues.au" \
        stem "va-campaign-check"}] \
]
set cv_va6 [$State classify_segment $seg_va6]
set issues_va6 [spar::validate_campaign $cv_va6]
set pt_va6 [issues_with_code $issues_va6 placeholder_to]
assert_eq [llength $pt_va6] 1 "validate_campaign: still detects placeholder_to via validate_approach delegation"

# ════════════════════════════════════════════════════════════════════════
# 12p. validate_profile (per-file front-matter check, #45)
# ════════════════════════════════════════════════════════════════════════
section "validate_profile"

# 12p-a. Valid front matter → no errors
set seg_vp1 [make_temp_segment]
set vp1_path [write_profile $seg_vp1 "vp-valid"]
set vp1_row [make_base_row {stem "vp-valid"}]
set vp1_issues [spar::validate_profile $vp1_path $vp1_row "VP Valid"]
assert_eq [llength $vp1_issues] 0 "validate_profile: valid front matter → no issues"

# 12p-b. Missing fences → invalid_front_matter error
set seg_vp2 [make_temp_segment]
set vp2_path [write_profile_raw $seg_vp2 "vp-nofm" "# Profile\n\nNo front matter here.\n"]
set vp2_issues [spar::validate_profile $vp2_path [make_base_row] "VP NoFM"]
assert_eq [has_issue $vp2_issues invalid_front_matter] 1 "validate_profile: missing fences → invalid_front_matter"

# 12p-c. Unparseable YAML in front matter → invalid_front_matter error
# Use a structure YAML cannot parse: mismatched indentation with a block seq inside a mapping.
set seg_vp3 [make_temp_segment]
set vp3_path [write_profile_raw $seg_vp3 "vp-badyaml" "---\nkey: value\n  - broken\n \tmixed indent with tab\n---\nbody"]
set vp3_issues [spar::validate_profile $vp3_path [make_base_row] "VP BadYAML"]
assert_eq [has_issue $vp3_issues invalid_front_matter] 1 "validate_profile: unparseable YAML → invalid_front_matter"

# 12p-d. Unknown top-level key → unknown_key_root error
set seg_vp4 [make_temp_segment]
set vp4_path [write_profile_raw $seg_vp4 "vp-unknown" "---\nprofile_date: 2026-04-12\nstar_rating: 3\nyield: 2\nwarmth_finding: cold\napplicable_angles:\n  - foo\ndependent_data: {}\nrogue_key: oops\n---\nbody"]
set vp4_issues [spar::validate_profile $vp4_path [make_base_row] "VP Unknown"]
assert_eq [has_issue $vp4_issues unknown_key_root] 1 "validate_profile: unknown root key → unknown_key_root"

# 12p-e. invalid_yield — non-integer value
set seg_vp5 [make_temp_segment]
set vp5_path [write_profile $seg_vp5 "vp-yield" -yield "sparkly"]
set vp5_issues [spar::validate_profile $vp5_path [make_base_row] "VP Yield"]
assert_eq [has_issue $vp5_issues invalid_yield] 1 "validate_profile: yield 'sparkly' → invalid_yield"

# 12p-f. invalid_warmth_finding
set seg_vp6 [make_temp_segment]
set vp6_path [write_profile $seg_vp6 "vp-warm" -warmth_finding "lukewarm"]
set vp6_issues [spar::validate_profile $vp6_path [make_base_row] "VP Warmth"]
assert_eq [has_issue $vp6_issues invalid_warmth_finding] 1 "validate_profile: warmth_finding 'lukewarm' → invalid_warmth_finding"

# 12p-g. invalid_star_rating (0 must not appear)
set seg_vp7 [make_temp_segment]
set vp7_path [write_profile $seg_vp7 "vp-star0" -star_rating 0]
set vp7_issues [spar::validate_profile $vp7_path [make_base_row] "VP Star0"]
assert_eq [has_issue $vp7_issues invalid_star_rating] 1 "validate_profile: star_rating 0 → invalid_star_rating"

# 12p-h. Missing required key (yield omitted)
set seg_vp8 [make_temp_segment]
set vp8_path [write_profile_raw $seg_vp8 "vp-miss" "---\nprofile_date: 2026-04-12\nstar_rating: 3\nwarmth_finding: cold\napplicable_angles:\n  - foo\ndependent_data: {}\n---\nbody"]
set vp8_issues [spar::validate_profile $vp8_path [make_base_row] "VP Missing"]
assert_eq [has_issue $vp8_issues missing_yield] 1 "validate_profile: missing yield → missing_yield"

# 12p-i. Staleness — snapshot contact_name differs from roster
set seg_vp9 [make_temp_segment]
set vp9_path [write_profile $seg_vp9 "vp-stale-name" \
    -contact_name "Old Name" -organisation "SomeOrg" -role "SomeRole" -date_excluded null]
set vp9_row [dict create stem "vp-stale-name" contact_name "New Name" \
    organisation "SomeOrg" role "SomeRole" date_excluded ""]
set vp9_issues [spar::validate_profile $vp9_path $vp9_row "VP StaleName"]
assert_eq [has_issue $vp9_issues stale_contact_name] 1 "validate_profile: contact_name drift → stale_contact_name"

# 12p-j. Staleness — date_excluded asymmetric: date → empty = stale
set seg_vp10 [make_temp_segment]
set vp10_path [write_profile $seg_vp10 "vp-stale-date" \
    -contact_name "Same" -organisation "Same" -role "Same" -date_excluded 2026-01-01]
set vp10_row [dict create stem "vp-stale-date" contact_name "Same" \
    organisation "Same" role "Same" date_excluded ""]
set vp10_issues [spar::validate_profile $vp10_path $vp10_row "VP StaleDate"]
assert_eq [has_issue $vp10_issues stale_date_excluded] 1 \
    "validate_profile: snapshot date_excluded set, current empty → stale_date_excluded"

# 12p-k. Staleness — date_excluded asymmetric: empty → date = NOT stale (EXCLUDED supersedes)
set seg_vp11 [make_temp_segment]
set vp11_path [write_profile $seg_vp11 "vp-not-stale" \
    -contact_name "Same" -organisation "Same" -role "Same" -date_excluded null]
set vp11_row [dict create stem "vp-not-stale" contact_name "Same" \
    organisation "Same" role "Same" date_excluded "2026-04-10"]
set vp11_issues [spar::validate_profile $vp11_path $vp11_row "VP NotStale"]
assert_eq [has_issue $vp11_issues stale_date_excluded] 0 \
    "validate_profile: snapshot empty, current has date → NOT stale (reverse direction)"

# 12p-l. Nonexistent file → no issues (graceful, mirrors validate_approach)
set vp12_issues [spar::validate_profile "/tmp/nonexistent-profile.md" [make_base_row] "VP Missing"]
assert_eq [llength $vp12_issues] 0 "validate_profile: nonexistent file → no issues"

# 12p-m. PROFILE_STALE classification via classify_contact
set seg_vp13 [make_temp_segment]
write_profile $seg_vp13 "vp-classify-stale" \
    -contact_name "Was Called This" -organisation "Same Org" -role "Same Role"
set vp13_roster [list stem contact_name organisation role date_excluded email]
set vp13_tsv [file join $seg_vp13 roster.tsv]
set fd [open $vp13_tsv w]
puts $fd [join $vp13_roster \t]
puts $fd [join [list "vp-classify-stale" "Is Called This Now" "Same Org" "Same Role" "" "x@y.com"] \t]
close $fd
set vp13_contacts [$State classify_segment $seg_vp13]
set vp13_state [dict get [lindex $vp13_contacts 0] state]
assert_eq $vp13_state "PROFILE_STALE" "classify_contact: snapshot ≠ roster → PROFILE_STALE"

# 12p-n. PROFILE_STALE appears as T3 transition target
set vp13_t3 [$State transition_eligible $vp13_contacts "T3"]
set vp13_t3_names [lmap c $vp13_t3 {dict get $c contact_name}]
assert_eq [expr {"Is Called This Now" in $vp13_t3_names}] 1 \
    "T3: PROFILE_STALE contact is eligible for re-profile"

# 12p-o. validate_campaign integration: staleness warning flows through
set vp14_issues [spar::validate_campaign $vp13_contacts]
assert_eq [has_issue $vp14_issues stale_contact_name] 1 \
    "validate_campaign: profile staleness surfaces through include_profile path"

# 12p-p. validate_campaign_semantics skips include_profile (progress-only path)
set vp14_sem [spar::validate_campaign_semantics $vp13_contacts]
assert_eq [has_issue $vp14_sem stale_contact_name] 0 \
    "validate_campaign_semantics: skips profile checks (include_profile=0)"

# 12p-q. #39 R1: profile exists but no channels and no date_excluded → error
set seg_vp15 [make_temp_segment]
set vp15_path [write_profile $seg_vp15 "vp-unreachable"]
set vp15_row [dict create stem "vp-unreachable" contact_name "X" organisation "Y" \
    role "Z" email "" linkedin_url "" facebook_url "" phone "" date_excluded ""]
set vp15_issues [spar::validate_profile $vp15_path $vp15_row "VP Unreachable"]
assert_eq [has_issue $vp15_issues profile_unreachable_without_exclusion] 1 \
    "validate_profile: profile + all channels empty + no date_excluded → profile_unreachable_without_exclusion"

# 12p-r. #39 R1: date_excluded set → no error (P honoured §4.15)
set seg_vp16 [make_temp_segment]
set vp16_path [write_profile $seg_vp16 "vp-excluded" -date_excluded "2026-04-12"]
set vp16_row [dict create stem "vp-excluded" contact_name "X" organisation "Y" \
    role "Z" email "" linkedin_url "" facebook_url "" phone "" date_excluded "2026-04-12"]
set vp16_issues [spar::validate_profile $vp16_path $vp16_row "VP Excluded"]
assert_eq [has_issue $vp16_issues profile_unreachable_without_exclusion] 0 \
    "validate_profile: all channels empty but date_excluded set → no R1 error"

# 12p-s. #39 R1: phone-only contact is reachable (phone path per §4.15)
set seg_vp17 [make_temp_segment]
set vp17_path [write_profile $seg_vp17 "vp-phoneonly"]
set vp17_row [dict create stem "vp-phoneonly" contact_name "X" organisation "Y" \
    role "Z" email "" linkedin_url "" facebook_url "" phone "0400000000" date_excluded ""]
set vp17_issues [spar::validate_profile $vp17_path $vp17_row "VP PhoneOnly"]
assert_eq [has_issue $vp17_issues profile_unreachable_without_exclusion] 0 \
    "validate_profile: phone-only contact → no R1 error"

# 12p-t. #39 R1: one channel present → no error
set seg_vp18 [make_temp_segment]
set vp18_path [write_profile $seg_vp18 "vp-haslinkedin"]
set vp18_row [dict create stem "vp-haslinkedin" contact_name "X" organisation "Y" \
    role "Z" email "" linkedin_url "https://linkedin.com/in/x" facebook_url "" \
    phone "" date_excluded ""]
set vp18_issues [spar::validate_profile $vp18_path $vp18_row "VP HasLinkedIn"]
assert_eq [has_issue $vp18_issues profile_unreachable_without_exclusion] 0 \
    "validate_profile: LinkedIn present → no R1 error"

# 12p-u. #39 R1: empty roster_row (orphan) → no R1 error (orphan is separate check)
set seg_vp19 [make_temp_segment]
set vp19_path [write_profile $seg_vp19 "vp-orphan"]
set vp19_issues [spar::validate_profile $vp19_path [dict create] "VP Orphan"]
assert_eq [has_issue $vp19_issues profile_unreachable_without_exclusion] 0 \
    "validate_profile: empty roster_row → no R1 error (orphan check is separate)"

# ════════════════════════════════════════════════════════════════════════
# 25. spar::build_reply_headers — reply header derivation (issue #79)
# ════════════════════════════════════════════════════════════════════════
section "25. spar::build_reply_headers — reply header derivation"

# Parent dict captured at A-time from `mailroom read`.
set brh_parent_root [dict create \
    account admin-rivermill-au \
    folder {[Gmail]/All Mail} \
    uid 34937 \
    message_id "<root@example.com>" \
    references {} \
    subject "Requirement of Chef" \
    from "Andrew Kerby <andrew@chefsontherun.example>" \
    to {director@rivermill.au} \
    cc {}]

# 25a. Plain reply (not reply-all) — To = parent.from; Cc empty.
set brh1 [spar::build_reply_headers $brh_parent_root director@rivermill.au 0]
assert_eq [dict get $brh1 to] "andrew@chefsontherun.example" \
    "build_reply_headers: To derived from parent.from (email-only)"
assert_eq [dict get $brh1 cc] "" \
    "build_reply_headers: Cc empty when reply_all=0"
assert_eq [dict get $brh1 subject] "Re: Requirement of Chef" \
    "build_reply_headers: Subject prepends Re:"
assert_eq [dict get $brh1 in_reply_to] "<root@example.com>" \
    "build_reply_headers: In-Reply-To = parent.message_id"
assert_eq [dict get $brh1 references] "<root@example.com>" \
    "build_reply_headers: References = parent.message_id alone for thread root"

# 25b. Reply-all — Cc preserves the rest of the recipient set, minus sender.
set brh_parent_multi [dict create \
    message_id "<thread2@example.com>" \
    references {<root2@example.com>} \
    subject "demi-chef" \
    from "Tania Flint <tania@chefsontherun.example>" \
    to {director@rivermill.au, ops@chefsontherun.example} \
    cc {colleague@rivermill.au}]
set brh2 [spar::build_reply_headers $brh_parent_multi director@rivermill.au 1]
assert_eq [dict get $brh2 to] "tania@chefsontherun.example" \
    "build_reply_headers: reply-all keeps To = parent.from"
# Cc is comma+space-joined; sender (director@rivermill.au) and the new To
# (tania@chefsontherun.example) are excluded.
assert_match [dict get $brh2 cc] "*ops@chefsontherun.example*" \
    "build_reply_headers: reply-all Cc keeps original other recipients"
assert_match [dict get $brh2 cc] "*colleague@rivermill.au*" \
    "build_reply_headers: reply-all Cc keeps original Cc"
assert_eq [string match "*director@rivermill.au*" [dict get $brh2 cc]] 0 \
    "build_reply_headers: reply-all Cc excludes the sender's own address"

# 25c. References chain — append parent.message_id to existing chain.
assert_eq [dict get $brh2 references] "<root2@example.com> <thread2@example.com>" \
    "build_reply_headers: References = chain + parent.message_id"

# 25d. Re: dedup — parent already starts with Re: → don't double-prefix.
set brh_parent_re [dict create \
    message_id "<m@x>" \
    subject "RE: Requirement of Chef" \
    from "andrew@example.com" \
    references {}]
set brh3 [spar::build_reply_headers $brh_parent_re director@rivermill.au 0]
assert_eq [dict get $brh3 subject] "RE: Requirement of Chef" \
    "build_reply_headers: Subject preserves existing Re: prefix (no double Re:)"

# 25e. Re[2]: dedup — bracketed counter form is also a Re prefix.
set brh_parent_re2 [dict create \
    message_id "<m@x>" \
    subject "Re\[2\]: Requirement of Chef" \
    from "andrew@example.com" \
    references {}]
set brh4 [spar::build_reply_headers $brh_parent_re2 director@rivermill.au 0]
assert_eq [dict get $brh4 subject] "Re\[2\]: Requirement of Chef" \
    "build_reply_headers: Subject preserves Re\[N\]: prefix"

# 25f. parent.references already ends with parent.message_id → don't duplicate.
set brh_parent_dup [dict create \
    message_id "<m@x>" \
    references {<a@x> <m@x>} \
    subject "X" \
    from "a@b.com"]
set brh5 [spar::build_reply_headers $brh_parent_dup director@rivermill.au 0]
assert_eq [dict get $brh5 references] "<a@x> <m@x>" \
    "build_reply_headers: References does not duplicate parent.message_id"

# ════════════════════════════════════════════════════════════════════════
# 26. validate_approach — reply-mode messages (issue #79)
# ════════════════════════════════════════════════════════════════════════
section "26. validate_approach — reply-mode messages"

proc issues_with_severity {issues sev} {
    set result {}
    foreach issue $issues { if {[dict get $issue severity] eq $sev} { lappend result $issue } }
    return $result
}

# 26a. mode: reply with complete parent block → no errors.
set seg_rv1 [make_temp_segment]
set rv1_path [write_approach_yaml $seg_rv1 "rv-reply-ok" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    mode: reply
    reply_all: false
    body: Following up on the Chef requirement we discussed.
    actioned_date: null
    replied_date: null
    parent:
      account: admin-rivermill-au
      folder: "[Gmail]/All Mail"
      uid: 34937
      message_id: "<root@example.com>"
      subject: Requirement of Chef
      from: Andrew Kerby <andrew@example.com>
}]
set rv1_issues [spar::validate_approach $rv1_path "andrew@example.com" "Test Contact"]
# Reply mode: To/Subject/desync checks don't apply (To is derived). Only
# structural and reply-specific gates run.
set rv1_errors [issues_with_severity $rv1_issues error]
assert_eq [llength $rv1_errors] 0 \
    "validate_approach: reply mode with full parent block → no errors"

# 26b. Subject may be omitted from the message under mode: reply.
set seg_rv2 [make_temp_segment]
set rv2_path [write_approach_yaml $seg_rv2 "rv-reply-no-subject" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    mode: reply
    body: Continuing the thread.
    parent:
      message_id: "<root@example.com>"
      subject: Original
      from: andrew@example.com
}]
set rv2_issues [spar::validate_approach $rv2_path "andrew@example.com" "Test Contact"]
set rv2_missing [issues_with_code $rv2_issues email_missing_content]
assert_eq [llength $rv2_missing] 0 \
    "validate_approach: reply mode without subject → no email_missing_content"

# 26c. mode: reply but no body → email_missing_content (body still required).
set seg_rv3 [make_temp_segment]
set rv3_path [write_approach_yaml $seg_rv3 "rv-reply-no-body" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    mode: reply
    parent:
      message_id: "<root@example.com>"
      subject: Original
      from: andrew@example.com
}]
set rv3_issues [spar::validate_approach $rv3_path "andrew@example.com" "Test Contact"]
set rv3_missing [issues_with_code $rv3_issues email_missing_content]
assert_eq [llength $rv3_missing] 1 \
    "validate_approach: reply mode without body → email_missing_content"

# 26d. mode: reply but parent.message_id missing → reply_missing_parent_message_id.
set seg_rv4 [make_temp_segment]
set rv4_path [write_approach_yaml $seg_rv4 "rv-reply-no-mid" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    mode: reply
    body: text
    parent:
      account: a
      folder: f
      uid: 1
      subject: x
      from: andrew@example.com
}]
set rv4_issues [spar::validate_approach $rv4_path "andrew@example.com" "Test Contact"]
set rv4_errors [issues_with_code $rv4_issues reply_missing_parent_message_id]
assert_eq [llength $rv4_errors] 1 \
    "validate_approach: reply with no parent.message_id → reply_missing_parent_message_id"

# 26e. parent block with unknown key → unknown_key_parent.
set seg_rv5 [make_temp_segment]
set rv5_path [write_approach_yaml $seg_rv5 "rv-reply-unknown" {decisions:
  channel: email
rounds:
- type: final
  number: 1
  messages:
  - channel: email
    mode: reply
    body: text
    parent:
      message_id: "<root@example.com>"
      subject: x
      from: andrew@example.com
      bogus_key: nope
}]
set rv5_issues [spar::validate_approach $rv5_path "andrew@example.com" "Test Contact"]
set rv5_unknown [issues_with_code $rv5_issues unknown_key_parent]
assert_eq [llength $rv5_unknown] 1 \
    "validate_approach: parent with unknown key → unknown_key_parent"


finish_tests
