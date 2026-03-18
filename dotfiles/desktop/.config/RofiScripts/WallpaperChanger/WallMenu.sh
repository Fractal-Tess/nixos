#!/bin/sh

chosen=$(printf " Choose Wallpaper\n Random Wallpaper\n" | rofi -dmenu -i -config '~/.config/RofiScripts/WallpaperChanger/WM.rasi')

case "$chosen" in
   " Choose Wallpaper") ~/.config/RofiScripts/WallpaperChanger/wall.sh ;;
   " Random Wallpaper") ~/.config/RofiScripts/WallpaperChanger/wallrandom.sh ;;
   *) exit 1 ;;
esac
