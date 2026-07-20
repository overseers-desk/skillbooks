# spar-validate.tcl — Validators for SPAR campaign artefacts: approach
# YAML, profile front matter, roster TSV, campaign-level cross-checks,
# sender block, and aggregated warnings. Sourced by spar-state.tcl which
# provides the readers used here.
#
# This file owns _approach_validation_error and _profile_validation_error
# — thin wrappers used by the per-class transition `eligible` methods to
# pre-flight an approach/profile before reporting a contact as ready.

package require sha256

# yamlmuster is vendored beside the other modules in vendor/, found via the
# same search path spar-harness.tcl registers; spar-validate.tcl adds it too
# because the CLI, tests, GUI, and tpool parse workers source this file but not
# spar-harness.tcl. The line only registers a module search path (no I/O, no
# load); the actual `package require yamlmuster`, the instance, and the rules
# load are deferred to spar::_yamlmuster_approach on first validation, so
# sourcing this file, including in the tpool parse workers that never validate,
# costs nothing.
::tcl::tm::path add [file join [file dirname [file normalize [info script]]] .. vendor]

# Directory of this file, captured at source time so the lazy bootstrap can
# locate rules/approach.rules independent of the caller's cwd.
namespace eval spar { variable _validate_dir [file dirname [file normalize [info script]]] }

