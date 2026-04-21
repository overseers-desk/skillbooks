# spar-manager/transitions/check_replies.tcl
#
# CheckRepliesTransition — T4 (Send → Reply). Delegates to
# ::spar::r::run, which queries the local mailroom CLI and appends any
# matched replies to the approach YAML. In commit 3 this `run` is
# rewritten as a Dispatcher client so the synchronous mailroom loop
# stops blocking the UI event loop; for now it matches commit-1
# behaviour.

oo::class create ::spar::transitions::CheckRepliesTransition {
    superclass ::spar::transitions::Transition

    method build_opts {tasks filter_segments filter_stems} {
        set segs [dict create]
        set stems {}
        foreach c $tasks {
            dict set segs [dict get $c _segment_dir] 1
            lappend stems [dict get $c stem]
        }
        set segments_list [dict keys $segs]
        return [dict create \
            segments $segments_list \
            stems $stems \
            log_message "[my tid]: [llength $tasks] task(s) across [llength $segments_list] segment(s) (reply-check pass)"]
    }

    method run {opts on_progress on_complete} {
        ::spar::r::run $opts $on_progress $on_complete
    }
}

::spar::transitions::register \
    -class ::spar::transitions::CheckRepliesTransition \
    -tid T4 \
    -label "Send → Reply" \
    -auto-safe 0 \
    -dispatch-status available \
    -ui-tree-row 1
