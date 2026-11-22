#!/usr/bin/env bash
# Hook: FZF & Fish syntax highlighting theme generator
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zenith"
mkdir -p "$CACHE_DIR"

python3 - "$PALETTE" "$CACHE_DIR/zenith-fzf.fish" "$CACHE_DIR/zenith-fzf.sh" <<'EOF'
import json, sys

pal_path, fish_out, sh_out = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(pal_path) as f:
        p = json.load(f)
except Exception:
    sys.exit(0)

bg = p.get('surface_container_lowest', p.get('background', '#140c0b'))
surf_high = p.get('surface_container_high', '#312822')
fg = p.get('on_surface', '#f1dfdb')
pri = p.get('primary', '#ffb4a7')
sec = p.get('secondary', '#e7bdb5')
ter = p.get('tertiary', '#ddc48c')
err = p.get('error', '#ffb4ab')
outl = p.get('outline', '#9a8f80')

fzf_opts = f"--color=bg+:{surf_high},bg:{bg},spinner:{pri},hl:{sec},fg:{fg},header:{sec},info:{ter},pointer:{pri},marker:{pri},fg+:{fg},prompt:{pri},hl+:{pri}"

fish_content = f"""# Zenith Material Design 3 theme for Fish and FZF
# Generated dynamically by Zenith Shell

set -gx FZF_DEFAULT_OPTS "{fzf_opts}"

# Fish syntax highlighting
set -g fish_color_normal "{fg}"
set -g fish_color_command "{pri}"
set -g fish_color_keyword "{pri}"
set -g fish_color_quote "{ter}"
set -g fish_color_redirection "{sec}"
set -g fish_color_end "{sec}"
set -g fish_color_error "{err}"
set -g fish_color_param "{fg}"
set -g fish_color_comment "{outl}"
set -g fish_color_selection --background="{surf_high}"
set -g fish_color_search_match --background="{surf_high}"
set -g fish_color_operator "{sec}"
set -g fish_color_escape "{ter}"
set -g fish_color_autosuggestion "{outl}"

# Fish completion pager
set -g fish_pager_color_prefix "{pri}"
set -g fish_pager_color_completion "{fg}"
set -g fish_pager_color_description "{outl}"
set -g fish_pager_color_selected_background --background="{surf_high}"
"""

sh_content = f"""# Zenith Material Design 3 FZF options
export FZF_DEFAULT_OPTS="{fzf_opts}"
"""

with open(fish_out, "w", encoding="utf-8") as f:
    f.write(fish_content)

with open(sh_out, "w", encoding="utf-8") as f:
    f.write(sh_content)
EOF
