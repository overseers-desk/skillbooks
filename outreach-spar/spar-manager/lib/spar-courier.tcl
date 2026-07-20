# spar-courier.tcl — Courier prefetch helpers used by the SPAR-P and
# SPAR-A prompt builders. Builds the "## Courier — prefetched by
# dispatcher" block injected into prompts: an account-list header
# (cached) plus a per-contact correspondence cascade. Goal: kill
# redundant per-agent account-list calls and the
# email_search/email-search guess pattern observed in courier #13.
# Cascade per SPAR-P §4.7 — pass 1 by email (from/to), pass 2 by
# subject for name and organisation. Uses `courier -A` (multi-account)
# with `--format text`; both shipped in courier 1.0.3 along with the
# [Gmail]/All Mail folder default and exit-1-on-empty.

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

proc spar::courier::contact_block {name org email} {
    set name  [string trim $name]
    set org   [string trim $org]
    set email [string trim $email]
    if {$name eq "" && $org eq "" && $email eq ""} { return "" }
    if {[auto_execok courier] eq ""} { return "" }

    set who $name
    if {$who eq ""} { set who "(unnamed)" }
    if {$org ne ""} { append who " ($org)" }
    set out "\n### Prior correspondence with $who\n\n"

    set pass1_hit 0
    if {$email ne ""} {
        set q1 "from:$email OR to:$email"
        append out "# Pass 1 — email lookup\n\$ courier -A search '$q1' --format text --limit 10\n"
        lassign [spar::courier::_run $q1] rc text
        append out "$text\n"
        if {$rc == 0} { set pass1_hit 1 }
    } else {
        append out "(Pass 1 — email lookup — skipped: no email on roster.)\n"
    }
    if {$pass1_hit} {
        append out "\n(Pass 1 hit — pass 2 skipped per cascade rule.)\n"
        return $out
    }

    set q2_parts {}
    if {$name ne ""} { lappend q2_parts "subject:\"$name\"" }
    if {$org  ne ""} { lappend q2_parts "subject:\"$org\"" }
    if {[llength $q2_parts] == 0} {
        append out "\n(Pass 2 skipped: no name or organisation to search on.)\n"
        return $out
    }
    set q2 [join $q2_parts " OR "]
    append out "\n# Pass 2 — subject-line search for name and organisation (SPAR-P §4.7)\n"
    append out "\$ courier -A search '$q2' --format text --limit 10\n"
    lassign [spar::courier::_run $q2] rc text
    append out "$text\n"
    return $out
}

proc spar::courier::_run {query} {
    set courier [auto_execok courier]
    # courier exits 1 on a successful-but-empty search (documented), so a
    # non-zero exit is not by itself a failure. pool_exec merges stderr into
    # stdout the way `2>@1` did and, on a non-zero exit, throws with that
    # merged output as its message; capture it either way, the way
    # imap_check_one does. rc 0 means the search returned hits, which the
    # caller reads to decide whether the email pass already satisfied the
    # cascade.
    set rc [catch {spar::pool_exec {*}$courier -A search --format text \
        --limit 10 $query} out]
    return [list $rc [string trim $out]]
}

package provide spar-courier 1.0
