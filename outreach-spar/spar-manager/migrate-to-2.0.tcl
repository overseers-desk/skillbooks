#!/usr/bin/env tclsh9.0
# migrate-to-2.0.tcl — one-shot migration of a spec-1.0 SPAR instance to
# the 2.0 layout (segments/ + campaigns/, campaign-keyed approaches; see
# spar-campaign-directory.md and spar-version-uplift-runbook.md).
#
# Dry-run by default: prints the full move plan, attribution decisions,
# and every finding (collision, ambiguity, unplaced file), then stops.
# --execute performs the plan with `git mv` so history follows, and
# stamps version: "2.0" (plus any --start-date) into the YAMLs.
#
# Usage:
#   tclsh9.0 migrate-to-2.0.tcl <instance-root> [--execute]
#       [--attribute <segment>=<campaign-stem>]...
#       [--start-date <campaign-stem>=<YYYY-MM-DD>]...
#
# Attribution: a segment's approach/*.yaml files belong to the one
# campaign that engaged the segment. Where only one campaign references
# the segment, that is the answer. Where several do, the script needs an
# --attribute override; it will not guess. Filename collisions inside a
# campaign folder (one person, two roster rows) stop the plan: merge the
# approach files by hand first (one campaign × one person = one file).

package require yaml

proc usage {} {
    puts stderr "Usage: tclsh9.0 migrate-to-2.0.tcl <instance-root> \[--execute\] \[--attribute seg=camp\]... \[--start-date camp=date\]..."
    exit 2
}

set root ""
set execute 0
array set attr_override {}
array set start_dates {}
for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    switch -glob -- $arg {
        --execute { set execute 1 }
        --attribute {
            incr i
            if {![regexp {^([^=]+)=(.+)$} [lindex $argv $i] -> k v]} usage
            set attr_override($k) $v
        }
        --start-date {
            incr i
            if {![regexp {^([^=]+)=(.+)$} [lindex $argv $i] -> k v]} usage
            set start_dates($k) $v
        }
        -* { usage }
        default {
            if {$root ne ""} usage
            set root [file normalize $arg]
        }
    }
}
if {$root eq "" || ![file isdirectory $root]} usage

set findings {}
set moves {}      ;# list of {src dst}
set yaml_edits {} ;# campaign stems needing field rewrite/stamp

proc finding {msg} { lappend ::findings $msg }
proc plan_move {src dst} {
    if {[file exists $dst]} {
        finding "collision: $dst already exists (moving $src)"
        return
    }
    foreach m $::moves {
        if {[lindex $m 1] eq $dst} {
            finding "collision: two files map to $dst ([lindex $m 0] and $src) — likely one person on two rosters; merge to one approach file first"
            return
        }
    }
    lappend ::moves [list $src $dst]
}

# ── 1. Campaign YAMLs at the root ────────────────────────────────────
set campaign_files [lsort [glob -nocomplain [file join $root campaign*.yaml]]]
if {[llength $campaign_files] == 0} {
    puts stderr "No campaign*.yaml at $root — nothing to migrate (pre-model instances are reconstructions, see the runbook)."
    exit 1
}

array set camp_segments {}   ;# campaign stem -> list of segment names
array set camp_paths {}      ;# campaign stem -> current yaml path
foreach cf $campaign_files {
    set stem [file rootname [file tail $cf]]
    regsub {^campaign-} $stem "" stem
    set fd [open $cf r]; set raw [read $fd]; close $fd
    if {[catch {::yaml::yaml2dict $raw} cdata]} {
        finding "unparseable campaign YAML: $cf ($cdata)"
        continue
    }
    set segs {}
    if {[dict exists $cdata segments]} {
        set sv [dict get $cdata segments]
        # map form {name plan ...} or list form {name name ...}
        if {[llength $sv] % 2 == 0 && [llength $sv] > 1} {
            foreach {k v} $sv { lappend segs $k }
        } else {
            set segs $sv
        }
    }
    if {"." in $segs} {
        finding "$cf uses segments: \".\" — name the segment first (2.0 has no root-as-segment form)"
        continue
    }
    set camp_segments($stem) $segs
    set camp_paths($stem) $cf
    plan_move $cf [file join $root campaigns "$stem.yaml"]
    lappend yaml_edits $stem
}

