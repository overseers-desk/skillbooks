#!/usr/bin/env tclsh9.0
# spar-email.tcl — Shared helpers for the email send/reply-check transitions.
#
# The SES integration lives in transitions/send_email.tcl and the inbox
# integration lives in transitions/check_replies.tcl. This file keeps only
# pure helpers that both classes (and the CLI/tests) need: email-address
# extraction, HTML-to-text cleanup, reply-fingerprint matching, approach
# YAML reply append, sent-approach collection, and the actioned_date stamp.

source [file join [file dirname [file normalize [info script]]] spar-lib.tcl]

namespace eval spar {
    namespace export stamp_actioned_date collect_sent_approaches
}

# ── Helpers (not exported) ─────────────────────────────────────────────

# extract_email_address -- extract bare email from "Name <email>" or bare email.
proc spar::extract_email_address {header} {
    if {[regexp {<([^>]+)>} $header -> addr]} {
        return [string tolower $addr]
    }
    return [string tolower [string trim $header]]
}

# html_to_text -- strip HTML to plain text, skipping blockquote content.
# Truncates at forwarded-message markers.
proc spar::html_to_text {body} {
    set text $body

    # Remove blockquote content (including nested), replacing with newline
    # Repeatedly strip innermost blockquotes until none remain
    while {[regexp -nocase {<blockquote[^>]*>.*?</blockquote>} $text]} {
        regsub -all -nocase {<blockquote[^>]*>.*?</blockquote>} $text "\n" text
    }

    # Replace <br>, <br/>, <br /> with newlines
    regsub -all -nocase {<br\s*/?>} $text "\n" text

    # Replace block-level tags with newlines
    regsub -all -nocase {<(?:div|p|tr|li)[^>]*>} $text "\n" text

    # Strip all remaining HTML tags
    regsub -all {<[^>]+>} $text {} text

    # Unescape HTML entities AFTER tag stripping so decoded < > are not
    # mistaken for tags
    set text [string map {
        &amp;   &
        &lt;    <
        &gt;    >
        &quot;  \"
        &apos;  '
        &#39;   '
        &nbsp;  " "
    } $text]

    # Trim at forwarded-original markers and quoted text
    set lines [split $text \n]
    set clean {}
    foreach line $lines {
        if {[regexp {^From:\s} $line]} break
        if {[regexp {^-{5,}.*Original Message} $line]} break
        if {[regexp {^>\s} $line]} break
        lappend clean $line
    }
    set text [join $clean \n]

    # Collapse runs of 3+ newlines to 2
    regsub -all {\n{3,}} $text "\n\n" text

    return [string trim $text]
}

# fingerprint_match -- check if a reply is already recorded.
# existing: list of "from_email|timestamp" strings
# from_email: sender email (lowercase)
# timestamp: message timestamp string
proc spar::fingerprint_match {existing from_email timestamp} {
    set candidate "${from_email}|${timestamp}"
    if {$candidate in $existing} {
        return 1
    }
    # Legacy: existing entry may be date-only (first 10 chars)
    set date_only "${from_email}|[string range $timestamp 0 9]"
    if {$date_only in $existing} {
        return 1
    }
    # Legacy: existing entry may have empty from_addr
    if {$from_email ne ""} {
        if {"|${timestamp}" in $existing} {
            return 1
        }
        if {"|[string range $timestamp 0 9]" in $existing} {
            return 1
        }
    }
    return 0
}

# _dbc_errors -- return only error-severity issues from validate_approach.
proc spar::_dbc_errors {approach_path} {
    set errs {}
    foreach issue [spar::validate_approach $approach_path "" ""] {
        if {[dict get $issue severity] eq "error"} {
            lappend errs [dict get $issue message]
        }
    }
    return $errs
}

