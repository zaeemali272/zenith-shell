#!/usr/bin/env bash
export PATH="/etc/profiles/per-user/${USER:-$(id -un)}/bin:/run/current-system/sw/bin:$HOME/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

PERC="${1:-50}"
PERC="${PERC%\%}"
if ! [[ "$PERC" =~ ^[0-9]+$ ]]; then
    exit 1
fi
(( PERC < 1 )) && PERC=1
(( PERC > 100 )) && PERC=100

if brightnessctl -c backlight set "${PERC}%" -q >/dev/null 2>&1; then
    exit 0
fi

DEV_PATH=""
for b in /sys/class/backlight/*; do
    if [ -d "$b" ]; then
        DEV_PATH="$b"
        break
    fi
done
[ -n "$DEV_PATH" ] || exit 1

DEV_NAME="$(basename "$DEV_PATH")"
MAX="$(cat "$DEV_PATH/max_brightness" 2>/dev/null || echo 100)"
(( MAX <= 0 )) && MAX=100
RAW=$(( (PERC * MAX + 50) / 100 ))
(( RAW < 1 )) && RAW=1

# Direct sysfs if writable
if [ -w "$DEV_PATH/brightness" ] && echo "$RAW" > "$DEV_PATH/brightness" 2>/dev/null; then
    exit 0
fi

# Fallback: systemd-logind SetBrightness on the active graphical seat session
SID="$(loginctl list-sessions --no-legend 2>/dev/null | awk '$4 != "-" && $4 != "" {print $1; exit}')"
[ -n "$SID" ] || SID="$(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1; exit}')"
if [ -n "$SID" ]; then
    SPATH="$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager GetSession s "$SID" 2>/dev/null | awk '{print $2}' | tr -d '"')"
    if [ -n "$SPATH" ]; then
        busctl call org.freedesktop.login1 "$SPATH" org.freedesktop.login1.Session SetBrightness ssu backlight "$DEV_NAME" "$RAW" >/dev/null 2>&1 && exit 0
    fi
fi

brightnessctl set "${PERC}%" -q >/dev/null 2>&1
