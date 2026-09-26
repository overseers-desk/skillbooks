# spar-manager/transitions/check_replies.tcl
#
# CheckRepliesTransition (T7, Send → Reply). One pass per campaign over
# the mailbox that receives its replies: every inbound message since the
# first send whose sender is not one of our own domains is a candidate
# reply, and each candidate is placed against a sent approach by the
# address the letter went to, then by the transport id the send stored,
# looked for in the candidate's threading headers. A placed reply is
# appended to that approach YAML; a candidate neither key places is
# reported for the reader to attribute by hand. The class carries the
# transition metadata, the campaign-level task, and the prepare_for_pool
# method that builds the one-row Pool batch; the per-campaign search-and-
# fetch leg the Pool's imap_poll worker proc invokes,
# spar::imap::check_one, follows the class.

package require TclOO
package require json
package require spar::email

# ── CheckRepliesTransition ──────────────────────────────────────────

oo::class create ::spar::transitions::CheckRepliesTransition {
    superclass ::spar::transitions::Transition

    method build_opts {tasks filter_segments filter_stems} {
        return [dict create \
            log_message "[my tid]: reply-check pass over the campaign's mailbox"]
    }

    # T7's task is the campaign's, not a contact's: one search places
    # replies for every sent contact at once, and a reply may come from
    # an address no contact carries (a colleague answering a forward, a
    # member writing in). So `eligible` contributes nothing and the task
    # arrives through campaign_tasks, as T0's census sources do, whenever
    # a sent approach still awaits a reply. Both front ends fold
    # campaign-level tasks in beside the contact walk.
    method eligible {state contact primary_channel cdata today_iso} {
        return {}
    }

    method campaign_tasks {cdata campaign_file segment_paths} {
        if {$campaign_file eq ""} { return {} }
        set approach_dir [spar::approach_dir_for_campaign $campaign_file]
        set seg_dirs {}
        foreach item $segment_paths { lappend seg_dirs [lindex $item 1] }
        set awaiting 0
        foreach entry [spar::collect_sent_approaches $approach_dir $seg_dirs] {
            if {![dict get $entry replied]} { incr awaiting }
        }
        if {$awaiting == 0} { return {} }
        return [list [my _task $campaign_file dispatchable \
            "$awaiting sent, awaiting a reply"]]
    }

    # The task dict both front ends consume, in spar::_task's shape: the
    # campaign's mailbox stands where a contact would.
    method _task {campaign_file task_state reason} {
        return [dict create \
            contact_name "reply check" \
            organisation [file rootname [file tail $campaign_file]] \
            segment      "" \
            stem         [spar::reply_check_stem] \
            _segment_dir "" \
            task_state   $task_state \
            reason       $reason \
            channel      email]
    }

    # prepare_for_pool — pool-shape entry. Returns
    # {worker_proc imap_poll rows {{stem opts}}}, one row for the
    # campaign. imap_poll has no rate-limit pacing requirement so it
    # inherits the global Jobs cap.
    method prepare_for_pool {opts on_progress} {
        set prep [my _build_row $opts $on_progress]
        if {$prep eq ""} {
            return [dict create worker_proc imap_poll rows {}]
        }
        return [dict create worker_proc imap_poll rows [list $prep]]
    }

    # _build_row — the campaign row's opts for prepare_for_pool. Returns
    # {stem opts} on success, or "" if a precondition failed (no sender
    # address, no courier account reading the reply mailbox, no sent
    # approaches) so the pool skips with no rows. Synchronous
    # failed/skipped events are emitted through on_progress.
    #
    # The mailbox to search is the one reply_check.mailbox names, the
    # sender's own address when the campaign names none. A reply lands in
    # whichever mailbox receives mail for the From address, and that need
    # not be an account courier sends from: a campaign relaying through its
    # own SMTP from an alias of another mailbox names that mailbox here.
    # The folder is reply_check.folder, INBOX unless that mailbox's mail
    # rules file this campaign's replies elsewhere. Our own domains are
    # the sender's and the mailbox's: mail from them is our outgoing copy
    # or our own answer, never a reply.
    method _build_row {opts on_progress} {
        set campaign_file [dict get $opts campaign_file]
        set dry_run       [dict getdef $opts dry_run 0]
        set segments      [dict getdef $opts segments {}]
        set courier_bin   [dict getdef $opts courier_bin ""]
        set stem          [spar::reply_check_stem]

        set cdata [spar::load_campaign $campaign_file]

        if {![dict exists $cdata sender email]} {
            if {$on_progress ne ""} {
                {*}$on_progress $stem failed "campaign YAML missing sender.email"
            }
            return ""
        }
        set sender  [string tolower [dict get $cdata sender email]]
        set mailbox [string tolower [dict getdef $cdata reply_check mailbox $sender]]
        set folder  [dict getdef $cdata reply_check folder INBOX]
        set own_domains {}
        foreach a [list $sender $mailbox] {
            set d [lindex [split $a @] end]
            if {$d ne "" && $d ni $own_domains} { lappend own_domains $d }
        }

        if {$courier_bin eq ""} {
            set courier_bin [spar::find_tool courier]
        }
        if {$courier_bin eq ""} {
            if {$on_progress ne ""} {
                {*}$on_progress $stem failed "courier not found — check Settings"
            }
            return ""
        }
        if {[catch {
            set account [spar::imap::account_reading_address $courier_bin $mailbox]
        } aerr]} {
            if {$on_progress ne ""} {
                {*}$on_progress $stem failed "courier list: $aerr"
            }
            return ""
        }
        if {$account eq ""} {
            if {$on_progress ne ""} {
                {*}$on_progress $stem failed \
                    "no courier account reads mail for $mailbox; name the mailbox that receives replies to $sender as reply_check.mailbox"
            }
            return ""
        }

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

        # Every sent approach takes part, replied ones included: their
        # addresses and ids still place a second message from the same
        # thread, and their fingerprints keep a recorded reply from being
        # appended again.
        set approaches [spar::collect_sent_approaches $approach_dir $segments]
        if {[llength $approaches] == 0} {
            if {$on_progress ne ""} {
                {*}$on_progress $stem skipped "no sent approach to check"
            }
            return ""
        }
        set since ""
        foreach entry $approaches {
            set fs [dict getdef $entry first_sent ""]
            if {$fs ne "" && ($since eq "" || $fs < $since)} { set since $fs }
        }

        return [list $stem [dict create \
            campaign_file $campaign_file \
            dry_run       $dry_run \
            approaches    $approaches \
            since         $since \
            own_domains   $own_domains \
            account       $account \
            folder        $folder \
            courier_bin   $courier_bin]]
    }
}

