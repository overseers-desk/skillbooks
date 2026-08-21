# spar-manager/transitions/send_email.tcl
#
# SendEmailTransition (T6, Approach → Send). Sends the final-round
# message of each approach YAML: email via SES SMTP, linkedin via the
# overseer. The class carries the transition metadata, the build_opts
# hook the dispatcher reads, the smtp_credentials keychain lookup, and
# the prepare_for_pool method that builds the per-row Pool batch. The
# two per-row legs the Pool's ses_send and linkedin_send worker procs
# invoke, spar::ses::send_one and spar::li::send_one, follow the class.
#
# actioned_date is stamped on success by the helper, not here.
# Sends are serialised at the unified Dispatcher's per-worker cap
# (set_kind_cap ses_send 1, installed by spar-transition.tcl's
# dispatch_ready) with an inter-row delay_ms throttle (opts.delay,
# default 2s) to stay under SES rate limits. SES rows therefore run
# at most one at a time inside the same shared pool that runs
# harness_run rows in parallel.
#
# Opts consumed by prepare_for_pool:
#   campaign_file  path to campaign YAML
#   dry_run        1 = skip SES send + skip stamp
#   tasks          list of classified dispatchable contacts (from build_opts)
#   delay          seconds between sends (default 2)
#   step_callback  optional --jobs=0 stepping gate

