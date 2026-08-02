#!/usr/bin/env bash
# Zenith Shell (Quickshell) Launcher & IPC CLI

SHELL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export ZENITH_ROOT="$SHELL_DIR"
export QML_IMPORT_PATH="$SHELL_DIR"
export QML2_IMPORT_PATH="$SHELL_DIR"

FIFO_FILE="$HOME/.cache/zenith_command"

# Ensure FIFO file directory exists
if [ ! -d "$HOME/.cache" ]; then
    mkdir -p "$HOME/.cache"
fi

is_running() {
    pidof quickshell >/dev/null 2>&1 || pgrep -f "quickshell" >/dev/null 2>&1
}

send_cmd() {
    local cmd="$1"
    if ! is_running; then
        echo "Starting Quickshell..."
        quickshell -d -p "$SHELL_DIR" &
        sleep 0.6
    fi
    echo "$cmd" > "$FIFO_FILE" 2>/dev/null || echo "$cmd" >> "$FIFO_FILE"
}

show_usage() {
    echo "Zenith Shell CLI & IPC Launch Script"
    echo ""
    echo "Usage: $0 [command/action]"
    echo ""
    echo "Actions:"
    echo "  dashboard | overview      Toggle Dashboard"
    echo "  wallpaper                 Toggle Wallpaper tab"
    echo "  pomodoro                  Toggle Pomodoro tab"
    echo "  wifi | network            Toggle Wi-Fi QuickSettings"
    echo "  bluetooth | bt            Toggle Bluetooth QuickSettings"
    echo "  volume | audio            Toggle Volume QuickSettings"
    echo "  powerprofile | prof       Toggle Power Profile QuickSettings"
    echo "  battery | pwr             Toggle Battery QuickSettings"
    echo "  power | sys               Toggle Power System QuickSettings"
    echo "  close                     Close all open menus/popups"
    echo "  cmd <raw_cmd>             Send raw IPC command"
    echo ""
    echo "Process Control:"
    echo "  start                     Start Quickshell in background"
    echo "  stop | kill               Terminate Quickshell"
    echo "  restart | reload          Restart Quickshell"
}

case "$1" in
    help|-h|--help)
        show_usage
        ;;
    dashboard|overview|ActionLauncher|Overview)
        send_cmd "dashboard:Default"
        ;;
    wallpaper|wallpapers)
        send_cmd "wallpaper"
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
    cmd)
        if [ -n "$2" ]; then
            case "$2" in
                Overview|ActionLauncher) send_cmd "dashboard:Default" ;;
                *) send_cmd "$2" ;;
            esac
        else
            show_usage
            exit 1
        fi
        ;;
    start)
        if is_running; then
            echo "Quickshell is already running."
        else
            echo "Starting Quickshell..."
            quickshell -d -p "$SHELL_DIR" &
        fi
        ;;
    stop|kill)
        echo "Stopping Quickshell..."
        pkill -f quickshell
        ;;
    restart|reload)
        echo "Restarting Quickshell..."
        pkill -f quickshell
        sleep 0.3
        quickshell -d -p "$SHELL_DIR" &
        ;;
    "")
        show_usage
        ;;
    *)
        # Fallback: send arg directly as IPC command
        send_cmd "$1"
        ;;
esac
