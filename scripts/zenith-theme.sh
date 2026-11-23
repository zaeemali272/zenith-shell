#!/usr/bin/env bash
# Zenith theme generator & preset engine.
#
# Supports:
#   zenith-theme.sh --preset <name> [--accent <hex>]   apply a curated dotfile theme
#   zenith-theme.sh --accent <hex>                     override active theme accent
#   zenith-theme.sh --dynamic [wall_path]              derive palette from wallpaper (matugen)
#   zenith-theme.sh --list                             list available presets as JSON
#   zenith-theme.sh --current                          show active theme status as JSON
#   zenith-theme.sh [wall_path]                        backwards-compatible wallpaper mode

set -uo pipefail

SHELL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zenith"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zenith"
PRESETS_DIR="$SHELL_DIR/themes/presets"
PALETTE="$CACHE_DIR/colors.json"
TEMPLATE="$SHELL_DIR/themes/matugen/colors.json"
HYPR_TEMPLATE="$SHELL_DIR/themes/matugen/hyprland-scheme.lua"
HYPR_SCHEME="$HOME/.config/hypr/scheme/current.lua"
WALL_CACHE="$HOME/.config/current_wallpaper.txt"
THEME_CONFIG="$STATE_DIR/theme_config.json"

log()      { printf '  -> %s\n' "$*"; }
log_step() { printf '\033[1;34m[STEP]\033[0m %s\n' "$*"; }
log_ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
log_err()  { printf '\033[1;31m[ERR]\033[0m %s\n' "$*" >&2; }

mkdir -p "$CACHE_DIR" "$STATE_DIR"

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

if [[ "${1:-}" == "--list" ]]; then
    python3 - "$PRESETS_DIR" <<'LIST_PRESETS'
import glob, json, os, sys
pdir = sys.argv[1]
items = []
for p in sorted(glob.glob(os.path.join(pdir, "*.json"))):
    try:
        d = json.load(open(p))
        items.append({
            "id": d.get("id", os.path.splitext(os.path.basename(p))[0]),
            "name": d.get("name", os.path.basename(p)),
            "category": d.get("category", "Custom"),
            "background": d.get("background", "#1e1e2e"),
            "surface": d.get("surface", "#181825"),
            "primary": d.get("primary", "#cba6f7"),
            "secondary": d.get("secondary", "#89b4fa")
        })
    except Exception:
        pass
print(json.dumps(items))
LIST_PRESETS
    exit 0
fi

if [[ "${1:-}" == "--current" ]]; then
    if [[ -f "$THEME_CONFIG" ]]; then
        cat "$THEME_CONFIG"
    else
        echo '{"mode":"dynamic","preset":"","accent":""}'
    fi
    exit 0
fi

# Parsing Arguments
MODE="dynamic"
PRESET_NAME=""
ACCENT_OVERRIDE=""
WALLPAPER=""
SOURCE_COLOR=""
PREFER="saturation"
SCHEME_TYPE=""
if [[ -f "$THEME_CONFIG" ]]; then
    SAVED_TYPE=$(python3 -c "import json; print(json.load(open('$THEME_CONFIG')).get('scheme_type', ''))" 2>/dev/null || true)
    [[ -n "$SAVED_TYPE" ]] && SCHEME_TYPE="$SAVED_TYPE"
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --scheme|--type|-t)
            SCHEME_TYPE="${2:-}"
            shift 2
            ;;
        --preset|-p)
            MODE="preset"
            PRESET_NAME="${2:-}"
            shift 2
            ;;
        --accent|-a)
            ACCENT_OVERRIDE="${2:-}"
            shift 2
            ;;
        --dynamic|-d)
            MODE="dynamic"
            if [[ -n "${2:-}" && ! "$2" =~ ^-- ]]; then
                WALLPAPER="$2"
                shift 2
            else
                shift 1
            fi
            ;;
        --autoselect)
            shift 1
            ;;
        --color)
            SOURCE_COLOR="${2:-}"
            shift 2
            ;;
        *)
            if [[ -z "$WALLPAPER" && ! "$1" =~ ^-- ]]; then
                WALLPAPER="$1"
            fi
            shift 1
            ;;
    esac
done

PALETTE_STAGE="$CACHE_DIR/colors.json.new"
HYPR_STAGE="$CACHE_DIR/hypr-scheme.lua.new"
rm -f "$PALETTE_STAGE" "$HYPR_STAGE"
trap 'rm -f "$PALETTE_STAGE" "$HYPR_STAGE"' EXIT

if [[ "$MODE" == "preset" ]]; then
    PRESET_FILE="$PRESETS_DIR/${PRESET_NAME}.json"
    if [[ ! -f "$PRESET_FILE" ]]; then
        # Try matching by id without extension or search
        MATCH=$(find "$PRESETS_DIR" -name "${PRESET_NAME}*.json" | head -n1)
        if [[ -n "$MATCH" && -f "$MATCH" ]]; then
            PRESET_FILE="$MATCH"
        else
            log_err "Preset not found: $PRESET_NAME"
            exit 1
        fi
    fi

    log_step "Applying theme preset: $(basename "$PRESET_FILE" .json)"

    # Render palette stage and lua stage via Python
    python3 - "$PRESET_FILE" "$PALETTE_STAGE" "$HYPR_STAGE" "$ACCENT_OVERRIDE" <<'GEN_PRESET'
import json, sys

src_file = sys.argv[1]
pal_out = sys.argv[2]
hypr_out = sys.argv[3]
accent = sys.argv[4].strip() if len(sys.argv) > 4 else ""

with open(src_file) as f:
    data = json.load(f)

if accent and accent.startswith("#"):
    data["primary"] = accent
    data["accent"] = accent

# Save colors.json
with open(pal_out, "w") as f:
    json.dump(data, f, indent=2)

# Generate Hyprland scheme lua
def strip(c, default=""):
    if isinstance(c, str) and c.strip():
        return c.strip().lstrip("#")
    return default

bg = strip(data.get("background"), "1e1e2e")
fg = strip(data.get("on_background"), "cdd6f4")
surf = strip(data.get("surface"), bg)
pri = strip(data.get("primary"), "cba6f7")
on_pri = strip(data.get("on_primary"), "11111b")
pri_container = strip(data.get("primary_container"), "45475a")
on_pri_container = strip(data.get("on_primary_container"), fg)
sec = strip(data.get("secondary"), "89b4fa")
on_sec = strip(data.get("on_secondary"), "11111b")
sec_container = strip(data.get("secondary_container"), "313244")
on_sec_container = strip(data.get("on_secondary_container"), fg)
ter = strip(data.get("tertiary"), "a6e3a1")
on_ter = strip(data.get("on_tertiary"), "11111b")
ter_container = strip(data.get("tertiary_container"), "313244")
on_ter_container = strip(data.get("on_tertiary_container"), fg)
err = strip(data.get("error"), "f38ba8")
on_err = strip(data.get("on_error"), "11111b")
err_container = strip(data.get("error_container"), "45475a")
on_err_container = strip(data.get("on_error_container"), err)
outl = strip(data.get("outline"), "585b70")
outl_var = strip(data.get("outline_variant"), "45475a")
surf_var = strip(data.get("surface_variant"), "313244")
on_surf_var = strip(data.get("on_surface_variant"), "a6adc8")
surf_dim = strip(data.get("surface_container_low"), bg)
surf_bright = strip(data.get("surface_container_highest"), bg)
surf_lowest = strip(data.get("surface_container_lowest"), "11111b")
surf_low = strip(data.get("surface_container_low"), "181825")
surf_mid = strip(data.get("surface_container"), bg)
surf_high = strip(data.get("surface_container_high"), "28283d")
surf_highest = strip(data.get("surface_container_highest"), "313244")
inv_pri = strip(data.get("inverse_primary"), pri_container)
inv_surf = strip(data.get("inverse_surface"), fg)
inv_on_surf = strip(data.get("inverse_on_surface"), bg)

