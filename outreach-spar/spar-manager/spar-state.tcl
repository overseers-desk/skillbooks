#!/usr/bin/env tclsh9.0
# spar-state.tcl — State machine library for SPAR campaign manager
# Pure read-only library: reads filesystem and TSV, returns current state.
# Sourced by both wish (GUI) and tclsh (CLI).

source [file join [file dirname [file normalize [info script]]] spar-lib.tcl]

# Transition classes populate ::spar::transitions::registry at load time.
# base.tcl declares the base class + registration proc; subclass files
# declare one class per "kind" of transition and call register to bind
# each T-id. This file's accessors then delegate to the registry — no
# parallel list of T-ids is maintained anywhere else.
apply {{} {
    set here [file dirname [file normalize [info script]]]
    set td [file join $here transitions]
    uplevel #0 [list source [file join $td base.tcl]]
    foreach f {profile.tcl approach.tcl send_email.tcl check_replies.tcl \
               linkedin_followup.tcl manual_followup.tcl} {
        uplevel #0 [list source [file join $td $f]]
    }
    # Drift check: registered T-ids must match state-machine.md.
    # Silent no-op if the doc is absent (tests, migrations).
    ::spar::transitions::assert_matches_doc [file join $here state-machine.md]
}}

# Captured at source time for the prefetch_approach_cache worker initcmd:
# tpool workers run in fresh interps and `source $::spar::_state_file`
# bootstraps them with the same projection helpers and yaml dependency
# the main interp has. Resolved against the symlinked-resolved path so
# workers see the same file even if callers source via a relative path.
namespace eval spar { variable _state_file [file normalize [info script]] }

namespace eval spar {
    namespace export detect_duplicates progress_counts \
        roster_counts \
        keychain_available \
        validate_campaign validate_campaign_semantics validate_sender_block \
        validate_approach validate_profile audit_skills_in_transcript \
        read_profile_front_matter build_warnings \
        final_email_message \
        has_transition_runner \
        transition_label transition_auto_safe transition_dispatch_status \
        transition_supports_reauthor \
        transition_tids ui_transition_tids
}

# find_tool -- resolve a tool name to an absolute path via $PATH.
# Returns "" if the tool is not on PATH; callers are expected to flag
# that condition rather than probe for a user-configurable override.
proc spar::find_tool {name} {
    return [auto_execok $name]
}

# keychain_available -- 1 iff this host can store SMTP passwords in an
# OS-native secret store. macOS always has `security`; Linux depends on
# libsecret-tools being installed; Windows is runtime-probed exactly
# once (PowerShell PasswordVault is built in from Windows 8 onwards, but
# can fail on locked-down hosts).  Result is cached in a namespace var.
namespace eval spar { variable _keychain_probe "" }
proc spar::keychain_available {} {
    variable _keychain_probe
    if {$_keychain_probe ne ""} { return $_keychain_probe }
    global tcl_platform
    switch $tcl_platform(os) {
        "Darwin" {
            set _keychain_probe [expr {[auto_execok security] ne ""}]
        }
        "Linux" {
            set _keychain_probe [expr {[auto_execok secret-tool] ne ""}]
        }
        "Windows NT" {
            if {[auto_execok powershell] eq ""} {
                set _keychain_probe 0
            } else {
                set script "try { \[void\](New-Object Windows.Security.Credentials.PasswordVault); 'ok' } catch { 'fail' }"
                if {[catch {exec powershell -NoProfile -NonInteractive -Command $script} out]} {
                    set _keychain_probe 0
                } else {
                    set _keychain_probe [expr {[string trim $out] eq "ok"}]
                }
            }
        }
        default { set _keychain_probe 0 }
    }
    return $_keychain_probe
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
#
# Instrumentation: increments ::spar::parse_count on every successful or
# failed parse. The counter is the canonical signal for verifying that
# render-path consumers go through the State cache; the parse-count
# assertion in /tmp/spar84-parse-count.tcl reads it. Test/bench callers
# can reset via `set ::spar::parse_count 0`. Cost is one set + one incr
# per parse (negligible against the parse itself).
namespace eval spar { variable parse_count 0 }
proc spar::read_approach_yaml {path} {
    incr ::spar::parse_count
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
        set data [spar::yaml_parse $raw]
    } err]} {
        if {$fd ne ""} {
            catch {close $fd}
        }
        return ""
    }
    return $data
}

# read_segment_yaml — safely read and parse a segment.yaml file.
# Returns parsed dict, or empty string on failure / missing file.
proc spar::read_segment_yaml {path} {
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
        set data [spar::yaml_parse $raw]
    } err]} {
        if {$fd ne ""} {
            catch {close $fd}
        }
        return ""
    }
    return $data
}

# final_channel_message — return the first final-round message dict on the
# given channel, or "" if the final round has none. For email, callers rely
# on the ≤1 invariant enforced by validate_approach (too_many_final_emails);
# if multiple are present (validator bypass or malformed file), returning the
# first fails safe rather than silently mis-targeting a send.
proc spar::final_channel_message {data channel} {
    if {$data eq "" || ![dict exists $data rounds]} { return "" }
    foreach round [dict get $data rounds] {
        if {![dict exists $round type]} continue
        if {[dict get $round type] ne "final"} continue
        if {![dict exists $round messages]} { return "" }
        foreach msg [dict get $round messages] {
            if {[dict getdef $msg channel ""] eq $channel} {
                return $msg
            }
        }
        return ""
    }
    return ""
}

proc spar::final_email_message {data} {
    return [spar::final_channel_message $data email]
}

