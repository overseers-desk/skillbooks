#!/usr/bin/env tclsh
# spar-state.tcl — State machine library for SPAR campaign manager
# Pure read-only library: reads filesystem and TSV, returns current state.
# Sourced by both wish (GUI) and tclsh (CLI).

source [file join [file dirname [file normalize [info script]]] spar-lib.tcl]

namespace eval spar {
    namespace export classify_contact classify_segment \
        transition_eligible detect_duplicates progress_counts
}

# parse_star — extract integer star rating from a roster field.
# "5" → 5, "3+" → 3, "" → 0, non-numeric → 0.
proc spar::parse_star {val} {
    set val [string trim $val]
    if {$val eq ""} {
        return 0
    }
    if {[regexp {^(\d+)} $val -> num]} {
        return [expr {int($num)}]
    }
    return 0
}

# normalise_name — lowercase, strip parentheticals, collapse whitespace.
# Tcl port of spar_lib.py normalise_name().
proc spar::normalise_name {s} {
    set s [string tolower $s]
    # Strip parenthetical content
    regsub -all {\([^)]*\)} $s {} s
    # Replace separators (slash, ampersand, dashes) with space
    regsub -all {[/&\u2014\u2013-]+} $s { } s
    # Collapse whitespace
    regsub -all {\s+} $s { } s
    return [string trim $s]
}

# read_approach_yaml — safely read and parse an approach YAML file.
# Returns parsed dict, or empty string on failure.
proc spar::read_approach_yaml {path} {
    if {![file exists $path]} {
        return ""
    }
    set fd {}
    if {[catch {
        set fd [open $path r]
        fconfigure $fd -encoding utf-8
        set raw [read $fd]
        close $fd
        set fd {}
        set data [::yaml::yaml2dict $raw]
    } err]} {
        if {$fd ne ""} {
            catch {close $fd}
        }
        return ""
    }
    return $data
}

# analyse_final_round — extract state and channel properties from approach YAML data.
# Returns dict with keys: has_final, any_sent, email_sent, linkedin_sent,
#   email_replied, to_addresses, unsent_subjects.
proc spar::analyse_final_round {data} {
    set result [dict create \
        has_final 0 \
        any_sent 0 \
        email_sent 0 \
        linkedin_sent 0 \
        email_replied 0 \
        to_addresses {} \
        unsent_subjects {}]

    if {$data eq "" || ![dict exists $data rounds]} {
        return $result
    }

    set rounds [dict get $data rounds]
    foreach round $rounds {
        if {![dict exists $round type]} continue
        if {[dict get $round type] ne "final"} continue

        dict set result has_final 1

        # Process messages
        if {[dict exists $round messages]} {
            foreach msg [dict get $round messages] {
                set channel [spar::dict_get_default $msg channel ""]
                set actioned [spar::dict_get_default $msg actioned_date ""]
                set replied [spar::dict_get_default $msg replied_date ""]
                set to_addr [spar::dict_get_default $msg to ""]
                set subject [spar::dict_get_default $msg subject ""]

                set is_actioned [expr {![spar::is_null $actioned]}]
                set is_replied [expr {![spar::is_null $replied]}]

                if {$is_actioned} {
                    dict set result any_sent 1
                    if {$channel eq "email"} {
                        dict set result email_sent 1
                    }
                    if {$channel eq "linkedin"} {
                        dict set result linkedin_sent 1
                    }
                }

                if {$is_replied} {
                    dict set result email_replied 1
                }

                # Collect To: addresses from email messages
                if {$channel eq "email" && ![spar::is_null $to_addr]} {
                    set addr [string trim $to_addr]
                    if {$addr ne ""} {
                        set addrs [dict get $result to_addresses]
                        lappend addrs $addr
                        dict set result to_addresses $addrs
                    }
                }

                # Collect unsent subjects from email messages
                if {$channel eq "email" && !$is_actioned && ![spar::is_null $subject]} {
                    set subj [string trim $subject]
                    if {$subj ne ""} {
                        set subjs [dict get $result unsent_subjects]
                        lappend subjs $subj
                        dict set result unsent_subjects $subjs
                    }
                }
            }
        }

        # Process replies
        if {[dict exists $round replies]} {
            foreach reply [dict get $round replies] {
                if {[spar::dict_get_default $reply direction ""] eq "received"} {
                    dict set result email_replied 1
                }
            }
        }
    }

    return $result
}