lua = f"""return {{
    primary_paletteKeyColor         = "7171ac",
    secondary_paletteKeyColor       = "76758e",
    tertiary_paletteKeyColor        = "9e648e",
    neutral_paletteKeyColor         = "78767b",
    neutral_variant_paletteKeyColor = "777680",
    background                      = "{bg}",
    onBackground                    = "{fg}",
    surface                         = "{surf}",
    surfaceDim                      = "{surf_dim}",
    surfaceBright                   = "{surf_bright}",
    surfaceContainerLowest          = "{surf_lowest}",
    surfaceContainerLow             = "{surf_low}",
    surfaceContainer                = "{surf_mid}",
    surfaceContainerHigh            = "{surf_high}",
    surfaceContainerHighest         = "{surf_highest}",
    onSurface                       = "{fg}",
    surfaceVariant                  = "{surf_var}",
    onSurfaceVariant                = "{on_surf_var}",
    inverseSurface                  = "{inv_surf}",
    inverseOnSurface                = "{inv_on_surf}",
    outline                         = "{outl}",
    outlineVariant                  = "{outl_var}",
    shadow                          = "000000",
    scrim                           = "000000",
    surfaceTint                     = "{pri}",
    primary                         = "{pri}",
    onPrimary                       = "{on_pri}",
    primaryContainer                = "{pri_container}",
    onPrimaryContainer              = "{on_pri_container}",
    inversePrimary                  = "{inv_pri}",
    secondary                       = "{sec}",
    onSecondary                     = "{on_sec}",
    secondaryContainer              = "{sec_container}",
    onSecondaryContainer            = "{on_sec_container}",
    tertiary                        = "{ter}",
    onTertiary                      = "{on_ter}",
    tertiaryContainer               = "{ter_container}",
    onTertiaryContainer             = "{on_ter_container}",
    error                           = "{err}",
    onError                         = "{on_err}",
    errorContainer                  = "{err_container}",
    onErrorContainer                = "{on_err_container}",
    primaryFixed                    = "{strip(data.get("primary_fixed"), pri)}",
    primaryFixedDim                 = "{strip(data.get("primary_fixed_dim"), pri)}",
    onPrimaryFixed                  = "{strip(data.get("on_primary_fixed"), bg)}",
    onPrimaryFixedVariant           = "{strip(data.get("on_primary_fixed_variant"), pri_container)}",
    secondaryFixed                  = "{strip(data.get("secondary_fixed"), sec)}",
    secondaryFixedDim               = "{strip(data.get("secondary_fixed_dim"), sec)}",
    onSecondaryFixed                = "{strip(data.get("on_secondary_fixed"), bg)}",
    onSecondaryFixedVariant         = "{strip(data.get("on_secondary_fixed_variant"), sec_container)}",
    tertiaryFixed                   = "{strip(data.get("tertiary_fixed"), ter)}",
    tertiaryFixedDim                = "{strip(data.get("tertiary_fixed_dim"), ter)}",
    onTertiaryFixed                 = "{strip(data.get("on_tertiary_fixed"), bg)}",
    onTertiaryFixedVariant          = "{strip(data.get("on_tertiary_fixed_variant"), ter_container)}",
    term0                           = "353434",
    term1                           = "ac73ff",
    term2                           = "44def5",
    term3                           = "ffdcf2",
    term4                           = "99aad8",
    term5                           = "b49fea",
    term6                           = "9dceff",
    term7                           = "e8d3de",
    term8                           = "ac9fa9",
    term9                           = "c093ff",
    term10                          = "89ecff",
    term11                          = "fff0f6",
    term12                          = "b5c1dd",
    term13                          = "c9b5f4",
    term14                          = "bae0ff",
    term15                          = "ffffff",
    rosewater                       = "f7eff9",
    flamingo                        = "e9def3",
    pink                            = "e2d7ff",
    mauve                           = "{pri}",
    red                             = "{err}",
    maroon                          = "c9b5ed",
    peach                           = "e0c2f9",
    yellow                          = "ffecf3",
    green                           = "{ter}",
    teal                            = "d3dfff",
    sky                             = "d0daff",
    sapphire                        = "{sec}",
    blue                            = "{sec}",
    lavender                        = "c7c8ff",
    text                            = "{fg}",
    subtext1                        = "{on_surf_var}",
    subtext0                        = "{outl}",
    overlay2                        = "7e7c86",
    overlay1                        = "6b6972",
    overlay0                        = "595860",
    surface2                        = "{surf_var}",
    surface1                        = "37373d",
    surface0                        = "25252a",
    base                            = "{bg}",
    mantle                          = "{surf_low}",
    crust                           = "{surf_lowest}",
    success                         = "{ter}",
    onSuccess                       = "{on_ter}",
    successContainer                = "{ter_container}",
    onSuccessContainer              = "{on_ter_container}",
    accent                          = "{strip(data.get("accent", pri))}",
}}
"""
with open(hypr_out, "w") as f:
    f.write(lua)
GEN_PRESET

    THEME_HYPRLAND=1

else
    # --- DYNAMIC WALLPAPER MODE (Matugen) ---
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

    CONFIG="$(mktemp -t zenith-matugen-XXXXXX.toml)"
    trap 'rm -f "$CONFIG" "$PALETTE_STAGE" "$HYPR_STAGE"' EXIT
    cat > "$CONFIG" <<EOF
[config]

[templates.zenith_shell]
input_path = "$TEMPLATE"
output_path = "$PALETTE_STAGE"
EOF

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
    [[ -n "$SCHEME_TYPE" ]] && matugen_args+=(-t "$SCHEME_TYPE")
    [[ -n "$SOURCE_COLOR" ]] && matugen_args+=(--color "$SOURCE_COLOR")

    if ! matugen "${matugen_args[@]}"; then
        log_err "matugen failed; the previous theme is still in place."
        exit 1
    fi
fi

# --- Validate before installing ---
if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$PALETTE_STAGE" 2>/dev/null; then
    log_err "Generated palette is not valid JSON; keeping the previous theme."
    exit 1
fi
mv -f "$PALETTE_STAGE" "$PALETTE"
log_ok "Palette written to $PALETTE"

# Generate Kitty colors matching the active Zenith palette
python3 - "$PALETTE" "$CACHE_DIR/kitty-colors.conf" <<'KITTY_PY' 2>/dev/null || true
import json, sys
pal = json.load(open(sys.argv[1]))
out_path = sys.argv[2]
content = f"""# Zenith Shell Kitty Colors
foreground            {pal.get('on_surface', '#f1dfdb')}
background            {pal.get('background', '#1a1110')}
selection_foreground  {pal.get('on_primary', '#561e15')}
selection_background  {pal.get('primary', '#ffb4a7')}

cursor                {pal.get('primary', '#ffb4a7')}
cursor_text_color     {pal.get('on_primary', '#561e15')}

url_color             {pal.get('tertiary', '#ddc48c')}

active_border_color   {pal.get('primary', '#ffb4a7')}
inactive_border_color {pal.get('surface_container_highest', '#3d3230')}
bell_border_color     {pal.get('error', '#ffb4ab')}

# Tab bar
active_tab_foreground   {pal.get('on_primary', '#561e15')}
active_tab_background   {pal.get('primary', '#ffb4a7')}
inactive_tab_foreground {pal.get('on_surface_variant', '#d8c2be')}
inactive_tab_background {pal.get('surface_container', '#271d1c')}
tab_bar_background      {pal.get('surface_container_lowest', '#140c0b')}

# 16 terminal colors
color0 {pal.get('surface_container_lowest', '#140c0b')}
color1 {pal.get('error', '#ffb4ab')}
color2 {pal.get('tertiary', '#ddc48c')}
color3 #fae0a6
color4 {pal.get('secondary', '#e7bdb5')}
color5 {pal.get('primary', '#ffb4a7')}
color6 {pal.get('on_primary_container', '#ffdad4')}
color7 {pal.get('on_surface', '#f1dfdb')}

color8  {pal.get('surface_variant', '#534340')}
color9  {pal.get('error', '#ffb4ab')}
color10 #fae0a6
color11 #fae0a6
color12 {pal.get('secondary', '#e7bdb5')}
color13 {pal.get('primary', '#ffb4a7')}
color14 {pal.get('on_primary_container', '#ffdad4')}
color15 #ffffff
"""
with open(out_path, 'w') as f:
    f.write(content)
KITTY_PY

# Update Starship palette if starship.toml is in place (or can be configured)
STARSHIP_TARGET="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"
STARSHIP_TEMPLATE="$SHELL_DIR/themes/starship.toml"

python3 - "$PALETTE" "$STARSHIP_TARGET" "$CACHE_DIR" "$STARSHIP_TEMPLATE" <<'STARSHIP_PY' || true
import json, os, re, sys

pal_path = sys.argv[1]
starship_path = sys.argv[2]
cache_dir = sys.argv[3] if len(sys.argv) > 3 else ""
template_path = sys.argv[4] if len(sys.argv) > 4 else ""

try:
    with open(pal_path, 'r', encoding='utf-8') as f:
        pal = json.load(f)
except Exception:
    sys.exit(0)

# Colors needed by Zenith Starship prompt capsules and symbols:
# os: bg:primary fg:on_primary
# git_branch/status/state: bg:secondary fg:on_secondary
# nix_shell/languages/username/hostname: bg:tertiary fg:on_tertiary
# directory/time/jobs/duration: bg:surface_high fg:text/subtext/yellow
# status: bg:red fg:on_red
# character: primary (success), red (error), tertiary (vimcmd)
primary = pal.get('primary', '#ffb4a7')
on_primary = pal.get('on_primary', '#561e15')
secondary = pal.get('secondary', '#e7bdb5')
on_secondary = pal.get('on_secondary', '#442a25')
tertiary = pal.get('tertiary', '#ddc48c')
on_tertiary = pal.get('on_tertiary', '#3d2e04')
surface = pal.get('surface_container', pal.get('surface', '#271d1c'))
surface_high = pal.get('surface_container_high', pal.get('surface_variant', '#3d3230'))
text = pal.get('on_surface', pal.get('text', '#f1dfdb'))
subtext = pal.get('on_surface_variant', pal.get('subtext', '#d8c2be'))
red = pal.get('error', pal.get('red', '#ffb4ab'))
on_red = pal.get('on_error', pal.get('on_red', '#690005'))
yellow = pal.get('yellow', '#fae0a6')
green = pal.get('green', '#a6d189')
blue = pal.get('blue', '#89b4fa')
purple = pal.get('purple', '#cba6f7')
accent = pal.get('on_primary_container', pal.get('accent', '#ffdad4'))
background = pal.get('background', '#1a1110')

new_palette = f"""[palettes.zenith]
primary = "{primary}"
on_primary = "{on_primary}"
secondary = "{secondary}"
on_secondary = "{on_secondary}"
tertiary = "{tertiary}"
on_tertiary = "{on_tertiary}"
surface = "{surface}"
surface_high = "{surface_high}"
text = "{text}"
subtext = "{subtext}"
red = "{red}"
on_red = "{on_red}"
yellow = "{yellow}"
green = "{green}"
blue = "{blue}"
purple = "{purple}"
accent = "{accent}"
background = "{background}"
"""