# t6_send_channel — the channel T6 dispatches for one contact: the
# channel of the first final-round message that is email or linkedin.
# Message order in the final round encodes the contact's own primary
# touch; secondary and tertiary channels belong to T9/T10. Routing is
# per contact, not per campaign, so an email-only contact in a
# linkedin-primary campaign still sends by email. Returns email,
# linkedin, or "" when the final round leads with no auto-send channel
# (e.g. phone-only).
proc spar::t6_send_channel {data} {
    if {$data eq "" || ![dict exists $data rounds]} { return "" }
    foreach round [dict get $data rounds] {
        if {![dict exists $round type]} continue
        if {[dict get $round type] ne "final"} continue
        if {![dict exists $round messages]} { return "" }
        foreach msg [dict get $round messages] {
            set ch [dict getdef $msg channel ""]
            if {$ch eq "email" || $ch eq "linkedin"} { return $ch }
        }
        return ""
    }
    return ""
}

# analyse_final_round — extract state and channel properties from approach YAML data.
# Returns dict with keys: has_final, any_sent, email_sent, linkedin_sent,
#   any_replied, to_addresses, unsent_subjects, messages.
# `messages` is a list of per-message dicts {channel actioned_date replied_date
#   is_actioned is_replied} used by T9/T10 channel-readiness evaluation.
proc spar::analyse_final_round {data} {
    set result [dict create \
        has_final 0 \
        any_sent 0 \
        email_sent 0 \
        linkedin_sent 0 \
        any_replied 0 \
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
                set channel [dict getdef $msg channel ""]
                set actioned [dict getdef $msg actioned_date ""]
                set replied [dict getdef $msg replied_date ""]
                set to_addr [dict getdef $msg to ""]
                set subject [dict getdef $msg subject ""]

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
                    dict set result any_replied 1
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
                if {[dict getdef $reply direction ""] eq "received"} {
                    dict set result any_replied 1
                }
            }
        }
    }

    return $result
}

# spar::State — owns per-unit-of-work classification. Phase B hangs an
# approach-summary cache off the instance: render-path consumers
# (refine_contact, the 5 transition `eligible` paths,
# approach_validation_error, channel_readiness via
# final_round_messages_for_contact) all route through approach_summary,
# so a contact eligible for T6+T7+T9+T10 incurs one parse per State
# lifetime instead of 4–8.
#
# ApproachCache is a dict approach_path → {hash mtime summary} where
# `hash` is the line-1 profile_hash hex (or "" for legacy approaches
# without one) and `mtime` is the file's mtime when last parsed. On
# cache hit, both are re-probed cheaply (one gets + one stat) before
# the cached summary is returned; mismatch on either drops the entry.
#
# Parse cost on the read path is shaped first by avoidance: the cache +
# cheap-tier classification keep cold-render parses to one-per-APPROACHED-
# contact and zero across renders within a State's lifetime. The
# remaining cold-load batch is dispatched by prefetch_approach_cache as
# fire-and-forget tpool jobs; approach_summary blocks per-path on a
# pending job only when a consumer actually asks for that path, so
# main-thread work overlaps with worker parses. Further reduction
# extends avoidance (e.g. front-matter caching for _profile_is_stale)
# before adding more parallelism.
oo::class create spar::State {
    variable ApproachCache Pool PendingJobs
    constructor {} {
        set ApproachCache [dict create]
        set Pool ""
        set PendingJobs [dict create]
    }
    destructor {
        if {$Pool ne ""} {
            # Drain any in-flight prefetch jobs before releasing the pool —
            # tpool::release would orphan their results otherwise.
            if {[dict size $PendingJobs]} {
                foreach jid [dict values $PendingJobs] {
                    catch {tpool::wait $Pool $jid}
                    catch {tpool::get $Pool $jid}
                }
            }
            catch {tpool::release $Pool}
        }
    }
}

# forget_approach -- drop the cached projection for a specific approach
# path. Used by writers (spar-a-harness.tcl's validate_and_correct loop)
# that rewrite the file mid-run: mtime granularity is 1s on some
# filesystems and the line-1 profile_hash often stays the same across
# retries, so neither hash+mtime invalidator can be relied on for
# back-to-back rewrites. An explicit forget after each write closes
# that window.
oo::define spar::State method forget_approach {approach_path} {
    if {[dict exists $ApproachCache $approach_path]} {
        set ApproachCache [dict remove $ApproachCache $approach_path]
    }
    # Drop any in-flight prefetch for this path — its result was captured
    # against the pre-rewrite bytes and would re-cache stale data on the
    # next approach_summary call. Drain (but discard) the worker so the
    # job slot is reclaimed cleanly.
    if {[dict exists $PendingJobs $approach_path]} {
        set jid [dict get $PendingJobs $approach_path]
        set PendingJobs [dict remove $PendingJobs $approach_path]
        catch {tpool::wait $Pool $jid}
        catch {tpool::get $Pool $jid}
    }
}

# _ensure_pool -- lazy-create the tpool worker pool. Pre-spawned with
# -minworkers = -maxworkers so all workers run their initcmd in parallel
# at pool creation; the alternative (-minworkers 0, lazy spawn) costs
# more on first prefetch because the first refine_contact that joins a
# pending job blocks while the worker spawns and sources spar-state.tcl
# (~300 ms). Sized to _NPROCESSORS_ONLN capped at 8 — past ~4 workers the
# main-thread join cost of projection dicts becomes the serial floor.
# -idletime 30 still decays workers if the pool sits unused, matching
# the State's lifetime hygiene. Workers source spar-state.tcl wholesale;
# the transitions/* files come along but are dead weight (workers never
# call them).
oo::define spar::State method _ensure_pool {} {
    if {$Pool ne ""} return
    package require Thread
    set n [expr {min([exec getconf _NPROCESSORS_ONLN], 8)}]
    set Pool [tpool::create \
        -minworkers $n \
        -maxworkers $n \
        -idletime   30 \
        -initcmd    [list source $::spar::_state_file]]
}

