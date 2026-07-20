# spar-harness.tcl — TclOO base class plus Approach and Profile subclasses
# for harnessed Claude CLI sessions.
#
# A "harness" wraps a single claude session with the machinery the DbC
# contract requires: JSON invocation, credit-limit retry, session-resume
# for fix loops, per-stage cost ledger. The spar::ApproachHarness and
# spar::ProfileHarness subclasses supply the phase-specific
# validate_and_correct loop and orchestration.
#
# Requires spar-state.tcl sourced first (for spar::State
# and the validators).

package require json
package require json::write
package require TclOO
package require logger
# vendor/ carries the modules this app depends on: a checkout runs as-is,
# and an upstream bump lands as a reviewable diff. deadman's home, man
# page, and full test suite live in the teatotal repository.
::tcl::tm::path add \
    [file join [file dirname [file normalize [info script]]] .. vendor]
package require deadman
# coachman carries the generic claude-session harness base; spar::Harness
# below subclasses it. Authored and published in the questlog repository,
# which spar is the only consumer of so far, so a bump comes from there.
package require coachman

# Idempotent: oo::class create is not idempotent, so guard against
# multiple sources.
if {[info exists ::spar::_harness_loaded]} {
    package provide spar-harness 1.0
    return
}

namespace eval spar {
    variable _harness_loaded 1
    # Capture the directory holding this file at source time. prompt_root
    # derives the checkout root from it, where load_prompt resolves
    # prompts/<name>.txt.
    variable harness_dir [file dirname [file normalize [info script]]]
    # Logger service for harness runtime output. Per-row context
    # (slug, phase) goes in the message body; logger adds the
    # timestamp, service tag, and level.
    variable harness_log [logger::init spar::harness]
}

source [file join $::spar::harness_dir spar-courier.tcl]

oo::class create spar::Harness {
    superclass coachman::Harness

    # spar::Harness is a thin subclass of the vendored coachman harness. coachman
    # owns the generic claude-session machinery (invoke/resume, credit-limit
    # recovery, stall-kill, cost cap, the fix-loop skeleton); spar supplies the
    # host-specific pieces coachman leaves injectable, plus its one domain method.

    # coachman's injected reach-ins, pointed at spar's own services. The
    # cost meter stays coachman's default: tallyman and anthropic-rates.tcl
    # sit beside the vendored module, so the cap is metered as shipped.
    method log_service {}         { return $::spar::harness_log }
    method prompt_root {}         { return [file dirname $::spar::harness_dir] }
    method claude_bin {}          { return [spar::find_tool claude] }

    # inject_courier — substitute __COURIER_SECTION__ in the prompt file with the
    # prefetched courier block (accounts header plus per-contact correspondence
    # cascade). Runs in the harness so the slow `courier -A search` exec
    # parallelises across contacts instead of serialising in the dispatcher's
    # prepare loop. Empty section when courier isn't installed. This is spar's
    # own concern and stays out of coachman.
    method inject_courier {prompt_path name org email} {
        set hdr  [spar::courier::accounts_block]
        set body [spar::courier::contact_block $name $org $email]
        set section [expr {$hdr eq "" ? "" : "\n\n${hdr}${body}"}]
        set prompt [spar::read_file $prompt_path]
        set prompt [string map [list __COURIER_SECTION__ $section] $prompt]
        spar::write_file $prompt_path $prompt
        ${::spar::harness_log}::info "\[[my slug]\] \[phase: courier\]"
    }
}

# Lightweight file helpers — used across harness scripts.
proc spar::read_file {path} {
    set fd [open $path r]
    set content [read $fd]
    close $fd
    return $content
}

proc spar::write_file {path content} {
    set fd [open $path w]
    puts -nonewline $fd $content
    close $fd
}

# ── ApproachHarness class ─────────────────────────────────────────────

