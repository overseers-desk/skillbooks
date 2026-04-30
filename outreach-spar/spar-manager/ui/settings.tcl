# spar-manager/ui/settings.tcl
#
# ::spar::ui::settings — toolbar status indicator and SPAR Settings dialog.
#
# There is no per-installation persisted config.  Tool paths (claude,
# mailroom) are pure PATH-presence checks with no override surface.
# The one secret the dialog configures is the SMTP password, which is
# stored in the OS keychain keyed by (smtp_host, smtp_user) — both read
# from the active campaign's YAML under sender:.  The password is
# therefore campaign-scoped via the (host, user) pair, and two campaigns
# that agree on both share a keychain entry while campaigns that differ
# on either get distinct entries.

package require Tk
package require logger

namespace eval ::spar::ui::settings {
    variable Campaign    ""
    variable StatusLabel ""
    variable GearSep     ""
    variable StatusShown 0
    variable TestRunning 0

    # Typed-but-unstored password survives close+reopen of the dialog
    # via this namespace variable.
    variable SmtpPassVar ""

    # Logger service for settings-dialog actions (SMTP test outcome,
    # credential lookup failures). Routed to the LogWindow Tk appender
    # in GUI mode by spar::ui::install_logger_appender.
    variable settings_log [logger::init spar::ui::settings]
}

# ── Keychain install hint (platform-specific, Linux has an actionable one) ──

proc ::spar::ui::settings::_keychain_install_hint {} {
    global tcl_platform
    switch $tcl_platform(os) {
        "Linux"  { return "sudo apt install libsecret-tools" }
        default  { return "" }
    }
}

# ── Preflight checks ────────────────────────────────────────────────────

# check_smtp_creds host user -- 1 iff the keychain holds a password at (host, user).
# Returns 0 on keychain-unavailable hosts regardless of (host, user).
proc ::spar::ui::settings::check_smtp_creds {host user} {
    global tcl_platform
    if {$host eq "" || $user eq ""} { return 0 }
    if {![spar::keychain_available]} { return 0 }
    switch $tcl_platform(os) {
        "Darwin" {
            if {[catch {exec security find-generic-password -s $host -a $user -w} val]} {
                return 0
            }
            return [expr {[string trim $val] ne ""}]
        }
        "Linux" {
            if {[catch {exec secret-tool lookup \
                    protocol smtp server $host user $user} val]} {
                return 0
            }
            return [expr {[string trim $val] ne ""}]
        }
        "Windows NT" {
            set sc "\$v = New-Object Windows.Security.Credentials.PasswordVault; try { (\$v.Retrieve('$host','$user')).Password } catch { '' }"
            if {[catch {exec powershell -NoProfile -NonInteractive -Command $sc} val]} {
                return 0
            }
            return [expr {[string trim $val] ne ""}]
        }
        default { return 0 }
    }
}

# check_issues campaign -- ordered list of issue strings, highest priority first.
# Ordering preserved: claude → SMTP → mailroom.
# SMTP is "configured" when either:
#   (a) keychain_available + (host,user) in YAML + entry in keychain, OR
#   (b) keychain_unavailable + host+user+smtp_pass all in YAML.
proc ::spar::ui::settings::check_issues {campaign} {
    set issues {}
    if {[spar::find_tool claude] eq ""} { lappend issues "claude not found" }
    set smtp_ok 0
    if {$campaign ne ""} {
        catch {
            set host     [$campaign get_smtp_host]
            set user     [$campaign get_smtp_user]
            set has_pass [$campaign get_has_smtp_pass]
            if {$host ne "" && $user ne ""} {
                if {[spar::keychain_available]} {
                    set smtp_ok [check_smtp_creds $host $user]
                } else {
                    set smtp_ok $has_pass
                }
            }
        }
    }
    if {!$smtp_ok} { lappend issues "SMTP not configured" }
    if {[spar::find_tool mailroom] eq ""} { lappend issues "mailroom not found" }
    return $issues
}

# ── Toolbar ──────────────────────────────────────────────────────────────