# prefetch_approach_cache -- fire-and-forget tpool dispatch for a list
# of approach paths. Each path that is not already cache-valid and not
# already in-flight is posted as a worker job; the job ID is stored in
# PendingJobs keyed by path. The method returns immediately, so the
# caller's main-thread work overlaps with worker parses. Cache writes
# happen later, in approach_summary, when a consumer first asks for
# that path: cache hit short-circuits, otherwise the pending job is
# joined and its result becomes the cache entry.
#
# Skips paths already valid in the cache (line-1 hash + mtime match),
# already in-flight (PendingJobs has the path), missing files, and
# empty strings. Workers capture hash+mtime alongside the parse so the
# tuple they return is race-free against the bytes they parsed.
#
# parse_count is incremented at cache-write time inside approach_summary,
# not here — the parse logically completes when the cache absorbs the
# result, and that point is where the test instrumentation is anchored.
oo::define spar::State method prefetch_approach_cache {paths} {
    set need {}
    foreach p $paths {
        if {$p eq "" || ![file exists $p]} continue
        if {[dict exists $PendingJobs $p]} continue
        set h [spar::_approach_first_line_hash $p]
        set m [file mtime $p]
        if {[dict exists $ApproachCache $p]} {
            set e [dict get $ApproachCache $p]
            if {[dict get $e hash] eq $h && [dict get $e mtime] eq $m} continue
        }
        lappend need $p
    }
    if {[llength $need] == 0} return
    my _ensure_pool
    foreach p $need {
        dict set PendingJobs $p \
            [tpool::post -nowait $Pool [list spar::_parse_worker_run $p]]
    }
}

# approach_summary -- return a cached projection of the contact's
# approach YAML, parsing only when the cache misses or the file's
# line-1 hash / mtime have moved. Render-path consumers call this
# instead of spar::read_approach_yaml so a contact eligible for
# T6+T7+T9+T10 incurs one parse per State lifetime, not four.
#
# Bypass-site rule: write paths (transitions/send_email.tcl), DbC
# snapshots in spar-dispatch.tcl, and the inspector continue to call
# spar::read_approach_yaml directly — they need fresh bytes and a
# cached projection would mask post-agent edits / in-flight writes.
#
# Returns the projection dict, or {} if the contact has no approach
# file or it cannot be parsed. The projection is what
# project_approach_data returns; field set is documented there.
oo::define spar::State method approach_summary {contact} {
    set ap [dict getdef $contact approach_path ""]
    if {$ap eq "" || ![file exists $ap]} { return {} }

    # Cheap validity probes — line-1 hash (one gets) and mtime (stat).
    # Together they catch the two ways an approach changes under us:
    # an A re-author rewrites the whole file (mtime advances; hash
    # often advances too if the profile changed), and an in-place edit
    # (validator fix loop, manual touch-up) advances mtime even when
    # line-1 hash stays put.
    set cur_hash [spar::_approach_first_line_hash $ap]
    set cur_mtime [file mtime $ap]

    if {[dict exists $ApproachCache $ap]} {
        set entry [dict get $ApproachCache $ap]
        if {[dict get $entry hash] eq $cur_hash \
                && [dict get $entry mtime] eq $cur_mtime} {
            return [dict get $entry summary]
        }
        # stale; fall through to re-parse
    }

    # Consume a pending prefetch for this path rather than re-parsing on
    # the main thread. tpool::wait on a single jobid pumps the event loop,
    # so Tk widgets keep painting while we block. The worker captured
    # hash+mtime atomically against the bytes it parsed; the next call's
    # cache probe re-validates against the current file, so a file
    # rewritten between post and consume self-corrects on the next call.
    if {[dict exists $PendingJobs $ap]} {
        set jid [dict get $PendingJobs $ap]
        set PendingJobs [dict remove $PendingJobs $ap]
        tpool::wait $Pool $jid
        if {![catch {tpool::get $Pool $jid} r]} {
            dict set ApproachCache $ap [dict create \
                hash    [dict get $r hash]    \
                mtime   [dict get $r mtime]   \
                summary [dict get $r summary]]
            incr ::spar::parse_count
            return [dict get $r summary]
        }
        # Worker errored — fall through to synchronous parse on this call.
    }

    set data [spar::read_approach_yaml $ap]
    if {$data eq ""} {
        # Parse failure — cache "" so callers consistently see an empty
        # projection and a re-parse only happens after the file changes.
        dict set ApproachCache $ap [dict create \
            hash $cur_hash mtime $cur_mtime summary {}]
        return {}
    }

    set summary [spar::project_approach_data $data]
    dict set ApproachCache $ap [dict create \
        hash $cur_hash mtime $cur_mtime summary $summary]
    return $summary
}

# project_approach_data -- build the render-path projection of a parsed
# approach YAML. Preserves the key skeleton at every level so the
# yamlmuster vocab rules (rules/approach.rules, via validate_approach)
# still flag drift, but blanks heavy text values
# (body, reply_summary, script[*]/text, replies[*]/text) so the cache
# stays small. Validator structural checks (`dict exists $msg body`,
# `dict exists $msg subject`) still see the keys; the values they
# don't read are dropped.
#
# Brief constraint: send-time consumers need the full body and call
# spar::read_approach_yaml directly — they are bypass sites and never
# touch the projection.
proc spar::project_approach_data {data} {
    if {$data eq "" || [llength $data] % 2 != 0} { return $data }
    set out [dict create]
    dict for {k v} $data {
        switch -- $k {
            rounds {
                set rounds_out {}
                foreach r $v {
                    lappend rounds_out [spar::_project_round $r]
                }
                dict set out rounds $rounds_out
            }
            decisions -
            fact_provenance -
            quality_checklist -
            angle_rationale -
            response_likelihood -
            a_note -
            r_note -
            profile_hash {
                # Small / structural — copy through.
                dict set out $k $v
            }
            default {
                # Unknown root key: preserve so the vocab rule can
                # flag it.
                dict set out $k $v
            }
        }
    }
    return $out
}

