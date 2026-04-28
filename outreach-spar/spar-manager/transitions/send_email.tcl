# spar-manager/transitions/send_email.tcl
#
# SendEmailTransition (T6, Approach → Send). Sends the final-round email
# message of each approach YAML via SES SMTP. Uses smtp_send.tcl, a
# hand-rolled SMTP client that captures the "250 Ok <id>" tracking token
# that tcllib smtp discards. actioned_date is stamped on success.
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

namespace eval ::spar::transitions {
    variable send_email_dir [file dirname [file normalize [info script]]]
}

# spar::smtp_credentials host user ?cdata? -- resolve the SMTP password.
# Lookup order:
#   1. OS keychain, keyed by (host, user) — native compound-key idiom on
#      macOS Keychain, Linux libsecret, and Windows PasswordVault.
#   2. YAML fallback: sender.smtp_pass in the passed campaign dict.
#   3. Error.
#
# Keychain always wins when a match exists, so migrating from YAML to
# keychain is a one-way ratchet; the user removes the YAML field after
# storing.  Callers that already know they have no keychain (e.g. tests)
# can pass a cdata with smtp_pass and the lookup still resolves.
proc ::spar::smtp_credentials {host user {cdata ""}} {
    global tcl_platform
    if {$host eq "" || $user eq ""} {
        error "smtp_credentials: host and user required"
    }
    set pass ""
    if {[spar::keychain_available]} {
        catch {
            switch $tcl_platform(os) {
                "Darwin" {
                    set pass [string trim [exec security find-generic-password \
                        -s $host -a $user -w]]
                }
                "Linux" {
                    set pass [string trim [exec secret-tool lookup \
                        protocol smtp server $host user $user]]
                }
                "Windows NT" {
                    set script "\$v = New-Object Windows.Security.Credentials.PasswordVault; \$c = \$v.Retrieve('$host','$user'); \$c.RetrievePassword(); \$c.Password"
                    set pass [string trim [exec powershell -NoProfile -NonInteractive -Command $script]]
                }
            }
        }
    }
    if {$pass ne ""} { return $pass }

    # YAML fallback.
    if {$cdata ne "" && [dict exists $cdata sender smtp_pass]} {
        set yaml_pass [dict get $cdata sender smtp_pass]
        if {$yaml_pass ne ""} { return $yaml_pass }
    }

    if {[spar::keychain_available]} {
        error "no keychain entry for ($host, $user) — store via Settings, or add sender.smtp_pass to campaign.yaml"
    } else {
        error "keychain not available on this host and sender.smtp_pass is not set in campaign.yaml"
    }
}

# ── SendEmailDriver ──────────────────────────────────────────────────
# Per-dispatch instance. Created by SendEmailTransition::run, lives
# until all tasks are processed (or cancel is called). Registers itself
# in ::spar::live_dispatchers for pause/resume/cancel.

