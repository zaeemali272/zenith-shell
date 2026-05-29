#!/bin/bash
# Path: $HOME/.config/quickshell/scripts/slideshow.sh

LIST="$HOME/.cache/zenith_wallpaper_list"
AWWW="/usr/bin/awww"
THUMB_DIR="$HOME/.cache/wallpaper_thumbs"
THEME_SCRIPT="$HOME/Documents/Dots/zenith-shell/scripts/zenith-theme.sh"

# Ensure awww-daemon is running
/usr/bin/pgrep -x awww-daemon > /dev/null || awww-daemon &
/usr/bin/sleep 2

while true; do
    if [ -f "$LIST" ]; then
        while IFS= read -r img; do
            [[ -z "$img" ]] && continue
            if [[ -f "$img" ]]; then
                # Apply wallpaper using awww
                $AWWW img --resize=crop "$img" --transition-type fade >> /tmp/slideshow.log 2>&1
                
                # Update current wallpaper cache for the theme script
                echo "$img" > "$HOME/.config/current_wallpaper.txt"

                # Trigger theme update
                "$THEME_SCRIPT" "$img" >> /tmp/slideshow.log 2>&1

                # Check for success
                if [ $? -eq 0 ]; then
                    /usr/bin/sleep 3600 # Sleep for 1 hour
                else
                    /usr/bin/sleep 5
                fi
            fi
        done < "$LIST"
    else
        /usr/bin/sleep 5
    fi
done