content = ""
# 1. Read existing config (following symlink if needed)
if os.path.exists(starship_path) or os.path.islink(starship_path):
    try:
        with open(starship_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        pass

# 2. If empty, try template or backup
if not content.strip():
    for fallback in [template_path, starship_path + ".backup", os.path.expanduser("~/.config/starship.toml.backup")]:
        if fallback and os.path.isfile(fallback):
            try:
                with open(fallback, 'r', encoding='utf-8') as f:
                    content = f.read()
                if content.strip():
                    break
            except Exception:
                pass

if content.strip():
    if "[palettes.zenith]" in content:
        content = re.sub(r'\[palettes\.zenith\][^\[]*', new_palette + "\n", content)
    else:
        if not re.search(r'^\s*palette\s*=', content, re.MULTILINE):
            content = 'palette = "zenith"\n\n' + content
        content = content.rstrip() + "\n\n" + new_palette + "\n"

    def write_atomic(dest_path, data):
        dest_dir = os.path.dirname(os.path.abspath(dest_path))
        os.makedirs(dest_dir, exist_ok=True)
        tmp = os.path.join(dest_dir, f".starship.tmp.{os.getpid()}")
        with open(tmp, 'w', encoding='utf-8') as f:
            f.write(data)
        os.replace(tmp, dest_path)

    try:
        write_atomic(starship_path, content)
    except Exception as e:
        sys.stderr.write(f"Failed to update starship config at {starship_path}: {e}\n")

    # Also update cache copy if cache dir exists
    if cache_dir and os.path.isdir(cache_dir):
        try:
            write_atomic(os.path.join(cache_dir, "starship.toml"), content)
        except Exception:
            pass
STARSHIP_PY
log_ok "Starship palette updated"

# Generate GTK 3, GTK 4, Thunar, and Qt (kdeglobals) themes (Orchis Borderless Material Design)
python3 - "$PALETTE" <<'GTK_QT_PY' || true
import json, os, sys, shutil

pal_path = sys.argv[1]
try:
    with open(pal_path) as f:
        pal = json.load(f)
except Exception:
    sys.exit(0)

home = os.path.expanduser("~")
gtk3_dir = os.path.join(home, ".config", "gtk-3.0")
gtk4_dir = os.path.join(home, ".config", "gtk-4.0")
kde_schemes_dir = os.path.join(home, ".local", "share", "color-schemes")
qt5ct_dir = os.path.join(home, ".config", "qt5ct", "colors")
qt6ct_dir = os.path.join(home, ".config", "qt6ct", "colors")

for d in [gtk3_dir, gtk4_dir, kde_schemes_dir, qt5ct_dir, qt6ct_dir]:
    os.makedirs(d, exist_ok=True)

def hex_to_rgb_tuple(h):
    if not h or not isinstance(h, str):
        return (255, 255, 255)
    h = h.strip().lstrip("#")
    if len(h) == 6:
        return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))
    return (255, 255, 255)

def rgb_to_hex(r, g, b):
    return f"#{max(0, min(255, int(r))):02x}{max(0, min(255, int(g))):02x}{max(0, min(255, int(b))):02x}"

def blend_colors(c1, c2, factor):
    r1, g1, b1 = hex_to_rgb_tuple(c1)
    r2, g2, b2 = hex_to_rgb_tuple(c2)
    return rgb_to_hex(r1 * (1 - factor) + r2 * factor, g1 * (1 - factor) + g2 * factor, b1 * (1 - factor) + b2 * factor)

def hex_to_rgb(hex_str, default="255,255,255"):
    r, g, b = hex_to_rgb_tuple(hex_str)
    return f"{r},{g},{b}"

# Base palette tokens
fg = pal.get('on_surface', pal.get('on_background', '#eee0d5'))
pri = pal.get('primary', '#ecc06c')
on_pri = pal.get('on_primary', '#412d00')
sec = pal.get('secondary', '#d9c4a0')
on_sec = pal.get('on_secondary', '#3b2e15')
ter = pal.get('tertiary', '#b2cfa7')
on_ter = pal.get('on_tertiary', '#1f361a')
err = pal.get('error', '#ffb4ab')
on_err = pal.get('on_error', '#690005')
outl = pal.get('outline', '#9a8f80')
outl_var = pal.get('outline_variant', '#4e4639')
surf_mid = pal.get('surface_container', '#241f17')
surf_high = pal.get('surface_container_high', '#2e2921')

# Color Hierarchy & Material Roles according to specification:
# - Base dark surface: for main view, window, dialogs, headerbar ("all the others should have this color example #130d07")
# - Elevated surface: for sidebar & input bar in filemanager ("only the input bar and the sidebar in the filemanager should have this color for example #19120c")
# - Selected: #503a24 ("selected should have this color #503a24")
# - Hover: #694e33 ("hover should have even lighter color")

is_preset = bool(pal.get('id') or pal.get('category'))
if is_preset:
    bg_dark = pal.get('surface_container_lowest', pal.get('background', '#130d07'))
    surf_elevated = pal.get('surface_container_low', pal.get('surface', '#19120c'))
    surf_mid = surf_elevated
    sel_color = pal.get('primary_container', pal.get('primary', '#503a24'))
    hover_color = blend_colors(sel_color, '#ffffff', 0.20)
    bg_dark_backdrop = blend_colors(bg_dark, '#ffffff', 0.02)
    surf_elevated_backdrop = blend_colors(surf_elevated, '#ffffff', 0.02)
else:
    if pal.get('surface_container_lowest') in ('#120e07', '#130d07', '#140c0b'):
        bg_dark = '#130d07'
        surf_elevated = '#19120c'
        surf_mid = '#19120c'
        surf_high = '#221910'
        sel_color = '#503a24'
        hover_color = '#694e33'
        # Unhovered / inactive window colors - subtly darker/subdued, NOT bright/washed-out
        bg_dark_backdrop = '#16110a'
        surf_elevated_backdrop = '#1c150e'
    else:
        bg_dark = pal.get('surface_container_lowest', '#130d07')
        surf_elevated = pal.get('surface_container_low', pal.get('surface', '#19120c'))
        if surf_elevated == bg_dark:
            surf_elevated = pal.get('surface_container', pal.get('surface_variant', '#19120c'))
        surf_mid = surf_elevated
        sel_color = pal.get('primary_container', '#503a24')
        hover_color = blend_colors(sel_color, '#ffffff', 0.20)
        bg_dark_backdrop = blend_colors(bg_dark, '#ffffff', 0.02)
        surf_elevated_backdrop = blend_colors(surf_elevated, '#ffffff', 0.02)

bg_dark_rgb = hex_to_rgb(bg_dark)
surf_elevated_rgb = hex_to_rgb(surf_elevated)
sel_color_rgb = hex_to_rgb(sel_color)
hover_color_rgb = hex_to_rgb(hover_color)
fg_rgb = hex_to_rgb(fg)
pri_rgb = hex_to_rgb(pri)
on_pri_rgb = hex_to_rgb(on_pri)
sec_rgb = hex_to_rgb(sec)
ter_rgb = hex_to_rgb(ter)
err_rgb = hex_to_rgb(err)
surf_mid_rgb = hex_to_rgb(surf_mid)
surf_high_rgb = hex_to_rgb(surf_high)
outl_rgb = hex_to_rgb(outl)

pri_rgb_tuple = hex_to_rgb_tuple(pri)
sel_color_rgb_tuple = hex_to_rgb_tuple(sel_color)

