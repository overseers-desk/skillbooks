# spar-manager/transitions/send_email.tcl
#
# SendEmailTransition (T6, Approach → Send). Sends the final-round
# email message of each approach YAML via SES SMTP. The per-row send
# body lives in transitions/ses_send_one.tcl as a pure helper that
# the Pool's ses_send worker proc invokes; this file keeps only the
# transition-class metadata, the build_opts hook the dispatcher
# reads, the smtp_credentials keychain lookup, and the run method
# that builds the per-row Pool batch.
#
# actioned_date is stamped on success by the helper, not here.
# Sends are serialised at jobs=1 inside the Pool with an inter-row
# delay_ms throttle (opts.delay, default 2s) to stay under SES rate
# limits.
#
# Opts consumed by run:
#   campaign_file  path to campaign YAML
#   dry_run        1 = skip SES send + skip stamp
#   tasks          list of classified ready contacts (from build_opts)
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
