# spar::courier — prefetch helpers for the SPAR-A prompt builder. Builds
# the "## Courier — prefetched by dispatcher" block: a cached account-list
# header plus a per-contact cascade (pass 1 from/to the email, pass 2
# subject-line for name and organisation), so the A worker neither
# re-lists accounts nor invents a search command (courier #13).
#
# Each pass asks the local mail index first through `mu find`, the index
# spar::dealings reads, which answers in about a tenth of a second. courier
# runs only when the index has a hit, because its output carries the
# account, folder and UID the worker needs to read a parent message
# (spar-A-approach.md §4.1.1), while an empty courier search falls through
# to a live IMAP round trip per account (#225). Where `mu` is absent or the
# index cannot be read, courier answers.

package require spar::lib

namespace eval spar::courier {
    variable accounts_block_cache ""
}

proc spar::courier::accounts_block {} {
    variable accounts_block_cache
    if {$accounts_block_cache ne ""} { return $accounts_block_cache }
    set courier [auto_execok courier]
    if {$courier eq ""} { return "" }
    if {[catch {set out [spar::pool_exec {*}$courier list]}]} { return "" }
    set hdr "## Courier — prefetched by dispatcher\n\n"
    append hdr "The commands and outputs below were already run for you. **Do not re-run `courier list` and do not search for this contact's email / name / organisation** — the results are below. If you need a different search, use the account names shown and invoke `courier -A search '<query>' --format text` directly.\n\n"
    append hdr "\$ courier list\n[string trim $out]\n"
    set accounts_block_cache $hdr
    return $hdr
}

# One courier cascade per contact, serving both prompts: `author` is the
# correspondence block the author's brief carries under the accounts
# header; `prior` is the "Prior correspondence" section the persona's
# prompt carries, the pass-1 hits alone, and empty when there are none,
# since an index with no hits does not show the message is the first.
proc spar::courier::contact_blocks {name org email} {
    set name  [string trim $name]
    set org   [string trim $org]
    set email [string trim $email]
    set none [dict create author "" prior ""]
    if {$name eq "" && $org eq "" && $email eq ""} { return $none }
    if {[auto_execok courier] eq ""} { return $none }
    set prior ""

    set who $name
    if {$who eq ""} { set who "(unnamed)" }
    if {$org ne ""} { append who " ($org)" }
    set out "\n### Prior correspondence with $who\n\n"

    set pass1_hit 0
    if {$email ne ""} {
        set q1 "from:$email OR to:$email"
        append out "# Pass 1 — email lookup\n"
        lassign [spar::courier::_lookup $q1] rc cmd text
        append out "$cmd\n$text\n"
        if {$rc == 0} {
            set pass1_hit 1
            set prior "\n### Prior correspondence\n\n$text\n"
        }
    } else {
        append out "(Pass 1 — email lookup — skipped: no email on roster.)\n"
    }
    if {$pass1_hit} {
        append out "\n(Pass 1 hit — pass 2 skipped per cascade rule.)\n"
        return [dict create author $out prior $prior]
    }

    set q2_parts {}
    if {$name ne ""} { lappend q2_parts "subject:\"$name\"" }
    if {$org  ne ""} { lappend q2_parts "subject:\"$org\"" }
    if {[llength $q2_parts] == 0} {
        append out "\n(Pass 2 skipped: no name or organisation to search on.)\n"
        return [dict create author $out prior $prior]
    }
    set q2 [join $q2_parts " OR "]
    append out "\n# Pass 2 — subject-line search for name and organisation\n"
    lassign [spar::courier::_lookup $q2] rc cmd text
    append out "$cmd\n$text\n"
    return [dict create author $out prior $prior]
}

# One pass, as {rc command output}: the command line shown to the worker
# and what it printed. rc 0 means courier returned hits. An empty answer
# from the local index is shown as the `mu find` that gave it, and courier
# is not called.
proc spar::courier::_lookup {query} {
    if {[spar::courier::_indexed $query] eq "none"} {
        return [list 1 "\$ mu find '$query'" \
            "(no messages in the local mail index)"]
    }
    lassign [spar::courier::_run $query] rc text
    return [list $rc \
        "\$ courier -A search '$query' --format text --limit 10" $text]
}

# What the local index says of a query: hit, none, or unknown. mu exits
# non-zero on an empty search, as courier does; its "no matches" message
# tells that apart from a missing or unreadable index, which is unknown
# and leaves the answer to courier.
proc spar::courier::_indexed {query} {
    set mu [auto_execok mu]
    if {$mu eq ""} { return unknown }
    if {[catch {spar::pool_exec {*}$mu find --fields "d s" -n 1 $query} out]} {
        return [expr {[string match -nocase "*no matches*" $out] ? "none" : "unknown"}]
    }
    return [expr {[string trim $out] eq "" ? "none" : "hit"}]
}

proc spar::courier::_run {query} {
    set courier [auto_execok courier]
    # courier exits 1 on a successful-but-empty search (documented), so a
    # non-zero exit is not by itself a failure. pool_exec merges stderr into
    # stdout the way `2>@1` did and, on a non-zero exit, throws with that
    # merged output as its message; capture it either way, the way
    # spar::imap::check_one does. rc 0 means the search returned hits, which the
    # caller reads to decide whether the email pass already satisfied the
    # cascade.
    set rc [catch {spar::pool_exec {*}$courier -A search --format text \
        --limit 10 $query} out]
    return [list $rc [string trim $out]]
}