gtk3_css = f"""/* ====================================================================
 * Zenith Shell - Orchis Borderless Material GTK 3 Theme & Thunar Styling
 * Generated automatically from ~/.cache/zenith/colors.json
 * ==================================================================== */

@define-color theme_bg_color {bg_dark};
@define-color theme_fg_color {fg};
@define-color theme_base_color {bg_dark};
@define-color theme_text_color {fg};
@define-color theme_selected_bg_color {sel_color};
@define-color theme_selected_fg_color #ffffff;
@define-color theme_view_hover_decoration_color {hover_color};
@define-color placeholder_text_color {outl};
@define-color borders transparent;
@define-color unfocused_borders transparent;
@define-color warning_color {ter};
@define-color error_color {err};
@define-color success_color {ter};

@define-color content_view_bg {bg_dark};
@define-color sidebar_bg {bg_dark};
@define-color window_bg {bg_dark};
@define-color headerbar_bg {bg_dark};
@define-color headerbar_fg {fg};
@define-color headerbar_border transparent;
@define-color headerbar_backdrop {bg_dark_backdrop};

/* Universal border & separator removal */
*,
*:backdrop {{
    border-color: transparent;
    border-style: none;
    border-width: 0;
}}

frame,
frame > border,
.frame,
scrolledwindow > border,
viewport > border,
decoration,
decoration:backdrop {{
    border: none;
    border-style: none;
    border-width: 0;
    box-shadow: none;
}}

paned > separator,
paned > separator:dir(ltr),
paned > separator:dir(rtl),
paned > separator.wide,
paned.horizontal > separator,
paned.horizontal > separator:dir(ltr),
paned.horizontal > separator:dir(rtl),
paned.horizontal > separator.wide,
paned.vertical > separator,
paned.vertical > separator:dir(ltr),
paned.vertical > separator:dir(rtl),
paned.vertical > separator.wide,
separator {{
    background-color: transparent;
    background-image: none;
    border: none;
    border-style: none;
    border-width: 0;
    box-shadow: none;
    min-width: 0px;
    min-height: 0px;
    margin: 0;
    padding: 0;
}}

/* Base Surfaces & Windows - NO POINT EDGES */
window,
window.background,
window.solid-csd {{
    background-color: {bg_dark};
    color: {fg};
    border-radius: 16px;
    border-style: none;
    border-width: 0;
    box-shadow: none;
}}

/* CSD Windows & Dialogs: Top corners are shaped by headerbar/titlebar, bottom corners are rounded (16px).
 * Critically: border-top-left-radius and border-top-right-radius MUST BE 0 so the junction between
 * the headerbar and window body / notebook has NO inward notch or wallpaper peaking through! */
window.csd,
window.background.csd,
dialog,
dialog.background,
dialog.background.csd,
messagedialog,
messagedialog.csd,
.background.csd {{
    background-color: {bg_dark};
    color: {fg};
    border-radius: 0 0 16px 16px;
    border-top-left-radius: 0px;
    border-top-right-radius: 0px;
    border-bottom-left-radius: 16px;
    border-bottom-right-radius: 16px;
    border-style: none;
    border-width: 0;
    box-shadow: none;
}}

dialog > box,
dialog.background > box,
dialog.background.csd > box,
dialog.background.csd > box.dialog-vbox,
dialog.background.csd > box.vertical.dialog-vbox,
window.dialog > box,
window.background.csd > box,
window.csd > box,
box.dialog-vbox,
box.vertical.dialog-vbox {{
    background-color: {bg_dark};
    border-radius: 0px;
    border-top-left-radius: 0px;
    border-top-right-radius: 0px;
    margin: 0px;
    padding: 0px;
    border: none;
    box-shadow: none;
}}

.view,
textview text {{
    background-color: {bg_dark};
    color: {fg};
    border-radius: 12px;
    border-style: none;
    border-width: 0;
}}

/* Titlebars & Headerbars - Flat Bottom Junction */
headerbar,
.titlebar,
toolbar {{
    background-color: {bg_dark};
    color: {fg};
    border-radius: 16px 16px 0 0;
    border-top-left-radius: 16px;
    border-top-right-radius: 16px;
    border-bottom-left-radius: 0px;
    border-bottom-right-radius: 0px;
    border-style: none;
    border-width: 0;
    box-shadow: none;
    padding: 4px 8px;
}}

headerbar:backdrop,
toolbar:backdrop {{
    background-color: {bg_dark};
    color: {outl};
}}

/* Checkboxes and Radios - NO OUTSIDE COLOR, ONLY FILL INSIDE */
checkbutton,
radiobutton,
checkbutton:hover,
radiobutton:hover,
checkbutton:active,
radiobutton:active,
checkbutton:checked,
radiobutton:checked,
checkbutton:focus,
radiobutton:focus {{
    background: transparent;
    background-color: transparent;
    border: none;
    box-shadow: none;
    padding: 3px 6px;
    margin: 2px 0;
    outline: none;
}}

checkbutton button,
radiobutton button {{
    background: transparent;
    background-color: transparent;
    border: none;
    box-shadow: none;
}}

check,
radio {{
    background: transparent;
    background-color: transparent;
    border: none;
    box-shadow: none;
    color: {outl};
    min-height: 20px;
    min-width: 20px;
    margin: 0 4px 0 0;
    padding: 0;
}}

check:checked,
check:indeterminate {{
    background: transparent;
    background-color: transparent;
    border: none;
    box-shadow: none;
    color: {pri};
}}

radio:checked,
radio:indeterminate {{
    background: transparent;
    background-color: transparent;
    border: none;
    box-shadow: none;
    color: {pri};
}}

check:disabled,
radio:disabled {{
    background: transparent;
    background-color: transparent;
    border: none;
    box-shadow: none;
    color: alpha({fg}, 0.25);
}}

/* General Material Buttons (Explicitly excluding check/radio and window controls) */
button:not(.check):not(.radio):not(.titlebutton):not(.close) {{
    background-color: {surf_mid};
    color: {fg};
    border-style: none;
    border-width: 0;
    border-radius: 10px;
    padding: 6px 14px;
    font-weight: 500;
    box-shadow: none;
    transition: background-color 150ms ease, color 150ms ease;
}}

button:not(.check):not(.radio):not(.titlebutton):not(.close):hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

button:not(.check):not(.radio):not(.titlebutton):not(.close):active,
button:not(.check):not(.radio):not(.titlebutton):not(.close):checked {{
    background-color: {sel_color};
    color: #ffffff;
}}

/* Toolbar & Headerbar Action Buttons - Flat & Transparent with Material hover */
toolbar button:not(.suggested-action):not(.destructive-action):not(.path-bar-button),
headerbar button:not(.suggested-action):not(.destructive-action):not(.path-bar-button),
.titlebar button:not(.suggested-action):not(.destructive-action):not(.path-bar-button),
.thunar toolbar button:not(.path-bar-button),
.thunar headerbar button:not(.path-bar-button) {{
    background-color: transparent;
    background-image: none;
    border: none;
    box-shadow: none;
    border-radius: 9999px;
    min-width: 32px;
    min-height: 32px;
    padding: 4px;
    margin: 1px 2px;
    color: {fg};
    transition: background-color 120ms ease, color 120ms ease;
}}

toolbar button:not(.suggested-action):not(.destructive-action):not(.path-bar-button):hover,
headerbar button:not(.suggested-action):not(.destructive-action):not(.path-bar-button):hover,
.titlebar button:not(.suggested-action):not(.destructive-action):not(.path-bar-button):hover,
.thunar toolbar button:not(.path-bar-button):hover,
.thunar headerbar button:not(.path-bar-button):hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

toolbar button:not(.suggested-action):not(.destructive-action):not(.path-bar-button):active,
toolbar button:not(.suggested-action):not(.destructive-action):not(.path-bar-button):checked,
headerbar button:not(.suggested-action):not(.destructive-action):not(.path-bar-button):active,
headerbar button:not(.suggested-action):not(.destructive-action):not(.path-bar-button):checked,
.thunar toolbar button:not(.path-bar-button):active,
.thunar toolbar button:not(.path-bar-button):checked,
.thunar headerbar button:not(.path-bar-button):active,
.thunar headerbar button:not(.path-bar-button):checked {{
    background-color: {sel_color};
    color: #ffffff;
}}

/* Window Controls / Titlebuttons (e.g. 'x' close button) - Transparent matching main body */
headerbar button.titlebutton,
headerbar button.titlebutton.close,
headerbar button.close,
headerbar windowcontrols button,
headerbar windowcontrols button.close,
.titlebar button.titlebutton,
.titlebar button.titlebutton.close,
.titlebar button.close,
windowcontrols button,
windowcontrols button.close,
button.titlebutton,
button.titlebutton.close,
button.close,
.thunar headerbar button.titlebutton,
.thunar headerbar button.close,
.thunar headerbar windowcontrols button,
.thunar headerbar windowcontrols button.close,
.thunar windowcontrols button,
.thunar windowcontrols button.close,
window.background.csd.thunar headerbar button.titlebutton,
window.background.csd.thunar headerbar button.close,
window.background.csd.thunar windowcontrols button,
window.background.csd.thunar windowcontrols button.close {{
    background: transparent;
    background-color: transparent;
    border: none;
    box-shadow: none;
    border-radius: 9999px;
    min-width: 24px;
    min-height: 24px;
    padding: 4px;
    margin: 1px 2px;
    color: {fg};
    transition: background-color 120ms ease, color 120ms ease;
}}

headerbar button.titlebutton:hover,
headerbar button.titlebutton.close:hover,
headerbar button.close:hover,
headerbar windowcontrols button:hover,
headerbar windowcontrols button.close:hover,
.titlebar button.titlebutton:hover,
.titlebar button.titlebutton.close:hover,
.titlebar button.close:hover,
windowcontrols button:hover,
windowcontrols button.close:hover,
button.titlebutton:hover,
button.titlebutton.close:hover,
button.close:hover,
.thunar headerbar button.titlebutton:hover,
.thunar headerbar button.close:hover,
.thunar headerbar windowcontrols button:hover,
.thunar headerbar windowcontrols button.close:hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

headerbar button.titlebutton:active,
headerbar button.titlebutton.close:active,
headerbar button.close:active,
button.titlebutton.close:active,
.thunar headerbar button.titlebutton:active,
.thunar headerbar button.close:active {{
    background-color: {sel_color};
    color: #ffffff;
}}

headerbar button.titlebutton:backdrop,
headerbar button.titlebutton.close:backdrop,
headerbar button.close:backdrop,
button.titlebutton:backdrop,
button.titlebutton.close:backdrop,
button.close:backdrop,
windowcontrols button:backdrop,
windowcontrols button.close:backdrop,
.thunar headerbar button.titlebutton:backdrop,
.thunar headerbar button.close:backdrop,
.thunar headerbar button:backdrop {{
    background: transparent;
    background-color: transparent;
    border: none;
    box-shadow: none;
    color: alpha({fg}, 0.5);
}}

button.flat {{
    background-color: transparent;
    border-style: none;
    border-width: 0;
    box-shadow: none;
    border-radius: 8px;
}}

button.flat:hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

button.circular,
button.pill {{
    border-radius: 9999px;
}}

button.suggested-action {{
    background-color: {pri};
    color: {on_pri};
    border-radius: 9999px;
    font-weight: 600;
}}

button.destructive-action {{
    background-color: {err};
    color: {on_err};
    border-radius: 9999px;
    font-weight: 600;
}}

/* Inputs & Entries */
entry {{
    background-color: {surf_elevated};
    color: {fg};
    border-radius: 9999px;
    border-style: none;
    border-width: 0;
    padding: 6px 14px;
    box-shadow: none;
}}

entry:focus {{
    background-color: {surf_elevated};
    box-shadow: 0 0 0 1.5px {pri};
}}

/* Notebook Tabs - Pill / Rounded Material */
notebook,
notebook header {{
    background-color: {bg_dark};
    border: none;
    box-shadow: none;
    padding: 4px 6px;
}}

/* Flat Topbar Junction - Remove Rounded Corners Below Topbar */
headerbar + box,
.titlebar + box,
headerbar + notebook,
.titlebar + notebook,
window > box,
dialog > box,
dialog.background > box,
dialog.background.csd > box,
dialog.background.csd > box.dialog-vbox,
dialog.background.csd > box.vertical.dialog-vbox,
box.dialog-vbox,
box.vertical.dialog-vbox,
notebook,
notebook.frame,
notebook > header,
notebook > header.top,
notebook > stack,
notebook.frame > header.top,
notebook.frame > stack,
notebook.frame > stack scrolledwindow.frame,
.background.csd notebook,
.background.csd notebook.frame,
.background.csd notebook.frame > header,
.background.csd notebook.frame > header.top,
.background.csd notebook.frame > stack,
.background.csd notebook.frame > stack scrolledwindow.frame,
dialog.background.csd notebook,
dialog.background.csd notebook.frame,
dialog.background.csd notebook.frame > header,
dialog.background.csd notebook.frame > header.top,
dialog.background.csd > box.vertical.dialog-vbox > notebook,
dialog.background.csd > box.vertical.dialog-vbox > notebook > stack,
dialog.background.csd > box.vertical.dialog-vbox > notebook > header,
dialog.background.csd > box.vertical.dialog-vbox > notebook > header.top,
.thunar notebook,
.thunar notebook.frame,
.thunar notebook > header.top,
.thunar notebook > stack {{
    background-color: {bg_dark};
    border-top-left-radius: 0px;
    border-top-right-radius: 0px;
    border-radius: 0px;
    border: none;
    box-shadow: none;
}}

/* Dropdowns / ComboBoxes */
combobox button.combo,
combobox button {{
    background-color: {surf_mid};
    color: {fg};
    border-radius: 8px;
    border: none;
    box-shadow: none;
}}

combobox button.combo:hover,
combobox button:hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

combobox button.combo:active,
combobox button.combo:checked,
combobox button:active,
combobox button:checked {{
    background-color: {sel_color};
    color: #ffffff;
}}

/* Inner transparent containers for buttons, dropdowns, and inputs */
button box,
button label,
button image,
button > alignment,
button > alignment > box,
combobox box,
combobox button box,
combobox cellview,
combobox button cellview,
combobox label,
combobox button label,
combobox arrow,
combobox button arrow,
cellview,
cellview:not(:selected),
entry box,
entry image,
spinbutton button {{
    background-color: transparent;
    background: transparent;
}}

notebook tab {{
    background-color: transparent;
    color: {outl};
    border-radius: 10px;
    padding: 6px 14px;
    margin: 2px 3px;
    border: none;
    font-weight: 500;
    transition: all 120ms ease;
}}

notebook tab:hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

notebook tab:checked {{
    background-color: {sel_color};
    color: #ffffff;
    font-weight: 600;
}}

/* Toggle Switches */
switch {{
    background-color: {surf_high};
    border-radius: 9999px;
    min-width: 44px;
    min-height: 22px;
    border: none;
}}

switch:checked {{
    background-color: {pri};
}}

switch slider {{
    background-color: {fg};
    border-radius: 9999px;
    min-width: 16px;
    min-height: 16px;
    margin: 3px;
    border: none;
}}

switch:checked slider {{
    background-color: {on_pri};
}}

/* Sliders / Scales */
scale trough {{
    background-color: {surf_mid};
    border-radius: 9999px;
    min-height: 4px;
    border: none;
}}

scale highlight {{
    background-color: {pri};
    border-radius: 9999px;
    min-height: 4px;
    border: none;
}}

scale slider,
scale.horizontal slider,
scale.vertical slider,
scale > trough > slider,
scale.horizontal > trough > slider,
scale.vertical > trough > slider {{
    background-color: {pri};
    color: {pri};
    border-radius: 9999px;
    min-width: 18px;
    min-height: 18px;
    margin: -7px;
    border: 2px solid {bg_dark};
    box-shadow: 0 1px 4px rgba(0, 0, 0, 0.4);
    transition: background-color 120ms ease, box-shadow 120ms ease;
}}

scale slider:hover,
scale > trough > slider:hover,
scale.horizontal > trough > slider:hover,
scale.vertical > trough > slider:hover {{
    background-color: {hover_color};
    border-color: {bg_dark};
    box-shadow: 0 0 0 6px rgba({pri_rgb}, 0.20), 0 2px 6px rgba(0, 0, 0, 0.5);
}}

scale slider:active,
scale > trough > slider:active,
scale.horizontal > trough > slider:active,
scale.vertical > trough > slider:active {{
    background-color: {sel_color};
    border-color: {bg_dark};
    box-shadow: 0 0 0 8px rgba({pri_rgb}, 0.30), 0 3px 8px rgba(0, 0, 0, 0.6);
}}

scale slider:disabled,
scale.horizontal slider:disabled,
scale.vertical slider:disabled,
scale > trough > slider:disabled,
scale.horizontal > trough > slider:disabled,
scale.vertical > trough > slider:disabled {{
    background-color: rgba({fg_rgb}, 0.25);
    border-color: transparent;
    box-shadow: none;
}}

/* Popovers & Context Menus */
popover,
menu,
.menu {{
    background-color: {surf_elevated};
    color: {fg};
    border-radius: 14px;
    border: none;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.5);
    padding: 6px;
}}

menuitem {{
    border-radius: 8px;
    padding: 6px 12px;
    margin: 1px 0;
}}

menuitem:hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

/* Scrollbars */
scrollbar {{
    background-color: transparent;
    border: none;
}}

scrollbar slider {{
    background-color: alpha({fg}, 0.2);
    border-radius: 9999px;
    min-width: 8px;
    min-height: 8px;
    border: none;
}}

scrollbar slider:hover {{
    background-color: {hover_color};
}}

/* PlacesSidebar (Nautilus, GTK file pickers) */
placessidebar list row.activatable {{
    border-radius: 9999px;
    margin: 2px 8px;
    padding: 6px 12px;
    border: none;
    color: {fg};
}}

placessidebar list row.activatable:hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

placessidebar list row.activatable:selected {{
    background-color: {sel_color};
    color: #ffffff;
    font-weight: 600;
}}

/* ====================================================================
 * Thunar File Manager - Bespoke Material Styling
 * ==================================================================== */

window.thunar,
.thunar,
window.background.csd.thunar {{
    background-color: {bg_dark};
    color: {fg};
    border-radius: 16px;
    border: none;
    box-shadow: none;
}}

/* Thunar Headerbar & Toolbar */
.thunar headerbar,
.thunar toolbar,
.thunar toolbar.horizontal,
.thunar .toolbar,
.thunar .titlebar,
.thunar headerbar.titlebar toolbar,
.thunar .path-bar,
.thunar .location-bar,
.thunar menubar,
window.background.csd.thunar headerbar,
window.background.csd.thunar toolbar,
window.background.csd.thunar .location-bar,
window.background.csd.thunar .path-bar {{
    background-color: {bg_dark};
    color: {fg};
    border: none;
    box-shadow: none;
    padding: 4px 8px;
}}

.thunar toolbar *,
.thunar .path-bar *,
.thunar .location-bar * {{
    color: {fg};
}}

/* Thunar Header Navigation & Action Buttons */
.thunar headerbar button.image-button,
.thunar toolbar button.image-button,
.thunar headerbar button,
.thunar toolbar button {{
    border-radius: 9999px;
    min-width: 32px;
    min-height: 32px;
    padding: 4px;
    margin: 1px 2px;
    background-color: transparent;
    border: none;
    box-shadow: none;
    color: {fg};
    transition: background-color 120ms ease, color 120ms ease;
}}

.thunar headerbar button.image-button:hover,
.thunar toolbar button.image-button:hover,
.thunar headerbar button:hover,
.thunar toolbar button:hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

.thunar headerbar button.image-button:active,
.thunar toolbar button.image-button:active,
.thunar headerbar button:active,
.thunar toolbar button:active,
.thunar headerbar button:checked,
.thunar toolbar button:checked {{
    background-color: {sel_color};
    color: #ffffff;
}}

/* Thunar Sidebar - Flat, Seamless, Left & Right Padding */
.thunar .sidebar,
.thunar .shortcuts-pane,
.thunar scrolledwindow.sidebar,
.thunar scrolledwindow.sidebar > border,
.thunar scrolledwindow.shortcuts-pane,
.thunar > grid > paned > scrolledwindow.sidebar,
.thunar > grid.horizontal > paned.horizontal > scrolledwindow,
.thunar > grid.horizontal > paned.horizontal > scrolledwindow.frame.sidebar.shortcuts-pane,
window.background.csd.thunar > grid > paned > scrolledwindow.sidebar,
window.background.csd.thunar > grid.horizontal > paned.horizontal > scrolledwindow.frame.sidebar.shortcuts-pane {{
    background-color: {bg_dark};
    color: {fg};
    border: none;
    border-radius: 0;
    margin: 0;
    padding: 0 10px;
    box-shadow: none;
    transition: background-color 150ms ease, color 150ms ease;
}}

.thunar .sidebar treeview,
.thunar .sidebar treeview.view,
.thunar .shortcuts-pane treeview,
.thunar .sidebar treeview:backdrop,
.thunar .sidebar treeview.view:backdrop,
.thunar .shortcuts-pane treeview:backdrop {{
    background-color: transparent;
    border: none;
    border-radius: 0;
    margin: 0;
    padding: 8px 4px;
    -GtkTreeView-horizontal-separator: 8;
    -GtkTreeView-vertical-separator: 6;
    -GtkTreeView-expander-size: 14;
}}

.thunar .sidebar treeview:hover,
.thunar .sidebar treeview.view:hover {{
    background-color: transparent;
}}

/* Sidebar row hover & selection */
.thunar .sidebar treeview:selected,
.thunar .sidebar treeview.view:selected,
.thunar .shortcuts-pane treeview:selected,
.thunar .sidebar treeview:selected:backdrop,
.thunar .sidebar treeview.view:selected:backdrop,
.thunar .shortcuts-pane treeview:selected:backdrop {{
    background-color: {sel_color};
    color: #ffffff;
    font-weight: 600;
    border-radius: 9999px;
    border: none;
    box-shadow: none;
}}

/* Pane separator: ZERO width & transparent */
.thunar paned > separator,
.thunar paned separator,
.thunar paned.horizontal > separator,
.thunar paned.vertical > separator {{
    background-color: transparent;
    background-image: none;
    border: none;
    min-width: 0px;
    min-height: 0px;
    margin: 0;
    padding: 0;
}}

/* Thunar Input Bar (Address / Search Entry) - Elevated Surface #19120c */
.thunar entry,
.thunar entry.search,
entry.path-bar-entry,
.thunar textview,
.thunar textview text,
.thunar textview.view {{
    background-color: {surf_elevated};
    color: {fg};
    border-radius: 9999px;
    padding: 6px 14px;
    min-height: 28px;
    border: none;
    box-shadow: none;
}}

.thunar entry:focus,
.thunar entry.search:focus,
entry.path-bar-entry:focus {{
    box-shadow: 0 0 0 1.5px {pri};
    background-color: {surf_elevated};
}}

/* Breadcrumbs / Pathbar Buttons */
.thunar .path-bar-button,
.thunar .path-bar button,
.path-bar-button,
button.path-bar-button {{
    background-color: {surf_elevated};
    color: {fg};
    border-radius: 9999px;
    margin: 2px 2px;
    padding: 4px 14px;
    font-weight: 500;
    font-size: 13px;
    border: none;
    box-shadow: none;
    transition: all 120ms ease;
}}

.thunar .path-bar-button:hover,
button.path-bar-button:hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

.thunar .path-bar-button:checked,
.thunar .path-bar-button:active,
button.path-bar-button:checked,
button.path-bar-button:active {{
    background-color: {sel_color};
    color: #ffffff;
    font-weight: 700;
}}

/* Thunar Main File Grid / List View - Base Dark #130d07 */
.thunar .standard-view,
.thunar .standard-view.frame,
.thunar .standard-view.frame > border,
.thunar .standard-view .view,
.thunar .standard-view widget.view,
.thunar iconview,
.thunar treeview.view,
.thunar frame,
.thunar frame > border,
.thunar .frame,
.thunar .frame > border,
.thunar scrolledwindow,
.thunar scrolledwindow > border,
.thunar scrolledwindow.frame,
.thunar scrolledwindow.frame > border,
.thunar paned paned paned > notebook.frame,
.thunar paned paned paned > notebook.frame > border {{
    background-color: {bg_dark};
    color: {fg};
    border: none;
    box-shadow: none;
    outline: none;
}}

/* Hover in main view */
.thunar iconview:hover,
.thunar treeview.view:hover {{
    background-color: {hover_color};
    color: #ffffff;
    border-radius: 10px;
}}

/* Selected item in main view - STRICT OVERRIDE FOR ORCHIS #3281EA & Silhouette Bug */
.background.csd .view:selected,
.background.csd .view:selected:focus,
.background.csd .view:selected:backdrop,
.background.csd.thunar .view:selected,
.background.csd.thunar .view:selected:focus,
.background.csd.thunar .view:selected:backdrop,
.thunar .standard-view.frame .view:selected,
.thunar .standard-view.frame .view:selected:focus,
.thunar .standard-view.frame .view:selected:backdrop,
.thunar .standard-view.frame:selected,
.thunar .standard-view.frame:selected:focus,
.thunar .standard-view.frame:selected:backdrop,
.thunar .standard-view .view:selected,
.thunar .standard-view .view:selected:focus,
.thunar .standard-view .view:selected:backdrop,
.thunar .standard-view widget.view:selected,
.thunar .standard-view widget.view:selected:focus,
.thunar .standard-view widget.view:selected:backdrop,
.thunar .standard-view.frame widget.view:selected,
.thunar iconview:selected,
.thunar iconview:selected:focus,
.thunar iconview:selected:backdrop,
.thunar treeview.view:selected,
.thunar treeview.view:selected:focus,
.thunar treeview.view:selected:backdrop,
.thunar .view:selected,
.thunar .view:selected:focus,
.thunar .view:selected:backdrop,
iconview:selected,
iconview:selected:focus,
iconview:selected:backdrop,
treeview.view:selected,
treeview.view:selected:focus,
treeview.view:selected:backdrop,
.view:selected,
.view:selected:focus,
.view:selected:backdrop,
*:selected,
*:selected:focus,
*:selected:backdrop {{
    background-color: {sel_color};
    background: {sel_color};
    color: #ffffff;
    border-radius: 10px;
    border: none;
    box-shadow: none;
    -gtk-icon-effect: none;
    -gtk-icon-shadow: none;
}}

/* Rubberband / Cursor Selection Box - Exact Match to Selected Item Background */
.rubberband,
rubberband,
*.rubberband,
* rubberband,
.view.rubberband,
.view rubberband,
.view .rubberband,
iconview.rubberband,
iconview rubberband,
iconview .rubberband,
ExoIconView.rubberband,
ExoIconView rubberband,
ExoIconView .rubberband,
treeview.rubberband,
treeview rubberband,
treeview .rubberband,
treeview.view.rubberband,
treeview.view rubberband,
treeview.view .rubberband,
scrolledwindow rubberband,
scrolledwindow .rubberband,
.content-view rubberband,
.content-view .rubberband,
flowbox rubberband,
flowbox .rubberband,
XfdesktopIconView.view .rubberband,
.thunar rubberband,
.thunar .rubberband,
.thunar * rubberband,
.thunar * .rubberband,
.thunar iconview.rubberband,
.thunar iconview .rubberband,
.thunar ExoIconView.rubberband,
.thunar ExoIconView .rubberband,
.thunar treeview.rubberband,
.thunar treeview .rubberband,
window.thunar rubberband,
window.thunar .rubberband,
window.background.csd.thunar rubberband,
window.background.csd.thunar .rubberband {{
    background-color: rgba({sel_color_rgb}, 0.38);
    background: rgba({sel_color_rgb}, 0.38);
    border: 1px solid {pri};
    border-color: {pri};
    border-style: solid;
    border-width: 1px;
    border-radius: 0;
    box-shadow: none;
}}

.rubberband:backdrop,
rubberband:backdrop,
.thunar rubberband:backdrop,
.thunar .rubberband:backdrop {{
    background-color: rgba({sel_color_rgb}, 0.25);
    background: rgba({sel_color_rgb}, 0.25);
    border: 1px solid rgba({pri_rgb}, 0.6);
    border-color: rgba({pri_rgb}, 0.6);
    border-style: solid;
    border-width: 1px;
    border-radius: 0;
    box-shadow: none;
}}

/* Thunar Statusbar - Base Dark #130d07 */
.thunar statusbar,
.thunar statusbar frame,
.thunar statusbar frame > border {{
    background-color: {bg_dark};
    color: {outl};
    border: none;
    box-shadow: none;
    padding: 4px 12px;
    font-size: 12px;
    margin: 0;
}}

/* ====================================================================
 * Inactive / Not Hovered Window - Visually Lighter Hierarchy (:backdrop)
 * ==================================================================== */

window:backdrop,
window.background:backdrop,
window.csd:backdrop,
window.solid-csd:backdrop,
window.background.csd:backdrop,
dialog:backdrop,
messagedialog:backdrop,
.thunar:backdrop,
window.thunar:backdrop,
window.background.csd.thunar:backdrop {{
    background-color: {bg_dark_backdrop};
    color: alpha({fg}, 0.85);
}}

headerbar:backdrop,
.titlebar:backdrop,
toolbar:backdrop,
.thunar headerbar:backdrop,
.thunar toolbar:backdrop,
.thunar .titlebar:backdrop,
.thunar headerbar.titlebar toolbar:backdrop {{
    background-color: {bg_dark_backdrop};
    color: {outl};
}}

.thunar .sidebar:backdrop,
.thunar .shortcuts-pane:backdrop,
.thunar scrolledwindow.sidebar:backdrop,
.thunar > grid > paned > scrolledwindow.sidebar:backdrop,
.thunar > grid.horizontal > paned.horizontal > scrolledwindow:backdrop,
.thunar > grid.horizontal > paned.horizontal > scrolledwindow.frame.sidebar.shortcuts-pane:backdrop,
window.background.csd.thunar > grid > paned > scrolledwindow.sidebar:backdrop,
window.background.csd.thunar > grid.horizontal > paned.horizontal > scrolledwindow.frame.sidebar.shortcuts-pane:backdrop {{
    background-color: {bg_dark_backdrop};
    color: alpha({fg}, 0.75);
    border: none;
    border-radius: 0;
    margin: 0;
    padding: 0 10px;
}}

.thunar .standard-view:backdrop,
.thunar .standard-view.frame:backdrop,
.thunar .standard-view.frame > border:backdrop,
.thunar .standard-view .view:backdrop,
.thunar .standard-view widget.view:backdrop,
.thunar iconview:backdrop,
.thunar treeview.view:backdrop,
.thunar frame:backdrop,
.thunar .frame:backdrop,
.thunar scrolledwindow:backdrop,
.thunar scrolledwindow > border:backdrop,
.thunar scrolledwindow.frame:backdrop,
.thunar scrolledwindow.frame > border:backdrop,
.thunar paned paned paned > notebook.frame:backdrop,
.thunar paned paned paned > notebook.frame > border:backdrop {{
    background-color: {bg_dark_backdrop};
    color: alpha({fg}, 0.85);
}}

.thunar entry:backdrop,
.thunar entry.search:backdrop,
entry.path-bar-entry:backdrop,
.thunar .path-bar-button:backdrop,
button.path-bar-button:backdrop {{
    background-color: {surf_elevated_backdrop};
    color: alpha({fg}, 0.85);
}}

.thunar statusbar:backdrop,
.thunar statusbar frame:backdrop,
.thunar statusbar frame > border:backdrop {{
    background-color: {bg_dark_backdrop};
    color: {outl};
}}
"""