# classify_contact -- classify one contact's state.
#
# roster_row   dict with TSV fields (contact_name, date_found_invalid,
#              star_rating, email, linkedin_url, facebook_url, phone,
#              profile_stem, approach_stem, ...)
# segment_dir  absolute path to the segment directory
#
# Returns a dict:
#   state         one of: INVALID DISCOVERED PROFILED PROFILE_STALE
#                         APPROACHED SENT REPLIED
#   profile_path  path to profile file, or empty string
#   approach_path path to approach YAML, or empty string
#   star          integer (0 if blank/unparseable)
#   has_email     bool
#   has_linkedin  bool
#   has_facebook  bool
#   has_phone_only bool
#   email_sent    bool
#   linkedin_sent bool
#   email_replied bool
#
proc spar::classify_contact {roster_row segment_dir} {
    # Extract roster fields with safe defaults.
    # strip_tsv_field: trim whitespace, and if the remaining value is a
    # quoted-empty-or-whitespace string (e.g. `" "` or `""`), collapse to "".
    # This happens when TSV was edited with a tool that CSV-quotes blank fields.
    set date_invalid [string trim [spar::dict_get_default $roster_row date_found_invalid ""]]
    set profile_stem [string trim [spar::dict_get_default $roster_row profile_stem ""]]
    set approach_stem [string trim [spar::dict_get_default $roster_row approach_stem ""]]
    set star_raw [spar::dict_get_default $roster_row star_rating ""]
    set email [string trim [spar::dict_get_default $roster_row email ""]]
    set linkedin [string trim [spar::dict_get_default $roster_row linkedin_url ""]]
    set facebook [string trim [spar::dict_get_default $roster_row facebook_url ""]]
    set phone [string trim [spar::dict_get_default $roster_row phone ""]]

    # Strip TSV quote artifacts: `" "`, `""`, `" "` → ""
    foreach var {date_invalid profile_stem approach_stem email linkedin facebook phone} {
        upvar 0 $var v
        if {[regexp {^"(.*)"$} $v -> inner]} {
            set v [string trim $inner]
        }
    }

    # Secondary properties
    set star [spar::parse_star $star_raw]
    set has_email [expr {[string first "@" $email] >= 0}]
    set has_linkedin [expr {$linkedin ne ""}]
    set has_facebook [expr {$facebook ne ""}]
    set has_phone_only [expr {$phone ne "" && !$has_email && !$has_linkedin && !$has_facebook}]

    # Initialise channel properties
    set email_sent 0
    set linkedin_sent 0
    set email_replied 0

    # Paths
    set profile_path ""
    set approach_path ""

    # State evaluation (ordered — first match wins)

    # 1. INVALID
    if {![spar::is_null $date_invalid]} {
        return [dict create \
            state INVALID \
            profile_path $profile_path \
            approach_path $approach_path \
            star $star \
            has_email $has_email \
            has_linkedin $has_linkedin \
            has_facebook $has_facebook \
            has_phone_only $has_phone_only \
            email_sent $email_sent \
            linkedin_sent $linkedin_sent \
            email_replied $email_replied]
    }

    # 2. DISCOVERED — profile_stem empty
    if {[spar::is_null $profile_stem]} {
        return [dict create \
            state DISCOVERED \
            profile_path $profile_path \
            approach_path $approach_path \
            star $star \
            has_email $has_email \
            has_linkedin $has_linkedin \
            has_facebook $has_facebook \
            has_phone_only $has_phone_only \
            email_sent $email_sent \
            linkedin_sent $linkedin_sent \
            email_replied $email_replied]
    }

    # Profile file check
    set profile_path [file join $segment_dir profiles "${profile_stem}.md"]
    if {![file exists $profile_path]} {
        # profile_stem set but file missing — treat as DISCOVERED
        set profile_path ""
        return [dict create \
            state DISCOVERED \
            profile_path $profile_path \
            approach_path $approach_path \
            star $star \
            has_email $has_email \
            has_linkedin $has_linkedin \
            has_facebook $has_facebook \
            has_phone_only $has_phone_only \
            email_sent $email_sent \
            linkedin_sent $linkedin_sent \
            email_replied $email_replied]
    }

    # 3. PROFILED (PROFILE_STALE deferred — all profiled are non-stale)
    # Check if there is an approach file
    if {[spar::is_null $approach_stem]} {
        return [dict create \
            state PROFILED \
            profile_path $profile_path \
            approach_path $approach_path \
            star $star \
            has_email $has_email \
            has_linkedin $has_linkedin \
            has_facebook $has_facebook \
            has_phone_only $has_phone_only \
            email_sent $email_sent \
            linkedin_sent $linkedin_sent \
            email_replied $email_replied]
    }

    set approach_path [file join $segment_dir approach "${approach_stem}.yaml"]
    if {![file exists $approach_path]} {
        # approach_stem set but file missing — still PROFILED
        set approach_path ""
        return [dict create \
            state PROFILED \
            profile_path $profile_path \
            approach_path $approach_path \
            star $star \
            has_email $has_email \
            has_linkedin $has_linkedin \
            has_facebook $has_facebook \
            has_phone_only $has_phone_only \
            email_sent $email_sent \
            linkedin_sent $linkedin_sent \
            email_replied $email_replied]
    }

    # Approach file exists — parse it for state determination
    set approach_data [spar::read_approach_yaml $approach_path]
    set fr [spar::analyse_final_round $approach_data]

    set email_sent [dict get $fr email_sent]
    set linkedin_sent [dict get $fr linkedin_sent]
    set email_replied [dict get $fr email_replied]

    # 6. REPLIED — SENT and (replied_date or reply with direction:received)
    if {[dict get $fr any_sent] && [dict get $fr email_replied]} {
        return [dict create \
            state REPLIED \
            profile_path $profile_path \
            approach_path $approach_path \
            star $star \
            has_email $has_email \
            has_linkedin $has_linkedin \
            has_facebook $has_facebook \
            has_phone_only $has_phone_only \
            email_sent $email_sent \
            linkedin_sent $linkedin_sent \
            email_replied $email_replied]
    }

    # 5. SENT — final round has at least one message with actioned_date
    if {[dict get $fr any_sent]} {
        return [dict create \
            state SENT \
            profile_path $profile_path \
            approach_path $approach_path \
            star $star \
            has_email $has_email \
            has_linkedin $has_linkedin \
            has_facebook $has_facebook \
            has_phone_only $has_phone_only \
            email_sent $email_sent \
            linkedin_sent $linkedin_sent \
            email_replied $email_replied]
    }

    # 4. APPROACHED — approach file exists, no final-round message with actioned_date
    return [dict create \
        state APPROACHED \
        profile_path $profile_path \
        approach_path $approach_path \
        star $star \
        has_email $has_email \
        has_linkedin $has_linkedin \
        has_facebook $has_facebook \
        has_phone_only $has_phone_only \
        email_sent $email_sent \
        linkedin_sent $linkedin_sent \
        email_replied $email_replied]
}

