# spar-manager/transitions/check_replies.tcl
#
# CheckRepliesTransition (T7, Send → Reply). Queries the campaign's
# configured inbox for replies to sent approaches and appends any new
# ones to the approach YAML. The per-row search-and-fetch body lives
# in transitions/imap_check_one.tcl as a pure helper that the Pool's
# imap_poll worker proc invokes; this file keeps only the transition-
# class metadata, the build_opts hook the dispatcher reads, and the
# prepare_for_pool method that builds the per-row Pool batch.

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

    # prepare_for_pool — pool-shape entry. Returns
    # {worker_proc imap_poll rows {{stem opts} ...}}. The unified
    # Dispatcher in spar-transition.tcl enqueues the rows directly;
    # imap_poll has no rate-limit pacing requirement so it inherits
    # the global Jobs cap.
    method prepare_for_pool {opts on_progress} {
        set prep [my _build_rows $opts $on_progress]
        if {$prep eq ""} {
            return [dict create worker_proc imap_poll rows {}]
        }
        return [dict create \
            worker_proc imap_poll \
            rows [dict get $prep rows]]
    }

    # _build_rows — per-row opts dict construction for prepare_for_pool.
    # Returns {rows {{stem opts} ...}} on success, or "" if a
    # precondition failed (missing reply_check config, no sent approaches)
    # so the pool skips with no rows. Synchronous failed/skipped events
    # are emitted through on_progress.
    method _build_rows {opts on_progress} {
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
            return ""
        }
        if {![dict exists $cdata sender email]} {
            if {$on_progress ne ""} {
                {*}$on_progress "" failed "campaign YAML missing sender.email"
            }
            return ""
        }

        set account [dict get $cdata reply_check mailroom_account]
        set folder  [dict get $cdata reply_check folder]
        set sender  [dict get $cdata sender email]
        set campaign_dir [file dirname $campaign_file]

        # Default segments to "all campaign segment dirs" when the caller
        # passed none. Mirrors the P-phase full-campaign default.
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
                    {*}$on_progress $s skipped "no email address to watch"
                }
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
                since         [spar::dict_get_default $entry first_sent ""] \
                fingerprints  $fingerprints \
                account       $account \
                folder        $folder \
                sender        $sender]]
        }

        # Stems requested but with no watchable sent approach get a
        # synchronous skipped line naming the reason.
        if {$on_progress ne ""} {
            foreach s $stems {
                if {![dict exists $seen_stems $s]} {
                    {*}$on_progress $s skipped "no email address to watch"
                }
            }
        }

        return [dict create rows $rows]
    }

    # T7: a message was sent on some channel, no reply recorded yet,
    # and an email address is known to watch (the final round's email
    # to: or the roster email). Contacts without a watchable address
    # are omitted: the inbox cannot be monitored for them; a reply on
    # another channel is recorded on the approach YAML directly and
    # resolves REPLIED without this transition. Gated on approach-YAML
    # structural validity (#43 principle 7).
    method eligible {state contact primary_channel cdata today_iso} {
        set cstate [dict get $contact state]
        if {$cstate eq "EXCLUDED"} { return {} }
        if {![dict get $contact any_sent]} { return {} }
        if {[dict get $contact any_replied]} { return {} }
        if {[llength [dict get $contact to_addresses]] == 0
            && ![dict get $contact has_email]} { return {} }
        set vmsg [$state approach_validation_error $contact]
        if {$vmsg ne ""} {
            return [list [spar::_task $contact blocked "invalid_approach_yaml: $vmsg"]]
        }
        return [list [spar::_task $contact dispatchable ""]]
    }
}

::spar::transitions::register \
    -class ::spar::transitions::CheckRepliesTransition \
    -tid T7 \
    -label "Send → Reply" \
    -auto-safe 0 \
    -dispatch-status available \
    -ui-tree-row 1
