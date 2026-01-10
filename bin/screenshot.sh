#!/usr/bin/env bash
set -euo pipefail

DIR="$HOME/Pictures/Screenshots"
FILE="$DIR/shot-$(date +%F_%H-%M-%S).png"

mkdir -p "$DIR"

# Select area; exit cleanly if cancelled
GEOM="$(slurp)" || exit 0

# Take screenshot
grim -g "$GEOM" "$FILE"

# Copy to clipboard
wl-copy < "$FILE"

# Open file manager to the screenshot location
thunar "$DIR"

# Notify user
notify-send "Screenshot" "Saved and copied to clipboard"
