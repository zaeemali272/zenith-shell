#!/bin/bash

ZENITH_DIR="$HOME/zenith"
ZENITH_REPO="https://github.com/zaeemali272/zenith.git"

log() {
    echo "[UpdateManager] $*"
}

# 1. Ensure Zenith exists and is updated
if [ ! -d "$ZENITH_DIR" ]; then
    log "Cloning Zenith..."
    git clone "$ZENITH_REPO" "$ZENITH_DIR"
else
    log "Pulling Zenith..."
    git -C "$ZENITH_DIR" pull
fi

# 2. Run the install script with passed arguments
cd "$ZENITH_DIR" || exit 1

log "Running: ./install.sh $*"
# Run in kitty for visibility
kitty -e bash -c "./install.sh $*; echo 'Done. Press enter to close.'; read"