# approach_validation_error -- return first error-severity validation message for
# a contact's approach file, or "" if clean. Used by transition `eligible` methods
# to gate approach-dependent transitions (T6, T7, T8, T9, T10) on structural
# validity (#43 principle 7). Routes through approach_summary so the parse is
# shared with classify_contact and channel_readiness on the same render.
oo::define spar::State method approach_validation_error {contact} {
    set ap [dict getdef $contact approach_path ""]
    if {$ap eq "" || ![file exists $ap]} { return "" }
    set roster_email [string trim [dict getdef $contact email ""]]
    set cname [dict getdef $contact contact_name ""]
    set adata [my approach_summary $contact]
    if {$adata eq ""} {
        # Parse failure is itself an error, mirroring validate_approach_path's
        # invalid_yaml issue on a fresh parse miss.
        return "Approach file could not be parsed as YAML"
    }
    return [spar::_approach_gate_error $adata $ap $roster_email $cname]
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

# _yamlmuster_load -- read rules/<file> as UTF-8 and load it into $inst under
# $label. yamlmuster does no I/O: the host reads the rules file and passes the
# text. Shared by the four per-kind accessors; the predicate registrations that
# must precede the load stay in each accessor, since they differ by kind.
proc spar::_yamlmuster_load {inst file label} {
    variable _validate_dir
    set fd [open [file join $_validate_dir .. rules $file] r]
    fconfigure $fd -encoding utf-8
    set script [read $fd]
    close $fd
    $inst load $script -name $label
}

# ── yamlmuster rules-engine bootstrap (approach) ───────────────────────────
# The closed-vocabulary walk and the structural checks run on the yamlmuster
# rule engine over rules/approach.rules. The canonical vocabulary is the
# `level` declarations in that file; this proc is its single source of truth.
#
# One engine instance per document kind: every rules file declares `level
# root`, so a single instance loading all four kinds would fail on the
# duplicate root. This wave wires the approach kind only.
#
# Lazy: package require, predicate registration, and the rules load all happen
# on the first approach validation, never at source time, so the tpool parse
# workers that source this file but never validate pay nothing.
namespace eval spar { variable _yamlmuster_approach_inst "" }
proc spar::_yamlmuster_approach {} {
    variable _yamlmuster_approach_inst
    if {$_yamlmuster_approach_inst ne ""} {
        return $_yamlmuster_approach_inst
    }
    package require yamlmuster
    set inst [yamlmuster new]
    # Host predicates: the checks that read files or aggregate across levels,
    # which the declarative DSL cannot express. Registered before load so a
    # rules-file typo is a line-numbered load error, not a validate surprise.
    $inst predicate rounds_structural           ::spar::_pred_rounds_structural
    $inst predicate placeholder_to              ::spar::_pred_placeholder_to
    $inst predicate linkedin_guard              ::spar::_pred_linkedin_guard
    $inst predicate first_line_is_profile_hash  ::spar::_pred_first_line_is_profile_hash
    $inst predicate profile_hash_actual         ::spar::_pred_profile_hash_actual
    spar::_yamlmuster_load $inst approach.rules approach
    set _yamlmuster_approach_inst $inst
    return $inst
}

# _xlate_engine_issue -- project one yamlmuster issue dict back to spar's
# legacy _issue shape {severity code contact_name message}. Two engine codes
# need re-spelling to the tokens the test suite and the A/P fix-loop prompts
# depend on: the built-in `unknown_key` becomes `unknown_key_<level>` with the
# canonical-vocabulary wording recomposed from key+level, and `wrong_level`
# keeps its code but recomposes its message from key + owning level. Every
# other rule already carries its verbatim legacy message (rule -message
# templates and predicate-built strings), so those pass through untouched.
proc spar::_xlate_engine_issue {ei contact_name} {
    set sev  [dict get $ei severity]
    set code [dict get $ei code]
    set msg  [dict get $ei message]
    if {$code eq "unknown_key"} {
        set lvl  [dict get $ei level]
        set code "unknown_key_$lvl"
        set msg  "unknown key '[dict get $ei key]' at $lvl — not in canonical vocabulary"
    } elseif {$code eq "wrong_level"} {
        set lvl [dict get $ei level]
        set msg "'[dict get $ei key]' at $lvl belongs at [dict get $ei owner]; move it there"
    }
    return [spar::_issue $sev $code $contact_name $msg]
}

# _approach_gate_error -- the transition eligibility gate. Returns the first
# error-severity validation message for an approach dict, or "" if clean.
# Cost-limited: -severities error drops the warning-DECLARED rules before
# traversal and -limit 1 stops the walk at the first error, so the hot T6-T10
# path never evaluates the full ruleset. -badnode ignore reproduces legacy's
# silent skip of malformed (odd-length) nodes.
#
# The emitted-issue severity filter is still needed on top of -severities
# error: a rule declared error-severity may emit a warning per issue (the
# placeholder_to predicate emits both the placeholder_to error and the
# email_desync warning), and those warnings do not count toward -limit, so the
# returned list can carry a warning ahead of the first error. Skip them, as
# legacy's approach_validation_error did.
proc spar::_approach_gate_error {approach_data approach_path roster_email contact_name} {
    set inst [spar::_yamlmuster_approach]
    set context [list roster_email $roster_email]
    if {$approach_path ne ""} { lappend context approach_path $approach_path }
    foreach ei [$inst validate $approach_data \
            -groups approach -severities error -limit 1 -badnode ignore \
            -context $context -extra [list contact_name $contact_name]] {
        if {[dict get $ei severity] ne "error"} continue
        return [dict get [spar::_xlate_engine_issue $ei $contact_name] message]
    }
    return ""
}

# ── Host predicates ────────────────────────────────────────────────────────
# Contract (yamlmuster): {*}$cmdprefix $node $meta, meta = {path level context
# extra}; return a list of partial issue dicts ({} = pass). The engine fills
# severity/code from the rule declaration and owns path/level; a predicate may
# override severity/code/message per issue.

# rounds_structural -- missing_rounds (two distinct messages) + no_final_round,
# reproducing legacy validate_approach_data lines 193-216 including its
# early-return semantics: on absent or empty rounds only the missing_rounds
# issue is emitted (no_final_round is suppressed). A declarative require
# -nonempty + any pair cannot express the two messages nor the empty-list
# suppression, so this stays a root predicate.
proc spar::_pred_rounds_structural {node meta} {
    if {![dict exists $node rounds]} {
        return [list [dict create code missing_rounds \
            message "Approach file missing required 'rounds' key"]]
    }
    set rounds [dict get $node rounds]
    if {[catch {llength $rounds} n] || $n == 0} {
        return [list [dict create code missing_rounds \
            message "Approach file has empty 'rounds' array"]]
    }
    foreach round $rounds {
        if {[dict exists $round type] && [dict get $round type] eq "final"} {
            return {}
        }
    }
    return [list [dict create code no_final_round \
        message "Approach file has no round with type: final"]]
}

# placeholder_to -- the email guard rails (legacy 320-363): over the final
# round's To: addresses (gathered by analyse_final_round), a mutually-exclusive
# chain of non-email shape / placeholder domain-or-local / roster desync. A
# root predicate because the addresses are a cross-level aggregation, the three
# checks share a `continue` chain, and desync interpolates the roster_email
# context value. No -needs: the shape and placeholder checks run regardless of
# roster_email; the desync sub-check is skipped when it is empty or lacks '@'.
proc spar::_pred_placeholder_to {node meta} {
    set roster_email [dict getdef [dict get $meta context] roster_email ""]
    set email_re {^[^@\s]+@[^@\s]+\.[^@\s]+$}
    set placeholder_domains {example.com example.org example.net example.edu
        domain.com fake.com placeholder.com email.com yourcompany.com}
    set placeholder_locals {todo placeholder xxx tbd fixme placeholder-email
        your-email-here}
    set fr [spar::analyse_final_round $node]
    set out {}
    foreach addr [dict get $fr to_addresses] {
        set addr_trimmed [string trim $addr]
        if {$addr_trimmed eq ""} continue
        if {![regexp $email_re $addr_trimmed]} {
            lappend out [dict create code placeholder_to \
                message "Approach file has non-email to: address '$addr_trimmed'"]
            continue
        }
        set addr_lc [string tolower $addr_trimmed]
        set at_idx [string first "@" $addr_lc]
        set local  [string range $addr_lc 0 [expr {$at_idx - 1}]]
        set domain [string range $addr_lc [expr {$at_idx + 1}] end]
        if {$domain in $placeholder_domains || $local in $placeholder_locals} {
            lappend out [dict create code placeholder_to \
                message "Approach to: '$addr_trimmed' looks like a placeholder (reserved domain or stub local-part)"]
            continue
        }
        if {$roster_email ne "" && [string first "@" $roster_email] >= 0} {
            if {[string tolower $addr_trimmed] ne [string tolower $roster_email]} {
                lappend out [dict create severity warning code email_desync \
                    message "Approach to: '$addr_trimmed' differs from roster email '$roster_email'"]
            }
        }
    }
    return $out
}

# linkedin_guard -- the #159 LinkedIn rails (legacy 285-308) over a final
# round's messages: the 300-char invite bound, measured on the text the
# dispatcher sends. A round predicate (gated -when {type final}) because it
# needs the round type and iterates the round's linkedin messages, with a
# text/body fallback and mode gate the length kind cannot express.
proc spar::_pred_linkedin_guard {node meta} {
    set out {}
    if {![dict exists $node messages]} { return $out }
    foreach msg [dict get $node messages] {
        if {![dict exists $msg channel] || [dict get $msg channel] ne "linkedin"} continue
        if {![spar::is_null [dict getdef $msg actioned_date ""]]} continue
        set li_text [string trim [dict getdef $msg text ""]]
        if {$li_text eq ""} { set li_text [string trim [dict getdef $msg body ""]] }
        set li_len  [string length $li_text]
        set li_mode [dict getdef $msg mode ""]
        if {($li_mode eq "invite" || $li_mode eq "") && $li_len > 300} {
            lappend out [dict create code linkedin_note_too_long \
                message "LinkedIn invite note is $li_len chars, limit 300; shorten it, or declare mode: dm if a direct message to a 1st-degree connection is intended"]
        }
    }
    return $out
}

# first_line_is_profile_hash -- profile_hash_misplaced (legacy 392-395). Opens
# the approach file and tests line 1. -needs approach_path drops the rule for
# pure-dict callers; the predicate also guards profile_hash presence.
proc spar::_pred_first_line_is_profile_hash {node meta} {
    set ap [dict getdef [dict get $meta context] approach_path ""]
    if {$ap eq "" || ![dict exists $node profile_hash]} { return {} }
    if {[spar::_approach_first_line_is_profile_hash $ap]} { return {} }
    return [list [dict create code profile_hash_misplaced \
        message "profile_hash must be the first line of the approach file (issue #63) — re-emit with the hash on line 1"]]
}

# profile_hash_actual -- profile_hash_mismatch (legacy 384-405): sha256 the
# sibling profile file and compare to the stored hash. -needs approach_path;
# guards profile_hash presence and sibling-profile existence internally.
proc spar::_pred_profile_hash_actual {node meta} {
    set ap [dict getdef [dict get $meta context] approach_path ""]
    if {$ap eq "" || ![dict exists $node profile_hash]} { return {} }
    set stored [string trim [dict get $node profile_hash]]
    if {[regexp {^sha256:([0-9a-fA-F]+)$} $stored -> hex]} {
        set stored_hex [string tolower $hex]
    } else {
        set stored_hex [string tolower $stored]
    }
    set profile_path [file join [file dirname [file dirname $ap]] profiles \
        "[file rootname [file tail $ap]].md"]
    if {![file exists $profile_path]} { return {} }
    set actual [string tolower [::sha2::sha256 -hex -file $profile_path]]
    if {$actual eq $stored_hex} { return {} }
    return [list [dict create code profile_hash_mismatch \
        message "Approach profile_hash 'sha256:$stored_hex' does not match profile file (current sha256:$actual) — re-approach required"]]
}

# validate_approach -- check a single approach file against guard rails.
#
# approach_path         path to the approach YAML file
# roster_email          email field from the roster row (may be empty)
# contact_name          roster contact_name (used for issue messages)
# roster_organisation   retained for signature compatibility; unused (the
#                       org/name_desync checks were retired with #63)
#
# Returns a list of issue dicts, each with keys:
#   severity, code, contact_name, message
#
# Path form: parses the YAML on every call. Used by CLI / harness
# callers (spar-a-harness.tcl) that don't construct a State and so
# can't share a cached projection. Render-path callers go through
# spar::State approach_validation_error → validate_approach_data, which
# reuses the cached projection.
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

    return [spar::validate_approach_data $approach_data $approach_path \
        $roster_email $contact_name $roster_organisation]
}