# ── 2. Segment set = union of referenced segments that exist ─────────
array set seg_campaigns {}   ;# segment -> campaigns referencing it
foreach stem [array names camp_segments] {
    foreach seg $camp_segments($stem) {
        lappend seg_campaigns($seg) $stem
    }
}

set seg_doc_words {summary profiles-summary comms-index sweep sweep-feedback}
foreach seg [lsort [array names seg_campaigns]] {
    set sdir [file join $root $seg]
    if {![file isdirectory $sdir]} {
        finding "referenced segment missing on disk: $seg (referenced by [join $seg_campaigns($seg) {, }])"
        continue
    }
    if {[file exists [file join $sdir segment.yaml]]} {
        plan_move [file join $sdir segment.yaml] [file join $root segments "$seg.yaml"]
    }
    if {[file exists [file join $sdir roster.tsv]]} {
        plan_move [file join $sdir roster.tsv] [file join $root segments "$seg.tsv"]
    } else {
        finding "segment $seg has no roster.tsv"
    }
    foreach {old new} [list sweep.yaml "$seg.sweep.yaml" \
                           sweep-feedback.tsv "$seg.sweep-feedback.tsv" \
                           profiles-summary.md "$seg.profiles-summary.md" \
                           comms-index.md "$seg.comms-index.md" \
                           "summary-$seg.md" "$seg.summary.md"] {
        if {[file exists [file join $sdir $old]]} {
            plan_move [file join $sdir $old] [file join $root segments $new]
        }
    }
    # profiles: strip legacy profile- prefix on the way through
    foreach f [glob -nocomplain [file join $sdir profiles *]] {
        set tail [file tail $f]
        regsub {^profile-} $tail "" tail
        plan_move $f [file join $root segments $seg $tail]
    }
    # approaches: attribute to the one campaign engaging this segment
    set ayamls [glob -nocomplain [file join $sdir approach *.yaml]]
    if {[llength $ayamls] > 0} {
        if {[info exists ::attr_override($seg)]} {
            set owner $::attr_override($seg)
        } elseif {[llength $seg_campaigns($seg)] == 1} {
            set owner [lindex $seg_campaigns($seg) 0]
        } else {
            finding "ambiguous attribution: segment $seg is referenced by [join $seg_campaigns($seg) {, }] and holds [llength $ayamls] approach files — pass --attribute $seg=<campaign>"
            continue
        }
        if {![info exists ::camp_paths($owner)]} {
            finding "attribution names unknown campaign '$owner' for segment $seg"
            continue
        }
        foreach f $ayamls {
            plan_move $f [file join $root campaigns $owner [file tail $f]]
        }
    }
    # anything left in the segment dir is reported, not guessed at
    foreach f [glob -nocomplain [file join $sdir *]] {
        set tail [file tail $f]
        if {$tail in {segment.yaml roster.tsv sweep.yaml sweep-feedback.tsv profiles approach profiles-summary.md comms-index.md}} continue
        if {$tail eq "summary-$seg.md"} continue
        finding "unplaced (left where it is): $f — move it by hand to segments/$seg.<word>.<ext> or the instance root"
    }
}

# ── 3. Campaign docs: single-campaign files take the dotted name ─────
# Renames only files following the campaign-<stem>-<word>.md convention.
foreach stem [lsort [array names camp_paths]] {
    foreach f [glob -nocomplain [file join $root "campaign-$stem-*.md"]] {
        set word [string range [file rootname [file tail $f]] \
            [string length "campaign-$stem-"] end]
        plan_move $f [file join $root campaigns "$stem.$word.md"]
    }
}

# ── 4. Report ────────────────────────────────────────────────────────
puts "Plan: [llength $moves] moves, [llength [array names camp_paths]] campaigns, [llength [array names seg_campaigns]] segments"
foreach m [lsort -index 0 $moves] {
    lassign $m src dst
    puts "  [string map [list $root/ {}] $src] -> [string map [list $root/ {}] $dst]"
}
if {[llength $findings]} {
    puts "\nFindings ([llength $findings]):"
    foreach f $findings { puts "  - $f" }
}
set blocking 0
foreach f $findings {
    if {[string match "collision:*" $f] || [string match "ambiguous*" $f] \
            || [string match "unparseable*" $f] || [string match "*uses segments*" $f]} {
        incr blocking
    }
}
if {$blocking} {
    puts "\n$blocking blocking finding(s) — resolve before --execute."
    exit 1
}
if {!$execute} {
    puts "\nDry run. Re-run with --execute to perform."
    exit 0
}

