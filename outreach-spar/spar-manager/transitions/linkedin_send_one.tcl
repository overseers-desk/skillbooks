# spar-manager/transitions/linkedin_send_one.tcl
#
# spar::li::send_one — per-row LinkedIn send through the overseer's
# POST /run (contract: docs/ducks-protocol.md in the Matter repository,
# the runner's design home). The overseer owns the logged-in browser, the profile
# lock, and the linkedin.com rate gate; this helper asks it to run one
# send primitive and interprets the primitive's result. Fail-fast rule:
# GET /health is probed first, and an absent or unhealthy overseer is
# an error, never a silent skip. No pacing here — cadence is the
# overseer's; the probe reads that cadence back so a parked row can say
# what it waits on (health_note).
#
# Inputs (opts dict):
#   approach_path  abs path to the approach YAML for this row
#   linkedin_url   the contact's roster linkedin_url (vanity source)
#   dry_run        1 = validate and report without calling the overseer
#   overseer_url   optional override; default http://127.0.0.1:11402
#   today          optional ISO date for stamp; default = today
#   note_cmd       optional cmdprefix, called with one line of text when
#                  the probe finds something standing in this send's way
#                  (a rate gate, an open breaker, an account not signed
#                  in). The dispatcher passes the pool's phase verb, so
#                  the row says what it is waiting on.
#
# Skill selection: the final linkedin message's `mode` key picks the
# primitive (invite → linkedin.com/send-invite, dm →
# linkedin.com/send-message). Absent mode falls back to invite when the
# text fits LinkedIn's 300-char connection-note limit, else dm.
#
# Returns one of:
#   {ok sent}        — the primitive confirmed the send; actioned_date
#                      stamped on the linkedin message
#   {ok "<mode>, <N> chars"} — dry run: validated only, nothing sent,
#                      nothing stamped; detail names the mode and the
#                      message length (e.g. "invite, 264 chars")
#   {error <reason>} — probe/read/build/run failure, or a primitive
#                      status of error/failed/uncertain. uncertain is
#                      never stamped: the human checks LinkedIn.

package require http
package require json
package require json::write

namespace eval ::spar::li {
    variable default_overseer "http://127.0.0.1:11402"
}

# One JSON POST to the overseer; returns the parsed response dict.
# Timeout is generous: a /run holds through the browser pool queue and
# the linkedin.com rate gate before the primitive even launches.
proc ::spar::li::_post_json {url body timeout_ms} {
    set tok [spar::pool_http $url -method POST -type application/json \
        -query $body -timeout $timeout_ms]
    try {
        if {[http::status $tok] ne "ok"} {
            error "overseer unreachable: [http::status $tok] [http::error $tok]"
        }
        if {[http::ncode $tok] != 200} {
            error "overseer HTTP [http::ncode $tok]: [string range [http::data $tok] 0 200]"
        }
        return [json::json2dict [http::data $tok]]
    } finally {
        http::cleanup $tok
    }
}

# GET /health, erroring unless it answers ok:true. A refusal names the
# overseer's own fault detail when it reported one, so the row says what
# is wrong rather than only that something is.
proc ::spar::li::_health {overseer} {
    set tok [spar::pool_http "$overseer/health" -timeout 5000]
    try {
        if {[http::status $tok] ne "ok" || [http::ncode $tok] != 200} {
            error "health probe failed"
        }
        set h [json::json2dict [http::data $tok]]
        if {![dict getdef $h ok 0]} {
            error "overseer reports not ok[::spar::li::_fault_suffix $h]"
        }
        return $h
    } finally {
        http::cleanup $tok
    }
}

# ": <detail>" from a health or /run document's fault object, or "" when
# it carries none. fault is null (json2dict yields the string) when clear,
# so the shape is checked before it is read as a dict.
proc ::spar::li::_fault_suffix {doc} {
    set f [dict getdef $doc fault ""]
    if {$f in {"" null}} { return "" }
    set detail ""
    catch {set detail [dict get $f detail]}
    return [expr {$detail ne "" ? ": $detail" : ""}]
}

# What /health says stands between this send and the browser, as one
# phrase, or "" when the way is clear. The document is the one _health
# already fetched, so this costs no extra round trip.
#
#   gates    host -> {opensIn_s, interval_s}: the seconds until that
#            host's rate gate frees, beside the interval it counts from
#   lanes    lane -> {since count detail}, an open circuit breaker; a
#            send's lane is its skill ref
#   holds    host -> identity -> {...}, an account declined until someone
#            signs it in again
#
# Every key is read by host or by lane, so a platform added later reads
# out of the same document with no change here.
proc ::spar::li::health_note {h host {lane ""}} {
    set parts {}
    # The gate names its unit in the key: take the countdown, not the
    # interval standing beside it. Guarded, so a document shaped another
    # way cannot throw in a send's path.
    set secs 0
    catch {set secs [dict get $h gates $host opensIn_s]}
    if {[string is integer -strict $secs] && $secs > 0} {
        lappend parts "$host gate ${secs}s"
    }
    if {$lane ne ""} {
        set trip [dict getdef $h lanes $lane ""]
        if {$trip ne ""} {
            lappend parts "lane tripped after [dict getdef $trip count "repeated"] failures"
        }
    }
    set held [dict keys [dict getdef $h holds $host ""]]
    if {[llength $held]} {
        lappend parts "account not signed in: [join $held {, }]"
    }
    return [join $parts "; "]
}

