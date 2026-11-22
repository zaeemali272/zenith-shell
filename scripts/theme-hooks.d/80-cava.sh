#!/usr/bin/env bash
# Hook: Cava audio visualizer gradient generator
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

CAVA_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/cava/config"

python3 - "$PALETTE" "$CAVA_CONF" <<'EOF'
import json, sys, os, re

pal_path, cava_path = sys.argv[1], sys.argv[2]
try:
    with open(pal_path) as f:
        p = json.load(f)
except Exception:
    sys.exit(0)

def hex_to_rgb(h):
    h = h.strip().lstrip("#")
    return [int(h[i:i+2], 16) for i in (0, 2, 4)]

def blend(c1, c2, factor):
    r1, g1, b1 = hex_to_rgb(c1)
    r2, g2, b2 = hex_to_rgb(c2)
    r = int(r1 * (1 - factor) + r2 * factor)
    g = int(g1 * (1 - factor) + g2 * factor)
    b = int(b1 * (1 - factor) + b2 * factor)
    return f"#{r:02x}{g:02x}{b:02x}"

pri = p.get('primary', '#ffb4a7')
sec = p.get('secondary', '#e7bdb5')
ter = p.get('tertiary', '#ddc48c')

# 8 gradient stops from primary to secondary to tertiary
stops = [
    pri,
    blend(pri, sec, 0.33),
    blend(pri, sec, 0.66),
    sec,
    blend(sec, ter, 0.33),
    blend(sec, ter, 0.66),
    blend(sec, ter, 0.85),
    ter
]

color_section = f"""[color]
gradient = 1
gradient_count = 8
gradient_color_1 = '{stops[0]}'
gradient_color_2 = '{stops[1]}'
gradient_color_3 = '{stops[2]}'
gradient_color_4 = '{stops[3]}'
gradient_color_5 = '{stops[4]}'
gradient_color_6 = '{stops[5]}'
gradient_color_7 = '{stops[6]}'
gradient_color_8 = '{stops[7]}'"""

if os.path.isfile(cava_path):
    try:
        with open(cava_path, "r", encoding="utf-8") as f:
            content = f.read()
        if re.search(r'^\s*\[color\]', content, re.MULTILINE):
            new_content = re.sub(
                r'\[color\](?:(?!\n\[).)*',
                color_section,
                content,
                flags=re.DOTALL
            )
            with open(cava_path, "w", encoding="utf-8") as f:
                f.write(new_content)
        else:
            with open(cava_path, "a", encoding="utf-8") as f:
                f.write("\n" + color_section + "\n")
    except Exception:
        pass
EOF

pkill -SIGUSR1 cava 2>/dev/null || true