# validate_approach_data -- full validation of an already-parsed approach dict
# on the yamlmuster approach ruleset (rules/approach.rules + the host
# predicates registered in spar::_yamlmuster_approach). Render-path callers
# (the State's approach_validation_error, via _approach_gate_error) pass the
# projection from approach_summary so the parse is shared with the rest of the
# render; CLI / harness callers pass a fresh parse. Returns every issue
# (errors and warnings) in spar's legacy _issue shape; callers wanting only the
# first error use the cost-limited gate, spar::_approach_gate_error.
#
# approach_path drives the two file-bound profile_hash predicates: they carry
# -needs approach_path, so passing "" (pure-dict callers with synthetic
# fixtures) omits it from the engine context and opts out of those checks,
# exactly the legacy behaviour. roster_organisation is unused, retained for
# signature compatibility (the org/name_desync checks were retired with #63).
#
proc spar::validate_approach_data {approach_data approach_path roster_email \
        contact_name {roster_organisation ""}} {
    set inst [spar::_yamlmuster_approach]
    set context [list roster_email $roster_email]
    if {$approach_path ne ""} { lappend context approach_path $approach_path }
    set issues {}
    foreach ei [$inst validate $approach_data \
            -groups approach -badnode ignore \
            -context $context -extra [list contact_name $contact_name]] {
        lappend issues [spar::_xlate_engine_issue $ei $contact_name]
    }
    return $issues
}