::spar::transitions::register \
    -class ::spar::transitions::CheckRepliesTransition \
    -tid T7 \
    -label "Send → Reply" \
    -auto-safe 0 \
    -dispatch-status available \
    -ui-tree-row 1

# reply_check_stem -- the stem the campaign's one T7 row runs under.
proc spar::reply_check_stem {} { return "reply-check" }

# ── spar::imap::check_one — per-campaign IMAP-poll leg ──────────────
#
# Pure per-campaign IMAP-poll helper. Search the configured folder for
# inbound mail since the first send, drop what our own domains sent,
# drop what an approach already records, place the rest against the sent
# approaches (spar::reply_attribution), fetch each placed message's body
# and append it via spar::append_reply_to_yaml. Returns counts and the
# remainder; no callbacks, no thread::send, no registry, no event loop.
#
# Under the pool model the campaign is one row: one `courier search`,
# one `courier read` per candidate, zero or more append_reply_to_yaml
# calls. The courier children run through spar::pool_exec, which drives
# the subprocess off the event loop when this helper runs inside a
# jobloop coroutine (the pool path) and falls back to a plain exec
# otherwise, so a slow inbox yields the loop to the other jobs instead of
# freezing it.
#
# Inputs (opts dict):
#   approaches      list of dicts from collect_sent_approaches
#                   (approach_path, to_email, message_ids, fingerprints)
#   since           ISO date floor; messages dated before it are inbox
#                   history, not replies (optional, "" = no floor)
#   own_domains     lowercase domains whose mail is ours, not a reply
#   account         courier --imap value
#   folder          courier -f value
#   dry_run         1 = parse and report but don't write to YAML
#   courier_bin     optional path override (tests pass a fake)
#
# Returns one of:
#   {ok {new_replies N unattributed_count M unattributed {line ...}}}
#   {error <reason>}                — search/read/parse/append failure