proc ::spar::ui::settings::build_status {campaign toolbar_frame} {
    variable Campaign
    variable StatusLabel
    variable GearSep

    set Campaign $campaign

    ttk::button ${toolbar_frame}.gear -text "⚙" -width 2 \
        -command ::spar::ui::settings::show_dialog
    pack ${toolbar_frame}.gear -side right -padx {0 2}

    ttk::frame ${toolbar_frame}.gearsep -width 12
    pack ${toolbar_frame}.gearsep -side right

    ttk::label ${toolbar_frame}.status -foreground "#b8860b"

    set StatusLabel ${toolbar_frame}.status
    set GearSep     ${toolbar_frame}.gearsep

    after 1 ::spar::ui::settings::recheck
}

proc ::spar::ui::settings::recheck {} {
    variable Campaign
    variable StatusLabel
    variable GearSep
    variable StatusShown
    if {$Campaign eq "" || $StatusLabel eq ""} return

    set issues [check_issues $Campaign]
    if {[llength $issues] == 0} {
        if {$StatusShown} {
            pack forget $StatusLabel
            set StatusShown 0
        }
        return
    }

    set top   [lindex $issues 0]
    set extra [expr {[llength $issues] - 1}]
    if {$extra == 0} {
        set text "⚠ $top"
    } elseif {$extra == 1} {
        set text "⚠ $top  (+1 other issue)"
    } else {
        set text "⚠ $top  (+$extra other issues)"
    }
    $StatusLabel configure -text $text

    if {!$StatusShown} {
        pack $StatusLabel -side right -before $GearSep -padx {4 8}
        set StatusShown 1
    }
}

# ── Settings dialog ──────────────────────────────────────────────────────

proc ::spar::ui::settings::show_dialog {} {
    variable Campaign

    # Full rebuild on every open. The dialog is small and rebuild lets
    # it reflect (a) newly-installed keychain tools, (b) a freshly-
    # edited campaign YAML — both without a separate refresh path.
    if {[winfo exists .sparconfig]} { destroy .sparconfig }

    toplevel .sparconfig
    wm title .sparconfig "SPAR Settings"
    wm resizable .sparconfig 0 0
    wm transient .sparconfig .
    wm protocol .sparconfig WM_DELETE_WINDOW \
        {grab release .sparconfig; wm withdraw .sparconfig}

    set f [ttk::frame .sparconfig.f -padding {12 10}]
    pack $f -fill both -expand 1

    _build_smtp_section $f $Campaign

    ttk::frame ${f}.btns
    pack ${f}.btns -fill x -pady {4 0}
    ttk::button ${f}.btns.close -text "Close" \
        -command {grab release .sparconfig; wm withdraw .sparconfig}
    pack ${f}.btns.close -side right

    grab set .sparconfig
}

# _build_smtp_section -- the only section. Renders different UIs for two
# top-level branches:
#
# KEYCHAIN-AVAILABLE branch (macOS, Linux-with-secret-tool, Windows-with-
# PasswordVault) — five states:
#   A: host+user in YAML, no password stored yet                 (prompt)
#   B: host+user in YAML, password stored                        (✓)
#   C: host or user missing from YAML                            (banner)
#   E (flag): sender.smtp_pass present in YAML                   (banner;
#             new copy references AI-agent scraping risk)
#
# KEYCHAIN-UNAVAILABLE branch (Linux-without-secret-tool, Windows-without-
# PasswordVault) — two states, no Store / Test buttons at all:
#   F: smtp_pass in YAML — the happy path on this branch         (info)
#   G: smtp_pass missing — broken, YAML edit required            (banner)
#
# Banners stack at the top when more than one applies.
proc ::spar::ui::settings::_build_smtp_section {f campaign} {
    variable SmtpPassVar

    set s ${f}.smtp
    ttk::labelframe $s -padding {8 4}
    pack $s -fill x -pady {0 8}
    grid columnconfigure $s 1 -weight 1

    set smtp_host ""; set smtp_user ""; set has_pass_in_yaml 0
    catch {
        set smtp_host        [$campaign get_smtp_host]
        set smtp_user        [$campaign get_smtp_user]
        set has_pass_in_yaml [$campaign get_has_smtp_pass]
    }

    set keychain_ok [spar::keychain_available]

    if {$keychain_ok} {
        _build_smtp_section_keychain $s $campaign $smtp_host $smtp_user $has_pass_in_yaml
    } else {
        _build_smtp_section_yaml $s $smtp_host $smtp_user $has_pass_in_yaml
    }
}

