#!/usr/bin/env bash
# Hook: Zed editor theme generator
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

ZED_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zed"
mkdir -p "$ZED_DIR/themes"

python3 - "$PALETTE" "$ZED_DIR/themes/zenith.json" "$ZED_DIR/settings.json" <<'EOF'
import json, sys, os

pal_path, theme_out, settings_path = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(pal_path) as f:
        p = json.load(f)
except Exception:
    sys.exit(0)

bg = p.get('surface_container_lowest', p.get('background', '#140c0b'))
surf_low = p.get('surface_container_low', '#19120c')
surf = p.get('surface_container', '#241f17')
surf_high = p.get('surface_container_high', '#2e2921')
fg = p.get('on_surface', '#f1dfdb')
fg_muted = p.get('on_surface_variant', '#d8c2be')
pri = p.get('primary', '#ffb4a7')
on_pri = p.get('on_primary', '#561e15')
sec = p.get('secondary', '#e7bdb5')
ter = p.get('tertiary', '#ddc48c')
err = p.get('error', '#ffb4ab')
outl = p.get('outline', '#9a8f80')
outl_var = p.get('outline_variant', '#4e4639')
pri_cont = p.get('primary_container', '#503a24')

zed_theme = {
    "$schema": "https://zed.dev/schema/themes/v0.1.0.json",
    "name": "Zenith",
    "author": "Zenith Shell",
    "themes": [
        {
            "name": "Zenith Dark",
            "appearance": "dark",
            "style": {
                "border": outl_var,
                "border.variant": outl_var,
                "border.focused": pri,
                "border.selected": pri,
                "border.transparent": "transparent",
                "elevated_surface.background": surf_low,
                "surface.background": surf,
                "background": bg,
                "element.background": surf,
                "element.hover": surf_high,
                "element.active": pri_cont,
                "element.selected": pri_cont,
                "element.disabled": outl_var,
                "drop_target.background": surf_high,
                "ghost_element.hover": surf_low,
                "ghost_element.active": surf,
                "ghost_element.selected": pri_cont,
                "text": fg,
                "text.muted": fg_muted,
                "text.accent": pri,
                "text.disabled": outl,
                "icon": fg,
                "icon.muted": fg_muted,
                "icon.accent": pri,
                "status_bar.background": bg,
                "title_bar.background": bg,
                "toolbar.background": bg,
                "tab_bar.background": bg,
                "tab.inactive_background": bg,
                "tab.active_background": surf,
                "panel.background": surf_low,
                "panel.focused_border": pri,
                "pane.focused_border": pri,
                "scrollbar_thumb.background": surf_high,
                "scrollbar_thumb.hover_background": outl,
                "scrollbar_track.background": bg,
                "scrollbar_track.border": outl_var,
                "editor.foreground": fg,
                "editor.background": bg,
                "editor.gutter.background": bg,
                "editor.active_line.background": surf_low,
                "editor.highlighted_line.background": surf,
                "editor.line_number": outl,
                "editor.active_line_number": pri,
                "terminal.background": bg,
                "terminal.foreground": fg,
                "terminal.ansi.black": bg,
                "terminal.ansi.red": err,
                "terminal.ansi.green": ter,
                "terminal.ansi.yellow": pri,
                "terminal.ansi.blue": sec,
                "terminal.ansi.magenta": pri,
                "terminal.ansi.cyan": sec,
                "terminal.ansi.white": fg,
                "terminal.ansi.bright_black": outl,
                "terminal.ansi.bright_red": err,
                "terminal.ansi.bright_green": ter,
                "terminal.ansi.bright_yellow": pri,
                "terminal.ansi.bright_blue": sec,
                "terminal.ansi.bright_magenta": pri,
                "terminal.ansi.bright_cyan": sec,
                "terminal.ansi.bright_white": "#ffffff",
                "players": [
                    {
                        "cursor": pri,
                        "background": pri,
                        "selection": surf_high
                    }
                ],
                "syntax": {
                    "comment": { "color": outl, "font_style": "italic" },
                    "constant": { "color": pri },
                    "function": { "color": sec },
                    "keyword": { "color": pri },
                    "number": { "color": ter },
                    "operator": { "color": sec },
                    "property": { "color": fg },
                    "string": { "color": ter },
                    "type": { "color": ter },
                    "variable": { "color": fg }
                }
            }
        }
    ]
}

with open(theme_out, "w", encoding="utf-8") as f:
    json.dump(zed_theme, f, indent=2)

# Update settings.json to use Zenith Dark if settings exist
if os.path.isfile(settings_path):
    try:
        # Strip trailing commas or comments for basic parse, or read carefully
        with open(settings_path, "r", encoding="utf-8") as f:
            raw = f.read()
        import re
        # If theme block exists, ensure "dark": "Zenith Dark"
        if '"theme":' in raw:
            new_raw = re.sub(r'("dark"\s*:\s*)"[^"]+"', r'\1"Zenith Dark"', raw)
            if new_raw != raw:
                with open(settings_path, "w", encoding="utf-8") as f:
                    f.write(new_raw)
        else:
            # Insert theme into settings JSON
            idx = raw.rfind('}')
            if idx != -1:
                theme_str = ',\n  "theme": {\n    "mode": "system",\n    "light": "One Dark",\n    "dark": "Zenith Dark"\n  }\n}'
                new_raw = raw[:idx].rstrip().rstrip(',') + theme_str
                with open(settings_path, "w", encoding="utf-8") as f:
                    f.write(new_raw)
    except Exception:
        pass
EOF
