#!/usr/bin/env tclsh9.0
# spar-state.tcl — State machine library for SPAR campaign manager
# Pure read-only library: reads filesystem and TSV, returns current state.
# Sourced by both wish (GUI) and tclsh (CLI).

source [file join [file dirname [file normalize [info script]]] spar-lib.tcl]

namespace eval spar {
    namespace export classify_contact classify_segment \
        transition_eligible detect_duplicates progress_counts \
        roster_counts \
        validate_campaign validate_campaign_semantics validate_approach \
        validate_profile read_profile_front_matter build_warnings \
        final_email_message \
        has_transition_runner transition_runner

    # T-id → runner proc name. Authored here alongside transition_eligible
    # because the routing fact is the same kind as the eligibility fact:
    # "what does this T-id mean, and who handles it." Absent entries mean
    # the T-id is unwired — has_transition_runner returns 0, callers skip.
    # Consumed by spar-transitions.tcl, spar-ui.tcl, and (per #54) the
    # orchestrator library unchanged.
    variable transition_runners [dict create \
        T1 ::spar::p::run \
        T6 ::spar::p::run \
        T2 ::spar::a::run \
        T7 ::spar::a::run]
}

# has_transition_runner -- 1 if the T-id has a wired runner, else 0.
proc spar::has_transition_runner {tid} {
    variable transition_runners
    return [dict exists $transition_runners $tid]
}

# transition_runner -- proc name that handles the given T-id.
# Errors if the T-id is unwired — callers should gate via has_transition_runner.
proc spar::transition_runner {tid} {
    variable transition_runners
    if {![dict exists $transition_runners $tid]} {
        error "no runner for $tid"
    }
    return [dict get $transition_runners $tid]
}

# is_masked_email — return 1 if email looks redacted (contains '*').
# No legitimate email address contains '*'.  Used by validate_campaign
# (reporting) and the P-stage post-profile guardrail (blanking).
proc spar::is_masked_email {email} {
    return [expr {$email ne "" && [string first "*" $email] >= 0}]
}

# parse_star — extract integer star rating from a roster field.
# "5" → 5, "3+" → 3, "" → 0, non-numeric → 0.
proc spar::parse_star {val} {
    set val [string trim $val]
    if {$val eq ""} {
        return 0
    }
    if {[regexp {^(\d+)} $val -> num]} {
        return [expr {int($num)}]
    }
    return 0
}

# normalise_name — lowercase, strip parentheticals, collapse whitespace.
# Tcl port of spar_lib.py normalise_name().
proc spar::normalise_name {s} {
    set s [string tolower $s]
    # Strip parenthetical content
    regsub -all {\([^)]*\)} $s {} s
    # Replace separators (slash, ampersand, dashes) with space
    regsub -all {[/&\u2014\u2013-]+} $s { } s
    # Collapse whitespace
    regsub -all {\s+} $s { } s
    return [string trim $s]
}

# read_approach_yaml — safely read and parse an approach YAML file.
# Returns parsed dict, or empty string on failure.
proc spar::read_approach_yaml {path} {
    if {![file exists $path]} {
        return ""
    }
    set fd {}
    if {[catch {
        set fd [open $path r]
        fconfigure $fd -encoding utf-8
        set raw [read $fd]
        close $fd
        set fd {}
        set data [::yaml::yaml2dict $raw]
    } err]} {
        if {$fd ne ""} {
            catch {close $fd}
        }
        return ""
    }
    return $data
}

# final_email_message — return the sole final-round email message dict, or ""
# if the final round has no email message. Callers rely on the ≤1 invariant
# enforced by validate_approach (too_many_final_emails). If multiple are
# present (validator bypass or malformed file), returns the first to fail
# safe rather than silently mis-targeting a send.
proc spar::final_email_message {data} {
    if {$data eq "" || ![dict exists $data rounds]} { return "" }
    foreach round [dict get $data rounds] {
        if {![dict exists $round type]} continue
        if {[dict get $round type] ne "final"} continue
        if {![dict exists $round messages]} { return "" }
        foreach msg [dict get $round messages] {
            if {[spar::dict_get_default $msg channel ""] eq "email"} {
                return $msg
            }
        }
        return ""
    }
    return ""
}

# analyse_final_round — extract state and channel properties from approach YAML data.
# Returns dict with keys: has_final, any_sent, email_sent, linkedin_sent,
#   email_replied, to_addresses, unsent_subjects, messages.
# `messages` is a list of per-message dicts {channel actioned_date replied_date
#   is_actioned is_replied} used by T9/T10 channel-readiness evaluation.
proc spar::analyse_final_round {data} {
    set result [dict create \
        has_final 0 \
        any_sent 0 \
        email_sent 0 \
        linkedin_sent 0 \
        email_replied 0 \
        to_addresses {} \
        unsent_subjects {} \
        messages {}]

    if {$data eq "" || ![dict exists $data rounds]} {
        return $result
    }

    set rounds [dict get $data rounds]
    foreach round $rounds {
        if {![dict exists $round type]} continue
        if {[dict get $round type] ne "final"} continue

        dict set result has_final 1

        # Process messages
        if {[dict exists $round messages]} {
            foreach msg [dict get $round messages] {
                set channel [spar::dict_get_default $msg channel ""]
                set actioned [spar::dict_get_default $msg actioned_date ""]
                set replied [spar::dict_get_default $msg replied_date ""]
                set to_addr [spar::dict_get_default $msg to ""]
                set subject [spar::dict_get_default $msg subject ""]

                set is_actioned [expr {![spar::is_null $actioned]}]
                set is_replied [expr {![spar::is_null $replied]}]

                if {$is_actioned} {
                    dict set result any_sent 1
                    if {$channel eq "email"} {
                        dict set result email_sent 1
                    }
                    if {$channel eq "linkedin"} {
                        dict set result linkedin_sent 1
                    }
                }

                if {$is_replied} {
                    dict set result email_replied 1
                }

                # Collect To: addresses from email messages
                if {$channel eq "email" && ![spar::is_null $to_addr]} {
                    set addr [string trim $to_addr]
                    if {$addr ne ""} {
                        set addrs [dict get $result to_addresses]
                        lappend addrs $addr
                        dict set result to_addresses $addrs
                    }
                }

                # Collect unsent subjects from email messages
                if {$channel eq "email" && !$is_actioned && ![spar::is_null $subject]} {
                    set subj [string trim $subject]
                    if {$subj ne ""} {
                        set subjs [dict get $result unsent_subjects]
                        lappend subjs $subj
                        dict set result unsent_subjects $subjs
                    }
                }

                # Append to per-message list for T9/T10 gating. Normalised
                # nulls so downstream code can rely on an empty string.
                set actioned_norm [expr {$is_actioned ? $actioned : ""}]
                set replied_norm  [expr {$is_replied ? $replied : ""}]
                set msgs [dict get $result messages]
                lappend msgs [dict create \
                    channel $channel \
                    actioned_date $actioned_norm \
                    replied_date $replied_norm \
                    is_actioned $is_actioned \
                    is_replied $is_replied]
                dict set result messages $msgs
            }
        }

        # Process replies
        if {[dict exists $round replies]} {
            foreach reply [dict get $round replies] {
                if {[spar::dict_get_default $reply direction ""] eq "received"} {
                    dict set result email_replied 1
                }
            }
        }
    }

    return $result
}