# _approach_first_line_is_profile_hash -- returns 1 iff the file's first
# line literally begins with `profile_hash:`. Used by validate_approach to
# enforce the position discipline introduced with issue #63. Reads only
# the first line (no YAML parser invocation), matching the cheap path
# the discipline is intended to unlock.
proc spar::_approach_first_line_is_profile_hash {approach_path} {
    if {[catch {set fd [open $approach_path r]}]} { return 0 }
    fconfigure $fd -encoding utf-8
    set line ""
    catch {set line [gets $fd]}
    close $fd
    return [regexp {^profile_hash:\s*sha256:[0-9a-fA-F]+\s*$} $line]
}

# ─────────────────────────────────────────────────────────────────────────────
# Profile validation (#45)
# Mirrors the approach validator: closed-vocabulary front matter + staleness
# check against the current roster row. Per state-machine.md §Design by
# Contract, this is the post-check for the P-phase AI call.
# ─────────────────────────────────────────────────────────────────────────────

# ── yamlmuster rules-engine bootstrap (profile) ────────────────────────────
# The front-matter vocabulary walk, required-key checks, yield/star validity,
# and the engagement-leak backstop that used to live inline in validate_profile
# now run on the yamlmuster rule engine over rules/profile.rules. A separate
# instance from the approach one: both declare `level root`, so a single
# instance loading both would fail on the duplicate. Lazy, like the approach
# accessor, so the tpool parse workers pay nothing.
namespace eval spar { variable _yamlmuster_profile_inst "" }
proc spar::_yamlmuster_profile {} {
    variable _yamlmuster_profile_inst
    if {$_yamlmuster_profile_inst ne ""} {
        return $_yamlmuster_profile_inst
    }
    package require yamlmuster
    set inst [yamlmuster new]
    $inst predicate engagement_leak     ::spar::_pred_engagement_leak
    $inst predicate invalid_yield       ::spar::_pred_invalid_yield
    $inst predicate invalid_star_rating ::spar::_pred_invalid_star_rating
    spar::_yamlmuster_load $inst profile.rules profile
    set _yamlmuster_profile_inst $inst
    return $inst
}