# _project_round -- helper for project_approach_data.
proc spar::_project_round {round} {
    if {[llength $round] % 2 != 0} { return $round }
    set out [dict create]
    dict for {k v} $round {
        switch -- $k {
            messages {
                set msgs_out {}
                foreach m $v { lappend msgs_out [spar::_project_message $m] }
                dict set out messages $msgs_out
            }
            replies {
                set replies_out {}
                foreach rep $v { lappend replies_out [spar::_project_reply $rep] }
                dict set out replies $replies_out
            }
            default {
                dict set out $k $v
            }
        }
    }
    return $out
}

# _project_message -- preserve key skeleton, blank the heavy text
# values (body, reply_summary, script[*]/text). channel/subject/to/
# actioned_date/replied_date/mode/parent are read by render-path
# consumers and pass through unchanged. Exception: linkedin bodies are
# kept — they are ≤ a few hundred chars and the validator's length and
# char_count checks (#159) measure them on this projection; blanking
# would let an over-long note through the T6-T10 gate and falsely flag
# every honest char_count.
proc spar::_project_message {msg} {
    if {[llength $msg] % 2 != 0} { return $msg }
    set out [dict create]
    dict for {k v} $msg {
        switch -- $k {
            body {
                if {[dict getdef $msg channel ""] eq "linkedin"} {
                    dict set out $k $v
                } else {
                    dict set out $k ""
                }
            }
            reply_summary {
                # Key preserved (validator checks `dict exists $msg body`),
                # value blanked — wire content lives on disk and is read
                # by the bypass site at send time.
                dict set out $k ""
            }
            script {
                set items_out {}
                foreach item $v { lappend items_out [spar::_project_script_item $item] }
                dict set out script $items_out
            }
            default {
                dict set out $k $v
            }
        }
    }
    return $out
}

# _project_script_item -- preserve key skeleton (so the closed-
# vocabulary walk at script_item level still operates), blank text
# value. The script_item vocab rule walks key presence; dropping
# the `text` key would break the walk silently.
proc spar::_project_script_item {item} {
    if {[llength $item] % 2 != 0} { return $item }
    set out [dict create]
    dict for {k v} $item {
        if {$k eq "text"} {
            dict set out $k ""
        } else {
            dict set out $k $v
        }
    }
    return $out
}

# _project_reply -- preserve direction (analyse_final_round reads it to
# compute any_replied) and any other keys present (so unknown-key
# walks still work), blank the text body.
proc spar::_project_reply {reply} {
    if {[llength $reply] % 2 != 0} { return $reply }
    set out [dict create]
    dict for {k v} $reply {
        if {$k eq "text"} {
            dict set out $k ""
        } else {
            dict set out $k $v
        }
    }
    return $out
}

# _parse_worker_run -- tpool worker entry. Takes an approach file path
# and returns a result tuple {path summary hash mtime} that the main
# thread uses to populate ApproachCache atomically. Hash and mtime are
# captured here so they are race-free against the bytes the worker
# parsed; main-thread storage uses the worker's tuple verbatim. Parse
# failure (missing file, malformed YAML) returns summary = {} — same
# semantics as the serial path.
proc spar::_parse_worker_run {path} {
    set hash  [spar::_approach_first_line_hash $path]
    set mtime [expr {[file exists $path] ? [file mtime $path] : 0}]
    set data  [spar::read_approach_yaml $path]
    set summary [expr {$data eq "" ? {} : [spar::project_approach_data $data]}]
    return [dict create path $path summary $summary hash $hash mtime $mtime]
}

