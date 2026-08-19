#!/usr/bin/env bash
# Loads the shell in a headless nested compositor and clicks through every
# menu, failing on a crash or a QML error.
#
# This exists because qmllint cannot see any of it. The bugs that shipped were
# all things that parse perfectly: a handler that could never fire, a model
# accessor that was always undefined, a layout binding that re-entered the
# engine and segfaulted. Loading it and driving it is the only thing that
# catches those.
#
# Cleans up only the processes it started. Never touches a running shell.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d -t zenith-smoke-XXXXXX)"
HYPR_PID=""
QS_PID=""
FAILED=0

cleanup() {
    [ -n "$QS_PID" ] && kill "$QS_PID" 2>/dev/null
    # quickshell re-execs itself as a daemon, so the pid we spawned is not
    # necessarily the one still running.
    [ -n "${QS_REAL:-}" ] && kill "$QS_REAL" 2>/dev/null
    [ -n "$HYPR_PID" ] && kill "$HYPR_PID" 2>/dev/null
    sleep 0.5
    rm -rf "$WORK"
}
trap cleanup EXIT

fail() { echo "  FAIL  $*"; FAILED=1; }
pass() { echo "  PASS  $*"; }

command -v Hyprland >/dev/null 2>&1 || { echo "  SKIP  Hyprland not available"; exit 0; }
command -v quickshell >/dev/null 2>&1 || { echo "  SKIP  quickshell not available"; exit 0; }

# Reuse the compositor already running when there is one. Starting a nested
# Hyprland needs capabilities a sandboxed shell or CI runner may not have, and
# there is no reason to when a session is right there.
if [ -n "${WAYLAND_DISPLAY:-}" ] && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    DISPLAY_NAME="$WAYLAND_DISPLAY"
    # The signature in the environment goes stale when Hyprland restarts, so
    # prefer the newest live instance directory when one exists.
    SIG="$(ls -t "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr" 2>/dev/null | head -1)"
    [ -z "$SIG" ] && SIG="$HYPRLAND_INSTANCE_SIGNATURE"
    REUSED=1
    pass "using the running compositor ($DISPLAY_NAME)"
    echo "  NOTE  a second bar appears on screen for about 30s; your own shell is untouched"
else
    REUSED=0
    cat > "$WORK/hypr.conf" <<'CONF'
monitor = HEADLESS-1,1920x1080@60,0x0,1
animations {
    enabled = false
}
decoration {
    blur {
        enabled = false
    }
}
misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
}
CONF

    RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    ls "$RUNTIME" 2>/dev/null | grep -E '^wayland-[0-9]+$' | sort > "$WORK/before"

    AQ_BACKENDS=headless AQ_HEADLESS_OUTPUTS=1 WLR_BACKENDS=headless \
        setsid Hyprland -c "$WORK/hypr.conf" > "$WORK/hypr.log" 2>&1 &
    HYPR_PID=$!

    DISPLAY_NAME=""
    for _ in $(seq 1 40); do
        ls "$RUNTIME" 2>/dev/null | grep -E '^wayland-[0-9]+$' | sort > "$WORK/after"
        DISPLAY_NAME="$(comm -13 "$WORK/before" "$WORK/after" | head -1)"
        [ -n "$DISPLAY_NAME" ] && break
        sleep 0.5
    done
    if [ -z "$DISPLAY_NAME" ]; then
        echo "  SKIP  no compositor available and could not start one:"
        tail -5 "$WORK/hypr.log" | sed "s/^/          /"
        exit 0
    fi
    pass "nested compositor up on $DISPLAY_NAME"
fi


# Whatever is already running belongs to the user. quickshell re-execs itself
# as a daemon, so the pid we spawn is not the pid that survives -- the new
# instance has to be identified by diffing against this list. Picking
# `pgrep quickshell | head -1` instead returns the *oldest* shell, which is the
# user's bar, and the cleanup below then kills it.
pgrep -f "quickshell" 2>/dev/null | sort > "$WORK/shells_before" || true

WAYLAND_DISPLAY="$DISPLAY_NAME" HYPRLAND_INSTANCE_SIGNATURE="$SIG" \
QT_QPA_PLATFORM=wayland ZENITH_ROOT="$REPO" QML_IMPORT_PATH="$REPO" \
    quickshell -p "$REPO" > "$WORK/qs.log" 2>&1 &
QS_PID=$!
echo "  ....  starting a test instance"
sleep 8

pgrep -f "quickshell" 2>/dev/null | sort > "$WORK/shells_after" || true
QS_REAL="$(comm -13 "$WORK/shells_before" "$WORK/shells_after" | head -1)"
if [ -z "$QS_REAL" ]; then
    fail "shell did not start"
    sed -e 's/\x1b\[[0-9;]*m//g' "$WORK/qs.log" | tail -15
    exit 1
fi
pass "test instance is pid $QS_REAL (pre-existing shells untouched)"

grep -q "Configuration Loaded" "$WORK/qs.log" \
    && pass "configuration loaded" || fail "configuration did not load"

# Every menu surface, including the sub-tools inside Focus.
for target in dashboard dashboard:pomodoro dashboard:roadmap dashboard:mail \
              dashboard:wallpaper quicksettings:network quicksettings:bluetooth \
              quicksettings:volume quicksettings:powerprofile quicksettings:battery \
              quicksettings:power launcher clipboard emoji close; do
    kill -0 "$QS_REAL" 2>/dev/null || { fail "shell died before $target"; break; }
    quickshell ipc --pid "$QS_REAL" call zenith:menu toggle "$target" >/dev/null 2>&1
    sleep 0.9
    if kill -0 "$QS_REAL" 2>/dev/null; then
        pass "$target"
    else
        fail "CRASHED opening $target"
        break
    fi
done

sed -i -e 's/\x1b\[[0-9;]*m//g' "$WORK/qs.log"

# Warnings that mean a real defect, as opposed to the nested compositor's own
# noise about sockets and tray registration.
PROBLEMS="$(grep -iE "error|recursive rearrange|Unable to assign|Cannot assign|is not a type|required property|TypeError|is not defined" "$WORK/qs.log" \
    | grep -viE "hyprland[. ]ipc|wl_display|notification server|Registration will|Tray|MPRIS|dbus|placeholder screen|connection broke|event socket|ServerNotFoundError|PeerClosedError" || true)"
if [ -n "$PROBLEMS" ]; then
    fail "QML diagnostics:"
    echo "$PROBLEMS" | head -10 | sed 's/^/          /'
else
    pass "no QML errors or layout warnings"
fi

[ "$FAILED" -eq 0 ] && echo "  smoke: OK" || echo "  smoke: FAILED"
exit "$FAILED"
