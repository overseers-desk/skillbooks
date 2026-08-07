# spar-control.tcl — TCP control socket for a running dispatch.
#
# Its own file rather than spar-transition.tcl script body so
# test/test-control.tcl can drive it against a stub dispatcher. The
# CLI sources this file, listens when dispatch begins, and keeps
# ::spar::control_dispatcher pointing at the live pool while one
# exists.
#
# Protocol: one text command per TCP connection to 127.0.0.1:<port>,
# one-line reply, connection closed. Verbs:
#   drain — cancel every queued row and launch nothing further; the
#           in-flight workers finish undisturbed, the run summarises
#           and exits, and an --auto loop starts no further pass.
#   jobs N — resize the --jobs cap. Raised, queued rows launch into
#           the freed slots at once; lowered, running rows finish
#           undisturbed and launches wait under the new cap. The value
#           outlives the pool it hit, so a later --auto pass builds
#           its pool at the resized cap.
#   setenv NAME=VALUE — set an environment variable in the dispatcher
#           process. Workers launched from then on inherit it; workers
#           already running keep the environment they started with.
#           The operator's case: half-way through a batch one Claude
#           account runs out, so `setenv CLAUDE_CONFIG_DIR=<other>`
#           points every subsequent `claude -p` at a different account
#           without stopping the run. The same NAME=VALUE form is
#           accepted on the CLI command line for the at-launch default.
# Operator commands:  echo drain | nc 127.0.0.1 <port>
#                     echo "jobs 20" | nc 127.0.0.1 <port>
#                     echo "setenv CLAUDE_CONFIG_DIR=$HOME/.claude-b" | nc 127.0.0.1 <port>
#
# The port is a per-process stop channel, not a lock: each dispatch
# gets its own so it can be stopped on its own. When the preferred
# port is taken (another dispatch already listening there, a leftover),
# the next free port up is used, and the chosen port is reported to the
# operator so they know where to send drain.
#
# The socket is TCP on loopback because core Tcl's [socket] speaks TCP
# only; a Unix-domain socket would need a compiled extension on every
# machine that runs spar.

namespace eval spar {
    variable control_draining 0
    variable control_dispatcher ""
    # The operator's latest `jobs N`, "" until one arrives. The live
    # pool is resized directly; this variable carries the value across
    # pool boundaries (an --auto pass builds its next pool from it).
    variable control_jobs_cap ""
}

# control_listen — open the listener on 127.0.0.1:$port and return the
# server channel. port 0 asks the OS for an ephemeral port (tests);
# read the assignment back from [chan configure $srv -sockname]. A
# busy port raises; the caller decides whether that is fatal.
proc spar::control_listen {port} {
    return [socket -server ::spar::_control_accept -myaddr 127.0.0.1 $port]
}

# control_listen_from — bind the first free port at or above $start,
# returning {chan port}. A busy port is stepped over, not fatal, so
# concurrent dispatches each get their own stop channel. Gives up after
# $tries ports and rethrows the last error (a persistent failure is a
# real fault, e.g. no loopback, not a contended port).
proc spar::control_listen_from {start {tries 64}} {
    for {set p $start} {$p < $start + $tries} {incr p} {
        if {![catch {spar::control_listen $p} srv]} {
            set bound [lindex [chan configure $srv -sockname] 2]
            return [list $srv $bound]
        }
    }
    return -code error "no free control port in $start..[expr {$start + $tries - 1}]: $srv"
}

proc spar::_control_accept {chan addr peer_port} {
    fconfigure $chan -blocking 0 -buffering line
    fileevent $chan readable [list ::spar::_control_read $chan]
}

proc spar::_control_read {chan} {
    set n [gets $chan line]
    if {$n < 0} {
        if {[eof $chan]} { catch {close $chan} }
        return
    }
    set line [string trim $line]
    if {$line eq "drain"} {
        set cancelled [spar::control_drain]
        catch {puts $chan "ok: draining ($cancelled queued row(s) cancelled)"}
    } elseif {[regexp {^jobs\s+([1-9][0-9]*)$} $line -> _n]} {
        catch {puts $chan "ok: [spar::control_set_jobs $_n]"}
    } elseif {[regexp {^setenv\s+([A-Za-z_][A-Za-z0-9_]*)=(.*)$} $line -> _name _val]} {
        set ::env($_name) $_val
        catch {puts $chan "ok: $_name set for workers launched from now on"}
    } else {
        catch {puts $chan "error: unknown command (try: drain | jobs N | setenv NAME=VALUE)"}
    }
    catch {close $chan}
}

# control_set_jobs — resize the live pool's cap and record the value
# for the pools that follow it, returning the reply body. With no pool
# live (between --auto passes) the record alone is the whole act.
proc spar::control_set_jobs {n} {
    variable control_dispatcher
    variable control_jobs_cap
    set control_jobs_cap $n
    if {$control_dispatcher ne ""} {
        set was [$control_dispatcher jobs_cap]
        $control_dispatcher set_jobs_cap $n
        return "jobs cap $n (was $was)"
    }
    return "jobs cap $n (no live pool — applies from the next pass)"
}

# control_drain — flip the drain flag and cancel every queued job in
# the live pool, returning how many were cancelled. The cancellations
# flow through the pool's normal job-state events, so the dispatch
# loop's completion accounting needs no adjustment. Idempotent, and
# callable with no pool live (drain between --auto passes).
proc spar::control_drain {} {
    variable control_draining
    variable control_dispatcher
    set control_draining 1
    set cancelled 0
    if {$control_dispatcher ne ""} {
        foreach job [$control_dispatcher queued_jobs] {
            $control_dispatcher cancel $job
            incr cancelled
        }
    }
    return $cancelled
}