# classify_contact -- classify one contact's state.
#
# roster_row   dict with TSV fields (contact_name, date_excluded,
#              star_rating, email, linkedin_url, facebook_url, phone,
#              stem, ...)
#              stem is required; classify_segment validates its presence
#              before calling this proc.
# segment_dir  absolute path to the segment directory
#
# Returns a dict:
#   state         one of: EXCLUDED DISCOVERED PROFILED PROFILE_STALE
#                         APPROACHED SENT REPLIED
#   profile_path  path to profile file, or empty string
#   approach_path path to approach YAML, or empty string
#   star          integer (0 if blank/unparseable)
#   has_email     bool
#   has_linkedin  bool
#   has_facebook  bool
#   has_phone_only bool
#   email_sent    bool
#   linkedin_sent bool
#   email_replied bool
#   to_addresses     list of final-round email To: addresses (empty if no approach)
#   unsent_subjects  list of final-round unsent email subjects (empty if no approach)
#
proc spar::classify_contact {roster_row segment_dir} {
    # Extract roster fields with safe defaults.
    # strip_tsv_field: trim whitespace, and if the remaining value is a
    # quoted-empty-or-whitespace string (e.g. `" "` or `""`), collapse to "".
    # This happens when TSV was edited with a tool that CSV-quotes blank fields.
    set date_invalid [string trim [spar::dict_get_default $roster_row date_excluded ""]]
    set stem [string trim [spar::dict_get_default $roster_row stem ""]]
    set star_raw [spar::dict_get_default $roster_row star_rating ""]
    set email [string trim [spar::dict_get_default $roster_row email ""]]
    set linkedin [string trim [spar::dict_get_default $roster_row linkedin_url ""]]
    set facebook [string trim [spar::dict_get_default $roster_row facebook_url ""]]
    set phone [string trim [spar::dict_get_default $roster_row phone ""]]

    # Strip TSV quote artifacts: `" "`, `""`, `" "` → ""
    foreach var {date_invalid stem email linkedin facebook phone} {
        upvar 0 $var v
        if {[regexp {^"(.*)"$} $v -> inner]} {
            set v [string trim $inner]
        }
    }

    # Secondary properties
    set star [spar::parse_star $star_raw]
    set has_email [expr {[string first "@" $email] >= 0 && ![spar::is_masked_email $email]}]
    set has_linkedin [expr {$linkedin ne ""}]
    set has_facebook [expr {$facebook ne ""}]
    set has_phone_only [expr {$phone ne "" && !$has_email && !$has_linkedin && !$has_facebook}]

    # Initialise channel properties
    set email_sent 0
    set linkedin_sent 0
    set email_replied 0

    # Approach-derived fields carried through for detect_duplicates, so the
    # YAML is parsed once per contact rather than a second time during the
    # duplicate scan. Empty for states that never parse an approach YAML.
    set to_addresses {}
    set unsent_subjects {}

    # Paths
    set profile_path ""
    set approach_path ""

    # State evaluation (ordered — first match wins)

    # 1. EXCLUDED
    if {![spar::is_null $date_invalid]} {
        return [dict create \
            state EXCLUDED \
            profile_path $profile_path \
            approach_path $approach_path \
            star $star \
            has_email $has_email \
            has_linkedin $has_linkedin \
            has_facebook $has_facebook \
            has_phone_only $has_phone_only \
            email_sent $email_sent \
            linkedin_sent $linkedin_sent \
            email_replied $email_replied \
            to_addresses $to_addresses \
            unsent_subjects $unsent_subjects]
    }

    # 2. DISCOVERED — profile file does not exist
    set profile_path [file join $segment_dir profiles "${stem}.md"]
    if {![file exists $profile_path]} {
        set profile_path ""
        return [dict create \
            state DISCOVERED \
            profile_path $profile_path \
            approach_path $approach_path \
            star $star \
            has_email $has_email \
            has_linkedin $has_linkedin \
            has_facebook $has_facebook \
            has_phone_only $has_phone_only \
            email_sent $email_sent \
            linkedin_sent $linkedin_sent \
            email_replied $email_replied \
            to_addresses $to_addresses \
            unsent_subjects $unsent_subjects]
    }

    # 3. PROFILED / PROFILE_STALE — profile exists. Determine which by comparing
    # the profile's front-matter dependent_data snapshot to the current roster row.
    # Malformed front matter does not flip to STALE — validate_profile catches that
    # separately; staleness is about roster-vs-snapshot divergence only.
    set profile_state PROFILED
    if {[spar::_profile_is_stale $profile_path $roster_row]} {
        set profile_state PROFILE_STALE
    }

    set approach_path [file join $segment_dir approach "${stem}.yaml"]
    if {![file exists $approach_path]} {
        set approach_path ""
        return [dict create \
            state $profile_state \
            profile_path $profile_path \
            approach_path $approach_path \
            star $star \
            has_email $has_email \
            has_linkedin $has_linkedin \
            has_facebook $has_facebook \
            has_phone_only $has_phone_only \
            email_sent $email_sent \
            linkedin_sent $linkedin_sent \
            email_replied $email_replied \
            to_addresses $to_addresses \
            unsent_subjects $unsent_subjects]
    }

    # Approach file exists — parse it for state determination
    set approach_data [spar::read_approach_yaml $approach_path]
    set fr [spar::analyse_final_round $approach_data]

    set email_sent [dict get $fr email_sent]
    set linkedin_sent [dict get $fr linkedin_sent]
    set email_replied [dict get $fr email_replied]
    set to_addresses [dict get $fr to_addresses]
    set unsent_subjects [dict get $fr unsent_subjects]

    # 6. REPLIED — SENT and (replied_date or reply with direction:received)
    if {[dict get $fr any_sent] && [dict get $fr email_replied]} {
        return [dict create \
            state REPLIED \
            profile_path $profile_path \
            approach_path $approach_path \
            star $star \
            has_email $has_email \
            has_linkedin $has_linkedin \
            has_facebook $has_facebook \
            has_phone_only $has_phone_only \
            email_sent $email_sent \
            linkedin_sent $linkedin_sent \
            email_replied $email_replied \
            to_addresses $to_addresses \
            unsent_subjects $unsent_subjects]
    }

    # 5. SENT — final round has at least one message with actioned_date
    if {[dict get $fr any_sent]} {
        return [dict create \
            state SENT \
            profile_path $profile_path \
            approach_path $approach_path \
            star $star \
            has_email $has_email \
            has_linkedin $has_linkedin \
            has_facebook $has_facebook \
            has_phone_only $has_phone_only \
            email_sent $email_sent \
            linkedin_sent $linkedin_sent \
            email_replied $email_replied \
            to_addresses $to_addresses \
            unsent_subjects $unsent_subjects]
    }

    # 4. APPROACHED — approach file exists, no final-round message with actioned_date
    return [dict create \
        state APPROACHED \
        profile_path $profile_path \
        approach_path $approach_path \
        star $star \
        has_email $has_email \
        has_linkedin $has_linkedin \
        has_facebook $has_facebook \
        has_phone_only $has_phone_only \
        email_sent $email_sent \
        linkedin_sent $linkedin_sent \
        email_replied $email_replied \
        to_addresses $to_addresses \
        unsent_subjects $unsent_subjects]
}

# classify_segment -- load roster and classify all contacts.
#
# segment_dir  absolute path to the segment directory
#
# Returns a list of dicts, one per valid+named roster row,
# each being the result of classify_contact merged with the original roster_row.
# On schema error, throws an error.
#
proc spar::classify_segment {segment_dir} {
    set roster_path [file join $segment_dir roster.tsv]
    if {![file exists $roster_path]} {
        error "Roster file not found: $roster_path"
    }

    set rows [spar::load_roster $roster_path]

    # Schema validation: check that stem column exists
    if {[llength $rows] > 0} {
        set first_row [lindex $rows 0]
        if {![dict exists $first_row stem]} {
            error "Error: roster missing required column 'stem' — run schema migration before using spar-state.tcl"
        }
    }

    set results {}
    foreach row $rows {
        set classified [spar::classify_contact $row $segment_dir]

        # Merge: original roster_row + classified result (classified wins on overlap)
        set merged $row
        dict for {k v} $classified {
            dict set merged $k $v
        }
        # Ensure segment_dir is available for cross-segment operations
        dict set merged _segment_dir $segment_dir

        lappend results $merged
    }

    return $results
}

# _final_round_messages_for_contact -- parse the contact's approach file
# and return the per-message list from analyse_final_round, or {} if no
# approach file exists. Convenience wrapper to avoid re-parsing the YAML
# at each caller.
proc spar::_final_round_messages_for_contact {contact} {
    set ap [spar::dict_get_default $contact approach_path ""]
    if {$ap eq "" || ![file exists $ap]} { return {} }
    set adata [spar::read_approach_yaml $ap]
    if {$adata eq ""} { return {} }
    set fr [spar::analyse_final_round $adata]
    return [dict get $fr messages]
}

# _channel_slot_wait_days -- extract wait_days from a channel slot dict
# (spar-campaign-yaml.md §Required channels). Returns "" if missing.
proc spar::_channel_slot_wait_days {slot} {
    if {$slot eq ""} { return "" }
    if {[llength $slot] <= 1} { return "" }
    return [spar::dict_get_default $slot wait_days ""]
}

# _channel_slot_wait_condition -- extract wait_condition. Returns "" if missing.
proc spar::_channel_slot_wait_condition {slot} {
    if {$slot eq ""} { return "" }
    if {[llength $slot] <= 1} { return "" }
    return [spar::dict_get_default $slot wait_condition ""]
}

# _channel_slot_as_map -- return the raw slot value (bare string or map)
# directly from a campaign dict. Used by T9/T10 to reach wait_days /
# wait_condition without re-implementing the normalisation logic.
proc spar::_campaign_slot {cdata key} {
    if {![dict exists $cdata $key]} { return "" }
    return [dict get $cdata $key]
}

# _days_since -- integer days from a date to today (or the supplied
# reference date). `date` may be ISO "YYYY-MM-DD" OR an epoch-seconds
# integer — the YAML parser in the approach-file path eagerly converts
# bare YAML date literals to epoch seconds, so both forms appear in
# classified contacts. Negative if the reference date is before `date`.
# Returns "" on parse failure.
proc spar::_days_since {date {today ""}} {
    if {$date eq "" || [spar::is_null $date]} { return "" }
    if {[string is integer -strict $date]} {
        set then_sec $date
    } elseif {[catch {clock scan $date -format "%Y-%m-%d" -timezone :UTC} then_sec]} {
        return ""
    }
    if {$today eq ""} {
        set now_sec [clock seconds]
    } elseif {[string is integer -strict $today]} {
        set now_sec $today
    } elseif {[catch {clock scan $today -format "%Y-%m-%d" -timezone :UTC} now_sec]} {
        return ""
    }
    return [expr {($now_sec - $then_sec) / 86400}]
}

# _channel_readiness -- evaluate secondary_ready / tertiary_ready for
# one contact given the campaign's channel slots. Returns a dict:
#   {secondary_ready bool tertiary_ready bool
#    secondary_reason "" tertiary_reason ""}
#
# Rules (spar-manager/state-machine.md §States, §Transition manager):
#  - The slot must be declared in the campaign.
#  - Final round must contain a sent message for the *preceding* channel
#    (actioned_date non-null) whose actioned_date is ≥ wait_days old.
#  - wait_condition must hold — today we implement only `no_reply`:
#    preceding message's replied_date must be null.
#  - Final round must contain a pending message (actioned_date null) for
#    the slot's own channel.
# Reason strings describe why a slot is NOT ready (empty when it is).
#
# today_iso — ISO YYYY-MM-DD reference date. Optional; defaults to today.
proc spar::_channel_readiness {contact cdata {today_iso ""}} {
    set out [dict create \
        secondary_ready 0 tertiary_ready 0 \
        secondary_reason "" tertiary_reason ""]
    set primary [spar::campaign_primary_channel $cdata]
    if {$primary eq ""} { return $out }
    set secondary_slot [spar::_campaign_slot $cdata secondary_channel]
    set secondary_ch [spar::_campaign_channel_slot $cdata secondary_channel]
    if {$secondary_ch eq ""} { return $out }

    set messages [spar::_final_round_messages_for_contact $contact]
    if {[llength $messages] == 0} {
        dict set out secondary_reason "no approach/final round"
        return $out
    }

    # Helper: find first message for a given channel in the list.
    set find_msg {
        apply {{msgs ch} {
            foreach m $msgs {
                if {[dict get $m channel] eq $ch} { return $m }
            }
            return {}
        }}
    }

    # Secondary: gated on the primary channel's sent message.
    set primary_msg [{*}$find_msg $messages $primary]
    set secondary_msg [{*}$find_msg $messages $secondary_ch]
    set wait_days [spar::_channel_slot_wait_days $secondary_slot]
    set wait_cond [spar::_channel_slot_wait_condition $secondary_slot]
    set sec_reason [spar::_evaluate_slot_readiness \
        $primary_msg $secondary_msg $wait_days $wait_cond $secondary_ch $today_iso]
    if {$sec_reason eq ""} {
        dict set out secondary_ready 1
    } else {
        dict set out secondary_reason $sec_reason
    }

    # Tertiary: gated on the secondary channel's sent message.
    set tertiary_slot [spar::_campaign_slot $cdata tertiary_channel]
    set tertiary_ch [spar::_campaign_channel_slot $cdata tertiary_channel]
    if {$tertiary_ch eq ""} { return $out }

    set tertiary_msg [{*}$find_msg $messages $tertiary_ch]
    set t_wait_days [spar::_channel_slot_wait_days $tertiary_slot]
    set t_wait_cond [spar::_channel_slot_wait_condition $tertiary_slot]
    set ter_reason [spar::_evaluate_slot_readiness \
        $secondary_msg $tertiary_msg $t_wait_days $t_wait_cond $tertiary_ch $today_iso]
    if {$ter_reason eq ""} {
        dict set out tertiary_ready 1
    } else {
        dict set out tertiary_reason $ter_reason
    }
    return $out
}

