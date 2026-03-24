#!/bin/bash
# Path: $HOME/.config/quickshell/scripts/slideshow.sh

LIST="$HOME/.cache/zenith_wallpaper_list"
SWWW="/usr/bin/swww"
DAEMON="/usr/bin/swww-daemon"

# Ensure swww-daemon is running
/usr/bin/pgrep -x swww-daemon > /dev/null || $DAEMON &
/usr/bin/sleep 2

while true; do
    if [ -f "$LIST" ]; then
        while IFS= read -r img; do
            [[ -z "$img" ]] && continue
            if [[ -f "$img" ]]; then
                # Get the filename for the notification
                filename=$(basename "$img")

                # Send notification
                notify-send -i "$img" "Zenith Shell" "Cycling to: $filename"

                # Apply wallpaper
                $SWWW img "$img" --transition-type fade --transition-step 90
                /usr/bin/sleep 3600
            fi
        done < "$LIST"
    else
        /usr/bin/sleep 5
    fi
done
