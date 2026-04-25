# spar-dispatcher.tcl — Async queue of child harness processes used by
# the SPAR-P and SPAR-A phase runners (and any future phase runner that
# drives a harness — see SmartLayer/aesop#35).
#
# Idempotent: oo::class create is not idempotent, so guard against
# multiple sources. The spar-dispatch.tcl entry point already guards
# itself, so this is belt-and-braces for direct callers.

package require TclOO

if {[info exists ::spar::_dispatcher_loaded]} {
    package provide spar-dispatcher 1.0
    return
}

namespace eval spar {
    variable _dispatcher_loaded 1
    # Registry of live Dispatcher instances. Populated by the
    # constructor, drained by the destructor. UI layer walks this to
    # pause/resume/cancel every in-flight dispatch — a single segment
    # run spawns one Dispatcher, a multi-segment P-phase run spawns
    # several in parallel.
    if {![info exists live_dispatchers]} {
        variable live_dispatchers [list]
    }
}

# spar::Dispatcher — async queue of child harness processes.
#
# Takes a list of prompt_dirs and runs up to Jobs concurrent
# `tclsh HarnessPath <prompt_dir> LogsDir` children. Each line of a
# child's stdout is forwarded as an OnProgress "started" message; pipe
# close determines done/failed. When the queue drains and no children
# are active, OnComplete is called with {done failed result}, after
# which the object destroys itself.

oo::class create spar::Dispatcher {
    variable Queue QueueIdx Active Completed Failed
    variable Jobs LogsDir HarnessPath OnProgress OnComplete Result
    variable Paused
    variable Tid StepCallback

    constructor {jobs logs_dir harness_path on_progress on_complete result \
                 {tid ""} {step_callback ""}} {
        set Jobs $jobs
        set LogsDir $logs_dir
        set HarnessPath $harness_path
        set OnProgress $on_progress
        set OnComplete $on_complete
        set Result $result
        set Tid $tid
        set StepCallback $step_callback
        set Queue {}
        set QueueIdx 0
        set Active 0
        set Completed 0
        set Failed 0
        set Paused 0
        lappend ::spar::live_dispatchers [self]
    }

    destructor {
        set idx [lsearch -exact $::spar::live_dispatchers [self]]
        if {$idx >= 0} {
            set ::spar::live_dispatchers \
                [lreplace $::spar::live_dispatchers $idx $idx]
        }
    }

    method pause {}  { set Paused 1 }
    method resume {} { set Paused 0; my start_next }

    method cancel {} {
        while {$QueueIdx < [llength $Queue]} {
            set pdir [lindex $Queue $QueueIdx]
            incr QueueIdx
            {*}$OnProgress [file tail $pdir] skipped "cancelled"
        }
        set Paused 0
        my start_next
    }

    method run {prompt_dirs} {
        set Queue $prompt_dirs
        my start_next
    }

    # start_next and on_harness_output are dispatched externally (from
    # fileevent, and via the [self] command from the start_next tail) so
    # they cannot use a leading-underscore private naming convention —
    # TclOO would not export them.
    method start_next {} {
        if {!$Paused} {
        while {$QueueIdx < [llength $Queue] && $Active < $Jobs} {
            set pdir [lindex $Queue $QueueIdx]
            incr QueueIdx
            set slug [file tail $pdir]

            if {$StepCallback ne ""} {
                set verdict [{*}$StepCallback $Tid $slug \
                    $QueueIdx [llength $Queue]]
                if {$verdict eq "abort"} {
                    {*}$OnProgress $slug skipped "aborted"
                    while {$QueueIdx < [llength $Queue]} {
                        set next_pdir [lindex $Queue $QueueIdx]
                        incr QueueIdx
                        {*}$OnProgress [file tail $next_pdir] skipped "aborted"
                    }
                    break
                }
            }

            {*}$OnProgress $slug started ""

            set cmd [list tclsh9.0 $HarnessPath $pdir $LogsDir]
            if {[catch {open "| $cmd 2>@1" r} pipe]} {
                {*}$OnProgress $slug failed "could not start harness: $pipe"
                incr Failed
                continue
            }
            fconfigure $pipe -blocking 0 -buffering line
            fileevent $pipe readable [list [self] on_harness_output $pipe $slug]
            incr Active
        }
        }

        if {$Active == 0 && $QueueIdx >= [llength $Queue]} {
            set cb $OnComplete
            set done $Completed
            set fail $Failed
            set result $Result
            [self] destroy
            {*}$cb $done $fail $result
        }
    }

    method on_harness_output {pipe slug} {
        if {[gets $pipe line] >= 0} {
            # Children emit ROSTER_UPDATE marker lines (tab-separated) to
            # request TSV mutations. The dispatcher applies them serially
            # from its single event loop — that is the synchronisation that
            # replaces the per-harness flock. Non-marker lines are forwarded
            # as ordinary progress.
            if {[string match "ROSTER_UPDATE\t*" $line]} {
                my handle_roster_update $slug $line
            } else {
                {*}$OnProgress $slug started $line
            }
            return
        }
        if {[eof $pipe]} {
            if {[catch {close $pipe} err]} {
                {*}$OnProgress $slug failed $err
                incr Failed
            } else {
                {*}$OnProgress $slug done ""
                incr Completed
            }
            incr Active -1
            my start_next
        }
    }

    # Parse ROSTER_UPDATE<TAB>roster_path<TAB>key_col<TAB>key_val<TAB>field<TAB>new_val
    # and apply via spar::update_roster_field. Failure is non-fatal: emit a
    # warning progress event and carry on.
    method handle_roster_update {slug line} {
        set parts [split $line \t]
        if {[llength $parts] != 6} {
            {*}$OnProgress $slug warning "malformed ROSTER_UPDATE (expected 6 fields, got [llength $parts])"
            return
        }
        lassign $parts _ roster_path key_col key_val field new_val
        if {[catch {
            spar::update_roster_field $roster_path $key_col $key_val $field $new_val
        } err]} {
            {*}$OnProgress $slug warning "roster update failed ($key_col=$key_val $field=$new_val): $err"
            return
        }
        {*}$OnProgress $slug started "roster: $key_col=$key_val $field=$new_val"
    }
}

proc spar::_for_live {verb} {
    variable live_dispatchers
    foreach d $live_dispatchers {
        if {[info object isa object $d]} { $d $verb }
    }
}
proc spar::pause_all  {} { spar::_for_live pause }
proc spar::resume_all {} { spar::_for_live resume }
proc spar::cancel_all {} { spar::_for_live cancel }

package provide spar-dispatcher 1.0
