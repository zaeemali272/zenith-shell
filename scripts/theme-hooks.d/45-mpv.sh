#!/usr/bin/env bash
# Hook: MPV + uosc dynamic Material 3 theme generator
# Generates ~/.config/mpv/script-opts/uosc.conf with Zenith palette
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

MPV_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mpv"
OPTS_DIR="$MPV_DIR/script-opts"
mkdir -p "$OPTS_DIR"

python3 - "$PALETTE" "$OPTS_DIR/uosc.conf" <<'EOF'
import json, sys, os

pal_path, conf_path = sys.argv[1], sys.argv[2]
try:
    with open(pal_path) as f:
        p = json.load(f)
except Exception:
    sys.exit(0)

def strip_hash(c):
    return str(c).lstrip('#')

# M3 Color Tokens
bg = strip_hash(p.get('surface_container_lowest', p.get('background', '#121212')))
surf = strip_hash(p.get('surface', '#1a1a1a'))
pri = strip_hash(p.get('primary', '#cba6f7'))
on_pri = strip_hash(p.get('on_primary', '#000000'))
sec = strip_hash(p.get('secondary', '#89b4fa'))
fg = strip_hash(p.get('on_surface', '#f1dfdb'))
outl = strip_hash(p.get('outline', '#9a8f80'))
err = strip_hash(p.get('error', '#ffb4ab'))

uosc_conf = f"""# Zenith Material Design 3 configuration for uosc (mpv)
# Auto-generated dynamically by Zenith Shell

# Timeline layout
timeline_style=line
timeline_line_width=2
timeline_size=32
timeline_border=0
timeline_persistency=
timeline_cache=yes

# Progress bar at window bottom
progress=windowed
progress_size=2
progress_line_width=20

# Minimalist modern controls
controls=menu,gap,subtitles,<has_many_audio>audio,<has_many_video>video,gap,space,speed,space,prev,play-pause,next,gap,fullscreen
controls_size=30
controls_margin=10
controls_spacing=4
controls_persistency=

# Sleek borderless top bar
top_bar=no-border
top_bar_size=36
top_bar_title=yes
top_bar_controls=right
top_bar_flash_on=video,audio

# Volume & Speed
volume=right
volume_size=36
volume_border=0
speed_step=0.1

# Aesthetics & Geometry
border_radius=8
animation_duration=120
proximity_in=40
proximity_out=100
pause_indicator=flash

# Dynamic Material Design 3 Palette
color=foreground={pri},foreground_text={on_pri},background={bg},background_text={fg},curtain={bg},match={pri},heatmap={sec},window_border={bg},success={pri},error={err}
opacity=timeline=0.9,position=1,chapters=0.8,slider=0.9,slider_gauge=1,controls=0,speed=0.6,menu=0.95,submenu=0.5,border=1,title=1,tooltip=1,thumbnail=1,curtain=0.85
"""

with open(conf_path, 'w') as f:
    f.write(uosc_conf)

print(f"Updated MPV uosc theme at {conf_path}")
EOF