oo::class create spar::ApproachHarness {
    superclass spar::Harness
    variable State Outfile RosterEmail ContactName RosterOrg \
             MaxPasses ContactSummary ChallengerModel ContactNameMeta \
             Pass Verdict ProfilePath

    constructor {prompt_dir log_dir} {
        next $prompt_dir $log_dir
        # The harness rewrites the approach file across fix attempts —
        # back-to-back rewrites can land within mtime granularity (1s)
        # and may keep the line-1 profile_hash unchanged, so neither
        # invalidator on approach_summary's cache fires reliably. Hold
        # a State for shared validation paths and use forget_approach
        # explicitly after each agent write that touched the outfile.
        set State [spar::State new]
    }
    destructor {
        if {[info exists State] && $State ne ""} {
            $State destroy
            set State ""
        }
    }
    method state {} { return $State }

    # DbC-Post loop for approach files. Per-call args are stashed as
    # instance vars so the validator and prompt-builder methods see
    # them; the retry skeleton lives in spar::Harness::run_fix_loop.
    method validate_and_correct {outfile roster_email contact_name {roster_organisation ""}} {
        set Outfile     $outfile
        set RosterEmail $roster_email
        set ContactName $contact_name
        set RosterOrg   $roster_organisation
        return [my run_fix_loop validate_approach_errors build_approach_fix_prompt]
    }

    # Path-form validate_approach parses fresh — appropriate because every
    # attempt follows an agent write to $Outfile.
    method validate_approach_errors {attempt} {
        return [spar::validate_approach $Outfile $RosterEmail $ContactName $RosterOrg]
    }

    method build_approach_fix_prompt {attempt hard error_text} {
        return [my load_prompt spar-a-fix [dict create \
            ERROR_TEXT   $error_text \
            OUTFILE      $Outfile \
            ROSTER_EMAIL $RosterEmail]]
    }

    # Drop the State's approach cache after each agent rewrite so the
    # next validate_approach + the post-loop prepend_profile_hash call
    # both see fresh bytes.
    method after_resume {} {
        $State forget_approach $Outfile
    }

    # Mediated roster writes, A side: a validated approach may declare a
    # root roster_patch (send-time email backfill, exclusion). The harness
    # applies it; the worker writes no TSV. Rejections are logged, not
    # fatal: the approach itself passed validation, and the roster is
    # untouched on rejection.
    method apply_declarations {} {
        set segment_dir [file dirname [file dirname $Outfile]]
        set roster_path [file join $segment_dir roster.tsv]
        set stem [file rootname [file tail $Outfile]]
        foreach issue [spar::apply_approach_patch $Outfile $roster_path $stem] {
            ${::spar::harness_log}::warn \
                "\[[my slug]\] roster_patch rejected: [dict getdef $issue message ?]"
        }
        $State forget_approach $Outfile
    }

    # Run the full A-phase pipeline. Returns 0 on success, 1 on failure.
    # The try/on-error wrapper turns an uncaught exception into a logged
    # FAIL line — without it, an exception in load_my_meta or any phase
    # method would propagate up to harness_run as "harness exited rc=…"
    # with no per-row context in the operator's log.
    method run {} {
        try {
            my load_my_meta
            my do_inject_courier
            if {[my do_author_draft]}             { return 1 }
            if {[my run_spar_loop]}               { return 1 }
            if {[my do_assembly]}                 { return 1 }
            if {[my do_post_assembly_validation]} { return 1 }
            my apply_declarations
            my do_summary
            return 0
        } on error {err opts} {
            my _fail \
                "FAIL ([my slug]): uncaught error in ApproachHarness::run — $err"
            return 1
        }
    }

    # Unpack meta.env into instance vars used by phase methods.
    # ProfilePath mirrors approach_path_for_stem / profile_path_for_stem:
    # outfile is <segment_dir>/approach/<stem>.yaml; profile is at
    # <segment_dir>/profiles/<stem>.md.
    method load_my_meta {} {
        set meta [my load_meta]
        set MaxPasses        [dict get $meta MAX_PASSES]
        set Outfile          [dict get $meta OUTFILE]
        set ContactSummary   [dict get $meta CONTACT_SUMMARY]
        set ChallengerModel  [dict getdef $meta CHALLENGER_MODEL sonnet]
        set RosterEmail      [dict getdef $meta ROSTER_EMAIL ""]
        set RosterOrg        [dict getdef $meta ROSTER_ORGANISATION ""]
        set ContactNameMeta  [dict getdef $meta CONTACT_NAME ""]
        set ContactName      [string trim [lindex [split $ContactSummary |] 0]]
        set seg_dir [file dirname [file dirname $Outfile]]
        set stem    [file rootname [file tail $Outfile]]
        set ProfilePath [file join $seg_dir profiles "${stem}.md"]
    }

    method do_inject_courier {} {
        my inject_courier \
            [file join [my prompt_dir] author-draft.txt] \
            $ContactNameMeta $RosterOrg $RosterEmail
    }

    method do_author_draft {} {
        set slug       [my slug]
        set log_prefix [my log_prefix]
        set prompt_dir [my prompt_dir]

        ${::spar::harness_log}::info "\[$slug\] \[phase: drafting\]"
        ${::spar::harness_log}::info "\[$slug\] Author: drafting..."
        set author_draft_log "${log_prefix}-author-draft.log"
        set author_prompt [spar::read_file [file join $prompt_dir author-draft.txt]]

        if {[my call "author-draft" $author_draft_log $author_prompt]} {
            return 1
        }

        set draft_text [coachman::transcript_assistant_text "${author_draft_log}.json"]
        set draft [coachman::extract_between $draft_text "DRAFT_START" "DRAFT_END"]
        if {$draft eq ""} {
            my _fail "FAIL (no draft markers): $slug"
            return 1
        }
        set rationale [coachman::extract_between $draft_text "RATIONALE_START" "RATIONALE_END"]
        spar::write_file [file join $prompt_dir draft-current.txt] $draft
        spar::write_file [file join $prompt_dir rationale.txt] $rationale
        return 0
    }

    # The challenger runs fresh each pass (context-isolated) — call,
    # not resume. The author is the persistent harness; its session_id
    # is what the rev step resumes.
    method run_spar_loop {} {
        set slug       [my slug]
        set log_prefix [my log_prefix]
        set prompt_dir [my prompt_dir]

        set Pass 0
        set Verdict "REVISE"

        while {$Pass < $MaxPasses && $Verdict eq "REVISE"} {
            incr Pass
            ${::spar::harness_log}::info "\[$slug\] \[phase: challenger $Pass/$MaxPasses\]"
            ${::spar::harness_log}::info "\[$slug\] Challenger pass $Pass/$MaxPasses..."

            set challenger_template [spar::read_file [file join $prompt_dir challenger-template.txt]]
            set current_draft [spar::read_file [file join $prompt_dir draft-current.txt]]
            set challenger_prompt [string map [list __DRAFT_PLACEHOLDER__ $current_draft] $challenger_template]

            set challenger_log "${log_prefix}-challenger-pass${Pass}.log"
            if {[my call "challenger-pass${Pass}" $challenger_log $challenger_prompt --model $ChallengerModel]} {
                return 1
            }

            file copy -force $challenger_log [file join $prompt_dir "challenger-pass${Pass}.txt"]

            set challenger_text [spar::read_file $challenger_log]
            set Verdict ""
            foreach line [split $challenger_text \n] {
                if {[string match "VERDICT:*" $line]} {
                    set Verdict [string trim [string range $line 8 end]]
                }
            }
            if {$Verdict eq ""} { set Verdict "REVISE" }

            if {$Verdict eq "DONE"} {
                ${::spar::harness_log}::info "\[$slug\] Challenger pass $Pass: DONE"
                break
            }

            ${::spar::harness_log}::info "\[$slug\] \[phase: revising $Pass\]"
            ${::spar::harness_log}::info "\[$slug\] Challenger pass $Pass: REVISE — author revising..."

            set author_rev_log "${log_prefix}-author-rev${Pass}.log"
            set challenger_feedback [spar::read_file [file join $prompt_dir "challenger-pass${Pass}.txt"]]

            set rev_prompt [my load_prompt spar-a-revise [dict create \
                PASS                $Pass \
                CHALLENGER_FEEDBACK $challenger_feedback]]

            spar::write_file [file join $prompt_dir "author-rev${Pass}.txt"] $rev_prompt

            if {[my resume "author-rev${Pass}" $author_rev_log $rev_prompt]} {
                return 1
            }

            set rev_text [coachman::transcript_assistant_text "${author_rev_log}.json"]
            set revised_draft [coachman::extract_between $rev_text "DRAFT_START" "DRAFT_END"]
            if {$revised_draft ne ""} {
                spar::write_file [file join $prompt_dir draft-current.txt] $revised_draft
            }
            set revised_rationale [coachman::extract_between $rev_text "RATIONALE_START" "RATIONALE_END"]
            if {$revised_rationale ne ""} {
                spar::write_file [file join $prompt_dir rationale.txt] $revised_rationale
            }
        }
        return 0
    }

    method do_assembly {} {
        set slug       [my slug]
        set log_prefix [my log_prefix]
        set prompt_dir [my prompt_dir]

        ${::spar::harness_log}::info "\[$slug\] \[phase: assembling\]"
        ${::spar::harness_log}::info "\[$slug\] Author: assembling..."

        set all_challenger ""
        for {set r 1} {$r <= $Pass} {incr r} {
            set cfile [file join $prompt_dir "challenger-pass${r}.txt"]
            if {[file exists $cfile]} {
                append all_challenger "\n### A2 Response $r\n\n[spar::read_file $cfile]\n"
            }
        }
        set all_revisions ""
        for {set r 1} {$r <= $Pass} {incr r} {
            set rev_log "${log_prefix}-author-rev${r}.log"
            if {[file exists $rev_log]} {
                set rev_draft [coachman::extract_between [coachman::transcript_assistant_text "${rev_log}.json"] "DRAFT_START" "DRAFT_END"]
                if {$rev_draft ne ""} {
                    append all_revisions "\n### A1 Draft [expr {$r + 1}]\n\n$rev_draft\n"
                }
            }
        }

        set initial_draft [coachman::extract_between [coachman::transcript_assistant_text "${log_prefix}-author-draft.log.json"] "DRAFT_START" "DRAFT_END"]
        set final_draft [spar::read_file [file join $prompt_dir draft-current.txt]]

        set assembly_prompt [my load_prompt spar-a-assembly [dict create \
            CONTACT_SUMMARY  $ContactSummary \
            INITIAL_DRAFT    $initial_draft \
            CHALLENGER_MODEL $ChallengerModel \
            ALL_CHALLENGER   $all_challenger \
            ALL_REVISIONS    $all_revisions \
            FINAL_DRAFT      $final_draft \
            OUTFILE          $Outfile]]

        set appendix_path [file join $prompt_dir appendix-assembly.txt]
        if {[file exists $appendix_path]} {
            set appendix_text [spar::read_file $appendix_path]
            if {[string trim $appendix_text] ne ""} {
                append assembly_prompt "\n\n$appendix_text"
            }
        }

        set assembly_log "${log_prefix}-author-assembly.log"
        spar::write_file [file join $prompt_dir assembly.txt] $assembly_prompt

        # DbC-Pre: pre-conditions for assembly are that the upstream
        # draft / spar / revision logs all exist and are non-empty.
        # Assert rather than trust.
        set required_logs [list "${log_prefix}-author-draft.log"]
        for {set r 1} {$r <= $Pass} {incr r} {
            lappend required_logs "${log_prefix}-challenger-pass${r}.log"
        }
        set rev_passes [expr {$Verdict eq "DONE" ? $Pass - 1 : $Pass}]
        for {set r 1} {$r <= $rev_passes} {incr r} {
            lappend required_logs "${log_prefix}-author-rev${r}.log"
        }
        foreach lg $required_logs {
            if {![file exists $lg]} {
                my _fail "FAIL (DbC-Pre: assembly precondition log missing: $lg): $slug"
                return 1
            }
            if {[file size $lg] == 0} {
                my _fail "FAIL (DbC-Pre: assembly precondition log empty: $lg): $slug"
                return 1
            }
        }
        if {[my resume "assembly" $assembly_log $assembly_prompt]} {
            return 1
        }
        return 0
    }

    # DbC-Post pair for the assembly call. validate_and_correct runs
    # spar::validate_approach on the file the agent just wrote; on
    # error it resumes the agent with the specific failure (the "blame
    # the renter" half of the contract). When Outfile is missing
    # (assembly silently produced nothing), fall through — do_summary
    # will warn.
    method do_post_assembly_validation {} {
        if {![file exists $Outfile]} { return 0 }
        if {[my validate_and_correct $Outfile $RosterEmail $ContactName $RosterOrg]} {
            return 1
        }
        # profile_hash linkage (#63): prepend AFTER validation passes.
        # Doing it here (not via the prompt) keeps the agent's attention
        # budget on the message and guarantees the position discipline
        # (line 1) without trusting the agent to follow it.
        if {[file exists $ProfilePath]} {
            spar::prepend_profile_hash $Outfile $ProfilePath
        }
        return 0
    }

    method do_summary {} {
        set slug       [my slug]
        set total_cost [my cost_total]

        if {![file exists $Outfile]} {
            ${::spar::harness_log}::warn "WARN: $slug completed but $Outfile not found (cost=\$$total_cost)"
            return
        }
        ${::spar::harness_log}::info "DONE: $slug ($Pass pass(es), verdict=$Verdict, cost=\$$total_cost)"

        # response_likelihood is written into the approach YAML by the
        # assembly agent (a root key, per spar-A-approach.md §6); it is
        # campaign-bound and does not go to the segment's shared roster.
        # No roster write-back here.
    }
}