# _build_smtp_section_keychain -- states A/B/C/E (keychain-available).
proc ::spar::ui::settings::_build_smtp_section_keychain {s campaign smtp_host smtp_user has_pass_in_yaml} {
    variable SmtpPassVar

    set fields_ok [expr {$smtp_host ne "" && $smtp_user ne ""}]
    set banner_shown 0

    # State E banner: sender.smtp_pass is in YAML — AI-leak warning.
    if {$has_pass_in_yaml} {
        ttk::label ${s}.ewarn -foreground "#b8860b" -anchor w -justify left \
            -text "⚠ Insecure: sender.smtp_pass is in campaign.yaml.\nYAML files are often read by AI agents and leaked to AI companies.\nStore a password below, then delete smtp_pass from campaign.yaml."
        grid ${s}.ewarn - -sticky w -padx {4 4} -pady {6 4}
        set banner_shown 1
    }
    # State C banner: host or user missing.
    if {$smtp_host eq "" || $smtp_user eq ""} {
        set missing {}
        if {$smtp_host eq ""} { lappend missing "sender.smtp_host" }
        if {$smtp_user eq ""} { lappend missing "sender.smtp_user" }
        set miss [join $missing " and "]
        ttk::label ${s}.cwarn -foreground "#b8860b" -anchor w -justify left \
            -text "⚠ Campaign YAML is missing $miss.\nEdit campaign.yaml, add the field(s) under sender:,\nthen close and reopen this dialog."
        grid ${s}.cwarn - -sticky w -padx {4 4} -pady {6 4}
        set banner_shown 1
    }
    if {$banner_shown} {
        $s configure -text "⚠ Email (SMTP)"
        ttk::separator ${s}.sep -orient horizontal
        grid ${s}.sep - -sticky ew -padx {4 4} -pady {2 4}
    } else {
        $s configure -text "Email (SMTP)"
    }

    # Body.
    set host_text [expr {$smtp_host ne "" ? $smtp_host : "(not set in campaign YAML)"}]
    set user_text [expr {$smtp_user ne "" ? $smtp_user : "(not set in campaign YAML)"}]

    ttk::label ${s}.hl -text "SMTP host" -anchor w
    ttk::entry ${s}.hv -style Flat.TEntry -takefocus 0
    ${s}.hv insert 0 $host_text
    ${s}.hv configure -state readonly
    grid ${s}.hl ${s}.hv -sticky ew -padx {4 4} -pady 2

    ttk::label ${s}.ul -text "Username" -anchor w
    ttk::entry ${s}.uv -style Flat.TEntry -takefocus 0
    ${s}.uv insert 0 $user_text
    ${s}.uv configure -state readonly
    grid ${s}.ul ${s}.uv -sticky ew -padx {4 4} -pady 2

    set SmtpPassVar ""
    set pe_state [expr {$fields_ok ? "normal" : "disabled"}]
    ttk::label ${s}.pl -text "Password" -anchor w
    ttk::entry ${s}.pe -textvariable ::spar::ui::settings::SmtpPassVar \
        -show • -state $pe_state
    grid ${s}.pl ${s}.pe -sticky ew -padx {4 4} -pady 2

    if {$fields_ok} {
        ttk::label ${s}.st
        grid ${s}.st - -sticky w -padx {4 4} -pady {2 0}
        if {[check_smtp_creds $smtp_host $smtp_user]} {
            ${s}.st configure -text "✓ Password stored in keychain" -foreground "#2a7a2a"
        } else {
            ${s}.st configure -text "⚠ Password not stored in keychain" -foreground "#b8860b"
        }
    }

    ttk::frame ${s}.btns
    if {$fields_ok} {
        ttk::button ${s}.btns.store -text "Store password" \
            -command ::spar::ui::settings::dialog_store_pass
        ttk::button ${s}.btns.test -text "Test connection" \
            -command ::spar::ui::settings::dialog_test_smtp
    } else {
        ttk::button ${s}.btns.store -text "Store password"  -state disabled
        ttk::button ${s}.btns.test  -text "Test connection" -state disabled
    }
    grid ${s}.btns - -sticky e -padx {4 4} -pady {4 2}
    pack ${s}.btns.store -side left
    pack ${s}.btns.test  -side left -padx {4 0}

    if {$fields_ok} {
        trace add variable ::spar::ui::settings::SmtpPassVar write \
            [list apply {{args} {::spar::ui::settings::_refresh_button_states}}]
        _refresh_button_states
    }
}