# _evaluate_slot_readiness -- helper for _channel_readiness. Given the
# preceding-slot message and the own-slot message, return "" if this
# slot is ready, or a human-readable reason if not.
proc spar::_evaluate_slot_readiness {preceding_msg own_msg wait_days wait_cond own_channel today_iso} {
    if {[llength $preceding_msg] == 0} {
        return "preceding channel has no message in final round"
    }
    if {![dict get $preceding_msg is_actioned]} {
        return "preceding channel not yet sent"
    }
    if {$wait_days ne ""} {
        set days [spar::_days_since [dict get $preceding_msg actioned_date] $today_iso]
        if {$days eq ""} {
            return "preceding actioned_date unparseable"
        }
        if {$days < $wait_days} {
            return "waiting until day $wait_days (currently day $days since preceding send)"
        }
    }
    if {$wait_cond eq "no_reply"} {
        if {[dict get $preceding_msg is_replied]} {
            return "preceding channel received a reply (no_reply condition failed)"
        }
    }
    if {[llength $own_msg] == 0} {
        return "no '$own_channel' message drafted in final round"
    }
    if {[dict get $own_msg is_actioned]} {
        return "own '$own_channel' message already sent"
    }
    return ""
}

# _approach_dispatch_gate -- SSOT for the campaign-wide gates that both
# transition_eligible (T2/T7) and spar::a::run apply when deciding
# whether a roster row may be approached. Returns "" if the row passes;
# otherwise a human-readable reason. Takes either a raw roster row or a
# classified contact — classify_segment merges row fields in, so both
# dicts expose star_rating, date_excluded, email, linkedin_url, etc.
#
# Gates (resolves #56):
#   - skip_excluded:   filter.skip_excluded (default true) + date_excluded
#   - in_scope_channel: roster_row_has_in_scope_channel against campaign slots
#   - min_star:        filter.min_star (default 3) vs parsed star_rating
#
# When cdata is empty (tests, legacy callers), falls back to the pre-#56
# T2 hardcode — star >= 3 + skip excluded — so run-tests.tcl T2 assertions
# keep passing without threading cdata through.
proc spar::_approach_dispatch_gate {row cdata} {
    set has_cdata [expr {[llength $cdata] > 0}]
    set date_ex [string trim [spar::dict_get_default $row date_excluded ""]]
    set skip_excluded 1
    set min_star 3
    set in_scope {}
    if {$has_cdata} {
        set filter [spar::dict_get_default $cdata filter [dict create]]
        set skip_excluded [string is true -strict \
            [spar::dict_get_default $filter skip_excluded true]]
        set min_star [spar::dict_get_default $filter min_star 3]
        set in_scope [spar::campaign_in_scope_channels $cdata]
    }
    if {$skip_excluded && $date_ex ne ""} {
        return "excluded on $date_ex"
    }
    if {![spar::roster_row_has_in_scope_channel $row $in_scope]} {
        return "no in-scope channel (campaign: [join $in_scope {, }])"
    }
    if {$min_star > 0} {
        set star [spar::parse_star [spar::dict_get_default $row star_rating ""]]
        if {$star < $min_star} {
            return "star $star below min_star $min_star"
        }
    }
    return ""
}

# _approach_validation_error -- return first error-severity validation message for
# a contact's approach file, or "" if clean. Used by transition_eligible to gate
# approach-dependent transitions (T3, T4, T8) on structural validity (#43 principle 7).
proc spar::_approach_validation_error {contact} {
    set ap [spar::dict_get_default $contact approach_path ""]
    if {$ap eq "" || ![file exists $ap]} { return "" }
    set roster_email [string trim [spar::dict_get_default $contact email ""]]
    set cname [spar::dict_get_default $contact contact_name ""]
    set corg  [spar::dict_get_default $contact organisation ""]
    foreach issue [spar::validate_approach $ap $roster_email $cname $corg] {
        if {[dict get $issue severity] eq "error"} {
            return [dict get $issue message]
        }
    }
    return ""
}

# transition_eligible -- filter classified contacts by transition eligibility.
#
# classified_contacts  output of classify_segment
# transition           transition name: T1, T2, ... T8
# primary_channel      campaign primary channel (bare string, e.g. "email").
#                      Empty string = unknown; T3 conservatively yields nothing.
#                      TODO(#49): this arg is an interim gate. Correct
#                      per-message eligibility must route each unsent final-
#                      round message to T3/T8/T9/T10 based on its slot in the
#                      primary/secondary/tertiary structure, not on channel
#                      alone. See issue #49 for acceptance criteria.
#
# Returns a list of dicts with keys:
#   contact_name, organisation, segment, task_state (ready/pending/done), reason
#
proc spar::transition_eligible {classified_contacts transition {primary_channel ""} {cdata {}} {today_iso ""}} {
    set results {}

    foreach contact $classified_contacts {
        set name [spar::dict_get_default $contact contact_name ""]
        set org [spar::dict_get_default $contact organisation ""]
        set stem [spar::dict_get_default $contact stem ""]
        set segment_dir [spar::dict_get_default $contact _segment_dir ""]
        set segment [file tail $segment_dir]
        set state [dict get $contact state]
        set star [dict get $contact star]
        set has_email [dict get $contact has_email]
        set email_sent [dict get $contact email_sent]
        set linkedin_sent [dict get $contact linkedin_sent]
        set email_replied [dict get $contact email_replied]

        switch -- $transition {
            T1 {
                # Sweep → Profile: state = DISCOVERED
                if {$state eq "DISCOVERED"} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        stem $stem _segment_dir $segment_dir \
                        task_state ready reason ""]
                }
            }
            T2 {
                # Profile → Approach: state = PROFILED + campaign-wide
                # approach-dispatch gates (min_star, in_scope_channel,
                # skip_excluded). Gate is SSOT (#56) — spar::a::run
                # consults the same proc.
                if {$state eq "PROFILED" && \
                    [spar::_approach_dispatch_gate $contact $cdata] eq ""} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        stem $stem _segment_dir $segment_dir \
                        task_state ready reason ""]
                }
            }
            T3 {
                # Approach → Send: state in {APPROACHED,SENT}, has_email, not email_sent.
                # Gate on approach-YAML validity (#43 principle 7) — broken files
                # surface as pending:invalid_approach_yaml instead of ready.
                #
                # TODO(#49): per-message routing. T3 should fire only for the
                # primary-channel email message; email-as-secondary belongs to
                # T9/T10 with wait_days/wait_condition gating. Until that is
                # resolved, require primary_channel == "email" — empty or any
                # other value yields zero tasks so a caller that forgets to
                # pass it fails safe rather than sending.
                if {$primary_channel ne "email"} continue
                if {$state eq "APPROACHED" || $state eq "SENT"} {
                    set vmsg [spar::_approach_validation_error $contact]
                    if {$has_email && !$email_sent} {
                        if {$vmsg ne ""} {
                            lappend results [dict create \
                                contact_name $name organisation $org segment $segment \
                                stem $stem _segment_dir $segment_dir \
                                task_state pending reason "invalid_approach_yaml: $vmsg"]
                        } else {
                            lappend results [dict create \
                                contact_name $name organisation $org segment $segment \
                                stem $stem _segment_dir $segment_dir \
                                task_state ready reason ""]
                        }
                    } elseif {!$has_email} {
                        lappend results [dict create \
                            contact_name $name organisation $org segment $segment \
                            stem $stem _segment_dir $segment_dir \
                            task_state pending reason "No email address"]
                    }
                }
            }
            T4 {
                # Send → Reply: email_sent, not email_replied (monitoring only).
                # Skip EXCLUDED — an invalidated contact's approach file may still
                # carry email_sent=true from before invalidation, but monitoring
                # for a reply is not meaningful once we've decided not to pursue.
                if {$state ne "EXCLUDED" && $email_sent && !$email_replied} {
                    set vmsg [spar::_approach_validation_error $contact]
                    if {$vmsg ne ""} {
                        lappend results [dict create \
                            contact_name $name organisation $org segment $segment \
                            stem $stem _segment_dir $segment_dir \
                            task_state pending reason "invalid_approach_yaml: $vmsg"]
                    } else {
                        lappend results [dict create \
                            contact_name $name organisation $org segment $segment \
                            stem $stem _segment_dir $segment_dir \
                            task_state pending reason "Waiting for reply"]
                    }
                }
            }
            T6 {
                # Stale → Re-profile: state = PROFILE_STALE
                # Zero tasks until PROFILE_STALE defined
                if {$state eq "PROFILE_STALE"} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        stem $stem _segment_dir $segment_dir \
                        task_state ready reason ""]
                }
            }
            T7 {
                # Re-profile → Re-approach: deferred, zero tasks
                # Would require PROFILE_STALE + re-profiling detection
            }
            T8 {
                # LinkedIn → Email follow-up: linkedin_sent, not email_sent.
                # Skip EXCLUDED for the same reason as T4. Gate on approach-YAML
                # validity (#43 principle 7).
                if {$state ne "EXCLUDED" && $linkedin_sent && !$email_sent} {
                    set vmsg [spar::_approach_validation_error $contact]
                    if {$vmsg ne ""} {
                        lappend results [dict create \
                            contact_name $name organisation $org segment $segment \
                            stem $stem _segment_dir $segment_dir \
                            task_state pending reason "invalid_approach_yaml: $vmsg"]
                    } else {
                        lappend results [dict create \
                            contact_name $name organisation $org segment $segment \
                            stem $stem _segment_dir $segment_dir \
                            task_state pending reason "LinkedIn sent, awaiting acceptance before email follow-up"]
                    }
                }
            }
            T9 {
                # Secondary follow-up (issue #41). Campaign must declare a
                # secondary_channel slot; contact must be APPROACHED or SENT
                # (primary was drafted). Gated on `secondary_ready`:
                # preceding primary is sent ≥ wait_days ago, wait_condition
                # holds, and the secondary-channel message is still pending.
                # Dispatch status is `manual` (state-machine.md §Transition
                # manager) — the UI exposes a render-script + actioned-date
                # button rather than spawning a harness. Skip EXCLUDED.
                if {$state eq "EXCLUDED"} continue
                if {$state ne "APPROACHED" && $state ne "SENT"} continue
                if {[llength $cdata] == 0} continue
                set vmsg [spar::_approach_validation_error $contact]
                if {$vmsg ne ""} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        stem $stem _segment_dir $segment_dir \
                        task_state pending reason "invalid_approach_yaml: $vmsg"]
                    continue
                }
                set r [spar::_channel_readiness $contact $cdata $today_iso]
                if {[dict get $r secondary_ready]} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        stem $stem _segment_dir $segment_dir \
                        task_state ready reason ""]
                } elseif {[dict get $r secondary_reason] ne ""} {
                    # Emit pending only for contacts whose primary channel
                    # was drafted — otherwise T9 has nothing to wait for.
                    set reason [dict get $r secondary_reason]
                    if {![string match "preceding channel has no message*" $reason] \
                        && ![string match "no approach*" $reason] \
                        && ![string match "preceding channel not yet sent*" $reason]} {
                        lappend results [dict create \
                            contact_name $name organisation $org segment $segment \
                            stem $stem _segment_dir $segment_dir \
                            task_state pending reason $reason]
                    }
                }
            }
            T10 {
                # Tertiary follow-up (issue #41). Same shape as T9 but
                # gated on `tertiary_ready` (preceding = secondary).
                if {$state eq "EXCLUDED"} continue
                if {$state ne "APPROACHED" && $state ne "SENT"} continue
                if {[llength $cdata] == 0} continue
                set vmsg [spar::_approach_validation_error $contact]
                if {$vmsg ne ""} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        stem $stem _segment_dir $segment_dir \
                        task_state pending reason "invalid_approach_yaml: $vmsg"]
                    continue
                }
                set r [spar::_channel_readiness $contact $cdata $today_iso]
                if {[dict get $r tertiary_ready]} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        stem $stem _segment_dir $segment_dir \
                        task_state ready reason ""]
                } elseif {[dict get $r tertiary_reason] ne ""} {
                    set reason [dict get $r tertiary_reason]
                    if {![string match "preceding channel has no message*" $reason] \
                        && ![string match "no approach*" $reason] \
                        && ![string match "preceding channel not yet sent*" $reason]} {
                        lappend results [dict create \
                            contact_name $name organisation $org segment $segment \
                            stem $stem _segment_dir $segment_dir \
                            task_state pending reason $reason]
                    }
                }
            }
        }
    }

    return $results
}

