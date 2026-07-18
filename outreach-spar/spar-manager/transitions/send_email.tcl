# spar-manager/transitions/send_email.tcl
#
# SendEmailTransition (T6, Approach → Send). Sends the final-round
# email message of each approach YAML via SES SMTP. The per-row send
# body lives in transitions/ses_send_one.tcl as a pure helper that
# the Pool's ses_send worker proc invokes; this file keeps only the
# transition-class metadata, the build_opts hook the dispatcher
# reads, the smtp_credentials keychain lookup, and the
# prepare_for_pool method that builds the per-row Pool batch.
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

# ── SendEmailTransition ─────────────────────────────────────────────

oo::class create ::spar::transitions::SendEmailTransition {
    superclass ::spar::transitions::Transition

    method build_opts {tasks filter_segments filter_stems} {
        return [dict create \
            tasks $tasks \
            log_message "[my tid]: [llength $tasks] email(s) ready"]
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
        set rows [my _build_rows $opts]
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
    method _build_rows {opts} {
        set campaign_file [dict get $opts campaign_file]
        set dry_run       [dict getdef $opts dry_run 0]
        set tasks         [dict getdef $opts tasks {}]
        set delay         [dict getdef $opts delay 2]

        set cdata [spar::load_campaign $campaign_file]
        set camp_sender [dict getdef $cdata sender [dict create]]

        set delay_ms [expr {$delay * 1000}]
        set rows {}
        set rosters [dict create]
        foreach c $tasks {
            set stem    [dict get $c stem]
            set seg_dir [dict get $c _segment_dir]
            set approach_path [file join $seg_dir approach "${stem}.yaml"]
            set channel [spar::final_auto_send_channel \
                [spar::read_approach_yaml $approach_path]]
            set row [dict create \
                campaign_file $campaign_file \
                dry_run       $dry_run \
                approach_path $approach_path \
                sender        $camp_sender \
                delay_ms      $delay_ms]
            if {$channel eq "linkedin"} {
                if {![dict exists $rosters $seg_dir]} {
                    dict set rosters $seg_dir \
                        [spar::load_roster [file join $seg_dir roster.tsv]]
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
    # wait_days/wait_condition (#49). Approach-YAML structural validity
    # is a hard gate (#43 principle 7). primary_channel is unused here;
    # it is part of the eligible signature every transition class shares.
    method eligible {state contact primary_channel cdata today_iso} {
        set cstate [dict get $contact state]
        if {$cstate ne "APPROACHED" && $cstate ne "SENT"} { return {} }
        set channel [dict getdef $contact auto_send_channel ""]
        switch -- $channel {
            email {
                if {![dict get $contact has_email]} {
                    return [list [spar::_task $contact blocked "No email address"]]
                }
                if {[dict get $contact email_sent]} { return {} }
            }
            linkedin {
                if {![dict get $contact has_linkedin]} {
                    return [list [spar::_task $contact blocked "No linkedin_url"]]
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
            return [list [spar::_task $contact blocked "invalid_approach_yaml: $vmsg"]]
        }
        return [list [spar::_task $contact dispatchable ""]]
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