# classify_contact -- classify one contact's cheap state.
#
# Returns the cheap projection only — state collapsed to APPROACHED for
# any approach-having contact (no SENT/REPLIED/APPROACH_STALE-via-parse
# refinement; APPROACH_STALE is still detected via the line-1 hash, which
# does not require a full YAML parse). Refined fields (SENT/REPLIED, the
# any_sent / email_sent / linkedin_sent / any_replied / to_addresses /
# unsent_subjects projections) are computed lazily by `refine_contact`, which
# routes through `approach_summary`'s per-instance cache. Cheap-tier
# callers (DISCOVERED/PROFILED/EXCLUDED routing, T1..T4 eligibility)
# never refine and pay zero parse cost.
#
# roster_row   dict with TSV fields (contact_name, date_excluded,
#              star_rating, email, linkedin_url, facebook_url, phone,
#              stem, ...)
#              stem is required; classify_segment validates its presence
#              before calling this method.
# segment_dir  absolute path to the segment directory
#
# Returns a dict:
#   state         one of: EXCLUDED DISCOVERED PROFILED PROFILE_STALE
#                         APPROACHED APPROACH_STALE
#                 (SENT / REPLIED only after refine_contact)
#   profile_path  path to profile file, or empty string
#   approach_path path to approach YAML, or empty string
#   star          integer (0 if blank/unparseable)
#   has_email     bool
#   has_linkedin  bool
#   has_facebook  bool
#   has_phone_only bool
#   any_sent      0 (placeholder; populated by refine_contact)
#   email_sent    0 (placeholder; populated by refine_contact)
#   linkedin_sent 0 (placeholder; populated by refine_contact)
#   any_replied   0 (placeholder; populated by refine_contact)
#   to_addresses     {} (placeholder; populated by refine_contact)
#   unsent_subjects  {} (placeholder; populated by refine_contact)
#
oo::define spar::State method classify_contact {roster_row segment_dir} {
    # Extract roster fields with safe defaults.
    # strip_tsv_field: trim whitespace, and if the remaining value is a
    # quoted-empty-or-whitespace string (e.g. `" "` or `""`), collapse to "".
    # This happens when TSV was edited with a tool that CSV-quotes blank fields.
    set date_invalid [string trim [dict getdef $roster_row date_excluded ""]]
    set stem [string trim [dict getdef $roster_row stem ""]]
    # P-authored (see spar-P-profile.md §5.1). Roster column is a query-
    # optimised cache for band filters and state predicates; the authorial
    # home is the profile front matter. Not an input to profiling.
    set star_raw [dict getdef $roster_row star_rating ""]
    set email [string trim [dict getdef $roster_row email ""]]
    set linkedin [string trim [dict getdef $roster_row linkedin_url ""]]
    set facebook [string trim [dict getdef $roster_row facebook_url ""]]
    set phone [string trim [dict getdef $roster_row phone ""]]

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

    # Result dict: defaults for paths and approach-derived fields. Each
    # branch overrides `state` (and, after parsing the approach YAML,
    # any_sent/email_sent/linkedin_sent/any_replied/to_addresses/unsent_subjects)
    # before returning. to_addresses/unsent_subjects are carried through so
    # detect_duplicates parses the YAML once per contact, not twice.
    set base [dict create \
        state "" \
        profile_path "" \
        approach_path "" \
        star $star \
        has_email $has_email \
        has_linkedin $has_linkedin \
        has_facebook $has_facebook \
        has_phone_only $has_phone_only \
        any_sent 0 \
        email_sent 0 \
        linkedin_sent 0 \
        any_replied 0 \
        to_addresses {} \
        unsent_subjects {}]

    # State evaluation (ordered — first match wins)

    # 1. EXCLUDED
    if {![spar::is_null $date_invalid]} {
        dict set base state EXCLUDED
        return $base
    }

    # 2. DISCOVERED — profile file does not exist AND no approach exists.
    #    If an approach exists pointing at a missing profile, the contact
    #    needs re-profiling, not first-time profiling — fall through to
    #    PROFILE_STALE below so T3 picks it up. After T3 re-profiles, the
    #    approach's stored profile_hash will mismatch the freshly-written
    #    profile and T4 will route the re-approach (#63).
    set profile_path [spar::profile_path_for_stem $segment_dir $stem]
    set approach_path [spar::approach_path_for_stem $segment_dir $stem]
    set profile_exists [file exists $profile_path]
    set approach_exists [file exists $approach_path]
    if {!$profile_exists && !$approach_exists} {
        dict set base state DISCOVERED
        return $base
    }
    if {$profile_exists} {
        dict set base profile_path $profile_path
    }

    # 3. PROFILED / PROFILE_STALE — determine whether the profile is fresh,
    # missing-but-needed (approach exists), or divergent from the roster
    # snapshot. Malformed front matter does not flip to STALE —
    # validate_profile catches that separately; staleness here is only
    # about roster-vs-snapshot divergence and approach-references-missing.
    set profile_state PROFILED
    if {!$profile_exists} {
        set profile_state PROFILE_STALE
    } elseif {[spar::_profile_is_stale $profile_path $roster_row]} {
        set profile_state PROFILE_STALE
    }

    if {!$approach_exists} {
        dict set base state $profile_state
        return $base
    }
    dict set base approach_path $approach_path

    # If the approach references a missing profile, route via T3 first.
    # The approach is preserved on disk; T3 re-profiles, then the next
    # sweep observes the hash mismatch (or, if no hash was stored, the
    # operator runs T4 manually) and re-approaches. This branch needs no
    # parse — file presence + the missing profile is sufficient signal.
    if {!$profile_exists} {
        dict set base state PROFILE_STALE
        return $base
    }

    # APPROACH_STALE check (#63): reads only the first line of the
    # approach file via spar::_approach_first_line_hash, so we can
    # answer it without a full YAML parse. Callers that need
    # SENT/REPLIED (which DOES require parsing) call refine_contact;
    # cheap-tier callers (T1..T4) never see those states.
    set hash_stale [spar::_approach_hash_mismatch $profile_path $approach_path]
    if {$hash_stale} {
        dict set base state APPROACH_STALE
    } else {
        dict set base state APPROACHED
    }
    return $base
}

