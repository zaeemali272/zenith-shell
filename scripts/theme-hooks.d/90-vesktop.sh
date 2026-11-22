#!/usr/bin/env bash
# Hook: Vesktop / Discord theme generator
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zenith"
mkdir -p "$CACHE_DIR"

python3 - "$PALETTE" "$CACHE_DIR/discord.css" "$HOME/.config/vesktop/themes/zenith.css" <<'EOF'
import json, sys, os

pal_path, cache_out, vesktop_theme = sys.argv[1], sys.argv[2], sys.argv[3]
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

css_content = f"""/**
 * @name Zenith
 * @description Material Design 3 theme matching Zenith Shell
 * @author Zenith
 * @version 1.0.0
 */

:root {{
  --background-primary: {bg} !important;
  --background-secondary: {surf_low} !important;
  --background-secondary-alt: {surf} !important;
  --background-tertiary: {bg} !important;
  --background-accent: {surf_high} !important;
  --background-floating: {surf_low} !important;
  --background-nested-floating: {bg} !important;
  --channeltextarea-background: {surf} !important;

  --brand-experiment: {pri} !important;
  --brand-experiment-560: {pri} !important;
  --brand-experiment-600: {sec} !important;

  --text-normal: {fg} !important;
  --text-muted: {fg_muted} !important;
  --text-link: {ter} !important;
  --header-primary: {fg} !important;
  --header-secondary: {fg_muted} !important;

  --interactive-normal: {fg_muted} !important;
  --interactive-hover: {fg} !important;
  --interactive-active: {pri} !important;
  --interactive-muted: {outl_var} !important;

  --scrollbar-thin-thumb: {surf_high} !important;
  --scrollbar-auto-thumb: {surf_high} !important;
  --scrollbar-auto-track: transparent !important;
}}
"""

with open(cache_out, "w", encoding="utf-8") as f:
    f.write(css_content)

vdir = os.path.dirname(vesktop_theme)
if os.path.isdir(os.path.dirname(vdir)):
    os.makedirs(vdir, exist_ok=True)
    with open(vesktop_theme, "w", encoding="utf-8") as f:
        f.write(css_content)
EOF
