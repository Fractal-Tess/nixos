#!/bin/sh

set -eu

DIR="$HOME/wallpapers/new"
LAST_WALLPAPER="$HOME/.config/RofiScripts/WallpaperChanger/last_wallpaper.txt"

[ -d "$DIR" ] || exit 0

count=$(find "$DIR" -maxdepth 1 -type f | wc -l)
[ "$count" -eq 0 ] && exit 0

last=""
[ -f "$LAST_WALLPAPER" ] && last=$(cat "$LAST_WALLPAPER")

selected=$(find "$DIR" -maxdepth 1 -type f | shuf -n 1)
if [ "$count" -gt 1 ]; then
  while [ "$selected" = "$last" ]; do
    selected=$(find "$DIR" -maxdepth 1 -type f | shuf -n 1)
  done
fi

waypaper --backend awww --wallpaper "$selected"
matugen image "$selected" -m dark -t scheme-fidelity --fallback-color '#888888' --source-color-index 0
echo "$selected" > "$LAST_WALLPAPER"