# detect_duplicates -- detect cross-segment duplicates.
#
# all_classified_contacts  flat list of all classified contacts across all segments
#                          (each dict has _segment_dir, contact_name, email, approach_path, etc.)
#
# Returns a dict with keys:
#   duplicate_to      — list of dicts {address files} where same To: email in multiple approach files
#   duplicate_name    — list of dicts {name entries} where same normalised name in multiple segments
#   duplicate_email   — list of dicts {email entries} where same email in multiple segments
#   identical_subject — list of dicts {subject files} where same subject in multiple unsent approach files
#
proc spar::detect_duplicates {all_classified_contacts} {
    # Accumulators: key → list of entries
    array set to_map {}       ;# to_address → list of {segment filename}
    array set name_map {}     ;# normalised_name → list of {segment contact_name organisation email}
    array set email_map {}    ;# email → list of {segment contact_name organisation}
    array set subject_map {}  ;# subject → list of {segment filename}

    foreach contact $all_classified_contacts {
        set name [spar::dict_get_default $contact contact_name ""]
        set org [spar::dict_get_default $contact organisation ""]
        set email [string trim [string tolower [spar::dict_get_default $contact email ""]]]
        set segment_dir [spar::dict_get_default $contact _segment_dir ""]
        set segment [file tail $segment_dir]
        set approach_path [dict get $contact approach_path]
        set state [dict get $contact state]
        set email_sent_flag [dict get $contact email_sent]

        # EXCLUDED contacts cannot be acted on — no transition dispatches them and
        # validate_campaign skips them. Their roster fields and approach files
        # must not feed duplicate-detection maps, or they fire warnings about
        # collisions that the rest of the state machine has already routed around.
        if {$state eq "EXCLUDED"} continue

        if {$name eq ""} continue

        # Name map (cross-segment)
        set nk [spar::normalise_name $name]
        if {$nk ne ""} {
            lappend name_map($nk) [list $segment $name $org $email]
        }

        # Email map (cross-segment)
        if {$email ne "" && [string first "@" $email] >= 0} {
            lappend email_map($email) [list $segment $name $org]
        }

        # Approach-file-based checks: only if approach file exists.
        # to_addresses and unsent_subjects come from the classify_contact
        # pass that already parsed this YAML — reusing them avoids a second
        # read+parse per contact on cold load.
        if {$approach_path eq "" || ![file exists $approach_path]} continue

        set filename [file tail $approach_path]

        # To: address duplicates
        foreach addr [spar::dict_get_default $contact to_addresses {}] {
            set addr_lower [string tolower [string trim $addr]]
            if {$addr_lower ne "" && [string first "@" $addr_lower] >= 0} {
                lappend to_map($addr_lower) [list $segment $filename]
            }
        }

        # Identical subject lines in unsent approach files
        foreach subj [spar::dict_get_default $contact unsent_subjects {}] {
            if {$subj ne ""} {
                lappend subject_map($subj) [list $segment $filename]
            }
        }
    }

    # Build result: only include entries with duplicates

    # duplicate_to: same To: address in multiple approach files
    set dup_to {}
    foreach addr [array names to_map] {
        set entries $to_map($addr)
        if {[llength $entries] > 1} {
            lappend dup_to [dict create address $addr files $entries]
        }
    }

    # duplicate_name: same normalised name across multiple segments
    set dup_name {}
    foreach nk [array names name_map] {
        set entries $name_map($nk)
        # Only flag if name appears in more than one distinct segment
        set seen_segments {}
        foreach entry $entries {
            set seg [lindex $entry 0]
            if {$seg ni $seen_segments} {
                lappend seen_segments $seg
            }
        }
        if {[llength $seen_segments] > 1} {
            lappend dup_name [dict create name $nk entries $entries]
        }
    }

    # duplicate_email: same email across multiple segments
    set dup_email {}
    foreach addr [array names email_map] {
        set entries $email_map($addr)
        set seen_segments {}
        foreach entry $entries {
            set seg [lindex $entry 0]
            if {$seg ni $seen_segments} {
                lappend seen_segments $seg
            }
        }
        if {[llength $seen_segments] > 1} {
            lappend dup_email [dict create email $addr entries $entries]
        }
    }

    # identical_subject: same subject in multiple unsent approach files
    set dup_subject {}
    foreach subj [array names subject_map] {
        set entries $subject_map($subj)
        if {[llength $entries] > 1} {
            lappend dup_subject [dict create subject $subj files $entries]
        }
    }

    return [dict create \
        duplicate_to $dup_to \
        duplicate_name $dup_name \
        duplicate_email $dup_email \
        identical_subject $dup_subject]
}

# progress_counts -- compute progress table counts for one segment.
#
# classified_contacts  output of classify_segment for one segment
#
# Returns a dict with counts:
#   valid, profiled, star3, approached_star3, has_email, approached_email,
#   has_linkedin, has_facebook, has_phone_only, email_sent, email_replied
#
proc spar::progress_counts {classified_contacts} {
    set valid 0
    set profiled 0
    set star3 0
    set approached_star3 0
    set has_email 0
    set approached_email 0
    set has_linkedin 0
    set has_facebook 0
    set has_phone_only 0
    set n_email_sent 0
    set n_email_replied 0

    # States that are "profiled or above"
    set profiled_plus {PROFILED PROFILE_STALE APPROACHED SENT REPLIED}
    # States that are "approached or above"
    set approached_plus {APPROACHED SENT REPLIED}

    foreach contact $classified_contacts {
        set state [dict get $contact state]
        set star [dict get $contact star]
        set c_has_email [dict get $contact has_email]
        set c_has_linkedin [dict get $contact has_linkedin]
        set c_has_facebook [dict get $contact has_facebook]
        set c_has_phone_only [dict get $contact has_phone_only]
        set c_email_sent [dict get $contact email_sent]
        set c_email_replied [dict get $contact email_replied]

        # Valid: not EXCLUDED
        if {$state ne "EXCLUDED"} {
            incr valid
        } else {
            continue
        }

        # Profiled: PROFILED or above
        if {$state in $profiled_plus} {
            incr profiled
        }

        # Star 3+
        if {$star >= 3} {
            incr star3

            # Approached and star3
            if {$state in $approached_plus} {
                incr approached_star3
            }

            # Has email (among star3)
            if {$c_has_email} {
                incr has_email

                # Approached with email (among star3 with email)
                if {$state in $approached_plus} {
                    incr approached_email
                }
            }

            # Has LinkedIn (among star3)
            if {$c_has_linkedin} {
                incr has_linkedin
            }

            # Has Facebook (among star3)
            if {$c_has_facebook} {
                incr has_facebook
            }

            # Has phone only (among star3)
            if {$c_has_phone_only} {
                incr has_phone_only
            }

            # Email sent / replied: only count among star3 with email
            if {$c_has_email && $state in $approached_plus} {
                if {$c_email_sent} {
                    incr n_email_sent
                }
                if {$c_email_replied} {
                    incr n_email_replied
                }
            }
        }
    }

    return [dict create \
        valid $valid \
        profiled $profiled \
        star3 $star3 \
        approached_star3 $approached_star3 \
        has_email $has_email \
        approached_email $approached_email \
        has_linkedin $has_linkedin \
        has_facebook $has_facebook \
        has_phone_only $has_phone_only \
        email_sent $n_email_sent \
        email_replied $n_email_replied]
}

