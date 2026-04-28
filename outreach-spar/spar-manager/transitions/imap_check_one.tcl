# spar-manager/transitions/imap_check_one.tcl
#
# spar::imap::check_one — pure per-row IMAP-poll helper. For one
# approach YAML (one sent contact), search the configured inbox for
# new replies from the contact's to_email, fetch each new message
# body, and append them to the approach via spar::append_reply_to_yaml.
# Returns counts; no callbacks, no thread::send, no registry, no event
# loop.
#
# Under the pool model, one row corresponds to one stem, so the
# previous async-fileevent queue (which served multiple stems through
# one shared event loop on the main thread) collapses to a
# synchronous per-stem call: one `mailroom search`, zero or more
# `mailroom read`s, zero or more append_reply_to_yaml calls. The
# worker thread is allowed to block — it has its own thread::send
# mailbox and does not share the main event loop.
#
# Inputs (opts dict):
#   approach_path   abs path to the approach YAML for this stem
#   to_email        recipient address of the original send (lower)
#   fingerprints    list of "from|date" strings already recorded
#   account         mailroom -a value
#   folder          mailroom -f value
#   sender          our own bare email address (used to filter inbound
#                   to messages addressed to us, not bounces)
#   dry_run         1 = parse and report but don't write to YAML
#   mailroom_bin    optional path override (tests pass a fake)
#
# Returns one of:
#   {ok <new_replies>}              — count of replies appended
#   {error <reason>}                — search/read/parse/append failure

package require TclOO
package require json

namespace eval ::spar::imap {}

proc ::spar::imap::check_one {opts} {
    set approach_path [dict get $opts approach_path]
    set to_email      [dict get $opts to_email]
    set fingerprints  [spar::dict_get_default $opts fingerprints {}]
    set account       [dict get $opts account]
    set folder        [dict get $opts folder]
    set sender        [dict get $opts sender]
    set dry_run       [spar::dict_get_default $opts dry_run 0]
    set mailroom_bin  [spar::dict_get_default $opts mailroom_bin ""]

    if {$mailroom_bin eq ""} {
        set mailroom_bin [spar::find_tool mailroom]
    }
    if {$mailroom_bin eq ""} {
        return [list error "mailroom not found — check Settings"]
    }

    if {[catch {
        set search_out [exec $mailroom_bin -a $account search -f $folder \
            --limit 50 "from:$to_email" 2>@1]
    } serr]} {
        return [list error "mailbox search failed: [string trim $serr]"]
    }

    # mailroom 1.1.0 wraps the payload as
    #   {"<op_str>": {"<account>": {"results": [...], "provenance": ...}}}
    if {[catch {
        set raw [::json::json2dict $search_out]
        set inner [dict get $raw [lindex [dict keys $raw] 0]]
        set per_account [dict get $inner [lindex [dict keys $inner] 0]]
        set messages [dict get $per_account results]
    } perr]} {
        return [list error "mailbox search JSON parse: $perr"]
    }

    set sender_lower [string tolower $sender]
    set incoming {}
    foreach msg $messages {
        set to_addrs {}
        set cc_addrs {}
        if {[dict exists $msg to]} {
            foreach a [dict get $msg to] {
                lappend to_addrs [spar::extract_email_address $a]
            }
        }
        if {[dict exists $msg cc]} {
            foreach a [dict get $msg cc] {
                lappend cc_addrs [spar::extract_email_address $a]
            }
        }
        if {$sender_lower in $to_addrs || $sender_lower in $cc_addrs} {
            lappend incoming $msg
        }
    }

    set incoming [lsort -command {apply {{a b} {
        set da [spar::dict_get_default $a date ""]
        set db [spar::dict_get_default $b date ""]
        return [string compare $da $db]
    }}} $incoming]

    set appended 0
    foreach msg $incoming {
        set from_email_addr [spar::extract_email_address \
            [spar::dict_get_default $msg from ""]]
        set date_str [spar::dict_get_default $msg date ""]
        if {![regexp {^\d{4}-\d{2}-\d{2}} $date_str]} continue

        if {[spar::fingerprint_match $fingerprints $from_email_addr $date_str]} {
            continue
        }

        set uid [spar::dict_get_default $msg uid ""]
        set from_display [spar::dict_get_default $msg from $from_email_addr]

        # Fetch the body. mailroom-read failure becomes a placeholder
        # text, exactly as the legacy Driver did, so the user still
        # sees that a reply arrived even if the body could not be
        # retrieved.
        set reply_text "(no text content)"
        if {[catch {
            set read_out [exec $mailroom_bin -a $account read \
                -f $folder -u $uid 2>@1]
            set raw [::json::json2dict $read_out]
            set inner [dict get $raw [lindex [dict keys $raw] 0]]
            set email_data [dict get $inner [lindex [dict keys $inner] 0]]
            set body [spar::dict_get_default $email_data body ""]
            if {$body ne ""} {
                set reply_text [spar::html_to_text $body]
            }
        } _]} {
            set reply_text "(inbox read failed -- review manually:\n  $mailroom_bin -a $account read -f $folder -u $uid)"
        }

        if {!$dry_run} {
            if {[catch {
                spar::append_reply_to_yaml $approach_path $date_str \
                    $from_display $reply_text
            } werr]} {
                return [list error "reply write error: $werr"]
            }
        }

        # Update local fingerprint set so a duplicate within this batch
        # is not re-appended (mailroom dedup is per-uid; this guards
        # the rare case of two messages from the same address with the
        # same date).
        lappend fingerprints "${from_email_addr}|${date_str}"
        incr appended
    }

    return [list ok $appended]
}

package provide spar-imap-check-one 1.0