# ── 5. Execute ───────────────────────────────────────────────────────
proc rel {path} { string map [list $::root/ {}] $path }
file mkdir [file join $root segments] [file join $root campaigns]
foreach stem [array names camp_paths] {
    file mkdir [file join $root campaigns $stem]
}
foreach seg [array names seg_campaigns] {
    if {[file isdirectory [file join $root $seg]]} {
        file mkdir [file join $root segments $seg]
    }
}
foreach m $moves {
    lassign $m src dst
    # An untracked source (work never committed) has no git identity to
    # move; rename it on disk and stage the destination.
    if {[catch {exec git -C $root mv [rel $src] [rel $dst]}]} {
        file rename $src $dst
        exec git -C $root add [rel $dst]
    }
}
# Remove now-empty 1.0 segment shells (profiles/, approach/, the dir).
foreach seg [array names seg_campaigns] {
    set sdir [file join $root $seg]
    foreach sub {profiles approach} {
        catch {file delete [file join $sdir $sub]}
    }
    catch {file delete $sdir}
}

# ── 6. Stamp + rewrite the campaign YAMLs in place ───────────────────
foreach stem $yaml_edits {
    set path [file join $root campaigns "$stem.yaml"]
    set fd [open $path r]; set raw [read $fd]; close $fd
    set out {}
    set in_skip 0
    set has_version 0
    foreach line [split $raw \n] {
        if {$in_skip} {
            if {[regexp {^\s+-\s} $line] || [string trim $line] eq ""} continue
            set in_skip 0
        }
        if {[regexp {^skip_segments:} $line]} { set in_skip 1; continue }
        if {[regexp {^version:} $line]} {
            set line {version: "2.0"}
            set has_version 1
        }
        # Path fields sit one level deeper now; ../x becomes ../../x and
        # a bare root-relative doc gets ../ unless it was renamed into
        # campaigns/ (dotted docs resolve by bare name, no prefix).
        if {[regexp {^(usp_document|antifacts|campaign_principles):(\s*)(\S.*)$} $line -> key sp val]} {
            set val [string trim $val]
            if {[string index $val 0] ne "/"} {
                if {[regexp "^campaign-$stem-(.+)\\.md$" $val -> word]} {
                    set val "$stem.$word.md"
                } else {
                    set val "../$val"
                }
                set line "$key: $val"
            }
        }
        lappend out $line
    }
    if {!$has_version} {
        set idx [lsearch -regexp $out {^campaign:}]
        if {$idx >= 0} {
            set out [linsert $out $idx {version: "2.0"}]
        } else {
            set out [linsert $out 0 {version: "2.0"}]
        }
    }
    if {[info exists start_dates($stem)]} {
        set idx [lsearch -regexp $out {^version:}]
        set out [linsert $out [expr {$idx + 1}] "start_date: \"$start_dates($stem)\""]
    }
    set fd [open $path w]
    puts -nonewline $fd [join $out \n]
    close $fd
    exec git -C $root add [rel $path]
}

# ── 7. Stamp segment YAMLs ───────────────────────────────────────────
foreach seg [array names seg_campaigns] {
    set path [file join $root segments "$seg.yaml"]
    if {![file exists $path]} continue
    set fd [open $path r]; set raw [read $fd]; close $fd
    if {![regexp -line {^version:} $raw]} {
        set fd [open $path w]
        puts $fd {version: "2.0"}
        puts -nonewline $fd $raw
        close $fd
    } else {
        regsub -line {^version:.*$} $raw {version: "2.0"} raw
        set fd [open $path w]
        puts -nonewline $fd $raw
        close $fd
    }
    exec git -C $root add [rel $path]
}

puts "Executed. Re-run the validator: tclsh9.0 spar-validate-cli.tcl <root>/campaigns/<campaign>.yaml"
