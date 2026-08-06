#!/usr/bin/env tclsh9.0
# spar-overseer-health.tcl — probe the overseer's /health and say which of
# four states it is in, each with its own exit code, so callers never parse
# health JSON ad hoc (a hand-rolled probe once conflated a parse error with
# "not answering" and misdiagnosed a healthy overseer):
#   0 healthy    (ok true, no current fault)
#   1 faulted    (answers, but carries a current fault or ok false)
#   2 unreachable (transport: nothing listening, timeout, refused)
#   3 malformed  (answers, but the body is not health-shaped JSON)
# The raw body always prints, so a schema change is visible instead of being
# re-summarised by the probe's own assumptions.
# Port: BI_OVERSEER_PORT or 11402, the same default as the send leg.

package require http
package require json

set port [expr {[info exists env(BI_OVERSEER_PORT)] ? $env(BI_OVERSEER_PORT) : 11402}]
set url "http://127.0.0.1:$port/health"

if {[catch {
    set tok [http::geturl $url -timeout 8000]
    set status [http::status $tok]
    set body [http::data $tok]
    http::cleanup $tok
} err]} {
    puts "unreachable: $err"
    exit 2
}
if {$status ne "ok"} {
    puts "unreachable: transport status '$status'"
    exit 2
}

puts $body
if {[catch {set h [json::json2dict $body]} err]} {
    puts "malformed: $err"
    exit 3
}
if {![dict exists $h ok]} {
    puts "malformed: no 'ok' field"
    exit 3
}

# fault is null when clean, a dict when sticky; both shapes are legal.
set fault [dict getdef $h fault ""]
set faulted [expr {$fault ni {"" null} && [dict getdef $fault current 0]}]
if {[dict get $h ok] && !$faulted} {
    puts "healthy: gate [dict getdef [dict getdef $h gates {}] linkedin.com {}]"
    exit 0
}
puts "faulted: [expr {$fault in {{} null} ? {ok false} : [dict getdef $fault detail $fault]}]"
exit 1
