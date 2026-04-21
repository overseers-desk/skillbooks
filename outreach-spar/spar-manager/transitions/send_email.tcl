# spar-manager/transitions/send_email.tcl
#
# SendEmailTransition — T3 (Approach → Send). Dispatches the list of
# approach-ready tasks through spar::send_email (AWS SES). Each task's
# approach YAML is read to extract the final-round email message; the
# sender resolves from decisions.sender (if set) or the campaign
# sender; actioned_date is stamped on success.
#
# Sends are serial with a pacing delay (opts.delay, default 2s) to stay
# under SES rate limits. Commit 3 will convert this to a Dispatcher
# client so pause/cancel reach in-flight sends and the UI stays
# responsive; for now the iteration is synchronous.
#
# Opts consumed:
#   campaign_file  path to campaign YAML
#   dry_run        1 = skip SES send + skip stamp
#   tasks          list of classified ready contacts (from build_opts)
#   delay          seconds between sends (default 2)

oo::class create ::spar::transitions::SendEmailTransition {
    superclass ::spar::transitions::Transition

    method build_opts {tasks filter_segments filter_stems} {
        return [dict create \
            tasks $tasks \
            log_message "[my tid]: [llength $tasks] email(s) ready"]
    }

    method run {opts on_progress on_complete} {
        set campaign_file [dict get $opts campaign_file]
        set dry_run       [expr {[dict exists $opts dry_run] ? [dict get $opts dry_run] : 0}]
        set tasks         [expr {[dict exists $opts tasks] ? [dict get $opts tasks] : {}}]
        set delay         [expr {[dict exists $opts delay] ? [dict get $opts delay] : 2}]

        set cdata [spar::load_campaign $campaign_file]
        set camp_sender    [spar::dict_get_default $cdata sender [dict create]]
        set camp_from_name [spar::dict_get_default $camp_sender name ""]
        set camp_from_email [spar::dict_get_default $camp_sender email ""]
        set camp_bcc       [spar::dict_get_default $camp_sender bcc ""]
        set ses_region     [spar::dict_get_default $cdata ses_region "ap-southeast-2"]

        set done 0
        set failed 0
        set first 1

        foreach c $tasks {
            if {!$first && !$dry_run} { after [expr {$delay * 1000}] }
            set first 0

            set stem    [dict get $c stem]
            set seg_dir [dict get $c _segment_dir]
            set slug    "[file tail $seg_dir]/$stem"
            set approach_path [file join $seg_dir approach "${stem}.yaml"]

            {*}$on_progress $slug started ""

            if {![file exists $approach_path]} {
                {*}$on_progress $slug failed "approach file missing: $approach_path"
                incr failed
                continue
            }

            set approach_data [spar::read_approach_yaml $approach_path]
            set msg [spar::final_email_message $approach_data]
            if {$msg eq ""} {
                {*}$on_progress $slug failed "no email message in final round"
                incr failed
                continue
            }

            set to      [string trim [spar::dict_get_default $msg to ""]]
            set cc      [string trim [spar::dict_get_default $msg cc ""]]
            set bcc     [string trim [spar::dict_get_default $msg bcc ""]]
            set subject [spar::dict_get_default $msg subject ""]
            set body    [spar::dict_get_default $msg body ""]

            if {$to eq "" || $subject eq "" || $body eq ""} {
                {*}$on_progress $slug failed "message missing to/subject/body"
                incr failed
                continue
            }

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
                {*}$on_progress $slug failed \
                    "no sender: neither approach decisions.sender.email nor campaign sender.email set"
                incr failed
                continue
            }
            set from_hdr [expr {$from_name ne "" ? "$from_name <$from_email>" : $from_email}]

            if {$bcc eq ""} { set bcc $camp_bcc }
            if {$bcc eq ""} { set bcc $from_email }

            set send_opts [dict create \
                region  $ses_region \
                from    $from_hdr \
                to      $to \
                subject $subject \
                body    $body \
                dry_run $dry_run]
            if {$cc ne ""}  { dict set send_opts cc  $cc  }
            if {$bcc ne ""} { dict set send_opts bcc $bcc }

            if {[catch {set result [spar::send_email $send_opts]} err]} {
                {*}$on_progress $slug failed "send_email threw: $err"
                incr failed
                continue
            }

            if {![dict get $result ok]} {
                {*}$on_progress $slug failed [dict get $result message_id]
                incr failed
                continue
            }

            if {!$dry_run} {
                set today [clock format [clock seconds] -format "%Y-%m-%d"]
                if {[catch {spar::stamp_actioned_date $approach_path $today} err]} {
                    {*}$on_progress $slug failed "sent ok but stamp failed: $err"
                    incr failed
                    continue
                }
            }

            {*}$on_progress $slug done [dict get $result message_id]
            incr done
        }

        {*}$on_complete $done $failed [dict create]
    }
}

::spar::transitions::register \
    -class ::spar::transitions::SendEmailTransition \
    -tid T3 \
    -label "Approach → Send" \
    -auto-safe 0 \
    -dispatch-status available \
    -ui-tree-row 1