# refine_contact -- promote a cheap-classified contact dict to its
# refined form by parsing the approach YAML (via approach_summary, so
# the parse is shared across the render). Returns a new dict with
# SENT/REPLIED resolved on `state` and any_sent / email_sent /
# linkedin_sent / any_replied / to_addresses / unsent_subjects populated.
#
# Idempotent: refining an already-refined contact rebuilds from the
# (cached) projection. Refining a contact whose state is something
# other than APPROACHED / APPROACH_STALE (DISCOVERED, PROFILED,
# EXCLUDED, etc.) is a no-op — those states cannot host a final-round
# message, so the parse is skipped and the contact is returned
# unchanged.
#
# Callers that need refined fields call this on a per-contact basis
# (UI inspector, send transitions) or via refine_segment (UI render,
# spar-progress.tcl, T6/T7/T8/T9/T10 eligibility).
oo::define spar::State method refine_contact {contact} {
    set state [dict getdef $contact state ""]
    if {$state ne "APPROACHED" && $state ne "APPROACH_STALE"} {
        return $contact
    }
    set ap [dict getdef $contact approach_path ""]
    if {$ap eq "" || ![file exists $ap]} { return $contact }

    set approach_data [my approach_summary $contact]
    set fr [spar::analyse_final_round $approach_data]
    dict set contact any_sent        [dict get $fr any_sent]
    dict set contact email_sent      [dict get $fr email_sent]
    dict set contact linkedin_sent   [dict get $fr linkedin_sent]
    # The contact's own T6 send channel, from its final round's message
    # order — promoted here so eligibility routes per contact without
    # re-parsing (and without send_email.tcl touching the projection cache).
    dict set contact t6_send_channel [spar::t6_send_channel $approach_data]
    dict set contact any_replied     [dict get $fr any_replied]
    dict set contact to_addresses    [dict get $fr to_addresses]
    dict set contact unsent_subjects [dict get $fr unsent_subjects]

    # Promote the campaign-bound engagement fields from the approach YAML
    # onto the contact dict. They live in the approach file (not the roster),
    # so any consumer expecting them on the contact (e.g. the inspector's
    # A-tab title) reads them from here.
    dict set contact response_likelihood [dict getdef $approach_data response_likelihood ""]
    dict set contact a_note              [dict getdef $approach_data a_note ""]
    dict set contact r_note              [dict getdef $approach_data r_note ""]

    # REPLIED — SENT and (replied_date or reply with direction:received).
    if {[dict get $fr any_sent] && [dict get $fr any_replied]} {
        dict set contact state REPLIED
        return $contact
    }
    # SENT — final round has at least one message with actioned_date.
    # SENT/REPLIED supersede APPROACH_STALE: a contact already engaged is
    # not re-approached on hash mismatch alone (would clobber send history).
    if {[dict get $fr any_sent]} {
        dict set contact state SENT
        return $contact
    }
    # APPROACHED / APPROACH_STALE retained as-set by classify_contact.
    return $contact
}

# refine_segment -- map refine_contact over a list of cheap-classified
# contacts. Cheap-tier states pass through untouched; APPROACHED /
# APPROACH_STALE contacts are promoted via the cache. Bulk form for
# the UI render path and progress.tcl.
oo::define spar::State method refine_segment {contacts} {
    set out {}
    foreach c $contacts {
        lappend out [my refine_contact $c]
    }
    return $out
}

