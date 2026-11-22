#!/usr/bin/env bash
# Hook: Yazi file manager theme generator
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

YAZI_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
mkdir -p "$YAZI_DIR"

python3 - "$PALETTE" "$YAZI_DIR/theme.toml" <<'EOF'
import json, sys

pal_path, theme_out = sys.argv[1], sys.argv[2]
try:
    with open(pal_path) as f:
        p = json.load(f)
except Exception:
    sys.exit(0)

bg = p.get('surface_container_lowest', p.get('background', '#140c0b'))
fg = p.get('on_surface', '#f1dfdb')
pri = p.get('primary', '#ffb4a7')
on_pri = p.get('on_primary', '#561e15')
sec = p.get('secondary', '#e7bdb5')
on_sec = p.get('on_secondary', '#442a25')
ter = p.get('tertiary', '#ddc48c')
on_ter = p.get('on_tertiary', '#3d2e04')
err = p.get('error', '#ffb4ab')
on_err = p.get('on_error', '#690005')
outl = p.get('outline', '#9a8f80')
outl_var = p.get('outline_variant', '#52443b')
surf_low = p.get('surface_container_low', '#221a15')
surf_mid = p.get('surface_container', '#261e19')
surf_high = p.get('surface_container_high', '#312822')
on_surf_var = p.get('on_surface_variant', '#d7c3b7')

content = f"""# Zenith Material Design 3 theme for Yazi
# Generated dynamically by Zenith Shell

[mgr]
cwd = {{ fg = "{pri}" }}
hovered = {{ bg = "{surf_high}", fg = "{fg}" }}
preview_hovered = {{ underline = true }}
find_keyword = {{ fg = "{ter}", bold = true }}
find_position = {{ fg = "{sec}", italic = true }}
marker_copied = {{ fg = "{pri}", bg = "{surf_low}" }}
marker_cut = {{ fg = "{err}", bg = "{surf_low}" }}
marker_marked = {{ fg = "{ter}", bg = "{surf_low}" }}
marker_selected = {{ fg = "{sec}", bg = "{surf_low}" }}
tab_active = {{ bg = "{pri}", fg = "{on_pri}" }}
tab_inactive = {{ bg = "{surf_mid}", fg = "{on_surf_var}" }}
count_copied = {{ fg = "{on_pri}", bg = "{pri}" }}
count_cut = {{ fg = "{on_err}", bg = "{err}" }}
count_selected = {{ fg = "{on_sec}", bg = "{sec}" }}
border_style = {{ fg = "{outl_var}" }}

[status]
separator_open = ""
separator_close = ""
separator_style = {{ fg = "{surf_high}", bg = "{surf_high}" }}
mode_normal = {{ bg = "{pri}", fg = "{on_pri}", bold = true }}
mode_select = {{ bg = "{sec}", fg = "{on_sec}", bold = true }}
mode_unset = {{ bg = "{ter}", fg = "{on_ter}", bold = true }}
progress_label = {{ bold = true }}
progress_normal = {{ fg = "{pri}", bg = "{surf_mid}" }}
progress_error = {{ fg = "{err}", bg = "{surf_mid}" }}
permissions_t = {{ fg = "{pri}" }}
permissions_r = {{ fg = "{sec}" }}
permissions_w = {{ fg = "{err}" }}
permissions_x = {{ fg = "{ter}" }}
permissions_s = {{ fg = "{on_surf_var}" }}

[select]
border = {{ fg = "{outl_var}" }}
active = {{ fg = "{pri}" }}
inactive = {{ fg = "{on_surf_var}" }}

[input]
border = {{ fg = "{pri}" }}
title = {{ fg = "{fg}" }}
value = {{ fg = "{fg}" }}
selected = {{ bg = "{surf_high}" }}

[completion]
border = {{ fg = "{outl_var}" }}
active = {{ bg = "{surf_high}", fg = "{pri}" }}
inactive = {{ fg = "{on_surf_var}" }}

[tasks]
border = {{ fg = "{outl_var}" }}
title = {{ fg = "{pri}" }}
hovered = {{ bg = "{surf_high}" }}

[which]
cols = 3
mask = {{ bg = "{bg}" }}
cand = {{ fg = "{pri}" }}
rest = {{ fg = "{fg}" }}
desc = {{ fg = "{on_surf_var}" }}
separator = "  "
separator_style = {{ fg = "{outl}" }}

[help]
on = {{ fg = "{pri}" }}
exec = {{ fg = "{ter}" }}
desc = {{ fg = "{fg}" }}
hovered = {{ bg = "{surf_high}" }}
footer = {{ fg = "{on_surf_var}", bg = "{surf_mid}" }}

[filetype]
rules = [
  {{ mime = "image/*", fg = "{ter}" }},
  {{ mime = "audio/*", fg = "{sec}" }},
  {{ mime = "video/*", fg = "{sec}" }},
  {{ mime = "application/*zip*", fg = "{err}" }},
  {{ mime = "application/x-{{tar,bzip*,7z-compressed,xz,rar}}", fg = "{err}" }},
  {{ mime = "application/pdf", fg = "{pri}" }},
  {{ name = "*/", fg = "{pri}" }}
]
"""

with open(theme_out, "w", encoding="utf-8") as f:
    f.write(content)
EOF
