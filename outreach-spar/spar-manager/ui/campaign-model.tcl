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
#   transition-loaded {tid label tasks}
#       one transition's eligibility has been computed; payload is the
#       tid string, its display label, and the list of task tuples (one
#       per eligible contact). Cheap-eligibility TIDs (T1..T4, no
#       approach-YAML parse needed) fire after Phase 1; parse TIDs (T6..T8)
#       fire after Phase 2 enrichment completes. Subscribers append
#       incrementally — `transition-loaded` arrival order matches
#       numeric T-id order under #82's loader phasing.
#   contact-finalised {stem}
#       a single contact's approach YAML has been parsed and the
#       SENT/REPLIED/to_addresses/unsent_subjects fields overlaid onto
#       its dict in AllContacts. Fires in Phase 2; payload is the stem
#       (lookup key for get_contact). No subscribers required — the event
#       is forward-leaning for #84's per-contact projection consumers.
#   reloading
#       refresh has reset Segments to TSV-only counts and emptied
#       AllContacts/Transitions/Warnings; subscribers should clear
#       their views. Fired before start_async kicks off; fully-loaded
#       fires when the post-reload coroutine completes.
#   fully-loaded
#       all async segments done; warnings and transitions are now populated
#   log-message {msg}
#       the model wants a line logged (piped to LogWindow by the caller;
#       the model does not own the log window directly)

