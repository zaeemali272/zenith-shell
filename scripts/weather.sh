#!/bin/bash
# Fetches weather from wttr.in in JSON format with caching.

CACHE_FILE="$HOME/.cache/weather.json"
MAX_AGE=1800 # 30 minutes

mkdir -p "$(dirname "$CACHE_FILE")"

fetch_weather() {
    # Timeout after 5 seconds to prevent hanging
    if curl -s --max-time 5 "wttr.in/?format=j1" > "$CACHE_FILE.tmp"; then
        mv "$CACHE_FILE.tmp" "$CACHE_FILE"
    else
        rm -f "$CACHE_FILE.tmp"
    fi
}

if [ -f "$CACHE_FILE" ]; then
    current_time=$(date +%s)
    file_time=$(date +%s -r "$CACHE_FILE")
    age=$((current_time - file_time))

    if [ $age -gt $MAX_AGE ]; then
        fetch_weather
    fi
else
    fetch_weather
fi

if [ -s "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
else
    echo "{}"
fi