# _build_smtp_section_yaml -- states F (happy) and G (broken) when no
# keychain is available on this host. No Store/Test buttons; the only
# way to configure is to edit campaign.yaml directly.
proc ::spar::ui::settings::_build_smtp_section_yaml {s smtp_host smtp_user has_pass_in_yaml} {
    set linux_hint [_keychain_install_hint]

    if {$has_pass_in_yaml} {
        # State F — the only working state on a no-keychain host.
        $s configure -text "Email (SMTP)"
        set info "ℹ Password read from campaign.yaml.\nKeychain not available on this system."
        if {$linux_hint ne ""} {
            append info "\n($linux_hint would enable the keychain path.)"
        }
        ttk::label ${s}.info -foreground "#555555" -anchor w -justify left \
            -text $info
        grid ${s}.info - -sticky w -padx {4 4} -pady {6 4}
    } else {
        # State G — broken. No password anywhere.
        $s configure -text "⚠ Email (SMTP)"
        set warn "⚠ Keychain not available on this system, and sender.smtp_pass is not in campaign.yaml.\nAdd smtp_pass under sender: to enable sending.\nThis is a security risk — protect the YAML file."
        if {$linux_hint ne ""} {
            append warn "\n($linux_hint would enable the secure keychain path instead.)"
        }
        ttk::label ${s}.gwarn -foreground "#b8860b" -anchor w -justify left \
            -text $warn
        grid ${s}.gwarn - -sticky w -padx {4 4} -pady {6 4}
        ttk::separator ${s}.sep -orient horizontal
        grid ${s}.sep - -sticky ew -padx {4 4} -pady {2 4}
    }

    set host_text [expr {$smtp_host ne "" ? $smtp_host : "(not set in campaign YAML)"}]
    set user_text [expr {$smtp_user ne "" ? $smtp_user : "(not set in campaign YAML)"}]

    ttk::label ${s}.hl -text "SMTP host" -anchor w
    ttk::entry ${s}.hv -style Flat.TEntry -takefocus 0
    ${s}.hv insert 0 $host_text
    ${s}.hv configure -state readonly
    grid ${s}.hl ${s}.hv -sticky ew -padx {4 4} -pady 2

    ttk::label ${s}.ul -text "Username" -anchor w
    ttk::entry ${s}.uv -style Flat.TEntry -takefocus 0
    ${s}.uv insert 0 $user_text
    ${s}.uv configure -state readonly
    grid ${s}.ul ${s}.uv -sticky ew -padx {4 4} -pady 2
}

# _refresh_button_states -- drive store/test enable state from current
# (SmtpPassVar, stored-credentials) without flipping disabled-by-invariant
# buttons.  Safe to call in any state; no-ops when the buttons don't exist.
proc ::spar::ui::settings::_refresh_button_states {} {
    variable Campaign
    variable SmtpPassVar
    if {![winfo exists .sparconfig.f.smtp.btns.store]} return
    # State D / C guard: when fields aren't OK the buttons were created
    # disabled and have no -command. Leave them alone.
    if {[.sparconfig.f.smtp.btns.store cget -command] eq ""} return

    set host ""; set user ""
    catch {
        set host [$Campaign get_smtp_host]
        set user [$Campaign get_smtp_user]
    }
    set have_typed  [expr {$SmtpPassVar ne ""}]
    set have_stored [check_smtp_creds $host $user]

    # Store: something new to save.
    .sparconfig.f.smtp.btns.store configure \
        -state [expr {$have_typed ? "normal" : "disabled"}]
    # Test: either a typed-but-unstored password, or a stored one.
    .sparconfig.f.smtp.btns.test configure \
        -state [expr {($have_typed || $have_stored) ? "normal" : "disabled"}]
}

