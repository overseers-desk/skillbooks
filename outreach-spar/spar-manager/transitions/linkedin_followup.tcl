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

    # T8: LinkedIn was sent but email has not been; surface the contact as
    # pending (awaiting connection acceptance).  Skip EXCLUDED.  Gated on
    # approach-YAML structural validity (#43 principle 7).
    method eligible {contact primary_channel cdata today_iso} {
        set state [dict get $contact state]
        if {$state eq "EXCLUDED"} { return {} }
        if {![dict get $contact linkedin_sent]} { return {} }
        if {[dict get $contact email_sent]} { return {} }
        set vmsg [spar::_approach_validation_error $contact]
        if {$vmsg ne ""} {
            return [list [spar::_task $contact pending "invalid_approach_yaml: $vmsg"]]
        }
        return [list [spar::_task $contact pending \
            "LinkedIn sent, awaiting acceptance before email follow-up"]]
    }
}

::spar::transitions::register \
    -class ::spar::transitions::LinkedInFollowupTransition \
    -tid T8 \
    -label "LinkedIn → Email follow-up" \
    -auto-safe 0 \
    -dispatch-status not-implemented \
    -ui-tree-row 1
