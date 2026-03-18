#!/bin/sh

DIR="$HOME/wallpapers/new"
LAST_WALLPAPER="$HOME/.config/RofiScripts/WallpaperChanger/last_wallpaper.txt"

files=("$DIR"/*)
[ ${#files[@]} -eq 0 ] && exit 0

last=""
[ -f "$LAST_WALLPAPER" ] && last=$(cat "$LAST_WALLPAPER")

while true; do
    selected=$(find "$DIR" -type f | shuf -n 1)
    [ "$selected" != "$last" ] && break
done

matugen image "$selected" -m dark -t scheme-fidelity --fallback-color '#888888' --source-color-index 0
echo "$selected" > "$LAST_WALLPAPER"
