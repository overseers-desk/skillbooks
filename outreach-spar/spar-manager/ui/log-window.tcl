# spar-manager/ui/log-window.tcl
#
# spar::ui::LogWindow — owns the dispatch log toplevel and its state.
#
# Encapsulates the log line buffer, unread count, and the optional
# `.logwin` toplevel with its text widget. Consumers call `log`,
# `show`, `clear` as public methods; the unread badge can be driven
# by subscribing to the `unread-changed` event.
#
# LogToStderr is a constructor argument (mirror of a top-level flag
# parsed from argv) — stored for read but never written internally.
#
# Events fired:
#   unread-changed {count}
#       emitted whenever the unread count changes (incremented by
#       `log`, reset by `show` and `clear`). The toolbar "Log…"
#       button's badge subscribes to this.

package require Tk
package require TclOO

namespace eval spar::ui {}

oo::class create spar::ui::LogWindow {
    variable LogBuffer LogUnread LogToStderr
    variable Subs

    constructor {log_to_stderr} {
        set LogBuffer   {}
        set LogUnread   0
        set LogToStderr $log_to_stderr
        set Subs        [dict create]
    }

    # ─── Subscription ─────────────────────────────────────────────────────
    method subscribe {event cb} { dict lappend Subs $event $cb }

    method _fire {event args} {
        if {![dict exists $Subs $event]} return
        foreach cb [dict get $Subs $event] { {*}$cb {*}$args }
    }

    # ─── Accessors ────────────────────────────────────────────────────────
    method get_unread {} { return $LogUnread }

    # ─── Public entry points ──────────────────────────────────────────────

    # log — append a timestamped line to the buffer, mirror to stderr
    # if LogToStderr, append to the text widget if the window exists,
    # and bump the unread count. Public so it can be used directly as
    # an `after`/`-command` callback or a subscriber.
    method log {msg} {
        set ts [clock format [clock seconds] -format "%H:%M:%S"]
        set line "$ts $msg"
        if {$LogToStderr} {
            puts stderr $line
            flush stderr
        }
        lappend LogBuffer $line
        if {[winfo exists .logwin]} {
            .logwin.txt configure -state normal
            .logwin.txt insert end "$line\n"
            .logwin.txt see end
            .logwin.txt configure -state disabled
        }
        incr LogUnread
        my _fire unread-changed $LogUnread
    }

    # show — create the log toplevel if absent, populate it from the
    # buffer, and raise it. Resets the unread count. Public so it can
    # serve as `-command` for the toolbar button.
    method show {} {
        set LogUnread 0
        my _fire unread-changed $LogUnread
        if {[winfo exists .logwin]} {
            wm deiconify .logwin
            raise .logwin
            return
        }
        toplevel .logwin
        wm title .logwin "Dispatch Log"

        ttk::frame .logwin.bar
        pack .logwin.bar -fill x -padx 4 -pady {4 0}
        ttk::button .logwin.bar.clear -text "Clear" \
            -command [list [self] clear]
        pack .logwin.bar.clear -side right

        text .logwin.txt -wrap word -font "TkFixedFont 8" -state disabled
        ttk::scrollbar .logwin.sb -orient vertical -command {.logwin.txt yview}
        .logwin.txt configure -yscrollcommand {.logwin.sb set}

        pack .logwin.sb -side right -fill y -padx {0 4} -pady {0 4}
        pack .logwin.txt -fill both -expand 1 -padx {4 0} -pady {0 4}

        .logwin.txt configure -state normal
        foreach line $LogBuffer {
            .logwin.txt insert end "$line\n"
        }
        .logwin.txt see end
        .logwin.txt configure -state disabled

        wm protocol .logwin WM_DELETE_WINDOW {wm withdraw .logwin}
    }

    # clear — empty the buffer and, if the window exists, clear the
    # text widget. Also resets the unread count. Public so it can
    # serve as `-command` for the Clear button.
    method clear {} {
        set LogBuffer {}
        if {[winfo exists .logwin]} {
            .logwin.txt configure -state normal
            .logwin.txt delete 1.0 end
            .logwin.txt configure -state disabled
        }
        set LogUnread 0
        my _fire unread-changed $LogUnread
    }
}
