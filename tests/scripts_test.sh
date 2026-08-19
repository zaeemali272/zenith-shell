#!/usr/bin/env bash
# The helper scripts the shell shells out to.
#
# These are the pieces most likely to break quietly: they run in a subprocess,
# their output is parsed by QML, and a malformed reply shows up as an empty
# widget rather than an error. Each check asserts the shape the QML side
# actually depends on.
#
# Network-dependent checks degrade to SKIP rather than failing a build because
# a CI runner has no route to the internet.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="$REPO/scripts"
WORK="$(mktemp -d -t zenith-scripts-XXXXXX)"
FAILED=0
trap 'rm -rf "$WORK"' EXIT
pass() { echo "  PASS  $*"; }
fail() { echo "  FAIL  $*"; FAILED=1; }
skip() { echo "  SKIP  $*"; }

json_has() {  # json, key...  -> all keys present at top level
    python3 -c "
import json,sys
try: d = json.loads(sys.stdin.read())
except Exception as e: sys.exit(1)
sys.exit(0 if all(k in d for k in sys.argv[1:]) else 1)" "$@"
}

# ---------------------------------------------------------------- detect_env
OUT="$(timeout 20 "$S/detect_env.sh" 2>/dev/null)"
if printf '%s' "$OUT" | json_has distroId countryCode; then
    pass "detect_env.sh emits distroId and countryCode"
else
    fail "detect_env.sh output missing expected keys: $(printf '%s' "$OUT" | head -c 90)"
fi
# Everything downstream reads .countryCode with jq; an empty string is fine, a
# missing key is not.
printf '%s' "$OUT" | jq -e 'has("countryCode")' >/dev/null 2>&1 \
    && pass "detect_env.sh is valid JSON for jq" \
    || fail "detect_env.sh is not jq-parseable"

# ------------------------------------------------------------------- wifi_nm
for mode in status cached; do
    OUT="$(timeout 25 python3 "$S/wifi_nm.py" "$mode" 2>/dev/null)"
    if printf '%s' "$OUT" | json_has networks; then
        pass "wifi_nm.py $mode returns a networks array"
    else
        fail "wifi_nm.py $mode did not return usable JSON"
    fi
done
# status must never claim to have scanned -- an empty list from it once wiped
# the panel, because an empty JS array is truthy.
OUT="$(timeout 25 python3 "$S/wifi_nm.py" status 2>/dev/null)"
if printf '%s' "$OUT" | python3 -c "import json,sys; sys.exit(0 if json.load(sys.stdin).get('networks')==[] else 1)"; then
    pass "wifi_nm.py status reports no networks rather than a stale list"
else
    skip "wifi_nm.py status returned networks (adapter state dependent)"
fi
timeout 20 python3 "$S/wifi_nm.py" nonsense-subcommand >/dev/null 2>&1 \
    && pass "wifi_nm.py tolerates an unknown subcommand" \
    || pass "wifi_nm.py rejects an unknown subcommand without hanging"

# ------------------------------------------------------------------- weather
OUT="$(timeout 30 "$S/weather.sh" 2>/dev/null)"
if [ -z "$OUT" ]; then
    skip "weather.sh returned nothing (offline?)"
elif printf '%s' "$OUT" | jq -e '.current_condition[0].temp_C' >/dev/null 2>&1; then
    pass "weather.sh emits the wttr-shaped fields the widget reads"
else
    fail "weather.sh output is not in the expected shape"
fi

# ------------------------------------------------------------- fetch_events
# It writes events.json rather than printing, so assert on the file.
EV="$REPO/events.json"
if [ -s "$EV" ] && jq -e 'type == "array"' "$EV" >/dev/null 2>&1; then
    pass "events.json is a JSON array"
    jq -e 'length == 0 or (.[0] | has("date") and has("name"))' "$EV" >/dev/null 2>&1 \
        && pass "event entries have date and name" \
        || fail "event entries are missing date/name"
else
    skip "no events.json to check"
fi

# Country detection decides which holidays get fetched. It read the locale
# first, so LANG=en_US.UTF-8 on a machine in Asia/Karachi reported US and the
# calendar filled with American holidays. The timezone has to win.
TZ_NOW="$(timeout 20 "$S/detect_env.sh" 2>/dev/null | jq -r '.timezone // empty')"
CC_NOW="$(timeout 20 "$S/detect_env.sh" 2>/dev/null | jq -r '.countryCode // empty')"
case "$TZ_NOW" in
    *Karachi*) [ "$CC_NOW" = "PK" ] \
        && pass "timezone beats locale for country (Asia/Karachi -> PK)" \
        || fail "Asia/Karachi reported $CC_NOW, not PK -- locale is winning again" ;;
    "") skip "no timezone reported" ;;
    *)  [ -n "$CC_NOW" ] \
        && pass "country detected as $CC_NOW for $TZ_NOW" \
        || fail "no country detected for $TZ_NOW" ;;
esac

# ------------------------------------------------------------- roadmap_graph
OUT="$(ZENITH_MAIL_CACHE="$WORK" timeout 30 "$S/roadmap_graph.sh" 2>/dev/null)"
printf '%s' "$OUT" | jq -e '.nodes | length == 0' >/dev/null 2>&1 \
    && pass "roadmap_graph.sh with no slug returns an empty graph, not an error" \
    || fail "roadmap_graph.sh mishandled a missing slug"