package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::CampaignModel {
    variable CampaignFile CampaignDir CampaignName SenderText FilterDesc
    variable Cdata SegmentOrder SkipSet SegmentPaths
    variable Segments AllContacts Transitions Warnings
    variable FullLoadDone SegmentPathsForAsync
    variable LoaderCoro LoaderAfterId
    variable ScriptDir
    variable Subs
    variable State

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
        set SegmentPathsForAsync  {}
        set LoaderCoro    ""
        set LoaderAfterId ""
        set Subs [dict create]
        # State lives for the model's lifetime so Phase B can reuse cache
        # entries across refresh() calls; refresh does not destroy/recreate.
        set State [spar::State new]
    }

    destructor {
        my _cancel_loader
        if {[info exists State] && [info commands $State] ne ""} {
            $State destroy
        }
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
    method get_state           {} { return $State }

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
    # Runs as a coroutine that yields back to the event loop between
    # segments and around the post-loop warnings/transitions build, so
    # the UI stays responsive throughout.
    method start_async {} {
        my _cancel_loader
        if {[llength $SegmentPathsForAsync] == 0} {
            set FullLoadDone 1
            my _fire fully-loaded
            return
        }
        set LoaderCoro [info object namespace [self]]::loader#[clock microseconds]
        coroutine $LoaderCoro [self] loader_body
    }

    # refresh — reload from disk. Resets state to the TSV-only pass,
    # fires `reloading` so views can clear, then re-runs the same
    # coroutine load() uses. fully-loaded fires when filling completes.
    method refresh {} {
        my _load_fast
        my _fire reloading
        my start_async
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

    # ─── Internal: transition build ───────────────────────────────────────

    method _primary_channel {} {
        if {[dict size $Cdata] == 0} { return "" }
        return [spar::campaign_primary_channel $Cdata]
    }

    method _transition_entry {tid primary_channel} {
        set label [spar::transition_label $tid]
        set eligible [$State transition_eligible $AllContacts $tid $primary_channel $Cdata]
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
        return [list $label [llength $eligible] $tasks]
    }

    method _build_transitions {} {
        set primary_channel [my _primary_channel]
        set result {}
        foreach tid [spar::ui_transition_tids] {
            lappend result [my _transition_entry $tid $primary_channel]
        }
        return $result
    }

    # ─── Internal: async loader (coroutine) ───────────────────────────────

    method _cancel_loader {} {
        if {$LoaderAfterId ne ""} {
            after cancel $LoaderAfterId
            set LoaderAfterId ""
        }
        if {$LoaderCoro ne "" && [llength [info commands $LoaderCoro]]} {
            rename $LoaderCoro ""
        }
        set LoaderCoro ""
    }

    method _yield_loop {} {
        # `after 1` (not `after 0`) so Tk's idle-priority redraws get a
        # chance to run between resumes. With `after 0` the timer queue
        # stays continuously full, idle handlers starve, and the UI does
        # not paint until the coroutine completes.
        set LoaderAfterId [after 1 [info coroutine]]
        yield
        set LoaderAfterId ""
    }

    method loader_body {} {
        # Phase 1 — cheap classify per segment. classify_segment skips
        # the approach-YAML parse (#63 fast path) so first paint depends
        # only on roster + file-presence reads. SENT/REPLIED contacts
        # are reported as APPROACHED here; Phase 2 refines them via
        # State::refine_contact, which routes through the per-instance
        # approach_summary cache (#84).
        #
        # Track each segment's range in AllContacts so Phase 2 can enrich
        # in-place per segment and re-fire segment-loaded with corrected
        # right-column counts.
        set seg_paths $SegmentPathsForAsync
        set SegmentPathsForAsync {}
        set seg_ranges {}
        foreach item $seg_paths {
            lassign $item seg_name seg_dir is_active
            set start [llength $AllContacts]

            if {![catch {set classified [$State classify_segment $seg_dir]} err]} {
                if {$is_active} {
                    foreach c $classified { lappend AllContacts $c }
                }
                set cdict [spar::progress_counts $classified]
                # email_sent / email_replied are uniformly 0 in cheap mode
                # (no YAML parsed). Sentinel "" tells the progress table to
                # preserve the "…" placeholder until Phase 2 re-fires with
                # real counts. Without this, the right columns flash 0
                # at the same instant the left columns fill in.
                dict set cdict email_sent ""
                dict set cdict email_replied ""
                my _fire segment-loaded $seg_name $cdict $is_active
            }
            set end [llength $AllContacts]
            lappend seg_ranges [list $seg_name $seg_dir $is_active $start $end]
            my _yield_loop
        }

        # Partition tree-row TIDs by whether eligibility needs the YAML.
        # The numbering scheme assigns cheap TIDs to T1..T5 (T5 reserved)
        # and parse TIDs to T6+; the partition is the source of truth so
        # adding a TID requires placing it in the right range.
        set primary_channel [my _primary_channel]
        set cheap_tids {}
        set parse_tids {}
        foreach tid [spar::ui_transition_tids] {
            if {[string range $tid 1 end] < 5} {
                lappend cheap_tids $tid
            } else {
                lappend parse_tids $tid
            }
        }

        # Cheap-TID emit. Yielding between tids lets the tree render
        # each branch as it lands.
        set Transitions {}
        foreach tid $cheap_tids {
            set entry [my _transition_entry $tid $primary_channel]
            lappend Transitions $entry
            lassign $entry tlabel _ ttasks
            my _fire transition-loaded $tid $tlabel $ttasks
            my _yield_loop
        }

        # Phase 2 — per-segment enrichment. For each segment, refine the
        # cheap-classified contacts (parse the approach YAML for those
        # whose state warrants it) and overlay the refined fields, then
        # re-fire segment-loaded with the now-correct counts. Inactive
        # segments are classified+refined fresh (without joining
        # AllContacts) so their progress row gets accurate sent/repl.
        set i 0
        foreach range $seg_ranges {
            lassign $range seg_name seg_dir is_active start end
            if {$is_active} {
                for {set idx $start} {$idx < $end} {incr idx} {
                    set c [lindex $AllContacts $idx]
                    if {[dict get $c approach_path] ne ""} {
                        if {![catch {set refined [$State refine_contact $c]}]} {
                            lset AllContacts $idx $refined
                            set c $refined
                        }
                    }
                    my _fire contact-finalised [spar::dict_get_default $c stem ""]
                    incr i
                    if {($i % 25) == 0} { my _yield_loop }
                }
                set seg_contacts [lrange $AllContacts $start [expr {$end - 1}]]
            } else {
                if {[catch {set seg_contacts \
                        [$State refine_segment [$State classify_segment $seg_dir]]}]} {
                    continue
                }
            }
            set cdict [spar::progress_counts $seg_contacts]
            my _fire segment-loaded $seg_name $cdict $is_active
            my _yield_loop
        }
        if {($i % 25) != 0} { my _yield_loop }

        # Parse-TID emit. Eligibility for these TIDs reads email_sent /
        # linkedin_sent / email_replied populated by Phase 2.
        foreach tid $parse_tids {
            set entry [my _transition_entry $tid $primary_channel]
            lappend Transitions $entry
            lassign $entry tlabel _ ttasks
            my _fire transition-loaded $tid $tlabel $ttasks
            my _yield_loop
        }

        # Phase 3 — warnings.
        set Warnings [dict get [spar::build_warnings $AllContacts $Cdata] messages]
        my _yield_loop

        set FullLoadDone 1
        set LoaderCoro ""
        my _fire fully-loaded
    }
}
