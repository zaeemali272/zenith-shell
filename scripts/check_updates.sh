#!/bin/bash

# Define paths relative to HOME
ZENITH_DIR="$HOME/zenith"
ZENITH_SHELL_DIR="$HOME/.config/quickshell"

check_repo() {
    local dir=$1
    local name=$2
    if [ -d "$dir/.git" ]; then
        cd "$dir" || return
        # Try to fetch updates with a timeout
        if command -v timeout >/dev/null 2>&1; then
            timeout 10s git fetch > /dev/null 2>&1
        else
            git fetch > /dev/null 2>&1
        fi
        
        if [ $? -eq 0 ]; then
            local count=$(git rev-list --count HEAD..@{u} 2>/dev/null)
            local commits="[]"
            if [ -n "$count" ] && [ "$count" -gt 0 ]; then
                # Get last 5 commit titles and dates
                commits=$(git log HEAD..@{u} --pretty=format:'{"title":"%s", "date":"%cr"}' -n 5 | jq -s .)
            fi
            
            if [ -z "$count" ]; then
                echo "{\"name\": \"$name\", \"exists\": true, \"updates\": 0, \"error\": \"No upstream\", \"commits\": []}"
            else
                echo "{\"name\": \"$name\", \"exists\": true, \"updates\": $count, \"commits\": $commits}"
            fi
        else
            echo "{\"name\": \"$name\", \"exists\": true, \"updates\": 0, \"error\": \"Fetch failed\", \"commits\": []}"
        fi
    else
        echo "{\"name\": \"$name\", \"exists\": false, \"updates\": 0, \"commits\": []}"
    fi
}

zenith_status=$(check_repo "$ZENITH_DIR" "zenith")
zenith_shell_status=$(check_repo "$ZENITH_SHELL_DIR" "zenith-shell")

jq -n \
    --argjson zenith "$zenith_status" \
    --argjson zenith_shell "$zenith_shell_status" \
    '{zenith: $zenith, zenith_shell: $zenith_shell}'