# ── ProfileHarness class ──────────────────────────────────────────────

oo::class create spar::ProfileHarness {
    superclass spar::Harness

    variable State Outfile RosterPath RequiredSkills Stem \
             ContactLinkedin OutfilePreexisted OutfileSnapshot

    # Profile workers run under an explicit allow-list instead of
    # skip-permissions, so a research delegation can only reach the
    # read-only Explore subagent (which cannot cascade); a full-tool/null
    # Agent spawn fails to match Agent(Explore) and the deep-research swarm
    # is denied. This closes the 270-subagent runaway (#132). dontAsk makes
    # the allow-list non-interactive: a tool outside it is denied, not
    # prompted, so an unattended run never stalls.
    method permission_args {} {
        return [list \
            --permission-mode dontAsk \
            --allowedTools "WebSearch,WebFetch,Read,Write,Edit,Glob,Grep,ToolSearch,TodoWrite,Skill,Bash,Agent(Explore),SendMessage" \
            --disallowedTools "Agent(general-purpose),Agent(claude),Agent(general),Workflow,Skill(deep-research),Skill(ot:build-dossier)"]
    }

    # Override the generic continuation prompt with the research-specific one:
    # a profile interrupted mid-research should resume its research, not stop
    # (the inverse of do_finalise_after_cost_kill, which stops it). load_my_meta
    # runs before do_profile_call, so Stem/Outfile are set by the time a
    # usage-window block can fire.
    method continuation_prompt {stage} {
        return [my load_prompt spar-p-continue [dict create \
            STEM $Stem OUTFILE $Outfile]]
    }

    method state {} {
        if {![info exists State] || $State eq ""} {
            set State [spar::State new]
        }
        return $State
    }

    destructor {
        if {[info exists State] && $State ne "" && [info commands $State] ne ""} {
            $State destroy
        }
    }

    # Load the current roster row for this slug. Used by both validation
    # and the masked-email sanitiser.
    method _roster_row {roster_path slug} {
        if {![file exists $roster_path]} { return [dict create] }
        foreach r [spar::load_roster $roster_path] {
            if {[dict getdef $r stem ""] eq $slug} { return $r }
        }
        return [dict create]
    }

    # DbC-Post: if the agent wrote a masked email (e.g. "b***@foo.com") to
    # the roster, blank the field. A masked address is worse than empty —
    # it inflates "has email" counts and propagates into approach files.
    # The harness runs as a coroutine on the one thread the pool and the
    # front-end share, so the roster write is already serialised against
    # every other job; blank the field by calling spar::update_roster_field
    # directly rather than marshalling a report across threads.
    method sanitise_roster_email {roster_path slug} {
        if {![file exists $roster_path]} { return }
        foreach row [spar::load_roster $roster_path] {
            if {[dict getdef $row stem ""] ne $slug} continue
            set email [string trim [dict getdef $row email ""]]
            if {[spar::is_masked_email $email]} {
                ${::spar::harness_log}::warn "\[[my slug]\] Guardrail: blanked masked email '$email' in roster"
                if {[catch {
                    spar::update_roster_field $roster_path \
                        stem $slug email ""
                } err]} {
                    ${::spar::harness_log}::warn \
                        "\[[my slug]\] roster blank failed for stem=$slug: $err"
                }
            }
        }
    }

    # DbC-Post loop for profile files. Per-call args stashed as instance
    # vars; retry skeleton lives in spar::Harness::run_fix_loop. The
    # required_skills list (derived from segment.yaml's profile_reject_if)
    # opts into the §4.3/§4.4 mandatory-skill audit per skill named.
    method validate_and_correct {outfile roster_path required_skills} {
        set Outfile        $outfile
        set RosterPath     $roster_path
        set RequiredSkills $required_skills
        return [my run_fix_loop validate_profile_errors build_profile_fix_prompt]
    }

    method validate_profile_errors {attempt} {
        set slug [my slug]
        set row  [my _roster_row $RosterPath $slug]
        # A missing file is normally the missing-profile fault (feeds the
        # missing-profile branch in build_profile_fix_prompt; the next
        # iteration re-validates the rewritten file). An excluded row is
        # softer: SPAR-P §5.4 asks for a short exclusion profile recording
        # why, but historical exclusions predate that requirement, so an
        # absent file next to a date_excluded row warns rather than loops
        # the worker.
        if {![file exists $Outfile]} {
            if {[spar::_roster_field_current $row date_excluded] ne ""} {
                return [list [dict create severity warning \
                    code exclusion_profile_missing \
                    message "Excluded row has no profile document; SPAR-P §5.4 asks for a short exclusion profile recording why"]]
            }
            return [list [dict create severity error code missing_profile \
                          message "The profile file was not written to $Outfile"]]
        }
        # Mediated roster writes: apply the deliverable's declarations
        # (star sync, one-shot roster_patch, sweep_feedback) before
        # validating, so validation sees the roster the declaration
        # produced. Runs on every attempt: idempotent by stamp, and a
        # fix-loop resume that edits the declaration gets it applied on
        # the re-validate. Rejections join the error list and drive the
        # same fix loop.
        set errors [spar::apply_roster_patch $Outfile $RosterPath $Stem]
        if {[llength $errors] == 0} {
            set row [my _roster_row $RosterPath $slug]
        }
        lappend errors {*}[spar::validate_profile $Outfile $row $slug]
        # Segment-scoped roster checks reach this harness via
        # contact_name match — within-segment duplicates and
        # shared-inbox collisions surface here for resume.
        set my_cname [string trim [dict getdef $row contact_name ""]]
        set segment_dir [file dirname $RosterPath]
        if {$my_cname ne ""} {
            if {[catch {[my state] classify_segment $segment_dir} seg_contacts]} {
                set seg_contacts {}
            }
            foreach ri [spar::validate_roster $seg_contacts] {
                if {[dict get $ri severity] ne "error"} continue
                if {[dict get $ri contact_name] ne $my_cname} continue
                lappend errors $ri
            }
        }
        # Issue #76: transcript-based audit. Skipped when the segment lists
        # no required skills (profile_reject_if absent or empty), the row
        # is excluded, or session_id was never captured.
        if {[llength $RequiredSkills] > 0 \
                && [string trim [dict getdef $row date_excluded ""]] eq "" \
                && [my session_id] ne ""} {
            foreach ai [spar::audit_skills_in_transcript \
                            [my session_id] $RequiredSkills $my_cname] {
                lappend errors $ai
            }
        }
        return $errors
    }

    method build_profile_fix_prompt {attempt hard error_text} {
        if {[llength $hard] == 1 && [dict get [lindex $hard 0] code] eq "missing_profile"} {
            return [my load_prompt spar-p-fix-missing [dict create OUTFILE $Outfile]]
        }
        return [my load_prompt spar-p-fix-validation [dict create \
            AUDIT_PREAMBLE [my build_audit_preamble $hard] \
            SLUG           [my slug] \
            ERROR_TEXT     $error_text \
            OUTFILE        $Outfile]]
    }

    # When the §4.3/§4.4 audit fires, prepend a high-priority instruction
    # so the agent does not bury the skill invocation under the rest of
    # the error bag.
    method build_audit_preamble {hard} {
        set audit_present {}
        foreach e $hard {
            set c [dict get $e code]
            if {$c eq "linkedin_lookup_missing" || $c eq "facebook_lookup_missing"} {
                lappend audit_present $c
            }
        }
        if {[llength $audit_present] == 0} { return "" }
        set parts {}
        foreach c $audit_present {
            if {$c eq "linkedin_lookup_missing"} {
                lappend parts "invoke the linkedin skill (Skill tool with skill=linkedin) to fetch and parse the LinkedIn profile per SPAR-P §4.3"
            } else {
                lappend parts "invoke the facebook skill (Skill tool with skill=facebook) to fetch and parse the Facebook profile per SPAR-P §4.4"
            }
        }
        return "FIRST: [join $parts { AND }]. Then re-derive any front-matter fields whose values depend on that data (star_rating, yield).\n\n"
    }

    # Override: include the first error message in the failure line.
    method report_fix_failure {hard max_fix} {
        set msg [dict get [lindex $hard 0] message]
        my _fail "FAIL (validation failed after $max_fix retries): [my slug] — $msg"
    }

    # Run the full P-phase pipeline. Returns 0 on success, 1 on failure.
    # The try/on-error wrapper logs uncaught exceptions as a FAIL line
    # so the operator sees a per-row outcome instead of a generic
    # "harness exited rc=…" from harness_run.
    method run {} {
        try {
            my load_my_meta
            if {[my inject_linkedin]} { return 1 }
            # do_profile_call returns one of four codes:
            #   0 — turn closed cleanly
            #   1 — hard failure (no usable product)
            #   2 — turn cut short by an EXTERNAL kill / truncation; the
            #       disk product may still hold real work, so fall through
            #       to validate it (FM-HARNESS-2): a complete profile lands
            #       DONE, a partial one surfaces missing_profile and the fix
            #       loop resumes the captured session.
            #   3 — DELIBERATE budget kill (cost cap). The watchdog SIGTERM
            #       lands after the costly research and the profile body are
            #       written but typically before the cheap finalisation the
            #       prompt orders last (the roster star_rating write and the
            #       YAML front matter). Resuming the *research* would re-spend
            #       the budget the cap bounds (#139); resuming only to
            #       FINALISE does no research, so it is cheap and recovers the
            #       near-total spend instead of discarding it. do_finalise_-
            #       after_cost_kill does that single bounded resume, then the
            #       product is validated below like any other run.
            set pc [my do_profile_call]
            if {$pc == 1} { return 1 }
            if {$pc == 3} { my do_finalise_after_cost_kill }
            # Truth-check (#181): a clean close that left a pre-existing
            # outfile byte-identical goes to the requeue path, not to
            # validation, which a stale file passes.
            if {$pc == 0 && [my _outfile_untouched]} {
                return [my _request_requeue]
            }
            # DbC-Post: sanitise masked emails written to the roster, then
            # run validate_profile on both the front matter and roster-row
            # invariants (#39 R1: profile_unreachable_without_exclusion —
            # profile exists iff the row has a reachable channel or
            # date_excluded is set).
            my sanitise_roster_email $RosterPath [my slug]
            if {[my validate_and_correct $Outfile $RosterPath $RequiredSkills]} { return 1 }
            my do_summary
            return 0
        } on error {err opts} {
            my _fail \
                "FAIL ([my slug]): uncaught error in ProfileHarness::run — $err"
            return 1
        }
    }

    method load_my_meta {} {
        set meta [my load_meta]
        set Outfile      [dict get $meta OUTFILE]
        set RosterPath   [dict get $meta ROSTER_PATH]
        set Stem         [dict get $meta STEM]
        set RequiredSkills [dict getdef $meta REQUIRED_SKILLS ""]
        set ContactLinkedin [dict getdef $meta CONTACT_LINKEDIN ""]
        # Snapshot for the post-call truth-check (#181). Bytes, not
        # mtime: consecutive runs can land within mtime granularity (1s),
        # per the ApproachHarness constructor note.
        set OutfilePreexisted [file exists $Outfile]
        set OutfileSnapshot \
            [expr {$OutfilePreexisted ? [spar::read_file $Outfile] : ""}]
    }

    # A re-profile row's outfile already exists, so "the run closed
    # cleanly and a valid file sits at Outfile" does not prove the worker
    # wrote anything: a worker that ends its turn parked on a background
    # fetch leaves the stale file to pass validation (staleness issues
    # are warning-severity) and lands a false DONE (#181).
    method _outfile_untouched {} {
        if {!$OutfilePreexisted} { return 0 }
        if {![file exists $Outfile]} { return 0 }
        return [string equal [spar::read_file $Outfile] $OutfileSnapshot]
    }

    # First occurrence: drop a marker in the prompt dir (which a requeued
    # row reuses) and return 4. harness_run maps 4 to a failed report
    # carrying PROFILE_UNTOUCHED_RETRY, and spar::Dispatcher::on_failed
    # requeues the row at the queue tail, so the retry runs after the
    # congestion that starved this attempt has drained. Marker present
    # means this run WAS the retry: hard FAIL, no loop.
    method _request_requeue {} {
        set marker [file join [my prompt_dir] retry.marker]
        if {[file exists $marker]} {
            my _fail "FAIL (profile untouched after requeue): [my slug] — $Outfile not written (cost=\$[my cost_total])"
            return 1
        }
        spar::write_file $marker \
            "attempt 1 session_id [my session_id]\n"
        ${::spar::harness_log}::info \
            "RETRY: [my slug] profile untouched after clean close, requeued to queue tail (cost=\$[my cost_total])"
        return 4
    }

    # inject_linkedin (skillbooks#182) — prefetch the roster row's
    # LinkedIn parse and substitute __LINKEDIN_SECTION__ in prompt.txt.
    # Runs here so the wait sits in Tcl, inside the overseer's fair
    # queue, before any token is spent; a worker-side fetch under a
    # saturated queue outlives its foreground window instead. The
    # worker reads the parse as text and skips its own fetch, and a
    # successful injection drops `linkedin` from the §4.3 transcript
    # audit's required-skill list: the harness satisfied the
    # requirement itself, so there is nothing left for the transcript
    # check to find.
    # Failure splits on the serialiser's exit code (#184). Exit 78 is
    # its environment code: no browser path at all, overseer absent
    # and standalone impossible. The worker's own §4.3 fetch runs the
    # same binary on the same host, so its turn is guaranteed waste
    # and the row fails here, before any token is spent. Every other
    # failure (65 skill error, 66 rate wall, 75 lock wait, 124 timeout
    # kill) is a transient the truth-check and queue-tail requeue
    # already bound:
    # the section stays empty, the warn names the exit code, and the
    # worker fetches live with the audit unchanged. Returns 1 on the
    # hard failure, 0 otherwise. The outer `timeout 600` bounds a hung
    # serialiser; the overseer queue wait it allows for is minutes,
    # not seconds.
    method inject_linkedin {} {
        set prompt_path [file join [my prompt_dir] prompt.txt]
        set section ""
        if {$ContactLinkedin ne "" && [auto_execok browser-serialiser] ne ""} {
            ${::spar::harness_log}::info \
                "\[[my slug]\] \[phase: linkedin prefetch\]"
            set cmd [auto_execok browser-serialiser]
            lappend cmd linkedin.com/parse-profile $ContactLinkedin
            # GNU timeout is absent on stock macOS; the bound is optional.
            set tmo [auto_execok timeout]
            if {$tmo ne ""} { set cmd [list {*}$tmo 600 {*}$cmd] }
            if {[catch {
                spar::pool_exec {*}$cmd
            } out copts]} {
                set ec [dict getdef $copts -errorcode {}]
                set ecode [expr {[lindex $ec 0] eq "CHILDSTATUS"
                                 ? [lindex $ec 2] : ""}]
                if {$ecode eq "78"} {
                    my _fail "FAIL (no browser path, browser-serialiser exit 78: overseer absent and standalone unavailable): [my slug]"
                    return 1
                }
                ${::spar::harness_log}::warn \
                    "\[[my slug]\] linkedin prefetch failed (exit ${ecode}; worker fetches live): $out"
            } else {
                set RequiredSkills \
                    [lsearch -all -inline -not -exact $RequiredSkills linkedin]
                set section "\n\n## LinkedIn — prefetched by dispatcher\n\nThe linkedin skill's parse-profile output for $ContactLinkedin, fetched just before this session started. Treat it as your §4.3 LinkedIn lookup; a re-fetch would only repeat the browser queue wait.\n\n\$ browser-serialiser linkedin.com/parse-profile $ContactLinkedin\n[string trim $out]\n"
            }
        }
        set prompt [spar::read_file $prompt_path]
        set prompt [string map [list __LINKEDIN_SECTION__ $section] $prompt]
        spar::write_file $prompt_path $prompt
        return 0
    }

    # DbC-Pre: roster integrity for this segment was validated at
    # spar::p::_run_segment entry (load_roster enforces field-count
    # assertion; required input files existence-checked there). The
    # agent inherits a roster known to be well-formed.
    method do_profile_call {} {
        set slug       [my slug]
        set log_prefix [my log_prefix]
        set prompt_dir [my prompt_dir]

        ${::spar::harness_log}::info "\[$slug\] \[phase: researching\]"
        ${::spar::harness_log}::info "\[$slug\] Profile: researching..."
        set draft_log "${log_prefix}-profile.log"
        set prompt [spar::read_file [file join $prompt_dir prompt.txt]]
        return [my call "profile" $draft_log $prompt]
    }

    # do_finalise_after_cost_kill — recover a cost-cap-killed profile worker.
    # The watchdog SIGTERM lands after the costly research and the profile
    # body are written but before the cheap finalisation (the roster
    # star_rating sqlite write and the YAML front matter, which the prompt
    # orders last), so discarding the worker loses near-all the spend and
    # leaves a body-only profile with no front matter that the validator
    # rejects. coachman's finalise_resume does the single bounded resume
    # under the cap plus its headroom, with a self-contained finalise
    # prompt that does no research, so it cannot re-spend the research
    # budget; absent a captured session it warns and resumes nothing. The
    # post-profile validate_and_correct in run() is the verdict either
    # way: a now-complete profile lands DONE, a still-partial one resumes
    # to be fixed.
    method do_finalise_after_cost_kill {} {
        if {[my session_id] ne ""} {
            ${::spar::harness_log}::info \
                "\[[my slug]\] \[phase: finalising (post cost-cap)\]"
        }
        my finalise_resume finalise "[my log_prefix]-finalise.log" \
            [my load_prompt spar-p-finalise [dict create \
                STEM        $Stem \
                OUTFILE     $Outfile \
                ROSTER_PATH $RosterPath]]
    }

    method do_summary {} {
        set total_cost [my cost_total]
        ${::spar::harness_log}::info "DONE: [my slug] (cost=\$$total_cost)"
    }
}

package provide spar-harness 1.0