# _update_smtp_status -- mutate the in-dialog status label.
proc ::spar::ui::settings::_update_smtp_status {msg ok} {
    if {![winfo exists .sparconfig.f.smtp.st]} return
    .sparconfig.f.smtp.st configure -text $msg \
        -foreground [expr {$ok ? "#2a7a2a" : "#b8860b"}]
    .sparconfig.f.smtp configure \
        -text [expr {$ok ? "Email (SMTP)" : "⚠ Email (SMTP)"}]
}

# ── Dialog actions ────────────────────────────────────────────────────────

proc ::spar::ui::settings::dialog_store_pass {} {
    variable Campaign
    variable SmtpPassVar
    set pass $SmtpPassVar
    if {$pass eq ""} return

    set host ""; set user ""
    catch {
        set host [$Campaign get_smtp_host]
        set user [$Campaign get_smtp_user]
    }
    if {$host eq "" || $user eq ""} {
        _update_smtp_status "⚠ Cannot store: host/user missing from campaign YAML" 0
        return
    }

    if {[catch {store_smtp_credentials $host $user $pass} err]} {
        _update_smtp_status "⚠ Store failed: $err" 0
        recheck
        return
    }

    _update_smtp_status "✓ Stored — testing…" 1
    update idletasks

    set port [$Campaign get_smtp_port]
    lassign [do_smtp_test $host $port $user $pass] status reason
    if {$status eq "ok"} {
        _update_smtp_status "✓ Stored and verified" 1
    } else {
        _update_smtp_status "✓ Stored — ⚠ connection test failed: $reason" 0
    }
    recheck
    _refresh_button_states
}

proc ::spar::ui::settings::dialog_test_smtp {} {
    variable TestRunning
    variable Campaign
    variable SmtpPassVar
    if {$TestRunning} return
    set TestRunning 1
    .sparconfig.f.smtp.btns.test configure -text "Testing…" -state disabled

    set host ""; set user ""
    catch {
        set host [$Campaign get_smtp_host]
        set user [$Campaign get_smtp_user]
    }
    set port 587
    catch { set port [$Campaign get_smtp_port] }

    # Prefer typed password (fresh input); fall back to the stored one.
    set pass $SmtpPassVar
    if {$pass eq ""} {
        catch { set pass [::spar::smtp_credentials $host $user] }
    }

    if {$host eq "" || $user eq ""} {
        _update_smtp_status "⚠ Missing host or username" 0
        _restore_test_btn
        return
    }
    if {$pass eq ""} {
        _update_smtp_status "⚠ No password to test with" 0
        _restore_test_btn
        return
    }

    _update_smtp_status "Testing…" 1
    update idletasks
    lassign [do_smtp_test $host $port $user $pass] status reason
    if {$status eq "ok"} {
        _update_smtp_status "✓ Connection verified" 1
    } else {
        _update_smtp_status "⚠ Connection test failed: $reason" 0
    }
    recheck
    _restore_test_btn
}

proc ::spar::ui::settings::_restore_test_btn {} {
    variable TestRunning
    set TestRunning 0
    if {[winfo exists .sparconfig.f.smtp.btns.test]} {
        .sparconfig.f.smtp.btns.test configure -text "Test connection"
        _refresh_button_states
    }
}

# ── Keychain write ────────────────────────────────────────────────────────

