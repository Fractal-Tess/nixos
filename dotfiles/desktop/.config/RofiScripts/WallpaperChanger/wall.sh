#!/bin/sh

DIR="$HOME/wallpapers/new"
selected=$(ls "$DIR" | while read -r A; do
  echo -en "$A\x00icon\x1f$DIR/$A\n"
done | rofi -dmenu -i -config '~/.config/RofiScripts/WallpaperChanger/WC.rasi')
[ -z "$selected" ] && exit 0
matugen image "$DIR/$selected" -m dark -t scheme-fidelity --fallback-color '#888888' --source-color-index 0
