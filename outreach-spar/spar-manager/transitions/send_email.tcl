# spar-manager/transitions/send_email.tcl
#
# SendEmailTransition (T3, Approach → Send). Sends the final-round email
# message of each approach YAML via AWS SES. Owns the SES integration
# end-to-end: request JSON construction, async pipe to `aws ses
# send-email`, response parsing, and the actioned_date stamp on success.
#
# Sends are serial with a pacing delay (opts.delay, default 2s) to stay
# under SES rate limits. Pacing uses `after $delay_ms cmd`, not a
# synchronous sleep, so the UI event loop keeps turning.
#
# Opts consumed:
#   campaign_file  path to campaign YAML
#   dry_run        1 = skip SES send + skip stamp
#   tasks          list of classified ready contacts (from build_opts)
#   delay          seconds between sends (default 2)

package require TclOO
package require json
package require json::write

# ── SendEmailDriver ──────────────────────────────────────────────────
# Per-dispatch instance. Created by SendEmailTransition::run, lives
# until all tasks are processed (or cancel is called). Registers itself
# in ::spar::live_dispatchers for pause/resume/cancel.

oo::class create ::spar::transitions::SendEmailDriver {
    variable Paused Cancelled
    variable OnProgress OnComplete
    variable Tasks TaskIdx Delay DryRun
    variable SesRegion CampSender CampFromName CampFromEmail CampBcc
    variable CurrentPipe CurrentBuf
    variable CurrentSlug CurrentApproachPath
    variable DelayTimer
    variable Done Failed
    variable Tid StepCallback

    constructor {tasks delay dry_run ses_region camp_sender \
                 on_progress on_complete {tid ""} {step_callback ""}} {
        set Tasks        $tasks
        set TaskIdx      0
        set Delay        $delay
        set DryRun       $dry_run
        set SesRegion    $ses_region
        set CampSender   $camp_sender
        set CampFromName  [spar::dict_get_default $camp_sender name ""]
        set CampFromEmail [spar::dict_get_default $camp_sender email ""]
        set CampBcc       [spar::dict_get_default $camp_sender bcc ""]

        set OnProgress $on_progress
        set OnComplete $on_complete
        set Tid $tid
        set StepCallback $step_callback

        set Paused 0
        set Cancelled 0
        set CurrentPipe ""
        set CurrentBuf ""
        set CurrentSlug ""
        set CurrentApproachPath ""
        set DelayTimer ""
        set Done 0
        set Failed 0

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

    method cancel {} {
        set Cancelled 1
        if {$DelayTimer ne ""} {
            after cancel $DelayTimer
            set DelayTimer ""
        }
        if {$CurrentPipe ne ""} {
            catch {fileevent $CurrentPipe readable {}}
            catch {close $CurrentPipe}
            set CurrentPipe ""
        }
        my finish
    }

    method kick {} { my start_next }

    method start_next {} {
        if {$Paused || $Cancelled} { return }
        if {$CurrentPipe ne ""}    { return }
        if {$TaskIdx >= [llength $Tasks]} {
            my finish
            return
        }

        set c [lindex $Tasks $TaskIdx]
        incr TaskIdx

        set stem    [dict get $c stem]
        set seg_dir [dict get $c _segment_dir]
        set slug    "[file tail $seg_dir]/$stem"
        set approach_path [file join $seg_dir approach "${stem}.yaml"]

        set CurrentSlug $slug
        set CurrentApproachPath $approach_path

        if {$StepCallback ne ""} {
            set verdict [{*}$StepCallback $Tid $slug $TaskIdx [llength $Tasks]]
            if {$verdict eq "abort"} {
                my finish
                return
            }
        }

        if {$OnProgress ne ""} {
            {*}$OnProgress $slug started ""
        }

        if {![file exists $approach_path]} {
            my fail_task "approach file missing: $approach_path"
            return
        }

        if {[catch {set approach_data [spar::read_approach_yaml $approach_path]} rerr]} {
            my fail_task "approach read error: $rerr"
            return
        }

        set msg [spar::final_email_message $approach_data]
        if {$msg eq ""} {
            my fail_task "no email message in final round"
            return
        }

        set to      [string trim [spar::dict_get_default $msg to ""]]
        set cc      [string trim [spar::dict_get_default $msg cc ""]]
        set bcc     [string trim [spar::dict_get_default $msg bcc ""]]
        set subject [spar::dict_get_default $msg subject ""]
        set body    [spar::dict_get_default $msg body ""]

        if {$to eq "" || $subject eq "" || $body eq ""} {
            my fail_task "message missing to/subject/body"
            return
        }

        set from_name  $CampFromName
        set from_email $CampFromEmail
        if {[dict exists $approach_data decisions]} {
            set ad_sender [spar::dict_get_default \
                [dict get $approach_data decisions] sender [dict create]]
            set ad_name  [spar::dict_get_default $ad_sender name ""]
            set ad_email [spar::dict_get_default $ad_sender email ""]
            if {$ad_email ne ""} {
                set from_email $ad_email
                if {$ad_name ne ""} { set from_name $ad_name }
            }
        }
        if {$from_email eq ""} {
            my fail_task \
                "no sender: neither approach decisions.sender.email nor campaign sender.email set"
            return
        }
        set from_hdr [expr {$from_name ne "" ? "$from_name <$from_email>" : $from_email}]

        if {$bcc eq ""} { set bcc $CampBcc }
        if {$bcc eq ""} { set bcc $from_email }

        if {$DryRun} {
            if {$OnProgress ne ""} {
                {*}$OnProgress $CurrentSlug done "dry-run"
            }
            incr Done
            # No real send, no pacing — advance immediately.
            my start_next
            return
        }

        ::json::write indented 0
        set dest_fields [list ToAddresses \
            [::json::write array [::json::write string $to]]]
        if {$cc ne ""} {
            lappend dest_fields CcAddresses \
                [::json::write array [::json::write string $cc]]
        }
        if {$bcc ne ""} {
            lappend dest_fields BccAddresses \
                [::json::write array [::json::write string $bcc]]
        }
        set dest_json [::json::write object {*}$dest_fields]

        set subj_obj [::json::write object \
            Data [::json::write string $subject] \
            Charset [::json::write string "UTF-8"]]
        set body_obj [::json::write object \
            Text [::json::write object \
                Data [::json::write string $body] \
                Charset [::json::write string "UTF-8"]]]
        set msg_json [::json::write object \
            Subject $subj_obj \
            Body $body_obj]

        set cmd [list aws ses send-email \
            --region $SesRegion \
            --from $from_hdr \
            --destination $dest_json \
            --message $msg_json]

        set CurrentBuf ""
        if {[catch {open "| $cmd 2>@1" r} pipe]} {
            my fail_task "send failed to start: $pipe"
            return
        }
        fconfigure $pipe -blocking 0 -buffering line
        fileevent $pipe readable [list [self] on_output $pipe]
        set CurrentPipe $pipe
    }

    method on_output {pipe} {
        if {[gets $pipe line] >= 0} {
            append CurrentBuf $line "\n"
            return
        }
        if {[eof $pipe]} {
            fileevent $pipe readable {}
            set close_err ""
            set failed [catch {close $pipe} close_err]
            set CurrentPipe ""

            if {$failed} {
                my fail_task "send error: $close_err"
                return
            }

            set message_id "?"
            if {[catch {set parsed [::json::json2dict $CurrentBuf]}]} {
                # Successful sends emit JSON; anything else with exit=0
                # is still treated as success but with unknown MessageId.
                set message_id "?"
            } else {
                set message_id [spar::dict_get_default $parsed MessageId "?"]
            }

            set today [clock format [clock seconds] -format "%Y-%m-%d"]
            if {[catch {spar::stamp_actioned_date $CurrentApproachPath $today} serr]} {
                if {$OnProgress ne ""} {
                    {*}$OnProgress $CurrentSlug failed "sent ok but stamp failed: $serr"
                }
                incr Failed
                my schedule_next
                return
            }

            if {$OnProgress ne ""} {
                {*}$OnProgress $CurrentSlug done $message_id
            }
            incr Done
            my schedule_next
        }
    }

    # Emit failure for the current task, then advance. No pacing delay
    # after failures — delays are for SES rate-limit protection, and a
    # failed send didn't reach SES.
    method fail_task {reason} {
        if {$OnProgress ne ""} {
            {*}$OnProgress $CurrentSlug failed $reason
        }
        incr Failed
        set CurrentPipe ""
        my start_next
    }

    # schedule_next -- insert the pacing delay before the next task.
    # `after ms cmd` yields to the event loop, unlike the pre-refactor
    # `after [expr {$delay * 1000}]` with no command (which was a
    # blocking sleep that froze the UI).
    method schedule_next {} {
        if {$Cancelled} {
            my finish
            return
        }
        if {$TaskIdx >= [llength $Tasks]} {
            my finish
            return
        }
        set delay_ms [expr {$Delay * 1000}]
        if {$delay_ms <= 0} {
            my start_next
            return
        }
        set DelayTimer [after $delay_ms [list [self] _delay_fired]]
    }

    method _delay_fired {} {
        set DelayTimer ""
        my start_next
    }

    method finish {} {
        set result [dict create]
        set cb $OnComplete
        set d $Done
        set f $Failed
        [self] destroy
        {*}$cb $d $f $result
    }
}

# ── SendEmailTransition ─────────────────────────────────────────────

oo::class create ::spar::transitions::SendEmailTransition {
    superclass ::spar::transitions::Transition

    method build_opts {tasks filter_segments filter_stems} {
        return [dict create \
            tasks $tasks \
            log_message "[my tid]: [llength $tasks] email(s) ready"]
    }

    method run {opts on_progress on_complete} {
        set campaign_file [dict get $opts campaign_file]
        set dry_run       [spar::dict_get_default $opts dry_run 0]
        set tasks         [spar::dict_get_default $opts tasks {}]
        set delay         [spar::dict_get_default $opts delay 2]
        set step_callback [spar::dict_get_default $opts step_callback ""]

        set cdata [spar::load_campaign $campaign_file]
        set camp_sender [spar::dict_get_default $cdata sender [dict create]]
        set ses_region  [spar::dict_get_default $cdata ses_region "ap-southeast-2"]

        set driver [::spar::transitions::SendEmailDriver new \
            $tasks $delay $dry_run $ses_region $camp_sender \
            $on_progress $on_complete [my tid] $step_callback]
        $driver kick
    }
}

::spar::transitions::register \
    -class ::spar::transitions::SendEmailTransition \
    -tid T3 \
    -label "Approach → Send" \
    -auto-safe 0 \
    -dispatch-status available \
    -requires-send-confirmation 1 \
    -ui-tree-row 1