# store_smtp_credentials host user pass -- write password to the OS
# keychain, keyed by (host, user).  Raises on failure (missing tool, etc).
proc ::spar::ui::settings::store_smtp_credentials {host user pass} {
    global tcl_platform
    switch $tcl_platform(os) {
        "Darwin" {
            exec security add-generic-password \
                -s $host -a $user -w $pass -U
        }
        "Linux" {
            if {[auto_execok secret-tool] eq ""} {
                error "secret-tool not installed — run: sudo apt install libsecret-tools"
            }
            set fd [open [list | secret-tool store \
                --label "SPAR $user @ $host" \
                protocol smtp server $host user $user] w]
            puts $fd $pass
            close $fd
        }
        "Windows NT" {
            set sc [format {
                Add-Type -AssemblyName System.Runtime.WindowsRuntime
                [void][Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime]
                $vault = New-Object Windows.Security.Credentials.PasswordVault
                $c = New-Object Windows.Security.Credentials.PasswordCredential('%s','%s','%s')
                $vault.Add($c)
            } $host $user $pass]
            exec powershell -NoProfile -NonInteractive -Command $sc
        }
        default {
            error "unsupported platform: $tcl_platform(os)"
        }
    }
}

# ── SMTP connection test ──────────────────────────────────────────────────

# smtp_test_recv sock expected -- read one SMTP response (may be multi-line).
proc ::spar::ui::settings::smtp_test_recv {sock expected} {
    set code ""; set buf ""
    while 1 {
        set line [gets $sock]
        if {[eof $sock]} { error "connection closed unexpectedly" }
        set code [string range $line 0 2]
        append buf $line "\n"
        if {[string length $line] < 4 || [string index $line 3] ne "-"} break
    }
    if {$code ne $expected} {
        error "SMTP $code (expected $expected): [string trim $buf]"
    }
    return $buf
}

# do_smtp_test host port user pass -- async connect + blocking handshake.
# Returns {ok reason} or {fail reason}.
proc ::spar::ui::settings::do_smtp_test {host port user pass} {
    if {[catch {package require tls}]} {
        return [list fail "TLS package (tcl-tls) not installed"]
    }

    set vname ::spar_smtptest_[clock microseconds]
    set $vname pending

    if {[catch {set sock [socket -async $host $port]} err]} {
        return [list fail "Cannot create socket: $err"]
    }

    set tid [after 10000 [list set $vname timeout]]
    fileevent $sock writable [list set $vname connected]
    vwait $vname
    fileevent $sock writable {}
    after cancel $tid

    set st [set $vname]
    unset $vname

    if {$st eq "timeout"} {
        catch {close $sock}
        return [list fail "Connection timed out (10 s)"]
    }

    set cerr [fconfigure $sock -error]
    if {$cerr ne ""} {
        catch {close $sock}
        return [list fail "Connection refused: $cerr"]
    }

    fconfigure $sock -blocking 1 -translation crlf -buffering full

    try {
        smtp_test_recv $sock 220

        puts $sock "EHLO spar-manager"; flush $sock
        smtp_test_recv $sock 250

        if {$port == 587 || $port == 2587} {
            puts $sock "STARTTLS"; flush $sock
            smtp_test_recv $sock 220
            tls::import $sock -server 0 -servername $host
            fconfigure $sock -blocking 1 -translation crlf -buffering full
            puts $sock "EHLO spar-manager"; flush $sock
            smtp_test_recv $sock 250
        }

        puts $sock "AUTH LOGIN"; flush $sock
        smtp_test_recv $sock 334
        puts $sock [binary encode base64 $user]; flush $sock
        smtp_test_recv $sock 334
        puts $sock [binary encode base64 $pass]; flush $sock
        smtp_test_recv $sock 235

        puts $sock "QUIT"; flush $sock
        catch {smtp_test_recv $sock 221}
    } on error {err} {
        if {[string match "SMTP 535*" $err]} {
            ${::spar::ui::settings::settings_log}::warn \
                "SMTP test failed: authentication rejected ($host:$port as $user)"
            return [list fail "Authentication failed (wrong credentials?)"]
        }
        ${::spar::ui::settings::settings_log}::warn \
            "SMTP test failed: $err ($host:$port as $user)"
        return [list fail $err]
    } finally {
        catch {close $sock}
    }

    ${::spar::ui::settings::settings_log}::info \
        "SMTP test ok: $host:$port as $user"
    return [list ok "Connection verified"]
}