# classify_segment -- load roster and classify all contacts (cheap form).
#
# segment_dir  absolute path to the segment directory
#
# Returns a list of dicts, one per valid+named roster row, each being
# the result of classify_contact merged with the original roster_row.
# Refined fields are placeholders — call refine_segment (or
# refine_contact per-row) on the result when SENT / REPLIED /
# any_sent / email_sent / linkedin_sent / any_replied / to_addresses /
# unsent_subjects are needed.
#
# On schema error, throws an error.
#
oo::define spar::State method classify_segment {segment_dir} {
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
        set classified [my classify_contact $row $segment_dir]

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

# final_round_messages_for_contact -- return the per-message list from
# analyse_final_round, or {} if no approach file exists. Phase B routes
# this through approach_summary so T9/T10 channel-readiness checks
# share the same parsed projection as classify_contact and the
# eligibility validators.
oo::define spar::State method final_round_messages_for_contact {contact} {
    set adata [my approach_summary $contact]
    if {$adata eq ""} { return {} }
    set fr [spar::analyse_final_round $adata]
    return [dict get $fr messages]
}

# _channel_slot_wait_days -- extract wait_days from a channel slot dict
# (spar-campaign-yaml.md §Required channels). Returns "" if missing.
proc spar::_channel_slot_wait_days {slot} {
    if {$slot eq ""} { return "" }
    if {[llength $slot] <= 1} { return "" }
    return [dict getdef $slot wait_days ""]
}

# _channel_slot_wait_condition -- extract wait_condition. Returns "" if missing.
proc spar::_channel_slot_wait_condition {slot} {
    if {$slot eq ""} { return "" }
    if {[llength $slot] <= 1} { return "" }
    return [dict getdef $slot wait_condition ""]
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

# channel_readiness -- evaluate secondary_ready / tertiary_ready for
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
oo::define spar::State method channel_readiness {contact cdata {today_iso ""}} {
    set out [dict create \
        secondary_ready 0 tertiary_ready 0 \
        secondary_reason "" tertiary_reason ""]
    set primary [spar::campaign_primary_channel $cdata]
    if {$primary eq ""} { return $out }
    set secondary_slot [spar::_campaign_slot $cdata secondary_channel]
    set secondary_ch [spar::_campaign_channel_slot $cdata secondary_channel]
    if {$secondary_ch eq ""} { return $out }

    set messages [my final_round_messages_for_contact $contact]
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
# transition_eligible (T2/T4) and spar::a::_build_prompts apply when
# deciding whether a roster row may be approached. Returns "" if the row passes;
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
# T2 hardcode — star >= 3 + skip excluded — so existing T2 test assertions
# keep passing without threading cdata through.
proc spar::_approach_dispatch_gate {row cdata} {
    set has_cdata [expr {[llength $cdata] > 0}]
    set date_ex [string trim [dict getdef $row date_excluded ""]]
    set skip_excluded 1
    set min_star 3
    set in_scope {}
    if {$has_cdata} {
        set filter [dict getdef $cdata filter [dict create]]
        set skip_excluded [string is true -strict \
            [dict getdef $filter skip_excluded true]]
        set min_star [dict getdef $filter min_star 3]
        set in_scope [spar::campaign_in_scope_channels $cdata]
    }
    if {$skip_excluded && $date_ex ne ""} {
        return "excluded on $date_ex"
    }
    if {![spar::roster_row_has_in_scope_channel $row $in_scope]} {
        return "no in-scope channel (campaign: [join $in_scope {, }])"
    }
    if {$min_star > 0} {
        # star_rating is P-authored (spar-P-profile.md §5.1); the roster
        # column is a cache so this band filter can scan without parsing
        # profiles. Pre-P rows carry 0 and fail the filter by design.
        set star [spar::parse_star [dict getdef $row star_rating ""]]
        if {$star < $min_star} {
            return "star $star below min_star $min_star"
        }
    }
    return ""
}

# _task -- factory for transition task dicts. Every per-T-id `eligible`
# method emits 0 or 1 of these per contact (manual_followup may emit
# dispatchable or awaiting, others typically one shape per branch).
proc spar::_task {contact task_state {reason ""}} {
    set name [dict getdef $contact contact_name ""]
    set org  [dict getdef $contact organisation ""]
    set stem [dict getdef $contact stem ""]
    set segment_dir [dict getdef $contact _segment_dir ""]
    return [dict create \
        contact_name $name organisation $org \
        segment [file tail $segment_dir] \
        stem $stem _segment_dir $segment_dir \
        task_state $task_state reason $reason]
}

# transition_eligible -- filter classified contacts by transition eligibility.
#
# classified_contacts  output of classify_segment, optionally followed by
#                      refine_segment. Parse-TIDs (T6+) require refined
#                      input — they read any_sent / email_sent / any_replied /
#                      to_addresses / unsent_subjects and the SENT/REPLIED
#                      state upgrade that refine_contact installs. Cheap-
#                      TIDs (T1..T4) accept either form: their `eligible`
#                      methods read only state, star_rating, date_excluded,
#                      email, linkedin_url — all populated by the cheap
#                      classify path. Callers that mix TIDs (the loader,
#                      spar-progress, spar-transition non-auto) refine
#                      once before calling here and reuse the refined list
#                      across every TID.
# transition           transition name: T1, T2, ... T10
# primary_channel      campaign primary channel (bare string, e.g. "email").
#                      Empty string = unknown; T6 conservatively yields nothing.
#                      TODO(#49): this arg is an interim gate. Correct
#                      per-message eligibility must route each unsent final-
#                      round message to T6/T8/T9/T10 based on its slot in the
#                      primary/secondary/tertiary structure, not on channel
#                      alone. See issue #49 for acceptance criteria.
#
# Per-T-id logic lives on the corresponding ::spar::transitions::* class as
# its `eligible` method (no leading underscore — TclOO would unexport it
# and external dispatch via the registered object command would fail). This
# method just walks contacts and folds the per-class results.
#
# Returns a list of dicts with keys:
#   contact_name, organisation, segment, task_state (dispatchable/awaiting/blocked/done), reason
#
oo::define spar::State method transition_eligible {classified_contacts transition \
        {primary_channel ""} {cdata {}} {today_iso ""}} {
    set t [::spar::transitions::get $transition]
    set out {}
    foreach contact $classified_contacts {
        foreach task [$t eligible [self] $contact $primary_channel $cdata $today_iso] {
            lappend out $task
        }
    }
    return $out
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
        set name [dict getdef $contact contact_name ""]
        set org [dict getdef $contact organisation ""]
        set email [string trim [string tolower [dict getdef $contact email ""]]]
        set segment_dir [dict getdef $contact _segment_dir ""]
        set segment [file tail $segment_dir]
        set approach_path [dict get $contact approach_path]
        set state [dict get $contact state]

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
        foreach addr [dict getdef $contact to_addresses {}] {
            set addr_lower [string tolower [string trim $addr]]
            if {$addr_lower ne "" && [string first "@" $addr_lower] >= 0} {
                lappend to_map($addr_lower) [list $segment $filename]
            }
        }

        # Identical subject lines in unsent approach files
        foreach subj [dict getdef $contact unsent_subjects {}] {
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
#   valid, profiled, star3, approached_star3, has_email,
#   has_linkedin, has_facebook, has_phone_only, sent, replied
#
proc spar::progress_counts {classified_contacts} {
    set valid 0
    set profiled 0
    set star3 0
    set approached_star3 0
    set has_email 0
    set has_linkedin 0
    set has_facebook 0
    set has_phone_only 0
    set n_sent 0
    set n_replied 0

    # States that are "profiled or above"
    set profiled_plus {PROFILED PROFILE_STALE APPROACHED APPROACH_STALE SENT REPLIED}
    # States that are "approached or above"
    set approached_plus {APPROACHED APPROACH_STALE SENT REPLIED}

    foreach contact $classified_contacts {
        set state [dict get $contact state]
        set star [dict get $contact star]
        set c_has_email [dict get $contact has_email]
        set c_has_linkedin [dict get $contact has_linkedin]
        set c_has_facebook [dict get $contact has_facebook]
        set c_has_phone_only [dict get $contact has_phone_only]

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

            # Sent / replied are projections of the SENT / REPLIED states
            # themselves: a message actioned on any channel, a reply
            # received on any channel.
            if {$state in {SENT REPLIED}} {
                incr n_sent
            }
            if {$state eq "REPLIED"} {
                incr n_replied
            }
        }
    }

    return [dict create \
        valid $valid \
        profiled $profiled \
        star3 $star3 \
        approached_star3 $approached_star3 \
        has_email $has_email \
        has_linkedin $has_linkedin \
        has_facebook $has_facebook \
        has_phone_only $has_phone_only \
        sent $n_sent \
        replied $n_replied]
}

# roster_counts -- compute progress counts from roster TSV alone (no filesystem).
#
# segment_dir  absolute path to the segment directory
#
# Returns a dict with the six TSV-derivable counts:
#   valid, star3, has_email, has_linkedin, has_facebook, has_phone_only
# These correspond to columns that do not require profile/approach file access.
# Counts not computable from the TSV alone (profiled, approached_star3,
# sent, replied) are omitted.
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
        set date_invalid [string trim [dict getdef $row date_excluded ""]]
        if {[regexp {^"(.*)"$} $date_invalid -> inner]} {
            set date_invalid [string trim $inner]
        }
        if {![spar::is_null $date_invalid]} continue

        set contact_name [string trim [dict getdef $row contact_name ""]]

        incr valid

        set star [spar::parse_star [dict getdef $row star_rating ""]]

        set email [string trim [dict getdef $row email ""]]
        if {[regexp {^"(.*)"$} $email -> inner]} { set email [string trim $inner] }
        set linkedin [string trim [dict getdef $row linkedin_url ""]]
        if {[regexp {^"(.*)"$} $linkedin -> inner]} { set linkedin [string trim $inner] }
        set facebook [string trim [dict getdef $row facebook_url ""]]
        if {[regexp {^"(.*)"$} $facebook -> inner]} { set facebook [string trim $inner] }
        set phone [string trim [dict getdef $row phone ""]]
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

# missing fences, YAML parse error).
proc spar::read_profile_front_matter {path} {
    if {![file exists $path]} { return "" }
    set fd ""
    try {
        set fd [open $path r]
        fconfigure $fd -encoding utf-8
        set raw [read $fd]
    } on error {} {
        return ""
    } finally {
        if {$fd ne ""} { catch {close $fd} }
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
    if {[catch { set data [spar::yaml_parse $fm_text] } err]} {
        return ""
    }
    return $data
}

# read_profile_body -- return the text after the closing `---` fence of the
# front-matter block. Returns "" for a missing file. When no opening fence is
# present, returns the whole file (tolerates legacy/malformed profiles). When
# an opening fence is present but the closing fence is missing, returns ""
# (matches read_profile_front_matter's strictness).
proc spar::read_profile_body {path} {
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
    if {[llength $lines] < 2 || [string trim [lindex $lines 0]] ne "---"} {
        return $raw
    }
    for {set i 1} {$i < [llength $lines]} {incr i} {
        if {[string trim [lindex $lines $i]] eq "---"} {
            set body [join [lrange $lines [expr {$i + 1}] end] \n]
            if {[string index $body 0] eq "\n"} {
                set body [string range $body 1 end]
            }
            return $body
        }
    }
    return ""
}

# _roster_field_current -- fetch and de-quote a roster field from a row dict.
# TSV loaders sometimes wrap blanks in `""`; strip the artifact.
proc spar::_roster_field_current {row field} {
    set v [string trim [dict getdef $row $field ""]]
    if {[regexp {^"(.*)"$} $v -> inner]} {
        set v [string trim $inner]
    }
    return $v
}

# _approach_first_line_hash -- return the lowercase hex stored on line 1
# of the approach file, or "" if line 1 is not a profile_hash declaration.
# Reads only the first line; never invokes the YAML parser. Position
# discipline (#63) is enforced by validate_approach (profile_hash_misplaced),
# so a hash sitting elsewhere in the file is a validator concern, not a
# silent classifier blind spot.
proc spar::_approach_first_line_hash {approach_path} {
    if {[catch {set fd [open $approach_path r]}]} { return "" }
    fconfigure $fd -encoding utf-8
    set line ""
    catch {set line [gets $fd]}
    close $fd
    if {[regexp {^profile_hash:\s*sha256:([0-9a-fA-F]+)\s*$} $line -> hex]} {
        return [string tolower $hex]
    }
    return ""
}

# _approach_hash_mismatch -- return 1 iff the approach carries a line-1
# profile_hash whose sha256 differs from the profile file's bytes. Returns
# 0 when the approach has no profile_hash on line 1 (legacy / manually-
# authored case — the state machine cannot prove staleness without a
# canonically-placed hash, and the contact stays APPROACHED). Caller has
# already confirmed both files exist.
proc spar::_approach_hash_mismatch {profile_path approach_path} {
    set stored [spar::_approach_first_line_hash $approach_path]
    if {$stored eq ""} { return 0 }
    set actual [string tolower [::sha2::sha256 -hex -file $profile_path]]
    return [expr {$actual ne $stored}]
}

# prepend_profile_hash -- write `profile_hash: sha256:<hex>` as line 1 of
# the approach file. Called by the A harness after validate_and_correct
# passes (#63). Idempotent: if line 1 already carries a hash, the file is
# left alone (so re-running the harness or the migration script does not
# duplicate the line). The harness, not A, owns the line — A's prompt
# tells A not to write one.
proc spar::prepend_profile_hash {approach_path profile_path} {
    if {![file exists $approach_path] || ![file exists $profile_path]} { return }
    set fd [open $approach_path r]
    fconfigure $fd -encoding utf-8
    set raw [read $fd]
    close $fd
    set lines [split $raw \n]
    if {[regexp {^profile_hash:\s*sha256:[0-9a-fA-F]+\s*$} [lindex $lines 0]]} {
        return
    }
    set hex [::sha2::sha256 -hex -file $profile_path]
    set lines [linsert $lines 0 "profile_hash: sha256:$hex"]
    set fd [open $approach_path w]
    fconfigure $fd -encoding utf-8
    puts -nonewline $fd [join $lines \n]
    close $fd
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


source [file join [file dirname [file normalize [info script]]] spar-validate.tcl]

package provide spar-state 1.0
