# spar-manager/transitions/check_replies.tcl
#
# CheckRepliesTransition (T7, Send → Reply). Queries the campaign's
# configured inbox for replies to sent approaches and appends any new
# ones to the approach YAML. The class carries the transition metadata,
# the build_opts hook the dispatcher reads, and the prepare_for_pool
# method that builds the per-row Pool batch; the per-row search-and-
# fetch leg the Pool's imap_poll worker proc invokes, spar::imap::check_one,
# follows the class.

package require TclOO
package require json

# ── CheckRepliesTransition ──────────────────────────────────────────

oo::class create ::spar::transitions::CheckRepliesTransition {
    superclass ::spar::transitions::Transition

    method build_opts {tasks filter_segments filter_stems} {
        set segs [dict create]
        set stems {}
        foreach c $tasks {
            dict set segs [dict get $c _segment_dir] 1
            lappend stems [dict get $c stem]
        }
        set segments_list [dict keys $segs]
        return [dict create \
            segments $segments_list \
            stems $stems \
            log_message "[my tid]: [llength $tasks] task(s) across [llength $segments_list] segment(s) (reply-check pass)"]
    }

    # prepare_for_pool — pool-shape entry. Returns
    # {worker_proc imap_poll rows {{stem opts} ...}}. The unified
    # Dispatcher in spar-transition enqueues the rows directly;
    # imap_poll has no rate-limit pacing requirement so it inherits
    # the global Jobs cap.
    method prepare_for_pool {opts on_progress} {
        set prep [my _build_rows $opts $on_progress]
        if {$prep eq ""} {
            return [dict create worker_proc imap_poll rows {}]
        }
        return [dict create \
            worker_proc imap_poll \
            rows [dict get $prep rows]]
    }

    # _build_rows — per-row opts dict construction for prepare_for_pool.
    # Returns {rows {{stem opts} ...}} on success, or "" if a
    # precondition failed (missing reply_check config, no sent approaches)
    # so the pool skips with no rows. Synchronous failed/skipped events
    # are emitted through on_progress.
    method _build_rows {opts on_progress} {
        set campaign_file [dict get $opts campaign_file]
        set dry_run       [dict getdef $opts dry_run 0]
        set segments      [dict getdef $opts segments {}]
        set stems         [dict getdef $opts stems    {}]

        set cdata [spar::load_campaign $campaign_file]

        if {![dict exists $cdata reply_check courier_account] \
            || ![dict exists $cdata reply_check folder]} {
            if {$on_progress ne ""} {
                {*}$on_progress "" failed \
                    "campaign YAML missing reply_check.courier_account or reply_check.folder"
            }
            return ""
        }
        if {![dict exists $cdata sender email]} {
            if {$on_progress ne ""} {
                {*}$on_progress "" failed "campaign YAML missing sender.email"
            }
            return ""
        }

        set account [dict get $cdata reply_check courier_account]
        set folder  [dict get $cdata reply_check folder]
        set sender  [dict get $cdata sender email]
        set campaign_dir [spar::instance_root_for_yaml $campaign_file]
        set approach_dir [spar::approach_dir_for_campaign $campaign_file]

        # Default segments to "all campaign segment dirs" when the caller
        # passed none. Mirrors the P-phase full-campaign default.
        if {[llength $segments] == 0} {
            foreach seg [spar::campaign_segment_names $cdata] {
                set seg_path [file join $campaign_dir segments $seg]
                if {[file isdirectory $seg_path]} {
                    lappend segments $seg_path
                }
            }
        }

        set approaches [spar::collect_sent_approaches $approach_dir $segments]
        set approaches [spar::filter_approaches_by_stems $approaches $stems]
        if {[llength $approaches] == 0} {
            if {$on_progress ne ""} {
                foreach s $stems {
                    {*}$on_progress $s skipped "no email address to watch"
                }
            }
            return ""
        }

        # Build {stem opts} pairs. The Pool's imap_poll worker drives
        # one (search + zero-or-more reads) cycle per row.
        set rows {}
        set seen_stems [dict create]
        foreach entry $approaches {
            set approach_path [dict get $entry approach_path]
            set stem [file rootname [file tail $approach_path]]
            set to_email [dict get $entry to_email]
            set fingerprints [dict get $entry fingerprints]
            dict set seen_stems $stem 1
            lappend rows [list $stem [dict create \
                campaign_file $campaign_file \
                dry_run       $dry_run \
                approach_path $approach_path \
                to_email      $to_email \
                since         [dict getdef $entry first_sent ""] \
                fingerprints  $fingerprints \
                account       $account \
                folder        $folder \
                sender        $sender]]
        }

        # Stems requested but with no watchable sent approach get a
        # synchronous skipped line naming the reason.
        if {$on_progress ne ""} {
            foreach s $stems {
                if {![dict exists $seen_stems $s]} {
                    {*}$on_progress $s skipped "no email address to watch"
                }
            }
        }

        return [dict create rows $rows]
    }

    # T7: a message was sent on some channel, no reply recorded yet,
    # and an email address is known to watch (the final round's email
    # to: or the roster email). Contacts without a watchable address
    # are omitted: the inbox cannot be monitored for them; a reply on
    # another channel is recorded on the approach YAML directly and
    # resolves REPLIED without this transition. Gated on approach-YAML
    # structural validity (#43 principle 7).
    method eligible {state contact primary_channel cdata today_iso} {
        set cstate [dict get $contact state]
        if {$cstate eq "EXCLUDED"} { return {} }
        if {![dict get $contact any_sent]} { return {} }
        if {[dict get $contact any_replied]} { return {} }
        if {[llength [dict get $contact to_addresses]] == 0
            && ![dict get $contact has_email]} { return {} }
        set vmsg [$state approach_validation_error $contact]
        if {$vmsg ne ""} {
            return [list [spar::_task $contact blocked "invalid_approach_yaml: $vmsg"]]
        }
        return [list [spar::_task $contact dispatchable ""]]
    }
}

::spar::transitions::register \
    -class ::spar::transitions::CheckRepliesTransition \
    -tid T7 \
    -label "Send → Reply" \
    -auto-safe 0 \
    -dispatch-status available \
    -ui-tree-row 1

# ── spar::imap::check_one — per-row IMAP-poll leg ───────────────────
#
# Pure per-row IMAP-poll helper. For one
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
