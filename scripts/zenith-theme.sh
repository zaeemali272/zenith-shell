#!/usr/bin/env bash
# Zenith theme generator.
#
# Derives a Material 3 palette from the current wallpaper with matugen and
# writes it where the shell can pick it up.
#
# Two things changed from the previous version:
#
#   * It no longer depends on ~/.config/matugen/config.toml. That file did not
#     exist on this machine, so every run failed at the matugen step and the
#     theme silently never updated. The config is now generated here, from the
#     template that ships with the repo, with absolute paths filled in at run
#     time -- nothing to install by hand, and nothing for Home Manager to own.
#
#   * It no longer kills and restarts Quickshell. Colors.qml watches the
#     generated palette, so the bar and every menu recolour in place. Restarting
#     the shell to change a colour threw away all open menus and shell state.

set -uo pipefail

SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zenith"
PALETTE="$CACHE_DIR/colors.json"
TEMPLATE="$SHELL_DIR/themes/matugen/colors.json"
HYPR_TEMPLATE="$SHELL_DIR/themes/matugen/hyprland-scheme.lua"
HYPR_SCHEME="$HOME/.config/hypr/scheme/current.lua"
WALL_CACHE="$HOME/.config/current_wallpaper.txt"

log()      { printf '  -> %s\n' "$*"; }
log_step() { printf '\033[1;34m[STEP]\033[0m %s\n' "$*"; }
log_ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
log_err()  { printf '\033[1;31m[ERR]\033[0m %s\n' "$*" >&2; }

# --autoselect keeps the old flag working; matugen needs a --prefer strategy
# when an image yields several candidate source colours and no terminal is
# attached to ask in (which is always, when called from the shell).

# Validates a generated Hyprland scheme without installing it. Exposed as a
# subcommand so the check that guards your desktop can itself be tested:
#
#     zenith-theme.sh --validate <file>     exit 0 if safe to install
#
# This is not hypothetical. A generated scheme once lost the trailing commas on
# its entries, was installed anyway, and Hyprland refused to start until the
# file was restored by hand.
validate_scheme() {
    local file="$1"
    [ -s "$file" ] || { echo "empty or missing" >&2; return 1; }

    python3 - "$file" <<'SCHEME_CHECK' || return 1
import re, sys
s = open(sys.argv[1]).read()
rows = [l for l in s.splitlines() if re.match(r'\s+\w+\s*=', l)]
problems = []
if not rows:                                       problems.append("no entries")
if any(not l.rstrip().endswith(',') for l in rows): problems.append("missing trailing comma")
if "{{" in s:                                      problems.append("unrendered template placeholder")
if s.count("{") != s.count("}"):                   problems.append("unbalanced braces")
if problems:
    sys.stderr.write("; ".join(problems) + "\n")
    sys.exit(1)
SCHEME_CHECK

    # Then a real interpreter, when one is available.
    local lua_bin
    for lua_bin in lua luajit lua5.4 lua5.3; do
        if command -v "$lua_bin" >/dev/null 2>&1; then
            "$lua_bin" -e "assert(type(dofile('$file'))=='table')" 2>/dev/null || {
                echo "not valid Lua" >&2
                return 1
            }
            break
        fi
    done
    return 0
}

if [[ "${1:-}" == "--validate" ]]; then
    validate_scheme "${2:-}" && { echo "ok"; exit 0; } || exit 1
fi

PREFER="saturation"
if [[ "${1:-}" == "--autoselect" ]]; then
    shift
fi

WALLPAPER="${1:-}"
SOURCE_COLOR="${2:-}"

if [[ -z "$WALLPAPER" ]]; then
    if [[ -f "$WALL_CACHE" ]]; then
        WALLPAPER="$(cat "$WALL_CACHE")"
        log "No path given, using current wallpaper: $WALLPAPER"
    else
        log_err "No wallpaper given and $WALL_CACHE does not exist."
        exit 1
    fi
fi