# classify_segment -- load roster and classify all contacts.
#
# segment_dir  absolute path to the segment directory
#
# Returns a list of dicts, one per valid+named roster row,
# each being the result of classify_contact merged with the original roster_row.
# On schema error, throws an error.
#
proc spar::classify_segment {segment_dir} {
    set roster_path [file join $segment_dir roster.tsv]
    if {![file exists $roster_path]} {
        error "Roster file not found: $roster_path"
    }

    set rows [spar::load_roster $roster_path]

    # Schema validation: check that profile_stem and approach_stem columns exist
    if {[llength $rows] > 0} {
        set first_row [lindex $rows 0]
        if {![dict exists $first_row profile_stem]} {
            error "Error: roster missing required column 'profile_stem' — run schema migration before using spar-state.tcl"
        }
        if {![dict exists $first_row approach_stem]} {
            error "Error: roster missing required column 'approach_stem' — run schema migration before using spar-state.tcl"
        }
    }

    set results {}
    foreach row $rows {
        # Skip rows with empty contact_name
        set contact_name [string trim [spar::dict_get_default $row contact_name ""]]
        if {$contact_name eq ""} continue

        set classified [spar::classify_contact $row $segment_dir]

        # Merge: original roster_row + classified result (classified wins on overlap)
        set merged $row
        dict for {k v} $classified {
            dict set merged $k $v
        }
        # Ensure segment_dir is available for cross-segment operations
        dict set merged _segment_dir $segment_dir

        lappend results $merged
    }

    return $results
}

