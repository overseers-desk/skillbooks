# Measured figures for `crates/app/src/tmux.rs`

Blind expectation vs measurement (the expectation came from a reader of the README who never saw the code):

| figure | expected | measured |
|---|---|---|
| A | 2 | 1 |
| B | 6 | 30 |
| C | 12 | 327 |
| D | 6 | 4 |

leak (B files the graph did not already count in A): 29  ·  flags: B high, leak signature

Definitions: A = non-test source files outside this one that reference a symbol it defines (from the symbol index, exact). D = non-test files whose symbols it references (its out-degree). B = files of any kind in the tree (.rs, .md, .toml; target/, .git/, .claude/ and Cargo.lock excluded) that mention any word of the module's vocabulary. C = total mentions.

## The module's vocabulary, exactly as the count used it

```
BACKLOG_CAP, BOOTSTRAP_DEADLINE, Capture, Detached, GatewayEvent, HostChanged, Intent, LayoutPanes, PENDING_CAP, PaneGate, RESIZE_DEBOUNCE, TightWire, WindowAdded, WindowClosed, WindowNames, a_bootstrap_no_flagged_reply_ever_answers_is_given_up_at_warn, a_bootstrap_that_was_answered_outlives_the_deadline, a_close_forgets_the_window_and_its_pane, a_pane_switch_reroutes_and_recaptures_into_the_same_channel, a_pane_whose_cursor_never_arrives_stops_banking_and_shows_what_it_has, a_silent_wire_is_not_the_watchdogs_business, a_transport_that_never_drains_bounds_the_queue_and_keeps_the_pairing, a_transport_that_takes_a_prefix_loses_no_command_and_keeps_the_pairing, a_window_add_relists_and_only_the_new_window_is_news, an_errored_capture_still_opens_the_gate, an_errored_capture_takes_its_cursor_down_with_it, attach_window, bootstrapped, control_mode_ended, exit_detaches_and_a_foreign_line_is_the_protocol_lost, finish_pane_bootstrap, flush_client_size, lost_protocol, neutralise_cursor_intent, new_window, queued_bytes, resize_due, sent_size, switch_active_pane, teardown, the_attach_burst_consumes_no_pending_command, the_bootstrap_goes_out_at_construction_with_no_timer, the_first_client_size_flushes_at_once_and_a_burst_settles_to_one, the_listing_becomes_windows_and_the_sweep_corrects_a_late_rename, the_pane_gate_drops_buffers_and_releases_in_the_references_order, tmux, wanted_size, what_tmux_says_to_the_user_is_logged_and_changes_nothing_it_arrives_before
```

## A files (the graph's consumers)

- `crates/app/src/window.rs`

## B files, with sites and the words that produced them

- `crates/app/src/window.rs` — 54 sites: tmux 30, GatewayEvent 8, lost_protocol 7, PENDING_CAP 1, control_mode_ended 1, HostChanged 1, WindowAdded 1, attach_window 1
- `crates/app/tests/tmux_flow.rs` — 47 sites: tmux 47
- `crates/app/src/channels.rs` — 34 sites: tmux 34
- `crates/tmux-cc/tests/support/mod.rs` — 22 sites: tmux 22
- `crates/tmux-cc/examples/record.rs` — 17 sites: tmux 17
- `crates/term/src/tmux_cc.rs` — 17 sites: tmux 17
- `crates/term/src/tmux_pane.rs` — 16 sites: tmux 16
- `crates/tmux-cc/src/event.rs` — 15 sites: tmux 15
- `crates/tmux-cc/src/command.rs` — 11 sites: tmux 11
- `crates/tmux-cc/src/escape.rs` — 11 sites: tmux 11
- `crates/tmux-cc/src/lib.rs` — 10 sites: tmux 10
- `crates/tmux-cc/tests/transcripts.rs` — 9 sites: tmux 9
- `crates/tmux-cc/tests/live_tmux.rs` — 9 sites: tmux 9
- `README.md` — 8 sites: tmux 8
- `crates/tmux-cc/src/codec.rs` — 8 sites: tmux 7, teardown 1
- `crates/tmux-cc/tests/transcripts/README.md` — 6 sites: tmux 6
- `crates/tmux-cc/Cargo.toml` — 5 sites: tmux 5
- `crates/term/src/session.rs` — 5 sites: tmux 5
- `crates/term/src/lib.rs` — 4 sites: tmux 4
- `crates/term/src/dcs.rs` — 4 sites: tmux 4
- `crates/tmux-cc/src/ids.rs` — 3 sites: tmux 3
- `crates/app/Cargo.toml` — 3 sites: tmux 3
- `crates/app/tests/profile_pixels.rs` — 2 sites: tmux 2
- `Cargo.toml` — 1 sites: tmux 1
- `docs/keys.md` — 1 sites: tmux 1
- `crates/term/tests/transcript.rs` — 1 sites: tmux 1
- `crates/term/src/pointer.rs` — 1 sites: tmux 1
- `crates/term/src/bin/esctest_harness.rs` — 1 sites: tmux 1
- `crates/app/src/lib.rs` — 1 sites: tmux 1
- `crates/app/src/overlay.rs` — 1 sites: tmux 1

## Leak files (B minus A)

- `Cargo.toml`
- `README.md`
- `crates/app/Cargo.toml`
- `crates/app/src/channels.rs`
- `crates/app/src/lib.rs`
- `crates/app/src/overlay.rs`
- `crates/app/tests/profile_pixels.rs`
- `crates/app/tests/tmux_flow.rs`
- `crates/term/src/bin/esctest_harness.rs`
- `crates/term/src/dcs.rs`
- `crates/term/src/lib.rs`
- `crates/term/src/pointer.rs`
- `crates/term/src/session.rs`
- `crates/term/src/tmux_cc.rs`
- `crates/term/src/tmux_pane.rs`
- `crates/term/tests/transcript.rs`
- `crates/tmux-cc/Cargo.toml`
- `crates/tmux-cc/examples/record.rs`
- `crates/tmux-cc/src/codec.rs`
- `crates/tmux-cc/src/command.rs`
- `crates/tmux-cc/src/escape.rs`
- `crates/tmux-cc/src/event.rs`
- `crates/tmux-cc/src/ids.rs`
- `crates/tmux-cc/src/lib.rs`
- `crates/tmux-cc/tests/live_tmux.rs`
- `crates/tmux-cc/tests/support/mod.rs`
- `crates/tmux-cc/tests/transcripts.rs`
- `crates/tmux-cc/tests/transcripts/README.md`
- `docs/keys.md`
