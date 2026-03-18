#!/bin/sh

chosen=$(printf "Dark Mode\nLight Mode\n" | rofi -dmenu -i -config '~/.config/RofiScripts/Animations/A.rasi')

case "$chosen" in
   "Dark Mode")
     WALLPAPER=$(cat ~/.config/RofiScripts/WallpaperChanger/last_wallpaper.txt 2>/dev/null || find ~/wallpapers/new -type f | shuf -n 1)
     matugen image "$WALLPAPER" -m dark -t scheme-fidelity --fallback-color grey
     ;;
   "Light Mode")
     WALLPAPER=$(cat ~/.config/RofiScripts/WallpaperChanger/last_wallpaper.txt 2>/dev/null || find ~/wallpapers/new -type f | shuf -n 1)
     matugen image "$WALLPAPER" -m light -t scheme-fidelity --fallback-color grey
     ;;
   *) exit 1 ;;
esac