# transition_eligible -- filter classified contacts by transition eligibility.
#
# classified_contacts  output of classify_segment
# transition           transition name: T1, T2, ... T8
#
# Returns a list of dicts with keys:
#   contact_name, organisation, segment, task_state (ready/pending/done), reason
#
proc spar::transition_eligible {classified_contacts transition} {
    set results {}

    foreach contact $classified_contacts {
        set name [spar::dict_get_default $contact contact_name ""]
        set org [spar::dict_get_default $contact organisation ""]
        set segment_dir [spar::dict_get_default $contact _segment_dir ""]
        set segment [file tail $segment_dir]
        set state [dict get $contact state]
        set star [dict get $contact star]
        set has_email [dict get $contact has_email]
        set email_sent [dict get $contact email_sent]
        set linkedin_sent [dict get $contact linkedin_sent]
        set email_replied [dict get $contact email_replied]

        switch -- $transition {
            T1 {
                # Sweep → Profile: state = DISCOVERED
                if {$state eq "DISCOVERED"} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        task_state ready reason ""]
                }
            }
            T2 {
                # Profile → Approach: state = PROFILED, star≥3
                if {$state eq "PROFILED" && $star >= 3} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        task_state ready reason ""]
                }
            }
            T3 {
                # Approach → Send: state in {APPROACHED,SENT}, has_email, not email_sent
                if {$state eq "APPROACHED" || $state eq "SENT"} {
                    if {$has_email && !$email_sent} {
                        lappend results [dict create \
                            contact_name $name organisation $org segment $segment \
                            task_state ready reason ""]
                    } elseif {!$has_email} {
                        lappend results [dict create \
                            contact_name $name organisation $org segment $segment \
                            task_state pending reason "No email address"]
                    }
                }
            }
            T4 {
                # Send → Reply: email_sent, not email_replied (monitoring only)
                if {$email_sent && !$email_replied} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        task_state pending reason "Waiting for reply"]
                }
            }
            T5 {
                # Flag invalid: any valid contact (not INVALID)
                if {$state ne "INVALID"} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        task_state ready reason ""]
                }
            }
            T6 {
                # Stale → Re-profile: state = PROFILE_STALE
                # Zero tasks until PROFILE_STALE defined
                if {$state eq "PROFILE_STALE"} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        task_state ready reason ""]
                }
            }
            T7 {
                # Re-profile → Re-approach: deferred, zero tasks
                # Would require PROFILE_STALE + re-profiling detection
            }
            T8 {
                # LinkedIn → Email follow-up: linkedin_sent, not email_sent
                if {$linkedin_sent && !$email_sent} {
                    lappend results [dict create \
                        contact_name $name organisation $org segment $segment \
                        task_state pending reason "LinkedIn sent, awaiting acceptance before email follow-up"]
                }
            }
        }
    }

    return $results
}

# detect_duplicates -- detect cross-segment duplicates.
#
# all_classified_contacts  flat list of all classified contacts across all segments
#                          (each dict has _segment_dir, contact_name, email, approach_path, etc.)
#
# Returns a dict with keys:
#   duplicate_to      — list of dicts {address files} where same To: email in multiple approach files
#   duplicate_name    — list of dicts {name entries} where same normalised name in multiple segments
#   duplicate_email   — list of dicts {email entries} where same email in multiple segments
#   identical_subject — list of dicts {subject files} where same subject in multiple unsent approach files
#
proc spar::detect_duplicates {all_classified_contacts} {
    # Accumulators: key → list of entries
    array set to_map {}       ;# to_address → list of {segment filename}
    array set name_map {}     ;# normalised_name → list of {segment contact_name organisation email}
    array set email_map {}    ;# email → list of {segment contact_name organisation}
    array set subject_map {}  ;# subject → list of {segment filename}

    foreach contact $all_classified_contacts {
        set name [spar::dict_get_default $contact contact_name ""]
        set org [spar::dict_get_default $contact organisation ""]
        set email [string trim [string tolower [spar::dict_get_default $contact email ""]]]
        set segment_dir [spar::dict_get_default $contact _segment_dir ""]
        set segment [file tail $segment_dir]
        set approach_path [dict get $contact approach_path]
        set state [dict get $contact state]
        set email_sent_flag [dict get $contact email_sent]

        if {$name eq ""} continue

        # Name map (cross-segment)
        set nk [spar::normalise_name $name]
        if {$nk ne ""} {
            lappend name_map($nk) [list $segment $name $org $email]
        }

        # Email map (cross-segment)
        if {$email ne "" && [string first "@" $email] >= 0} {
            lappend email_map($email) [list $segment $name $org]
        }

        # Approach-file-based checks: only if approach file exists
        if {$approach_path eq "" || ![file exists $approach_path]} continue

        set approach_data [spar::read_approach_yaml $approach_path]
        if {$approach_data eq ""} continue

        set fr [spar::analyse_final_round $approach_data]
        set filename [file tail $approach_path]

        # To: address duplicates
        foreach addr [dict get $fr to_addresses] {
            set addr_lower [string tolower [string trim $addr]]
            if {$addr_lower ne "" && [string first "@" $addr_lower] >= 0} {
                lappend to_map($addr_lower) [list $segment $filename]
            }
        }

        # Identical subject lines in unsent approach files
        foreach subj [dict get $fr unsent_subjects] {
            if {$subj ne ""} {
                lappend subject_map($subj) [list $segment $filename]
            }
        }
    }

    # Build result: only include entries with duplicates

    # duplicate_to: same To: address in multiple approach files
    set dup_to {}
    foreach addr [array names to_map] {
        set entries $to_map($addr)
        if {[llength $entries] > 1} {
            lappend dup_to [dict create address $addr files $entries]
        }
    }

    # duplicate_name: same normalised name across multiple segments
    set dup_name {}
    foreach nk [array names name_map] {
        set entries $name_map($nk)
        # Only flag if name appears in more than one distinct segment
        set seen_segments {}
        foreach entry $entries {
            set seg [lindex $entry 0]
            if {$seg ni $seen_segments} {
                lappend seen_segments $seg
            }
        }
        if {[llength $seen_segments] > 1} {
            lappend dup_name [dict create name $nk entries $entries]
        }
    }

    # duplicate_email: same email across multiple segments
    set dup_email {}
    foreach addr [array names email_map] {
        set entries $email_map($addr)
        set seen_segments {}
        foreach entry $entries {
            set seg [lindex $entry 0]
            if {$seg ni $seen_segments} {
                lappend seen_segments $seg
            }
        }
        if {[llength $seen_segments] > 1} {
            lappend dup_email [dict create email $addr entries $entries]
        }
    }

    # identical_subject: same subject in multiple unsent approach files
    set dup_subject {}
    foreach subj [array names subject_map] {
        set entries $subject_map($subj)
        if {[llength $entries] > 1} {
            lappend dup_subject [dict create subject $subj files $entries]
        }
    }

    return [dict create \
        duplicate_to $dup_to \
        duplicate_name $dup_name \
        duplicate_email $dup_email \
        identical_subject $dup_subject]
}

