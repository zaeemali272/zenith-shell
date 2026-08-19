#!/usr/bin/env bash
# The guard that stands between a bad matugen render and an unbootable desktop.
#
# A generated Hyprland scheme once shipped without the trailing commas on its
# entries. It was installed anyway, and Hyprland refused to load its config
# until the file was restored by hand. These cases are that failure, plus the
# other ways a render can come out wrong.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME="$REPO/scripts/zenith-theme.sh"
WORK="$(mktemp -d -t zenith-theme-XXXXXX)"
FAILED=0
trap 'rm -rf "$WORK"' EXIT
pass() { echo "  PASS  $*"; }
fail() { echo "  FAIL  $*"; FAILED=1; }

check() {  # name, expected(ok|reject), file
    local name="$1" expect="$2" file="$3"
    if bash "$THEME" --validate "$file" >/dev/null 2>&1; then
        got="ok"
    else
        got="reject"
    fi
    [ "$got" = "$expect" ] && pass "$name" || fail "$name (expected $expect, got $got)"
}

cat > "$WORK/good.lua" <<'LUA'
return {
    primary = "edc06c",
    onPrimary = "3f2d00",
    surface = "16130b",
}
LUA
check "a well-formed scheme installs" ok "$WORK/good.lua"

# The exact regression: a rewrite that dropped the trailing commas.
cat > "$WORK/nocomma.lua" <<'LUA'
return {
    primary = "edc06c"
    onPrimary = "3f2d00"
}
LUA
check "missing trailing commas rejected" reject "$WORK/nocomma.lua"

# matugen failing halfway leaves its own placeholders behind.
cat > "$WORK/unrendered.lua" <<'LUA'
return {
    primary = "{{colors.primary.default.hex_stripped}}",
}
LUA
check "unrendered template placeholders rejected" reject "$WORK/unrendered.lua"

cat > "$WORK/unbalanced.lua" <<'LUA'
return {
    primary = "edc06c",
LUA
check "unbalanced braces rejected" reject "$WORK/unbalanced.lua"

: > "$WORK/empty.lua"
check "empty file rejected" reject "$WORK/empty.lua"

check "missing file rejected" reject "$WORK/does-not-exist.lua"

# Syntactically plausible but not a table -- Hyprland would fail on require.
cat > "$WORK/nottable.lua" <<'LUA'
return "not a table"
LUA
if command -v lua >/dev/null 2>&1 || command -v luajit >/dev/null 2>&1; then
    check "a scheme that is not a table rejected" reject "$WORK/nottable.lua"
else
    echo "  SKIP  no lua interpreter for the type check"
fi

exit "$FAILED"
