#!/bin/bash

# Get year from argument or use current year
YEAR=${1:-$(date +%Y)}
# Fetch country code
COUNTRY=$(curl -s https://ipapi.co/country/)

# If country is empty, default to PK (as it was in original script)
if [ -z "$COUNTRY" ]; then
    COUNTRY="PK"
fi

# Fetch holidays for the specific year and country
curl -s "https://date.nager.at/api/v3/PublicHolidays/$YEAR/$COUNTRY" > /home/zaeem/Documents/Dots/zenith-shell/events.json

# If the file is empty or not valid JSON, generate a fallback
if [ ! -s /home/zaeem/Documents/Dots/zenith-shell/events.json ] || ! jq . /home/zaeem/Documents/Dots/zenith-shell/events.json >/dev/null 2>&1; then
    if [ "$COUNTRY" == "PK" ]; then
        echo "[
            {\"date\": \"$YEAR-03-23\", \"name\": \"Pakistan Day\"},
            {\"date\": \"$YEAR-05-01\", \"name\": \"Labour Day\"},
            {\"date\": \"$YEAR-08-14\", \"name\": \"Independence Day\"},
            {\"date\": \"$YEAR-11-09\", \"name\": \"Iqbal Day\"},
            {\"date\": \"$YEAR-12-25\", \"name\": \"Quaid-e-Azam Day\"}
        ]" > /home/zaeem/Documents/Dots/zenith-shell/events.json
    else
        echo "[]" > /home/zaeem/Documents/Dots/zenith-shell/events.json
    fi
fi