[[ -f "$WALLPAPER" ]] || { log_err "Wallpaper does not exist: $WALLPAPER"; exit 1; }
command -v matugen >/dev/null 2>&1 || { log_err "matugen is not installed."; exit 1; }
[[ -f "$TEMPLATE" ]] || { log_err "Palette template missing: $TEMPLATE"; exit 1; }

mkdir -p "$CACHE_DIR"

# Everything is rendered to a staging file, validated, and only then moved into
# place. Writing generated output straight onto a live config is how a bad
# template takes the desktop down: a dropped comma once turned the Hyprland
# scheme into a syntax error, and Hyprland could not start until it was
# restored by hand. Nothing below replaces a real file until it parses.
PALETTE_STAGE="$CACHE_DIR/colors.json.new"
HYPR_STAGE="$CACHE_DIR/hypr-scheme.lua.new"
rm -f "$PALETTE_STAGE" "$HYPR_STAGE"

# Generated per run so the paths are always right, wherever the repo lives.
CONFIG="$(mktemp -t zenith-matugen-XXXXXX.toml)"
trap 'rm -f "$CONFIG" "$PALETTE_STAGE" "$HYPR_STAGE"' EXIT
cat > "$CONFIG" <<EOF
[config]

[templates.zenith_shell]
input_path = "$TEMPLATE"
output_path = "$PALETTE_STAGE"
EOF

# Hyprland reads its colours from a Lua table. Only regenerate it when the
# template and the target directory are both present, so a machine without
# these dots still themes the shell fine.
if [[ -f "$HYPR_TEMPLATE" && -d "$(dirname "$HYPR_SCHEME")" ]]; then
    cat >> "$CONFIG" <<EOF

[templates.hyprland_scheme]
input_path = "$HYPR_TEMPLATE"
output_path = "$HYPR_STAGE"
EOF
    THEME_HYPRLAND=1
fi

log_step "Generating palette from $(basename "$WALLPAPER")"

matugen_args=(image "$WALLPAPER" --config "$CONFIG" --mode dark --prefer "$PREFER")
[[ -n "$SOURCE_COLOR" ]] && matugen_args+=(--color "$SOURCE_COLOR")

if ! matugen "${matugen_args[@]}"; then
    log_err "matugen failed; the previous theme is still in place."
    exit 1
fi

# --- Validate before installing -----------------------------------------
if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$PALETTE_STAGE" 2>/dev/null; then
    log_err "Generated palette is not valid JSON; keeping the previous theme."
    exit 1
fi
mv -f "$PALETTE_STAGE" "$PALETTE"
log_ok "Palette written to $PALETTE"

if [[ "${THEME_HYPRLAND:-0}" == "1" ]]; then
    if ! validate_scheme "$HYPR_STAGE"; then
        log_err "Generated Hyprland scheme is malformed; keeping the existing one."
        exit 1
    fi

    # Keep one generation of backup, in the cache dir rather than beside the
    # config: ~/.config/hypr is commonly a symlink into a dotfiles repo, and a
    # .bak dropped there shows up as untracked clutter in `git status`.
    [[ -f "$HYPR_SCHEME" ]] && cp -f "$HYPR_SCHEME" "$CACHE_DIR/hypr-scheme.previous.lua"
    mv -f "$HYPR_STAGE" "$HYPR_SCHEME"
    log "Hyprland scheme written to $HYPR_SCHEME (previous: $CACHE_DIR/hypr-scheme.previous.lua)"
fi
log "The shell watches this file -- the bar and menus recolour without a restart."

# --- Other components that do need a nudge -------------------------------
log_step "Refreshing other components"

if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl reload >/dev/null 2>&1 && log "Hyprland reloaded"
fi

killall -USR1 kitty 2>/dev/null && log "kitty reloaded"

if command -v gsettings >/dev/null 2>&1; then
    # Toggling forces GTK apps to re-read the colour scheme.
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null
    sleep 0.1
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null
fi

log_ok "Zenith theme updated."
