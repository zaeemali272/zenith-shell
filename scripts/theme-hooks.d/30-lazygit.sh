#!/usr/bin/env bash
# Hook: Lazygit theme generator
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

LG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit"
mkdir -p "$LG_DIR"

python3 - "$PALETTE" "$LG_DIR/config.yml" <<'EOF'
import json, sys, os, re

pal_path, config_path = sys.argv[1], sys.argv[2]
try:
    with open(pal_path) as f:
        p = json.load(f)
except Exception:
    sys.exit(0)

pri = p.get('primary', '#ffb4a7')
sec = p.get('secondary', '#e7bdb5')
ter = p.get('tertiary', '#ddc48c')
err = p.get('error', '#ffb4ab')
outl_var = p.get('outline_variant', '#52443b')
surf_high = p.get('surface_container_high', '#312822')
fg = p.get('on_surface', '#f1dfdb')

theme_yaml = f"""  theme:
    activeBorderColor:
      - '{pri}'
      - bold
    inactiveBorderColor:
      - '{outl_var}'
    optionsTextColor:
      - '{sec}'
    selectedLineBgColor:
      - '{surf_high}'
    cherryPickCompatColor:
      - '{ter}'
    cherryPickPrevCommitColor:
      - '{sec}'
    markedBaseCommitColor:
      - '{pri}'
    unstagedChangesColor:
      - '{err}'
    defaultFgColor:
      - '{fg}'
    searchingActiveBorderColor:
      - '{ter}'
      - bold"""

content = ""
if os.path.isfile(config_path):
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception:
        content = ""

if not content.strip():
    content = f"gui:\n{theme_yaml}\n"
else:
    # If gui: block exists, replace or add theme:
    if "gui:" in content:
        if re.search(r'^\s*theme:', content, re.MULTILINE):
            # Replace existing theme block under gui
            content = re.sub(
                r'(gui:.*?\n\s*theme:)(?:(?!\n[a-zA-Z_]).)*',
                r'gui:\n' + theme_yaml,
                content,
                flags=re.DOTALL
            )
        else:
            content = content.replace("gui:\n", f"gui:\n{theme_yaml}\n")
    else:
        content = content.rstrip() + f"\n\ngui:\n{theme_yaml}\n"

with open(config_path, "w", encoding="utf-8") as f:
    f.write(content)
EOF
