#!/usr/bin/env bash
# Power profile switch helper for zenith-shell.
# Handles switching profiles even when invoked from a daemonized / detached
# process context where polkit might otherwise deny direct D-Bus access.
set -euo pipefail

cmd="${1:-get}"
target="${2:-}"

case "$cmd" in
    get)
        powerprofilesctl get 2>/dev/null || echo "balanced"
        ;;
    set)
        if [ -z "$target" ]; then
            echo "Usage: $0 set <performance|balanced|power-saver|powersave|turbo>" >&2
            exit 1
        fi

        case "$target" in
            powersave) target="power-saver" ;;
            turbo) target="performance" ;;
        esac

        # 1. Direct powerprofilesctl call (fastest if polkit session matches)
        if powerprofilesctl set "$target" 2>/dev/null; then
            exit 0
        fi

        # 2. systemd-run --user (executes within user session slice, authorized by polkit)
        if command -v systemd-run >/dev/null 2>&1; then
            if systemd-run --user -q --wait powerprofilesctl set "$target" 2>/dev/null; then
                exit 0
            fi
        fi

        # 3. Direct D-Bus call to org.freedesktop.UPower.PowerProfiles
        if command -v busctl >/dev/null 2>&1; then
            if busctl call org.freedesktop.UPower.PowerProfiles /org/freedesktop/UPower/PowerProfiles org.freedesktop.DBus.Properties Set "ssv" org.freedesktop.UPower.PowerProfiles ActiveProfile s "$target" 2>/dev/null; then
                exit 0
            fi
        fi

        # 4. Final attempt with error propagation
        powerprofilesctl set "$target"
        ;;
    list)
        powerprofilesctl list 2>/dev/null || true
        ;;
    *)
        echo "Usage: $0 [get|set <profile>|list]" >&2
        exit 1
        ;;
esac