# roster_counts -- compute progress counts from roster TSV alone (no filesystem).
#
# segment_dir  absolute path to the segment directory
#
# Returns a dict with the six TSV-derivable counts:
#   valid, star3, has_email, has_linkedin, has_facebook, has_phone_only
# These correspond to columns that do not require profile/approach file access.
# Counts not computable from the TSV alone (profiled, approached_star3,
# approached_email, email_sent, email_replied) are omitted.
#
proc spar::roster_counts {segment_dir} {
    set roster_path [file join $segment_dir roster.tsv]
    set rows [spar::load_roster $roster_path]

    set valid 0
    set star3 0
    set has_email 0
    set has_linkedin 0
    set has_facebook 0
    set has_phone_only 0

    foreach row $rows {
        if {[dict exists $row stem]} {
            set stem [string trim [dict get $row stem]]
        } else {
            continue
        }

        # Skip EXCLUDED (date_excluded set)
        set date_invalid [string trim [spar::dict_get_default $row date_excluded ""]]
        if {[regexp {^"(.*)"$} $date_invalid -> inner]} {
            set date_invalid [string trim $inner]
        }
        if {![spar::is_null $date_invalid]} continue

        set contact_name [string trim [spar::dict_get_default $row contact_name ""]]

        incr valid

        set star [spar::parse_star [spar::dict_get_default $row star_rating ""]]

        set email [string trim [spar::dict_get_default $row email ""]]
        if {[regexp {^"(.*)"$} $email -> inner]} { set email [string trim $inner] }
        set linkedin [string trim [spar::dict_get_default $row linkedin_url ""]]
        if {[regexp {^"(.*)"$} $linkedin -> inner]} { set linkedin [string trim $inner] }
        set facebook [string trim [spar::dict_get_default $row facebook_url ""]]
        if {[regexp {^"(.*)"$} $facebook -> inner]} { set facebook [string trim $inner] }
        set phone [string trim [spar::dict_get_default $row phone ""]]
        if {[regexp {^"(.*)"$} $phone -> inner]} { set phone [string trim $inner] }

        set c_has_email [expr {[string first "@" $email] >= 0 && ![spar::is_masked_email $email]}]
        set c_has_linkedin [expr {$linkedin ne ""}]
        set c_has_facebook [expr {$facebook ne ""}]
        set c_has_phone_only [expr {$phone ne "" && !$c_has_email && !$c_has_linkedin && !$c_has_facebook}]

        if {$star >= 3} {
            incr star3
            if {$c_has_email} { incr has_email }
            if {$c_has_linkedin} { incr has_linkedin }
            if {$c_has_facebook} { incr has_facebook }
            if {$c_has_phone_only} { incr has_phone_only }
        }
    }

    return [dict create \
        valid $valid \
        star3 $star3 \
        has_email $has_email \
        has_linkedin $has_linkedin \
        has_facebook $has_facebook \
        has_phone_only $has_phone_only]
}

# _approach_canonical_keys -- single source of truth for approach YAML vocabulary.
# Keyed by level; must stay in sync with approach-schema.yaml's additionalProperties.
# Per issue SmartLayer/aesop#43.
proc spar::_approach_canonical_keys {} {
    return [dict create \
        root {decisions rounds profile_date profile_richness angle_rationale roster_note fact_provenance quality_checklist response_likelihood generated_for} \
        decisions {warmth channel language angle sender warmth_detail channel_detail subsegment} \
        round {type number messages verdict fact_check in_character chosen_usps revision_note notes replies antifact_check} \
        message {channel subject body to actioned_date replied_date reply_summary script text char_count bcc cc director_note to_note phone_note} \
        fact_provenance_item {claim source} \
        fact_check_item {claim source result note correction} \
        script_item {point text} \
        generated_for {contact_name organisation}]
}

# _check_unknown_keys -- emit unknown_key_<level> or wrong_level issues for a parsed dict.
# If an unknown key is canonical at another level, emit wrong_level with a pointer.
proc spar::_check_unknown_keys {data level contact_name} {
    set issues {}
    set canon [spar::_approach_canonical_keys]
    if {![dict exists $canon $level]} { return $issues }
    set known [dict get $canon $level]
    if {[llength $data] % 2 != 0} { return $issues }
    foreach {k _v} $data {
        if {$k in $known} continue
        set found_at ""
        dict for {lvl keys} $canon {
            if {$lvl eq $level} continue
            if {$k in $keys} { set found_at $lvl; break }
        }
        if {$found_at ne ""} {
            lappend issues [dict create \
                severity error \
                code wrong_level \
                contact_name $contact_name \
                message "'$k' at $level belongs at $found_at; move it there"]
        } else {
            lappend issues [dict create \
                severity error \
                code unknown_key_$level \
                contact_name $contact_name \
                message "unknown key '$k' at $level — not in canonical vocabulary"]
        }
    }
    return $issues
}

# validate_approach -- check a single approach file against guard rails.
#
# approach_path         path to the approach YAML file
# roster_email          email field from the roster row (may be empty)
# contact_name          roster contact_name (used for messages and, when
#                       generated_for is present, the name_desync comparison)
# roster_organisation   roster organisation (optional, used for org_desync)
#
# Returns a list of issue dicts, each with keys:
#   severity, code, contact_name, message
#
proc spar::validate_approach {approach_path roster_email contact_name {roster_organisation ""}} {
    set issues {}

    if {$approach_path eq "" || ![file exists $approach_path]} {
        return $issues
    }

    set approach_data [spar::read_approach_yaml $approach_path]
    if {$approach_data eq ""} {
        lappend issues [dict create \
            severity error \
            code invalid_yaml \
            contact_name $contact_name \
            message "Approach file could not be parsed as YAML"]
        return $issues
    }

    # ── Closed-vocabulary walk (approach-schema.yaml) ──
    # Emits unknown_key_<level> / wrong_level issues. Per #43 principle 1.

    lappend issues {*}[spar::_check_unknown_keys $approach_data root $contact_name]

    if {[dict exists $approach_data decisions]} {
        set _dec [dict get $approach_data decisions]
        lappend issues {*}[spar::_check_unknown_keys $_dec decisions $contact_name]
    }

    if {[dict exists $approach_data generated_for]} {
        set _gf [dict get $approach_data generated_for]
        if {[llength $_gf] % 2 == 0} {
            lappend issues {*}[spar::_check_unknown_keys $_gf generated_for $contact_name]
        }
    }

    if {[dict exists $approach_data rounds]} {
        foreach _round [dict get $approach_data rounds] {
            if {[llength $_round] % 2 != 0} continue
            lappend issues {*}[spar::_check_unknown_keys $_round round $contact_name]
            if {[dict exists $_round messages]} {
                foreach _msg [dict get $_round messages] {
                    if {[llength $_msg] % 2 != 0} continue
                    lappend issues {*}[spar::_check_unknown_keys $_msg message $contact_name]
                    if {[dict exists $_msg script]} {
                        foreach _item [dict get $_msg script] {
                            if {[llength $_item] % 2 != 0} continue
                            lappend issues {*}[spar::_check_unknown_keys $_item script_item $contact_name]
                        }
                    }
                }
            }
            if {[dict exists $_round fact_check]} {
                foreach _item [dict get $_round fact_check] {
                    if {[llength $_item] % 2 != 0} continue
                    lappend issues {*}[spar::_check_unknown_keys $_item fact_check_item $contact_name]
                }
            }
        }
    }

    if {[dict exists $approach_data fact_provenance]} {
        foreach _item [dict get $approach_data fact_provenance] {
            if {[llength $_item] % 2 != 0} continue
            lappend issues {*}[spar::_check_unknown_keys $_item fact_provenance_item $contact_name]
        }
    }

    # ── Structural checks (approach-schema.yaml) ──

    # decisions key must exist
    if {![dict exists $approach_data decisions]} {
        lappend issues [dict create \
            severity error \
            code missing_decisions \
            contact_name $contact_name \
            message "Approach file missing required 'decisions' key"]
    }

    # rounds key must exist and be non-empty
    if {![dict exists $approach_data rounds]} {
        lappend issues [dict create \
            severity error \
            code missing_rounds \
            contact_name $contact_name \
            message "Approach file missing required 'rounds' key"]
        return $issues
    }
    set rounds [dict get $approach_data rounds]
    if {[llength $rounds] == 0} {
        lappend issues [dict create \
            severity error \
            code missing_rounds \
            contact_name $contact_name \
            message "Approach file has empty 'rounds' array"]
        return $issues
    }

    # At least one round must have type: final
    set has_final 0
    foreach round $rounds {
        if {[dict exists $round type] && [dict get $round type] eq "final"} {
            set has_final 1
            break
        }
    }
    if {!$has_final} {
        lappend issues [dict create \
            severity error \
            code no_final_round \
            contact_name $contact_name \
            message "Approach file has no round with type: final"]
    }

    # Per-round checks
    foreach round $rounds {
        set rtype ""
        if {[dict exists $round type]} {
            set rtype [dict get $round type]
        }

        # Draft and review rounds require number
        if {$rtype eq "draft" && ![dict exists $round number]} {
            lappend issues [dict create \
                severity warning \
                code draft_missing_number \
                contact_name $contact_name \
                message "Draft round missing required 'number' field"]
        }
        if {$rtype eq "review" && ![dict exists $round number]} {
            lappend issues [dict create \
                severity warning \
                code review_missing_number \
                contact_name $contact_name \
                message "Review round missing required 'number' field"]
        }

        # Email messages must have subject or body
        set final_email_count 0
        if {[dict exists $round messages]} {
            foreach msg [dict get $round messages] {
                if {[dict exists $msg channel] && [dict get $msg channel] eq "email"} {
                    if {![dict exists $msg subject] && ![dict exists $msg body]} {
                        lappend issues [dict create \
                            severity warning \
                            code email_missing_content \
                            contact_name $contact_name \
                            message "Email message missing both 'subject' and 'body'"]
                    }
                    if {$rtype eq "final"} { incr final_email_count }
                }
            }
        }

        # Final round may have at most one email message. Follow-ups belong
        # in subsequent rounds; multi-recipient belongs in cc/bcc.
        if {$rtype eq "final" && $final_email_count > 1} {
            lappend issues [dict create \
                severity error \
                code too_many_final_emails \
                contact_name $contact_name \
                message "Final round has $final_email_count email messages; maximum is 1"]
        }
    }

    # ── Email guard rails (existing checks) ──

    set email_re {^[^@\s]+@[^@\s]+\.[^@\s]+$}
    # RFC 2606 reserves example.{com,org,net,edu}, test.*, invalid.*, localhost.*
    # for documentation and testing. Plus common stub domains humans type as
    # placeholders. Kept deliberately short — false positives here reject
    # legitimate sends.
    set placeholder_domains {example.com example.org example.net example.edu
        domain.com fake.com placeholder.com email.com yourcompany.com}
    # Local-part placeholders that are too generic to be real addresses.
    # Avoid common-English words ("test", "name", "unknown") — they match
    # legitimate mailbox conventions.
    set placeholder_locals {todo placeholder xxx tbd fixme placeholder-email
        your-email-here}
    set fr [spar::analyse_final_round $approach_data]
    set to_addresses [dict get $fr to_addresses]

    foreach addr $to_addresses {
        set addr_trimmed [string trim $addr]
        if {$addr_trimmed eq ""} continue

        if {![regexp $email_re $addr_trimmed]} {
            lappend issues [dict create \
                severity error \
                code placeholder_to \
                contact_name $contact_name \
                message "Approach file has non-email to: address '$addr_trimmed'"]
            continue
        }

        set addr_lc [string tolower $addr_trimmed]
        set at_idx [string first "@" $addr_lc]
        set local  [string range $addr_lc 0 [expr {$at_idx - 1}]]
        set domain [string range $addr_lc [expr {$at_idx + 1}] end]
        if {$domain in $placeholder_domains || $local in $placeholder_locals} {
            lappend issues [dict create \
                severity error \
                code placeholder_to \
                contact_name $contact_name \
                message "Approach to: '$addr_trimmed' looks like a placeholder (reserved domain or stub local-part)"]
            continue
        }

        if {$roster_email ne "" && [string first "@" $roster_email] >= 0} {
            if {[string tolower $addr_trimmed] ne [string tolower $roster_email]} {
                lappend issues [dict create \
                    severity warning \
                    code email_desync \
                    contact_name $contact_name \
                    message "Approach to: '$addr_trimmed' differs from roster email '$roster_email'"]
            }
        }
    }

    # ── generated_for guard rail (issue #30) ──
    # Recorded at generation; compared against current roster values to
    # detect roster edits that post-date the approach file.
    if {[dict exists $approach_data generated_for]} {
        set _gf [dict get $approach_data generated_for]
        set _gf_name ""
        set _gf_org  ""
        if {[llength $_gf] % 2 == 0} {
            if {[dict exists $_gf contact_name]} {
                set _gf_name [string trim [dict get $_gf contact_name]]
            }
            if {[dict exists $_gf organisation]} {
                set _gf_org [string trim [dict get $_gf organisation]]
            }
        }
        if {$_gf_name ne "" && $contact_name ne "" \
                && [string tolower $_gf_name] ne [string tolower $contact_name]} {
            lappend issues [dict create \
                severity warning \
                code name_desync \
                contact_name $contact_name \
                message "Approach generated_for.contact_name '$_gf_name' differs from roster contact_name '$contact_name'"]
        }
        if {$_gf_org ne "" && $roster_organisation ne "" \
                && [string tolower $_gf_org] ne [string tolower $roster_organisation]} {
            lappend issues [dict create \
                severity warning \
                code org_desync \
                contact_name $contact_name \
                message "Approach generated_for.organisation '$_gf_org' differs from roster organisation '$roster_organisation'"]
        }
    } else {
        lappend issues [dict create \
            severity error \
            code missing_generated_for \
            contact_name $contact_name \
            message "Approach file missing required 'generated_for' key (see spar-A-approach.md §6)"]
    }

    return $issues
}

