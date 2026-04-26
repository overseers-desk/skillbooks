# spar-validate.tcl — Validators for SPAR campaign artefacts: approach
# YAML, profile front matter, roster TSV, campaign-level cross-checks,
# sender block, and aggregated warnings. Sourced by spar-state.tcl which
# provides the dict_get_default / readers used here.
#
# This file owns _approach_validation_error and _profile_validation_error
# — thin wrappers used by the per-class transition `eligible` methods to
# pre-flight an approach/profile before reporting a contact as ready.

package require sha256

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
        if {[dict get $issue severity] ne "error"} continue
        return [dict get $issue message]
    }
    return ""
}

# _issue -- factory for validator issue dicts. Every issue carries severity,
# code, contact_name, message; extra accommodates {segment $segment} and
# {category case_N} variants without every call site spelling them.
proc spar::_issue {severity code contact_name message {extra {}}} {
    set d [dict create severity $severity code $code \
        contact_name $contact_name message $message]
    if {[llength $extra] > 0} {
        foreach {k v} $extra { dict set d $k $v }
    }
    return $d
}

# _approach_canonical_keys -- single source of truth for approach YAML vocabulary.
# Per issues SmartLayer/aesop#43 (closed vocabulary) and #63 (replicas retired in
# favour of profile_hash linkage).
proc spar::_approach_canonical_keys {} {
    return [dict create \
        root {decisions rounds angle_rationale a_note fact_provenance quality_checklist profile_hash} \
        decisions {channel language angle sender channel_detail subsegment} \
        round {type number messages verdict fact_check in_character chosen_usps revision_note notes replies antifact_check} \
        message {channel subject body to actioned_date replied_date reply_summary script text char_count bcc cc director_note to_note phone_note mode parent reply_all} \
        parent {account folder uid message_id references subject from to cc} \
        fact_provenance_item {claim source} \
        fact_check_item {claim source result note correction} \
        script_item {point text}]
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
            lappend issues [spar::_issue error wrong_level $contact_name \
                "'$k' at $level belongs at $found_at; move it there"]
        } else {
            lappend issues [spar::_issue error unknown_key_$level $contact_name \
                "unknown key '$k' at $level — not in canonical vocabulary"]
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
        lappend issues [spar::_issue error invalid_yaml $contact_name \
            "Approach file could not be parsed as YAML"]
        return $issues
    }

    # ── Closed-vocabulary walk (approach-schema.yaml) ──
    # Emits unknown_key_<level> / wrong_level issues. Per #43 principle 1.

    lappend issues {*}[spar::_check_unknown_keys $approach_data root $contact_name]

    if {[dict exists $approach_data decisions]} {
        set _dec [dict get $approach_data decisions]
        lappend issues {*}[spar::_check_unknown_keys $_dec decisions $contact_name]
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
                    if {[dict exists $_msg parent]} {
                        set _parent [dict get $_msg parent]
                        if {[llength $_parent] % 2 == 0} {
                            lappend issues {*}[spar::_check_unknown_keys $_parent parent $contact_name]
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
        lappend issues [spar::_issue error missing_decisions $contact_name \
            "Approach file missing required 'decisions' key"]
    }

    # rounds key must exist and be non-empty
    if {![dict exists $approach_data rounds]} {
        lappend issues [spar::_issue error missing_rounds $contact_name \
            "Approach file missing required 'rounds' key"]
        return $issues
    }
    set rounds [dict get $approach_data rounds]
    if {[llength $rounds] == 0} {
        lappend issues [spar::_issue error missing_rounds $contact_name \
            "Approach file has empty 'rounds' array"]
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
        lappend issues [spar::_issue error no_final_round $contact_name \
            "Approach file has no round with type: final"]
    }

    # Per-round checks
    foreach round $rounds {
        set rtype ""
        if {[dict exists $round type]} {
            set rtype [dict get $round type]
        }

        # Draft and review rounds require number
        if {$rtype eq "draft" && ![dict exists $round number]} {
            lappend issues [spar::_issue warning draft_missing_number $contact_name \
                "Draft round missing required 'number' field"]
        }
        if {$rtype eq "review" && ![dict exists $round number]} {
            lappend issues [spar::_issue warning review_missing_number $contact_name \
                "Review round missing required 'number' field"]
        }

        # Email messages must have content. For ordinary sends that means
        # both subject and body; for `mode: reply` the subject is derived
        # from the parent thread (Re: <parent.subject>), so only body is
        # required at the message level. A reply must carry a parent block
        # with a non-empty message_id — without it T3 cannot construct the
        # In-Reply-To / References headers that join the thread.
        set final_email_count 0
        if {[dict exists $round messages]} {
            foreach msg [dict get $round messages] {
                if {[dict exists $msg channel] && [dict get $msg channel] eq "email"} {
                    set is_reply [expr {[dict exists $msg mode] && \
                        [dict get $msg mode] eq "reply"}]
                    if {$is_reply} {
                        if {![dict exists $msg body]} {
                            lappend issues [spar::_issue warning email_missing_content $contact_name \
                                "Reply email message missing 'body'"]
                        }
                        set _parent [spar::dict_get_default $msg parent ""]
                        set _pmid [spar::dict_get_default $_parent message_id ""]
                        if {[string trim $_pmid] eq ""} {
                            lappend issues [spar::_issue error reply_missing_parent_message_id $contact_name \
                                "Reply email message has no parent.message_id; cannot thread the reply"]
                        }
                    } else {
                        if {![dict exists $msg subject] && ![dict exists $msg body]} {
                            lappend issues [spar::_issue warning email_missing_content $contact_name \
                                "Email message missing both 'subject' and 'body'"]
                        }
                    }
                    if {$rtype eq "final"} { incr final_email_count }
                }
            }
        }

        # Final round may have at most one email message. Follow-ups belong
        # in subsequent rounds; multi-recipient belongs in cc/bcc.
        if {$rtype eq "final" && $final_email_count > 1} {
            lappend issues [spar::_issue error too_many_final_emails $contact_name \
                "Final round has $final_email_count email messages; maximum is 1"]
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
            lappend issues [spar::_issue error placeholder_to $contact_name \
                "Approach file has non-email to: address '$addr_trimmed'"]
            continue
        }

        set addr_lc [string tolower $addr_trimmed]
        set at_idx [string first "@" $addr_lc]
        set local  [string range $addr_lc 0 [expr {$at_idx - 1}]]
        set domain [string range $addr_lc [expr {$at_idx + 1}] end]
        if {$domain in $placeholder_domains || $local in $placeholder_locals} {
            lappend issues [spar::_issue error placeholder_to $contact_name \
                "Approach to: '$addr_trimmed' looks like a placeholder (reserved domain or stub local-part)"]
            continue
        }

        if {$roster_email ne "" && [string first "@" $roster_email] >= 0} {
            if {[string tolower $addr_trimmed] ne [string tolower $roster_email]} {
                lappend issues [spar::_issue warning email_desync $contact_name \
                    "Approach to: '$addr_trimmed' differs from roster email '$roster_email'"]
            }
        }
    }

    # ── profile_hash linkage (issue #63) ──
    # When the approach carries profile_hash and the source profile is
    # present, mismatch is an error: the profile was rebuilt or edited
    # after the approach was drafted, so the approach references stale
    # angle evidence. profile_hash is optional — manually-authored
    # approaches and any path that did not read a profile have no hash
    # to record. Absent profile (no file at the expected path) is not
    # an error here; the state machine routes that through T6 → T7.
    if {[dict exists $approach_data profile_hash]} {
        set _stored [string trim [dict get $approach_data profile_hash]]
        set _stored_hex $_stored
        if {[regexp {^sha256:([0-9a-fA-F]+)$} $_stored -> _hex]} {
            set _stored_hex [string tolower $_hex]
        } else {
            set _stored_hex [string tolower $_stored]
        }
        set _seg_dir [file dirname [file dirname $approach_path]]
        set _stem [file rootname [file tail $approach_path]]
        set _profile_path [file join $_seg_dir profiles "${_stem}.md"]
        if {[file exists $_profile_path]} {
            set _actual [string tolower [::sha2::sha256 -hex -file $_profile_path]]
            if {$_actual ne $_stored_hex} {
                lappend issues [spar::_issue error profile_hash_mismatch $contact_name \
                    "Approach profile_hash 'sha256:$_stored_hex' does not match profile file (current sha256:$_actual) — re-approach required"]
            }
        }
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
        root {profile_date star_rating yield warmth_finding applicable_angles dependent_data} \
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
            lappend issues [spar::_issue error wrong_level $contact_name \
                "'$k' at $level belongs at $found_at; move it there"]
        } else {
            lappend issues [spar::_issue error unknown_key_$level $contact_name \
                "unknown key '$k' at $level — not in canonical vocabulary"]
        }
    }
    return $issues
}

