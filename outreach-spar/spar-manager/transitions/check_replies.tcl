# spar-manager/transitions/check_replies.tcl
#
# CheckRepliesTransition (T7, Send → Reply). Queries the campaign's
# configured inbox for replies to sent approaches and appends any new
# ones to the approach YAML. The per-row search-and-fetch body lives
# in transitions/imap_check_one.tcl as a pure helper that the Pool's
# imap_poll worker proc invokes; this file keeps only the transition-
# class metadata, the build_opts hook the dispatcher reads, and the
# run method that builds the per-row Pool batch.

package require TclOO

# ── CheckRepliesTransition ──────────────────────────────────────────

oo::class create ::spar::transitions::CheckRepliesTransition {
    superclass ::spar::transitions::Transition

    method build_opts {tasks filter_segments filter_stems} {
        set segs [dict create]
        set stems {}
        foreach c $tasks {
            dict set segs [dict get $c _segment_dir] 1
            lappend stems [dict get $c stem]
        }
        set segments_list [dict keys $segs]
        return [dict create \
            segments $segments_list \
            stems $stems \
            log_message "[my tid]: [llength $tasks] task(s) across [llength $segments_list] segment(s) (reply-check pass)"]
    }

    method run {opts on_progress on_complete} {
        set step_callback [spar::dict_get_default $opts step_callback ""]
        set jobs          [spar::dict_get_default $opts jobs 1]

        set prep [my _build_rows $opts $on_progress $on_complete]
        if {$prep eq ""} return  ;# _build_rows already invoked on_complete
        set rows [dict get $prep rows]

        spar::run_through_pool $jobs [my tid] imap_poll $rows \
            [dict create] $on_progress $on_complete $step_callback
    }

    # prepare_for_pool — pool-shape entry. Returns
    # {worker_proc imap_poll rows {{stem opts} ...}}. The unified
    # Dispatcher in spar-transitions.tcl enqueues the rows directly;
    # imap_poll has no rate-limit pacing requirement so it inherits
    # the global Jobs cap.
    method prepare_for_pool {opts on_progress} {
        set prep [my _build_rows $opts $on_progress ""]
        if {$prep eq ""} {
            return [dict create worker_proc imap_poll rows {}]
        }
        return [dict create \
            worker_proc imap_poll \
            rows [dict get $prep rows]]
    }

    # _build_rows — extract the per-row opts dict construction so
    # both run (legacy callback shape) and prepare_for_pool (unified
    # Dispatcher) share one path. Returns {rows {{stem opts} ...}}
    # on success or "" if a precondition failed.
    #
    # When called via run, on_complete may be invoked directly for
    # missing-config or empty-rows shortcut paths; when called via
    # prepare_for_pool, on_complete is "" and we just return empty
    # rows for the pool to skip.
    method _build_rows {opts on_progress on_complete} {
        set campaign_file [dict get $opts campaign_file]
        set dry_run       [spar::dict_get_default $opts dry_run 0]
        set segments      [spar::dict_get_default $opts segments {}]
        set stems         [spar::dict_get_default $opts stems    {}]

        set cdata [spar::load_campaign $campaign_file]

        if {![dict exists $cdata reply_check mailroom_account] \
            || ![dict exists $cdata reply_check folder]} {
            if {$on_progress ne ""} {
                {*}$on_progress "" failed \
                    "campaign YAML missing reply_check.mailroom_account or reply_check.folder"
            }
            if {$on_complete ne ""} { {*}$on_complete 0 1 {} }
            return ""
        }
        if {![dict exists $cdata sender email]} {
            if {$on_progress ne ""} {
                {*}$on_progress "" failed "campaign YAML missing sender.email"
            }
            if {$on_complete ne ""} { {*}$on_complete 0 1 {} }
            return ""
        }

        set account [dict get $cdata reply_check mailroom_account]
        set folder  [dict get $cdata reply_check folder]
        set sender  [dict get $cdata sender email]
        set campaign_dir [file dirname $campaign_file]

        # Default segments to "all campaign segment dirs" when the caller
        # passed none. Mirrors spar::p::run's full-campaign default.
        if {[llength $segments] == 0} {
            set skip_set [spar::dict_get_default $cdata skip_segments {}]
            foreach seg [spar::dict_get_default $cdata segments {}] {
                if {$seg in $skip_set} continue
                set seg_path [file join $campaign_dir $seg]
                if {[file isdirectory $seg_path]} {
                    lappend segments $seg_path
                }
            }
        }

        set approaches [spar::collect_sent_approaches $segments]
        set approaches [spar::filter_approaches_by_stems $approaches $stems]
        if {[llength $approaches] == 0} {
            if {$on_progress ne ""} {
                foreach s $stems {
                    {*}$on_progress $s skipped "no reply yet"
                }
            }
            if {$on_complete ne ""} {
                {*}$on_complete 0 0 [dict create new_replies 0 errors 0]
            }
            return ""
        }

        # Build {stem opts} pairs. The Pool's imap_poll worker drives
        # one (search + zero-or-more reads) cycle per row.
        set rows {}
        set seen_stems [dict create]
        foreach entry $approaches {
            set approach_path [dict get $entry approach_path]
            set stem [file rootname [file tail $approach_path]]
            set to_email [dict get $entry to_email]
            set fingerprints [dict get $entry fingerprints]
            dict set seen_stems $stem 1
            lappend rows [list $stem [dict create \
                campaign_file $campaign_file \
                dry_run       $dry_run \
                approach_path $approach_path \
                to_email      $to_email \
                fingerprints  $fingerprints \
                account       $account \
                folder        $folder \
                sender        $sender]]
        }

        # Stems requested but with no sent approach get a synchronous
        # "skipped — no reply yet" line, matching the legacy Driver's
        # tail loop.
        if {$on_progress ne ""} {
            foreach s $stems {
                if {![dict exists $seen_stems $s]} {
                    {*}$on_progress $s skipped "no reply yet"
                }
            }
        }

        return [dict create rows $rows]
    }

    # T7: email was sent, no reply yet, contact still in scope (not
    # EXCLUDED).  Gated on approach-YAML structural validity (#43
    # principle 7).
    method eligible {state contact primary_channel cdata today_iso} {
        set cstate [dict get $contact state]
        if {$cstate eq "EXCLUDED"} { return {} }
        if {![dict get $contact email_sent]} { return {} }
        if {[dict get $contact email_replied]} { return {} }
        set vmsg [$state approach_validation_error $contact]
        if {$vmsg ne ""} {
            return [list [spar::_task $contact pending "invalid_approach_yaml: $vmsg"]]
        }
        return [list [spar::_task $contact ready ""]]
    }
}

::spar::transitions::register \
    -class ::spar::transitions::CheckRepliesTransition \
    -tid T7 \
    -label "Send → Reply" \
    -auto-safe 0 \
    -dispatch-status available \
    -ui-tree-row 1
