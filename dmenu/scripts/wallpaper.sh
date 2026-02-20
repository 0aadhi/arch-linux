#!/bin/sh

WALLDIR="/home/aadhi/wallpapers"

# ensure images exist
find "$WALLDIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \
\) | grep -q . || exit 1

# run sxiv with files as arguments (NOT stdin)
SELECTED=$(find "$WALLDIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \
\) -exec sxiv -t -o {} +)

# cancelled
[ -z "$SELECTED" ] && exit 0

# set wallpaper
feh --bg-fill "$SELECTED"