gtk4_css = f"""/* ====================================================================
 * Zenith Shell - Orchis Borderless Material GTK 4 / Libadwaita Theme
 * Generated automatically from ~/.cache/zenith/colors.json
 * ==================================================================== */

@define-color accent_color {pri};
@define-color accent_bg_color {sel_color};
@define-color accent_fg_color #ffffff;

@define-color window_bg_color {bg_dark};
@define-color window_fg_color {fg};

@define-color view_bg_color {bg_dark};
@define-color view_fg_color {fg};

@define-color headerbar_bg_color {bg_dark};
@define-color headerbar_fg_color {fg};
@define-color headerbar_border_color transparent;
@define-color headerbar_backdrop_color {bg_dark_backdrop};

@define-color card_bg_color {surf_elevated};
@define-color card_fg_color {fg};
@define-color card_border_color transparent;

@define-color dialog_bg_color {bg_dark};
@define-color dialog_fg_color {fg};

@define-color popover_bg_color {surf_elevated};
@define-color popover_fg_color {fg};

@define-color secondary_accent_color {sec};
@define-color secondary_accent_bg_color {sec};
@define-color secondary_accent_fg_color {on_sec};

@define-color error_color {err};
@define-color error_bg_color {err};
@define-color error_fg_color {on_err};

@define-color warning_color {ter};
@define-color warning_bg_color {ter};
@define-color warning_fg_color {on_ter};

@define-color success_color {ter};
@define-color success_bg_color {ter};
@define-color success_fg_color {on_ter};

@define-color shade_color rgba(0, 0, 0, 0.4);
@define-color scrollbar_outline_color rgba(0, 0, 0, 0.5);

/* Universal border removal */
*, *:backdrop {{
    border-color: transparent;
    border-style: none;
    border-width: 0;
}}

window {{
    border-radius: 16px;
    border-style: none;
    border-width: 0;
    background-color: {bg_dark};
    color: {fg};
}}

window:backdrop {{
    background-color: {bg_dark_backdrop};
}}

.card {{
    border-radius: 14px;
    border-style: none;
    border-width: 0;
    background-color: {surf_elevated};
}}

.card:backdrop {{
    background-color: {surf_elevated_backdrop};
}}

.navigation-sidebar,
.navigation-sidebar list {{
    background-color: {bg_dark};
    color: {fg};
    border: none;
    border-radius: 0;
    margin: 0;
    padding: 0 10px;
}}

.navigation-sidebar:backdrop,
.navigation-sidebar list:backdrop {{
    background-color: {bg_dark_backdrop};
    color: alpha({fg}, 0.75);
    border: none;
    border-radius: 0;
    margin: 0;
    padding: 0 10px;
}}

.navigation-sidebar list row {{
    border-radius: 9999px;
    margin: 2px 6px;
    padding: 6px 12px;
    border-style: none;
    border-width: 0;
}}

.navigation-sidebar list row:hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

.navigation-sidebar list row:selected {{
    background-color: {sel_color};
    color: #ffffff;
    font-weight: 600;
}}

/* Titlebuttons & Close Button in GTK 4 - Transparent matching body */
headerbar button.titlebutton,
headerbar button.close,
windowcontrols button,
windowcontrols button.close {{
    background: transparent;
    background-color: transparent;
    border: none;
    box-shadow: none;
}}

headerbar button.titlebutton:hover,
headerbar button.close:hover,
windowcontrols button:hover,
windowcontrols button.close:hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

checkbutton {{
    background: transparent;
    background-color: transparent;
    border: none;
    box-shadow: none;
    padding: 3px 6px;
    margin: 2px 0;
}}

check, radio {{
    background: transparent;
    background-color: transparent;
    border: none;
    box-shadow: none;
    color: {outl};
}}

check:checked, radio:checked {{
    background: transparent;
    background-color: transparent;
    border: none;
    box-shadow: none;
    color: {pri};
}}

button:not(.check):not(.radio) {{
    background-color: {surf_mid};
    color: {fg};
    border-radius: 10px;
    border: none;
    padding: 6px 14px;
    font-weight: 500;
}}

button:not(.check):not(.radio):hover {{
    background-color: {hover_color};
    color: #ffffff;
}}

button:not(.check):not(.radio):active,
button:not(.check):not(.radio):checked {{
    background-color: {sel_color};
    color: #ffffff;
}}

button.pill {{
    border-radius: 9999px;
    border-style: none;
    border-width: 0;
}}

/* Sliders / Scales in GTK 4 - 100% Dynamic Themed */
scale trough {{
    background-color: {surf_mid};
    background-image: none;
    border-radius: 9999px;
    min-height: 4px;
    border: none;
    box-shadow: none;
}}

scale highlight {{
    background-color: {pri};
    background-image: none;
    border-radius: 9999px;
    min-height: 4px;
    border: none;
    box-shadow: none;
}}

scale slider,
scale.horizontal slider,
scale.vertical slider,
scale > trough > slider,
scale.horizontal > trough > slider,
scale.vertical > trough > slider {{
    background-color: {pri};
    color: {pri};
    border-radius: 9999px;
    min-width: 18px;
    min-height: 18px;
    margin: -7px;
    border: 2px solid {bg_dark};
    box-shadow: 0 1px 4px rgba(0, 0, 0, 0.4);
    transition: background-color 120ms ease, box-shadow 120ms ease;
}}

scale slider:hover,
scale > trough > slider:hover,
scale.horizontal > trough > slider:hover,
scale.vertical > trough > slider:hover {{
    background-color: {hover_color};
    border-color: {bg_dark};
    box-shadow: 0 0 0 6px rgba({pri_rgb}, 0.20), 0 2px 6px rgba(0, 0, 0, 0.5);
}}

scale slider:active,
scale > trough > slider:active,
scale.horizontal > trough > slider:active,
scale.vertical > trough > slider:active {{
    background-color: {sel_color};
    border-color: {bg_dark};
    box-shadow: 0 0 0 8px rgba({pri_rgb}, 0.30), 0 3px 8px rgba(0, 0, 0, 0.6);
}}

scale slider:disabled,
scale > trough > slider:disabled {{
    background-color: rgba({fg_rgb}, 0.25);
    border-color: transparent;
    box-shadow: none;
}}

/* Flat Topbar Junction - Remove Rounded Corners Below Topbar */
headerbar + box,
.titlebar + box,
headerbar + notebook,
.titlebar + notebook,
window > box,
dialog > box,
notebook,
notebook.frame,
notebook > header,
notebook > header.top,
notebook > stack,
notebook.frame > header.top,
notebook.frame > stack {{
    border-top-left-radius: 0px;
    border-top-right-radius: 0px;
}}

/* Dropdowns & Buttons in GTK 4 */
combobox button.combo,
combobox button {{
    background-color: {surf_mid};
    color: {fg};
    border-radius: 8px;
    border: none;
}}

button box,
button label,
button image,
combobox box,
combobox button box,
combobox cellview,
combobox button cellview,
combobox label,
combobox button label,
cellview,
entry box,
entry image {{
    background-color: transparent;
    background: transparent;
}}

entry {{
    background-color: {surf_elevated};
    color: {fg};
    border-radius: 9999px;
    border: none;
    padding: 6px 14px;
}}
"""

