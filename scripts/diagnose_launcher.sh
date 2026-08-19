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
echo "== super tap detector =="
# The launcher is the only action with a tap detector in front of it. Emoji and
# clipboard go through the same launch.sh and the same IPC, so if those work and
# the launcher does not, the problem is here rather than anywhere downstream.
if pgrep -f "super_tap.py" >/dev/null 2>&1; then
    ok "super_tap.py is running"
else
    bad "super_tap.py is NOT running"
    info "it is started from Hyprland's execs.lua; check that config is loaded"
fi

# Whether the devices can actually be read is the thing that matters. Group
# membership is only the usual reason it fails, and it can be misreported inside
# a sandbox or a container, so it is reported as a hint rather than a verdict.
READABLE=0; TOTAL=0
for dev in /dev/input/event*; do
    [ -e "$dev" ] || continue
    TOTAL=$((TOTAL + 1))
    [ -r "$dev" ] && READABLE=$((READABLE + 1))
done

if [ "$TOTAL" -eq 0 ]; then
    bad "no /dev/input/event* devices at all"
elif [ "$READABLE" -eq "$TOTAL" ]; then
    ok "all $TOTAL input devices are readable -- the tap can be seen"
else
    bad "only $READABLE of $TOTAL input devices are readable"
    info "super_tap.py reads these directly; it cannot detect a tap without them."
    if id -nG 2>/dev/null | tr ' ' '\n' | grep -qx input; then
        info "you are in the 'input' group, so this is a udev/permissions issue"
    else
        info "you are not in the 'input' group. NixOS adds it in the system"
        info "configuration; on Arch you have to do it yourself:"
        info "    sudo usermod -aG input \$USER     # then log out and back in"
    fi
fi

echo
echo "== hyprland binds =="
if command -v hyprctl >/dev/null 2>&1; then
    N="$(hyprctl binds 2>/dev/null | grep -c 'key: SUPER_L' || true)"
    info "SUPER_L binds registered: $N (expected 2: press and release)"
    [ "$N" = "2" ] && ok "the keybind half is present" || warn "keybinds.lua may not be loaded"
fi

echo
echo "== summary =="
info "If ipc failed above, that is the cause. Everything else can look healthy"
info "-- including tests/smoke.sh, which talks to the shell by pid, not by path."
