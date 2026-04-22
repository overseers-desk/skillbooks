#!/usr/bin/env tclsh9.0
# smtp_send.tcl — hand-rolled SES SMTP send over STARTTLS.
#
# Prints the bare SES tracking token from "250 Ok <token>" on stdout.
# Unlike tcllib smtp, this captures and returns that token.
#
# Written assuming SES: SES rewrites the RFC 822 Message-ID header on every
# send (both HTTPS and SMTP endpoints), so the token printed here is the
# SES-assigned id, not the one the client may have supplied.
#
# Usage: tclsh9.0 smtp_send.tcl <params_file>
# params_file must contain a Tcl dict with keys:
#   smtp_host  smtp_port  smtp_user  smtp_pass
#   from_email  from_name  to  cc  bcc  subject  body

package require base64
package require tls

proc b64 {s} {
    string map {"\n" "" "\r" "" " " ""} [base64::encode $s]
}

proc smtp_recv {sock expected} {
    set last ""
    while 1 {
        set line [gets $sock]
        set last $line
        if {[string length $line] < 4 || [string index $line 3] ne "-"} break
    }
    set code [string range $last 0 2]
    if {$code ne $expected} {
        error "SMTP $code (expected $expected): $last"
    }
    return $last
}

proc smtp_send_line {sock line} {
    puts $sock $line
    flush $sock
}

proc smtp_write_hdr {sock name val} {
    smtp_send_line $sock "${name}: ${val}"
}

proc smtp_run {params} {
    set host       [dict get $params smtp_host]
    set port       [dict get $params smtp_port]
    set user       [dict get $params smtp_user]
    set pass       [dict get $params smtp_pass]
    set from_email [dict get $params from_email]
    set from_name  [dict get $params from_name]
    set to         [dict get $params to]
    set cc         [dict get $params cc]
    set bcc        [dict get $params bcc]
    set subject    [dict get $params subject]
    set body       [dict get $params body]

    set from_hdr [expr {$from_name ne "" ? "$from_name <$from_email>" : $from_email}]

    set sock [socket $host $port]
    fconfigure $sock -blocking 1 -translation crlf -buffering full

    smtp_recv $sock 220

    smtp_send_line $sock "EHLO [info hostname]"
    smtp_recv $sock 250

    if {$port == 587 || $port == 2587} {
        smtp_send_line $sock "STARTTLS"
        smtp_recv $sock 220
        tls::import $sock -server 0 -servername $host
        fconfigure $sock -blocking 1 -translation crlf -buffering full
        smtp_send_line $sock "EHLO [info hostname]"
        smtp_recv $sock 250
    }

    smtp_send_line $sock "AUTH LOGIN"
    smtp_recv $sock 334
    smtp_send_line $sock [b64 $user]
    smtp_recv $sock 334
    smtp_send_line $sock [b64 $pass]
    smtp_recv $sock 235

    smtp_send_line $sock "MAIL FROM:<$from_email>"
    smtp_recv $sock 250
    smtp_send_line $sock "RCPT TO:<$to>"
    smtp_recv $sock 250
    if {$cc  ne ""} { smtp_send_line $sock "RCPT TO:<$cc>";  smtp_recv $sock 250 }
    if {$bcc ne ""} { smtp_send_line $sock "RCPT TO:<$bcc>"; smtp_recv $sock 250 }

    smtp_send_line $sock "DATA"
    smtp_recv $sock 354

    set date [clock format [clock seconds] -format "%a, %d %b %Y %H:%M:%S %z"]
    smtp_write_hdr $sock "Date"                      $date
    smtp_write_hdr $sock "From"                      $from_hdr
    smtp_write_hdr $sock "To"                        $to
    if {$cc ne ""}  { smtp_write_hdr $sock "Cc"      $cc }
    smtp_write_hdr $sock "Subject"                   $subject
    smtp_write_hdr $sock "MIME-Version"              "1.0"
    smtp_write_hdr $sock "Content-Type"              "text/plain; charset=utf-8"
    smtp_write_hdr $sock "Content-Transfer-Encoding" "8bit"
    smtp_send_line $sock ""

    foreach line [split $body "\n"] {
        set line [string trimright $line "\r"]
        if {[string index $line 0] eq "."} { set line ".$line" }
        smtp_send_line $sock $line
    }

    smtp_send_line $sock "."

    set response [smtp_recv $sock 250]

    smtp_send_line $sock "QUIT"
    catch {smtp_recv $sock 221}
    close $sock

    set mid "?"
    regexp {^250 Ok (\S+)} $response _ mid
    return $mid
}

# ── main ─────────────────────────────────────────────────────────────

if {$argc < 1} {
    puts stderr "usage: smtp_send.tcl <params_file>"
    exit 2
}

set params_file [lindex $argv 0]
if {[catch {
    set f [open $params_file r]
    set params [read $f]
    close $f
} err]} {
    puts stderr "smtp_send.tcl: cannot read params file: $err"
    exit 2
}

if {[catch {set mid [smtp_run $params]} err]} {
    puts stderr "smtp error: $err"
    exit 1
}

puts $mid
exit 0
