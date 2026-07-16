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
    namespace export stamp_actioned_date collect_sent_approaches \
        filter_approaches_by_stems
}

# ── Helpers (not exported) ─────────────────────────────────────────────

# extract_email_address -- extract bare email from "Name <email>" or bare email.
proc spar::extract_email_address {header} {
    if {[regexp {<([^>]+)>} $header -> addr]} {
        return [string tolower $addr]
    }
    return [string tolower [string trim $header]]
}

# build_reply_headers -- derive the headers needed to thread a reply onto an
# existing IMAP message. Pure function: takes the parent block captured at
# A-time (see SPAR-A §6 `parent` keyset, populated from `courier read`) plus
# the sender's address and reply_all flag, returns a dict with `to`, `cc`,
# `subject`, `in_reply_to`, `references` ready to drop into the SMTP path.
#
# The parent dict is captured from `courier read` at A-time and frozen into
# the approach YAML; we deliberately do not re-fetch at send time, so the
# reply still threads correctly even if the parent UID has shifted in the
# meantime (Gmail label cleanups, server migrations).
#
# parent dict keys consumed: message_id, subject, from, to, cc, references.
# Any may be missing or empty; the only one strictly required for threading
# is `message_id` (the caller is responsible for rejecting empty).
#
# sender_email is the bare address chosen for this send (campaign default or
# decisions.sender override). It is removed from the resulting To/Cc set so
# we do not accidentally email ourselves.
proc spar::build_reply_headers {parent sender_email reply_all} {
    set sender_lc [string tolower [string trim $sender_email]]
    set parent_msg_id [dict getdef $parent message_id ""]
    set parent_subject [dict getdef $parent subject ""]
    set parent_from [dict getdef $parent from ""]
    set parent_to [dict getdef $parent to ""]
    set parent_cc [dict getdef $parent cc ""]
    set parent_references [dict getdef $parent references ""]

    # To: the sender of the parent. Reply-all preserves the rest of the
    # original recipient set in Cc, minus our own address.
    set to_addr [spar::extract_email_address $parent_from]

    set cc_addrs {}
    if {$reply_all} {
        foreach raw [list {*}[spar::_split_address_list $parent_to] \
                          {*}[spar::_split_address_list $parent_cc]] {
            set bare [spar::extract_email_address $raw]
            if {$bare eq "" || $bare eq $sender_lc || $bare eq $to_addr} continue
            if {$bare in $cc_addrs} continue
            lappend cc_addrs $bare
        }
    }
    set cc_joined [join $cc_addrs ", "]

    # Subject: prepend "Re: " unless the parent already carries an RFC 5322
    # reply prefix (Re: / RE: / Re[2]: / Re : etc.). Match case-insensitively
    # at the start of the trimmed subject.
    set sub_trim [string trim $parent_subject]
    if {[regexp -nocase {^re(\[\d+\])?\s*:} $sub_trim]} {
        set subject $sub_trim
    } else {
        set subject "Re: $sub_trim"
    }

    # References: append parent.message_id to the captured chain. RFC 2822
    # gives References as a space-separated list of msg-id tokens. Avoid
    # double-listing if the chain already ends with the parent message_id.
    set ref_tokens {}
    foreach r $parent_references {
        set rt [string trim $r]
        if {$rt ne ""} { lappend ref_tokens $rt }
    }
    set parent_msg_id_trim [string trim $parent_msg_id]
    if {$parent_msg_id_trim ne ""} {
        if {[llength $ref_tokens] == 0 || \
                [lindex $ref_tokens end] ne $parent_msg_id_trim} {
            lappend ref_tokens $parent_msg_id_trim
        }
    }
    set references [join $ref_tokens " "]

    return [dict create \
        to $to_addr \
        cc $cc_joined \
        subject $subject \
        in_reply_to $parent_msg_id_trim \
        references $references]
}