# ─────────────────────────────────────────────────────────────────────────────
# Profile validation (SmartLayer/aesop#45)
# Mirrors the approach validator: closed-vocabulary front matter + staleness
# check against the current roster row. Per state-machine.md §Design by
# Contract, this is the post-check for the P-phase AI call.
# ─────────────────────────────────────────────────────────────────────────────

# _profile_canonical_keys -- single source of truth for profile front-matter vocabulary.
# Keyed by level; must stay in sync with spar-P-profile.md §5.1.
proc spar::_profile_canonical_keys {} {
    return [dict create \
        root {profile_date star_rating richness richness_count warmth_finding applicable_angles dependent_data} \
        dependent_data {contact_name organisation role date_excluded}]
}

# _check_profile_unknown_keys -- mirror of _check_unknown_keys, profile vocabulary.
proc spar::_check_profile_unknown_keys {data level contact_name} {
    set issues {}
    set canon [spar::_profile_canonical_keys]
    if {![dict exists $canon $level]} { return $issues }
    set known [dict get $canon $level]
    if {[llength $data] % 2 != 0} { return $issues }
    foreach {k _v} $data {
        if {$k in $known} continue
        set found_at ""
        dict for {lvl keys} $canon {
            if {$lvl eq $level} continue
            if {$k in $keys} { set found_at $lvl; break }
        }
        if {$found_at ne ""} {
            lappend issues [dict create \
                severity error \
                code wrong_level \
                contact_name $contact_name \
                message "'$k' at $level belongs at $found_at; move it there"]
        } else {
            lappend issues [dict create \
                severity error \
                code unknown_key_$level \
                contact_name $contact_name \
                message "unknown key '$k' at $level — not in canonical vocabulary"]
        }
    }
    return $issues
}

# read_profile_front_matter -- extract and parse the YAML front-matter block
# of a profile file. Returns parsed dict, or "" on any failure (missing file,
# missing fences, YAML parse error).
proc spar::read_profile_front_matter {path} {
    if {![file exists $path]} { return "" }
    set fd {}
    if {[catch {
        set fd [open $path r]
        fconfigure $fd -encoding utf-8
        set raw [read $fd]
        close $fd
        set fd {}
    } err]} {
        if {$fd ne ""} { catch {close $fd} }
        return ""
    }
    set lines [split $raw \n]
    if {[llength $lines] < 2} { return "" }
    if {[string trim [lindex $lines 0]] ne "---"} { return "" }
    set fm_lines {}
    set closed 0
    for {set i 1} {$i < [llength $lines]} {incr i} {
        set line [lindex $lines $i]
        if {[string trim $line] eq "---"} {
            set closed 1
            break
        }
        lappend fm_lines $line
    }
    if {!$closed} { return "" }
    set fm_text [join $fm_lines \n]
    set data ""
    if {[catch { set data [::yaml::yaml2dict $fm_text] } err]} {
        return ""
    }
    return $data
}

# _roster_field_current -- fetch and de-quote a roster field from a row dict.
# TSV loaders sometimes wrap blanks in `""`; strip the artifact.
proc spar::_roster_field_current {row field} {
    set v [string trim [spar::dict_get_default $row $field ""]]
    if {[regexp {^"(.*)"$} $v -> inner]} {
        set v [string trim $inner]
    }
    return $v
}

# _profile_is_stale -- return 1 iff any dependent_data field in the profile's
# front matter diverges from the corresponding roster field. Used by
# classify_contact to decide PROFILED vs PROFILE_STALE. Missing/malformed
# front matter returns 0 (validate_profile reports malformed separately).
proc spar::_profile_is_stale {profile_path roster_row} {
    if {$profile_path eq "" || ![file exists $profile_path]} { return 0 }
    set fm [spar::read_profile_front_matter $profile_path]
    if {$fm eq "" || ![dict exists $fm dependent_data]} { return 0 }
    set dep [dict get $fm dependent_data]
    if {[llength $dep] % 2 != 0} { return 0 }

    foreach field {contact_name organisation role} {
        if {![dict exists $dep $field]} continue
        set snap [dict get $dep $field]
        if {[spar::is_null $snap]} { set snap "" }
        set cur [spar::_roster_field_current $roster_row $field]
        if {$snap ne $cur} { return 1 }
    }
    # date_excluded: asymmetric — stale only when snapshot had a date and
    # current is empty (contact was re-validated after an exclusion episode).
    if {[dict exists $dep date_excluded]} {
        set snap [dict get $dep date_excluded]
        set cur [spar::_roster_field_current $roster_row date_excluded]
        set snap_has_date [expr {![spar::is_null $snap] && $snap ne ""}]
        set cur_has_date [expr {![spar::is_null $cur] && $cur ne ""}]
        if {$snap_has_date && !$cur_has_date} { return 1 }
    }
    return 0
}

# validate_profile -- check a single profile file against the front-matter
# contract. Emits malformed (errors) and stale (warnings) issues.
#
# profile_path   path to the profile .md file
# roster_row     dict of the contact's roster row (for dependent_data comparison)
# contact_name   for error messages
#
# Returns a list of issue dicts with keys: severity, code, contact_name, message.
#
proc spar::validate_profile {profile_path roster_row contact_name} {
    set issues {}
    if {$profile_path eq "" || ![file exists $profile_path]} {
        return $issues
    }

    # Read raw to distinguish "missing fences" from "YAML parse failure".
    set fd {}
    set raw ""
    if {[catch {
        set fd [open $profile_path r]
        fconfigure $fd -encoding utf-8
        set raw [read $fd]
        close $fd
        set fd {}
    } err]} {
        if {$fd ne ""} { catch {close $fd} }
        lappend issues [dict create severity error code invalid_front_matter \
            contact_name $contact_name \
            message "Profile file could not be read: $err"]
        return $issues
    }

    set lines [split $raw \n]
    if {[llength $lines] < 2 || [string trim [lindex $lines 0]] ne "---"} {
        lappend issues [dict create severity error code invalid_front_matter \
            contact_name $contact_name \
            message "Profile missing YAML front matter — first line must be '---'"]
        return $issues
    }

    set fm [spar::read_profile_front_matter $profile_path]
    if {$fm eq ""} {
        lappend issues [dict create severity error code invalid_front_matter \
            contact_name $contact_name \
            message "Profile front matter fences malformed or YAML did not parse"]
        return $issues
    }

    # Closed-vocabulary walk.
    lappend issues {*}[spar::_check_profile_unknown_keys $fm root $contact_name]
    if {[dict exists $fm dependent_data]} {
        set _dep [dict get $fm dependent_data]
        if {[llength $_dep] % 2 == 0} {
            lappend issues {*}[spar::_check_profile_unknown_keys $_dep dependent_data $contact_name]
        }
    }

    # Required keys at root.
    foreach req {profile_date star_rating richness richness_count warmth_finding applicable_angles dependent_data} {
        if {![dict exists $fm $req]} {
            lappend issues [dict create severity error code missing_${req} \
                contact_name $contact_name \
                message "Profile front matter missing required key '${req}'"]
        }
    }

    # Enum checks.
    if {[dict exists $fm richness]} {
        set r [dict get $fm richness]
        if {$r ni {rich medium thin}} {
            lappend issues [dict create severity error code invalid_richness \
                contact_name $contact_name \
                message "richness '$r' — must be rich, medium, or thin"]
        }
    }
    if {[dict exists $fm warmth_finding]} {
        set w [dict get $fm warmth_finding]
        if {$w ni {existing prior known-of cold}} {
            lappend issues [dict create severity error code invalid_warmth_finding \
                contact_name $contact_name \
                message "warmth_finding '$w' — must be existing, prior, known-of, or cold"]
        }
    }
    if {[dict exists $fm star_rating]} {
        set s [dict get $fm star_rating]
        if {![string is integer -strict $s] || $s < 1 || $s > 5} {
            lappend issues [dict create severity error code invalid_star_rating \
                contact_name $contact_name \
                message "star_rating '$s' — must be integer 1..5 (0 never appears; excluded contacts have no profile)"]
        }
    }

    # richness/richness_count consistency (warning).
    if {[dict exists $fm richness] && [dict exists $fm richness_count]} {
        set r [dict get $fm richness]
        set rc [dict get $fm richness_count]
        if {[string is integer -strict $rc]} {
            set mismatch 0
            if {$r eq "thin"   && $rc >= 5} { set mismatch 1 }
            if {$r eq "medium" && ($rc < 3 || $rc > 7)} { set mismatch 1 }
            if {$r eq "rich"   && $rc < 6} { set mismatch 1 }
            if {$mismatch} {
                lappend issues [dict create severity warning code richness_count_mismatch \
                    contact_name $contact_name \
                    message "richness '$r' inconsistent with richness_count $rc"]
            }
        }
    }

    # Reachability (#39 R1): a profile exists only if P honoured §4.4a —
    # either the roster row has a reachable channel (email, linkedin_url,
    # facebook_url, or phone for the phone-only path) or date_excluded is
    # set. A profile next to an all-empty row means P produced a profile
    # for an unreachable contact without recording the exclusion.
    # Skip when called without a matching roster row (orphan profiles are
    # reported by a separate check).
    if {[dict size $roster_row] > 0} {
        set _email [spar::_roster_field_current $roster_row email]
        set _li    [spar::_roster_field_current $roster_row linkedin_url]
        set _fb    [spar::_roster_field_current $roster_row facebook_url]
        set _ph    [spar::_roster_field_current $roster_row phone]
        set _excl  [spar::_roster_field_current $roster_row date_excluded]
        if {![string match *@* $_email] && $_li eq "" && $_fb eq "" \
            && $_ph eq "" && $_excl eq ""} {
            lappend issues [dict create severity error \
                code profile_unreachable_without_exclusion \
                contact_name $contact_name \
                message "Profile exists but roster row has no email/LinkedIn/Facebook/phone and no date_excluded — SPAR-P §4.4a requires either setting date_excluded='no reachable channel (YYYY-MM-DD)' or backfilling a channel"]
        }
    }

    # Staleness: compare dependent_data snapshot to the current roster row.
    if {[dict exists $fm dependent_data]} {
        set dep [dict get $fm dependent_data]
        if {[llength $dep] % 2 == 0} {
            foreach field {contact_name organisation role} {
                if {![dict exists $dep $field]} continue
                set snap [dict get $dep $field]
                if {[spar::is_null $snap]} { set snap "" }
                set cur [spar::_roster_field_current $roster_row $field]
                if {$snap ne $cur} {
                    lappend issues [dict create severity warning code stale_${field} \
                        contact_name $contact_name \
                        message "snapshot ${field} '$snap' ≠ current roster '$cur' — profile may be stale"]
                }
            }
            if {[dict exists $dep date_excluded]} {
                set snap [dict get $dep date_excluded]
                set cur [spar::_roster_field_current $roster_row date_excluded]
                set snap_has_date [expr {![spar::is_null $snap] && $snap ne ""}]
                set cur_has_date [expr {![spar::is_null $cur] && $cur ne ""}]
                if {$snap_has_date && !$cur_has_date} {
                    lappend issues [dict create severity warning code stale_date_excluded \
                        contact_name $contact_name \
                        message "profile snapshot had date_excluded='$snap'; roster now empty — contact re-validated, re-profile"]
                }
            }
        }
    }

    return $issues
}