# append_reply_to_yaml -- append a received reply to the final round in a YAML approach file.
# Also sets replied_date on email messages in the final round if not already set.
proc spar::append_reply_to_yaml {approach_path timestamp from_display reply_text} {
    # DbC-Pre: refuse to write if the file already has structural errors.
    set pre_errs [spar::_dbc_errors $approach_path]
    if {[llength $pre_errs] > 0} {
        puts stderr "append_reply_to_yaml: refusing to modify $approach_path — pre-validation failed:"
        foreach e $pre_errs { puts stderr "  - $e" }
        return
    }

    set fd [open $approach_path r]
    set content [read $fd]
    close $fd

    # Parse YAML to find the final round and check structure
    set data [::yaml::yaml2dict $content]
    if {![dict exists $data rounds]} return

    # Find final round index to locate it in the text
    set has_final 0
    foreach r [dict get $data rounds] {
        if {[spar::dict_get_default $r type ""] eq "final"} {
            set has_final 1
            break
        }
    }
    if {!$has_final} return

    # Escape special YAML characters in body text for safe embedding.
    # Use literal block scalar (|) for multi-line body.
    set escaped_body [_indent_body $reply_text 6]

    # Build the reply YAML block
    set reply_block "  - direction: received\n"
    append reply_block "    date: \"$timestamp\"\n"
    append reply_block "    from: \"$from_display\"\n"
    append reply_block "    body: |\n$escaped_body"

    # Locate the final round's extent so the replies block lands inside it,
    # not at EOF. Files typically have top-level keys (fact_provenance,
    # a_note, …) after `rounds:` — appending at EOF orphans the replies at
    # the wrong indent level, corrupting the YAML.
    #
    # Algorithm: find `- type: final` (or the nested `  type: final`
    # variant). Walk subsequent lines; any line indented strictly deeper
    # than the round marker belongs to the round. Stop at the first line
    # with ≤ marker indent — that's either the next round or a new
    # top-level key.
    set lines [split $content \n]
    set final_end -1
    set final_indent -1
    set in_final 0
    set has_replies_section 0

    set idx 0
    foreach line $lines {
        if {!$in_final
            && [regexp {^(\s*)- type:\s*final} $line -> lead]} {
            set final_indent [string length $lead]
            set final_end $idx
            set in_final 1
        } elseif {$in_final} {
            set trimmed [string trim $line]
            if {$trimmed eq ""} {
                # Blank line — provisionally inside the round; extend end.
                set final_end $idx
            } elseif {[regexp {^(\s*)\S} $line -> ind]} {
                if {[string length $ind] > $final_indent} {
                    set final_end $idx
                    if {[regexp {^\s+replies:\s*$} $line]} {
                        set has_replies_section 1
                    }
                } else {
                    # Shallower or equal indent — left the final round.
                    set in_final 0
                }
            }
        }
        incr idx
    }

    if {$final_end < 0} {
        # No final round found — fall back to appending at EOF so we don't
        # silently drop the reply; DbC-Post will surface any corruption.
        set content_trimmed [string trimright $content "\n"]
        if {$has_replies_section} {
            set new_content "${content_trimmed}\n${reply_block}"
        } else {
            set new_content "${content_trimmed}\n  replies:\n${reply_block}"
        }
    } else {
        # Insert after final_end. reply_block is multi-line text with a
        # trailing newline; split into lines and splice.
        set insertion {}
        if {!$has_replies_section} {
            lappend insertion "  replies:"
        }
        foreach bl [split [string trimright $reply_block "\n"] "\n"] {
            lappend insertion $bl
        }
        set before [lrange $lines 0 $final_end]
        set after  [lrange $lines [expr {$final_end + 1}] end]
        set new_content [join [concat $before $insertion $after] "\n"]
    }

    # Also set replied_date on email messages if not already set
    set reply_date [string range $timestamp 0 9]
    # Replace "replied_date: null" with the date (only in final round context)
    regsub -all {replied_date:\s*null} $new_content "replied_date: $reply_date" new_content

    set fd [open $approach_path w]
    # Tolerate characters that cannot round-trip through strict UTF-8 (e.g.
    # raw bytes that slipped in from upstream inbox output). Tcl 9's default
    # profile is strict and aborts the write; -profile replace substitutes
    # U+FFFD on malformed output. Encoding stays at the channel default.
    fconfigure $fd -profile replace
    puts -nonewline $fd $new_content
    # Ensure trailing newline
    if {[string index $new_content end] ne "\n"} {
        puts $fd ""
    }
    close $fd

    # DbC-Post: re-validate. New errors indicate a code bug in the reply-append
    # logic, which would silently corrupt data if ignored.
    set post_errs [spar::_dbc_errors $approach_path]
    if {[llength $post_errs] > 0} {
        puts stderr "append_reply_to_yaml: post-validation failed for $approach_path:"
        foreach e $post_errs { puts stderr "  - $e" }
        error "append_reply_to_yaml produced invalid YAML at $approach_path"
    }
}

# _indent_body -- indent each line of body text to the given level for YAML literal block.
proc spar::_indent_body {text indent_spaces} {
    set prefix [string repeat " " $indent_spaces]
    set lines [split $text \n]
    set result {}
    foreach line $lines {
        lappend result "${prefix}${line}"
    }
    return [join $result \n]
}

# ── Exported procs ─────────────────────────────────────────────────────

