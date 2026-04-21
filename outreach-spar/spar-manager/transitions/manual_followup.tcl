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
