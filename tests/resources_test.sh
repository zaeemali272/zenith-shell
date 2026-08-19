#!/usr/bin/env bash
# scripts/resources.sh must die when nothing is reading it.
#
# It did not, once: `except Exception: time.sleep(2)` swallowed the
# BrokenPipeError raised when the shell went away, so every restart left
# another polling daemon behind. Nine were found running at once, the oldest
# against a shell that had not existed for twelve hours.
#
# Every check below tracks the exact pid it started. Nothing here matches
# processes by name -- a pkill on a pattern like "proc/stat" would take out the
# daemon belonging to the running shell.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO/scripts/resources.sh"
WORK="$(mktemp -d -t zenith-res-XXXXXX)"
FAILED=0
trap 'rm -rf "$WORK"' EXIT
pass() { echo "  PASS  $*"; }
fail() { echo "  FAIL  $*"; FAILED=1; }

# 1. It produces a usable sample.
LINE="$(timeout 10 "$SCRIPT" 2>/dev/null | head -1)"
if printf '%s' "$LINE" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if 'cpu' in d and 'mem' in d else 1)" 2>/dev/null; then
    pass "emits a JSON sample with cpu and mem"
else
    fail "first sample was not usable JSON: ${LINE:0:60}"
fi

# 2. Reader closes -> the daemon exits rather than looping forever.
mkfifo "$WORK/pipe"
"$SCRIPT" > "$WORK/pipe" 2>/dev/null &
WRITER=$!
head -1 < "$WORK/pipe" >/dev/null 2>&1   # take one sample, then close the read end
sleep 4
if kill -0 "$WRITER" 2>/dev/null; then
    fail "still running after its reader closed (the daemon leak)"
    kill -9 "$WRITER" 2>/dev/null
else
    pass "exits when its reader goes away"
fi

# 3. Orphaned -> exits rather than being adopted and left polling.
setsid sh -c "\"$SCRIPT\" > /dev/null 2>&1 & echo \$! > \"$WORK/child.pid\"; sleep 60" >/dev/null 2>&1 &
sleep 3
CHILD="$(cat "$WORK/child.pid" 2>/dev/null || true)"
PARENT="$(ps -o ppid= -p "$CHILD" 2>/dev/null | tr -d ' ' || true)"
if [ -n "${CHILD:-}" ] && [ -n "$PARENT" ] && [ "$PARENT" != "1" ]; then
    kill -9 "$PARENT" 2>/dev/null
    sleep 5
    if kill -0 "$CHILD" 2>/dev/null; then
        fail "survived being orphaned"
        kill -9 "$CHILD" 2>/dev/null
    else
        pass "exits when orphaned"
    fi
else
    echo "  SKIP  could not set up the orphan case here"
fi
exit "$FAILED"