kdeglobals_ini = f"""[General]
ColorScheme=Zenith
Name=Zenith
accentColor={pri_rgb}

[KDE]
colorScheme=Zenith
ShowDeleteCommand=true
contrast=7

[Colors:Window]
BackgroundNormal={bg_dark_rgb}
BackgroundAlternate={surf_elevated_rgb}
ForegroundNormal={fg_rgb}
ForegroundInactive={outl_rgb}
ForegroundActive={pri_rgb}
ForegroundLink={ter_rgb}
ForegroundVisited={sec_rgb}
ForegroundNegative={err_rgb}
ForegroundNeutral={ter_rgb}
ForegroundPositive={ter_rgb}

[Colors:View]
BackgroundNormal={bg_dark_rgb}
BackgroundAlternate={surf_elevated_rgb}
ForegroundNormal={fg_rgb}
ForegroundInactive={outl_rgb}
ForegroundActive={pri_rgb}
ForegroundLink={ter_rgb}
ForegroundVisited={sec_rgb}
ForegroundNegative={err_rgb}
ForegroundNeutral={ter_rgb}
ForegroundPositive={ter_rgb}

[Colors:Button]
BackgroundNormal={surf_elevated_rgb}
BackgroundAlternate={hover_color_rgb}
ForegroundNormal={fg_rgb}
ForegroundInactive={outl_rgb}
ForegroundActive={pri_rgb}
ForegroundLink={ter_rgb}
ForegroundVisited={sec_rgb}
ForegroundNegative={err_rgb}
ForegroundNeutral={ter_rgb}
ForegroundPositive={ter_rgb}

[Colors:Selection]
BackgroundNormal={sel_color_rgb}
BackgroundAlternate={hover_color_rgb}
ForegroundNormal=255,255,255
ForegroundInactive=255,255,255
ForegroundActive=255,255,255
ForegroundLink=255,255,255
ForegroundVisited=255,255,255
ForegroundNegative={err_rgb}
ForegroundNeutral=255,255,255
ForegroundPositive=255,255,255

[Colors:Tooltip]
BackgroundNormal={bg_dark_rgb}
BackgroundAlternate={surf_elevated_rgb}
ForegroundNormal={fg_rgb}
ForegroundInactive={outl_rgb}
ForegroundActive={pri_rgb}
ForegroundLink={ter_rgb}
ForegroundVisited={sec_rgb}
ForegroundNegative={err_rgb}
ForegroundNeutral={ter_rgb}
ForegroundPositive={ter_rgb}

[Colors:Complementary]
BackgroundNormal={surf_elevated_rgb}
BackgroundAlternate={bg_dark_rgb}
ForegroundNormal={fg_rgb}
ForegroundInactive={outl_rgb}
ForegroundActive={pri_rgb}

[Colors:Header]
BackgroundNormal={bg_dark_rgb}
ForegroundNormal={fg_rgb}

[WM]
activeBackground={surf_elevated_rgb}
activeForeground={fg_rgb}
inactiveBackground={bg_dark_rgb}
inactiveForeground={outl_rgb}
"""

