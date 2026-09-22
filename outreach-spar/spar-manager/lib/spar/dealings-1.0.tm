# spar::dealings — the contact's own messages to us, prefetched for the
# SPAR-P prompt. It answers the question six segment rubrics ask and the
# profile phase could not otherwise reach: what has this contact done to
# us, and when (spar-P-profile.md §4.7).
#
# Four properties hold I1 by construction rather than by instruction.
# The query reads from: the contact and never to:, so our own outreach
# is absent from a context that never held it. The block lists dated
# messages and no count, score or grade, so nothing shaped like warmth
# is there to lift. No hits yields the empty string, so the profiler has
# no absence to report and cannot write one. Bulk and list traffic drops
# out, because a newsletter blast is not conduct.
#
# Reads the local index through `mu`, which answers an address query in
# about a tenth of a second and is refreshed out of band. Where `mu` is
# absent or the index is unreadable the block is empty and profiling
# proceeds, the same degradation courier-1.0.tm takes.

package require spar::lib

namespace eval spar::dealings {
    # Domains that say nothing about who else writes from them, so the
    # colleague fallback would match strangers rather than an employer.
    variable freemail {
        gmail.com googlemail.com hotmail.com hotmail.com.au outlook.com
        live.com live.com.au msn.com yahoo.com yahoo.com.au ymail.com
        y7mail.com aol.com icloud.com me.com mac.com protonmail.com
        proton.me gmx.com mail.com bigpond.com bigpond.net.au
        optusnet.com.au tpg.com.au iinet.net.au westnet.com.au
        dodo.com.au internode.on.net
    }
    # A colleague query returning more than this is matching something
    # wider than one employer's mail, so it is discarded rather than
    # guessed at.
    variable domain_cap 40
    variable per_query 20
}

# Newest-first dated lines for a query, or {} when the search is empty,
# mu is missing, or the index cannot be read. mu exits non-zero on a
# successful-but-empty search, as courier does, so a non-zero status is
# not by itself a failure and both branches return the same thing.
proc spar::dealings::_find {query limit} {
    set mu [auto_execok mu]
    if {$mu eq ""} { return {} }
    if {[catch {
        spar::pool_exec {*}$mu find --fields "d s" --sortfield=date \
            --reverse -n $limit $query
    } out]} { return {} }
    set lines {}
    foreach l [split [string trim $out] \n] {
        if {[string trim $l] ne ""} { lappend lines [string trim $l] }
    }
    return $lines
}

# The block substituted into the P prompt. Empty string when this
# contact has never written to us.
proc spar::dealings::inbound_block {name org email} {
    variable freemail
    variable domain_cap
    variable per_query

    set email [string trim $email]
    if {$email eq "" || ![string match "*@*" $email]} { return "" }
    set addr [string tolower $email]

    set q "from:$addr AND NOT flag:list"
    set hits [spar::dealings::_find $q $per_query]

    set domain [string range $addr [expr {[string first @ $addr] + 1}] end]
    set colleagues {}
    set dq ""
    if {[lsearch -exact $freemail $domain] < 0} {
        set dq "from:$domain AND NOT from:$addr AND NOT flag:list"
        set found [spar::dealings::_find $dq $domain_cap]
        # At the cap the query is matching more than one employer's
        # mail, so it says nothing about this contact's organisation.
        if {[llength $found] < $domain_cap} { set colleagues $found }
    }

    if {[llength $hits] == 0 && [llength $colleagues] == 0} { return "" }

    set who [expr {$name eq "" ? $email : $name}]
    set out "\n\n## Prior dealings — prefetched by dispatcher\n\n"
    append out "Messages $who sent us, newest first, from the local mail index. Each line is a dated act of theirs, which SPAR-P §4.7 records in `## Mechanism evidence` with its date. What we sent them is not in this block and is not profile content.\n"
    if {[llength $hits] > 0} {
        append out "\n\$ mu find '$q'\n[join $hits \n]\n"
    }
    if {[llength $colleagues] > 0} {
        append out "\nFrom the same domain, so the organisation rather than this person:\n"
        append out "\n\$ mu find '$dq'\n[join $colleagues \n]\n"
    }
    return $out
}
