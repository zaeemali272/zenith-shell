#!/usr/bin/env bash
# Zenith Shell (Quickshell) Launcher & IPC CLI

SHELL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export ZENITH_ROOT="$SHELL_DIR"
export QML_IMPORT_PATH="$SHELL_DIR"
export QML2_IMPORT_PATH="$SHELL_DIR"

FIFO_FILE="$HOME/.cache/zenith_fifo"

# Ensure FIFO file directory exists
if [ ! -d "$HOME/.cache" ]; then
    mkdir -p "$HOME/.cache"
fi

if [ ! -p "$FIFO_FILE" ]; then
    rm -f "$FIFO_FILE"
    mkfifo "$FIFO_FILE" 2>/dev/null || touch "$FIFO_FILE"
fi

COMBO_FILE="$HOME/.cache/zenith_last_combo"

mark_combo() {
    python3 -c "import time; print(int(time.time()*1000))" > "$COMBO_FILE" 2>/dev/null || date +%s%3N > "$COMBO_FILE" 2>/dev/null || true
}

is_recent_combo() {
    if [ -f "$COMBO_FILE" ]; then
        local last_time
        last_time=$(cat "$COMBO_FILE" 2>/dev/null || echo 0)
        local now
        now=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || date +%s%3N 2>/dev/null || echo 0)
        local diff=$((now - last_time))
        if [ "$diff" -ge 0 ] && [ "$diff" -lt 550 ]; then
            return 0
        fi
    fi
    return 1
}

is_running() {
    pgrep -x "quickshell" >/dev/null 2>&1 || pgrep -x ".quickshell-wra" >/dev/null 2>&1 || pgrep -f "quickshell" >/dev/null 2>&1
}

send_cmd() {
    local cmd="$1"
    if [ "$cmd" != "launcher" ]; then
        "$SHELL_DIR/scripts/super_launcher.sh" mark_combo 2>/dev/null || true
        mark_combo
    fi
    if ! is_running; then
        echo "Starting Quickshell..."
        quickshell -d -p "$SHELL_DIR" &
        sleep 0.6
    fi
    quickshell ipc -p "$SHELL_DIR" call zenith:menu toggle "$cmd" 2>/dev/null || \
    quickshell ipc call zenith:menu toggle "$cmd" 2>/dev/null || \
    python3 -c "import os, sys; p=sys.argv[1]; c=sys.argv[2]; f=os.open(p, os.O_WRONLY|os.O_NONBLOCK); os.write(f, (c+'\n').encode()); os.close(f)" "$FIFO_FILE" "$cmd" 2>/dev/null || \
    (echo "$cmd" > "$FIFO_FILE" 2>/dev/null &)
}


show_usage() {
    echo "Zenith Shell CLI & IPC Launch Script"
    echo ""
    echo "Usage: $0 [command/action]"
    echo ""
    echo "Actions:"
    echo "  launcher | applauncher     Toggle App Launcher"
    echo "  clipboard | clip | cliphist Toggle Clipboard Manager"
    echo "  emoji | emojis             Toggle Emoji Selector"
    echo "  dashboard | overview      Toggle Dashboard"
    echo "  wallpaper                 Toggle Wallpaper tab"
    echo "  pomodoro                  Toggle Pomodoro tab"
    echo "  wifi | network            Toggle Wi-Fi QuickSettings"
    echo "  bluetooth | bt            Toggle Bluetooth QuickSettings"
    echo "  volume | audio            Toggle Volume QuickSettings"
    echo "  powerprofile | prof       Toggle Power Profile QuickSettings"
    echo "  battery | pwr             Toggle Battery QuickSettings"
    echo "  power | sys               Toggle Power Menu"
    echo "  close | close_all         Close all active menus"
    echo "  restart | reload          Restart Quickshell"
    echo "  stop                      Stop Quickshell"
    echo ""
}

case "$1" in
    start)
        if ! is_running; then
            echo "Starting Quickshell..."
            quickshell -d -p "$SHELL_DIR" &
        else
            echo "Quickshell is already running."
        fi
        ;;
    stop)
        echo "Stopping Quickshell..."
        pkill -f quickshell
        ;;
    restart|reload)
        echo "Restarting Quickshell..."
        pkill -f quickshell
        sleep 0.3
        quickshell -d -p "$SHELL_DIR" &
        ;;
    launcher|applauncher|Launcher)
        if is_recent_combo; then
            exit 0
        fi
        send_cmd "launcher"
        ;;
    mark_combo|combo)
        mark_combo
        ;;

    clipboard|clip|cliphist|Clipboard)
        send_cmd "clipboard"
        ;;
    emoji|emojis|emojiselector|Emoji)
        send_cmd "emoji"
        ;;
    pomodoro)
        send_cmd "pomodoro"
        ;;
    wifi|network)
        send_cmd "wifi"
        ;;
    bluetooth|bt)
        send_cmd "bluetooth"
        ;;
    volume|audio)
        send_cmd "volume"
        ;;
    powerprofile|prof)
        send_cmd "powerprofile"
        ;;
    battery|pwr)
        send_cmd "battery"
        ;;
    power|sys)
        send_cmd "power"
        ;;
    close|close_all)
        send_cmd "close_all"
        ;;
    settings)
        send_cmd "settings"
        ;;
    "")
        show_usage
        ;;
    *)
        # Fallback: send arg directly as IPC command
        send_cmd "$1"
        ;;
esac
