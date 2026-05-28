#!/bin/bash

# Define paths
SHELL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export ZENITH_ROOT="$SHELL_DIR"
LOG_FILE="$SHELL_DIR/zenith.log"

# Set QML import paths
export QML_IMPORT_PATH="$SHELL_DIR"
export QML2_IMPORT_PATH="$SHELL_DIR"

show_usage() {
    echo "Zenith Shell Launch Script"
    echo ""
    echo "Usage: $0 [command] [args]"
    echo ""
    echo "Commands:"
    echo "  keybinds          Toggle the Keybinds tab in Dashboard."
    echo "  cmd <action>      Send a command to the main shell instance."
    echo ""
    echo "Available Cmd Actions:"
    echo "  Overview              Toggle the Overview window."
    echo "  Keybinds              Toggle Keybinds tab in Dashboard."
    echo "  ActionLauncher        Toggle Dashboard (Default)."
    echo "  dashboard:<tab>       Toggle dashboard (tabs: Default, Pomodoro, Wallpaper, Keybinds)."
    echo "  quicksettings:<tab>   Toggle quicksettings (tabs: network, bluetooth, volume, etc)."
    echo ""
    echo "Examples:"
    echo "  $0 keybinds"
    echo "  $0 cmd Overview"
}

case "$1" in
    keybinds)
        echo "Keybinds" > "$HOME/.cache/zenith_command"
        ;;

    cmd)
        if [ -z "$2" ]; then
            show_usage
            exit 1
        fi
        echo "$2" > "$HOME/.cache/zenith_command"
        ;;

    *)
        show_usage
        exit 1
        ;;
esac
