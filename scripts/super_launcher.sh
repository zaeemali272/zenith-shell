#!/usr/bin/env bash
# Dedicated Zenith Super Key Tap Detector

SHELL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/zenith_super"
mkdir -p "$STATE_DIR"

PRESS_FILE="$STATE_DIR/press_time"
COMBO_FILE="$STATE_DIR/combo_flag"

ACTION="${1:-release}"

get_time_ms() {
    python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || date +%s%3N 2>/dev/null || echo 0
}

case "$ACTION" in
    press)
        get_time_ms > "$PRESS_FILE"
        echo "0" > "$COMBO_FILE"
        ;;
    combo|mark_combo)
        echo "1" > "$COMBO_FILE"
        ;;
    release)
        combo=$(cat "$COMBO_FILE" 2>/dev/null || echo 0)
        if [ "$combo" -eq 1 ]; then
            echo "0" > "$COMBO_FILE"
            exit 0
        fi

        press_time=$(cat "$PRESS_FILE" 2>/dev/null || echo 0)
        now=$(get_time_ms)
        diff=$((now - press_time))

        # Reset state
        echo "0" > "$PRESS_FILE"
        echo "0" > "$COMBO_FILE"

        # If tap duration was under 600ms and not combined with another key
        if [ "$press_time" -eq 0 ] || ([ "$diff" -ge 15 ] && [ "$diff" -le 600 ]); then
            "$SHELL_DIR/launch.sh" launcher
        fi
        ;;
esac