proc ::spar::li::send_one {opts} {
    variable default_overseer
    set approach_path [dict get $opts approach_path]
    set linkedin_url  [string trim [dict getdef $opts linkedin_url ""]]
    set dry_run       [dict getdef $opts dry_run 0]
    set overseer      [dict getdef $opts overseer_url $default_overseer]
    set today         [dict getdef $opts today \
        [clock format [clock seconds] -format "%Y-%m-%d"]]
    set note_cmd      [dict getdef $opts note_cmd ""]

    if {![file exists $approach_path]} {
        return [list error "approach file missing: $approach_path"]
    }
    set approach_data [spar::read_approach_yaml $approach_path]
    if {$approach_data eq ""} {
        return [list error "approach read error: $approach_path"]
    }
    set msg [spar::final_channel_message $approach_data linkedin]
    if {$msg eq ""} {
        return [list error "no linkedin message in final round"]
    }
    set text [string trim [dict getdef $msg text ""]]
    if {$text eq ""} { set text [string trim [dict getdef $msg body ""]] }
    if {$text eq ""} {
        return [list error "linkedin message has no text"]
    }

    # Vanity slug from the roster URL (linkedin.com/in/<vanity>).
    if {![regexp {linkedin\.com/in/([^/?#]+)} $linkedin_url -> vanity]} {
        return [list error "cannot extract vanity name from linkedin_url: '$linkedin_url'"]
    }

    # invite vs dm: the draft's mode key decides; absent, a text within
    # the 300-char note limit reads as a connection invite.
    set mode [dict getdef $msg mode ""]
    if {$mode eq ""} {
        set mode [expr {[string length $text] <= 300 ? "invite" : "dm"}]
    }
    switch -- $mode {
        invite  { set skill_ref "linkedin.com/send-invite" }
        dm      { set skill_ref "linkedin.com/send-message" }
        default { return [list error "unknown linkedin message mode '$mode' (expect invite|dm)"] }
    }
    if {$mode eq "invite" && [string length $text] > 300} {
        return [list error "invite note is [string length $text] chars; LinkedIn limit is 300"]
    }

    if {$dry_run} {
        return [list ok "$mode, [string length $text] chars"]
    }

    # Fail-fast probe: the overseer must be present and healthy.
    if {[catch {set health [::spar::li::_health $overseer]} err]} {
        return [list error "overseer not available at $overseer — start it before T6 linkedin sends ($err)"]
    }

    # A /run parks server-side behind the rate gate, an open breaker or a
    # held account, so the row would otherwise sit silent for as long as
    # the wait lasts. The probe already knows why; report it through the
    # caller's note cmdprefix, and keep it for the failure text.
    set note [::spar::li::health_note $health \
        [lindex [split $skill_ref /] 0] $skill_ref]
    if {$note ne "" && $note_cmd ne ""} {
        catch {{*}$note_cmd $note}
    }
    set at_probe [expr {$note ne "" ? " (at probe: $note)" : ""}]

    set args_json [json::write array \
        [json::write string $vanity] \
        [json::write string $text]]
    set body [json::write object \
        skillRef [json::write string $skill_ref] \
        argsJson [json::write string $args_json]]

    if {[catch {
        set resp [::spar::li::_post_json "$overseer/run" $body 600000]
    } err]} {
        return [list error "overseer /run failed: $err$at_probe"]
    }

    # Outer fault: the browser or the primitive failed to run at all.
    if {[dict exists $resp fault] && [dict get $resp fault] ni {null ""}} {
        set f [dict get $resp fault]
        set shape ""; set detail ""
        catch {set shape [dict get $f shape]}
        catch {set detail [dict get $f detail]}
        return [list error "overseer fault ($shape): $detail$at_probe"]
    }
    set inner [dict getdef $resp result ""]
    if {$inner in {"" null}} {
        return [list error "overseer returned no result"]
    }
    if {[catch {set r [json::json2dict $inner]} err]} {
        return [list error "unparseable primitive result: [string range $inner 0 200]"]
    }
    set status [dict getdef $r status ""]
    switch -- $status {
        sent {
            if {[catch {set stamped [spar::stamp_actioned_date $approach_path $today linkedin]} serr]} {
                return [list error "sent ok but stamp failed: $serr"]
            }
            # A confirmed send that stamps nothing leaves the file reading
            # as unsent — the contact would be re-dispatched (issue #160).
            # The send DID go out; surface it as a FAIL naming the file.
            if {!$stamped} {
                return [list error "sent ok but stamp made no change: $approach_path"]
            }
            return [list ok sent]
        }
        default {
            set reason [dict getdef $r reason ""]
            if {$reason eq ""} { set reason $status }
            return [list error "primitive status '$status': $reason$at_probe"]
        }
    }
}

package provide spar-li-send-one 1.0
