#!/usr/bin/env tclsh9.0
# Tests for spar::transcript_assistant_text — the A harness sources the
# author's draft markers from the full transcript, not the envelope's final
# `result` text. Regression for #145: a post-draft turn (e.g. a Stop hook
# reacting to a `#N` token the draft quoted) displaces the final text, so
# reading only `result` loses an already-written draft.

set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir test-helpers.tcl]
source [file join $script_dir .. spar-lib.tcl]

section "transcript_assistant_text + extract_between"

# Write a JSONL transcript fixture to a temp file and return its path.
proc write_transcript {lines} {
    set dir [make_temp_dir]
    set path [file join $dir author-draft.log.json]
    set fd [open $path w]
    foreach l $lines { puts $fd $l }
    close $fd
    return $path
}

# #145 scenario: assistant emits the draft, a Stop hook injects a user turn,
# the assistant replies without markers, and that reply is the envelope result.
set f [write_transcript [list \
    {{"type":"system","subtype":"init","session_id":"abc"}} \
    {{"type":"assistant","message":{"content":[{"type":"text","text":"I'll read the files first."}]}}} \
    {{"type":"assistant","message":{"content":[{"type":"text","text":"RATIONALE_START\nWarmth: cold.\nRATIONALE_END\n\nDRAFT_START\nBen, worth pitching as a story?\nDRAFT_END"}]}}} \
    {{"type":"user","message":{"content":[{"type":"text","text":"Stop hook feedback: your last message referenced #5."}]}}} \
    {{"type":"assistant","message":{"content":[{"type":"text","text":"The only #5 was a podcast episode. Nothing to post."}]}}} \
    {{"type":"result","result":"The only #5 was a podcast episode. Nothing to post."}} \
]]

set text [spar::transcript_assistant_text $f]
set draft [spar::extract_between $text "DRAFT_START" "DRAFT_END"]
set rationale [spar::extract_between $text "RATIONALE_START" "RATIONALE_END"]

assert_eq $draft "Ben, worth pitching as a story?" \
    "draft recovered from transcript despite a post-draft Stop-hook turn"
assert_eq $rationale "Warmth: cold." \
    "rationale recovered from transcript"

# Absent file → empty string, no error.
assert_eq [spar::transcript_assistant_text /nonexistent/x.json] "" \
    "missing transcript → empty string"

# A malformed (non-JSON) line is skipped, not fatal — the draft still parses.
set f2 [write_transcript [list \
    {not valid json} \
    {{"type":"assistant","message":{"content":[{"type":"text","text":"DRAFT_START\nhi\nDRAFT_END"}]}}} \
    {{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Read","input":{}}]}}} \
]]
assert_eq [spar::extract_between [spar::transcript_assistant_text $f2] "DRAFT_START" "DRAFT_END"] "hi" \
    "malformed line skipped; non-text blocks ignored"

finish_tests