# engagement_leak -- the I1 backstop (INVARIANTS.md): a reusable profile must
# carry no engagement, warmth, or pitch content, which is campaign-bound and
# goes stale on reuse, so its presence is a build failure, not a style note. A
# host predicate because it scans the whole profile text (context `raw`), not a
# front-matter field, and each message interpolates the matched pattern/phrase.
# Emits the three case-sensitive heading/line patterns first, then the three
# case-insensitive prior-contact phrases, in that order, all code engagement_leak.
proc spar::_pred_engagement_leak {node meta} {
    set raw [dict getdef [dict get $meta context] raw ""]
    set out {}
    foreach {pat desc} {
        "## Prior correspondence" "prior-correspondence or warmth section"
        "## Angles"               "pitch or angles section"
        "Warmth:"                 "warmth line"
    } {
        if {[string first $pat $raw] >= 0} {
            lappend out [dict create message \
                "Profile carries a $desc ('$pat'). Engagement and pitch content is campaign-bound and must not live in a reusable profile (INVARIANTS.md I1)."]
        }
    }
    set low [string tolower $raw]
    foreach ph {"no prior contact" "no prior correspondence" "no prior connection"} {
        if {[string first $ph $low] >= 0} {
            lappend out [dict create message \
                "Profile states '$ph'. Prior-contact state is campaign-bound and stale on reuse (INVARIANTS.md I1)."]
        }
    }
    return $out
}

# invalid_yield / invalid_star_rating -- the yield and star_rating validity
# checks (legacy validate_profile 596-602 / 625-631). Host predicates rather
# than the declarative `range` kind because legacy's guard fires on a
# present-but-BLANK value ("" is a non-integer), and the engine's value-reading
# kinds treat a blank keypath as absent, so `range` would let a blank slip
# through. Each replicates legacy's exact guard: skip only when the key is
# absent (existence is require's job); otherwise flag blank, non-integer, and
# out-of-range in one check, with the verbatim legacy message.
proc spar::_pred_invalid_yield {node meta} {
    if {![dict exists $node yield]} { return {} }
    set y [dict get $node yield]
    if {![string is integer -strict $y] || $y < 0} {
        return [list [dict create message \
            "yield '$y' — must be a non-negative integer (data-point count per SPAR-P §4.14)"]]
    }
    return {}
}
proc spar::_pred_invalid_star_rating {node meta} {
    if {![dict exists $node star_rating]} { return {} }
    set s [dict get $node star_rating]
    # 0 is valid only on an exclusion profile: SPAR-P §5.4 has the excluded
    # contact keep a short profile whose front matter mirrors the roster's
    # star_rating=0, discriminated by dependent_data.date_excluded being set.
    set excluded ""
    if {[dict exists $node dependent_data date_excluded]} {
        set excluded [dict get $node dependent_data date_excluded]
    }
    if {$excluded in {null ~ Null NULL}} { set excluded "" }
    set lo [expr {$excluded ne "" ? 0 : 1}]
    if {![string is integer -strict $s] || $s < $lo || $s > 5} {
        return [list [dict create message \
            "star_rating '$s' — must be integer 1..5 (0 only on an exclusion profile with dependent_data.date_excluded set, SPAR-P §5.4)"]]
    }
    return {}
}