# _split_address_list -- split a comma-separated address header into entries.
# YAML parses `to: addr` and `to: a@x, b@y` as strings; `to: [a@x, b@y]`
# parses as a Tcl list. Detect comma-separated headers by the literal comma
# (a Tcl list of addresses contains no commas after parsing); otherwise treat
# the value as a (possibly single-element) Tcl list.
proc spar::_split_address_list {value} {
    set s [string trim $value]
    if {$s eq ""} { return {} }
    if {[string first "," $s] >= 0} {
        set out {}
        foreach part [split $s ","] {
            set p [string trim $part]
            if {$p ne ""} { lappend out $p }
        }
        return $out
    }
    set out {}
    foreach addr $s {
        set a [string trim $addr]
        if {$a ne ""} { lappend out $a }
    }
    return $out
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
        if {[dict get $issue severity] ne "error"} continue
        lappend errs [dict get $issue message]
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
        if {[dict getdef $r type ""] eq "final"} {
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
    append reply_block "    channel: email\n"
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

    # Stamp replied_date on the final round's email message: an inbox
    # reply answers the email leg, so only that message's null marker
    # is filled. Messages on other channels and in other rounds keep
    # their own markers for their own ingest paths. Assumes `channel:`
    # precedes `replied_date:` within a message item, the order the A
    # harness writes.
    set reply_date [string range $timestamp 0 9]
    set out_lines {}
    set in_final 0
    set final_indent -1
    set msg_channel ""
    foreach line [split $new_content \n] {
        if {!$in_final} {
            if {[regexp {^(\s*)- type:\s*final} $line -> lead]} {
                set final_indent [string length $lead]
                set in_final 1
            }
        } else {
            if {[regexp {^(\s*)\S} $line -> ind]
                && [string length $ind] <= $final_indent} {
                set in_final 0
                set msg_channel ""
            } elseif {[regexp {^\s*(?:-\s+)?channel:\s*(\S+)} $line -> ch]} {
                set msg_channel $ch
            }
            if {$in_final && $msg_channel eq "email"
                && [regexp {^(\s*)replied_date:\s*null\s*$} $line -> rl]} {
                set line "${rl}replied_date: $reply_date"
            }
        }
        lappend out_lines $line
    }
    set new_content [join $out_lines \n]

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

# spar::stamp_actioned_date -- set actioned_date on unsent final-round messages
# of one channel (default email; T6's LinkedIn leg passes linkedin).
#
# approach_path   path to approach YAML file
# today           date string (e.g. "2026-04-10")
# channel         message channel to stamp (email | linkedin | phone)
#
# Returns 1 if file was modified, 0 otherwise.
#
proc spar::stamp_actioned_date {approach_path today {channel email}} {
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
        if {[dict getdef $r type ""] ne "final"} continue
        if {![dict exists $r messages]} continue
        foreach msg [dict get $r messages] {
            if {[dict getdef $msg channel ""] ne $channel} continue
            set ad [dict getdef $msg actioned_date ""]
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

    # Targeted text edit: in the final round section, replace
    # actioned_date: null with actioned_date: $today for the channel's
    # messages — or, when the message carries no actioned_date line at all
    # (the schema lets lifecycle fields be omitted, issue #160), insert one
    # after the message's last existing field line.
    #
    # Strategy: walk lines, track when we're in a final round and a message
    # block of the target channel, and replace actioned_date: null only in
    # that context. While inside a target-channel message block, remember
    # the field indentation (from the channel: line) and the position of
    # the block's last non-blank line; when the block ends (dedent — the
    # next "- channel:" item, the next round, and any top-level key all
    # dedent below the field indent — or EOF) without an actioned_date
    # line having been seen, splice one in at that position. Note: YAML
    # list items start with "- ", so regexes must allow for an optional
    # dash-space prefix (e.g. "- type: final").
    set lines [split $content \n]
    set result {}
    set in_final 0
    set in_channel_msg 0
    set changed 0
    set msg_field_indent 0   ;# indent of field lines in the current target msg
    set msg_has_ad 0         ;# actioned_date line seen in the current target msg
    set msg_last_ridx -1     ;# index in $result of the block's last non-blank line

    foreach line $lines {
        set trimmed [string trim $line]

        # Close an open target-channel message block on dedent: any
        # non-blank line indented shallower than the block's field lines
        # ends the message (deeper lines are literal-block content or
        # nested field lists; equal-indent lines are further fields).
        if {$in_channel_msg && $trimmed ne ""} {
            regexp {^(\s*)} $line -> lead
            if {[string length $lead] < $msg_field_indent} {
                if {!$msg_has_ad} {
                    set pad [string repeat " " $msg_field_indent]
                    set result [linsert $result [expr {$msg_last_ridx + 1}] \
                        "${pad}actioned_date: $today"]
                    set changed 1
                }
                set in_channel_msg 0
            }
        }

        # Detect "type: final" at round level (may be "- type: final")
        if {[regexp {[-\s]*type:\s*final} $line]} {
            set in_final 1
        }
        # Detect start of a new round (type: something other than final)
        if {[regexp {[-\s]*type:\s*(\S+)} $line -> rtype]} {
            if {$rtype ne "final"} {
                set in_final 0
                set in_channel_msg 0
            }
        }
        # Detect the target channel within a final round (may be "  - channel: email")
        if {$in_final && [regexp {^(\s*)(-\s+)?channel:\s*(\S+)\s*$} $line -> lead dash ch]} {
            set in_channel_msg [expr {$ch eq $channel}]
            if {$in_channel_msg} {
                # Fields sit where the key after the "- " sits.
                set msg_field_indent [expr {[string length $lead] + [string length $dash]}]
                set msg_has_ad 0
            }
        }
        # Replace actioned_date: null in target-channel message context
        if {$in_final && $in_channel_msg && [regexp {^(\s*)actioned_date:\s*(null|~|)\s*$} $line -> indent]} {
            lappend result "${indent}actioned_date: $today"
            set changed 1
        } else {
            lappend result $line
        }
        # Record an actioned_date line (null-replaced or already set) and
        # the block's last non-blank line, for the insertion path above.
        if {$in_channel_msg} {
            if {[regexp {^\s*actioned_date:} $line]} {
                set msg_has_ad 1
            }
            if {$trimmed ne ""} {
                set msg_last_ridx [expr {[llength $result] - 1}]
            }
        }
    }

    # EOF closes any still-open target-channel message block.
    if {$in_channel_msg && !$msg_has_ad} {
        set pad [string repeat " " $msg_field_indent]
        set result [linsert $result [expr {$msg_last_ridx + 1}] \
            "${pad}actioned_date: $today"]
        set changed 1
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

# _roster_email_map -- stem → watchable roster email for one segment.
#
# Applies the same hygiene as classify_contact: strip TSV quote
# artifacts, require an @, reject masked (starred) addresses. A
# missing or unreadable roster yields an empty map.
proc spar::_roster_email_map {seg_dir} {
    set map [dict create]
    set roster_path [file join $seg_dir roster.tsv]
    if {![file exists $roster_path]} { return $map }
    if {[catch {set rows [spar::load_roster $roster_path]}]} { return $map }
    foreach row $rows {
        set stem  [string trim [dict getdef $row stem ""]]
        set email [string trim [dict getdef $row email ""]]
        foreach var {stem email} {
            upvar 0 $var v
            if {[regexp {^"(.*)"$} $v -> inner]} { set v [string trim $inner] }
        }
        if {$stem eq "" || [string first "@" $email] < 0} continue
        if {[spar::is_masked_email $email]} continue
        dict set map $stem [string tolower $email]
    }
    return $map
}

# spar::collect_sent_approaches -- find all sent approach files across segments.
#
# segments      list of segment directory paths
#
# Returns list of dicts, each with:
#   approach_path   path to approach YAML file
#   to_email        address to watch for replies (lowercase): the final
#                   round's email to:, or the roster email when the send
#                   went out on another channel
#   first_sent      earliest final-round actioned_date (reply date floor)
#   fingerprints    list of "from|date" strings for existing replies
#
# A roster-sourced address is used by at most one approach per call
# (first stem wins): shared inboxes would otherwise record one inbound
# mail as a reply to every contact behind that address. The roster
# validators (roster_shared_inbox_collision) flag the underlying
# collision to the operator.
proc spar::collect_sent_approaches {segments} {
    set results {}
    set watched_addresses [dict create]

    foreach seg_dir $segments {
        set approach_dir [file join $seg_dir approach]
        if {![file isdirectory $approach_dir]} continue

        set roster_map ""

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
            set first_sent ""
            set fingerprints {}

            foreach r [dict get $data rounds] {
                if {[dict getdef $r type ""] ne "final"} continue

                if {[dict exists $r messages]} {
                    foreach msg [dict get $r messages] {
                        set ad [dict getdef $msg actioned_date ""]
                        if {![is_null $ad]} {
                            set is_sent 1
                            # yaml2dict parses unquoted dates to epoch
                            # seconds; quoted ones stay ISO strings.
                            set ad_day [string trim $ad]
                            if {[string is wideinteger -strict $ad_day]} {
                                set ad_day [clock format $ad_day -format %Y-%m-%d]
                            } else {
                                set ad_day [string range $ad_day 0 9]
                            }
                            if {$first_sent eq "" || $ad_day < $first_sent} {
                                set first_sent $ad_day
                            }
                        }
                        if {[dict getdef $msg channel ""] eq "email"} {
                            set msg_to [dict getdef $msg to ""]
                            if {$msg_to ne "" && $to_email eq ""} {
                                set to_email [string tolower [string trim $msg_to]]
                            }
                        }
                    }
                }

                if {[dict exists $r replies]} {
                    foreach reply [dict get $r replies] {
                        set rd [dict getdef $reply date ""]
                        set rf [dict getdef $reply from ""]
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

            if {!$is_sent} continue

            if {$to_email eq ""} {
                # Send went out on a non-email channel; watch the roster
                # email, if the roster carries a usable one.
                if {$roster_map eq ""} {
                    set roster_map [spar::_roster_email_map $seg_dir]
                }
                set stem [file rootname [file tail $yf]]
                set fallback [dict getdef $roster_map $stem ""]
                if {$fallback eq "" || [dict exists $watched_addresses $fallback]} {
                    continue
                }
                set to_email $fallback
            }
            dict set watched_addresses $to_email 1

            lappend results [dict create \
                approach_path $yf \
                to_email $to_email \
                first_sent $first_sent \
                fingerprints $fingerprints]
        }
    }

    return $results
}

# spar::filter_approaches_by_stems -- narrow an approach list to a cohort.
#
# approaches    list of dicts from collect_sent_approaches
# stems         cohort stems; empty means "no filter" (return input as-is)
#
# The stem is derived from the approach filename (basename without .yaml),
# matching the convention used in check_replies.tcl (driver's reply-log
# output) and the roster's stem column.
proc spar::filter_approaches_by_stems {approaches stems} {
    if {[llength $stems] == 0} {
        return $approaches
    }
    set wanted [dict create]
    foreach s $stems { dict set wanted $s 1 }
    set out {}
    foreach entry $approaches {
        set stem [file rootname [file tail [dict get $entry approach_path]]]
        if {[dict exists $wanted $stem]} { lappend out $entry }
    }
    return $out
}

package provide spar-email 1.0