# progress_counts -- compute progress table counts for one segment.
#
# classified_contacts  output of classify_segment for one segment
#
# Returns a dict with counts:
#   valid, profiled, star3, approached_star3, has_email, approached_email,
#   has_linkedin, has_facebook, has_phone_only, email_sent, email_replied
#
proc spar::progress_counts {classified_contacts} {
    set valid 0
    set profiled 0
    set star3 0
    set approached_star3 0
    set has_email 0
    set approached_email 0
    set has_linkedin 0
    set has_facebook 0
    set has_phone_only 0
    set n_email_sent 0
    set n_email_replied 0

    # States that are "profiled or above"
    set profiled_plus {PROFILED PROFILE_STALE APPROACHED SENT REPLIED}
    # States that are "approached or above"
    set approached_plus {APPROACHED SENT REPLIED}

    foreach contact $classified_contacts {
        set state [dict get $contact state]
        set star [dict get $contact star]
        set c_has_email [dict get $contact has_email]
        set c_has_linkedin [dict get $contact has_linkedin]
        set c_has_facebook [dict get $contact has_facebook]
        set c_has_phone_only [dict get $contact has_phone_only]
        set c_email_sent [dict get $contact email_sent]
        set c_email_replied [dict get $contact email_replied]

        # Valid: not INVALID
        if {$state ne "INVALID"} {
            incr valid
        } else {
            continue
        }

        # Profiled: PROFILED or above
        if {$state in $profiled_plus} {
            incr profiled
        }

        # Star 3+
        if {$star >= 3} {
            incr star3

            # Approached and star3
            if {$state in $approached_plus} {
                incr approached_star3
            }

            # Has email (among star3)
            if {$c_has_email} {
                incr has_email

                # Approached with email (among star3 with email)
                if {$state in $approached_plus} {
                    incr approached_email
                }
            }

            # Has LinkedIn (among star3)
            if {$c_has_linkedin} {
                incr has_linkedin
            }

            # Has Facebook (among star3)
            if {$c_has_facebook} {
                incr has_facebook
            }

            # Has phone only (among star3)
            if {$c_has_phone_only} {
                incr has_phone_only
            }

            # Email sent / replied: only count among star3 with email
            if {$c_has_email && $state in $approached_plus} {
                if {$c_email_sent} {
                    incr n_email_sent
                }
                if {$c_email_replied} {
                    incr n_email_replied
                }
            }
        }
    }

    return [dict create \
        valid $valid \
        profiled $profiled \
        star3 $star3 \
        approached_star3 $approached_star3 \
        has_email $has_email \
        approached_email $approached_email \
        has_linkedin $has_linkedin \
        has_facebook $has_facebook \
        has_phone_only $has_phone_only \
        email_sent $n_email_sent \
        email_replied $n_email_replied]
}

package provide spar-state 1.0