# read_profile_front_matter -- extract and parse the YAML front-matter block
# of a profile file. Returns parsed dict, or "" on any failure (missing file,
# audit_skills_in_transcript -- count Skill tool_use invocations in a
# Claude session transcript. Returns a list of issue dicts (same shape
# as validate_profile output) with code "<skill>_lookup_missing" for
# each required skill that has zero invocations. If the transcript file
# is missing, returns a single warning-severity issue with code
# transcript_not_found rather than masquerading as a skill miss — a
# future Claude storage-layout change should not loop the agent.
#
# session_id      UUID returned by claude --output-format json
# required_skills list of skill IDs (e.g. {linkedin facebook})
# contact_name    for issue dicts (consumed by validate_and_correct)
#
# Glob by session_id rather than reconstructing the project_dir from
# pwd: the dispatcher does not chdir per-job, claude inherits the
# spar-manager launch cwd which is not deterministic from here. UUID
# v4 collision risk is negligible.
proc spar::audit_skills_in_transcript {session_id required_skills contact_name {transcripts_root ""}} {
    set issues {}
    if {$transcripts_root eq ""} {
        set transcripts_root [file join $::env(HOME) .claude projects]
    }
    set matches [glob -nocomplain \
        -directory $transcripts_root \
        -types f -- */${session_id}.jsonl]
    if {[llength $matches] == 0} {
        return [list [dict create severity warning code transcript_not_found \
            contact_name $contact_name \
            message "Session transcript $session_id.jsonl not found under ~/.claude/projects/*/ — audit skipped"]]
    }
    set transcript [lindex $matches 0]

    set counts [dict create]
    foreach s $required_skills { dict set counts $s 0 }

    set fd [open $transcript r]
    fconfigure $fd -encoding utf-8
    while {[gets $fd line] >= 0} {
        # Cheap prefilter — long P sessions are 100s KB to a few MB and
        # json::json2dict is slow per line. Skip lines that cannot
        # contain a Skill tool_use.
        if {![string match {*"name":"Skill"*} $line]} continue
        if {[catch {set d [::json::json2dict $line]}]} continue
        set msg [spar::dict_get_default $d message [dict create]]
        set content [spar::dict_get_default $msg content {}]
        foreach blk $content {
            if {[spar::dict_get_default $blk type ""] ne "tool_use"} continue
            if {[spar::dict_get_default $blk name ""] ne "Skill"} continue
            set input [spar::dict_get_default $blk input [dict create]]
            set sk [spar::dict_get_default $input skill ""]
            if {[dict exists $counts $sk]} {
                dict incr counts $sk
            }
        }
    }
    close $fd

    set sec [dict create linkedin §4.3 facebook §4.4]
    foreach s $required_skills {
        if {[dict get $counts $s] == 0} {
            set sref [spar::dict_get_default $sec $s "(spec)"]
            lappend issues [spar::_issue error "${s}_lookup_missing" $contact_name \
                "SPAR-P $sref requires the $s skill; transcript shows zero Skill invocations with input.skill=$s."]
        }
    }
    return $issues
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
        lappend issues [spar::_issue error invalid_front_matter $contact_name \
            "Profile file could not be read: $err"]
        return $issues
    }

    set lines [split $raw \n]
    if {[llength $lines] < 2 || [string trim [lindex $lines 0]] ne "---"} {
        lappend issues [spar::_issue error invalid_front_matter $contact_name \
            "Profile missing YAML front matter — first line must be '---'"]
        return $issues
    }

    set fm [spar::read_profile_front_matter $profile_path]
    if {$fm eq ""} {
        lappend issues [spar::_issue error invalid_front_matter $contact_name \
            "Profile front matter fences malformed or YAML did not parse"]
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
    foreach req {profile_date star_rating yield warmth_finding applicable_angles dependent_data} {
        if {![dict exists $fm $req]} {
            lappend issues [spar::_issue error missing_${req} $contact_name \
                "Profile front matter missing required key '${req}'"]
        }
    }

    # Enum checks.
    if {[dict exists $fm yield]} {
        set y [dict get $fm yield]
        if {![string is integer -strict $y] || $y < 0} {
            lappend issues [spar::_issue error invalid_yield $contact_name \
                "yield '$y' — must be a non-negative integer (data-point count per SPAR-P §4.14)"]
        }
    }
    if {[dict exists $fm warmth_finding]} {
        set w [dict get $fm warmth_finding]
        if {$w ni {existing prior known-of cold}} {
            lappend issues [spar::_issue error invalid_warmth_finding $contact_name \
                "warmth_finding '$w' — must be existing, prior, known-of, or cold"]
        }
    }
    if {[dict exists $fm star_rating]} {
        set s [dict get $fm star_rating]
        if {![string is integer -strict $s] || $s < 1 || $s > 5} {
            lappend issues [spar::_issue error invalid_star_rating $contact_name \
                "star_rating '$s' — must be integer 1..5 (0 never appears; excluded contacts have no profile)"]
        }
    }

    # Reachability (#39 R1): a profile exists only if P honoured §4.15 —
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
            lappend issues [spar::_issue error profile_unreachable_without_exclusion $contact_name \
                "Profile exists but roster row has no email/LinkedIn/Facebook/phone and no date_excluded — SPAR-P §4.15 requires either setting date_excluded='no reachable channel (YYYY-MM-DD)' or backfilling a channel"]
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
                    lappend issues [spar::_issue warning stale_${field} $contact_name \
                        "snapshot ${field} '$snap' ≠ current roster '$cur' — profile may be stale"]
                }
            }
            if {[dict exists $dep date_excluded]} {
                set snap [dict get $dep date_excluded]
                set cur [spar::_roster_field_current $roster_row date_excluded]
                set snap_has_date [expr {![spar::is_null $snap] && $snap ne ""}]
                set cur_has_date [expr {![spar::is_null $cur] && $cur ne ""}]
                if {$snap_has_date && !$cur_has_date} {
                    lappend issues [spar::_issue warning stale_date_excluded $contact_name \
                        "profile snapshot had date_excluded='$snap'; roster now empty — contact re-validated, re-profile"]
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

# validate_sender_block -- campaign-level sender schema checks. Pure
# schema validation, platform-agnostic — smtp_pass in YAML is not
# flagged here (environmental concern, handled in build_warnings /
# the gear dialog where the platform's keychain capability is known).
# Returns issue dicts in the same shape as validate_campaign, with
# empty segment/contact_name (these are campaign-level, not per-contact).
proc spar::validate_sender_block {cdata} {
    set issues {}
    if {![dict exists $cdata sender]} {
        lappend issues [spar::_issue error sender_missing "" \
            "sender: block missing from campaign.yaml — required for sending." \
            {segment ""}]
        return $issues
    }
    set sender [dict get $cdata sender]

    set smtp_host [string trim [spar::dict_get_default $sender smtp_host ""]]
    set smtp_user [string trim [spar::dict_get_default $sender smtp_user ""]]
    set smtp_port [spar::dict_get_default $sender smtp_port ""]

    if {$smtp_host eq ""} {
        lappend issues [spar::_issue error smtp_host_missing "" \
            "sender.smtp_host not set — required for sending." \
            {segment ""}]
    }
    if {$smtp_user eq ""} {
        lappend issues [spar::_issue error smtp_user_missing "" \
            "sender.smtp_user not set — required for sending; the keychain is keyed by (host, user)." \
            {segment ""}]
    }
    if {$smtp_port ne "" && ![string is integer -strict $smtp_port]} {
        lappend issues [spar::_issue warning smtp_port_non_numeric "" \
            "sender.smtp_port '$smtp_port' is not numeric — expected an integer port (e.g. 587)." \
            {segment ""}]
    }
    return $issues
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
            lappend issues [spar::_issue warning merged_contact_name $contact_name \
                "Contact name contains ' & ' — may be two people entered as one row" \
                [list segment $segment]]
        }

        # Check 6: masked_email — roster email contains * (redacted/masked)
        if {[spar::is_masked_email $roster_email]} {
            lappend issues [spar::_issue error masked_email $contact_name \
                "Roster email '$roster_email' appears masked (contains '*')" \
                [list segment $segment]]
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
        set profile_dir [spar::profile_dir_for_segment $segment_dir]
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
                lappend issues [spar::_issue warning orphan_profile "" \
                    "Profile file '${filestem}.md' not referenced by any roster row" \
                    [list segment $segment]]
            }
        }
    }

    # Check 5: orphan_approach
    foreach segment_dir [array names seg_dirs_seen] {
        set segment [file tail $segment_dir]
        set approach_dir [spar::approach_dir_for_segment $segment_dir]
        set known_stems {}
        if {[info exists seg_stems($segment_dir)]} {
            set known_stems $seg_stems($segment_dir)
        }

        foreach f [glob -nocomplain [file join $approach_dir *.yaml]] {
            set filestem [file rootname [file tail $f]]
            if {$filestem ni $known_stems} {
                lappend issues [spar::_issue warning orphan_approach "" \
                    "Approach file '${filestem}.yaml' not referenced by any roster row" \
                    [list segment $segment]]
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
        set date_invalid [string trim [spar::dict_get_default $contact date_excluded ""]]
        set star [string trim [spar::dict_get_default $contact star_rating ""]]
        set response_likelihood [string trim [spar::dict_get_default $contact response_likelihood ""]]
        set stem [string trim [spar::dict_get_default $contact stem ""]]
        set field_count_warning [spar::dict_get_default $contact _field_count_warning ""]

        # Assertion 2: extra fields (truncated rows are hard errors in load_roster)
        if {$field_count_warning ne ""} {
            lappend issues [spar::_issue warning roster_extra_fields $contact_name \
                "Roster row $field_count_warning" \
                [list segment $segment]]
        }

        # Assertion 9: non-empty stem (hard error)
        if {$stem eq ""} {
            lappend issues [spar::_issue error roster_empty_stem $contact_name \
                "Roster row has empty stem" \
                [list segment $segment]]
        }

        # Assertion 10: duplicate stems
        if {$stem ne ""} {
            if {$stem in $seen_stems} {
                lappend issues [spar::_issue error roster_duplicate_stem $contact_name \
                    "Duplicate stem '$stem' in segment" \
                    [list segment $segment]]
            }
            lappend seen_stems $stem
        }

        # Skip EXCLUDED for assertions that require a valid contact
        if {$state eq "EXCLUDED"} continue

        # Assertion 1: non-empty contact_name (unless blank + org known — P §4.1 will resolve),
        # and not a placeholder
        set is_blank_with_org [expr {$contact_name eq "" && $org ne ""}]
        if {(!$is_blank_with_org && $contact_name eq "") \
                || [string tolower $contact_name] in {unknown n/a tbd placeholder}} {
            lappend issues [spar::_issue warning roster_placeholder_name $contact_name \
                "Contact name is empty or a placeholder" \
                [list segment $segment]]
        }

        # Assertion 3: duplicate (contact_name, organisation) pair.
        # Within-segment case 1 (issue #5): same person, same org ⇒ true
        # duplicate. Error severity so ProfileHarness::validate_and_correct
        # refuses to ship the second profile; human resolves by excluding
        # or merging one row.
        set name_org_key "[string tolower $contact_name]|[string tolower $org]"
        if {$name_org_key in $seen_name_org} {
            lappend issues [spar::_issue error roster_duplicate_name_org $contact_name \
                "True duplicate: (contact_name, organisation) pair repeats in segment" \
                [list category case_1 segment $segment]]
        }
        lappend seen_name_org $name_org_key

        # Assertion 4: at least one of email, linkedin_url, facebook_url, phone
        if {![string match *@* $email] && $linkedin eq "" && $facebook eq "" && $phone eq ""} {
            lappend issues [spar::_issue warning roster_no_channel $contact_name \
                "Profile has no email, LinkedIn, Facebook, or phone" \
                [list segment $segment]]
        }

        # Assertion 5: sweep_iteration has a value
        if {$sweep eq ""} {
            lappend issues [spar::_issue warning roster_no_sweep_iteration $contact_name \
                "Contact has no sweep_iteration value" \
                [list segment $segment]]
        }

        # Assertion 7: response_likelihood implies star_rating
        if {$response_likelihood ne "" && $response_likelihood ne "0"} {
            if {$star eq ""} {
                lappend issues [spar::_issue warning roster_likelihood_without_star $contact_name \
                    "Contact has response_likelihood but no star_rating" \
                    [list segment $segment]]
            }
        }

        # Assertion 8: star_rating=0 implies date_excluded
        if {[string is integer -strict $star] && $star == 0 && $date_invalid eq ""} {
            lappend issues [spar::_issue warning roster_zero_star_no_invalid $contact_name \
                "Contact has star_rating=0 but no date_excluded" \
                [list segment $segment]]
        }
    }

    # Within-segment email categorisation (issue #5).
    # Scope is deliberately segment-local in this pass; cross-segment is
    # tracked as follow-up. Groups rows sharing the same normalised email,
    # then classifies each group:
    #   case_2 (error): same org, different name → shared org inbox.
    #                   Resolved per spar-P-profile.md §4.8 shared-inbox
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
                lappend issues [spar::_issue error roster_shared_inbox_collision $_name \
                    "Shared inbox: '$_email' is also used by another contact at the same organisation in this segment" \
                    [list category case_2 segment $segment]]
            }
            if {$_saw_personal_reuse} {
                lappend issues [spar::_issue warning roster_personal_email_reused $_name \
                    "Personal email reused: '$_email' is also used by the same person under a different organisation in this segment" \
                    [list category case_3 segment $segment]]
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
proc spar::build_warnings {all_classified_contacts {cdata {}}} {
    set messages {}
    set dup_to_count 0
    set dup_name_count 0
    set dup_email_count 0
    set dup_subject_count 0
    set val_errors 0
    set val_warnings 0

    # Campaign-level sender-block issues run even if the contact list is
    # empty (e.g. an unreadable campaign). Merge them into the messages
    # list first so they appear at the top.  The validator is platform-
    # agnostic; environmental (keychain-dependent) advice is the gear
    # dialog's job, not this utility.
    if {[llength $cdata] > 0} {
        foreach issue [spar::validate_sender_block $cdata] {
            set sev [dict get $issue severity]
            set msg [dict get $issue message]
            lappend messages "\[[string toupper $sev]\]: $msg"
            if {$sev eq "error"} { incr val_errors } else { incr val_warnings }
        }
    }

    if {[llength $all_classified_contacts] == 0} {
        return [dict create messages $messages \
            duplicate_to 0 duplicate_name 0 duplicate_email 0 \
            identical_subject 0 validation_errors $val_errors \
            validation_warnings $val_warnings]
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


package provide spar-validate 1.0
