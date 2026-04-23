# spar-manager/ui/settings.tcl
#
# ::spar::ui::settings — persistent config, preflight checks, toolbar
# status indicator, and SPAR Settings dialog.
#
# Toolbar integration: call build_status once after the toolbar frame is
# packed.  The gear button and optional warning label are appended to the
# right side of the given toolbar frame.
#
# Persistent config: two keys (claude_path, mailroom_path) stored as a
# Tcl dict in ~/.spar-config.  These populate ::spar::tool_overrides so
# spar::find_tool picks them up in both UI and CLI mode.

package require Tk

namespace eval ::spar::ui::settings {
    variable Cfg         [dict create claude_path "" mailroom_path ""]
    variable ConfigFile  [file join [file home] .spar-config]
    variable Campaign    ""
    variable StatusLabel ""
    variable GearSep     ""
    variable StatusShown 0
    variable TestRunning 0

    # Textvariables for dialog entries — persist across dialog hide/show.
    variable SmtpUserVar ""
    variable SmtpPassVar ""
    variable claudeVar   ""
    variable mroomVar    ""
}

# ── Config persistence ───────────────────────────────────────────────────

proc ::spar::ui::settings::load_config {} {
    variable Cfg
    variable ConfigFile
    if {![file exists $ConfigFile]} return
    catch {
        set fd [open $ConfigFile r]
        set raw [string trim [read $fd]]
        close $fd
        if {$raw ne ""} { set Cfg $raw }
    }
    set ::spar::tool_overrides $Cfg
}

proc ::spar::ui::settings::save_config {} {
    variable Cfg
    variable ConfigFile
    catch {
        set fd [open $ConfigFile w]
        puts -nonewline $fd $Cfg
        close $fd
    }
    set ::spar::tool_overrides $Cfg
}

# ── Preflight helpers ────────────────────────────────────────────────────

# check_smtp_creds -- 1 if keychain contains a non-empty spar-smtp user entry.
proc ::spar::ui::settings::check_smtp_creds {} {
    global tcl_platform
    switch $tcl_platform(os) {
        "Darwin" {
            if {[catch {exec security find-generic-password -s spar-smtp -w} val]} {
                return 0
            }
            return [expr {[string trim $val] ne ""}]
        }
        "Linux" {
            if {[catch {exec secret-tool lookup service spar-smtp key user} val]} {
                return 0
            }
            return [expr {[string trim $val] ne ""}]
        }
        "Windows NT" {
            set sc {$vault = New-Object Windows.Security.Credentials.PasswordVault; try { ($vault.FindAllByResource('spar-smtp') | Select-Object -First 1).Password } catch { '' }}
            if {[catch {exec powershell -NoProfile -NonInteractive -Command $sc} val]} {
                return 0
            }
            return [expr {[string trim $val] ne ""}]
        }
        default { return 0 }
    }
}

# check_issues campaign -- ordered list of issue strings, highest priority first.
proc ::spar::ui::settings::check_issues {campaign} {
    set issues {}
    if {[spar::find_tool claude] eq ""} { lappend issues "claude not found" }
    set smtp_ok 0
    if {$campaign ne ""} {
        catch {
            set host [$campaign get_smtp_host]
            set smtp_ok [expr {$host ne "" && [check_smtp_creds]}]
        }
    }
    if {!$smtp_ok} { lappend issues "SMTP not configured" }
    if {[spar::find_tool mailroom] eq ""} { lappend issues "mailroom not found" }
    return $issues
}

# ── Toolbar ──────────────────────────────────────────────────────────────

