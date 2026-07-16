# spar-manager/transitions/imap_check_one.tcl
#
# spar::imap::check_one — pure per-row IMAP-poll helper. For one
# approach YAML (one sent contact), search the configured inbox for
# new replies from the contact's to_email, fetch each new message
# body, and append them to the approach via spar::append_reply_to_yaml.
# Returns counts; no callbacks, no thread::send, no registry, no event
# loop.
#
# Under the pool model, one row corresponds to one stem: one `courier
# search`, zero or more `courier read`s, zero or more append_reply_to_yaml
# calls. The courier children run through spar::pool_exec, which drives the
# subprocess off the event loop when this helper runs inside a jobloop
# coroutine (the pool path) and falls back to a plain exec otherwise, so a
# slow inbox yields the loop to the other jobs instead of freezing it.
#
# Inputs (opts dict):
#   approach_path   abs path to the approach YAML for this stem
#   to_email        address watched for replies (lower)
#   since           ISO date floor; messages dated before it are not
#                   replies to this approach (optional, "" = no floor)
#   fingerprints    list of "from|date" strings already recorded
#   account         courier --imap value
#   folder          courier -f value
#   sender          our own bare email address (used to filter inbound
#                   to messages addressed to us, not bounces)
#   dry_run         1 = parse and report but don't write to YAML
#   courier_bin    optional path override (tests pass a fake)
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
    set since         [dict getdef $opts since ""]
    set fingerprints  [dict getdef $opts fingerprints {}]
    set account       [dict get $opts account]
    set folder        [dict get $opts folder]
    set sender        [dict get $opts sender]
    set dry_run       [dict getdef $opts dry_run 0]
    set courier_bin   [dict getdef $opts courier_bin ""]

    if {$courier_bin eq ""} {
        set courier_bin [spar::find_tool courier]
    }
    if {$courier_bin eq ""} {
        return [list error "courier not found — check Settings"]
    }

    # courier 1.1.15 exits 1 on a successful search that returns zero
    # results (documented), so a non-zero exit is not by itself a failure.
    # Capture the merged output whether exec returns or throws; the JSON
    # payload is present either way, and only an unparseable payload below
    # is treated as a real error.
    catch {spar::pool_exec $courier_bin --imap $account search -f $folder \
        --limit 50 "from:$to_email"} search_out

    # On the exit-1 path the output may carry a trailing Tcl "child process
    # exited abnormally" note; isolate the JSON object by its outer braces.
    set jb [string first "\{" $search_out]
    set je [string last  "\}" $search_out]
    if {$jb >= 0 && $je > $jb} {
        set search_out [string range $search_out $jb $je]
    }

    # courier wraps the payload as
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
        set da [dict getdef $a date ""]
        set db [dict getdef $b date ""]
        return [string compare $da $db]
    }}} $incoming]

    set appended 0
    foreach msg $incoming {
        set from_email_addr [spar::extract_email_address \
            [dict getdef $msg from ""]]
        set date_str [dict getdef $msg date ""]
        if {![regexp {^\d{4}-\d{2}-\d{2}} $date_str]} continue

        # Mail predating the send is unrelated inbox history, not a
        # reply; ISO dates order lexically.
        if {$since ne "" && [string range $date_str 0 9] < $since} continue

        if {[spar::fingerprint_match $fingerprints $from_email_addr $date_str]} {
            continue
        }

        set uid [dict getdef $msg uid ""]
        set from_display [dict getdef $msg from $from_email_addr]

        # Fetch the body. courier-read failure becomes a placeholder
        # text, exactly as the legacy Driver did, so the user still
        # sees that a reply arrived even if the body could not be
        # retrieved.
        set reply_text "(no text content)"
        if {[catch {
            set read_out [spar::pool_exec $courier_bin --imap $account read \
                -f $folder -u $uid]
            set raw [::json::json2dict $read_out]
            set inner [dict get $raw [lindex [dict keys $raw] 0]]
            set email_data [dict get $inner [lindex [dict keys $inner] 0]]
            set body [dict getdef $email_data body ""]
            if {$body ne ""} {
                set reply_text [spar::html_to_text $body]
            }
        } _]} {
            set reply_text "(inbox read failed -- review manually:\n  $courier_bin --imap $account read -f $folder -u $uid)"
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
        # is not re-appended (courier dedup is per-uid; this guards
        # the rare case of two messages from the same address with the
        # same date).
        lappend fingerprints "${from_email_addr}|${date_str}"
        incr appended
    }

    return [list ok $appended]
}

package provide spar-imap-check-one 1.0