package require TclOO
package require http
package require json
package require json::write

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
                    set pass [string trim [spar::pool_exec security \
                        find-generic-password -s $host -a $user -w]]
                }
                "Linux" {
                    set pass [string trim [spar::pool_exec secret-tool lookup \
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

# send_channels — the auto-send channel vocabulary: every value
# spar::final_auto_send_channel routes to a send worker (email →
# ses_send, linkedin → the overseer /run leg). --action validates
# against this list and _build_rows filters by it; a new send leg
# (another platform's worker) adds its channel here in the same
# commit that adds its routing below.
proc ::spar::transitions::send_channels {} {
    return {email linkedin}
}

# ── SendEmailTransition ─────────────────────────────────────────────

oo::class create ::spar::transitions::SendEmailTransition {
    superclass ::spar::transitions::Transition

    method build_opts {tasks filter_segments filter_stems} {
        return [dict create \
            tasks $tasks \
            log_message "[my tid]: [llength $tasks] send(s) ready"]
    }

    # prepare_for_pool — pool-shape entry. Returns
    # {worker_proc ses_send rows {{stem opts} ...}}; a row's opts may
    # carry its own worker_proc (linkedin rows carry linkedin_send),
    # which the enqueuers honour over the batch default. The callers
    # (spar-transition.tcl's dispatch_ready, the GUI's pool setup)
    # install set_kind_cap 1 for both send workers on the shared
    # Dispatcher so send rows run serially even when other transition
    # kinds parallelise.
    method prepare_for_pool {opts on_progress} {
        set rows [my _build_rows $opts $on_progress]
        return [dict create worker_proc ses_send rows $rows]
    }

    # _build_rows — per-row opts dict construction for prepare_for_pool.
    # Reads tasks, campaign_file, dry_run, delay, sender from opts; the
    # per-row dict carries everything the send worker needs for one
    # message. Each contact's OWN primary touch
    # (spar::final_auto_send_channel, the same selector eligible routes
    # on) decides the worker: email rows go to ses_send, linkedin rows to
    # linkedin_send (which also gets the contact's linkedin_url from the
    # segment roster). The send path is a full-file bypass site, so it
    # reads the approach directly.
    method _build_rows {opts on_progress} {
        set campaign_file [dict get $opts campaign_file]
        set dry_run       [dict getdef $opts dry_run 0]
        set tasks         [dict getdef $opts tasks {}]
        set delay         [dict getdef $opts delay 2]
        # --action scope: an empty list means every channel sends.
        set actions       [dict getdef $opts actions {}]

        set cdata [spar::load_campaign $campaign_file]
        set camp_sender [dict getdef $cdata sender [dict create]]

        set delay_ms [expr {$delay * 1000}]
        set rows {}
        set rosters [dict create]
        foreach c $tasks {
            set stem    [dict get $c stem]
            set seg_dir [dict get $c _segment_dir]
            set approach_path [spar::approach_path_for_stem $campaign_file $stem]
            set channel [spar::final_auto_send_channel \
                [spar::read_approach_yaml $approach_path]]
            if {[llength $actions] > 0 && $channel ni $actions} {
                {*}$on_progress $stem skipped \
                    "channel '$channel' outside --action=[join $actions ,]"
                continue
            }
            set row [dict create \
                campaign_file $campaign_file \
                dry_run       $dry_run \
                approach_path $approach_path \
                sender        $camp_sender \
                delay_ms      $delay_ms]
            if {$channel eq "linkedin"} {
                if {![dict exists $rosters $seg_dir]} {
                    dict set rosters $seg_dir \
                        [spar::load_roster [spar::roster_path_for_segment $seg_dir]]
                }
                set linkedin_url ""
                foreach r [dict get $rosters $seg_dir] {
                    if {[dict getdef $r stem ""] eq $stem} {
                        set linkedin_url [string trim \
                            [dict getdef $r linkedin_url ""]]
                        break
                    }
                }
                dict set row worker_proc linkedin_send
                dict set row linkedin_url $linkedin_url
            }
            lappend rows [list $stem $row]
        }
        return $rows
    }

    # T6: APPROACHED/SENT, routed by the contact's OWN primary touch
    # (spar::final_auto_send_channel over its final round), not the
    # campaign channel, so an email-only contact in a linkedin-primary
    # campaign sends by email. email → SES rows (has_email, not yet
    # email_sent); linkedin → overseer /run rows (has_linkedin, not yet
    # linkedin_sent). Secondary/tertiary channels belong to T9/T10 with
    # wait_days/wait_condition (#174). Approach-YAML structural validity
    # is a hard gate (#43 principle 7). primary_channel is unused here;
    # it is part of the eligible signature every transition class shares.
    method eligible {state contact primary_channel cdata today_iso} {
        set cstate [dict get $contact state]
        if {$cstate ne "APPROACHED" && $cstate ne "SENT"} { return {} }
        set channel [dict getdef $contact auto_send_channel ""]
        switch -- $channel {
            email {
                if {![dict get $contact has_email]} {
                    return [list [spar::_task $contact blocked "No email address" $channel]]
                }
                if {[dict get $contact email_sent]} { return {} }
            }
            linkedin {
                if {![dict get $contact has_linkedin]} {
                    return [list [spar::_task $contact blocked "No linkedin_url" $channel]]
                }
                if {[dict get $contact linkedin_sent]} { return {} }
            }
            default {
                # No auto-send channel resolves for a phone-only final
                # round, but also for a structurally broken approach
                # file (no final round at all). The broken file stays
                # visible as blocked; only the genuinely other-channel
                # contact drops out of T6.
                set vmsg [$state approach_validation_error $contact]
                if {$vmsg ne ""} {
                    return [list [spar::_task $contact blocked "invalid_approach_yaml: $vmsg"]]
                }
                return {}
            }
        }
        set vmsg [$state approach_validation_error $contact]
        if {$vmsg ne ""} {
            return [list [spar::_task $contact blocked "invalid_approach_yaml: $vmsg" $channel]]
        }
        return [list [spar::_task $contact dispatchable "" $channel]]
    }
}

::spar::transitions::register \
    -class ::spar::transitions::SendEmailTransition \
    -tid T6 \
    -outgoing 1 \
    -label "Approach → Send" \
    -auto-safe 0 \
    -dispatch-status available \
    -requires-send-confirmation 1 \
    -ui-tree-row 1

# ── spar::ses::send_one — per-row SMTP-send leg ─────────────────────
#
# Pure per-row SMTP-send helper. Sends the final-
# round email message of one approach YAML via SES, then stamps
# actioned_date on success. No callbacks, no thread::send, no registry,
# no event loop — the caller (production: ses_send worker in
# spar-dispatcher.tcl; tests: test-pool.tcl) does its own
# signalling.
#
# The SMTP exchange itself is the subprocess smtp_send.tcl beside this
# file: it isolates TLS state per send.
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


namespace eval ::spar::ses {
    variable script_dir [file dirname [file normalize [info script]]]
}

proc ::spar::ses::send_one {opts} {
    variable script_dir
    set approach_path [dict get $opts approach_path]
    set sender        [dict get $opts sender]
    set dry_run       [dict getdef $opts dry_run 0]
    set smtp_helper   [dict getdef $opts smtp_helper \
        [file join $script_dir smtp_send.tcl]]
    set today         [dict getdef $opts today \
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

    set to      [string trim [dict getdef $msg to ""]]
    set cc      [string trim [dict getdef $msg cc ""]]
    set bcc     [string trim [dict getdef $msg bcc ""]]
    set subject [dict getdef $msg subject ""]
    set body    [dict getdef $msg body ""]

    set camp_from_name  [dict getdef $sender name ""]
    set camp_from_email [dict getdef $sender email ""]
    set camp_bcc        [dict getdef $sender bcc ""]
    set camp_smtp_host  [dict getdef $sender smtp_host ""]
    set camp_smtp_port  [dict getdef $sender smtp_port 587]
    set camp_smtp_user  [dict getdef $sender smtp_user ""]

    # Sender resolution mirrors the legacy Driver: approach
    # decisions.sender beats campaign sender, used both for the
    # From header and for the reply-header self-removal below.
    set from_name  $camp_from_name
    set from_email $camp_from_email
    if {[dict exists $approach_data decisions]} {
        set ad_sender [dict getdef \
            [dict get $approach_data decisions] sender [dict create]]
        set ad_name  [dict getdef $ad_sender name ""]
        set ad_email [dict getdef $ad_sender email ""]
        if {$ad_email ne ""} {
            set from_email $ad_email
            if {$ad_name ne ""} { set from_name $ad_name }
        }
    }
    if {$from_email eq ""} {
        return [list error \
            "no sender: neither approach decisions.sender.email nor campaign sender.email set"]
    }

    # Reply threading (issue #79). A parent block is what makes the
    # message a reply on an existing thread.
    set in_reply_to ""
    set references ""
    set is_reply [dict exists $msg parent]
    if {$is_reply} {
        set parent [dict get $msg parent]
        set parent_mid [string trim [dict getdef $parent message_id ""]]
        if {$parent_mid eq ""} {
            return [list error "reply has an empty parent.message_id; cannot construct In-Reply-To"]
        }
        set reply_all [dict getdef $msg reply_all 0]
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

# ── spar::li::send_one — per-row LinkedIn send leg ──────────────────
#
# Per-row LinkedIn send through the overseer's
# POST /run (contract: docs/ducks-protocol.md in the Matter repository,
# the runner's design home). The overseer owns the logged-in browser, the profile
# lock, and the linkedin.com rate gate; this helper asks it to run one
# send primitive and interprets the primitive's result. Fail-fast rule:
# GET /health is probed first, and an absent or unhealthy overseer is
# an error, never a silent skip. No pacing here — cadence is the
# overseer's; the probe reads that cadence back so a parked row can say
# what it waits on (health_note).
#
# Inputs (opts dict):
#   approach_path  abs path to the approach YAML for this row
#   linkedin_url   the contact's roster linkedin_url (vanity source)
#   dry_run        1 = validate and report without calling the overseer
#   overseer_url   optional override; default http://127.0.0.1:11402
#   today          optional ISO date for stamp; default = today
#   note_cmd       optional cmdprefix, called with one line of text when
#                  the probe finds something standing in this send's way
#                  (a rate gate, an open breaker, an account not signed
#                  in). The dispatcher passes the pool's phase verb, so
#                  the row says what it is waiting on.
#
# Skill selection: an invitation with the text as its note by default;
# invitation_unavailable: true routes to a direct Message
# (linkedin.com/send-invite vs linkedin.com/send-message).
#
# Returns one of:
#   {ok sent}        — the primitive confirmed the send; actioned_date
#                      stamped on the linkedin message
#   {ok "<invitation|message>, <N> chars"} — dry run: validated only, nothing sent,
#                      nothing stamped; detail names the route and the
#                      message length (e.g. "invite, 264 chars")
#   {error <reason>} — probe/read/build/run failure, or a primitive
#                      status of error/failed/uncertain. uncertain is
#                      never stamped: the human checks LinkedIn.


namespace eval ::spar::li {
    variable default_overseer "http://127.0.0.1:11402"
}

# One JSON POST to the overseer; returns the parsed response dict.
# Timeout is generous: a /run holds through the browser pool queue and
# the linkedin.com rate gate before the primitive even launches.
proc ::spar::li::_post_json {url body timeout_ms} {
    set tok [spar::pool_http $url -method POST -type application/json \
        -query $body -timeout $timeout_ms]
    try {
        if {[http::status $tok] ne "ok"} {
            error "overseer unreachable: [http::status $tok] [http::error $tok]"
        }
        if {[http::ncode $tok] != 200} {
            error "overseer HTTP [http::ncode $tok]: [string range [http::data $tok] 0 200]"
        }
        return [json::json2dict [http::data $tok]]
    } finally {
        http::cleanup $tok
    }
}

# GET /health, erroring unless it answers ok:true. A refusal names the
# overseer's own fault detail when it reported one, so the row says what
# is wrong rather than only that something is.
proc ::spar::li::_health {overseer} {
    set tok [spar::pool_http "$overseer/health" -timeout 5000]
    try {
        if {[http::status $tok] ne "ok" || [http::ncode $tok] != 200} {
            error "health probe failed"
        }
        set h [json::json2dict [http::data $tok]]
        if {![dict getdef $h ok 0]} {
            error "overseer reports not ok[::spar::li::_fault_suffix $h]"
        }
        return $h
    } finally {
        http::cleanup $tok
    }
}

# ": <detail>" from a health or /run document's fault object, or "" when
# it carries none. fault is null (json2dict yields the string) when clear,
# so the shape is checked before it is read as a dict.
proc ::spar::li::_fault_suffix {doc} {
    set f [dict getdef $doc fault ""]
    if {$f in {"" null}} { return "" }
    set detail ""
    catch {set detail [dict get $f detail]}
    return [expr {$detail ne "" ? ": $detail" : ""}]
}

# What /health says stands between this send and the browser, as one
# phrase, or "" when the way is clear. The document is the one _health
# already fetched, so this costs no extra round trip.
#
#   gates    host -> {opensIn_s, interval_s}: the seconds until that
#            host's rate gate frees, beside the interval it counts from
#   lanes    lane -> {since count detail}, an open circuit breaker; a
#            send's lane is its skill ref
#   holds    host -> identity -> {...}, an account declined until someone
#            signs it in again
#
# Every key is read by host or by lane, so a platform added later reads
# out of the same document with no change here.
proc ::spar::li::health_note {h host {lane ""}} {
    set parts {}
    # The gate names its unit in the key: take the countdown, not the
    # interval standing beside it. Guarded, so a document shaped another
    # way cannot throw in a send's path.
    set secs 0
    catch {set secs [dict get $h gates $host opensIn_s]}
    if {[string is integer -strict $secs] && $secs > 0} {
        lappend parts "$host gate ${secs}s"
    }
    if {$lane ne ""} {
        set trip [dict getdef $h lanes $lane ""]
        if {$trip ne ""} {
            lappend parts "lane tripped after [dict getdef $trip count "repeated"] failures"
        }
    }
    set held [dict keys [dict getdef $h holds $host ""]]
    if {[llength $held]} {
        lappend parts "account not signed in: [join $held {, }]"
    }
    return [join $parts "; "]
}

# What the server said, as one phrase for the dispatch log. The primitive
# decides "sent" from a disjunction of unequal strength: an invitation or
# message API that answered 2xx is proof, while a modal that merely closed
# with no API call captured is inference. Both arrive as the same word, so
# the phrase names the evidence and the operator can tell one from the
# other without opening the browser.
#
# Reads the fields the two send primitives return (send-invite.tcl,
# send-message.tcl): api_responses, server_message_echo, toast, and the
# per-primitive cleared flag (modal_closed / compose_cleared).
proc ::spar::li::send_proof {r} {
    set parts {}

    set codes {}
    foreach e [dict getdef $r api_responses {}] {
        catch {lappend codes [dict get $e status]}
    }
    set api_ok 0
    foreach c $codes { if {$c in {200 201 204}} { set api_ok 1 } }
    if {[llength $codes]} {
        lappend parts "API [join $codes {, }]"
    } else {
        lappend parts "no API call captured"
    }

    set echo [dict getdef $r server_message_echo ""]
    if {$echo ni {"" null}} {
        lappend parts "server echoed the text"
    }
    set toast [dict getdef $r toast ""]
    if {$toast ni {"" null}} {
        lappend parts "toast: [string range $toast 0 79]"
    }
    foreach {k phrase} {modal_closed {modal closed} compose_cleared {compose cleared}} {
        set v [dict getdef $r $k ""]
        if {$v ni {"" null}} {
            lappend parts [expr {[string is true -strict $v] ? $phrase : "$phrase: no"}]
        }
    }

    # The operator's cue that this send rests on inference alone.
    if {!$api_ok} { lappend parts "unconfirmed by server" }
    return [join $parts "; "]
}

proc ::spar::li::send_one {opts} {
    variable default_overseer
    set approach_path [dict get $opts approach_path]
    set linkedin_url  [string trim [dict getdef $opts linkedin_url ""]]
    set dry_run       [dict getdef $opts dry_run 0]
    set overseer      [dict getdef $opts overseer_url $default_overseer]
    set today         [dict getdef $opts today \
        [clock format [clock seconds] -format "%Y-%m-%d"]]
    set note_cmd      [dict getdef $opts note_cmd ""]

    if {![file exists $approach_path]} {
        return [list error "approach file missing: $approach_path"]
    }
    set approach_data [spar::read_approach_yaml $approach_path]
    if {$approach_data eq ""} {
        return [list error "approach read error: $approach_path"]
    }
    set msg [spar::final_channel_message $approach_data linkedin]
    if {$msg eq ""} {
        return [list error "no linkedin message in final round"]
    }
    set text [string trim [dict getdef $msg text ""]]
    if {$text eq ""} { set text [string trim [dict getdef $msg body ""]] }
    if {$text eq ""} {
        return [list error "linkedin message has no text"]
    }

    # Vanity slug from the roster URL (linkedin.com/in/<vanity>).
    if {![regexp {linkedin\.com/in/([^/?#]+)} $linkedin_url -> vanity]} {
        return [list error "cannot extract vanity name from linkedin_url: '$linkedin_url'"]
    }

    # The first touch is a connection invitation with the text as its
    # note. invitation_unavailable: true records that this profile offers
    # no note box (follow-first profile, invitation limit), and the text
    # goes out as a direct Message instead.
    if {[string is true -strict [dict getdef $msg invitation_unavailable 0]]} {
        set send_as "message"
        set skill_ref "linkedin.com/send-message"
    } else {
        set send_as "invitation"
        set skill_ref "linkedin.com/send-invite"
        if {[string length $text] > 300} {
            return [list error "invite note is [string length $text] chars; LinkedIn limit is 300"]
        }
    }

    if {$dry_run} {
        return [list ok "$send_as, [string length $text] chars"]
    }

    # Fail-fast probe: the overseer must be present and healthy.
    if {[catch {set health [::spar::li::_health $overseer]} err]} {
        return [list error "overseer not available at $overseer — start it before T6 linkedin sends ($err)"]
    }

    # A /run parks server-side behind the rate gate, an open breaker or a
    # held account, so the row would otherwise sit silent for as long as
    # the wait lasts. The probe already knows why; report it through the
    # caller's note cmdprefix, and keep it for the failure text.
    set note [::spar::li::health_note $health \
        [lindex [split $skill_ref /] 0] $skill_ref]
    if {$note ne "" && $note_cmd ne ""} {
        catch {{*}$note_cmd $note}
    }
    set at_probe [expr {$note ne "" ? " (at probe: $note)" : ""}]

    # The runner holds no skills checkout: the caller resolves the skill body
    # and the serialiser lib dir and hands both in (ducks-protocol.md, POST
    # /run). BI_SKILLS_ROOT names the checkout's skills/ directory, the same
    # variable the overseer runbook uses. Absent or wrong, fail before the
    # queue: a half-resolved payload would refuse server-side anyway.
    if {![info exists ::env(BI_SKILLS_ROOT)]} {
        return [list error "BI_SKILLS_ROOT is not set; export it as <skills-checkout>/skills so the send leg can hand the overseer skillPath and libDir (ducks-protocol.md POST /run)"]
    }
    set skills_root $::env(BI_SKILLS_ROOT)
    set skill_path [file join $skills_root "$skill_ref.tcl"]
    if {![file exists $skill_path]} {
        return [list error "BI_SKILLS_ROOT does not resolve: skill body missing at $skill_path"]
    }
    # libDir is the dir holding serialiser-harness.tcl. The contract sketches
    # <root>/skills/lib; the deployed toolbox keeps it at <root>/lib beside
    # skills/. Accept whichever holds the harness; neither is a fault.
    set lib_dir ""
    foreach cand [list [file join $skills_root lib] \
                       [file join [file dirname $skills_root] lib]] {
        if {[file exists [file join $cand serialiser-harness.tcl]]} {
            set lib_dir $cand
            break
        }
    }
    if {$lib_dir eq ""} {
        return [list error "no serialiser-harness.tcl under $skills_root/lib or [file dirname $skills_root]/lib; BI_SKILLS_ROOT points at the wrong checkout"]
    }

    set args_json [json::write array \
        [json::write string $vanity] \
        [json::write string $text]]
    set body [json::write object \
        skillRef [json::write string $skill_ref] \
        skillPath [json::write string $skill_path] \
        libDir [json::write string $lib_dir] \
        argsJson [json::write string $args_json]]

    if {[catch {
        set resp [::spar::li::_post_json "$overseer/run" $body 600000]
    } err]} {
        return [list error "overseer /run failed: $err$at_probe"]
    }

    # Outer fault: the browser or the primitive failed to run at all.
    if {[dict exists $resp fault] && [dict get $resp fault] ni {null ""}} {
        set f [dict get $resp fault]
        set shape ""; set detail ""
        catch {set shape [dict get $f shape]}
        catch {set detail [dict get $f detail]}
        return [list error "overseer fault ($shape): $detail$at_probe"]
    }
    set inner [dict getdef $resp result ""]
    if {$inner in {"" null}} {
        return [list error "overseer returned no result"]
    }
    if {[catch {set r [json::json2dict $inner]} err]} {
        return [list error "unparseable primitive result: [string range $inner 0 200]"]
    }
    set status [dict getdef $r status ""]
    switch -- $status {
        sent {
            if {[catch {set stamped [spar::stamp_actioned_date $approach_path $today linkedin]} serr]} {
                return [list error "sent ok but stamp failed: $serr"]
            }
            # A confirmed send that stamps nothing leaves the file reading
            # as unsent — the contact would be re-dispatched (issue #160).
            # The send DID go out; surface it as a FAIL naming the file.
            if {!$stamped} {
                return [list error "sent ok but stamp made no change: $approach_path"]
            }
            return [list ok "sent; [::spar::li::send_proof $r]"]
        }
        default {
            set reason [dict getdef $r reason ""]
            if {$reason eq ""} { set reason $status }
            return [list error "primitive status '$status': $reason$at_probe"]
        }
    }
}
