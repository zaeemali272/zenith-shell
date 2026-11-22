#!/usr/bin/env bash
# Hook: Zen Browser theme generator
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zenith"
mkdir -p "$CACHE_DIR"

python3 - "$PALETTE" "$CACHE_DIR/zen.css" "$HOME/.zen" <<'EOF'
import json, sys, os, glob

pal_path, cache_out, zen_home = sys.argv[1], sys.argv[2], sys.argv[3]
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

css_content = f"""/* Zenith Material Design 3 Theme for Zen Browser */
/* Generated dynamically by Zenith Shell */

:root {{
  /* Zen color variables */
  --zen-primary-color: {pri} !important;
  --zen-colors-primary: {pri} !important;
  --zen-colors-primary-foreground: {on_pri} !important;
  --zen-colors-secondary: {sec} !important;
  --zen-colors-tertiary: {ter} !important;
  --zen-colors-base: {bg} !important;
  --zen-colors-base-90: {surf_low} !important;
  --zen-colors-base-80: {surf} !important;
  --zen-colors-base-70: {surf_high} !important;
  --zen-colors-surface: {surf} !important;
  --zen-colors-surface-container: {surf_low} !important;
  --zen-colors-border: {outl_var} !important;

  /* Native Firefox chrome tokens */
  --toolbar-bgcolor: {surf_low} !important;
  --toolbar-color: {fg} !important;
  --lwt-accent-color: {bg} !important;
  --lwt-text-color: {fg} !important;
  --toolbar-field-background-color: {surf} !important;
  --toolbar-field-color: {fg} !important;
  --toolbar-field-focus-background-color: {surf_high} !important;
  --toolbar-field-focus-color: {fg} !important;
  --toolbar-field-border-color: {outl_var} !important;
  --tab-selected-bgcolor: {surf} !important;
  --tab-selected-textcolor: {pri} !important;
  --arrowpanel-background: {surf_low} !important;
  --arrowpanel-color: {fg} !important;
  --arrowpanel-border-color: {outl_var} !important;
}}
"""

with open(cache_out, "w", encoding="utf-8") as f:
    f.write(css_content)

# Look for Zen profiles
if os.path.isdir(zen_home):
    for entry in os.listdir(zen_home):
        profile_path = os.path.join(zen_home, entry)
        if os.path.isdir(profile_path) and ("Default" in entry or "default" in entry or entry.endswith(".default-release")):
            chrome_dir = os.path.join(profile_path, "chrome")
            os.makedirs(chrome_dir, exist_ok=True)
            
            # Write profile-local zenith-colors.css
            colors_css_path = os.path.join(chrome_dir, "zenith-colors.css")
            with open(colors_css_path, "w", encoding="utf-8") as f:
                f.write(css_content)
                
            # Ensure userChrome.css imports zenith-colors.css
            user_chrome_path = os.path.join(chrome_dir, "userChrome.css")
            import_statement = '@import url("zenith-colors.css");\n'
            
            if os.path.isfile(user_chrome_path):
                with open(user_chrome_path, "r", encoding="utf-8") as f:
                    u_content = f.read()
                if '@import url("zenith-colors.css");' not in u_content:
                    with open(user_chrome_path, "w", encoding="utf-8") as f:
                        f.write(import_statement + u_content)
            else:
                with open(user_chrome_path, "w", encoding="utf-8") as f:
                    f.write(import_statement)
EOF