# build_status campaign toolbar_frame -- add warning label + gear button.
proc ::spar::ui::settings::build_status {campaign toolbar_frame} {
    variable Campaign
    variable StatusLabel
    variable GearSep

    set Campaign $campaign
    load_config

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

# recheck -- recompute issues and update the toolbar warning label.
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

# _keychain_available -- 1 if the platform keychain CLI is present.
proc ::spar::ui::settings::_keychain_available {} {
    global tcl_platform
    switch $tcl_platform(os) {
        "Darwin"     { return [expr {[auto_execok security]     ne ""}] }
        "Linux"      { return [expr {[auto_execok secret-tool]  ne ""}] }
        "Windows NT" { return 1 }
        default      { return 0 }
    }
}

# _keychain_install_hint -- human-readable install instruction when unavailable.
proc ::spar::ui::settings::_keychain_install_hint {} {
    global tcl_platform
    switch $tcl_platform(os) {
        "Linux"  { return "sudo apt install libsecret-tools" }
        default  { return "(no keychain tool available on this platform)" }
    }
}

# ── Settings dialog ───────────────────────────────────────────────────────

proc ::spar::ui::settings::show_dialog {} {
    variable Campaign

    if {[winfo exists .sparconfig]} {
        _refresh_dialog
        wm deiconify .sparconfig
        raise .sparconfig
        grab set .sparconfig
        return
    }

    toplevel .sparconfig
    wm title .sparconfig "SPAR Settings"
    wm resizable .sparconfig 0 0
    wm transient .sparconfig .
    wm protocol .sparconfig WM_DELETE_WINDOW \
        {grab release .sparconfig; wm withdraw .sparconfig}

    set f [ttk::frame .sparconfig.f -padding {12 10}]
    pack $f -fill both -expand 1

    _build_smtp_section   $f $Campaign
    _build_tool_section   $f claude "Claude CLI"   claude_path
    _build_tool_section   $f mroom  "Mailroom CLI" mailroom_path

    ttk::frame ${f}.btns
    pack ${f}.btns -fill x -pady {4 0}
    ttk::button ${f}.btns.close -text "Close" \
        -command {grab release .sparconfig; wm withdraw .sparconfig}
    pack ${f}.btns.close -side right

    _refresh_dialog
    grab set .sparconfig
}

proc ::spar::ui::settings::_build_smtp_section {f campaign} {
    set s ${f}.smtp
    ttk::labelframe $s -padding {8 4}
    pack $s -fill x -pady {0 8}
    grid columnconfigure $s 1 -weight 1

    set smtp_host ""
    catch { set smtp_host [$campaign get_smtp_host] }
    set host_text [expr {$smtp_host ne "" ? $smtp_host : "(not set in campaign YAML)"}]

    set keychain_ok [_keychain_available]

    # Keychain-absent banner is the first block — it owns the section.
    if {!$keychain_ok} {
        $s configure -text "⚠ Email (SMTP)"
        ttk::label ${s}.warn -foreground "#b8860b" -anchor w -justify left \
            -text "⚠ Keychain tool not installed.\nRun: [_keychain_install_hint]\nClose and reopen this dialog after installing."
        grid ${s}.warn - -sticky w -padx {4 4} -pady {6 4}
        ttk::separator ${s}.sep -orient horizontal
        grid ${s}.sep - -sticky ew -padx {4 4} -pady {2 4}
    } else {
        $s configure -text "Email (SMTP)"
    }

    # Host row — always shown, read-only.
    ttk::label ${s}.hl -text "SMTP host" -anchor w
    ttk::entry ${s}.hv -state readonly -style Flat.TEntry -takefocus 0
    ${s}.hv configure -state normal
    ${s}.hv insert 0 $host_text
    ${s}.hv configure -state readonly
    grid ${s}.hl ${s}.hv -sticky ew -padx {4 4} -pady 2

    # Credentials — present in both branches, disabled when keychain absent.
    set field_state [expr {$keychain_ok ? "normal" : "disabled"}]

    ttk::label ${s}.ul -text "Username" -anchor w
    ttk::entry ${s}.ue -textvariable ::spar::ui::settings::SmtpUserVar \
        -state $field_state
    grid ${s}.ul ${s}.ue -sticky ew -padx {4 4} -pady 2

    ttk::label ${s}.pl -text "Password" -anchor w
    ttk::entry ${s}.pe -textvariable ::spar::ui::settings::SmtpPassVar \
        -show • -state $field_state
    grid ${s}.pl ${s}.pe -sticky ew -padx {4 4} -pady 2

    # Status label belongs to the keychain-present branch only; the banner
    # subsumes its role in the absent state.
    if {$keychain_ok} {
        ttk::label ${s}.st
        grid ${s}.st - -sticky w -padx {4 4} -pady {2 0}
    }

    ttk::frame ${s}.btns
    if {$keychain_ok} {
        ttk::button ${s}.btns.store -text "Store credentials in keychain" \
            -command ::spar::ui::settings::dialog_store_creds
        ttk::button ${s}.btns.test -text "Test connection" \
            -command ::spar::ui::settings::dialog_test_smtp
    } else {
        ttk::button ${s}.btns.store -text "Store credentials in keychain" \
            -state disabled
        ttk::button ${s}.btns.test -text "Test connection" \
            -state disabled
    }
    grid ${s}.btns - -sticky e -padx {4 4} -pady {4 2}
    pack ${s}.btns.store -side left
    pack ${s}.btns.test  -side left -padx {4 0}

    # Write-traces drive the Store button's dynamic enable. They must not
    # run in the keychain-absent branch, where Store is a permanent stub.
    if {$keychain_ok} {
        trace add variable ::spar::ui::settings::SmtpUserVar write \
            [list apply {{args} {::spar::ui::settings::_update_store_btn}}]
        trace add variable ::spar::ui::settings::SmtpPassVar write \
            [list apply {{args} {::spar::ui::settings::_update_store_btn}}]
    }
}

proc ::spar::ui::settings::_update_store_btn {} {
    variable SmtpUserVar
    variable SmtpPassVar
    variable Campaign
    if {![winfo exists .sparconfig.f.smtp.btns.store]} return
    # Keychain-absent branch: both buttons are permanently disabled stubs.
    if {![_keychain_available]} return
    set host ""
    catch { set host [$Campaign get_smtp_host] }
    set have_creds  [expr {$SmtpUserVar ne "" && $SmtpPassVar ne ""}]
    set have_stored [check_smtp_creds]
    .sparconfig.f.smtp.btns.store configure \
        -state [expr {$have_creds ? "normal" : "disabled"}]
    .sparconfig.f.smtp.btns.test configure \
        -state [expr {($host ne "" && ($have_creds || $have_stored)) ? "normal" : "disabled"}]
}

proc ::spar::ui::settings::_build_tool_section {f id label cfg_key} {
    set s ${f}.$id
    ttk::labelframe $s -text $label -padding {8 4}
    pack $s -fill x -pady {0 8}

    ttk::label  ${s}.pl -text "Path" -anchor w
    ttk::entry  ${s}.pe -textvariable ::spar::ui::settings::${id}Var
    ttk::button ${s}.br -text "Browse…" \
        -command [list ::spar::ui::settings::_browse_tool $id]
    ttk::label  ${s}.st -anchor w

    grid ${s}.pl ${s}.pe ${s}.br -sticky ew -padx {4 4} -pady 2
    grid ${s}.st  -       -      -sticky w  -padx {4 4} -pady {0 4}
    grid columnconfigure $s 1 -weight 1

    set debounce_var ::spar::ui::settings::_deb_$id
    set $debounce_var ""
    trace add variable ::spar::ui::settings::${id}Var write \
        [list apply [list {id s debvar args} {
            after cancel [set $debvar]
            set $debvar [after 300 [list ::spar::ui::settings::_update_tool_status $id $s]]
        }] $id $s $debounce_var]
}

proc ::spar::ui::settings::_update_tool_status {id s} {
    variable Cfg
    if {![winfo exists ${s}.st]} return
    set varname   ::spar::ui::settings::${id}Var
    set path      [string trim [set $varname]]
    set cfg_keys  [dict create claude claude_path mroom mailroom_path]
    set cfg_key   [dict get $cfg_keys $id]
    set titles    [dict create claude "Claude CLI" mroom "Mailroom CLI"]
    set base      [dict get $titles $id]
    set tool_name [expr {$id eq "mroom" ? "mailroom" : $id}]

    # Auto-save: always persist the current entry value (empty or not).
    dict set Cfg $cfg_key $path
    save_config

    if {$path ne "" && [file executable $path]} {
        ${s}.st configure -text "✓ Found: $path" -foreground "#2a7a2a"
        $s configure -text $base
    } elseif {$path ne ""} {
        ${s}.st configure -text "⚠ Not found at that path" -foreground "#b8860b"
        $s configure -text "⚠ $base"
    } else {
        set found [auto_execok $tool_name]
        if {$found ne ""} {
            ${s}.st configure -text "✓ Found on PATH: $found" -foreground "#2a7a2a"
            $s configure -text $base
        } else {
            ${s}.st configure -text "⚠ Not found on PATH" -foreground "#b8860b"
            $s configure -text "⚠ $base"
        }
    }
    recheck
}

proc ::spar::ui::settings::_browse_tool {id} {
    set path [tk_getOpenFile -parent .sparconfig \
        -title "Locate executable" \
        -initialdir [file home]]
    if {$path eq ""} return
    set ::spar::ui::settings::${id}Var $path
}

# _refresh_dialog -- update dialog widgets to reflect current keychain/config state.
proc ::spar::ui::settings::_refresh_dialog {} {
    variable Cfg
    variable SmtpUserVar
    variable SmtpPassVar
    variable claudeVar
    variable mroomVar

    # SMTP: try to pre-fill username from keychain (never pre-fill password)
    set SmtpPassVar ""
    catch {
        global tcl_platform
        switch $tcl_platform(os) {
            "Darwin" {
                set info [exec security find-generic-password -s spar-smtp]
                if {[regexp {"acct"<blob>="([^"]+)"} $info _ u]} {
                    set SmtpUserVar $u
                }
            }
            "Linux" {
                set u [string trim [exec secret-tool lookup service spar-smtp key user]]
                if {$u ne ""} { set SmtpUserVar $u }
            }
        }
    }
    _update_smtp_status

    # Tool paths: pre-fill from stored config
    set claudeVar [spar::dict_get_default $Cfg claude_path  ""]
    set mroomVar  [spar::dict_get_default $Cfg mailroom_path ""]

    after idle [list ::spar::ui::settings::_update_tool_status claude .sparconfig.f.claude]
    after idle [list ::spar::ui::settings::_update_tool_status mroom  .sparconfig.f.mroom]
    after idle ::spar::ui::settings::_update_store_btn
}

# _update_smtp_status ?msg? -- refresh the SMTP status label and section title.
proc ::spar::ui::settings::_update_smtp_status {{msg ""}} {
    if {![winfo exists .sparconfig.f.smtp.st]} return
    set base "Email (SMTP)"

    if {$msg ne ""} {
        set ok [string match "✓*" $msg]
        .sparconfig.f.smtp.st configure -text $msg \
            -foreground [expr {$ok ? "#2a7a2a" : "#b8860b"}]
        .sparconfig.f.smtp configure -text [expr {$ok ? $base : "⚠ $base"}]
        return
    }

    if {[check_smtp_creds]} {
        .sparconfig.f.smtp.st configure \
            -text "✓ Credentials stored in keychain" -foreground "#2a7a2a"
        .sparconfig.f.smtp configure -text $base
    } else {
        .sparconfig.f.smtp.st configure \
            -text "⚠ Not stored in keychain" -foreground "#b8860b"
        .sparconfig.f.smtp configure -text "⚠ $base"
    }
}

# ── Dialog actions ────────────────────────────────────────────────────────

proc ::spar::ui::settings::dialog_store_creds {} {
    variable SmtpUserVar
    variable SmtpPassVar
    variable Campaign
    set user [string trim $SmtpUserVar]
    set pass $SmtpPassVar
    if {$user eq "" || $pass eq ""} return

    if {[catch {store_smtp_credentials $user $pass} err]} {
        _update_smtp_status "⚠ Store failed: $err"
        recheck
        return
    }

    _update_smtp_status "✓ Stored — testing…"
    update idletasks

    set host ""
    set port 587
    catch { set host [$Campaign get_smtp_host] }
    catch {
        set cdata [$Campaign get_cdata]
        if {[dict exists $cdata sender smtp_port]} {
            set port [dict get $cdata sender smtp_port]
        }
    }

    lassign [do_smtp_test $host $port $user $pass] status reason
    if {$status eq "ok"} {
        _update_smtp_status "✓ Stored and verified"
    } else {
        _update_smtp_status "✓ Stored — ⚠ connection test failed: $reason"
    }
    recheck
}

proc ::spar::ui::settings::dialog_test_smtp {} {
    variable TestRunning
    variable Campaign
    variable SmtpUserVar
    variable SmtpPassVar
    if {$TestRunning} return
    set TestRunning 1
    .sparconfig.f.smtp.btns.test configure -text "Testing…" -state disabled

    set host ""
    set port 587
    catch { set host [$Campaign get_smtp_host] }
    catch {
        set cdata [$Campaign get_cdata]
        if {[dict exists $cdata sender smtp_port]} {
            set port [dict get $cdata sender smtp_port]
        }
    }

    # Prefer entry-field credentials; fall back to keychain.
    set user [string trim $SmtpUserVar]
    set pass $SmtpPassVar
    if {$user eq "" || $pass eq ""} {
        catch {
            set creds [::spar::smtp_credentials]
            set user [dict get $creds user]
            set pass [dict get $creds pass]
        }
    }

    if {$host eq ""} {
        _update_smtp_status "⚠ SMTP host not set in campaign YAML"
        _restore_test_btn
        return
    }
    if {$user eq ""} {
        _update_smtp_status "⚠ No credentials to test with"
        _restore_test_btn
        return
    }

    _update_smtp_status "✓ Stored — testing…"
    update idletasks

    lassign [do_smtp_test $host $port $user $pass] status reason
    if {$status eq "ok"} {
        _update_smtp_status "✓ Stored and verified"
    } else {
        _update_smtp_status "✓ Stored — ⚠ connection test failed: $reason"
    }
    recheck
    _restore_test_btn
}

proc ::spar::ui::settings::_restore_test_btn {} {
    variable TestRunning
    set TestRunning 0
    if {[winfo exists .sparconfig.f.smtp.btns.test]} {
        .sparconfig.f.smtp.btns.test configure -text "Test connection"
        _update_store_btn
    }
}

# ── Keychain write ────────────────────────────────────────────────────────

proc ::spar::ui::settings::store_smtp_credentials {user pass} {
    global tcl_platform
    switch $tcl_platform(os) {
        "Darwin" {
            exec security add-generic-password -s spar-smtp \
                -a $user -w $pass -U
        }
        "Linux" {
            if {[auto_execok secret-tool] eq ""} {
                error "secret-tool not installed — run: sudo apt install libsecret-tools"
            }
            set fd [open [list | secret-tool store \
                --label {SPAR SMTP user} service spar-smtp key user] w]
            puts $fd $user; close $fd
            set fd [open [list | secret-tool store \
                --label {SPAR SMTP pass} service spar-smtp key pass] w]
            puts $fd $pass; close $fd
        }
        "Windows NT" {
            set sc [format {
                Add-Type -AssemblyName System.Runtime.WindowsRuntime
                [void][Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime]
                $vault = New-Object Windows.Security.Credentials.PasswordVault
                $c = New-Object Windows.Security.Credentials.PasswordCredential('spar-smtp','%s','%s')
                $vault.Add($c)
            } $user $pass]
            exec powershell -NoProfile -NonInteractive -Command $sc
        }
        default {
            error "unsupported platform: $tcl_platform(os)"
        }
    }
}

# ── SMTP connection test ──────────────────────────────────────────────────

# smtp_test_recv sock expected -- read one SMTP response (possibly multi-line).
proc ::spar::ui::settings::smtp_test_recv {sock expected} {
    set code ""
    set buf  ""
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

    # Async connect with 10-second timeout so the Tk event loop stays live.
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

    # Proceed with blocking SMTP handshake (typically < 2 s).
    fconfigure $sock -blocking 1 -translation crlf -buffering full

    if {[catch {
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
        close $sock
    } err]} {
        catch {close $sock}
        if {[string match "SMTP 535*" $err]} {
            return [list fail "Authentication failed (wrong credentials?)"]
        }
        return [list fail $err]
    }

    return [list ok "Connection verified"]
}
