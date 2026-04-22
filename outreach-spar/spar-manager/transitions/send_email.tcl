# spar-manager/transitions/send_email.tcl
#
# SendEmailTransition (T3, Approach → Send). Sends the final-round email
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

# spar::smtp_credentials -- fetch SMTP user+pass from the OS secret store.
# Entry name: "spar-smtp".
# macOS:    security add-generic-password -s spar-smtp -a USER -w PASS -U
# Linux:    secret-tool store --label="SPAR SMTP user" service spar-smtp key user
#           secret-tool store --label="SPAR SMTP pass" service spar-smtp key pass
# Windows:  New-Object Windows.Security.Credentials.PasswordVault then .Add(...)
# Returns a dict: user pass
proc ::spar::smtp_credentials {} {
    global tcl_platform
    switch $tcl_platform(os) {
        "Darwin" {
            set pass [string trim [exec security find-generic-password -s spar-smtp -w]]
            set info [exec security find-generic-password -s spar-smtp]
            if {![regexp {"acct"<blob>="([^"]+)"} $info _ user]} {
                error "cannot read account from keychain entry spar-smtp"
            }
        }
        "Linux" {
            set user [string trim [exec secret-tool lookup service spar-smtp key user]]
            set pass [string trim [exec secret-tool lookup service spar-smtp key pass]]
        }
        "Windows NT" {
            set script {[void][Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime]; $vault = New-Object Windows.Security.Credentials.PasswordVault; $cred = $vault.FindAllByResource('spar-smtp') | Select-Object -First 1; $cred.RetrievePassword(); $cred.UserName; $cred.Password}
            set lines [split [string trim [exec powershell -NoProfile -NonInteractive -Command $script]] "\n"]
            set user [string trim [lindex $lines 0]]
            set pass [string trim [lindex $lines 1]]
        }
        default {
            error "smtp_credentials: unsupported platform \"$tcl_platform(os)\""
        }
    }
    return [dict create user $user pass $pass]
}

# ── SendEmailDriver ──────────────────────────────────────────────────
# Per-dispatch instance. Created by SendEmailTransition::run, lives
# until all tasks are processed (or cancel is called). Registers itself
# in ::spar::live_dispatchers for pause/resume/cancel.

oo::class create ::spar::transitions::SendEmailDriver {
    variable Paused Cancelled
    variable OnProgress OnComplete
    variable Tasks TaskIdx Delay DryRun
    variable CampSender CampFromName CampFromEmail CampBcc CampSmtpHost CampSmtpPort
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

        # GUI confirmation: show email details and let the user approve
        # or skip before hitting the wire.
        set preview "To: $to\nSubject: $subject\n\n[string range $body 0 499]"
        if {[string length $body] > 500} { append preview "\n…" }
        set answer [tk_messageBox -title "Send Email — $stem" \
            -icon question -type yesno \
            -message "Send this email?" \
            -detail $preview]
        if {$answer ne "yes"} {
            if {$OnProgress ne ""} {
                {*}$OnProgress $CurrentSlug skipped "user declined"
            }
            my start_next
            return
        }

        if {$CampSmtpHost eq ""} {
            my fail_task "sender.smtp_host not set in campaign"
            return
        }
        if {[catch {set creds [::spar::smtp_credentials]} err]} {
            my fail_task "keychain lookup failed: $err"
            return
        }

        set params [dict create \
            smtp_host  $CampSmtpHost \
            smtp_port  $CampSmtpPort \
            smtp_user  [dict get $creds user] \
            smtp_pass  [dict get $creds pass] \
            from_email $from_email \
            from_name  $from_name \
            to         $to \
            cc         $cc \
            bcc        $bcc \
            subject    $subject \
            body       $body]

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

        set driver [::spar::transitions::SendEmailDriver new \
            $tasks $delay $dry_run $camp_sender \
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
