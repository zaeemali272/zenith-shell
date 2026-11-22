#!/usr/bin/env bash
# Hook: Btop system monitor theme generator
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

BTOP_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/btop"
THEMES_DIR="$BTOP_DIR/themes"
mkdir -p "$THEMES_DIR"

python3 - "$PALETTE" "$THEMES_DIR/zenith.theme" "$BTOP_DIR/btop.conf" <<'EOF'
import json, sys, os, re

pal_path, theme_out, conf_path = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(pal_path) as f:
        p = json.load(f)
except Exception:
    sys.exit(0)

# Extract M3 tokens with fallbacks
bg = p.get('surface_container_lowest', p.get('background', '#140c0b'))
fg = p.get('on_surface', '#f1dfdb')
pri = p.get('primary', '#ffb4a7')
sec = p.get('secondary', '#e7bdb5')
ter = p.get('tertiary', '#ddc48c')
err = p.get('error', '#ffb4ab')
outl = p.get('outline', '#9a8f80')
outl_var = p.get('outline_variant', '#52443b')
surf_high = p.get('surface_container_high', '#312822')
surf_mid = p.get('surface_container', '#261e19')
on_surf_var = p.get('on_surface_variant', '#d7c3b7')

theme_content = f"""# Zenith Material Design 3 theme for Btop
# Generated dynamically by Zenith Shell

theme[main_bg]="{bg}"
theme[main_fg]="{fg}"
theme[title]="{pri}"
theme[hi_fg]="{ter}"
theme[selected_bg]="{surf_high}"
theme[selected_fg]="{pri}"
theme[inactive_fg]="{outl}"
theme[graph_text]="{on_surf_var}"
theme[meter_bg]="{surf_mid}"
theme[proc_misc]="{sec}"

# Box outlines and dividers
theme[cpu_box]="{outl_var}"
theme[mem_box]="{outl_var}"
theme[net_box]="{outl_var}"
theme[proc_box]="{outl_var}"
theme[div_line]="{outl_var}"

# Temperature gradient
theme[temp_start]="{pri}"
theme[temp_mid]="{ter}"
theme[temp_end]="{err}"

# CPU usage gradient
theme[cpu_start]="{pri}"
theme[cpu_mid]="{sec}"
theme[cpu_end]="{ter}"

# Memory gradient (available)
theme[free_start]="{ter}"
theme[free_mid]="{sec}"
theme[free_end]="{pri}"

# Memory gradient (used)
theme[used_start]="{sec}"
theme[used_mid]="{ter}"
theme[used_end]="{err}"

# Network transfer gradient
theme[download_start]="{sec}"
theme[download_mid]="{ter}"
theme[download_end]="{pri}"
theme[upload_start]="{ter}"
theme[upload_mid]="{sec}"
theme[upload_end]="{pri}"

# Process usage gradient
theme[process_start]="{pri}"
theme[process_mid]="{sec}"
theme[process_end]="{ter}"
"""

with open(theme_out, "w", encoding="utf-8") as f:
    f.write(theme_content)

# Update btop.conf color_theme if the file exists
if os.path.isfile(conf_path):
    try:
        with open(conf_path, "r", encoding="utf-8") as f:
            content = f.read()
        if 'color_theme =' in content:
            new_content = re.sub(r'color_theme\s*=\s*".*?"', 'color_theme = "zenith"', content)
            if new_content != content:
                with open(conf_path, "w", encoding="utf-8") as f:
                    f.write(new_content)
    except Exception:
        pass
EOF

# Trigger btop reload if running
pkill -SIGUSR2 btop 2>/dev/null || true