oo::class create ::spar::transitions::SendEmailDriver {
    variable Paused Cancelled
    variable OnProgress OnComplete
    variable Tasks TaskIdx Delay DryRun
    variable CampSender CampFromName CampFromEmail CampBcc CampSmtpHost CampSmtpPort CampSmtpUser
    variable CurrentPipe CurrentBuf TmpFile
    variable CurrentSlug CurrentApproachPath
    variable DelayTimer
    variable Done Failed
    variable Tid StepCallback

    constructor {tasks delay dry_run camp_sender \
                 on_progress on_complete {tid ""} {step_callback ""}} {
        set Tasks        $tasks
        set TaskIdx      0
        set Delay        $delay
        set DryRun       $dry_run
        set CampSender   $camp_sender
        set CampFromName  [spar::dict_get_default $camp_sender name ""]
        set CampFromEmail [spar::dict_get_default $camp_sender email ""]
        set CampBcc       [spar::dict_get_default $camp_sender bcc ""]
        set CampSmtpHost  [spar::dict_get_default $camp_sender smtp_host ""]
        set CampSmtpPort  [spar::dict_get_default $camp_sender smtp_port 587]
        set CampSmtpUser  [spar::dict_get_default $camp_sender smtp_user ""]

        set OnProgress $on_progress
        set OnComplete $on_complete
        set Tid $tid
        set StepCallback $step_callback

        set Paused 0
        set Cancelled 0
        set CurrentPipe ""
        set CurrentBuf ""
        set TmpFile ""
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
        if {$TmpFile ne ""} { catch {file delete $TmpFile}; set TmpFile "" }
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

        # Sender resolution. Done before any reply-header derivation because
        # build_reply_headers needs the chosen sender address to drop it
        # from the original recipient set when reply_all is true.
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

        # Reply mode (issue #79). The To/Subject/Cc and threading headers
        # are derived from the captured parent block; the message itself
        # only carries the body. Validator gates have already required
        # parent.message_id to be present, but we re-check defensively.
        set in_reply_to ""
        set references ""
        set is_reply [expr {[spar::dict_get_default $msg mode ""] eq "reply"}]
        if {$is_reply} {
            set parent [spar::dict_get_default $msg parent [dict create]]
            set parent_mid [string trim [spar::dict_get_default $parent message_id ""]]
            if {$parent_mid eq ""} {
                my fail_task "reply mode but parent.message_id is empty; \
                    cannot construct In-Reply-To"
                return
            }
            set reply_all [spar::dict_get_default $msg reply_all 0]
            set rh [spar::build_reply_headers $parent $from_email $reply_all]
            set to          [dict get $rh to]
            set cc          [dict get $rh cc]
            set subject     [dict get $rh subject]
            set in_reply_to [dict get $rh in_reply_to]
            set references  [dict get $rh references]
        }

        if {$to eq "" || $subject eq "" || $body eq ""} {
            my fail_task "message missing to/subject/body"
            return
        }

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

        if {$CampSmtpHost eq ""} {
            my fail_task "sender.smtp_host not set in campaign"
            return
        }
        if {$CampSmtpUser eq ""} {
            my fail_task "sender.smtp_user not set in campaign — required (keychain is keyed by host+user)"
            return
        }
        set _cdata_for_lookup [dict create sender $CampSender]
        if {[catch {set pass [::spar::smtp_credentials \
                $CampSmtpHost $CampSmtpUser $_cdata_for_lookup]} err]} {
            my fail_task "SMTP password lookup failed for ($CampSmtpHost, $CampSmtpUser): $err"
            return
        }

        set params [dict create \
            smtp_host    $CampSmtpHost \
            smtp_port    $CampSmtpPort \
            smtp_user    $CampSmtpUser \
            smtp_pass    $pass \
            from_email   $from_email \
            from_name    $from_name \
            to           $to \
            cc           $cc \
            bcc          $bcc \
            subject      $subject \
            body         $body \
            in_reply_to  $in_reply_to \
            references   $references]

        if {[catch {set TmpFile [exec mktemp]} err]} {
            my fail_task "tempfile error: $err"
            return
        }
        if {[catch {
            set f [open $TmpFile w]
            puts $f $params
            close $f
        } err]} {
            catch {file delete $TmpFile}; set TmpFile ""
            my fail_task "tempfile write error: $err"
            return
        }

        set helper [file join $::spar::transitions::send_email_dir smtp_send.tcl]
        set cmd [list tclsh9.0 $helper $TmpFile]

        set CurrentBuf ""
        if {[catch {open "| $cmd 2>@1" r} pipe]} {
            catch {file delete $TmpFile}; set TmpFile ""
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
            if {$TmpFile ne ""} { catch {file delete $TmpFile}; set TmpFile "" }

            if {$failed} {
                my fail_task "send error: [string trim $CurrentBuf]"
                return
            }

            # smtp_send.tcl prints the bare SES tracking token on stdout
            set message_id [string trim $CurrentBuf]
            if {$message_id eq ""} { set message_id "?" }

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
        set DelayTimer [after $delay_ms [list [self] delay_fired]]
    }

    method delay_fired {} {
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
        set jobs          [spar::dict_get_default $opts jobs 1]

        set cdata [spar::load_campaign $campaign_file]
        set camp_sender [spar::dict_get_default $cdata sender [dict create]]

        # Build per-row {stem opts} pairs. The Pool's ses_send worker
        # consumes per-row data — campaign_file, dry_run,
        # approach_path, sender, delay_ms — instead of the legacy
        # tasks list. delay_ms throttles consecutive sends from the
        # same worker thread (SES rate-cap).
        set delay_ms [expr {$delay * 1000}]
        set rows {}
        foreach c $tasks {
            set stem    [dict get $c stem]
            set seg_dir [dict get $c _segment_dir]
            set approach_path [file join $seg_dir approach "${stem}.yaml"]
            lappend rows [list $stem [dict create \
                campaign_file $campaign_file \
                dry_run       $dry_run \
                approach_path $approach_path \
                sender        $camp_sender \
                delay_ms      $delay_ms]]
        }

        # SES is serial by convention (one auth handshake per
        # connection, pacing by delay_ms). Force jobs=1 here even if
        # the caller passed --jobs=N — the per-row delay would
        # interleave unpredictably with parallel workers.
        spar::run_through_pool 1 [my tid] ses_send $rows [dict create] \
            $on_progress $on_complete $step_callback
    }

    # T6: APPROACHED/SENT, has_email, not yet email_sent.  Gated on
    # primary_channel == "email" until per-message routing (#49) lands —
    # email-as-secondary belongs to T9/T10 with wait_days/wait_condition.
    # Approach-YAML structural validity is a hard gate (#43 principle 7).
    method eligible {state contact primary_channel cdata today_iso} {
        if {$primary_channel ne "email"} { return {} }
        set cstate [dict get $contact state]
        if {$cstate ne "APPROACHED" && $cstate ne "SENT"} { return {} }
        set has_email   [dict get $contact has_email]
        set email_sent  [dict get $contact email_sent]
        if {!$has_email} {
            return [list [spar::_task $contact pending "No email address"]]
        }
        if {$email_sent} { return {} }
        set vmsg [$state approach_validation_error $contact]
        if {$vmsg ne ""} {
            return [list [spar::_task $contact pending "invalid_approach_yaml: $vmsg"]]
        }
        return [list [spar::_task $contact ready ""]]
    }
}

::spar::transitions::register \
    -class ::spar::transitions::SendEmailTransition \
    -tid T6 \
    -label "Approach → Send" \
    -auto-safe 0 \
    -dispatch-status available \
    -requires-send-confirmation 1 \
    -ui-tree-row 1
