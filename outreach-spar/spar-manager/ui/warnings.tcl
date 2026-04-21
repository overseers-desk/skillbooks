# spar-manager/ui/warnings.tcl
#
# ::spar::ui::warnings — the campaign-panel warnings zone.
#
# Namespace module, not a class. The warnings zone's state is barely
# beyond trivial: an expanded/collapsed flag, a cached summary string,
# the frame widget path, and a back-reference to the CampaignModel.
# A TclOO class would be ceremony without payoff.
#
# Consumers call `init` once at startup with the CampaignModel and the
# parent frame. The module builds the widget tree and subscribes to the
# model's `refreshed` and `fully-loaded` events so it rebuilds itself
# when the underlying warnings list changes.

package require Tk

namespace eval ::spar::ui::warnings {
    variable Expanded 0
    variable Summary  ""
    variable Frame    ""
    variable Campaign ""

    # init — build the warnings widget tree inside $parent_frame and
    # subscribe to the CampaignModel's refresh-lifecycle events.
    proc init {campaign parent_frame} {
        variable Expanded
        variable Summary
        variable Frame
        variable Campaign

        set Campaign $campaign
        set Expanded 0

        ttk::frame ${parent_frame}.warnings
        pack ${parent_frame}.warnings -fill x -padx 8 -pady {2 4}
        set Frame ${parent_frame}.warnings

        set Summary [compute_summary]

        set warnings [$Campaign get_warnings]
        ttk::button ${Frame}.toggle \
            -text "▸ ⚠ [llength $warnings] warnings ($Summary)" \
            -command ::spar::ui::warnings::toggle -style Toolbutton
        pack ${Frame}.toggle -fill x -anchor w

        text ${Frame}.txt -height 5 -wrap word -font "TkDefaultFont 8" \
            -state disabled -background "#fff8e1" -relief flat

        populate_text

        $Campaign subscribe refreshed    ::spar::ui::warnings::rebuild
        $Campaign subscribe fully-loaded ::spar::ui::warnings::rebuild
    }

    # compute_summary — bucket the warnings list into duplicate-email /
    # duplicate-name / identical-subject / other and return a short
    # "N duplicate email, M duplicate name, …" string.
    proc compute_summary {} {
        variable Campaign
        set warnings [$Campaign get_warnings]
        set warn_dup_email 0
        set warn_dup_name 0
        set warn_dup_subject 0
        set warn_other 0
        foreach w $warnings {
            if {[string match "*Duplicate To:*" $w] || [string match "*Duplicate email:*" $w]} {
                incr warn_dup_email
            } elseif {[string match "*Duplicate name:*" $w]} {
                incr warn_dup_name
            } elseif {[string match "*Identical subject:*" $w]} {
                incr warn_dup_subject
            } else {
                incr warn_other
            }
        }
        set parts {}
        if {$warn_dup_email   > 0} { lappend parts "${warn_dup_email} duplicate email" }
        if {$warn_dup_name    > 0} { lappend parts "${warn_dup_name} duplicate name" }
        if {$warn_dup_subject > 0} { lappend parts "${warn_dup_subject} identical subject" }
        if {$warn_other       > 0} { lappend parts "${warn_other} other" }
        return [join $parts ", "]
    }

    # populate_text — rewrite the bullet-list text widget from the
    # current warnings.
    proc populate_text {} {
        variable Frame
        variable Campaign
        set warnings [$Campaign get_warnings]
        ${Frame}.txt tag configure bold -font "TkDefaultFont 8 bold"
        ${Frame}.txt configure -state normal
        ${Frame}.txt delete 1.0 end
        foreach w $warnings {
            set colon [string first ":" $w]
            if {$colon >= 0} {
                ${Frame}.txt insert end "• " {} \
                    [string range $w 0 $colon] bold \
                    [string range $w [expr {$colon+1}] end] {}
            } else {
                ${Frame}.txt insert end "• $w"
            }
            ${Frame}.txt insert end "\n"
        }
        ${Frame}.txt configure -state disabled
    }

    # toggle — show/hide the text widget and flip the toggle arrow glyph.
    proc toggle {} {
        variable Expanded
        variable Frame
        variable Summary
        variable Campaign
        set warnings [$Campaign get_warnings]
        if {$Expanded} {
            pack forget ${Frame}.txt
            ${Frame}.toggle configure \
                -text "▸ ⚠ [llength $warnings] warnings ($Summary)"
            set Expanded 0
        } else {
            pack ${Frame}.txt -fill x -padx 4 -pady 2
            ${Frame}.toggle configure \
                -text "▾ ⚠ [llength $warnings] warnings ($Summary)"
            set Expanded 1
        }
    }

    # rebuild — recompute summary, repopulate text, refresh the toggle
    # button's count/summary. Subscribes to the Campaign's refreshed and
    # fully-loaded events; the arrow glyph reflects the current Expanded
    # state so toggling state is preserved across refreshes.
    proc rebuild {} {
        variable Expanded
        variable Frame
        variable Summary
        variable Campaign
        set Summary [compute_summary]
        populate_text
        set warnings [$Campaign get_warnings]
        set arrow [expr {$Expanded ? "▾" : "▸"}]
        ${Frame}.toggle configure \
            -text "$arrow ⚠ [llength $warnings] warnings ($Summary)"
    }
}
