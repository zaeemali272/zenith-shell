#!/bin/bash

# Define paths
SHELL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export ZENITH_ROOT="$SHELL_DIR"
LOG_FILE="$SHELL_DIR/zenith.log"

# Set QML import paths
export QML_IMPORT_PATH="$SHELL_DIR"
export QML2_IMPORT_PATH="$SHELL_DIR"

case "$1" in
    overview)
        if pgrep -f "quickshell.*windows/Overview.qml" > /dev/null; then
            pkill -f "quickshell.*windows/Overview.qml"
            exit 0
        fi
        quickshell -p "$SHELL_DIR/windows/Overview.qml" >> "$LOG_FILE" 2>&1 &
        ;;

    cheatsheet)
        if pgrep -f "quickshell.*windows/Cheatsheet.qml" > /dev/null; then
            pkill -f "quickshell.*windows/Cheatsheet.qml"
            exit 0
        fi
        quickshell -p "$SHELL_DIR/windows/Cheatsheet.qml" >> "$LOG_FILE" 2>&1 &
        ;;

    actionLauncher)
        if pgrep -f "quickshell.*windows/ActionLauncher.qml" > /dev/null; then
            pkill -f "quickshell.*windows/ActionLauncher.qml"
            exit 0
        fi
        quickshell -p "$SHELL_DIR/windows/ActionLauncher.qml" >> "$LOG_FILE" 2>&1 &
        ;;

    cmd)
        if [ -z "$2" ]; then
            echo "Usage: $0 cmd <command>"
            echo "Example: $0 cmd dashboard:Wallpaper"
            exit 1
        fi
        echo "$2" > "$HOME/.cache/zenith_command"
        ;;

    *)
        echo "Usage: $0 {overview|cheatsheet|actionLauncher|cmd}"
        exit 1
        ;;
esac