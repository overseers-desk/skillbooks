# spar-transition-cli.tcl — argv parser for spar-transition.tcl.
#
# Lifted out of the script body so test/test-cli-parser.tcl can drive
# the grammar in isolation. The script sources this file, calls
# spar::parse_cli $argv, and either dispatches the resulting spec dict
# or exits with the error.
#
# Grammar:
#
#   <campaign.yaml>                    positional, required (filesystem
#                                      checks deferred to the script layer)
#   Tn                                 all rows of TID Tn, campaign-wide
#   Tn:<segment>                       Tn restricted to one segment
#   Tn:<segment>/<stem>                Tn for one specific contact
#   --dry-run                          dispatch path with writes disabled
#   --jobs=N | --delay=N | --limit=N | --yes
#   --control-port=N                   control socket (0 disables)
#   --auto                             refuses any positional Tn token
#   --dispatchable | --awaiting | --blocked   report mode filter
#   -v | --verbose
#   -h | --help
#
# The deleted flags --tid=, --segment=, --stem= produce a one-line
# error pointing at the new positional grammar. There is no back-compat
# shim — anyone with shell history hits the hint.

namespace eval spar {}

# parse_cli — return {ok 1 spec <dict>} on success, {ok 0 error <msg>}
# on parse failure. Does not exit; the caller decides how to surface
# the error (script exits, test reports a failure).
#
# spec keys:
#   campaign_path  raw positional (file or dir, or "" if unspecified)
#   tid_scopes     list of {tid segment stem} triples; empty == "all"
#   filter_state   "" | "dispatchable" | "awaiting" | "blocked"
#   auto_mode      0/1   (--auto)
#   dry_run        0/1   (--dry-run; gates the dispatch path)
#   jobs           int   (default 4; 0 means stepping)
#   delay          int   (default 2)
#   limit          int   (default 0; 0 means no row cap)
#   control_port   int   (default 25519; 0 means no control socket)
#   assume_yes     0/1
#   verbose        0/1
#   help           0/1   (--help requested)
proc spar::parse_cli {argv} {
    set spec [dict create \
        campaign_path ""   \
        tid_scopes    {}   \
        filter_state  ""   \
        auto_mode     0    \
        dry_run       0    \
        jobs          4    \
        delay         2    \
        limit         0    \
        control_port  25519 \
        assume_yes    0    \
        verbose       0    \
        help          0]

    # Track whether any Tn token was supplied (needed for the
    # "--auto + Tn is forbidden" check, which mirrors the historical
    # "--auto + --tid=" check).
    set saw_positional_tid 0
    set saw_auto 0

    foreach arg $argv {
        switch -glob -- $arg {
            -h          -
            --help      { dict set spec help 1 }
            --jobs=*    { dict set spec jobs   [string range $arg 7 end] }
            --delay=*   { dict set spec delay  [string range $arg 8 end] }
            --limit=*   { dict set spec limit  [string range $arg 8 end] }
            --control-port=* {
                dict set spec control_port [string range $arg 15 end]
            }
            --yes       { dict set spec assume_yes 1 }
            --dispatchable { dict set spec filter_state dispatchable }
            --awaiting     { dict set spec filter_state awaiting }
            --blocked      { dict set spec filter_state blocked }
            --auto      { dict set spec auto_mode 1; set saw_auto 1 }
            --dry-run   { dict set spec dry_run 1 }
            -v          -
            --verbose   { dict set spec verbose 1 }
            --tid=*     {
                return [dict create ok 0 error \
                    {--tid=Tn was replaced by positional Tn (or Tn:seg, Tn:seg/stem). See --help.}]
            }
            --segment=* {
                return [dict create ok 0 error \
                    {--segment=NAME was replaced by positional Tn:seg. See --help.}]
            }
            --stem=*    {
                return [dict create ok 0 error \
                    {--stem=STEM was replaced by positional Tn:seg/stem. See --help.}]
            }
            --*         {
                return [dict create ok 0 error \
                    "Unknown flag: $arg (try --help)"]
            }
            default     {
                # Either a Tn[:seg[/stem]] token or the campaign
                # path. Prefix `Tn` decides which path: any token
                # starting with T followed by digits is a transition
                # token.
                if {[regexp {^T[0-9]+} $arg]} {
                    if {[regexp {^(T[0-9]+)$} $arg -> tid]} {
                        set seg ""
                        set stem ""
                    } elseif {[regexp {^(T[0-9]+):([^/]+)$} $arg \
                                  -> tid seg]} {
                        set stem ""
                    } elseif {[regexp {^(T[0-9]+):([^/]+)/(.+)$} $arg \
                                  -> tid seg stem]} {
                        # all three captured
                    } elseif {[regexp {^(T[0-9]+):/} $arg]} {
                        return [dict create ok 0 error \
                            "stem requires segment in $arg"]
                    } else {
                        return [dict create ok 0 error \
                            "malformed transition token: $arg"]
                    }
                    if {![spar::_tid_known $tid]} {
                        return [dict create ok 0 error \
                            "unknown transition: $tid (try --help)"]
                    }
                    set saw_positional_tid 1
                    dict lappend spec tid_scopes [list $tid $seg $stem]
                } else {
                    # Campaign path positional. Captured verbatim;
                    # the script layer enforces "yaml file that exists".
                    # parse_cli stays filesystem-pure so tests run
                    # without temp YAMLs.
                    if {[dict get $spec campaign_path] ne ""} {
                        return [dict create ok 0 error \
                            "only one campaign path may be supplied"]
                    }
                    dict set spec campaign_path $arg
                }
            }
        }
    }

    if {$saw_auto && $saw_positional_tid} {
        return [dict create ok 0 error \
            "--auto excludes positional Tn tokens — drop one"]
    }

    return [dict create ok 1 spec $spec]
}

# _tid_known — predicate for the registry. Defined as a separate proc
# so tests can stub it if they want to exercise parse_cli without
# loading the full transition registry; production callers source
# spar-state.tcl first which registers all T-ids at load time.
proc spar::_tid_known {tid} {
    if {[catch {::spar::transitions::all} all]} {
        return 0
    }
    return [expr {$tid in $all}]
}
