#!/usr/bin/env bash
# Hook: Dynamic Icon Theme generator for Zenith Shell
# Recolors Reversal folder icons dynamically to match the active wallpaper/preset palette.
set -euo pipefail

PALETTE="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/zenith/colors.json}"
[[ -f "$PALETTE" ]] || exit 0

python3 - "$PALETTE" <<'EOF'
import os, sys, glob, shutil, json

pal_path = sys.argv[1]
try:
    with open(pal_path, "r", encoding="utf-8") as f:
        pal = json.load(f)
except Exception:
    sys.exit(0)

home = os.path.expanduser("~")
dest_icons = os.path.join(home, ".local", "share", "icons")
dest_theme = os.path.join(dest_icons, "Reversal-dark")
dest_base = os.path.join(dest_icons, "Reversal")

# Locate Reversal and Reversal-dark icon themes from system or nix store
candidates = [
    "/run/current-system/sw/share/icons",
    os.path.join(home, ".nix-profile", "share", "icons"),
    f"/etc/profiles/per-user/{os.environ.get('USER', 'zaeem')}/share/icons",
]
for data_dir in os.environ.get("XDG_DATA_DIRS", "").split(":"):
    if data_dir:
        candidates.append(os.path.join(data_dir, "icons"))

store_theme = None
for c in candidates:
    target = os.path.join(c, "Reversal-dark")
    if os.path.isdir(target):
        store_theme = os.path.realpath(target)
        break

if not store_theme or not os.path.isdir(store_theme):
    # Fallback search in nix store
    matches = sorted(glob.glob("/nix/store/*reversal-icon-theme*/share/icons/Reversal-dark"))
    if matches:
        store_theme = matches[-1]

if not store_theme or not os.path.isdir(store_theme):
    sys.exit(0)

store_base = os.path.join(os.path.dirname(store_theme), "Reversal")
if not os.path.isdir(store_base):
    sys.exit(0)

# Ensure ~/.local/share/icons/Reversal symlink exists so relative symlinks resolve properly
os.makedirs(dest_icons, exist_ok=True)
if not os.path.exists(dest_base) and not os.path.islink(dest_base):
    try:
        os.symlink(store_base, dest_base)
    except OSError:
        pass

# Ensure target theme directory structure
os.makedirs(dest_theme, exist_ok=True)

# Symlink top-level directories and files from base theme (except places and cache)
for item in os.listdir(store_theme):
    if item in ["places", "icon-theme.cache"]:
        continue
    src = os.path.join(store_theme, item)
    dst = os.path.join(dest_theme, item)
    if not os.path.exists(dst) and not os.path.islink(dst):
        try:
            os.symlink(src, dst)
        except OSError:
            pass

# Setup places structure
dest_places = os.path.join(dest_theme, "places")
os.makedirs(dest_places, exist_ok=True)
for sub in ["16", "22", "24", "symbolic"]:
    src = os.path.join(store_theme, "places", sub)
    dst = os.path.join(dest_places, sub)
    if not os.path.exists(dst) and not os.path.islink(dst):
        try:
            os.symlink(src, dst)
        except OSError:
            pass

dest_scalable = os.path.join(dest_places, "scalable")
os.makedirs(dest_scalable, exist_ok=True)

# --- Color Calculation ---
def hex_to_rgb(h):
    h = h.strip().lstrip("#")
    if len(h) == 6:
        return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
    return (255, 255, 255)

def rgb_to_hex(r, g, b):
    return f"#{max(0, min(255, int(round(r)))):02x}{max(0, min(255, int(round(g)))):02x}{max(0, min(255, int(round(b)))):02x}"

def blend(c1, c2, factor):
    r1, g1, b1 = hex_to_rgb(c1)
    r2, g2, b2 = hex_to_rgb(c2)
    return rgb_to_hex(r1 * (1 - factor) + r2 * factor, g1 * (1 - factor) + g2 * factor, b1 * (1 - factor) + b2 * factor)

def get_luminance(c):
    r, g, b = hex_to_rgb(c)
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0

pri = pal.get("primary", "#cba6f7").strip()
lum = get_luminance(pri)

# If primary is too bright, soften slightly so white emblem glyphs retain crisp contrast
front_color = blend(pri, "#000000", 0.15) if lum > 0.82 else pri
back_color = blend(front_color, "#000000", 0.18)
fold_color = blend(front_color, "#000000", 0.35)

# Pristine SVGs live in store_base/places/scalable
src_scalable = os.path.join(store_base, "places", "scalable")
for fname in os.listdir(src_scalable):
    fpath = os.path.join(src_scalable, fname)
    if not os.path.isfile(fpath) or os.path.islink(fpath) or not fname.endswith(".svg"):
        continue

    try:
        with open(fpath, "r", encoding="utf-8") as f:
            svg = f.read()

        if "#ffc841" in svg:
            svg = svg.replace("#ffc841", front_color)
            svg = svg.replace("#f5aa1e", back_color)
            svg = svg.replace("#f08705", fold_color)

        dst_path = os.path.join(dest_scalable, fname)
        with open(dst_path, "w", encoding="utf-8") as f:
            f.write(svg)
    except Exception:
        pass

# Recreate symlinks within places/scalable
store_theme_scalable = os.path.join(store_theme, "places", "scalable")
if os.path.isdir(store_theme_scalable):
    for fname in os.listdir(store_theme_scalable):
        src_link = os.path.join(store_theme_scalable, fname)
        dst_link = os.path.join(dest_scalable, fname)
        if os.path.exists(dst_link):
            continue
        if os.path.islink(src_link):
            target = os.readlink(src_link)
            base_target = os.path.basename(target)
            if os.path.exists(os.path.join(dest_scalable, base_target)):
                try:
                    os.symlink(base_target, dst_link)
                except OSError:
                    pass
            else:
                try:
                    os.symlink(target, dst_link)
                except OSError:
                    pass
EOF

# Update icon cache
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -f "$HOME/.local/share/icons/Reversal-dark" 2>/dev/null || true
fi
