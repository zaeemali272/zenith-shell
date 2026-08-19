#!/usr/bin/env bash
# Every check, in the order they get cheaper to fix.
#
#   tests/run.sh          static + unit tests (works anywhere, used by CI)
#   tests/run.sh --all    also the headless smoke test (needs a compositor)
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
FAILED=0
step() { echo; echo "=== $* ==="; }

# No qmllint here. Quickshell's QML is not stock QtQuick -- its types are
# registered by the runtime, so qmllint reports them all as unresolved and has
# to be run with most of its checks disabled, at which point it only catches
# syntax. tests/smoke.sh loads the shell for real, which catches syntax and
# everything qmllint never could.

step "shell script syntax"
for f in $(find scripts tests -name '*.sh' 2>/dev/null); do
    bash -n "$f" || { echo "  FAIL  $f"; FAILED=1; }
done
echo "  PASS  shell scripts parse"

step "python syntax"
for f in $(find scripts tests -name '*.py' 2>/dev/null); do
    python3 -c "import ast,io,sys; ast.parse(io.open(sys.argv[1]).read())" "$f" \
        || { echo "  FAIL  $f"; FAILED=1; }
done
echo "  PASS  python files parse"

step "nerd font glyphs"
python3 - <<'PY' || FAILED=1
import io, os, sys
# A glyph that gets retyped instead of copied becomes an empty box on the bar,
# and nothing else in the toolchain notices.
total = 0
for root, dirs, files in os.walk('.'):
    if '/.git' in root: continue
    for f in files:
        if f.endswith('.qml'):
            s = io.open(os.path.join(root, f), encoding='utf-8').read()
            total += sum(1 for c in s
                         if 0xE000 <= ord(c) <= 0xF8FF or 0xF0000 <= ord(c) <= 0xFFFFD)
print("  PASS  %d private-use glyphs present" % total)
sys.exit(0 if total > 100 else 1)
PY

step "resources daemon lifecycle"
bash tests/resources_test.sh || FAILED=1

step "hyprland scheme validation"
bash tests/theme_test.sh || FAILED=1

step "helper scripts"
bash tests/scripts_test.sh || FAILED=1

step "todoist sync"
python3 tests/todoist_sync_test.py || FAILED=1

step "mail"
python3 tests/mail_test.py || FAILED=1

if [ "${1:-}" = "--all" ]; then
    step "headless smoke"
    bash tests/smoke.sh || FAILED=1
fi

echo
[ "$FAILED" -eq 0 ] && echo "ALL CHECKS PASSED" || echo "CHECKS FAILED"
exit "$FAILED"