namespace eval ::spar::imap {}

# spar::imap::account_reading_address courier_bin address — the courier
# IMAP account label that reads mail for `address`, or "" when none does.
# An account reads the address it logs in as and every address it carries
# an identity for. Reads `courier list`, the sanctioned view of courier's
# configuration (labels, hosts and addresses; no credentials), so the
# mapping is never copied into a campaign file by hand. Raises when
# courier itself fails or its output does not parse.
proc ::spar::imap::account_reading_address {courier_bin address} {
    set out [spar::pool_exec $courier_bin list]
    set jb [string first "\{" $out]
    set je [string last  "\}" $out]
    if {$jb < 0 || $je <= $jb} {
        error "no JSON in `courier list` output"
    }
    set cfg [::json::json2dict [string range $out $jb $je]]
    set wanted [string tolower [string trim $address]]
    dict for {label acct} [dict getdef $cfg imap {}] {
        if {[string tolower [dict getdef $acct username ""]] eq $wanted} {
            return $label
        }
    }
    dict for {label ident} [dict getdef $cfg identity {}] {
        if {[string tolower [dict getdef $ident address ""]] eq $wanted} {
            return [dict getdef $ident imap ""]
        }
    }
    return ""
}

proc ::spar::imap::check_one {opts} {
    set approaches  [dict get $opts approaches]
    set since       [dict getdef $opts since ""]
    set own_domains [dict getdef $opts own_domains {}]
    set account     [dict get $opts account]
    set folder      [dict get $opts folder]
    set dry_run     [dict getdef $opts dry_run 0]
    set courier_bin [dict getdef $opts courier_bin ""]

    if {$courier_bin eq ""} {
        set courier_bin [spar::find_tool courier]
    }
    if {$courier_bin eq ""} {
        return [list error "courier not found — check Settings"]
    }

    # One fingerprint set across the campaign: a reply recorded by hand
    # on any approach is recorded, whichever file it sits in.
    set fingerprints {}
    foreach entry $approaches {
        lappend fingerprints {*}[dict getdef $entry fingerprints {}]
    }

    # courier 1.1.15 exits 1 on a successful search that returns zero
    # results (documented), so a non-zero exit is not by itself a failure.
    # Capture the merged output whether exec returns or throws; the JSON
    # payload is present either way, and only an unparseable payload below
    # is treated as a real error.
    set query [expr {$since ne "" ? "after:$since" : "newer:1m"}]
    catch {spar::pool_exec $courier_bin --imap $account search -f $folder \
        --limit 500 $query} search_out

    # The merged output carries courier's stderr before the JSON (a
    # connect failure is warned there with the server's reason) and may
    # carry a trailing Tcl "child process exited abnormally" note after
    # it; isolate the JSON object by its outer braces and keep the
    # preamble for the failure message.
    set jb [string first "\{" $search_out]
    set je [string last  "\}" $search_out]
    set preamble ""
    if {$jb >= 0 && $je > $jb} {
        set preamble [string trim [string range $search_out 0 $jb-1]]
        set search_out [string range $search_out $jb $je]
    }

    # courier wraps the payload as
    #   {"<op_str>": {"<account>": {"results": [...], "provenance": ...}}}
    # and, for an account it could not search, as
    #   {"<op_str>": {"<account>": {"error": "..."}}}
    if {[catch {
        set raw [::json::json2dict $search_out]
        set inner [dict get $raw [lindex [dict keys $raw] 0]]
        set per_account [dict get $inner [lindex [dict keys $inner] 0]]
    } perr]} {
        return [list error "mailbox search JSON parse: $perr"]
    }
    if {[dict exists $per_account error]} {
        set why [dict get $per_account error]
        if {$preamble ne ""} { append why " ($preamble)" }
        return [list error "mailbox search: $why"]
    }
    if {[catch {set messages [dict get $per_account results]} perr]} {
        return [list error "mailbox search JSON parse: $perr"]
    }

    set messages [lsort -command {apply {{a b} {
        set da [dict getdef $a date ""]
        set db [dict getdef $b date ""]
        return [string compare $da $db]
    }}} $messages]

    set appended 0
    set unattributed {}
    foreach msg $messages {
        set from_email_addr [string tolower [spar::extract_email_address \
            [dict getdef $msg from ""]]]
        set date_str [dict getdef $msg date ""]
        if {![regexp {^\d{4}-\d{2}-\d{2}} $date_str]} continue

        # Mail predating the send is unrelated inbox history, not a
        # reply; ISO dates order lexically.
        if {$since ne "" && [string range $date_str 0 9] < $since} continue

        # Our own outgoing copy, or our own answer on the thread.
        if {[lindex [split $from_email_addr @] end] in $own_domains} continue

        if {[spar::fingerprint_match $fingerprints $from_email_addr $date_str]} {
            continue
        }

        set uid [dict getdef $msg uid ""]
        set from_display [dict getdef $msg from $from_email_addr]

        # Fetch the message: its threading headers place it, and its body
        # is what the approach records. courier-read failure becomes a
        # placeholder text, so the user still sees that a reply arrived
        # even if the body could not be retrieved.
        set reply_text "(no text content)"
        set thread_ids {}
        set read_error ""
        if {[catch {
            set read_out [spar::pool_exec $courier_bin --imap $account read \
                -f $folder -u $uid]
            # courier's stderr arrives merged ahead of the JSON (a version
            # notice, a connection warning), as it does for the search.
            set rb [string first "\{" $read_out]
            set re [string last  "\}" $read_out]
            if {$rb < 0 || $re <= $rb} {
                error "no JSON in courier read output: [string range $read_out 0 199]"
            }
            set raw [::json::json2dict [string range $read_out $rb $re]]
            set inner [dict get $raw [lindex [dict keys $raw] 0]]
            set email_data [dict get $inner [lindex [dict keys $inner] 0]]
            set body [dict getdef $email_data body ""]
            if {$body ne ""} {
                set reply_text [spar::html_to_text $body]
            }
            set irt [dict getdef $email_data in_reply_to ""]
            if {$irt ne ""} { lappend thread_ids $irt }
            lappend thread_ids {*}[dict getdef $email_data references {}]
        } rerr]} {
            set read_error $rerr
            set reply_text "(inbox read failed -- review manually:\n  $courier_bin --imap $account read -f $folder -u $uid)"
        }

        set approach_path [spar::reply_attribution $approaches \
            $from_email_addr $thread_ids]
        if {$approach_path eq ""} {
            lappend unattributed "unplaced reply $date_str from $from_display, subject \"[dict getdef $msg subject ""]\": record it on its approach by hand ($courier_bin --imap $account read -f $folder -u $uid)[expr {$read_error eq "" ? "" : "; its headers could not be read, so no thread could place it: $read_error"}]"
            continue
        }

        if {!$dry_run} {
            if {[catch {
                spar::append_reply_to_yaml $approach_path $date_str \
                    $from_display $reply_text
            } werr]} {
                return [list error "reply write error: $werr"]
            }
        }

        # Update the fingerprint set so a duplicate within this batch
        # is not re-appended (courier dedup is per-uid; this guards
        # the rare case of two messages from the same address with the
        # same date).
        lappend fingerprints "${from_email_addr}|${date_str}"
        incr appended
    }

    return [list ok [dict create \
        new_replies $appended \
        unattributed_count [llength $unattributed] \
        unattributed $unattributed]]
}
