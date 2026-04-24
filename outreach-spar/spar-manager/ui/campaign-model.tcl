# spar-manager/ui/campaign-model.tcl
#
# spar::ui::CampaignModel — owns the in-memory model of the current campaign.
#
# Encapsulates campaign config, segment data, classification aggregate
# (all_contacts, transitions, warnings), and async-load state. Consumers
# subscribe to events and read via get_* accessors; no outside code writes
# the encapsulated fields.
#
# Events fired:
#   segment-loaded {segment counts_dict is_active}
#       one segment of the async pass has finished classifying; payload is
#       the segment name, its spar::progress_counts dict, and its active flag
#   fully-loaded
#       all async segments done; warnings and transitions are now populated
#   refreshed
#       a full synchronous refresh has completed; every accessor is fresh
#   log-message {msg}
#       the model wants a line logged (piped to LogWindow by the caller;
#       the model does not own the log window directly)

package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::CampaignModel {
    variable CampaignFile CampaignDir CampaignName SenderText FilterDesc
    variable Cdata SegmentOrder SkipSet SegmentPaths
    variable Segments AllContacts Transitions Warnings
    variable FullLoadDone AsyncAfterIds SegmentPathsForAsync AsyncSegmentsRemaining
    variable ScriptDir
    variable Subs

    constructor {campaign_file script_dir} {
        set CampaignFile $campaign_file
        set CampaignDir  [file dirname $campaign_file]
        set ScriptDir    $script_dir
        set CampaignName ""
        set SenderText   ""
        set FilterDesc   ""
        set Cdata        [dict create]
        set SegmentOrder {}
        set SkipSet      {}
        set SegmentPaths {}
        set Segments     {}
        set AllContacts  {}
        set Transitions  {}
        set Warnings     {}
        set FullLoadDone 1
        set AsyncAfterIds         {}
        set SegmentPathsForAsync  {}
        set AsyncSegmentsRemaining 0
        set Subs [dict create]
    }

    destructor {
        my _cancel_async
    }

    # ─── Subscription ─────────────────────────────────────────────────────
    method subscribe {event cb} { dict lappend Subs $event $cb }

    method _fire {event args} {
        if {![dict exists $Subs $event]} return
        foreach cb [dict get $Subs $event] { {*}$cb {*}$args }
    }

    # ─── Accessors ────────────────────────────────────────────────────────
    method get_campaign_file   {} { return $CampaignFile }
    method get_campaign_dir    {} { return $CampaignDir }
    method get_campaign_name   {} { return $CampaignName }
    method get_sender_text     {} { return $SenderText }
    method get_filter_desc     {} { return $FilterDesc }
    method get_cdata           {} { return $Cdata }
    method get_segment_order   {} { return $SegmentOrder }
    method get_skip_set        {} { return $SkipSet }
    method get_segments        {} { return $Segments }
    method get_all_contacts    {} { return $AllContacts }
    method get_transitions     {} { return $Transitions }
    method get_warnings        {} { return $Warnings }
    method get_full_load_done  {} { return $FullLoadDone }

    method get_smtp_host {} {
        if {![dict exists $Cdata sender]} { return "" }
        return [spar::dict_get_default [dict get $Cdata sender] smtp_host ""]
    }

    method get_smtp_user {} {
        if {![dict exists $Cdata sender]} { return "" }
        return [spar::dict_get_default [dict get $Cdata sender] smtp_user ""]
    }

    method get_smtp_port {} {
        if {![dict exists $Cdata sender]} { return 587 }
        return [spar::dict_get_default [dict get $Cdata sender] smtp_port 587]
    }

    # get_has_smtp_pass -- 1 if the YAML insecurely embeds a password.
    # Presence of the key is the signal — value is not returned.
    method get_has_smtp_pass {} {
        if {![dict exists $Cdata sender]} { return 0 }
        return [dict exists [dict get $Cdata sender] smtp_pass]
    }

    method get_contact {stem} {
        if {$stem eq "" || [llength $AllContacts] == 0} { return "" }
        foreach c $AllContacts {
            if {[spar::dict_get_default $c stem ""] eq $stem} { return $c }
        }
        return ""
    }

    # ─── Public entry points ──────────────────────────────────────────────

    # load — config parse + TSV-only fast pass. Called once at startup
    # before subscribers are wired, so it fires no events.
    method load {} {
        my _load_config
        my _load_fast
    }

    # start_async — kick off async filesystem-dependent load. Each
    # segment fires segment-loaded; the last also fires fully-loaded.
    method start_async {} { my _schedule_async }

    # refresh — cancel any pending async, do a full synchronous pass,
    # fire refreshed.
    method refresh {} {
        my _cancel_async
        my _load_full
        my _fire refreshed
    }

    # ─── Internal: helpers ────────────────────────────────────────────────

    method _format_pct {num denom} {
        if {$denom == 0} { return "-" }
        return "[expr {$num * 100 / $denom}]%"
    }

    method _zero_row {} {
        return [list 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {} 0 {}]
    }

    # ─── Internal: config load ────────────────────────────────────────────

    method _load_config {} {
        if {![file exists $CampaignFile]} {
            tk_messageBox -icon error -title "Campaign Missing" \
                -message "Campaign YAML no longer exists:\n$CampaignFile"
            set CampaignName "(missing)"
            set SenderText   ""
            set FilterDesc   ""
            set SegmentOrder {}
            set SegmentPaths {}
            return 0
        }

        if {[catch {set Cdata [spar::load_campaign $CampaignFile]} err]} {
            tk_messageBox -icon error -title "Campaign Load Error" \
                -message "Error loading campaign:\n$err"
            set CampaignName "(error)"
            set SenderText   ""
            set FilterDesc   ""
            set SegmentOrder {}
            set SegmentPaths {}
            return 0
        }

        set CampaignName [spar::dict_get_default $Cdata campaign [file tail $CampaignFile]]

        # Sender
        set sender_parts {}
        if {[dict exists $Cdata sender]} {
            set sender_d [dict get $Cdata sender]
            set s_name  [spar::dict_get_default $sender_d name  ""]
            set s_role  [spar::dict_get_default $sender_d role  ""]
            set s_email [spar::dict_get_default $sender_d email ""]
            if {$s_name  ne ""} { lappend sender_parts $s_name }
            if {$s_role  ne ""} { lappend sender_parts $s_role }
            if {$s_email ne ""} { lappend sender_parts "($s_email)" }
        }
        set SenderText [join $sender_parts ", "]

        # Filter
        set FilterDesc ""
        if {[dict exists $Cdata filter]} {
            set filt [dict get $Cdata filter]
            set filter_parts {}
            if {[catch {
                dict for {k v} $filt { lappend filter_parts "${k}=${v}" }
            }]} {
                set FilterDesc "$filt"
            } else {
                set FilterDesc [join $filter_parts "  "]
            }
        }

        # Discover segments
        set segments_list {}
        if {[dict exists $Cdata segments]} {
            set segments_list [dict get $Cdata segments]
        }
        set SkipSet {}
        if {[dict exists $Cdata skip_segments]} {
            foreach s [dict get $Cdata skip_segments] { lappend SkipSet $s }
        }
        if {[llength $segments_list] == 0} {
            foreach child [lsort [glob -nocomplain [file join $CampaignDir *]]] {
                if {[file isdirectory $child] && [file exists [file join $child roster.tsv]]} {
                    lappend segments_list [file tail $child]
                }
            }
        }

        set SegmentOrder {}
        set SegmentPaths {}
        foreach seg $segments_list {
            set seg_dir [file join $CampaignDir $seg]
            if {[file isdirectory $seg_dir] && [file exists [file join $seg_dir roster.tsv]]} {
                lappend SegmentOrder $seg
                lappend SegmentPaths [list $seg $seg_dir]
            }
        }

        return 1
    }

    # ─── Internal: fast load (TSV counts only) ────────────────────────────

    method _load_fast {} {
        set FullLoadDone 0
        set SegmentPathsForAsync {}

        if {![my _load_config]} {
            set Segments    {}
            set Warnings    {}
            set Transitions {}
            set AllContacts {}
            set FullLoadDone 1
            return
        }

        set AllContacts {}
        set Segments    {}

        foreach item $SegmentPaths {
            lassign $item label seg_dir
            set is_active [expr {$label ni $SkipSet}]

            lappend SegmentPathsForAsync [list $label $seg_dir $is_active]

            if {[catch {set rcounts [spar::roster_counts $seg_dir]} err]} {
                lappend Segments [list $label $is_active [my _zero_row]]
                continue
            }

            set v  [dict get $rcounts valid]
            set s3 [dict get $rcounts star3]
            set e  [dict get $rcounts has_email]
            set l  [dict get $rcounts has_linkedin]
            set f  [dict get $rcounts has_facebook]
            set po [dict get $rcounts has_phone_only]

            set raw_data [list \
                $v {} \
                0 {} \
                $s3 [my _format_pct $s3 $v] \
                0 {} \
                $e  [my _format_pct $e  $s3] \
                0 {} \
                $l  [my _format_pct $l  $s3] \
                $f  [my _format_pct $f  $s3] \
                $po [my _format_pct $po $s3] \
                0 {} \
                0 {}]

            lappend Segments [list $label $is_active $raw_data]
        }

        set Warnings    {}
        set Transitions {}
    }

    # ─── Internal: full synchronous load ──────────────────────────────────

    method _load_full {} {
        set FullLoadDone 1

        if {![my _load_config]} {
            set Segments    {}
            set Warnings    {}
            set Transitions {}
            set AllContacts {}
            return
        }

        set AllContacts {}
        set Segments    {}

        foreach item $SegmentPaths {
            lassign $item label seg_dir
            set is_active [expr {$label ni $SkipSet}]

            if {[catch {set classified [spar::classify_segment $seg_dir]} err]} {
                lappend Segments [list $label $is_active [my _zero_row]]
                continue
            }

            if {$is_active} {
                foreach c $classified { lappend AllContacts $c }
            }

            set counts [spar::progress_counts $classified]

            set v  [dict get $counts valid]
            set p  [dict get $counts profiled]
            set s3 [dict get $counts star3]
            set a3 [dict get $counts approached_star3]
            set e  [dict get $counts has_email]
            set ae [dict get $counts approached_email]
            set l  [dict get $counts has_linkedin]
            set f  [dict get $counts has_facebook]
            set po [dict get $counts has_phone_only]
            set es [dict get $counts email_sent]
            set er [dict get $counts email_replied]

            set raw_data [list \
                $v  {} \
                $p  [my _format_pct $p  $v] \
                $s3 [my _format_pct $s3 $v] \
                $a3 [my _format_pct $a3 $s3] \
                $e  [my _format_pct $e  $s3] \
                $ae [my _format_pct $ae $e] \
                $l  [my _format_pct $l  $s3] \
                $f  [my _format_pct $f  $s3] \
                $po [my _format_pct $po $s3] \
                $es [my _format_pct $es $ae] \
                $er [my _format_pct $er $es]]

            lappend Segments [list $label $is_active $raw_data]
        }

        set Warnings    [dict get [spar::build_warnings $AllContacts $Cdata] messages]
        set Transitions [my _build_transitions]
    }

    # ─── Internal: transition build ───────────────────────────────────────

    method _build_transitions {} {
        set tids [spar::ui_transition_tids]

        set primary_channel ""
        if {[dict size $Cdata] > 0} {
            set primary_channel [spar::campaign_primary_channel $Cdata]
        }

        set result {}
        foreach tid $tids {
            set label [spar::transition_label $tid]

            set eligible [spar::transition_eligible $AllContacts $tid $primary_channel $Cdata]
            set count [llength $eligible]

            set tasks {}
            foreach contact $eligible {
                set cname  [dict get $contact contact_name]
                set cstem  [spar::dict_get_default $contact stem ""]
                set org    [dict get $contact organisation]
                set seg    [dict get $contact segment]
                set tstate [dict get $contact task_state]
                set reason [dict get $contact reason]
                lappend tasks [list $cname $cstem $org $seg $tstate $reason]
            }

            lappend result [list $label $count $tasks]
        }

        return $result
    }

    # ─── Internal: async loader ───────────────────────────────────────────

    method _cancel_async {} {
        foreach id $AsyncAfterIds { after cancel $id }
        set AsyncAfterIds {}
    }

    method _schedule_async {} {
        my _cancel_async
        set AsyncSegmentsRemaining [llength $SegmentPathsForAsync]
        if {$AsyncSegmentsRemaining == 0} {
            set FullLoadDone 1
            my _fire fully-loaded
            return
        }
        lappend AsyncAfterIds [after 1 [list [self] async_next]]
    }

    method async_next {} {
        if {[llength $SegmentPathsForAsync] == 0} return

        set item [lindex $SegmentPathsForAsync 0]
        set SegmentPathsForAsync [lrange $SegmentPathsForAsync 1 end]
        lassign $item seg_name seg_dir is_active

        if {![catch {set classified [spar::classify_segment $seg_dir]} err]} {
            if {$is_active} {
                foreach c $classified { lappend AllContacts $c }
            }
            set cdict [spar::progress_counts $classified]
            my _fire segment-loaded $seg_name $cdict $is_active
        }

        incr AsyncSegmentsRemaining -1

        if {[llength $SegmentPathsForAsync] > 0} {
            lappend AsyncAfterIds [after 1 [list [self] async_next]]
        } else {
            set FullLoadDone 1
            set Warnings    [dict get [spar::build_warnings $AllContacts $Cdata] messages]
            set Transitions [my _build_transitions]
            my _fire fully-loaded
        }
    }
}
