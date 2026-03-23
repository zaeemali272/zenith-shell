#!/bin/bash

# Define categories
CORE_DIRS=(
    "$HOME/.cache/thumbnails"
    "$HOME/.cache/yay"
    "$HOME/.cache/paru"
    "$HOME/.cache/mesa_shader_cache"
    "$HOME/.cache/fontconfig"
    "$HOME/.cache/qt5ct"
    "$HOME/.cache/qt6ct"
    "$HOME/.cache/quickshell"
    "$HOME/.cache/gstreamer-1.0"
    "$HOME/.cache/wallpaper_thumbs"
    "$HOME/.cache/animation_thumbs"
    "$HOME/.local/share/Trash"
)

BROWSER_DIRS=(
    "$HOME/.cache/zen"
    "$HOME/.cache/mozilla"
    "$HOME/.cache/google-chrome"
    "$HOME/.cache/chromium"
    "$HOME/.cache/thorium"
)

VSCODE_DIRS=(
    "$HOME/.cache/vscode-cpptools"
    "$HOME/.cache/vscode-ripgrep"
    "$HOME/.cache/Code"
)

DEV_DIRS=(
    "$HOME/.cache/pip"
    "$HOME/.cache/npm"
    "$HOME/.cache/electron"
    "$HOME/.cache/uv"
    "$HOME/.cache/bazel"
    "$HOME/.cache/bazelisk"
    "$HOME/.cache/go-build"
    "$HOME/.cache/ms-playwright-go"
    "$HOME/.cache/sdkmanager"
    "$HOME/.cache/pypoetry"
    "$HOME/.cache/jedi"
    "$HOME/.cache/typescript"
    "$HOME/.cache/deno"
    "$HOME/.cache/node"
    "$HOME/.cache/pnpm"
    "$HOME/.cache/prisma"
    "$HOME/.cache/gem"
    "$HOME/.cache/g-ir-scanner"
)

WINE_GAME_DIRS=(
    "$HOME/.cache/wine"
    "$HOME/.cache/winetricks"
    "$HOME/.cache/Proton"
    "$HOME/.cache/Unity"
    "$HOME/.cache/unity3d"
)

SYSTEM_UI_DIRS=(
    "$HOME/.cache/wallust"
    "$HOME/.cache/gtk-4.0"
    "$HOME/.cache/tracker3"
    "$HOME/.cache/cliphist"
    "$HOME/.cache/fish"
    "$HOME/.cache/virt-manager"
    "$HOME/.cache/kdeconnect.app"
    "$HOME/.cache/kdeconnect.sms"
    "$HOME/.cache/Softdeluxe"
)

MEDIA_DIRS=(
    "$HOME/.cache/yt-dlp"
    "$HOME/.cache/lollypop"
    "$HOME/.cache/vlc"
)

# Function to format bytes into human-readable format
format_size() {
    local bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes} B"
    elif [[ $bytes -lt 1048576 ]]; then
        echo "$(echo "scale=1; $bytes / 1024" | bc -l) KB"
    elif [[ $bytes -lt 1073741824 ]]; then
        echo "$(echo "scale=1; $bytes / 1048576" | bc -l) MB"
    else
        echo "$(echo "scale=1; $bytes / 1073741824" | bc -l) GB"
    fi
}

# ANSI colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to draw a bar chart with colors
draw_bar() {
    local percent=$1
    local width=20
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    printf "${CYAN}["
    for ((i=0; i<filled; i++)); do printf "#"; done
    for ((i=0; i<empty; i++)); do printf " "; done
    printf "]${NC}"
}

echo -e "🧹 ${CYAN}Gathering cache information...${NC}"

declare -A DIR_SIZES
TOTAL_BYTES=0
MAX_BYTES=0

get_sizes() {
    local dirs=("$@")
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            size=$(du -sb "$dir" 2>/dev/null | awk '{print $1}')
            if [[ -n "$size" && $size -gt 0 ]]; then
                DIR_SIZES["$dir"]=$size
                TOTAL_BYTES=$((TOTAL_BYTES + size))
                [[ $size -gt $MAX_BYTES ]] && MAX_BYTES=$size
            fi
        fi
    done
}

get_sizes "${CORE_DIRS[@]}"
get_sizes "${BROWSER_DIRS[@]}"
get_sizes "${VSCODE_DIRS[@]}"
get_sizes "${DEV_DIRS[@]}"
get_sizes "${WINE_GAME_DIRS[@]}"
get_sizes "${SYSTEM_UI_DIRS[@]}"
get_sizes "${MEDIA_DIRS[@]}"

if [[ $TOTAL_BYTES -eq 0 ]]; then
    echo -e "✨ ${GREEN}All safe caches are already empty!${NC}"
    exit 0
fi

# Sort and display like ncdu
echo "--------------------------------------------------"
echo -e "   ${YELLOW}Size      Cache Path${NC}"
echo "--------------------------------------------------"

sorted_dirs=$(for dir in "${!DIR_SIZES[@]}"; do
    echo "${DIR_SIZES[$dir]} $dir"
done | sort -rn)

while read -r size dir; do
    percent=0
    [[ $MAX_BYTES -gt 0 ]] && percent=$((size * 100 / MAX_BYTES))
    h_size=$(format_size "$size")
    bar=$(draw_bar "$percent")
    printf "%b %-10s  ${CYAN}%s${NC}\n" "$bar" "$h_size" "$dir"
done <<< "$sorted_dirs"

echo "--------------------------------------------------"
printf "Total potential: ${YELLOW}%s${NC}\n" "$(format_size "$TOTAL_BYTES")"
echo "--------------------------------------------------"

clear_dirs() {
    local name=$1
    shift
    local dirs=("$@")
    local found_any=false
    local group_size=0
    
    for dir in "${dirs[@]}"; do
        if [[ -n "${DIR_SIZES["$dir"]}" ]]; then
            found_any=true
            group_size=$((group_size + DIR_SIZES["$dir"]))
        fi
    done
    
    if [[ "$found_any" == true ]]; then
        echo -ne "Clear ${YELLOW}${name}${NC} cache? ($(format_size "$group_size")) [y/N] "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            for dir in "${dirs[@]}"; do
                if [[ -d "$dir" ]]; then
                    echo -e "Clearing ${CYAN}$dir${NC}..."
                    rm -rf "$dir"/*
                fi
            done
            return 0
        fi
    fi
    return 1
}

# Individual Prompts
clear_dirs "Core System" "${CORE_DIRS[@]}"
clear_dirs "Browser" "${BROWSER_DIRS[@]}"
clear_dirs "VS Code" "${VSCODE_DIRS[@]}"
clear_dirs "Development" "${DEV_DIRS[@]}"
clear_dirs "Wine/Games" "${WINE_GAME_DIRS[@]}"
clear_dirs "System UI" "${SYSTEM_UI_DIRS[@]}"
clear_dirs "Media" "${MEDIA_DIRS[@]}"

# Optional: Pacman cache (only uninstalled pkgs)
if command -v pacman &>/dev/null; then
    echo -ne "Clean ${YELLOW}Pacman${NC} cache (uninstalled pkgs only)? [y/N] "
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "System: ${CYAN}Cleaning pacman cache...${NC}"
        sudo pacman -Sc --noconfirm
    fi
fi

echo "--------------------------------------------------"
echo -e "✅ ${GREEN}Task completed!${NC}"
