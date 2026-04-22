# spar-manager/transitions/check_replies.tcl
#
# CheckRepliesTransition (T4, Send → Reply). Queries the campaign's
# configured inbox for replies to sent approaches and appends any new
# ones to the approach YAML. Owns the integration to the external inbox
# tool end-to-end: search command construction, JSON parsing, reply
# append, and the async queue that runs one shell-out at a time while
# the UI event loop stays free.
#
# The run method hands control to a Driver instance (one per dispatch).
# The Driver registers itself in ::spar::live_dispatchers so pause_all
# and cancel_all reach it, drives a two-stage job queue via fileevent
# on `open "| ... "` pipes, and destroys itself on completion.

package require TclOO
package require json
package require yaml

# ── CheckRepliesDriver ───────────────────────────────────────────────
# Per-dispatch instance. Created by CheckRepliesTransition::run, lives
# until all queued jobs finish (or cancel is called), then destroys
# itself. Not reused across dispatches.

oo::class create ::spar::transitions::CheckRepliesDriver {
    variable Paused Cancelled
    variable OnProgress OnComplete
    variable Account Folder Sender CampaignDir DryRun
    variable CohortSet Stems
    variable JobQueue JobIdx
    variable ByTo
    variable CurrentPipe CurrentBuf
    variable CurrentTo CurrentEntries
    variable NewReplies Errors
    variable ReportedStems IterReplyStems
    variable Tid StepCallback SearchTotal SearchIdx

    constructor {account folder sender campaign_dir dry_run stems cohort_set \
                 by_to on_progress on_complete {tid ""} {step_callback ""}} {
        set Account     $account
        set Folder      $folder
        set Sender      $sender
        set CampaignDir $campaign_dir
        set DryRun      $dry_run
        set Stems       $stems
        set CohortSet   $cohort_set
        set ByTo        $by_to
        set OnProgress  $on_progress
        set OnComplete  $on_complete
        set Tid         $tid
        set StepCallback $step_callback

        set Paused 0
        set Cancelled 0
        set CurrentPipe ""
        set CurrentBuf ""
        set CurrentTo ""
        set CurrentEntries {}
        set NewReplies 0
        set Errors 0
        set ReportedStems {}
        set IterReplyStems {}

        set JobQueue {}
        set JobIdx 0
        set SearchIdx 0
        foreach to_email [dict keys $ByTo] {
            lappend JobQueue [list search $to_email]
        }
        set SearchTotal [llength $JobQueue]

        lappend ::spar::live_dispatchers [self]
    }

    destructor {
        set idx [lsearch -exact $::spar::live_dispatchers [self]]
        if {$idx >= 0} {
            set ::spar::live_dispatchers \
                [lreplace $::spar::live_dispatchers $idx $idx]
        }
    }

    method pause  {} { set Paused 1 }
    method resume {} { set Paused 0; my start_next }

    # cancel drops all pending jobs, closes the in-flight pipe (if any),
    # and walks the state machine to completion so on_complete still
    # fires exactly once.
    method cancel {} {
        set Cancelled 1
        set JobQueue [lrange $JobQueue 0 [expr {$JobIdx - 1}]]
        if {$CurrentPipe ne ""} {
            catch {fileevent $CurrentPipe readable {}}
            catch {close $CurrentPipe}
            set CurrentPipe ""
            my finish
        } else {
            my finish
        }
    }

    method kick {} { my start_next }

    # start_next -- advance the queue. One job at a time: once a pipe is
    # opened, further start_next calls short-circuit until the pipe's
    # EOF handler closes it. Paused leaves the queue alone; resume
    # re-enters here.
    method start_next {} {
        if {$Paused || $Cancelled} { return }
        if {$CurrentPipe ne ""}    { return }
        if {$JobIdx >= [llength $JobQueue]} {
            my finish
            return
        }

        set job [lindex $JobQueue $JobIdx]
        incr JobIdx
        set kind [lindex $job 0]

        switch -- $kind {
            search {
                incr SearchIdx
                if {$StepCallback ne ""} {
                    set to_email [lindex $job 1]
                    set verdict [{*}$StepCallback $Tid $to_email \
                        $SearchIdx $SearchTotal]
                    if {$verdict eq "abort"} {
                        my finish
                        return
                    }
                }
                my do_search [lindex $job 1]
            }
            read   { my do_read  $job }
            end_to { my do_end_to [lindex $job 1] }
            default { my start_next }
        }
    }

    # do_search -- kick off an async mailbox search for one to_email.
    # The pipe is read line-by-line into CurrentBuf; on EOF the full
    # JSON is parsed and read-jobs are prepended (by splice) to the
    # queue for any new incoming messages.
    method do_search {to_email} {
        set CurrentTo $to_email
        set CurrentEntries [dict get $ByTo $to_email]
        set IterReplyStems {}
        set CurrentBuf ""

        set cmd [list mailroom -a $Account search -f $Folder \
            --limit 50 "from:$to_email"]
        if {[catch {open "| $cmd 2>@1" r} pipe]} {
            incr Errors
            if {$OnProgress ne ""} {
                {*}$OnProgress $to_email error "mailbox search failed to start: $pipe"
            }
            my emit_iter_skipped
            set CurrentPipe ""
            my start_next
            return
        }

        fconfigure $pipe -blocking 0 -buffering line
        fileevent $pipe readable [list [self] on_search_output $pipe]
        set CurrentPipe $pipe
    }

    method on_search_output {pipe} {
        if {[gets $pipe line] >= 0} {
            append CurrentBuf $line "\n"
            return
        }
        if {[eof $pipe]} {
            fileevent $pipe readable {}
            set close_err ""
            if {[catch {close $pipe} close_err]} {
                # mailroom writes diagnostic lines to stdout (we merged
                # 2>@1), so a non-zero exit is real. Record and move on.
                incr Errors
                if {$OnProgress ne ""} {
                    {*}$OnProgress $CurrentTo error "mailbox search failed: $close_err"
                }
                set CurrentPipe ""
                my emit_iter_skipped
                my start_next
                return
            }
            set CurrentPipe ""

            if {[catch {set messages [::json::json2dict $CurrentBuf]} perr]} {
                incr Errors
                if {$OnProgress ne ""} {
                    {*}$OnProgress $CurrentTo error "mailbox search JSON parse: $perr"
                }
                my emit_iter_skipped
                my start_next
                return
            }

            set sender_lower [string tolower $Sender]
            set incoming {}
            foreach msg $messages {
                set to_addrs {}
                set cc_addrs {}
                if {[dict exists $msg to]} {
                    foreach a [dict get $msg to] {
                        lappend to_addrs [spar::extract_email_address $a]
                    }
                }
                if {[dict exists $msg cc]} {
                    foreach a [dict get $msg cc] {
                        lappend cc_addrs [spar::extract_email_address $a]
                    }
                }
                if {$sender_lower in $to_addrs || $sender_lower in $cc_addrs} {
                    lappend incoming $msg
                }
            }

            set incoming [lsort -command {apply {{a b} {
                set da [spar::dict_get_default $a date ""]
                set db [spar::dict_get_default $b date ""]
                return [string compare $da $db]
            }}} $incoming]

            set read_jobs {}
            foreach msg $incoming {
                set from_email_addr [spar::extract_email_address \
                    [spar::dict_get_default $msg from ""]]
                set date_str [spar::dict_get_default $msg date ""]
                if {![regexp {^\d{4}-\d{2}-\d{2}} $date_str]} continue

                set already_recorded 0
                foreach entry $CurrentEntries {
                    if {[spar::fingerprint_match \
                            [dict get $entry fingerprints] \
                            $from_email_addr $date_str]} {
                        set already_recorded 1
                        break
                    }
                }
                if {$already_recorded} continue

                set uid [spar::dict_get_default $msg uid ""]
                set from_display [spar::dict_get_default $msg from $from_email_addr]
                lappend read_jobs [list read $CurrentTo \
                    $from_email_addr $date_str $from_display $uid]
            }

            if {[llength $read_jobs] > 0} {
                set before [lrange $JobQueue 0 [expr {$JobIdx - 1}]]
                set after  [lrange $JobQueue $JobIdx end]
                # Emit the iteration's skipped burst only after all this
                # to_email's reads finish — queue a sentinel.
                set JobQueue [concat $before $read_jobs \
                    [list [list end_to $CurrentTo]] $after]
            } else {
                my emit_iter_skipped
            }

            my start_next
        }
    }

    # do_read -- fetch one message body from the inbox.
    method do_read {job} {
        lassign $job _ to_email from_email_addr date_str from_display uid
        set CurrentTo $to_email
        set CurrentBuf ""

        # Store per-read context for the EOF handler. CurrentEntries was
        # set when the enclosing search started and still reflects the
        # same group.
        set ReadCtx [dict create \
            from_email_addr $from_email_addr \
            date_str        $date_str \
            from_display    $from_display \
            uid             $uid]

        set cmd [list mailroom -a $Account read -f $Folder -u $uid]
        if {[catch {open "| $cmd 2>@1" r} pipe]} {
            my handle_read_failure $ReadCtx \
                "(inbox read failed -- review manually:\n  mailroom -a $Account read -f $Folder -u $uid)"
            my start_next
            return
        }

        fconfigure $pipe -blocking 0 -buffering line
        fileevent $pipe readable [list [self] on_read_output $pipe $ReadCtx]
        set CurrentPipe $pipe
    }

    method on_read_output {pipe ctx} {
        if {[gets $pipe line] >= 0} {
            append CurrentBuf $line "\n"
            return
        }
        if {[eof $pipe]} {
            fileevent $pipe readable {}
            set close_err ""
            set fetch_failed [catch {close $pipe} close_err]
            set CurrentPipe ""

            set uid [dict get $ctx uid]
            if {$fetch_failed} {
                my handle_read_failure $ctx \
                    "(inbox read failed -- review manually:\n  mailroom -a $Account read -f $Folder -u $uid)"
                my start_next
                return
            }

            if {[catch {set email_data [::json::json2dict $CurrentBuf]} _]} {
                my handle_read_failure $ctx \
                    "(could not parse reply -- review manually:\n  mailroom -a $Account read -f $Folder -u $uid)"
                my start_next
                return
            }

            set body [spar::dict_get_default $email_data body ""]
            if {$body ne ""} {
                set reply_text [spar::html_to_text $body]
            } else {
                set reply_text "(no text content)"
            }

            my record_reply $ctx $reply_text
            my start_next
        }
    }

    method handle_read_failure {ctx reply_text} {
        my record_reply $ctx $reply_text
    }

    # record_reply -- common post-read logic: write to the first approach
    # file for this to_email, update in-memory fingerprints, emit the
    # "reply" progress event. Shared between successful reads and the
    # placeholder-text fallback paths.
    method record_reply {ctx reply_text} {
        set from_email_addr [dict get $ctx from_email_addr]
        set date_str        [dict get $ctx date_str]
        set from_display    [dict get $ctx from_display]

        set first_entry [lindex $CurrentEntries 0]
        set approach_path [dict get $first_entry approach_path]

        if {!$DryRun} {
            if {[catch {spar::append_reply_to_yaml \
                    $approach_path $date_str $from_display $reply_text} werr]} {
                incr Errors
                if {$OnProgress ne ""} {
                    set stem [file rootname [file tail $approach_path]]
                    {*}$OnProgress $stem failed "reply write error: $werr"
                }
                return
            }
        }

        set fps [dict get $first_entry fingerprints]
        lappend fps "${from_email_addr}|${date_str}"
        dict set first_entry fingerprints $fps
        lset CurrentEntries 0 $first_entry
        dict set ByTo $CurrentTo $CurrentEntries

        incr NewReplies

        if {$OnProgress ne ""} {
            set stem [file rootname [file tail $approach_path]]
            lappend ReportedStems $stem
            lappend IterReplyStems $stem
            set tag [expr {$DryRun ? "would-append reply" : "reply"}]
            {*}$OnProgress $stem done "$tag from $from_email_addr ($date_str)"
        }
    }

    # end_to job handler -- fires after the last read for a to_email
    # finishes, so the iteration's skipped events are emitted in order
    # (matching the CLI's old per-iteration burst).
    method do_end_to {to_email} {
        set CurrentTo $to_email
        my emit_iter_skipped
        my start_next
    }

    method emit_iter_skipped {} {
        if {$OnProgress eq ""} return
        foreach entry $CurrentEntries {
            set stem [file rootname [file tail [dict get $entry approach_path]]]
            if {$stem in $IterReplyStems} continue
            if {[dict size $CohortSet] > 0 && ![dict exists $CohortSet $stem]} continue
            lappend ReportedStems $stem
            {*}$OnProgress $stem skipped "no reply yet"
        }
        set IterReplyStems {}
    }

    method finish {} {
        # Emit skipped for any cohort stems that never reported — this
        # mirrors the CLI's tail loop in the pre-refactor r::run.
        if {$OnProgress ne ""} {
            foreach s $Stems {
                if {$s ni $ReportedStems} {
                    {*}$OnProgress $s skipped "no reply yet"
                }
            }
        }
        set result [dict create new_replies $NewReplies errors $Errors]
        set cb $OnComplete
        set nr $NewReplies
        set er $Errors
        [self] destroy
        {*}$cb $nr $er $result
    }
}

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
        set campaign_file [dict get $opts campaign_file]
        set dry_run       [spar::dict_get_default $opts dry_run 0]
        set segments      [spar::dict_get_default $opts segments {}]
        set stems         [spar::dict_get_default $opts stems    {}]
        set step_callback [spar::dict_get_default $opts step_callback ""]

        # Emit started per-slug so UI rows leave their initial state
        # before the collection pass (YAML parsing) starts.
        if {$on_progress ne ""} {
            foreach s $stems {
                {*}$on_progress $s started ""
            }
        }

        set cdata [spar::load_campaign $campaign_file]

        if {![dict exists $cdata reply_check mailroom_account] \
            || ![dict exists $cdata reply_check folder]} {
            if {$on_progress ne ""} {
                {*}$on_progress "" failed \
                    "campaign YAML missing reply_check.mailroom_account or reply_check.folder"
            }
            {*}$on_complete 0 1 {}
            return
        }
        if {![dict exists $cdata sender email]} {
            if {$on_progress ne ""} {
                {*}$on_progress "" failed "campaign YAML missing sender.email"
            }
            {*}$on_complete 0 1 {}
            return
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
            {*}$on_complete 0 0 [dict create new_replies 0 errors 0]
            return
        }

        set by_to [dict create]
        foreach entry $approaches {
            set to_email [dict get $entry to_email]
            if {![dict exists $by_to $to_email]} {
                dict set by_to $to_email {}
            }
            dict lappend by_to $to_email $entry
        }

        set cohort_set [dict create]
        foreach s $stems { dict set cohort_set $s 1 }

        set driver [::spar::transitions::CheckRepliesDriver new \
            $account $folder $sender $campaign_dir $dry_run \
            $stems $cohort_set $by_to $on_progress $on_complete \
            [my tid] $step_callback]
        $driver kick
    }
}

::spar::transitions::register \
    -class ::spar::transitions::CheckRepliesTransition \
    -tid T4 \
    -label "Send → Reply" \
    -auto-safe 0 \
    -dispatch-status available \
    -ui-tree-row 1