# _profile_validation_error -- return first error-severity validation message for
# the profile of a classified contact, or "" if none. Mirrors
# _approach_validation_error. Used by DbC-Post handlers and by downstream
# gatekeeping (not currently wired to any T-transition, but available).
proc spar::_profile_validation_error {contact} {
    set pp [spar::dict_get_default $contact profile_path ""]
    if {$pp eq ""} { return "" }
    set cname [spar::dict_get_default $contact contact_name ""]
    foreach issue [spar::validate_profile $pp $contact $cname] {
        if {[dict get $issue severity] eq "error"} {
            return [dict get $issue message]
        }
    }
    return ""
}

# validate_campaign_semantics -- cross-file checks only; no per-file approach validation.
# Used by progress/warnings paths where per-file schema validation is out of scope
# (per issue SmartLayer/aesop#43 principle 6).
proc spar::validate_campaign_semantics {all_classified_contacts} {
    return [spar::validate_campaign $all_classified_contacts 0 0]
}

# validate_campaign -- run validation checks across all classified contacts.
#
# all_classified_contacts  flat list from classify_segment across one or more segments
#                          (each dict has _segment_dir set)
# include_approach         when 1 (default), delegate per-file approach validation to
#                          validate_approach. When 0, skip — used by progress.
# include_profile          when 1 (default), delegate per-file profile validation to
#                          validate_profile. When 0, skip — used by progress.
#
# Returns a list of issue dicts, each with keys:
#   severity, code, segment, contact_name, message
#
proc spar::validate_campaign {all_classified_contacts {include_approach 1} {include_profile 1}} {
    set issues {}

    # Collect per-segment data for orphan checks
    array set seg_stems {}   ;# segment_dir → list of stem values
    array set seg_dirs_seen {}       ;# segment_dir → 1

    foreach contact $all_classified_contacts {
        set state [spar::dict_get_default $contact state ""]
        set segment_dir [spar::dict_get_default $contact _segment_dir ""]
        set segment [file tail $segment_dir]
        set contact_name [spar::dict_get_default $contact contact_name ""]
        set roster_email [string trim [spar::dict_get_default $contact email ""]]
        set roster_org [string trim [spar::dict_get_default $contact organisation ""]]
        set stem [string trim [spar::dict_get_default $contact stem ""]]

        # Track segment directories and stems for orphan checks
        set seg_dirs_seen($segment_dir) 1
        if {$stem ne ""} {
            lappend seg_stems($segment_dir) $stem
        }

        # Skip EXCLUDED contacts for checks 1, 2, 3
        if {$state eq "EXCLUDED"} continue

        # Check 3: merged_contact_name
        if {[string first " & " $contact_name] >= 0} {
            lappend issues [dict create \
                severity warning \
                code merged_contact_name \
                segment $segment \
                contact_name $contact_name \
                message "Contact name contains ' & ' — may be two people entered as one row"]
        }

        # Check 6: masked_email — roster email contains * (redacted/masked)
        if {[spar::is_masked_email $roster_email]} {
            lappend issues [dict create \
                severity error \
                code masked_email \
                segment $segment \
                contact_name $contact_name \
                message "Roster email '$roster_email' appears masked (contains '*')"]
        }

        # Checks 1 and 2: delegate to validate_approach (skipped when include_approach=0)
        if {$include_approach} {
            set approach_path [spar::dict_get_default $contact approach_path ""]
            foreach issue [spar::validate_approach $approach_path $roster_email $contact_name $roster_org] {
                dict set issue segment $segment
                lappend issues $issue
            }
        }

        # Profile validation (skipped when include_profile=0). State PROFILE_STALE
        # still emits through validate_profile's stale_* warnings; DISCOVERED has
        # no profile file so validate_profile no-ops.
        if {$include_profile} {
            set profile_path [spar::dict_get_default $contact profile_path ""]
            foreach issue [spar::validate_profile $profile_path $contact $contact_name] {
                dict set issue segment $segment
                lappend issues $issue
            }
        }
    }

    # Roster quality-checklist assertions (per-segment)
    array set seg_contacts {}
    foreach contact $all_classified_contacts {
        set sd [spar::dict_get_default $contact _segment_dir ""]
        lappend seg_contacts($sd) $contact
    }
    foreach sd [array names seg_contacts] {
        foreach issue [spar::validate_roster $seg_contacts($sd)] {
            lappend issues $issue
        }
    }

    # Check 4: orphan_profile
    foreach segment_dir [array names seg_dirs_seen] {
        set segment [file tail $segment_dir]
        set profile_dir [file join $segment_dir profiles]
        set known_profile_names {}
        if {[info exists seg_stems($segment_dir)]} {
            foreach s $seg_stems($segment_dir) {
                lappend known_profile_names $s
            }
        }

        foreach f [glob -nocomplain [file join $profile_dir *.md]] {
            set filestem [file rootname [file tail $f]]
            # Skip legacy profile-* files during migration window — they are reference
            # artefacts, not authoritative profiles. The classifier reads {stem}.md only.
            if {[string match "profile-*" $filestem]} continue
            if {$filestem ni $known_profile_names} {
                lappend issues [dict create \
                    severity warning \
                    code orphan_profile \
                    segment $segment \
                    contact_name "" \
                    message "Profile file '${filestem}.md' not referenced by any roster row"]
            }
        }
    }

    # Check 5: orphan_approach
    foreach segment_dir [array names seg_dirs_seen] {
        set segment [file tail $segment_dir]
        set approach_dir [file join $segment_dir approach]
        set known_stems {}
        if {[info exists seg_stems($segment_dir)]} {
            set known_stems $seg_stems($segment_dir)
        }

        foreach f [glob -nocomplain [file join $approach_dir *.yaml]] {
            set filestem [file rootname [file tail $f]]
            if {$filestem ni $known_stems} {
                lappend issues [dict create \
                    severity warning \
                    code orphan_approach \
                    segment $segment \
                    contact_name "" \
                    message "Approach file '${filestem}.yaml' not referenced by any roster row"]
            }
        }
    }

    return $issues
}

