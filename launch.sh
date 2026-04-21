#!/bin/bash

# Define paths
SHELL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export ZENITH_ROOT="$SHELL_DIR"
LOG_FILE="$SHELL_DIR/zenith.log"

# Set QML import paths
export QML_IMPORT_PATH="$SHELL_DIR"
export QML2_IMPORT_PATH="$SHELL_DIR"

case "$1" in
    wallpaperSelector)
        if pgrep -f "quickshell.*windows/WallpaperWindow.qml" > /dev/null; then
            pkill -f "quickshell.*windows/WallpaperWindow.qml"
            exit 0
        fi
        quickshell -p "$SHELL_DIR/windows/WallpaperWindow.qml" >> "$LOG_FILE" 2>&1 &
        ;;

    overview)
        if pgrep -f "quickshell.*windows/Overview.qml" > /dev/null; then
            pkill -f "quickshell.*windows/Overview.qml"
            exit 0
        fi
        quickshell -p "$SHELL_DIR/windows/Overview.qml" >> "$LOG_FILE" 2>&1 &
        ;;

    *)
        echo "Usage: $0 {wallpaperSelector|overview}"
        exit 1
        ;;
esac