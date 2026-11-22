#!/usr/bin/env bash
# Hook: Obsidian theme snippet generator
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zenith"
mkdir -p "$CACHE_DIR"

python3 - "$PALETTE" "$CACHE_DIR/obsidian-zenith.css" "$HOME/.config/obsidian/obsidian.json" <<'EOF'
import json, sys, os

pal_path, cache_out, obs_json_path = sys.argv[1], sys.argv[2], sys.argv[3]
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
sec = p.get('secondary', '#e7bdb5')
ter = p.get('tertiary', '#ddc48c')
outl_var = p.get('outline_variant', '#4e4639')

css_content = f"""/* Zenith Material Design 3 Theme snippet for Obsidian */
/* Generated dynamically by Zenith Shell */

.theme-dark {{
  --color-base-00: {bg};
  --color-base-10: {surf_low};
  --color-base-20: {surf};
  --color-base-30: {surf_high};
  --background-primary: {bg};
  --background-primary-alt: {surf_low};
  --background-secondary: {surf_low};
  --background-secondary-alt: {surf};
  --background-modifier-border: {outl_var};
  --background-modifier-border-hover: {pri};
  --text-normal: {fg};
  --text-muted: {fg_muted};
  --text-accent: {pri};
  --interactive-accent: {pri};
  --interactive-accent-hover: {sec};
  --titlebar-background: {bg};
  --tab-background-active: {surf};
  --nav-item-color-hover: {pri};
  --nav-item-color-active: {pri};
}}
"""

with open(cache_out, "w", encoding="utf-8") as f:
    f.write(css_content)

# If Obsidian config exists, check for vaults
if os.path.isfile(obs_json_path):
    try:
        with open(obs_json_path, "r", encoding="utf-8") as f:
            obs_cfg = json.load(f)
        vaults = obs_cfg.get("vaults", {})
        for vkey, vinfo in vaults.items():
            vpath = vinfo.get("path")
            if vpath and os.path.isdir(vpath):
                snippets_dir = os.path.join(vpath, ".obsidian", "snippets")
                os.makedirs(snippets_dir, exist_ok=True)
                with open(os.path.join(snippets_dir, "zenith.css"), "w", encoding="utf-8") as sf:
                    sf.write(css_content)
                
                # Check app.json to enable snippet
                app_json = os.path.join(vpath, ".obsidian", "app.json")
                app_data = {}
                if os.path.isfile(app_json):
                    try:
                        with open(app_json, "r", encoding="utf-8") as af:
                            app_data = json.load(af)
                    except Exception:
                        pass
                snippets = app_data.get("enabledCssSnippets", [])
                if "zenith" not in snippets:
                    snippets.append("zenith")
                    app_data["enabledCssSnippets"] = snippets
                    with open(app_json, "w", encoding="utf-8") as af:
                        json.dump(app_data, af, indent=2)
    except Exception:
        pass
EOF
