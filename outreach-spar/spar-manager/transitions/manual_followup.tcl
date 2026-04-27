# spar-manager/transitions/manual_followup.tcl
#
# ManualFollowupTransition — T9 (secondary follow-up) and T10 (tertiary
# follow-up). Both are manual: the UI exposes a render-script + mark-
# actioned button rather than spawning a harness. ui_tree_row=0 keeps
# them off the main transition tree (state-machine.md §Transition
# manager); they surface through the per-contact inspector.

oo::class create ::spar::transitions::ManualFollowupTransition {
    superclass ::spar::transitions::Transition
    # run inherited — reports dispatch_status=manual

    # T9 (slot=secondary) and T10 (slot=tertiary): contact is in
    # APPROACHED/SENT, campaign declares the relevant slot, and channel
    # readiness reports `<slot>_ready`.  Pending reasons that name the
    # missing preceding-channel send are suppressed — the operator already
    # sees those through T6/T7/T8 and does not need duplicate noise here.
    method eligible {state contact primary_channel cdata today_iso} {
        set cstate [dict get $contact state]
        if {$cstate eq "EXCLUDED"} { return {} }
        if {$cstate ne "APPROACHED" && $cstate ne "SENT"} { return {} }
        if {[llength $cdata] == 0} { return {} }
        set vmsg [$state approach_validation_error $contact]
        if {$vmsg ne ""} {
            return [list [spar::_task $contact pending "invalid_approach_yaml: $vmsg"]]
        }
        set r [$state channel_readiness $contact $cdata $today_iso]
        set slot [my param -slot]
        if {[dict get $r ${slot}_ready]} {
            return [list [spar::_task $contact ready ""]]
        }
        set reason [dict get $r ${slot}_reason]
        if {$reason eq ""} { return {} }
        if {[string match "preceding channel has no message*" $reason] \
            || [string match "no approach*" $reason] \
            || [string match "preceding channel not yet sent*" $reason]} {
            return {}
        }
        return [list [spar::_task $contact pending $reason]]
    }
}

::spar::transitions::register \
    -class ::spar::transitions::ManualFollowupTransition \
    -tid T9 \
    -label "Secondary follow-up" \
    -auto-safe 0 \
    -dispatch-status manual \
    -ui-tree-row 0 \
    -slot secondary

::spar::transitions::register \
    -class ::spar::transitions::ManualFollowupTransition \
    -tid T10 \
    -label "Tertiary follow-up" \
    -auto-safe 0 \
    -dispatch-status manual \
    -ui-tree-row 0 \
    -slot tertiary
