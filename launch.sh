#!/usr/bin/env bash
# Zenith Shell (Quickshell) launcher & IPC CLI.
#
#   launch.sh start|stop|restart      manage the shell process
#   launch.sh <action>                toggle a surface (see --help)
#
# Keybinds do not go through here: Hyprland-dots binds them to the shell's
# native global shortcuts (hl.dsp.global("zenith:...")), which costs no
# process at all. This script is for terminals, scripts and anything that is
# not the compositor.
set -uo pipefail

SHELL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export ZENITH_ROOT="$SHELL_DIR"
export QML_IMPORT_PATH="$SHELL_DIR"
export QML2_IMPORT_PATH="$SHELL_DIR"

FIFO_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/zenith_fifo"

# Matched on the command line, not the process name: on NixOS the binary is a
# wrapper whose comm is ".quickshell-wra", so `pkill -x quickshell` never
# matched anything and every "restart" started a second shell beside the
# first (two bars, every keybind firing twice).
shell_pids() {
    pgrep -f '^quickshell( |$)' 2>/dev/null
}

is_running() {
    [ -n "$(shell_pids)" ]
}

stop_shell() {
    local pids
    pids="$(shell_pids)"
    [ -n "$pids" ] || return 0
    # shellcheck disable=SC2086
    kill $pids 2>/dev/null
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        is_running || return 0
        sleep 0.1
    done
    # shellcheck disable=SC2086
    kill -9 $(shell_pids) 2>/dev/null || true
}

start_shell() {
    echo "Starting Quickshell..."
    (cd "$SHELL_DIR" && setsid quickshell -d -p "$SHELL_DIR" >/dev/null 2>&1 &)
}

# Fastest first. Writing to the FIFO the shell already reads is a single
# open+write; `quickshell ipc` is a Qt client start-up (~100ms). The FIFO open
# blocks when nobody is reading, so it is bounded by a timeout and falls
# through to ipc, which also covers a shell started from somewhere else.
send_cmd() {
    local cmd="$1"

    if ! is_running; then
        start_shell
        sleep 0.8
    fi

    if [ -p "$FIFO_FILE" ] && timeout 0.3 bash -c 'printf "%s\n" "$1" > "$2"' _ "$cmd" "$FIFO_FILE" 2>/dev/null; then
        return 0
    fi

    local qs_pid
    qs_pid="$(shell_pids | head -1)"
    { [ -n "$qs_pid" ] && quickshell ipc --pid "$qs_pid" call zenith:menu toggle "$cmd" >/dev/null 2>&1; } \
        || quickshell ipc -p "$SHELL_DIR" call zenith:menu toggle "$cmd" >/dev/null 2>&1 \
        || quickshell ipc call zenith:menu toggle "$cmd" >/dev/null 2>&1
}

show_usage() {
    cat <<USAGE
Zenith Shell CLI

Usage: $(basename "$0") <command>

Process:
  start                       Start Quickshell if it is not running
  stop                        Stop Quickshell
  restart | reload            Restart Quickshell
  toggle                      Stop it if running, start it otherwise

Surfaces (each toggles):
  launcher | applauncher      App launcher
  clipboard | clip            Clipboard history
  emoji                       Emoji picker
  dashboard | overview        Dashboard
  dashboard:<tab>             Dashboard on a tab: pomodoro, roadmap, mail, wallpaper
  wallpaper                   Wallpaper tab
  pomodoro | roadmap | mail   Focus / roadmap / mail tabs
  wifi | network              Wi-Fi quick settings
  bluetooth | bt              Bluetooth quick settings
  volume | audio              Audio quick settings
  powerprofile | prof         Power profile quick settings
  battery | pwr               Battery quick settings
  power | sys                 Session / power menu
  settings | config           Settings window
  lock                        Lock the session
  close | close_all           Close every open menu

Any other word is sent to the shell unchanged.
USAGE
}

case "${1:-}" in
    start)
        if is_running; then echo "Quickshell is already running."; else start_shell; fi
        ;;
    stop)
        echo "Stopping Quickshell..."
        stop_shell
        ;;
    restart|reload)
        echo "Restarting Quickshell..."
        stop_shell
        start_shell
        ;;
    toggle)
        if is_running; then echo "Stopping Quickshell..."; stop_shell; else start_shell; fi
        ;;
    ""|-h|--help|help)
        show_usage
        ;;
    *)
        # shell.qml normalises aliases (bt, prof, sys, ...) itself.
        send_cmd "$1"
        ;;
esac