# read_profile_front_matter -- extract and parse the YAML front-matter block
# of a profile file. Returns parsed dict, or "" on any failure (missing file,
# audit_skills_in_transcript -- the SPAR reading of a session's Skill
# calls: coachman::tool_use_counts does the counting (the worker's
# parent session plus its research subagents), and this wrapper turns
# zero counts into issue dicts (same shape as validate_profile output),
# code "<skill>_lookup_missing" per required skill with no invocation.
# A missing transcript becomes a single warning-severity issue with
# code transcript_not_found rather than masquerading as a skill miss —
# a future Claude storage-layout change should not loop the agent.
#
# session_id      UUID returned by claude --output-format json
# required_skills list of skill IDs (e.g. {linkedin facebook})
# contact_name    for issue dicts (consumed by validate_and_correct)
proc spar::audit_skills_in_transcript {session_id required_skills contact_name {transcripts_root ""}} {
    if {$transcripts_root eq ""} {
        set transcripts_root [file join $::env(HOME) .claude projects]
    }
    # Deferred require, mirroring _yamlmuster_approach above: the
    # validate CLI and the tpool parse workers source this file without
    # the harness, so coachman loads only when an audit actually runs
    # (this file's own vendor tm path makes it resolvable here).
    package require coachman
    if {[catch {
        coachman::tool_use_counts $session_id $transcripts_root Skill skill
    } counts opts]} {
        if {[dict getdef $opts -errorcode {}] eq {COACHMAN NO_TRANSCRIPT}} {
            return [list [dict create severity warning code transcript_not_found \
                contact_name $contact_name \
                message "Session transcript $session_id.jsonl not found under ~/.claude/projects/*/ — audit skipped"]]
        }
        return -options $opts $counts
    }
    set issues {}
    set sec [dict create linkedin §4.3 facebook §4.4]
    foreach s $required_skills {
        if {[dict getdef $counts $s 0] == 0} {
            set sref [dict getdef $sec $s "(spec)"]
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
    set fd ""
    set raw ""
    try {
        set fd [open $profile_path r]
        fconfigure $fd -encoding utf-8
        set raw [read $fd]
    } on error {err} {
        lappend issues [spar::_issue error invalid_front_matter $contact_name \
            "Profile file could not be read: $err"]
        return $issues
    } finally {
        if {$fd ne ""} { catch {close $fd} }
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

    # Closed-vocabulary walk, required keys, yield/star ranges, and the
    # engagement-leak backstop now run on the yamlmuster profile ruleset
    # (rules/profile.rules + the engagement_leak predicate). The whole profile
    # text is passed as context `raw` for the leak scan; contact_name rides in
    # -extra for the issue shape. Reachability and staleness stay imperative
    # below (roster-row comparisons), appended after these issues to preserve
    # the legacy near-last emission order.
    foreach ei [[spar::_yamlmuster_profile] validate $fm \
            -groups profile -badnode ignore \
            -context [list raw $raw] -extra [list contact_name $contact_name]] {
        lappend issues [spar::_xlate_engine_issue $ei $contact_name]
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
    set pp [dict getdef $contact profile_path ""]
    if {$pp eq ""} { return "" }
    set cname [dict getdef $contact contact_name ""]
    foreach issue [spar::validate_profile $pp $contact $cname] {
        if {[dict get $issue severity] eq "error"} {
            return [dict get $issue message]
        }
    }
    return ""
}

# ── yamlmuster rules-engine bootstrap (sender) ─────────────────────────────
# validate_sender_block's schema checks run on the yamlmuster rule engine over
# rules/sender.rules. Its own instance (the shared-root constraint again); no
# predicates, since the sender rules are all declarative require/range. sender.rules
# carries no vocab rule (legacy never closed-vocabulary-walks the campaign or
# sender block), and legacy's "no sender block => skip the smtp_* checks" early
# return is reproduced structurally: with no `sender` key the walk never
# descends to the sender_block level, so its rules never run.
namespace eval spar { variable _yamlmuster_sender_inst "" }
proc spar::_yamlmuster_sender {} {
    variable _yamlmuster_sender_inst
    if {$_yamlmuster_sender_inst ne ""} {
        return $_yamlmuster_sender_inst
    }
    package require yamlmuster
    set inst [yamlmuster new]
    spar::_yamlmuster_load $inst sender.rules sender
    set _yamlmuster_sender_inst $inst
    return $inst
}

# validate_sender_block -- campaign-level sender schema checks. Pure
# schema validation, platform-agnostic — smtp_pass in YAML is not
# flagged here (environmental concern, handled in build_warnings /
# the gear dialog where the platform's keychain capability is known).
# Returns issue dicts in the same shape as validate_campaign, with
# empty segment/contact_name (these are campaign-level, not per-contact).
proc spar::validate_sender_block {cdata} {
    set issues {}
    foreach ei [[spar::_yamlmuster_sender] validate $cdata \
            -groups sender -badnode ignore] {
        lappend issues [spar::_issue [dict get $ei severity] [dict get $ei code] "" \
            [dict get $ei message] {segment ""}]
    }
    return $issues
}

# ---------------------------------------------------------------------------
# Spec versioning
#
# campaign.yaml and segment.yaml each declare a top-level `version:` naming the
# SPAR spec generation they conform to. The tool supports CURRENT_SPEC_VERSION;
# data declaring a different version is refused (version_unsupported, error).
# Data with no version field is legacy/unstamped — a warning, not an error, so
# instances that still validate clean keep running until they are stamped.
# ---------------------------------------------------------------------------
namespace eval spar { variable CURRENT_SPEC_VERSION "1.0" }

# campaign_version / segment_version -- read the declared `version` from an
# already-parsed campaign or segment dict; "" when absent. The field name is
# spelled in exactly one place per file type here.
proc spar::campaign_version {cdata} {
    return [dict getdef $cdata version ""]
}
proc spar::segment_version {segment_data} {
    return [dict getdef $segment_data version ""]
}

# ── yamlmuster rules-engine bootstrap (version) ────────────────────────────
# The spec-version gate runs on the yamlmuster rule engine over
# rules/version.rules. Its own instance (shared-root constraint). Both rules
# are predicates: their messages interpolate the per-call $label and
# CURRENT_SPEC_VERSION, neither a node field nor a -message template token, so
# the declarative oneof/require kinds cannot carry them. The declared version
# and label arrive via -context; the throwaway data dict is empty.
namespace eval spar { variable _yamlmuster_version_inst "" }
proc spar::_yamlmuster_version {} {
    variable _yamlmuster_version_inst
    if {$_yamlmuster_version_inst ne ""} {
        return $_yamlmuster_version_inst
    }
    package require yamlmuster
    set inst [yamlmuster new]
    $inst predicate version_unstamped   ::spar::_pred_version_unstamped
    $inst predicate version_unsupported ::spar::_pred_version_unsupported
    spar::_yamlmuster_load $inst version.rules version
    set _yamlmuster_version_inst $inst
    return $inst
}

# version_unstamped -- warning when the declared version is empty. Mutually
# exclusive with version_unsupported (which guards declared ne "" first).
proc spar::_pred_version_unstamped {node meta} {
    variable CURRENT_SPEC_VERSION
    set ctx [dict get $meta context]
    set declared [dict getdef $ctx declared ""]
    set label [dict getdef $ctx label ""]
    if {$declared ne ""} { return {} }
    return [list [dict create message \
        "$label has no version: field — treating as pre-$CURRENT_SPEC_VERSION (unstamped). Stamp it with version: \"$CURRENT_SPEC_VERSION\"."]]
}

# version_unsupported -- error when a non-empty declared version is not the one
# this tool supports.
proc spar::_pred_version_unsupported {node meta} {
    variable CURRENT_SPEC_VERSION
    set ctx [dict get $meta context]
    set declared [dict getdef $ctx declared ""]
    set label [dict getdef $ctx label ""]
    if {$declared eq "" || $declared eq $CURRENT_SPEC_VERSION} { return {} }
    return [list [dict create message \
        "$label declares spec version '$declared' but this tool supports $CURRENT_SPEC_VERSION."]]
}

# validate_spec_version -- gate one declared version against CURRENT_SPEC_VERSION.
# Returns zero or one issue dict (same shape as the other validators).
#   declared  the version string, possibly "" (unstamped)
#   label     human tag for the message, e.g. "campaign.yaml" or "segment 'x'"
#   extra     passed through to _issue (e.g. {segment growers-market})
proc spar::validate_spec_version {declared label {extra {}}} {
    if {[llength $extra] == 0} { set extra {segment ""} }
    set issues {}
    foreach ei [[spar::_yamlmuster_version] validate {} \
            -groups version \
            -context [list declared $declared label $label]] {
        lappend issues [spar::_issue [dict get $ei severity] [dict get $ei code] "" \
            [dict get $ei message] $extra]
    }
    return $issues
}

# validate_versions -- run the version gate on the campaign dict and each
# segment's segment.yaml. segment_paths is a list of {label seg_dir} pairs,
# the shape produced by spar::resolve_campaign. A missing segment.yaml is
# treated as unstamped (same as an empty version).
proc spar::validate_versions {cdata segment_paths} {
    set issues [spar::validate_spec_version [spar::campaign_version $cdata] "campaign.yaml"]
    foreach item $segment_paths {
        lassign $item label seg_dir
        set sdata [spar::read_segment_yaml [file join $seg_dir segment.yaml]]
        set declared [expr {$sdata eq "" ? "" : [spar::segment_version $sdata]}]
        lappend issues {*}[spar::validate_spec_version $declared "segment '$label'" [list segment $label]]
    }
    return $issues
}

# assert_supported_version -- refuse-to-start guard for the dispatcher. Throws
# when a declared version is unsupported (version_unsupported); unstamped data
# (no version field) is allowed through with no error, so legacy campaigns keep
# running until they are stamped. Reuses validate_spec_version so the rule lives
# in one place. This is a pre-flight input check, not a DbC pre/post pair.
proc spar::assert_supported_version {label declared} {
    foreach issue [spar::validate_spec_version $declared $label] {
        if {[dict get $issue code] eq "version_unsupported"} {
            error [dict get $issue message]
        }
    }
}

# validate_campaign_semantics -- cross-file checks only; no per-file approach validation.
# Used by progress/warnings paths where per-file schema validation is out of scope
# (per issue #43 principle 6).
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
        set state [dict getdef $contact state ""]
        set segment_dir [dict getdef $contact _segment_dir ""]
        set segment [file tail $segment_dir]
        set contact_name [dict getdef $contact contact_name ""]
        set roster_email [string trim [dict getdef $contact email ""]]
        set roster_org [string trim [dict getdef $contact organisation ""]]
        set stem [string trim [dict getdef $contact stem ""]]

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
            set approach_path [dict getdef $contact approach_path ""]
            foreach issue [spar::validate_approach $approach_path $roster_email $contact_name $roster_org] {
                dict set issue segment $segment
                lappend issues $issue
            }
        }

        # Profile validation (skipped when include_profile=0). State PROFILE_STALE
        # still emits through validate_profile's stale_* warnings; DISCOVERED has
        # no profile file so validate_profile no-ops.
        if {$include_profile} {
            set profile_path [dict getdef $contact profile_path ""]
            foreach issue [spar::validate_profile $profile_path $contact $contact_name] {
                dict set issue segment $segment
                lappend issues $issue
            }
        }
    }

    # Roster quality-checklist assertions (per-segment)
    array set seg_contacts {}
    foreach contact $all_classified_contacts {
        set sd [dict getdef $contact _segment_dir ""]
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
    set segment_dir [dict getdef [lindex $segment_contacts 0] _segment_dir ""]
    set segment [file tail $segment_dir]

    # Accumulators for cross-row checks
    set seen_name_org {}  ;# list of "name|org" keys (lowercased)
    set seen_stems {}     ;# list of stem values

    foreach contact $segment_contacts {
        set state [dict getdef $contact state ""]
        set contact_name [string trim [dict getdef $contact contact_name ""]]
        set org [string trim [dict getdef $contact organisation ""]]
        set email [string trim [dict getdef $contact email ""]]
        set linkedin [string trim [dict getdef $contact linkedin_url ""]]
        set facebook [string trim [dict getdef $contact facebook_url ""]]
        set phone [string trim [dict getdef $contact phone ""]]
        set sweep [string trim [dict getdef $contact sweep_iteration ""]]
        set date_invalid [string trim [dict getdef $contact date_excluded ""]]
        set star [string trim [dict getdef $contact star_rating ""]]
        set stem [string trim [dict getdef $contact stem ""]]
        set field_count_warning [dict getdef $contact _field_count_warning ""]

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
        set state [dict getdef $contact state ""]
        if {$state eq "EXCLUDED"} continue
        set _name [string trim [dict getdef $contact contact_name ""]]
        if {$_name eq ""} continue
        set _org [string trim [dict getdef $contact organisation ""]]
        set _email [string trim [string tolower [dict getdef $contact email ""]]]
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
#   validation_issues  — structured per-contact semantic issues, each a dict
#                        {severity segment contact message}, in the same order
#                        their flat strings were appended to messages. Lets a
#                        caller (spar-progress) group by problem instead of
#                        printing one line per contact.
#
proc spar::build_warnings {all_classified_contacts {cdata {}}} {
    set messages {}
    set dup_to_count 0
    set dup_name_count 0
    set dup_email_count 0
    set dup_subject_count 0
    set val_errors 0
    set val_warnings 0
    set validation_issues {}

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
            validation_warnings $val_warnings validation_issues {}]
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
        set seg [dict getdef $issue segment ""]
        set cname [dict getdef $issue contact_name ""]
        set msg [dict get $issue message]
        set prefix "\[[string toupper $sev]\]"
        if {$seg ne ""} { append prefix " $seg" }
        if {$cname ne ""} { append prefix " ($cname)" }
        lappend messages "$prefix: $msg"
        lappend validation_issues \
            [dict create severity $sev segment $seg contact $cname message $msg]
        if {$sev eq "error"} {
            incr val_errors
        } else {
            incr val_warnings
        }
    }

    return [dict create messages $messages \
        duplicate_to $dup_to_count duplicate_name $dup_name_count \
        duplicate_email $dup_email_count identical_subject $dup_subject_count \
        validation_errors $val_errors validation_warnings $val_warnings \
        validation_issues $validation_issues]
}


package provide spar-validate 1.0
