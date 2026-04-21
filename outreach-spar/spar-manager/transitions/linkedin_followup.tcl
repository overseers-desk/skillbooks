# spar-manager/transitions/linkedin_followup.tcl
#
# LinkedInFollowupTransition — T8 (LinkedIn → Email follow-up). Not
# implemented: the state machine currently flags eligible contacts as
# `pending` (awaiting connection acceptance) and has no dispatcher. The
# base-class stub fires on_complete with a not-implemented message; the
# UI tree row is still shown so operators can see the count.

oo::class create ::spar::transitions::LinkedInFollowupTransition {
    superclass ::spar::transitions::Transition
    # run inherited from Transition — reports not-implemented
    # build_opts inherited — no extra opts
}

::spar::transitions::register \
    -class ::spar::transitions::LinkedInFollowupTransition \
    -tid T8 \
    -label "LinkedIn → Email follow-up" \
    -auto-safe 0 \
    -dispatch-status not-implemented \
    -ui-tree-row 1