# validate_roster -- roster quality-checklist assertions (spar-roster-format.md §Quality checklist).
#
# segment_contacts  list of classified contact dicts for ONE segment
#                   (each dict has _segment_dir, state, and all roster fields)
#
# Returns a list of issue dicts, same format as validate_campaign.
#
proc spar::validate_roster {segment_contacts} {
    set issues {}
    if {[llength $segment_contacts] == 0} {
        return $issues
    }
    set segment_dir [spar::dict_get_default [lindex $segment_contacts 0] _segment_dir ""]
    set segment [file tail $segment_dir]

    # Accumulators for cross-row checks
    set seen_name_org {}  ;# list of "name|org" keys (lowercased)
    set seen_stems {}     ;# list of stem values

    foreach contact $segment_contacts {
        set state [spar::dict_get_default $contact state ""]
        set contact_name [string trim [spar::dict_get_default $contact contact_name ""]]
        set org [string trim [spar::dict_get_default $contact organisation ""]]
        set email [string trim [spar::dict_get_default $contact email ""]]
        set linkedin [string trim [spar::dict_get_default $contact linkedin_url ""]]
        set facebook [string trim [spar::dict_get_default $contact facebook_url ""]]
        set phone [string trim [spar::dict_get_default $contact phone ""]]
        set sweep [string trim [spar::dict_get_default $contact sweep_iteration ""]]
        set verified [string trim [spar::dict_get_default $contact verified ""]]
        set date_invalid [string trim [spar::dict_get_default $contact date_excluded ""]]
        set star [string trim [spar::dict_get_default $contact star_rating ""]]
        set response_likelihood [string trim [spar::dict_get_default $contact response_likelihood ""]]
        set stem [string trim [spar::dict_get_default $contact stem ""]]
        set field_count_warning [spar::dict_get_default $contact _field_count_warning ""]

        # Assertion 2: extra fields (truncated rows are hard errors in load_roster)
        if {$field_count_warning ne ""} {
            lappend issues [dict create \
                severity warning \
                code roster_extra_fields \
                segment $segment \
                contact_name $contact_name \
                message "Roster row $field_count_warning"]
        }

        # Assertion 9: non-empty stem (hard error)
        if {$stem eq ""} {
            lappend issues [dict create \
                severity error \
                code roster_empty_stem \
                segment $segment \
                contact_name $contact_name \
                message "Roster row has empty stem"]
        }

        # Assertion 10: duplicate stems
        if {$stem ne ""} {
            if {$stem in $seen_stems} {
                lappend issues [dict create \
                    severity error \
                    code roster_duplicate_stem \
                    segment $segment \
                    contact_name $contact_name \
                    message "Duplicate stem '$stem' in segment"]
            }
            lappend seen_stems $stem
        }

        # Assertion 6: verified=yes without conflicting date_excluded
        if {[string tolower $verified] eq "yes" && $date_invalid ne ""} {
            lappend issues [dict create \
                severity warning \
                code roster_verified_but_invalid \
                segment $segment \
                contact_name $contact_name \
                message "Contact is verified=yes but has date_excluded set"]
        }

        # Assertion 6 (cont.): verified=yes but p_note indicates role exit
        set p_note [string trim [spar::dict_get_default $contact p_note ""]]
        if {[string tolower $verified] eq "yes" && $p_note ne ""} {
            if {[regexp -nocase {\y(no longer|left|departed|replaced by|moved to)\y} $p_note]} {
                lappend issues [dict create \
                    severity warning \
                    code roster_verified_but_departed \
                    segment $segment \
                    contact_name $contact_name \
                    message "Contact is verified=yes but p_note indicates role exit"]
            }
        }

        # Skip EXCLUDED for assertions that require a valid contact
        if {$state eq "EXCLUDED"} continue

        # Assertion 1: non-empty contact_name (unless blank + org known — P §4.0b will resolve),
        # and not a placeholder
        set is_blank_with_org [expr {$contact_name eq "" && $org ne ""}]
        if {(!$is_blank_with_org && $contact_name eq "") \
                || [string tolower $contact_name] in {unknown n/a tbd placeholder}} {
            lappend issues [dict create \
                severity warning \
                code roster_placeholder_name \
                segment $segment \
                contact_name $contact_name \
                message "Contact name is empty or a placeholder"]
        }

        # Assertion 3: duplicate (contact_name, organisation) pair.
        # Within-segment case 1 (issue #5): same person, same org ⇒ true
        # duplicate. Error severity so ProfileHarness::validate_and_correct
        # refuses to ship the second profile; human resolves by excluding
        # or merging one row.
        set name_org_key "[string tolower $contact_name]|[string tolower $org]"
        if {$name_org_key in $seen_name_org} {
            lappend issues [dict create \
                severity error \
                code roster_duplicate_name_org \
                category case_1 \
                segment $segment \
                contact_name $contact_name \
                message "True duplicate: (contact_name, organisation) pair repeats in segment"]
        }
        lappend seen_name_org $name_org_key

        # Assertion 4: at least one of email, linkedin_url, facebook_url, phone
        if {![string match *@* $email] && $linkedin eq "" && $facebook eq "" && $phone eq ""} {
            lappend issues [dict create \
                severity warning \
                code roster_no_channel \
                segment $segment \
                contact_name $contact_name \
                message "Profile has no email, LinkedIn, Facebook, or phone"]
        }

        # Assertion 5: sweep_iteration has a value
        if {$sweep eq ""} {
            lappend issues [dict create \
                severity warning \
                code roster_no_sweep_iteration \
                segment $segment \
                contact_name $contact_name \
                message "Contact has no sweep_iteration value"]
        }

        # Assertion 7: response_likelihood implies star_rating
        if {$response_likelihood ne "" && $response_likelihood ne "0"} {
            if {$star eq ""} {
                lappend issues [dict create \
                    severity warning \
                    code roster_likelihood_without_star \
                    segment $segment \
                    contact_name $contact_name \
                    message "Contact has response_likelihood but no star_rating"]
            }
        }

        # Assertion 8: star_rating=0 implies date_excluded
        if {[string is integer -strict $star] && $star == 0 && $date_invalid eq ""} {
            lappend issues [dict create \
                severity warning \
                code roster_zero_star_no_invalid \
                segment $segment \
                contact_name $contact_name \
                message "Contact has star_rating=0 but no date_excluded"]
        }
    }

    # Within-segment email categorisation (issue #5).
    # Scope is deliberately segment-local in this pass; cross-segment is
    # tracked as follow-up. Groups rows sharing the same normalised email,
    # then classifies each group:
    #   case_2 (error): same org, different name → shared org inbox.
    #                   Resolved per spar-P-profile.md §4.11 shared-inbox
    #                   rule (find a non-shared alternate, or leave empty).
    #   case_3 (warning): same normalised name, different org → same
    #                   person reached via multiple affiliations sharing
    #                   one personal email. Human judgement; not solved.
    # case_1 (same name + same org) is already caught above as
    # roster_duplicate_name_org.
    array set _email_group {}
    foreach contact $segment_contacts {
        set state [spar::dict_get_default $contact state ""]
        if {$state eq "EXCLUDED"} continue
        set _name [string trim [spar::dict_get_default $contact contact_name ""]]
        if {$_name eq ""} continue
        set _org [string trim [spar::dict_get_default $contact organisation ""]]
        set _email [string trim [string tolower [spar::dict_get_default $contact email ""]]]
        if {$_email eq "" || [string first "@" $_email] < 0} continue
        lappend _email_group($_email) [list $_name $_org]
    }
    foreach _email [array names _email_group] {
        set _rows $_email_group($_email)
        if {[llength $_rows] < 2} continue
        foreach _row $_rows {
            lassign $_row _name _org
            set _name_norm [spar::normalise_name $_name]
            set _org_norm [string tolower $_org]
            set _saw_shared_inbox 0
            set _saw_personal_reuse 0
            foreach _other $_rows {
                if {$_other eq $_row} continue
                lassign $_other _oname _oorg
                set _oname_norm [spar::normalise_name $_oname]
                set _oorg_norm [string tolower $_oorg]
                if {$_name_norm eq $_oname_norm && $_org_norm eq $_oorg_norm} {
                    # Same (name, org) — already flagged as case_1 above; skip.
                    continue
                }
                if {$_org_norm eq $_oorg_norm && $_name_norm ne $_oname_norm} {
                    set _saw_shared_inbox 1
                    continue
                }
                if {$_name_norm eq $_oname_norm && $_org_norm ne $_oorg_norm} {
                    set _saw_personal_reuse 1
                    continue
                }
            }
            if {$_saw_shared_inbox} {
                lappend issues [dict create \
                    severity error \
                    code roster_shared_inbox_collision \
                    category case_2 \
                    segment $segment \
                    contact_name $_name \
                    message "Shared inbox: '$_email' is also used by another contact at the same organisation in this segment"]
            }
            if {$_saw_personal_reuse} {
                lappend issues [dict create \
                    severity warning \
                    code roster_personal_email_reused \
                    category case_3 \
                    segment $segment \
                    contact_name $_name \
                    message "Personal email reused: '$_email' is also used by the same person under a different organisation in this segment"]
            }
        }
    }

    return $issues
}

# build_warnings -- combined duplicates + validation as displayable strings.
#
# all_classified_contacts  flat list from classify_segment across segments
#
# Returns a dict:
#   messages           — flat list of human-readable warning strings
#   duplicate_to       — count of duplicate To: address warnings
#   duplicate_name     — count of duplicate name warnings
#   duplicate_email    — count of duplicate email warnings
#   identical_subject  — count of identical subject warnings
#   validation_errors  — count of validation errors
#   validation_warnings — count of validation warnings
#
proc spar::build_warnings {all_classified_contacts} {
    set messages {}
    set dup_to_count 0
    set dup_name_count 0
    set dup_email_count 0
    set dup_subject_count 0
    set val_errors 0
    set val_warnings 0

    if {[llength $all_classified_contacts] == 0} {
        return [dict create messages {} \
            duplicate_to 0 duplicate_name 0 duplicate_email 0 \
            identical_subject 0 validation_errors 0 validation_warnings 0]
    }

    # Duplicates
    set dups [spar::detect_duplicates $all_classified_contacts]

    foreach item [dict get $dups duplicate_to] {
        set addr [dict get $item address]
        set files [dict get $item files]
        set locs {}
        foreach f $files {
            lassign $f seg filename
            lappend locs "$seg/$filename"
        }
        lappend messages "Duplicate To: $addr in [join $locs {, }]"
        incr dup_to_count
    }

    foreach item [dict get $dups duplicate_name] {
        set entries [dict get $item entries]
        set display_name [lindex [lindex $entries 0] 1]
        set parts {}
        foreach entry $entries {
            lassign $entry seg cname org email
            lappend parts "$seg ($org)"
        }
        lappend messages "Duplicate name: $display_name in [join $parts { and }]"
        incr dup_name_count
    }

    foreach item [dict get $dups duplicate_email] {
        set addr [dict get $item email]
        set entries [dict get $item entries]
        set parts {}
        foreach entry $entries {
            lassign $entry seg cname org
            lappend parts "$seg ($cname)"
        }
        lappend messages "Duplicate email: $addr in [join $parts { and }]"
        incr dup_email_count
    }

    foreach item [dict get $dups identical_subject] {
        set subj [dict get $item subject]
        set files [dict get $item files]
        set locs {}
        foreach f $files {
            lassign $f seg filename
            lappend locs "$seg/$filename"
        }
        lappend messages "Identical subject: \"$subj\" in [join $locs {, }]"
        incr dup_subject_count
    }

    # Validation — semantics only (cross-file). Per-file approach schema
    # validation is a transition dependency, not a progress concern (#43 principle 6).
    foreach issue [spar::validate_campaign_semantics $all_classified_contacts] {
        set sev [dict get $issue severity]
        set seg [spar::dict_get_default $issue segment ""]
        set cname [spar::dict_get_default $issue contact_name ""]
        set msg [dict get $issue message]
        set prefix "\[[string toupper $sev]\]"
        if {$seg ne ""} { append prefix " $seg" }
        if {$cname ne ""} { append prefix " ($cname)" }
        lappend messages "$prefix: $msg"
        if {$sev eq "error"} {
            incr val_errors
        } else {
            incr val_warnings
        }
    }

    return [dict create messages $messages \
        duplicate_to $dup_to_count duplicate_name $dup_name_count \
        duplicate_email $dup_email_count identical_subject $dup_subject_count \
        validation_errors $val_errors validation_warnings $val_warnings]
}

package provide spar-state 1.0