with open(os.path.join(gtk3_dir, "gtk.css"), "w") as f:
    f.write(gtk3_css)

with open(os.path.join(gtk4_dir, "gtk.css"), "w") as f:
    f.write(gtk4_css)

for d in [gtk3_dir, gtk4_dir]:
    stray_thunar = os.path.join(d, "thunar.css")
    if os.path.isfile(stray_thunar):
        try:
            os.remove(stray_thunar)
        except OSError:
            pass

with open(os.path.join(home, ".config", "kdeglobals"), "w") as f:
    f.write(kdeglobals_ini)

with open(os.path.join(kde_schemes_dir, "Zenith.colors"), "w") as f:
    f.write(kdeglobals_ini)

with open(os.path.join(qt5ct_dir, "Zenith.conf"), "w") as f:
    f.write(kdeglobals_ini)

with open(os.path.join(qt6ct_dir, "Zenith.conf"), "w") as f:
    f.write(kdeglobals_ini)

# Patch Orchis theme files and PNG assets if installed so no hardcoded #3281EA persists
def recolor_orchis_asset(src_path, dst_path, target_rgb):
    try:
        from PIL import Image
        im = Image.open(src_path).convert('RGBA')
        pixels = im.load()
        if isinstance(target_rgb, str):
            tr, tg, tb = [int(v.strip()) for v in target_rgb.split(",")]
        else:
            tr, tg, tb = target_rgb
        w, h = im.size
        for y in range(h):
            for x in range(w):
                r, g, b, a = pixels[x, y]
                if a == 0:
                    continue
                if b > 120 and b > r + 20 and b > g + 10:
                    lum = (r * 0.299 + g * 0.587 + b * 0.114) / 117.35
                    nr = min(255, max(0, int(tr * lum)))
                    ng = min(255, max(0, int(tg * lum)))
                    nb = min(255, max(0, int(tb * lum)))
                    pixels[x, y] = (nr, ng, nb, a)
        im.save(dst_path)
    except Exception:
        pass

