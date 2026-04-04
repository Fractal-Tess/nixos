#!/bin/sh

set -eu

DIR="$HOME/wallpapers/new"

[ -d "$DIR" ] || exit 0

selected=$(
  find "$DIR" -maxdepth 1 -type f -printf '%f\n' | sort | while read -r A; do
    printf '%s\000icon\037%s/%s\n' "$A" "$DIR" "$A"
  done | rofi -dmenu -i -config '~/.config/RofiScripts/WallpaperChanger/WC.rasi'
)

[ -z "$selected" ] && exit 0

waypaper --backend awww --wallpaper "$DIR/$selected"
matugen image "$DIR/$selected" -m dark -t scheme-fidelity --fallback-color '#888888' --source-color-index 0
