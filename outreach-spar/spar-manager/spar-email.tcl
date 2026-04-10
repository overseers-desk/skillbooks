#!/usr/bin/env tclsh
# spar-email.tcl — Email operations for SPAR campaign manager
# Handles sending via AWS SES and reply checking via mailroom CLI.

source [file join [file dirname [file normalize [info script]]] spar-lib.tcl]

namespace eval spar {
    namespace export send_email stamp_actioned_date \
        check_replies_mailroom collect_sent_approaches
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

# append_reply_to_yaml -- append a received reply to the final round in a YAML approach file.
# Also sets replied_date on email messages in the final round if not already set.
proc spar::append_reply_to_yaml {approach_path timestamp from_display reply_text} {
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

    # Strategy: check if "replies:" section already exists in the final round.
    # If it does, append the new reply entry after the last reply.
    # If not, add "replies:" before the file ends (after the last round content).

    set lines [split $content \n]
    set result_lines {}
    set in_final_round 0
    set has_replies_section 0
    set last_replies_line -1
    set in_replies 0
    set indent_depth 0

    # First pass: find if there's a replies: section in the final round
    set line_idx 0
    foreach line $lines {
        if {[regexp {^- type:\s*final} $line] || [regexp {^  type:\s*final} $line]} {
            set in_final_round 1
        }
        if {$in_final_round && [regexp {^\s*replies:\s*$} $line]} {
            set has_replies_section 1
        }
        if {$in_final_round && $has_replies_section} {
            # Track the last line that belongs to replies section
            if {[regexp {^\s*-\s+direction:} $line] || [regexp {^\s{4,}\S} $line]} {
                set last_replies_line $line_idx
            }
        }
        incr line_idx
    }

    # Second approach: simpler text-based strategy
    # Find the end of the file content, append replies section or entries
    set content_trimmed [string trimright $content "\n"]

    if {$has_replies_section} {
        # Append the new reply entry at the end of the file
        set new_content "${content_trimmed}\n${reply_block}"
    } else {
        # Add "replies:" header then the entry
        set new_content "${content_trimmed}\n  replies:\n${reply_block}"
    }

    # Also set replied_date on email messages if not already set
    set reply_date [string range $timestamp 0 9]
    # Replace "replied_date: null" with the date (only in final round context)
    regsub -all {replied_date:\s*null} $new_content "replied_date: $reply_date" new_content

    set fd [open $approach_path w]
    puts -nonewline $fd $new_content
    # Ensure trailing newline
    if {[string index $new_content end] ne "\n"} {
        puts $fd ""
    }
    close $fd
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

# spar::send_email -- send one email via AWS SES.
#
# opts dict keys:
#   region       AWS region (default: ap-southeast-2)
#   from         From address (e.g. "Name <email>" or bare email)
#   to           To address
#   bcc          BCC address (optional, empty string to skip)
#   subject      Subject line
#   body         Body text (plain text)
#   dry_run      If true, return without sending
#
# Returns dict:
#   ok           bool (1 on success, 0 on failure)
#   message_id   SES MessageId on success, error message on failure
#
proc spar::send_email {opts} {
    set region  [dict_get_default $opts region "ap-southeast-2"]
    set from    [dict get $opts from]
    set to      [dict get $opts to]
    set bcc     [dict_get_default $opts bcc ""]
    set subject [dict get $opts subject]
    set body    [dict get $opts body]
    set dry_run [dict_get_default $opts dry_run 0]

    if {$dry_run} {
        return [dict create ok 1 message_id "dry-run"]
    }

    # Build destination JSON
    ::json::write indented 0
    set to_list [::json::write array [::json::write string $to]]
    if {$bcc ne ""} {
        set dest_json [::json::write object \
            ToAddresses $to_list \
            BccAddresses [::json::write array [::json::write string $bcc]]]
    } else {
        set dest_json [::json::write object ToAddresses $to_list]
    }

    # Build message JSON
    set subj_obj [::json::write object \
        Data [::json::write string $subject] \
        Charset [::json::write string "UTF-8"]]
    set body_obj [::json::write object \
        Text [::json::write object \
            Data [::json::write string $body] \
            Charset [::json::write string "UTF-8"]]]
    set msg_json [::json::write object \
        Subject $subj_obj \
        Body $body_obj]

    # Call AWS SES
    set code [catch {
        exec aws ses send-email \
            --region $region \
            --from $from \
            --destination $dest_json \
            --message $msg_json
    } output]

    if {$code != 0} {
        return [dict create ok 0 message_id $output]
    }

    # Parse JSON response to extract MessageId
    if {[catch {set parsed [::json::json2dict $output]} err]} {
        return [dict create ok 1 message_id "?"]
    }
    set mid [dict_get_default $parsed MessageId "?"]
    return [dict create ok 1 message_id $mid]
}

# spar::stamp_actioned_date -- set actioned_date on unsent final-round email messages.
#
# approach_path   path to approach YAML file
# today           date string (e.g. "2026-04-10")
#
# Returns 1 if file was modified, 0 otherwise.
#
proc spar::stamp_actioned_date {approach_path today} {
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

# spar::check_replies_mailroom -- check mailroom for new replies to sent approaches.
#
# campaign_dir    base directory of the campaign
# segments        list of segment directory paths to check
# mailroom_account  mailroom account name
# mailroom_folder   mailroom folder name
# sender_email    the campaign sender's email address
# on_progress     callback proc name: called with {to_email approach_stem status message}
#
# Returns dict:
#   new_replies   count of new replies found
#   errors        count of errors
#
proc spar::check_replies_mailroom {campaign_dir segments mailroom_account mailroom_folder sender_email on_progress} {
    set new_replies 0
    set errors 0
    set sender_lower [string tolower $sender_email]

    # Check mailroom is available
    if {[catch {exec mailroom --help} _]} {
        if {$on_progress ne ""} {
            {*}$on_progress "" "" "error" "mailroom CLI not found"
        }
        return [dict create new_replies 0 errors 1]
    }

    set approaches [collect_sent_approaches $segments]
    if {[llength $approaches] == 0} {
        return [dict create new_replies 0 errors 0]
    }

    # Group by to_email to avoid duplicate queries
    set by_to [dict create]
    foreach entry $approaches {
        set to_email [dict get $entry to_email]
        if {![dict exists $by_to $to_email]} {
            dict set by_to $to_email {}
        }
        dict lappend by_to $to_email $entry
    }

    dict for {to_email approach_entries} $by_to {
        # Search mailroom for messages from this contact
        set code [catch {
            exec mailroom -a $mailroom_account \
                search -f $mailroom_folder \
                --limit 50 \
                "from:$to_email"
        } search_output]

        if {$code != 0} {
            incr errors
            continue
        }

        if {[catch {set messages [::json::json2dict $search_output]} err]} {
            incr errors
            continue
        }

        # Filter to messages addressed to the sender (check to/cc)
        set incoming {}
        foreach msg $messages {
            set to_addrs {}
            set cc_addrs {}
            if {[dict exists $msg to]} {
                foreach a [dict get $msg to] {
                    lappend to_addrs [extract_email_address $a]
                }
            }
            if {[dict exists $msg cc]} {
                foreach a [dict get $msg cc] {
                    lappend cc_addrs [extract_email_address $a]
                }
            }
            if {$sender_lower in $to_addrs || $sender_lower in $cc_addrs} {
                lappend incoming $msg
            }
        }

        # Sort by date
        set incoming [lsort -command {apply {{a b} {
            set da [spar::dict_get_default $a date ""]
            set db [spar::dict_get_default $b date ""]
            return [string compare $da $db]
        }}} $incoming]

        foreach msg $incoming {
            set from_email_addr [extract_email_address [dict_get_default $msg from ""]]
            set date_str [dict_get_default $msg date ""]

            # Validate date format
            if {![regexp {^\d{4}-\d{2}-\d{2}} $date_str]} continue

            # Check if ANY approach file sharing this to_email already has the reply
            set already_recorded 0
            foreach entry $approach_entries {
                set fps [dict get $entry fingerprints]
                if {[fingerprint_match $fps $from_email_addr $date_str]} {
                    set already_recorded 1
                    break
                }
            }
            if {$already_recorded} continue

            # Fetch reply content
            set uid [dict_get_default $msg uid ""]
            set reply_text ""
            set fetch_code [catch {
                exec mailroom -a $mailroom_account \
                    read -f $mailroom_folder \
                    -u $uid
            } read_output]

            if {$fetch_code == 0} {
                if {[catch {set email_data [::json::json2dict $read_output]}]} {
                    set reply_text "(could not parse reply -- review manually:\n  mailroom -a $mailroom_account read -f $mailroom_folder -u $uid)"
                } else {
                    set body [dict_get_default $email_data body ""]
                    if {$body ne ""} {
                        set reply_text [html_to_text $body]
                    } else {
                        set reply_text "(no text content)"
                    }
                }
            } else {
                set reply_text "(mailroom read failed -- review manually:\n  mailroom -a $mailroom_account read -f $mailroom_folder -u $uid)"
            }

            # Add reply to first approach file
            set first_entry [lindex $approach_entries 0]
            set approach_path [dict get $first_entry approach_path]
            set from_display [dict_get_default $msg from $from_email_addr]

            append_reply_to_yaml $approach_path $date_str $from_display $reply_text

            # Update fingerprints in memory for dedup within this batch
            set fps [dict get $first_entry fingerprints]
            lappend fps "${from_email_addr}|${date_str}"
            dict set first_entry fingerprints $fps
            lset approach_entries 0 $first_entry
            dict set by_to $to_email $approach_entries

            incr new_replies

            # Call progress callback
            if {$on_progress ne ""} {
                set stem [file rootname [file tail $approach_path]]
                {*}$on_progress $to_email $stem "reply" "reply from $from_email_addr ($date_str)"
            }
        }
    }

    return [dict create new_replies $new_replies errors $errors]
}

package provide spar-email 1.0
