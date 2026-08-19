#!/usr/bin/env bash
# Why is the launcher not opening?
#
# The Super key does not talk to the shell directly. The chain is:
#
#   SUPER_L  ->  super_launcher.sh  ->  launch.sh  ->  quickshell ipc -p <dir>
#
# and `-p` selects the running instance *by the config path it was started
# with*. If the shell was launched from a different path than the one
# launch.sh computes -- a symlink on one machine and a real directory on
# another -- the IPC call matches nothing and the key silently does nothing,
# while everything else about the shell works fine.
set -uo pipefail

SHELL_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
ok()   { printf '  \033[1;32mok\033[0m    %s\n' "$*"; }
bad()  { printf '  \033[1;31mFAIL\033[0m  %s\n' "$*"; }
warn() { printf '  \033[1;33m!!\033[0m    %s\n' "$*"; }
info() { printf '        %s\n' "$*"; }

echo "== shell process =="
PIDS="$(pgrep -f 'quickshell' | tr '\n' ' ')"
if [ -z "$PIDS" ]; then
    bad "quickshell is not running"
    info "start it:  quickshell -d -p $SHELL_DIR"
    exit 1
fi
ok "running (pid $PIDS)"
for p in $PIDS; do
    info "$(tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null)"
done

echo
echo "== config paths =="
info "launch.sh will use:  $SHELL_DIR"
info "~/.config/quickshell: $(readlink -f "$HOME/.config/quickshell" 2>/dev/null || echo '(absent)')"
if [ "$(readlink -f "$HOME/.config/quickshell" 2>/dev/null)" = "$SHELL_DIR" ]; then
    ok "they resolve to the same directory"
else
    warn "they differ -- 'quickshell ipc -p' may not match the running instance"
fi

echo
echo "== ipc =="
if ! command -v quickshell >/dev/null 2>&1; then
    bad "the 'quickshell' binary is not on PATH"
    command -v qs >/dev/null 2>&1 && info "but 'qs' is -- this build names it differently, launch.sh calls 'quickshell'"
    exit 1
fi
ok "quickshell binary found: $(command -v quickshell)"

if quickshell ipc -p "$SHELL_DIR" call zenith:menu toggle launcher >/dev/null 2>&1; then
    ok "ipc -p '$SHELL_DIR' works  <- the launcher should open now"
    quickshell ipc -p "$SHELL_DIR" call zenith:menu toggle close >/dev/null 2>&1
else
    bad "ipc -p '$SHELL_DIR' does NOT reach the running shell"
    info "this is the failure. The shell is running from a different path."
    for p in $PIDS; do
        if quickshell ipc --pid "$p" call zenith:menu toggle launcher >/dev/null 2>&1; then
            ok "but --pid $p works"
            info "fix: start the shell from $SHELL_DIR, or point"
            info "     ~/.config/quickshell at it:"
            info "     ln -sfn $SHELL_DIR ~/.config/quickshell"
            quickshell ipc --pid "$p" call zenith:menu toggle close >/dev/null 2>&1
            break
        fi
    done
fi

echo
echo "== key binding =="
if command -v hyprctl >/dev/null 2>&1; then
    if hyprctl binds 2>/dev/null | grep -q "SUPER_L"; then
        ok "SUPER_L is bound in Hyprland"
    else
        bad "SUPER_L is not bound -- the Hyprland keybinds are not loaded"
        info "check that Hyprland-dots keybinds.lua is being sourced"
    fi
else
    warn "hyprctl not available; cannot check the binding"
fi

echo
echo "== tap detector =="
STATE="${XDG_RUNTIME_DIR:-/tmp}/zenith_super"
if "$SHELL_DIR/scripts/super_launcher.sh" press >/dev/null 2>&1 && [ -f "$STATE/press_time" ]; then
    ok "super_launcher.sh records a press ($STATE)"
    rm -f "$STATE/press_time" "$STATE/combo_flag"
else
    bad "super_launcher.sh cannot write its state to $STATE"
    info "XDG_RUNTIME_DIR is ${XDG_RUNTIME_DIR:-unset}"
fi

echo
echo "== summary =="
info "If ipc failed above, that is the cause. Everything else can look healthy"
info "-- including tests/smoke.sh, which talks to the shell by pid, not by path."