pristine_root = os.path.join(home, ".local", "share", "zenith", "orchis-pristine")
orchis_roots = [
    os.path.join(home, ".themes", "Orchis-Dark"),
    os.path.join(home, ".themes", "Orchis-Dark-Compact"),
    os.path.join(home, ".themes", "Orchis-Dark-hdpi"),
    os.path.join(home, ".themes", "Orchis-Dark-xhdpi"),
    os.path.join(home, ".themes", "Orchis-Dark-Compact-hdpi"),
    os.path.join(home, ".themes", "Orchis-Dark-Compact-xhdpi"),
    os.path.join(home, ".local", "share", "themes", "Orchis-Dark"),
    os.path.join(home, ".local", "share", "themes", "Orchis-Dark-Compact"),
]

for root in orchis_roots:
    theme_name = os.path.basename(root)
    for sub in ["gtk-3.0", "gtk-4.0"]:
        dpath = os.path.join(root, sub)
        if not os.path.isdir(dpath):
            continue

        # 1. Patch CSS files
        for fname in ["gtk.css", "gtk-dark.css"]:
            fpath = os.path.join(dpath, fname)
            orig_path = fpath + ".orig"
            pristine_path = os.path.join(pristine_root, theme_name, sub, fname)
            if not os.path.isfile(orig_path):
                if os.path.isfile(pristine_path):
                    shutil.copy2(pristine_path, orig_path)
                elif os.path.isfile(fpath):
                    try:
                        with open(fpath, "r", encoding="utf-8") as f_chk:
                            if "#3281ea" in f_chk.read().lower():
                                shutil.copy2(fpath, orig_path)
                    except Exception:
                        pass

            source_file = orig_path if os.path.isfile(orig_path) else (fpath if os.path.isfile(fpath) else None)
            if source_file:
                try:
                    with open(source_file, "r", encoding="utf-8") as f_in:
                        text = f_in.read()
                    text = text.replace("#3281EA", sel_color).replace("#3281ea", sel_color)
                    text = text.replace("50, 129, 234", sel_color_rgb).replace("44, 93, 160", sel_color_rgb)
                    text = text.replace(f"rgba({sel_color_rgb}, 0.3)", f"rgba({sel_color_rgb}, 0.38)")
                    text = text.replace(".background.csd notebook.frame > header.top {\n  border-radius: 12px 12px 0 0;", ".background.csd notebook.frame > header.top {\n  border-radius: 0;")
                    text = text.replace(".background.csd notebook.frame, .background.csd notebook.frame > stack {\n  border-radius: 12px;", ".background.csd notebook.frame, .background.csd notebook.frame > stack {\n  border-radius: 0 0 12px 12px;")
                    text = text.replace(".background.csd notebook.frame > header.top > tabs > tab {\n  border-radius: 12px 12px 0 0;", ".background.csd notebook.frame > header.top > tabs > tab {\n  border-radius: 0;")
                    with open(fpath, "w", encoding="utf-8") as f_out:
                        f_out.write(text)
                except Exception:
                    pass

        # 2. Patch PNG assets (scale sliders, marks, checkboxes, rows)
        assets_dir = os.path.join(dpath, "assets")
        if os.path.isdir(assets_dir):
            for aname in os.listdir(assets_dir):
                if not aname.endswith(".png") or aname.endswith(".orig.png"):
                    continue
                apath = os.path.join(assets_dir, aname)
                aorig = os.path.join(assets_dir, aname[:-4] + ".orig.png")
                pristine_asset = os.path.join(pristine_root, theme_name, sub, "assets", aname)

                if os.path.isfile(pristine_asset):
                    shutil.copy2(pristine_asset, aorig)
                elif not os.path.isfile(aorig) and os.path.isfile(apath):
                    try:
                        from PIL import Image
                        chk = Image.open(apath).convert('RGBA').getcolors(maxcolors=2048)
                        if chk and any(a > 10 and b > 120 and b > r + 20 and b > g + 10 for count, (r, g, b, a) in chk):
                            shutil.copy2(apath, aorig)
                    except Exception:
                        pass

                if os.path.isfile(aorig):
                    target = sel_color_rgb_tuple if "row-selected" in aname else pri_rgb_tuple
                    recolor_orchis_asset(aorig, apath, target)
GTK_QT_PY

if [[ "${THEME_HYPRLAND:-0}" == "1" && -f "$HYPR_STAGE" ]]; then
    if ! validate_scheme "$HYPR_STAGE"; then
        log_err "Generated Hyprland scheme is malformed; keeping the existing one."
        exit 1
    fi

    [[ -f "$HYPR_SCHEME" ]] && cp -f "$HYPR_SCHEME" "$CACHE_DIR/hypr-scheme.previous.lua"
    mv -f "$HYPR_STAGE" "$HYPR_SCHEME"
    log "Hyprland scheme written to $HYPR_SCHEME"
fi

# Write runtime config state
cat > "$THEME_CONFIG" <<EOF
{
  "mode": "$MODE",
  "preset": "$PRESET_NAME",
  "accent": "$ACCENT_OVERRIDE",
  "scheme_type": "${SCHEME_TYPE:-scheme-tonal-spot}",
  "wallpaper": "${WALLPAPER:-}"
}
EOF

# --- Modular App Theme Hooks ---
HOOKS_DIR="$SHELL_DIR/scripts/theme-hooks.d"
if [[ -d "$HOOKS_DIR" ]]; then
    log_step "Executing app theme hooks"
    for hook in "$HOOKS_DIR"/*.sh; do
        if [[ -f "$hook" && -x "$hook" ]]; then
            log "Running hook: $(basename "$hook")"
            "$hook" "$PALETTE" || log_err "Hook failed: $(basename "$hook")"
        fi
    done
fi

# --- Refresh live components ---
log_step "Refreshing compositor and apps"

if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl reload >/dev/null 2>&1 && log "Hyprland reloaded"
fi

killall -USR1 kitty 2>/dev/null && log "kitty reloaded"

if command -v thunar >/dev/null 2>&1; then
    thunar -q 2>/dev/null || true
fi

# Clean up any stray thunar.css leftover from other shells
rm -f "$HOME/.config/gtk-3.0/thunar.css" "$HOME/.config/gtk-4.0/thunar.css" 2>/dev/null || true

if command -v dconf >/dev/null 2>&1; then
    dconf write /org/gnome/desktop/interface/gtk-theme "'Orchis-Dark'" 2>/dev/null || true
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
fi

if command -v gsettings >/dev/null 2>&1; then
    for s in /run/current-system/sw/share/gsettings-schemas/* "$HOME/.nix-profile/share/gsettings-schemas"/* /nix/store/*gsettings-desktop-schemas*/share/gsettings-schemas/*; do
        [[ -d "$s" ]] && export XDG_DATA_DIRS="$s:${XDG_DATA_DIRS:-}"
    done
    gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
    sleep 0.05
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
fi

log_ok "Zenith theme updated successfully."
