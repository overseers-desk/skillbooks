# spar-manager/transitions/ses_send_one.tcl
#
# spar::ses::send_one — pure per-row SMTP-send helper. Sends the final-
# round email message of one approach YAML via SES, then stamps
# actioned_date on success. No callbacks, no thread::send, no registry,
# no event loop — the caller (production: ses_send worker in
# spar-dispatcher-initcmd.tcl; tests: test-pool.tcl) does its own
# signalling.
#
# This file holds the per-row body that the previous CLI's per-
# dispatch send driver used to inline. Decision: keep the subprocess
# invocation of smtp_send.tcl rather than inline the SMTP code — the
# helper is a hot reuse target, the subprocess isolates TLS state and
# is well-tested in production, and inlining would duplicate ~100
# lines of SMTP code into the worker thread.
#
# Inputs (opts dict):
#   campaign_file   abs path to campaign YAML — used only as fallback
#                   for sender.smtp_pass when keychain miss
#   approach_path   abs path to the approach YAML file for this row
#   sender          dict with name email bcc smtp_host smtp_port smtp_user
#                   (constructed by the caller from the campaign cdata)
#   dry_run         1 = skip SES send and skip stamp
#   smtp_helper     optional override path to smtp_send.tcl (tests pass
#                   a fake; default is alongside this file)
#   today           optional ISO date for stamp; default = today
#
# Returns one of:
#   {ok <message-id>}        — sent (or dry-run reported as "dry-run")
#   {error <reason>}         — read/build/send/stamp failure
#
# Pure: no side effects beyond the SMTP send itself, the temp params
# file, and the post-send actioned_date stamp on the approach YAML.

package require TclOO

namespace eval ::spar::ses {
    variable script_dir [file dirname [file normalize [info script]]]
}

proc ::spar::ses::send_one {opts} {
    variable script_dir
    set approach_path [dict get $opts approach_path]
    set sender        [dict get $opts sender]
    set dry_run       [spar::dict_get_default $opts dry_run 0]
    set smtp_helper   [spar::dict_get_default $opts smtp_helper \
        [file join $script_dir smtp_send.tcl]]
    set today         [spar::dict_get_default $opts today \
        [clock format [clock seconds] -format "%Y-%m-%d"]]

    if {![file exists $approach_path]} {
        return [list error "approach file missing: $approach_path"]
    }

    set approach_data [spar::read_approach_yaml $approach_path]
    if {$approach_data eq ""} {
        return [list error "approach read error: $approach_path"]
    }

    set msg [spar::final_email_message $approach_data]
    if {$msg eq ""} {
        return [list error "no email message in final round"]
    }

    set to      [string trim [spar::dict_get_default $msg to ""]]
    set cc      [string trim [spar::dict_get_default $msg cc ""]]
    set bcc     [string trim [spar::dict_get_default $msg bcc ""]]
    set subject [spar::dict_get_default $msg subject ""]
    set body    [spar::dict_get_default $msg body ""]

    set camp_from_name  [spar::dict_get_default $sender name ""]
    set camp_from_email [spar::dict_get_default $sender email ""]
    set camp_bcc        [spar::dict_get_default $sender bcc ""]
    set camp_smtp_host  [spar::dict_get_default $sender smtp_host ""]
    set camp_smtp_port  [spar::dict_get_default $sender smtp_port 587]
    set camp_smtp_user  [spar::dict_get_default $sender smtp_user ""]

    # Sender resolution mirrors the legacy Driver: approach
    # decisions.sender beats campaign sender, used both for the
    # From header and for the reply-header self-removal below.
    set from_name  $camp_from_name
    set from_email $camp_from_email
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
        return [list error \
            "no sender: neither approach decisions.sender.email nor campaign sender.email set"]
    }

    # Reply-mode threading (issue #79).
    set in_reply_to ""
    set references ""
    set is_reply [expr {[spar::dict_get_default $msg mode ""] eq "reply"}]
    if {$is_reply} {
        set parent [spar::dict_get_default $msg parent [dict create]]
        set parent_mid [string trim [spar::dict_get_default $parent message_id ""]]
        if {$parent_mid eq ""} {
            return [list error "reply mode but parent.message_id is empty; cannot construct In-Reply-To"]
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
        return [list error "message missing to/subject/body"]
    }

    if {$bcc eq ""} { set bcc $camp_bcc }
    if {$bcc eq ""} { set bcc $from_email }

    if {$dry_run} {
        return [list ok "dry-run"]
    }

    if {$camp_smtp_host eq ""} {
        return [list error "sender.smtp_host not set in campaign"]
    }
    if {$camp_smtp_user eq ""} {
        return [list error "sender.smtp_user not set in campaign — required (keychain is keyed by host+user)"]
    }
    set _cdata_for_lookup [dict create sender $sender]
    if {[catch {set pass [::spar::smtp_credentials \
            $camp_smtp_host $camp_smtp_user $_cdata_for_lookup]} err]} {
        return [list error "SMTP password lookup failed for ($camp_smtp_host, $camp_smtp_user): $err"]
    }

    set params [dict create \
        smtp_host    $camp_smtp_host \
        smtp_port    $camp_smtp_port \
        smtp_user    $camp_smtp_user \
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

    if {[catch {set tmp_file [exec mktemp]} err]} {
        return [list error "tempfile error: $err"]
    }
    if {[catch {
        set f [open $tmp_file w]
        puts $f $params
        close $f
    } err]} {
        catch {file delete $tmp_file}
        return [list error "tempfile write error: $err"]
    }

    set rc [catch {spar::pool_exec tclsh9.0 $smtp_helper $tmp_file} send_out]
    catch {file delete $tmp_file}

    if {$rc != 0} {
        return [list error "send error: [string trim $send_out]"]
    }

    set message_id [string trim $send_out]
    if {$message_id eq ""} { set message_id "?" }

    if {[catch {set stamped [spar::stamp_actioned_date $approach_path $today]} serr]} {
        return [list error "sent ok ($message_id) but stamp failed: $serr"]
    }
    # A confirmed send that stamps nothing leaves the file reading as
    # unsent — the contact would be re-dispatched (issue #160). The send
    # DID go out; surface it as a FAIL naming the file.
    if {!$stamped} {
        return [list error "sent ok ($message_id) but stamp made no change: $approach_path"]
    }

    return [list ok $message_id]
}

package provide spar-ses-send-one 1.0
