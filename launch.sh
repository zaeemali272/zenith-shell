#!/bin/bash

# Define paths
# Get the directory where the script is stored
SHELL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export ZENITH_ROOT="$SHELL_DIR"
LOG_FILE="$SHELL_DIR/zenith.log"

case "$1" in
    wallpaperSelector)
        # Toggle logic: if it's already running, kill it and exit
        if pgrep -f "quickshell --path $SHELL_DIR/windows/WallpaperWindow.qml" > /dev/null; then
            pkill -f "quickshell --path $SHELL_DIR/windows/WallpaperWindow.qml"
            echo "[$(date +%T)] Wallpaper Selector closed via toggle" >> "$LOG_FILE"
            exit 0
        fi

        # Otherwise, launch it
        echo "[$(date +%T)] Launching Wallpaper Selector..." >> "$LOG_FILE"
        quickshell --path "$SHELL_DIR/windows/WallpaperWindow.qml" >> "$LOG_FILE" 2>&1
        ;;
    
    *)
        echo "Usage: $0 {wallpaperSelector}"
        exit 1
        ;;
esac