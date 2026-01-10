#!/usr/bin/env bash
set -euo pipefail

DIR="$HOME/Pictures/Screenshots"
DEFAULT_NAME="shot-$(date +%F_%H-%M-%S).png"
DEFAULT_PATH="$DIR/$DEFAULT_NAME"

mkdir -p "$DIR"

# 1) Area select first (exit cleanly if cancelled)
GEOM="$(slurp)" || exit 0

# 2) Capture to a temp file first
TMP="$(mktemp --suffix=.png)"
cleanup() { rm -f "$TMP"; }
trap cleanup EXIT

grim -g "$GEOM" "$TMP"

# 3) Copy to clipboard immediately
wl-copy < "$TMP"

# 4) Notify immediately
notify-send "Screenshot" "Captured to clipboard — choose where to save"

# 5) Save dialog (prefilled)
FILE="$(env GTK_USE_PORTAL=0 zenity --file-selection \
  --save \
  --confirm-overwrite \
  --filename="$DEFAULT_PATH")" || exit 0

# 6) Persist to chosen location
mv -f "$TMP" "$FILE"
trap - EXIT  # file is no longer temp-managed

notify-send "Screenshot" "Saved and copied to clipboard"