# spar::stamp_actioned_date -- set actioned_date on unsent final-round email messages.
#
# approach_path   path to approach YAML file
# today           date string (e.g. "2026-04-10")
#
# Returns 1 if file was modified, 0 otherwise.
#
proc spar::stamp_actioned_date {approach_path today} {
    # DbC-Pre: refuse to write if the file already has structural errors.
    set pre_errs [spar::_dbc_errors $approach_path]
    if {[llength $pre_errs] > 0} {
        puts stderr "stamp_actioned_date: refusing to modify $approach_path — pre-validation failed:"
        foreach e $pre_errs { puts stderr "  - $e" }
        return 0
    }

    set fd [open $approach_path r]
    set content [read $fd]
    close $fd

    # Parse YAML to identify which final-round email messages need stamping
    set data [::yaml::yaml2dict $content]
    if {![dict exists $data rounds]} {
        return 0
    }

    set needs_stamp 0
    foreach r [dict get $data rounds] {
        if {[dict_get_default $r type ""] ne "final"} continue
        if {![dict exists $r messages]} continue
        foreach msg [dict get $r messages] {
            if {[dict_get_default $msg channel ""] ne "email"} continue
            set ad [dict_get_default $msg actioned_date ""]
            if {[is_null $ad]} {
                set needs_stamp 1
                break
            }
        }
        if {$needs_stamp} break
    }

    if {!$needs_stamp} {
        return 0
    }

    # Targeted text replacement: in the final round section, replace
    # actioned_date: null with actioned_date: $today for email messages.
    #
    # Strategy: walk lines, track when we're in a final round and an email
    # message block, and replace actioned_date: null only in that context.
    # Note: YAML list items start with "- ", so regexes must allow for
    # an optional dash-space prefix (e.g. "- type: final").
    set lines [split $content \n]
    set result {}
    set in_final 0
    set in_email_msg 0
    set changed 0

    foreach line $lines {
        # Detect "type: final" at round level (may be "- type: final")
        if {[regexp {[-\s]*type:\s*final} $line]} {
            set in_final 1
        }
        # Detect start of a new round (type: something other than final)
        if {[regexp {[-\s]*type:\s*(\S+)} $line -> rtype]} {
            if {$rtype ne "final"} {
                set in_final 0
                set in_email_msg 0
            }
        }
        # Detect channel: email within a final round (may be "  - channel: email")
        if {$in_final && [regexp {[-\s]*channel:\s*email\s*$} $line]} {
            set in_email_msg 1
        }
        # Detect a new message block start (channel: something else)
        if {$in_final && [regexp {[-\s]*channel:\s*(\S+)} $line -> ch]} {
            if {$ch ne "email"} {
                set in_email_msg 0
            }
        }
        # Replace actioned_date: null in email message context
        if {$in_final && $in_email_msg && [regexp {^(\s*)actioned_date:\s*(null|~|)\s*$} $line -> indent]} {
            lappend result "${indent}actioned_date: $today"
            set changed 1
        } else {
            lappend result $line
        }
    }

    if {$changed} {
        set fd [open $approach_path w]
        puts -nonewline $fd [join $result \n]
        close $fd

        # DbC-Post: re-validate. New errors indicate a regex-bug in the stamp logic.
        set post_errs [spar::_dbc_errors $approach_path]
        if {[llength $post_errs] > 0} {
            puts stderr "stamp_actioned_date: post-validation failed for $approach_path:"
            foreach e $post_errs { puts stderr "  - $e" }
            error "stamp_actioned_date produced invalid YAML at $approach_path"
        }
    }

    return $changed
}

# spar::collect_sent_approaches -- find all sent approach files across segments.
#
# segments      list of segment directory paths
#
# Returns list of dicts, each with:
#   approach_path   path to approach YAML file
#   to_email        recipient email address (lowercase)
#   fingerprints    list of "from|date" strings for existing replies
#
proc spar::collect_sent_approaches {segments} {
    set results {}

    foreach seg_dir $segments {
        set approach_dir [file join $seg_dir approach]
        if {![file isdirectory $approach_dir]} continue

        foreach yf [lsort [glob -nocomplain -directory $approach_dir *.yaml]] {
            if {[catch {
                set fd [open $yf r]
                set raw [read $fd]
                close $fd
                set data [::yaml::yaml2dict $raw]
            }]} continue

            if {![dict exists $data rounds]} continue

            set is_sent 0
            set to_email ""
            set fingerprints {}

            foreach r [dict get $data rounds] {
                if {[dict_get_default $r type ""] ne "final"} continue

                if {[dict exists $r messages]} {
                    foreach msg [dict get $r messages] {
                        set ad [dict_get_default $msg actioned_date ""]
                        if {![is_null $ad]} {
                            set is_sent 1
                        }
                        if {[dict_get_default $msg channel ""] eq "email"} {
                            set msg_to [dict_get_default $msg to ""]
                            if {$msg_to ne "" && $to_email eq ""} {
                                set to_email [string tolower [string trim $msg_to]]
                            }
                        }
                    }
                }

                if {[dict exists $r replies]} {
                    foreach reply [dict get $r replies] {
                        set rd [dict_get_default $reply date ""]
                        set rf [dict_get_default $reply from ""]
                        if {$rd ne ""} {
                            set from_addr ""
                            if {$rf ne ""} {
                                set from_addr [extract_email_address $rf]
                            }
                            lappend fingerprints "${from_addr}|${rd}"
                        }
                    }
                }
            }

            if {!$is_sent || $to_email eq ""} continue

            lappend results [dict create \
                approach_path $yf \
                to_email $to_email \
                fingerprints $fingerprints]
        }
    }

    return $results
}

package provide spar-email 1.0