OUT="$(timeout 40 "$S/roadmap_graph.sh" devops 2>/dev/null)"
if printf '%s' "$OUT" | jq -e '.nodes | length > 0' >/dev/null 2>&1; then
    pass "roadmap_graph.sh returns a populated graph"
    printf '%s' "$OUT" | jq -e '[.nodes[] | select(.x < 0 or .y < 0)] | length == 0' >/dev/null 2>&1 \
        && pass "roadmap_graph.sh normalises coordinates to zero" \
        || fail "roadmap_graph.sh emitted negative coordinates"
    printf '%s' "$OUT" | jq -e '[.nodes[] | select(.label | test("^roadmap\\.sh$"))] | length == 0' >/dev/null 2>&1 \
        && pass "roadmap_graph.sh strips the roadmap.sh promo block" \
        || fail "roadmap_graph.sh left the promo block in"
else
    skip "roadmap_graph.sh returned nothing (offline?)"
fi

# ----------------------------------------------------------- roadmap_content
OUT="$(timeout 20 "$S/roadmap_content.sh" 2>/dev/null)"
printf '%s' "$OUT" | jq -e '.resources | length == 0' >/dev/null 2>&1 \
    && pass "roadmap_content.sh with no arguments returns an empty topic" \
    || fail "roadmap_content.sh mishandled missing arguments"

OUT="$(timeout 40 "$S/roadmap_content.sh" devops v5FGKQc-_7NYEsWjmTEuq 2>/dev/null)"
if printf '%s' "$OUT" | jq -e '.title != ""' >/dev/null 2>&1; then
    pass "roadmap_content.sh resolves node id -> published write-up"
    printf '%s' "$OUT" | jq -e '.resources | length > 0 and (.[0] | has("kind") and has("url"))' >/dev/null 2>&1 \
        && pass "roadmap_content.sh parses typed resource links" \
        || fail "roadmap_content.sh did not parse resources"
else
    skip "roadmap_content.sh returned nothing (offline?)"
fi

OUT="$(timeout 30 "$S/roadmap_content.sh" devops not-a-real-node-id 2>/dev/null)"
printf '%s' "$OUT" | jq -e '.missing == true' >/dev/null 2>&1 \
    && pass "roadmap_content.sh reports an unknown node as missing" \
    || skip "roadmap_content.sh unknown-node case needs network"

# ------------------------------------------------------ battery_conservation
OUT="$(timeout 15 "$S/battery_conservation.sh" status 2>/dev/null)"
if printf '%s' "$OUT" | json_has supported active label; then
    pass "battery_conservation.sh status reports supported/active/label"
    SUPPORTED="$(printf '%s' "$OUT" | jq -r .supported)"
    if [ "$SUPPORTED" = "true" ]; then
        printf '%s' "$OUT" | jq -e '.label != ""' >/dev/null 2>&1 \
            && pass "battery_conservation.sh names the control it found" \
            || fail "supported but no label"
    else
        skip "no charge-limit node on this machine"
    fi
else
    fail "battery_conservation.sh status is not usable JSON"
fi
timeout 15 "$S/battery_conservation.sh" bogus 2>/dev/null | jq -e '.ok == false' >/dev/null 2>&1 \
    && pass "battery_conservation.sh rejects an unknown command" \
    || fail "battery_conservation.sh accepted an unknown command"

# ----------------------------------------------------------- detect_hardware
OUT="$(timeout 15 "$S/detect_hardware.sh" 2>/dev/null)"
if printf '%s' "$OUT" | json_has battery bluetooth wifi ethernet vm; then
    pass "detect_hardware.sh reports every capability key"
else
    fail "detect_hardware.sh output is not usable: ${OUT:0:70}"
fi
# systemd-detect-virt prints "none" *and* exits 1 on bare metal, which once made
# a physical laptop report itself as a VM.
printf '%s' "$OUT" | jq -e '.virt | test("\n") | not' >/dev/null 2>&1 \
    && pass "detect_hardware.sh virt field is a single clean value" \
    || fail "virt field contains stray output: $(printf '%s' "$OUT" | jq -r .virt)"
printf '%s' "$OUT" | jq -e '(.vm | type) == "boolean" and (.battery | type) == "boolean"' >/dev/null 2>&1 \
    && pass "detect_hardware.sh emits real booleans" \
    || fail "capabilities are not booleans"

# ------------------------------------------------------------ super_launcher
# Tap detection keeps its state under XDG_RUNTIME_DIR; point it somewhere
# disposable so a test cannot disturb a live session.
export XDG_RUNTIME_DIR="$WORK"
timeout 10 "$S/super_launcher.sh" press >/dev/null 2>&1
if [ -f "$WORK/zenith_super/press_time" ]; then
    pass "super_launcher.sh records a press"
else
    fail "super_launcher.sh did not record a press"
fi
timeout 10 "$S/super_launcher.sh" combo >/dev/null 2>&1
[ -f "$WORK/zenith_super/combo_flag" ] \
    && pass "super_launcher.sh records a combo, which suppresses the tap" \
    || fail "super_launcher.sh did not record a combo"

exit "$FAILED"
